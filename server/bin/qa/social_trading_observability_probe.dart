// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

Future<void> main() async {
  final baseUrl = (Platform.environment['TEST_API_BASE_URL'] ??
          Platform.environment['BASE_URL'] ??
          'http://127.0.0.1:8082')
      .replaceFirst(RegExp(r'/$'), '');
  final sampleCount = math
      .max(3, int.tryParse(Platform.environment['OBS_SAMPLE_COUNT'] ?? '') ?? 5)
      .toInt();
  final marker =
      'qa_obs_${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
  final client = http.Client();

  final probe = _Probe(
    client: client,
    baseUrl: baseUrl,
    sampleCount: sampleCount,
    marker: marker,
  );

  try {
    await probe.run();
  } finally {
    client.close();
  }
}

class _Probe {
  _Probe({
    required this.client,
    required this.baseUrl,
    required this.sampleCount,
    required this.marker,
  });

  final http.Client client;
  final String baseUrl;
  final int sampleCount;
  final String marker;
  final Map<String, List<int>> timings = {};

  late String sellerToken;
  late String buyerToken;
  late String sellerId;
  late String cardId;
  late String binderItemId;
  late String tradeId;
  late String conversationId;

  Future<void> run() async {
    print(
        'SOCIAL_OBS_PROBE base_url=$baseUrl samples=$sampleCount marker=$marker');

    await _health();
    await _setupUsers();
    await _setupBinder();
    await _triggerExpectedErrors();
    await _measureMarketplace();
    await _measureTrades();
    await _measureTradeMessages();
    await _measureDirectMessages();
    await _triggerClientTimeout();
    _printSummary();
  }

  Future<void> _health() async {
    final response = await client.get(Uri.parse('$baseUrl/health'));
    print('HEALTH status=${response.statusCode}');
    if (response.statusCode != 200) {
      throw StateError('Backend health failed: ${response.statusCode}');
    }
  }

  Future<void> _setupUsers() async {
    final seller = await _register('seller');
    final buyer = await _register('buyer');
    sellerToken = seller.token;
    buyerToken = buyer.token;
    sellerId = seller.userId;
    print('SETUP users_created seller_id=$sellerId buyer_id=${buyer.userId}');
  }

  Future<_AuthResult> _register(String role) async {
    final suffix = '${marker}_$role';
    final response = await _request(
      'POST',
      '/auth/register',
      body: {
        'username': suffix,
        'email': '$suffix@example.invalid',
        'password': 'TestPassword123!',
      },
      expectedStatus: {200, 201},
      record: false,
    );
    final user = response.json['user'] as Map<String, dynamic>;
    return _AuthResult(
      token: response.json['token'] as String,
      userId: user['id'] as String,
    );
  }

  Future<void> _setupBinder() async {
    final cards = await _request(
      'GET',
      '/cards?name=Sol%20Ring&limit=1',
      token: sellerToken,
      record: false,
    );
    final data = cards.json['data'] as List<dynamic>;
    if (data.isEmpty) {
      throw StateError('Sol Ring not found for probe setup');
    }
    cardId = (data.first as Map<String, dynamic>)['id'] as String;

    final binder = await _request(
      'POST',
      '/binder',
      token: sellerToken,
      expectedStatus: {201},
      body: {
        'card_id': cardId,
        'quantity': sampleCount + 4,
        'condition': 'NM',
        'for_trade': true,
        'for_sale': true,
        'price': 9.99,
        'list_type': 'have',
      },
      record: false,
    );
    binderItemId = binder.json['id'] as String;
    print('SETUP binder_item_id=$binderItemId card_id=$cardId');
  }

  Future<void> _triggerExpectedErrors() async {
    final invalidTrade = await _request(
      'POST',
      '/trades',
      token: buyerToken,
      expectedStatus: {400},
      body: {
        'receiver_id': sellerId,
        'type': 'sale',
        'payment_method': 'wire',
        'requested_items': [
          {'binder_item_id': binderItemId, 'quantity': 1},
        ],
      },
      record: false,
    );
    print('OBS_EVENT invalid_payload status=${invalidTrade.statusCode}');

    final notFound = await _request(
      'GET',
      '/trades/00000000-0000-0000-0000-000000000000',
      token: buyerToken,
      expectedStatus: {404},
      record: false,
    );
    print('OBS_EVENT expected_4xx status=${notFound.statusCode}');
  }

  Future<void> _measureMarketplace() async {
    for (var i = 0; i < sampleCount; i++) {
      await _request(
        'GET',
        '/community/marketplace?search=Sol%20Ring&page=1&limit=20',
        token: buyerToken,
        metricName: 'GET /community/marketplace',
      );
    }
  }

