import '../../../documents/data/models/document_model.dart';

class ChatMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<DocumentModel> referencedDocuments;
  final List<String> suggestedFollowUps;
  final bool isLoading;
  final bool hasError;
  final String? action;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.referencedDocuments = const [],
    this.suggestedFollowUps = const [],
    this.isLoading = false,
    this.hasError = false,
    this.action,
  });

  ChatMessageModel copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    List<DocumentModel>? referencedDocuments,
    List<String>? suggestedFollowUps,
    bool? isLoading,
    bool? hasError,
    String? action,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      referencedDocuments: referencedDocuments ?? this.referencedDocuments,
      suggestedFollowUps: suggestedFollowUps ?? this.suggestedFollowUps,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      action: action ?? this.action,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    List<DocumentModel> docs = [];
    if (json['referenced_documents'] != null && json['referenced_documents'] is List) {
      docs = (json['referenced_documents'] as List)
          .whereType<Map<String, dynamic>>()
          .map((docJson) => DocumentModel.fromJson(docJson))
          .toList();
    } else if (json['documents'] != null && json['documents'] is List) {
      docs = (json['documents'] as List)
          .whereType<Map<String, dynamic>>()
          .map((docJson) => DocumentModel.fromJson(docJson))
          .toList();
    }

    List<String> suggestions = [];
    if (json['suggested_follow_ups'] != null && json['suggested_follow_ups'] is List) {
      suggestions = (json['suggested_follow_ups'] as List).map((e) => e.toString()).toList();
    } else if (json['suggestions'] != null && json['suggestions'] is List) {
      suggestions = (json['suggestions'] as List).map((e) => e.toString()).toList();
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['reply']?.toString() ?? json['message']?.toString() ?? json['text']?.toString() ?? '',
      isUser: false,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      referencedDocuments: docs,
      suggestedFollowUps: suggestions,
      action: json['action']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'is_user': isUser,
        'timestamp': timestamp.toIso8601String(),
        'action': action,
      };
}

