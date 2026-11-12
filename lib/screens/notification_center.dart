import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../models/market_stock.dart';
import '../providers/notification_provider.dart';
import '../theme/format.dart';
import '../theme/tokens.dart';
import '../widgets/ask_sheet.dart';
import '../widgets/ui.dart';

/// In-app alerts, newest first. Swipe left to delete.
class NotificationCenter extends StatelessWidget {
  const NotificationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      backgroundColor: p.paper,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: provider.markAllRead,
                child: const Text('Mark all read'),
              );
            },
          ),
          const SizedBox(width: Gap.sm),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final items = provider.notifications;
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: Gap.page),
              child: MessageBlock(
                title: 'No notifications yet',
                body: 'Price moves and research updates for your holdings will appear here.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: Gap.xxl),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Hairline(indent: Gap.page, endIndent: Gap.page),
            itemBuilder: (context, i) => _NotificationRow(notif: items[i], provider: provider),
          );
        },
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final AppNotification notif;
  final NotificationProvider provider;
  const _NotificationRow({required this.notif, required this.provider});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    final unread = !notif.isRead;
    final ticker = notif.ticker;
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Gap.page),
        color: p.down,
        child: Text('Delete', style: t.labelLarge?.copyWith(color: p.paper)),
      ),
      onDismissed: (_) => provider.removeNotification(notif.id),
      child: InkWell(
        onTap: () => provider.markRead(notif.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.page, 14, Gap.page, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(_iconFor(notif.type), size: 20, color: unread ? p.ink : p.inkFaint),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: t.titleSmall?.copyWith(
                              color: unread ? p.ink : p.inkMuted,
                              fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread)
                          Semantics(
                            label: 'Unread',
                            child: Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(left: Gap.sm, top: 6),
                              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: t.bodyMedium?.copyWith(color: unread ? p.inkMuted : p.inkFaint),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(_relativeTime(notif.timestamp), style: t.bodySmall),
                        const Spacer(),
                        LinkText(
                          'Ask about this',
                          arrow: false,
                          style: t.labelMedium,
                          onTap: () => showAskSheet(
                            context,
                            about: ticker != null && ticker != 'weekly'
                                ? AskContext(ticker: ticker)
                                : null,
                            initialMessage:
                                'Explain this update: ${notif.title}. ${notif.body}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.priceMovement:
        return Icons.show_chart;
      case NotificationType.safetyIndex:
        return Icons.shield_outlined;
      case NotificationType.aiForecast:
        return Icons.article_outlined;
      case NotificationType.appUpdate:
        return Icons.system_update_outlined;
      case NotificationType.weeklySummary:
        return Icons.calendar_today_outlined;
    }
  }

  static String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return Fmt.date(timestamp);
  }
}
