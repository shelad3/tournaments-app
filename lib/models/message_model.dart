import 'package:flutter/material.dart';

enum MessagePriority { normal, important, urgent }

class MessageModel {
  final String id;
  final String title;
  final String body;
  final MessagePriority priority;
  final String createdBy;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.title,
    required this.body,
    this.priority = MessagePriority.normal,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get priorityLabel {
    switch (priority) {
      case MessagePriority.normal:
        return 'Normal';
      case MessagePriority.important:
        return 'Important';
      case MessagePriority.urgent:
        return 'Urgent';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case MessagePriority.normal:
        return Colors.grey;
      case MessagePriority.important:
        return Colors.orange;
      case MessagePriority.urgent:
        return Colors.red;
    }
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'priority': priority.name,
    'createdBy': createdBy,
    'createdAt': createdAt,
  };

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) => MessageModel(
    id: id,
    title: map['title'] ?? '',
    body: map['body'] ?? '',
    priority: _parsePriority(map['priority']),
    createdBy: map['createdBy'] ?? '',
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  static MessagePriority _parsePriority(String? p) {
    switch (p) {
      case 'important':
        return MessagePriority.important;
      case 'urgent':
        return MessagePriority.urgent;
      default:
        return MessagePriority.normal;
    }
  }
}
