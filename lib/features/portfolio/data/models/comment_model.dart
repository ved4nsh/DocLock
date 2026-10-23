class CommentModel {
  final String id;
  final String portfolioId;
  final String userId;
  final String username;
  final String? userPhotoUrl;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.portfolioId,
    required this.userId,
    required this.username,
    this.userPhotoUrl,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString() ?? '',
      portfolioId: json['portfolio_id']?.toString() ??
          json['portfolioId']?.toString() ??
          '',
      userId: json['user_id']?.toString() ??
          json['userId']?.toString() ??
          json['author_id']?.toString() ??
          '',
      username: (json['username'] as String?) ??
          (json['author_name'] as String?) ??
          (json['user_email'] as String?) ??
          'Anonymous',
      userPhotoUrl: json['user_photo_url'] as String? ??
          json['user_avatar'] as String? ??
          json['photo_url'] as String?,
      content: (json['content'] as String?) ??
          (json['text'] as String?) ??
          (json['comment'] as String?) ??
          '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portfolio_id': portfolioId,
      'user_id': userId,
      'username': username,
      'user_photo_url': userPhotoUrl,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
