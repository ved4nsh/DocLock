import 'package:flutter/material.dart';

enum DocumentType {
  pdf,
  image,
  text,
  spreadsheet,
  certificate,
}

/// Matches the JSON returned by GET /api/v1/documents
/// and POST /api/v1/documents, while also supporting UI helper getters.
class DocumentModel {
  final String id;
  final String filename;
  final String? mimeType;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  final String ownerId;
  final String? customCategory;
  final bool isPinned;
  final List<String> customTags;

  DocumentModel({
    required this.id,
    String? filename,
    String? title,
    this.mimeType,
    int? fileSizeBytes,
    String? fileSize,
    DateTime? uploadedAt,
    DateTime? updatedAt,
    String? ownerId,
    String? category,
    this.isPinned = false,
    List<String>? tags,
    DocumentType? type,
  })  : filename = filename ?? title ?? 'Untitled',
        fileSizeBytes = fileSizeBytes ?? _parseSizeStringToBytes(fileSize),
        uploadedAt = uploadedAt ?? updatedAt ?? DateTime.now(),
        ownerId = ownerId ?? '',
        customCategory = category,
        customTags = tags ?? const [];

  // ─── Display & Compatibility Getters ────────────────────────────────────────

  String get displayName {
    return filename.split('/').last.split('\\').last;
  }

  String get title => displayName;

  String get extension {
    final parts = displayName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  DocumentType get type {
    final ext = extension;
    if (['pdf'].contains(ext)) return DocumentType.pdf;
    if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) {
      return DocumentType.image;
    }
    if (['xlsx', 'xls', 'csv', 'numbers'].contains(ext)) {
      return DocumentType.spreadsheet;
    }
    if (['cer', 'crt', 'pem', 'p12', 'pfx'].contains(ext)) {
      return DocumentType.certificate;
    }
    final mime = mimeType ?? '';
    if (mime.startsWith('image/')) return DocumentType.image;
    if (mime == 'application/pdf') return DocumentType.pdf;
    return DocumentType.text;
  }

  IconData get icon {
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

  Color get accentColor {
    switch (type) {
      case DocumentType.pdf:
        return const Color(0xFFFF5252);
      case DocumentType.image:
        return const Color(0xFF00E5FF);
      case DocumentType.spreadsheet:
        return const Color(0xFF00E676);
      case DocumentType.certificate:
        return const Color(0xFFFFAB00);
      case DocumentType.text:
        return const Color(0xFF6C63FF);
    }
  }

  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileSize => fileSizeDisplay;

  DateTime get updatedAt => uploadedAt;

  String get category {
    if (customCategory != null && customCategory!.isNotEmpty) {
      return customCategory!;
    }
    switch (type) {
      case DocumentType.pdf:
        return 'Legal & Reports';
      case DocumentType.image:
        return 'Photos & Scans';
      case DocumentType.spreadsheet:
        return 'Financial';
      case DocumentType.certificate:
        return 'Identity & Security';
      case DocumentType.text:
        return 'Personal Notes';
    }
  }

  List<String> get tags {
    if (customTags.isNotEmpty) return customTags;
    final ext = extension.toUpperCase();
    return [if (ext.isNotEmpty) ext, type.name.toUpperCase()];
  }

  DocumentModel copyWith({
    String? id,
    String? filename,
    String? mimeType,
    int? fileSizeBytes,
    DateTime? uploadedAt,
    String? ownerId,
    String? category,
    bool? isPinned,
    List<String>? tags,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      ownerId: ownerId ?? this.ownerId,
      category: category ?? customCategory,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? customTags,
    );
  }

  // ─── Serialisation ──────────────────────────────────────────────────────────

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return DocumentModel(
      id: rawId.toString(),
      filename: (json['filename'] as String?) ??
          (json['file_name'] as String?) ??
          (json['title'] as String?) ??
          'Untitled',
      mimeType: json['mime_type'] as String? ?? json['content_type'] as String?,
      fileSizeBytes: _parseInt(json['file_size'] ?? json['size'] ?? 0),
      uploadedAt: _parseDate(
          json['uploaded_at'] ?? json['created_at'] ?? json['updated_at']),
      ownerId: (json['owner_id'] ?? json['user_id'] ?? '').toString(),
      category: json['category'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'mime_type': mimeType,
        'file_size': fileSizeBytes,
        'uploaded_at': uploadedAt.toIso8601String(),
        'owner_id': ownerId,
        'category': customCategory,
        'is_pinned': isPinned,
        'tags': customTags,
      };

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
      return _parseSizeStringToBytes(v);
    }
    return 0;
  }

  static int _parseSizeStringToBytes(String? str) {
    if (str == null || str.isEmpty) return 0;
    final lower = str.toLowerCase().trim();
    final numPart = double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (lower.contains('mb')) return (numPart * 1024 * 1024).round();
    if (lower.contains('kb')) return (numPart * 1024).round();
    if (lower.contains('gb')) return (numPart * 1024 * 1024 * 1024).round();
    return numPart.round();
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }
}
