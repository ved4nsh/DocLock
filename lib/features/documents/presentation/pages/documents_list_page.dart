import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/datasources/document_remote_datasource.dart';
import '../../data/models/document_model.dart';
import 'document_upload_page.dart';

class DocumentsListPage extends StatefulWidget {
  final String token;

  const DocumentsListPage({super.key, required this.token});

  @override
  State<DocumentsListPage> createState() => _DocumentsListPageState();
}

class _DocumentsListPageState extends State<DocumentsListPage> {
  final _dataSource = DocumentRemoteDataSourceImpl();
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _downloadingIds = {};
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docs = await _dataSource.getDocuments(token: widget.token);
      if (mounted) setState(() => _documents = docs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDocument(DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Document',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Permanently delete "${doc.displayName}"?\nThis action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingIds.add(doc.id));
    try {
      await _dataSource.deleteDocument(token: widget.token, documentId: doc.id);
      if (mounted) {
        setState(() => _documents.removeWhere((d) => d.id == doc.id));
        _showSnack('Document deleted successfully', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(doc.id));
    }
  }

  Future<void> _downloadDocument(DocumentModel doc) async {
    setState(() => _downloadingIds.add(doc.id));
    try {
      final filePath = await _dataSource.downloadDocument(
        token: widget.token,
        documentId: doc.id,
        filename: doc.displayName,
      );
      if (mounted) {
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done && mounted) {
          _showSnack('Could not open file: ${result.message}', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _downloadingIds.remove(doc.id));
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

  Future<void> _goToUpload() async {
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentUploadPage(token: widget.token),
      ),
    );
    if (uploaded == true) _fetchDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('My Documents',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchDocuments,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _buildFAB(),
      body: _buildBody(),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _goToUpload,
      backgroundColor: Colors.transparent,
      elevation: 0,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.upload_file_rounded, color: Color(0xFF070B14), size: 20),
            SizedBox(width: 8),
            Text(
              'Upload Document',
              style: TextStyle(
                color: Color(0xFF070B14),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text('Loading your vault...', style: AppTextStyles.body),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 56),
              const SizedBox(height: 16),
              Text('Failed to load documents', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchDocuments,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF070B14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('No Documents Yet', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to upload\nyour first encrypted document.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: _fetchDocuments,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _documents.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return _DocumentCard(
            doc: doc,
            isDownloading: _downloadingIds.contains(doc.id),
            isDeleting: _deletingIds.contains(doc.id),
            onDownload: () => _downloadDocument(doc),
            onDelete: () => _deleteDocument(doc),
          );
        },
      ),
    );
  }
}

// ─── Document Card ──────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  final bool isDownloading;
  final bool isDeleting;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.doc,
    required this.isDownloading,
    required this.isDeleting,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('doc_${doc.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // let the delete handler control removal
      },
      background: Container(
        margin: const EdgeInsets.only(left: 80),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: doc.accentColor.withValues(alpha: 0.1),
            onTap: onDownload,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: doc.accentColor.withValues(alpha: 0.12),
                      border: Border.all(
                          color: doc.accentColor.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Icon(doc.icon, color: doc.accentColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _tag(doc.extension.isEmpty ? 'FILE' : doc.extension.toUpperCase(),
                                doc.accentColor),
                            const SizedBox(width: 8),
                            Text(doc.fileSizeDisplay,
                                style: AppTextStyles.caption),
                            const Spacer(),
                            Text(_timeAgo(doc.uploadedAt),
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Download / Delete actions
                  if (isDeleting)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.error),
                      ),
                    )
                  else if (isDownloading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  else
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onDownload,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.download_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 18),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
