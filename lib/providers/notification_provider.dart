import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _boxName = 'notifications';
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Call during app startup to load persisted notifications from Hive.
  Future<void> loadNotifications() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get('list');
    if (raw != null && raw is List) {
      _notifications = raw
          .map((e) => AppNotification.fromMap(e as Map))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      _notifications = [];
    }
    notifyListeners();
  }

  /// Add a notification. Deduplicates by type per calendar day — one
  /// notification of each type is allowed per day.
  Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Check for duplicate (same type on same day)
    final duplicate = _notifications.any(
      (n) =>
          n.type == type &&
          n.timestamp.isAfter(todayStart),
    );
    if (duplicate) return;

    final notification = AppNotification(
      id: '${type.index}_${now.millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      timestamp: now,
    );

    _notifications.insert(0, notification);

    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx].isRead = true;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    bool changed = false;
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications = [];
    final box = await Hive.openBox(_boxName);
    await box.delete('list');
    notifyListeners();
  }

  Future<void> _persist() async {
    final box = await Hive.openBox(_boxName);
    await box.put('list', _notifications.map((n) => n.toMap()).toList());
  }
}
