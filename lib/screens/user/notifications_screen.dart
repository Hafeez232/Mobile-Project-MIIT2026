import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/app_notification.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

Future<void> showNotificationsPanel(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Notifications',
    barrierColor: Colors.black.withOpacity(0.25),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.7,
          heightFactor: 1,
          child: Material(
            color: AppColors.background,
            child: SafeArea(child: NotificationsPanel()),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _db = FirestoreService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_uid.isNotEmpty) _db.markNotificationsRead(_uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: const NotificationsPanel(),
    );
  }
}

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final _db = FirestoreService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_uid.isNotEmpty) _db.markNotificationsRead(_uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppNotification>>(
            stream: _db.notificationsStream(_uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = snap.data ?? [];
              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 56,
                        color: AppColors.textLight,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(notification: notification);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final color = switch (notification.type) {
      'booked' => AppColors.success,
      'cancelled' => AppColors.cancelRed,
      'edited' => AppColors.secondary,
      _ => AppColors.primary,
    };
    final icon = switch (notification.type) {
      'booked' => Icons.check_circle_outline,
      'cancelled' => Icons.cancel_outlined,
      'edited' => Icons.edit_calendar_outlined,
      _ => Icons.notifications_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: notification.isRead
            ? null
            : Border.all(color: AppColors.secondary.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDateTime(notification.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} $hour:$minute';
  }
}
