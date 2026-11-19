import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class NotificationsState {
  final bool isLoading;
  final List<NotificationModel> notifications;

  const NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _apiClient;
  Timer? _pollingTimer;

  NotificationsNotifier(this._apiClient) : super(const NotificationsState()) {
    fetchNotifications();
    // Start polling every 30 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications({bool isBackground = false}) async {
    if (!isBackground) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final res = await _apiClient.get('/notifications');
      final list = (res.data as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, notifications: list);
    } catch (_) {
      if (!isBackground) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _apiClient.patch('/notifications/$id/read');
      final updated = state.notifications.map((n) {
        if (n.id == id) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.post('/notifications/read-all');
      final updated = state.notifications.map((n) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient);
});
