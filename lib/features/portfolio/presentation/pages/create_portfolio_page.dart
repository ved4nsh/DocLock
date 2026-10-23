import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../documents/data/datasources/document_remote_datasource.dart';
import '../../../documents/data/models/document_model.dart';
import '../../data/datasources/portfolio_remote_datasource.dart';

class CreatePortfolioPage extends StatefulWidget {
  final String token;

  const CreatePortfolioPage({super.key, required this.token});

  @override
  State<CreatePortfolioPage> createState() => _CreatePortfolioPageState();
}

class _CreatePortfolioPageState extends State<CreatePortfolioPage> {
  final _captionController = TextEditingController();
  final _documentDataSource = DocumentRemoteDataSourceImpl();
  final _portfolioDataSource = PortfolioRemoteDataSourceImpl();

  List<DocumentModel> _userDocuments = [];
  final Set<String> _selectedDocumentIds = {};
  bool _isLoadingDocs = true;
  bool _isPublishing = false;
  String? _docLoadError;

  @override
  void initState() {
    super.initState();
    _loadUserDocuments();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDocuments() async {
    setState(() {
      _isLoadingDocs = true;
      _docLoadError = null;
    });

    try {
      final docs = await _documentDataSource.getDocuments(token: widget.token);
      if (mounted) {
        setState(() {
          _userDocuments = docs;
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _docLoadError = e.toString().replaceFirst('Exception: ', '');
          _isLoadingDocs = false;
        });
      }
    }
  }

  void _toggleSelection(DocumentModel doc) {
    setState(() {
      if (_selectedDocumentIds.contains(doc.id)) {
        _selectedDocumentIds.remove(doc.id);
      } else {
        _selectedDocumentIds.add(doc.id);
      }
    });
  }

  bool get _hasPrivateSelected {
    return _userDocuments.any(
      (d) => _selectedDocumentIds.contains(d.id) && !d.isPublic,
    );
  }

  Future<void> _handlePublish() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      _showSnackbar('Please write a caption for your portfolio', isError: true);
      return;
    }

    if (_selectedDocumentIds.isEmpty) {
      _showSnackbar('Please select at least one document to showcase',
          isError: true);
      return;
    }

    setState(() => _isPublishing = true);

    try {
      // 1. Ensure attached documents are made public before publishing
      final selectedDocs = _userDocuments
          .where((d) => _selectedDocumentIds.contains(d.id))
          .toList();

      for (final doc in selectedDocs) {
        if (!doc.isPublic) {
          try {
            await _documentDataSource.updateDocumentVisibility(
              token: widget.token,
              documentId: doc.id,
              isPublic: true,
            );
          } catch (_) {}
        }
      }

      // 2. Submit caption and selected document IDs to POST /api/v1/portfolios
      await _portfolioDataSource.createPortfolio(
        token: widget.token,
        caption: caption,
        documentIds: _selectedDocumentIds.toList(),
      );

      if (!mounted) return;
      _showSnackbar('Portfolio published successfully!', isError: false);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _showSnackbar(e.toString().replaceFirst('Exception: ', ''),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _showSnackbar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Portfolio',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _handlePublish,
            child: _isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Publish',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption Input
            const Text(
              'Caption & Overview',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _captionController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText:
                    'What are you showcasing? e.g. "My Verified Certifications & Projects 2026"',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.inputField,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Documents Section
            Row(
              children: [
                const Text(
                  'Select Documents to Showcase',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedDocumentIds.length} selected',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap documents to attach them to your public portfolio post.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),

            // Notice if private docs are selected
            if (_hasPrivateSelected) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Attached private documents will be automatically set to Public so viewers can inspect your credentials.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Document selector cards
            if (_isLoadingDocs)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_docLoadError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: AppColors.error, size: 36),
                    const SizedBox(height: 8),
                    Text(_docLoadError!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadUserDocuments,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_userDocuments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.folder_open_rounded,
                        color: AppColors.textMuted, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'No Documents in Vault',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upload documents to your vault first before creating a portfolio.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userDocuments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = _userDocuments[index];
                  final isSelected = _selectedDocumentIds.contains(doc.id);

                  return GestureDetector(
                    onTap: () => _toggleSelection(doc),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: doc.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(doc.icon,
                                color: doc.accentColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: doc.isPublic
                                            ? AppColors.primary
                                                .withValues(alpha: 0.12)
                                            : AppColors.inputField,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        doc.isPublic ? 'Public' : 'Private',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: doc.isPublic
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      doc.fileSizeDisplay,
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                                  isSelected ? AppColors.primaryGradient : null,
                              color: isSelected ? null : AppColors.inputField,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.black)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 36),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isPublishing ? null : _handlePublish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch_rounded,
                                color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Publish Portfolio Post',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
