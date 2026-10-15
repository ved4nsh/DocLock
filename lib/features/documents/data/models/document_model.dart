import 'package:flutter/material.dart';

enum DocumentType {
  pdf,
  image,
  text,
  spreadsheet,
  certificate,
}

class DocumentModel {
  final String id;
  final String title;
  final String category;
  final DocumentType type;
  final String fileSize;
  final DateTime updatedAt;
  final String encryptionAlgorithm;
  final bool isPinned;
  final bool isShared;
  final List<String> tags;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.fileSize,
    required this.updatedAt,
    this.encryptionAlgorithm = 'AES-256-GCM',
    this.isPinned = false,
    this.isShared = false,
    this.tags = const [],
  });

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

  DocumentModel copyWith({
    String? id,
    String? title,
    String? category,
    DocumentType? type,
    String? fileSize,
    DateTime? updatedAt,
    String? encryptionAlgorithm,
    bool? isPinned,
    bool? isShared,
    List<String>? tags,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      fileSize: fileSize ?? this.fileSize,
      updatedAt: updatedAt ?? this.updatedAt,
      encryptionAlgorithm: encryptionAlgorithm ?? this.encryptionAlgorithm,
      isPinned: isPinned ?? this.isPinned,
      isShared: isShared ?? this.isShared,
      tags: tags ?? this.tags,
    );
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      type: DocumentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DocumentType.text,
      ),
      fileSize: json['file_size'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      encryptionAlgorithm: json['encryption_algorithm'] as String? ?? 'AES-256-GCM',
      isPinned: json['is_pinned'] as bool? ?? false,
      isShared: json['is_shared'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'type': type.name,
      'file_size': fileSize,
      'updated_at': updatedAt.toIso8601String(),
      'encryption_algorithm': encryptionAlgorithm,
      'is_pinned': isPinned,
      'is_shared': isShared,
      'tags': tags,
    };
  }
}
