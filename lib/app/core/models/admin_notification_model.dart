class AdminNotificationModel {
  const AdminNotificationModel({
    required this.id,
    required this.eventType,
    required this.title,
    required this.body,
    required this.createdAt,
    this.payload = const {},
    this.isRead = false,
  });

  final int id;
  final String eventType;
  final String title;
  final String body;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final bool isRead;

  AdminNotificationModel copyWith({bool? isRead}) => AdminNotificationModel(
    id: id,
    eventType: eventType,
    title: title,
    body: body,
    createdAt: createdAt,
    payload: payload,
    isRead: isRead ?? this.isRead,
  );

  factory AdminNotificationModel.fromJson(
    Map<String, dynamic> json, {
    bool isRead = false,
  }) => AdminNotificationModel(
    id: (json['id'] as num).toInt(),
    eventType: (json['event_type'] as String?) ?? '',
    title: (json['title'] as String?) ?? '',
    body: (json['body'] as String?) ?? '',
    createdAt:
        DateTime.tryParse((json['created_at'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    payload: json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : const {},
    isRead: isRead,
  );
}
