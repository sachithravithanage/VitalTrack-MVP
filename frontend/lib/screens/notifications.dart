import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/scope.dart';
import '../app/state.dart';
import '../app/ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final AppState app = AppScope.of(context);
    try {
      setState(() => _loading = true);
      await app.loadNotificationHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${app.t('error')}: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final notifications = app.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0A1430),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE4EAF3)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ResponsiveListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          children: <Widget>[
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (notifications.isEmpty)
              const EmptyStateCard(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                subtitle: 'You will see reminders and alerts here.',
              )
            else
              ...notifications.map(
                (notification) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: notification.read
                        ? null
                        : () async {
                            try {
                              await app.markNotificationAsRead(notification.id);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${app.t('error')}: $e'),
                                ),
                              );
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: notification.read
                                  ? const Color(0xFFE9EEF7)
                                  : const Color(0xFFE3EEFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              notification.read
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                              color: notification.read
                                  ? const Color(0xFF7A8BA3)
                                  : const Color(0xFF1E73D8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  notification.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF0A1430),
                                        fontWeight: notification.read
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.body,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF5F7391),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat(
                                    'MMM d, yyyy • hh:mm a',
                                  ).format(notification.sentAt),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF7A8BA3),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E73D8),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
