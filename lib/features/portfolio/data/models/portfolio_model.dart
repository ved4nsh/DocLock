import '../../../documents/data/models/document_model.dart';

class PortfolioModel {
  final String id;
  final String caption;
  final String userId;
  final String authorUsername;
  final String? authorPhotoUrl;
  final List<String> documentIds;
  final List<DocumentModel> documents;
  final bool isPublic;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PortfolioModel({
    required this.id,
    required this.caption,
    required this.userId,
    required this.authorUsername,
    this.authorPhotoUrl,
    required this.documentIds,
    this.documents = const [],
    this.isPublic = true,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    // Parse document IDs
    List<String> docIds = [];
    if (json['document_ids'] is List) {
      docIds = (json['document_ids'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['documentIds'] is List) {
      docIds = (json['documentIds'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Parse attached documents if embedded
    List<DocumentModel> docs = [];
    if (json['documents'] is List) {
      docs = (json['documents'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => DocumentModel.fromJson(e))
          .toList();
      if (docIds.isEmpty) {
        docIds = docs.map((d) => d.id).toList();
      }
    }

    final visibility = json['visibility'] as String?;
    final isPublic = json['is_public'] as bool? ??
        (visibility != null ? visibility == 'public' : true);

    return PortfolioModel(
      id: json['id']?.toString() ?? '',
      caption: (json['caption'] as String?) ??
          (json['description'] as String?) ??
          (json['title'] as String?) ??
          '',
      userId: json['user_id']?.toString() ??
          json['userId']?.toString() ??
          json['owner_id']?.toString() ??
          '',
      authorUsername: (json['author_username'] as String?) ??
          (json['username'] as String?) ??
          (json['user_email'] as String?) ??
          'Anonymous User',
      authorPhotoUrl: json['author_photo_url'] as String? ??
          json['author_avatar'] as String? ??
          json['photo_url'] as String?,
      documentIds: docIds,
      documents: docs,
      isPublic: isPublic,
      likesCount: _parseInt(json['likes_count'] ?? json['likesCount'] ?? 0),
      commentsCount:
          _parseInt(json['comments_count'] ?? json['commentsCount'] ?? 0),
      isLiked: json['is_liked'] as bool? ?? json['isLiked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'user_id': userId,
      'author_username': authorUsername,
      'author_photo_url': authorPhotoUrl,
      'document_ids': documentIds,
      'documents': documents.map((d) => d.toJson()).toList(),
      'is_public': isPublic,
      'visibility': isPublic ? 'public' : 'private',
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  PortfolioModel copyWith({
    String? id,
    String? caption,
    String? userId,
    String? authorUsername,
    String? authorPhotoUrl,
    List<String>? documentIds,
    List<DocumentModel>? documents,
    bool? isPublic,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PortfolioModel(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      userId: userId ?? this.userId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      documentIds: documentIds ?? this.documentIds,
      documents: documents ?? this.documents,
      isPublic: isPublic ?? this.isPublic,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
