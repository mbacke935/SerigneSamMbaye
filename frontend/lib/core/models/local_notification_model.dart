import 'dart:convert';

class LocalNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'audio', 'video', 'citation'
  final DateTime receivedAt;

  const LocalNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'receivedAt': receivedAt.toIso8601String(),
      };

  factory LocalNotificationModel.fromJson(Map<String, dynamic> json) =>
      LocalNotificationModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type'] as String? ?? 'tous',
        receivedAt: DateTime.parse(json['receivedAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  static LocalNotificationModel fromJsonString(String s) =>
      LocalNotificationModel.fromJson(
          jsonDecode(s) as Map<String, dynamic>);
}
