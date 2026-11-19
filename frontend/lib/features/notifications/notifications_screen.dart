import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              onPressed: () => notifier.markAllRead(),
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text("Mark all read", style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => notifier.fetchNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = state.notifications[index];
                      return _buildNotificationCard(notif, notifier);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 54, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            "No Notifications Yet",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF475569)),
          ),
          SizedBox(height: 4),
          Text(
            "You will receive updates when an advisor reviews your financial profile.",
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif, NotificationsNotifier notifier) {
    IconData icon = Icons.info_outline;
    Color iconColor = AppTheme.primaryTeal;

    if (notif.type == "meeting") {
      icon = Icons.event;
      iconColor = const Color(0xFF0284C7);
    } else if (notif.type == "status") {
      icon = Icons.update;
      iconColor = AppTheme.accentGold;
    } else if (notif.type == "advisor") {
      icon = Icons.support_agent;
      iconColor = AppTheme.primaryTeal;
    }

    return InkWell(
      onTap: () {
        if (!notif.isRead) notifier.markRead(notif.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notif.isRead ? const Color(0xFFE2E8F0) : AppTheme.primaryTeal.withOpacity(0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notif.title,
                        style: TextStyle(
                          fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