  Future<void> _measureTrades() async {
    for (var i = 0; i < sampleCount; i++) {
      final trade = await _request(
        'POST',
        '/trades',
        token: buyerToken,
        expectedStatus: {201},
        metricName: 'POST /trades',
        body: {
          'receiver_id': sellerId,
          'type': 'sale',
          'payment_method': 'cash',
          'payment_amount': 9.99,
          'requested_items': [
            {
              'binder_item_id': binderItemId,
              'quantity': 1,
              'agreed_price': 9.99,
            },
          ],
          'message': 'QA observability trade $i',
        },
      );
      tradeId = trade.json['id'] as String;
      _expectKeys(trade.json, ['id', 'status', 'type', 'created_at']);

      await _request(
        'PUT',
        '/trades/$tradeId/respond',
        token: sellerToken,
        body: {'action': 'accept'},
        record: false,
      );

      final status = await _request(
        'PUT',
        '/trades/$tradeId/status',
        token: sellerToken,
        metricName: 'PUT /trades/:id/status',
        body: {
          'status': 'shipped',
          'delivery_method': 'correios',
          'tracking_code': 'OBS-$i',
        },
      );
      _expectKeys(status.json, ['old_status', 'status']);
    }

    for (var i = 0; i < sampleCount; i++) {
      final list = await _request(
        'GET',
        '/trades?page=1&limit=20',
        token: buyerToken,
        metricName: 'GET /trades',
      );
      _expectKeys(list.json, ['data']);

      final detail = await _request(
        'GET',
        '/trades/$tradeId',
        token: buyerToken,
        metricName: 'GET /trades/:id',
      );
      _expectKeys(detail.json, ['id', 'status', 'sender', 'receiver']);
    }
  }

  Future<void> _measureTradeMessages() async {
    for (var i = 0; i < sampleCount; i++) {
      final message = await _request(
        'POST',
        '/trades/$tradeId/messages',
        token: buyerToken,
        expectedStatus: {201},
        metricName: 'POST /trades/:id/messages',
        body: {'message': 'QA trade message $i'},
      );
      _expectKeys(message.json, ['id', 'trade_offer_id', 'sender_id']);
    }
  }

  Future<void> _measureDirectMessages() async {
    final conversation = await _request(
      'POST',
      '/conversations',
      token: buyerToken,
      body: {'user_id': sellerId},
      record: false,
    );
    conversationId = conversation.json['id'] as String;

    for (var i = 0; i < sampleCount; i++) {
      final message = await _request(
        'POST',
        '/conversations/$conversationId/messages',
        token: buyerToken,
        expectedStatus: {201},
        metricName: 'POST /conversations/:id/messages',
        body: {'message': 'QA direct message $i'},
      );
      _expectKeys(message.json, ['id', 'conversation_id', 'sender_id']);
    }
  }

  Future<void> _triggerClientTimeout() async {
    try {
      await client
          .get(
            Uri.parse(
              '$baseUrl/community/marketplace?search=Sol%20Ring&page=1&limit=20',
            ),
            headers: _headers(buyerToken),
          )
          .timeout(const Duration(microseconds: 1));
      print('OBS_EVENT client_timeout status=not_triggered');
    } on TimeoutException {
      print('OBS_EVENT client_timeout status=triggered timeout_us=1');
    }
  }

  Future<_TimedJson> _request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Set<int> expectedStatus = const {200},
    String? metricName,
    bool record = true,
  }) async {
    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse('$baseUrl$path');
    final response = switch (method) {
      'GET' => await client.get(uri, headers: _headers(token)),
      'POST' => await client.post(
          uri,
          headers: _headers(token),
          body: jsonEncode(body ?? const {}),
        ),
      'PUT' => await client.put(
          uri,
          headers: _headers(token),
          body: jsonEncode(body ?? const {}),
        ),
      _ => throw ArgumentError('Unsupported method $method'),
    };
    stopwatch.stop();

    if (!expectedStatus.contains(response.statusCode)) {
      throw StateError(
        '$method $path returned ${response.statusCode}; expected $expectedStatus',
      );
    }

    if (record) {
      timings.putIfAbsent(metricName ?? '$method $path', () => [])
        ..add(stopwatch.elapsedMilliseconds);
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    return _TimedJson(
      statusCode: response.statusCode,
      json: decoded,
    );
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'X-Request-Id': '$marker-${DateTime.now().microsecondsSinceEpoch}',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  void _expectKeys(Map<String, dynamic> json, List<String> keys) {
    final missing = keys.where((key) => !json.containsKey(key)).toList();
    if (missing.isNotEmpty) {
      print(
          'OBS_EVENT contract_error status=triggered missing=${missing.join(',')}');
      throw StateError('Contract keys missing: ${missing.join(',')}');
    }
  }

  void _printSummary() {
    print('');
    print('SOCIAL_OBS_PROBE_METRICS marker=$marker');
    for (final entry in timings.entries) {
      final stats = _Stats(entry.value);
      print(
        'METRIC endpoint="${entry.key}" samples=${entry.value.length} '
        'p50_ms=${stats.p50} p95_ms=${stats.p95} p99_ms=${stats.p99} '
        'min_ms=${stats.min} max_ms=${stats.max}',
      );
    }
    print('OBS_EVENT contract_error status=not_triggered contracts_valid=true');
  }
}

class _AuthResult {
  _AuthResult({required this.token, required this.userId});

  final String token;
  final String userId;
}

class _TimedJson {
  _TimedJson({
    required this.statusCode,
    required this.json,
  });

  final int statusCode;
  final Map<String, dynamic> json;
}

class _Stats {
  _Stats(List<int> values) : sorted = [...values]..sort();

  final List<int> sorted;

  int get min => sorted.first;
  int get max => sorted.last;
  int get p50 => _percentile(50);
  int get p95 => _percentile(95);
  int get p99 => _percentile(99);

  int _percentile(int percentile) {
    final rank = (percentile / 100 * sorted.length).ceil() - 1;
    final index = rank.clamp(0, sorted.length - 1).toInt();
    return sorted[index];
  }
}
