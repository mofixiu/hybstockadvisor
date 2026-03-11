import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationCenter extends StatelessWidget {
  const NotificationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => provider.markAllRead(),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: Color(0xFF0A3D62),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey[500],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your alerts will appear here',
                    style: TextStyle(
                      color: isDark ? Colors.white24 : Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 24),
                ),
                onDismissed: (_) => provider.removeNotification(notif.id),
                child: GestureDetector(
                  onTap: () => provider.markRead(notif.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? cardColor.withOpacity(0.6)
                          : cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: notif.isRead
                          ? null
                          : Border.all(
                              color: const Color(0xFF0A3D62).withOpacity(0.3),
                              width: 1,
                            ),
                      boxShadow: notif.isRead
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _iconBgColor(notif.type)
                                  .withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _iconForType(notif.type),
                              color: _iconBgColor(notif.type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
                                          color: notif.isRead
                                              ? textColor.withOpacity(0.55)
                                              : textColor,
                                          fontWeight: notif.isRead
                                              ? FontWeight.w500
                                              : FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(
                                            left: 6, top: 2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0A3D62),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.body,
                                  style: TextStyle(
                                    color: notif.isRead
                                        ? textColor.withOpacity(0.4)
                                        : textColor.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _relativeTime(notif.timestamp),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey[400],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.priceMovement:
        return Icons.show_chart;
      case NotificationType.safetyIndex:
        return Icons.shield_outlined;
      case NotificationType.aiForecast:
        return Icons.auto_awesome;
      case NotificationType.appUpdate:
        return Icons.system_update_outlined;
      case NotificationType.weeklySummary:
        return Icons.summarize_outlined;
    }
  }

  Color _iconBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.priceMovement:
        return Colors.blue;
      case NotificationType.safetyIndex:
        return Colors.green;
      case NotificationType.aiForecast:
        return const Color(0xFF0A3D62);
      case NotificationType.appUpdate:
        return Colors.orange;
      case NotificationType.weeklySummary:
        return Colors.purple;
    }
  }

  String _relativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}';
  }
}
