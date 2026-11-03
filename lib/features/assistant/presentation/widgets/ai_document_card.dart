import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../documents/data/datasources/document_remote_datasource.dart';
import '../../../documents/data/models/document_model.dart';

class AiDocumentCard extends StatefulWidget {
  final DocumentModel document;
  final String token;

  const AiDocumentCard({
    super.key,
    required this.document,
    required this.token,
  });

  @override
  State<AiDocumentCard> createState() => _AiDocumentCardState();
}

class _AiDocumentCardState extends State<AiDocumentCard> {
  final DocumentRemoteDataSource _dataSource = DocumentRemoteDataSourceImpl();
  bool _isDownloading = false;

  Future<void> _openDocument() async {
    setState(() => _isDownloading = true);
    try {
      final filePath = await _dataSource.downloadDocument(
        token: widget.token,
        documentId: widget.document.id,
        filename: widget.document.displayName,
      );
      if (mounted) {
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  IconData _iconForType(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return Icons.picture_as_pdf_rounded;
      case DocumentType.image:
        return Icons.image_rounded;
      case DocumentType.spreadsheet:
        return Icons.table_chart_rounded;
      case DocumentType.certificate:
        return Icons.verified_user_rounded;
      case DocumentType.text:
        return Icons.description_rounded;
    }
  }

  Color _colorForType(DocumentType type) {
    switch (type) {
      case DocumentType.pdf:
        return const Color(0xFFFF5252);
      case DocumentType.image:
        return AppColors.accent;
      case DocumentType.spreadsheet:
        return const Color(0xFF00E676);
      case DocumentType.certificate:
        return const Color(0xFFFFAB00);
      case DocumentType.text:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final typeColor = _colorForType(doc.type);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconForType(doc.type), color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doc.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      doc.category,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    const SizedBox(width: 6),
                    Text(
                      doc.fileSize,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isDownloading ? null : _openDocument,
            tooltip: 'Open Document',
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
          ),
        ],
      ),
    );
  }
}

