import '../api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ActivationEventTracker {
  Future<void> track(
    String eventName, {
    String? format,
    String? deckId,
    String source,
    Map<String, dynamic>? metadata,
  });

  Future<void> trackOnce(
    String dedupeKey,
    String eventName, {
    String? format,
    String? deckId,
    String source,
    Map<String, dynamic>? metadata,
  });
}

class ActivationFunnelService implements ActivationEventTracker {
  ActivationFunnelService._();

  static final ActivationFunnelService instance = ActivationFunnelService._();
  static const _receiptPrefix = 'manaloom.analytics.receipt.v1.';

  final ApiClient _apiClient = ApiClient();
  final Set<String> _sessionReceipts = <String>{};
  final Map<String, Future<void>> _inFlightOnce = <String, Future<void>>{};

  @override
  Future<void> track(
    String eventName, {
    String? format,
    String? deckId,
    String source = 'app',
    Map<String, dynamic>? metadata,
  }) async {
    await _send(
      eventName,
      format: format,
      deckId: deckId,
      source: source,
      metadata: metadata,
    );
  }

  @override
  Future<void> trackOnce(
    String dedupeKey,
    String eventName, {
    String? format,
    String? deckId,
    String source = 'app',
    Map<String, dynamic>? metadata,
  }) {
    final normalizedKey = dedupeKey.trim();
    if (normalizedKey.isEmpty || _sessionReceipts.contains(normalizedKey)) {
      return Future<void>.value();
    }

    final existing = _inFlightOnce[normalizedKey];
    if (existing != null) return existing;

    final future = _trackOnce(
      normalizedKey,
      eventName,
      format: format,
      deckId: deckId,
      source: source,
      metadata: metadata,
    );
    _inFlightOnce[normalizedKey] = future;
    return future.whenComplete(() {
      if (identical(_inFlightOnce[normalizedKey], future)) {
        _inFlightOnce.remove(normalizedKey);
      }
    });
  }

  Future<void> _trackOnce(
    String dedupeKey,
    String eventName, {
    String? format,
    String? deckId,
    required String source,
    Map<String, dynamic>? metadata,
  }) async {
    SharedPreferences? preferences;
    final receiptKey = '$_receiptPrefix${Uri.encodeComponent(dedupeKey)}';
    try {
      preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(receiptKey) == true) {
        _sessionReceipts.add(dedupeKey);
        return;
      }
    } catch (_) {
      // A indisponibilidade do receipt não pode afetar o fluxo principal.
    }

    final sent = await _send(
      eventName,
      format: format,
      deckId: deckId,
      source: source,
      metadata: {...?metadata, 'idempotency_key': dedupeKey},
    );
    if (!sent) return;

    _sessionReceipts.add(dedupeKey);
    try {
      await preferences?.setBool(receiptKey, true);
    } catch (_) {
      // O receipt é somente uma otimização de telemetria local.
    }
  }

  Future<bool> _send(
    String eventName, {
    String? format,
    String? deckId,
    required String source,
    Map<String, dynamic>? metadata,
  }) async {
    if (!ApiClient.hasAuthenticationToken) return false;

    try {
      final response = await _apiClient.post('/users/me/activation-events', {
        'event_name': eventName,
        if (format != null) 'format': format,
        if (deckId != null) 'deck_id': deckId,
        'source': source,
        'metadata': metadata ?? <String, dynamic>{},
      });
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      // Telemetria não pode quebrar fluxo principal.
      return false;
    }
  }
}
