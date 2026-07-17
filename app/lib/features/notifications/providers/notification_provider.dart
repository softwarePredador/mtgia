import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/observability/app_observability.dart';

// ─── Model ───────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String type;
  final String? referenceId;
  final String title;
  final String? body;
  final String? readAt;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.type,
    this.referenceId,
    required this.title,
    this.body,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      referenceId: json['reference_id'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

// ─── Provider ────────────────────────────────────────────────

class NotificationProvider extends ChangeNotifier {
  final ApiClient _api;

  NotificationProvider({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasLoadedNotifications = false;
  String? _error;
  String? get error => _error;

  Timer? _pollTimer;
  int _stateGeneration = 0;
  int _unreadFetchGeneration = 0;
  int _notificationFetchGeneration = 0;
  Future<bool>? _markAllAsReadOperation;

  /// Inicia polling de contagem de não-lidas a cada 30s
  void startPolling() {
    _pollTimer?.cancel();
    fetchUnreadCount();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchUnreadCount();
    });
  }

  /// Para o polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  /// Busca contagem de não-lidas (badge)
  Future<void> fetchUnreadCount() async {
    // A resposta de um poll iniciado durante a mutação pode representar o
    // estado anterior do servidor. O próximo ciclo atualizará o badge depois
    // que a operação terminar.
    if (_markAllAsReadOperation != null) return;

    final generation = _stateGeneration;
    final requestGeneration = ++_unreadFetchGeneration;
    try {
      final resp = await _api.get('/notifications/count');
      if (generation != _stateGeneration ||
          requestGeneration != _unreadFetchGeneration) {
        return;
      }
      if (resp.statusCode == 200 && resp.data is Map) {
        final newCount = (resp.data as Map)['unread'] as int? ?? 0;
        if (newCount != _unreadCount) {
          _unreadCount = newCount;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[NotificationProvider] fetchUnreadCount error: $e');
      unawaited(
        AppObservability.instance.recordEvent(
          'notification_unread_count_failed',
          category: 'notifications',
          data: {'operation': 'fetchUnreadCount', 'error': '$e'},
        ),
      );
    }
  }

  /// Busca lista de notificações
  Future<void> fetchNotifications({
    int page = 1,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    if (_isLoading) return;

    final generation = _stateGeneration;
    final requestGeneration = ++_notificationFetchGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final query =
          'page=$page&limit=$limit${unreadOnly ? '&unread_only=true' : ''}';
      final resp = await _api.get('/notifications?$query');
      if (generation != _stateGeneration ||
          requestGeneration != _notificationFetchGeneration) {
        return;
      }
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map<String, dynamic>;
        final list = (data['data'] as List?) ?? [];
        _notifications =
            list
                .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
                .toList();
        _hasLoadedNotifications = true;
      } else {
        _error = 'Não foi possível carregar as notificações.';
      }
    } catch (e, stackTrace) {
      if (generation != _stateGeneration ||
          requestGeneration != _notificationFetchGeneration) {
        return;
      }
      _error = 'Não foi possível carregar as notificações.';
      debugPrint('[NotificationProvider] fetchNotifications error: $e');
      _captureProviderException(
        e,
        stackTrace: stackTrace,
        operation: 'fetchNotifications',
        extras: {'page': page, 'limit': limit, 'unread_only': unreadOnly},
      );
    } finally {
      if (generation == _stateGeneration &&
          requestGeneration == _notificationFetchGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Atualiza badge/lista em resposta a um evento FCM em foreground.
  Future<void> handleRealtimeEvent({
    required String type,
    String? referenceId,
  }) async {
    unawaited(
      AppObservability.instance.recordEvent(
        'notification_realtime_refresh',
        category: 'notifications',
        data: {'type': type, 'has_reference_id': referenceId != null},
      ),
    );

    await fetchUnreadCount();
    if (_hasLoadedNotifications || _notifications.isNotEmpty) {
      await fetchNotifications();
    }
  }

  /// Marca uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    final generation = _stateGeneration;
    try {
      final resp = await _api.put('/notifications/$notificationId/read', {});
      if (generation != _stateGeneration) return;
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return;
      }
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx >= 0) {
        final old = _notifications[idx];
        if (old.isRead) {
          return;
        }
        _notifications[idx] = AppNotification(
          id: old.id,
          type: old.type,
          referenceId: old.referenceId,
          title: old.title,
          body: old.body,
          readAt: DateTime.now().toIso8601String(),
          createdAt: old.createdAt,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('[NotificationProvider] markAsRead error: $e');
      _captureProviderException(
        e,
        stackTrace: stackTrace,
        operation: 'markAsRead',
        extras: {'notification_id': notificationId},
      );
    }
  }

  /// Marca todas como lidas
  Future<bool> markAllAsRead() {
    final activeOperation = _markAllAsReadOperation;
    if (activeOperation != null) return activeOperation;

    late final Future<bool> operation;
    operation = _performMarkAllAsRead().whenComplete(() {
      if (identical(_markAllAsReadOperation, operation)) {
        _markAllAsReadOperation = null;
      }
    });
    _markAllAsReadOperation = operation;
    return operation;
  }

  Future<bool> _performMarkAllAsRead() async {
    final generation = _stateGeneration;
    try {
      final hasUnreadLocal = _notifications.any((n) => !n.isRead);
      if (!hasUnreadLocal && _unreadCount == 0) {
        return true;
      }

      // Invalida qualquer contagem solicitada antes da mutação. Sem isso, um
      // poll lento poderia restaurar o badge antigo depois do sucesso abaixo.
      _unreadFetchGeneration++;
      final resp = await _api.put('/notifications/read-all', {});
      if (generation != _stateGeneration) return false;
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return false;
      }
      var changed = false;
      for (var i = 0; i < _notifications.length; i++) {
        final old = _notifications[i];
        if (!old.isRead) {
          _notifications[i] = AppNotification(
            id: old.id,
            type: old.type,
            referenceId: old.referenceId,
            title: old.title,
            body: old.body,
            readAt: DateTime.now().toIso8601String(),
            createdAt: old.createdAt,
          );
          changed = true;
        }
      }
      final data = resp.data is Map ? resp.data as Map : const {};
      final nextUnread = data['unread'] as int? ?? 0;
      if (_unreadCount != nextUnread) {
        _unreadCount = nextUnread;
        changed = true;
      }
      if (changed) {
        notifyListeners();
      }
      return true;
    } catch (e, stackTrace) {
      debugPrint('[NotificationProvider] markAllAsRead error: $e');
      _captureProviderException(
        e,
        stackTrace: stackTrace,
        operation: 'markAllAsRead',
      );
      return false;
    }
  }

  /// Limpa todo o estado do provider (chamado no logout)
  void clearAllState() {
    _stateGeneration++;
    _unreadFetchGeneration++;
    _notificationFetchGeneration++;
    _markAllAsReadOperation = null;
    if (_notifications.isEmpty &&
        _unreadCount == 0 &&
        !_isLoading &&
        _error == null &&
        !_hasLoadedNotifications) {
      stopPolling();
      return;
    }

    stopPolling();
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    _hasLoadedNotifications = false;
    notifyListeners();
  }

  void _captureProviderException(
    Object error, {
    required StackTrace stackTrace,
    required String operation,
    Map<String, Object?>? extras,
  }) {
    unawaited(
      AppObservability.instance.captureProviderException(
        error,
        stackTrace: stackTrace,
        provider: 'NotificationProvider',
        operation: operation,
        extras: extras,
      ),
    );
  }
}
