enum NotificationType {
  priceMovement,
  safetyIndex,
  aiForecast,
  appUpdate,
  weeklySummary,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<dynamic, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.values[map['type'] as int],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isRead: map['isRead'] as bool,
    );
  }
}
