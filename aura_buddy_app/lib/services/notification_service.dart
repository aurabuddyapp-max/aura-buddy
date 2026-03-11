import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    _loadMockNotifications();
    _loadReadStates();
  }

  void _loadMockNotifications() {
    _notifications.addAll([
      NotificationItem(
        id: '1',
        type: 'aura_received',
        title: '@aura_king gave you aura',
        body: '+50 aura on your gym post',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationItem(
        id: '2',
        type: 'reply',
        title: '@fit_guru replied to your comment',
        body: '"Beast mode! Keep it up 🔥"',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      NotificationItem(
        id: '3',
        type: 'validated',
        title: 'Mission Validated! ✅',
        body: 'Your WORKOUT mission was validated. +250 aura from pool!',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationItem(
        id: '4',
        type: 'hated',
        title: '@hater_101 hated your post',
        body: '-25 aura on your cooking post',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationItem(
        id: '5',
        type: 'task_complete',
        title: 'Weekly Task Complete! 🎯',
        body: '"Content Creator" — Created 2 posts. Claim +100 aura!',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      NotificationItem(
        id: '6',
        type: 'streak',
        title: 'Aura Streak! 🔥',
        body: '5 days giving aura — Bonus +200 aura unlocked!',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      NotificationItem(
        id: '7',
        type: 'aura_received',
        title: '@book_worm99 gave you aura',
        body: '+100 aura on your reading post',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        isRead: true,
      ),
      NotificationItem(
        id: '8',
        type: 'reply',
        title: '@good_karma replied to your comment',
        body: '"Totally agree with you!"',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationItem(
        id: '9',
        type: 'aura_received',
        title: '@healthy_vibes gave you aura',
        body: '+10 aura on your meal prep post',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ]);
  }

  Future<void> _loadReadStates() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_notifications') ?? [];
    for (var note in _notifications) {
      if (readIds.contains(note.id)) {
        note.isRead = true;
      }
    }
    notifyListeners();
  }

  Future<void> _saveReadStates() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = _notifications
        .where((n) => n.isRead)
        .map((n) => n.id)
        .toList();
    await prefs.setStringList('read_notifications', readIds);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _saveReadStates();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      _saveReadStates();
      notifyListeners();
    }
  }

  void addNotification(NotificationItem item) {
    _notifications.insert(0, item);
    notifyListeners();
  }
}

