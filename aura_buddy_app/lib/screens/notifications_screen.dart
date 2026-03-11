import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationService>().markAllAsRead();
      }
    });
  }

  @override
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final notifications = notificationService.notifications;
    final unreadCount = notificationService.unreadCount;

    return Scaffold(
      backgroundColor: AuraBuddyTheme.background,
      body: Column(
        children: [
          // ── Header ─────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AuraBuddyTheme.textOnPrimary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (unreadCount > 0)
                      GestureDetector(
                        onTap:
                            () =>
                                context
                                    .read<NotificationService>()
                                    .markAllAsRead(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Mark all read',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Notification List ──────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 800));
              },
              color: AuraBuddyTheme.primary,
              child: notifications.isEmpty
                  ? ListView( // ListView needed for RefreshIndicator to work on empty state
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_off_rounded,
                                size: 48,
                                color: AuraBuddyTheme.textLight,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No notifications yet',
                                style: GoogleFonts.inter(
                                  color: AuraBuddyTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (ctx, i) {
                        final notif = notifications[i];
                        return GestureDetector(
                          onTap: () {
                            context.read<NotificationService>().markAsRead(
                              notif.id,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  notif.isRead
                                      ? AuraBuddyTheme.surface
                                      : AuraBuddyTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  notif.isRead
                                      ? null
                                      : Border.all(
                                        color: AuraBuddyTheme.primary
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _notifColor(
                                      notif.type,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                    child: notif.emoji == '✨'
                                        ? AuraBuddyTheme.auraIcon(size: 20)
                                        : Center(
                                            child: Text(
                                              notif.emoji,
                                              style: const TextStyle(fontSize: 18),
                                            ),
                                          ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight:
                                              notif.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                          color: AuraBuddyTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        notif.body,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AuraBuddyTheme.textMedium,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _timeAgo(notif.createdAt),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AuraBuddyTheme.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!notif.isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: const BoxDecoration(
                                      color: AuraBuddyTheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white24,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'aura_received':
        return AuraBuddyTheme.primary;
      case 'hated':
        return AuraBuddyTheme.danger;
      case 'reply':
        return Colors.blue;
      case 'validated':
        return AuraBuddyTheme.success;
      case 'task_complete':
        return AuraBuddyTheme.warning;
      case 'streak':
        return AuraBuddyTheme.gold;
      default:
        return AuraBuddyTheme.textMedium;
    }
  }
}

