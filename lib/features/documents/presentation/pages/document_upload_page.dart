import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/datasources/document_remote_datasource.dart';

class DocumentUploadPage extends StatefulWidget {
  final String token;

  const DocumentUploadPage({super.key, required this.token});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage>
    with SingleTickerProviderStateMixin {
  final _dataSource = DocumentRemoteDataSourceImpl();

  File? _pickedFile;
  String? _pickedFileName;
  int? _pickedFileSize;
  bool _isUploading = false;
  bool _isPublic = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: -8, end: 8).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    if (result != null && result.files.single.path != null) {
      final f = File(result.files.single.path!);
      setState(() {
        _pickedFile = f;
        _pickedFileName = result.files.single.name;
        _pickedFileSize = result.files.single.size;
      });
    }
  }

  Future<void> _upload() async {
    if (_pickedFile == null) {
      _shakeController.forward(from: 0);
      _showSnack('Please select a file first', isError: true);
      return;
    }

    setState(() => _isUploading = true);
    try {
      final doc = await _dataSource.uploadDocument(
        token: widget.token,
        file: _pickedFile!,
      );
      if (_isPublic && doc.id.isNotEmpty) {
        try {
          await _dataSource.updateDocumentVisibility(
            token: widget.token,
            documentId: doc.id,
            isPublic: true,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      _showSnack('Document uploaded successfully!', isError: false);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop(true); // signal refresh
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text('Upload Document',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // Header
              const Text('Add to Vault', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              const Text(
                'Select a file to encrypt and store securely in your DocLock vault.',
                style: AppTextStyles.body,
              ),

              const SizedBox(height: 36),

              // File picker area
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_pickedFile == null ? _shakeAnimation.value : 0, 0),
                  child: child,
                ),
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickFile,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _pickedFile != null
                          ? AppColors.success.withValues(alpha: 0.05)
                          : AppColors.surfaceCard,
                      border: Border.all(
                        color: _pickedFile != null
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.border,
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: _pickedFile == null
                        ? _buildPickerPrompt()
                        : _buildFilePreview(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Security notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary.withValues(alpha: 0.05),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your file will be encrypted with AES-256-GCM before storage.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Visibility Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Document Visibility',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose whether to keep this document private in your vault or make it public for portfolios.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPublic = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isPublic
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : AppColors.inputField,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !_isPublic
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: !_isPublic ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 16,
                                    color: !_isPublic
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Private (Vault)',
                                    style: TextStyle(
                                      color: !_isPublic
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isPublic = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isPublic
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.inputField,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isPublic
                                      ? AppColors.accent
                                      : AppColors.border,
                                  width: _isPublic ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.public_rounded,
                                    size: 16,
                                    color: _isPublic
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Public (Shared)',
                                    style: TextStyle(
                                      color: _isPublic
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Upload button
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: _isUploading ? null : AppColors.primaryGradient,
                  color: _isUploading ? AppColors.surfaceCard : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isUploading
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _upload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading...',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_rounded,
                                color: Color(0xFF070B14), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Encrypt & Upload',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF070B14),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              if (_pickedFile != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isUploading
                      ? null
                      : () => setState(() {
                            _pickedFile = null;
                            _pickedFileName = null;
                            _pickedFileSize = null;
                          }),
                  child: const Text('Choose a different file',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerPrompt() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.08),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          ),
          child: const Icon(Icons.upload_file_rounded,
              color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap to select a file',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'PDF, images, documents, spreadsheets\nand more supported',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    final ext = (_pickedFileName ?? '').split('.').last.toUpperCase();
    final size = _pickedFileSize != null ? _formatSize(_pickedFileSize!) : '';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.1),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _pickedFileName ?? '',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pill(ext, AppColors.primary),
            if (size.isNotEmpty) ...[
              const SizedBox(width: 8),
              _pill(size, AppColors.accent),
            ],
          ],
        ),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
