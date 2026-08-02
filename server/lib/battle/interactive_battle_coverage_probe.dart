import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../ai/battle_engine_config.dart';
import 'interactive_battle_contract.dart';

const interactiveBattleCoverageMaximumPayloadBytes = 512 * 1024;

class InteractiveBattleCoverageResult {
  const InteractiveBattleCoverageResult({
    required this.ready,
    required this.unsupportedCards,
  });

  final bool ready;
  final List<Map<String, dynamic>> unsupportedCards;
}

class InteractiveBattleCoverageException implements Exception {
  const InteractiveBattleCoverageException(
    this.code, {
    this.statusCode,
    this.retryable = false,
  });

  final String code;
  final int? statusCode;
  final bool retryable;

  @override
  String toString() => 'InteractiveBattleCoverageException($code)';
}

/// Proves that both read-only deck coverage results belong to their governed
/// batch and interactive processes and agree under the same pinned catalog
/// and qualification policy.
class InteractiveBattleCoverageClient {
  InteractiveBattleCoverageClient({
    required String batchBaseUrl,
    required String interactiveBaseUrl,
    required ExternalBattleEngineIdentity expectedIdentity,
    required int expectedInteractiveMaximumActive,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    this.maximumPayloadBytes = interactiveBattleCoverageMaximumPayloadBytes,
  }) : _batchBaseUri = _validatedBaseUri(batchBaseUrl),
       _interactiveBaseUri = _validatedBaseUri(interactiveBaseUrl),
       _expectedIdentity = expectedIdentity,
       _expectedInteractiveMaximumActive = expectedInteractiveMaximumActive,
       _client = client ?? http.Client() {
    if (_sameRuntime(_batchBaseUri, _interactiveBaseUri)) {
      throw const InteractiveBattleCoverageException(
        'interactive_runtime_not_isolated',
      );
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
    if (maximumPayloadBytes < 64 * 1024) {
      throw ArgumentError.value(
        maximumPayloadBytes,
        'maximumPayloadBytes',
        'Must be at least 64 KiB.',
      );
    }
    if (expectedInteractiveMaximumActive < 1) {
      throw ArgumentError.value(
        expectedInteractiveMaximumActive,
        'expectedInteractiveMaximumActive',
        'Must be positive.',
      );
    }
  }

  final Uri _batchBaseUri;
  final Uri _interactiveBaseUri;
  final ExternalBattleEngineIdentity _expectedIdentity;
  final int _expectedInteractiveMaximumActive;
  final http.Client _client;
  final Duration timeout;
  final int maximumPayloadBytes;

  Future<InteractiveBattleCoverageResult> check({
    required Map<String, dynamic> deckA,
    required Map<String, dynamic> deckB,
  }) async {
    final batchHealth = await _requestJson(
      'GET',
      _batchBaseUri.resolve('/health'),
    );
    final interactiveHealth = await _requestJson(
      'GET',
      _interactiveBaseUri.resolve('/health'),
    );
    final batchCoverage = await _requestJson(
      'POST',
      _batchBaseUri.resolve('/coverage'),
      body: {'deck_a': deckA, 'deck_b': deckB},
    );
    final interactiveCoverage = await _requestJson(
      'POST',
      _interactiveBaseUri.resolve('/coverage'),
      body: {'deck_a': deckA, 'deck_b': deckB},
    );

    _validateIdentity(batchHealth);
    _validateIdentity(interactiveHealth);
    _validateIdentity(batchCoverage);
    _validateIdentity(interactiveCoverage);
    _validateRuntimeModes(batchHealth, interactiveHealth);
    _validateCatalogProof(batchHealth, interactiveHealth);
    _validateProcessCorrelation(
      batchHealth,
      interactiveHealth,
      batchCoverage,
      interactiveCoverage,
    );
    final batchResult = _validateCoverage(
      batchCoverage,
      deckA: deckA,
      deckB: deckB,
    );
    final interactiveResult = _validateCoverage(
      interactiveCoverage,
      deckA: deckA,
      deckB: deckB,
    );
    if (batchResult.ready != interactiveResult.ready ||
        _coverageSignature(batchResult) !=
            _coverageSignature(interactiveResult)) {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_result_mismatch',
        statusCode: 502,
      );
    }
    return interactiveResult;
  }

  void close() => _client.close();

  Future<Map<String, dynamic>> _requestJson(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final request =
        http.Request(method, uri)
          ..followRedirects = false
          ..headers['Accept'] = 'application/json';
    if (body != null) {
      final encoded = utf8.encode(jsonEncode(body));
      if (encoded.length > maximumPayloadBytes) {
        throw const InteractiveBattleCoverageException(
          'interactive_coverage_request_too_large',
        );
      }
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.bodyBytes = encoded;
    }

    late final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(timeout);
    } on TimeoutException {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_timeout',
        statusCode: 504,
        retryable: true,
      );
    } on http.ClientException {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_transport_failed',
        retryable: true,
      );
    }

    late final List<int> bytes;
    try {
      bytes = await _boundedBody(response).timeout(timeout);
    } on TimeoutException {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_timeout',
        statusCode: 504,
        retryable: true,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InteractiveBattleCoverageException(
        'interactive_coverage_unavailable',
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500,
      );
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      // The neutral invalid-payload error below is intentionally fail-closed.
    }
    throw const InteractiveBattleCoverageException(
      'interactive_coverage_payload_invalid',
      statusCode: 502,
    );
  }

  Future<List<int>> _boundedBody(http.StreamedResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maximumPayloadBytes) {
        throw const InteractiveBattleCoverageException(
          'interactive_coverage_payload_too_large',
          statusCode: 502,
        );
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  void _validateIdentity(Map<String, dynamic> payload) {
    if (externalBattleIdentityValidationError(
          payload,
          expected: _expectedIdentity,
        ) !=
        null) {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_identity_rejected',
        statusCode: 502,
      );
    }
  }

  void _validateRuntimeModes(
    Map<String, dynamic> batch,
    Map<String, dynamic> interactive,
  ) {
    if (batch['status'] != 'ok' ||
        batch['runtime_mode'] != 'batch' ||
        batch['batch_simulation_available'] != true ||
        interactive['status'] != 'ok' ||
        interactive['runtime_mode'] != 'interactive' ||
        interactive['batch_simulation_available'] != false ||
        !_validInteractiveMetrics(interactive['interactive_battle'])) {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_runtime_rejected',
        statusCode: 502,
      );
    }
  }

  bool _validInteractiveMetrics(Object? raw) {
    if (raw is! Map) return false;
    final metrics = raw.map((key, value) => MapEntry(key.toString(), value));
    final maximumActive = metrics['maximum_active'];
    final active = metrics['active'];
    final retained = metrics['retained'];
    return metrics['schema_version'] == interactiveBattleRuntimeSchema &&
        metrics['runtime_mode'] == 'interactive' &&
        metrics['batch_simulation_available'] == false &&
        maximumActive is int &&
        maximumActive == _expectedInteractiveMaximumActive &&
        active is int &&
        active >= 0 &&
        active <= maximumActive &&
        retained is int &&
        retained >= 0;
  }

  void _validateCatalogProof(
    Map<String, dynamic> batch,
    Map<String, dynamic> interactive,
  ) {
    if (!_validCatalogProof(batch) || !_validCatalogProof(interactive)) {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_catalog_invalid',
        statusCode: 502,
      );
    }
    for (final key in _catalogProofKeys) {
      if (batch[key] != interactive[key]) {
        throw const InteractiveBattleCoverageException(
          'interactive_coverage_catalog_mismatch',
          statusCode: 502,
        );
      }
    }
  }

  bool _validCatalogProof(Map<String, dynamic> payload) {
    final indexedNames = payload['indexed_names'];
    final qualificationRestrictions =
        payload['card_qualification_restrictions'];
    final activationRestrictions = payload['card_activation_restrictions'];
    final transitionInventory = payload['pin_transition_card_inventory'];
    final futureRestrictions = payload['future_card_activation_restrictions'];
    final releasedMissingRestrictions =
        payload['released_missing_card_activation_restrictions'];
    final activationSchema = payload['card_activation_policy_schema'];
    return payload['catalog_ready'] == true &&
        indexedNames is int &&
        indexedNames > 0 &&
        payload['card_qualification_policy_commit'] ==
            _expectedIdentity.commit &&
        qualificationRestrictions is int &&
        qualificationRestrictions >= 0 &&
        activationSchema is String &&
        activationSchema.trim().isNotEmpty &&
        activationSchema.length <= 160 &&
        activationRestrictions is int &&
        activationRestrictions >= 0 &&
        transitionInventory is int &&
        transitionInventory >= 0 &&
        _sha256Pattern.hasMatch(
          payload['card_activation_postgresql_evidence_sha256']?.toString() ??
              '',
        ) &&
        _sha256Pattern.hasMatch(
          payload['card_activation_postgresql_rows_sha256']?.toString() ?? '',
        ) &&
        futureRestrictions is int &&
        futureRestrictions >= 0 &&
        releasedMissingRestrictions is int &&
        releasedMissingRestrictions >= 0;
  }

  void _validateProcessCorrelation(
    Map<String, dynamic> batch,
    Map<String, dynamic> interactive,
    Map<String, dynamic> batchCoverage,
    Map<String, dynamic> interactiveCoverage,
  ) {
    final batchProcessId = batch['sidecar_process_id'];
    final batchStartedAt = batch['sidecar_started_at'];
    final interactiveProcessId = interactive['sidecar_process_id'];
    final interactiveStartedAt = interactive['sidecar_started_at'];
    if (batchProcessId == interactiveProcessId ||
        batchCoverage['sidecar_process_id'] != batchProcessId ||
        batchCoverage['sidecar_started_at'] != batchStartedAt ||
        interactiveCoverage['sidecar_process_id'] != interactiveProcessId ||
        interactiveCoverage['sidecar_started_at'] != interactiveStartedAt) {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_correlation_rejected',
        statusCode: 502,
      );
    }
  }

  InteractiveBattleCoverageResult _validateCoverage(
    Map<String, dynamic> payload, {
    required Map<String, dynamic> deckA,
    required Map<String, dynamic> deckB,
  }) {
    final ready = payload['ready'];
    final status = payload['status'];
    final decks = payload['decks'];
    final unsupported = payload['unsupported_cards'];
    if (ready is! bool ||
        status != (ready ? 'ready' : 'unsupported') ||
        decks is! List ||
        unsupported is! List) {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_payload_invalid',
        statusCode: 502,
      );
    }

    final expectedDecks = <String, String>{
      'deck_a': deckA['id']?.toString() ?? '',
      'deck_b': deckB['id']?.toString() ?? '',
    };
    final deckReady = <String, bool>{};
    for (final raw in decks) {
      if (raw is! Map) {
        throw const InteractiveBattleCoverageException(
          'interactive_coverage_payload_invalid',
          statusCode: 502,
        );
      }
      final row = raw.map((key, value) => MapEntry(key.toString(), value));
      final key = row['deck_key']?.toString();
      final id = row['deck_id']?.toString();
      final isReady = row['ready'];
      if (key == null ||
          !expectedDecks.containsKey(key) ||
          expectedDecks[key]!.isEmpty ||
          id != expectedDecks[key] ||
          isReady is! bool ||
          deckReady.containsKey(key)) {
        throw const InteractiveBattleCoverageException(
          'interactive_coverage_correlation_rejected',
          statusCode: 502,
        );
      }
      deckReady[key] = isReady;
    }
    if (deckReady.length != expectedDecks.length ||
        ready != deckReady.values.every((value) => value)) {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_correlation_rejected',
        statusCode: 502,
      );
    }

    final unsupportedCards = <Map<String, dynamic>>[];
    for (final raw in unsupported) {
      if (raw is! Map) {
        throw const InteractiveBattleCoverageException(
          'interactive_coverage_payload_invalid',
          statusCode: 502,
        );
      }
      final row = raw.map((key, value) => MapEntry(key.toString(), value));
      final deckKey = row['deck_key']?.toString();
      final name = row['name']?.toString().trim() ?? '';
      if (!expectedDecks.containsKey(deckKey) || name.isEmpty) {
        throw const InteractiveBattleCoverageException(
          'interactive_coverage_correlation_rejected',
          statusCode: 502,
        );
      }
      unsupportedCards.add(row);
    }
    if (ready != unsupportedCards.isEmpty) {
      throw const InteractiveBattleCoverageException(
        'interactive_coverage_correlation_rejected',
        statusCode: 502,
      );
    }
    return InteractiveBattleCoverageResult(
      ready: ready,
      unsupportedCards: unsupportedCards,
    );
  }

  String _coverageSignature(InteractiveBattleCoverageResult result) {
    final rows = result.unsupportedCards
        .map(
          (row) => <String, Object?>{
            'deck_key': row['deck_key']?.toString(),
            'name': row['name']?.toString(),
            'set_code': row['set_code']?.toString(),
            'collector_number': row['collector_number']?.toString(),
            'quantity': row['quantity'],
            'is_commander': row['is_commander'],
          },
        )
        .toList(growable: false)
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
    return jsonEncode({'ready': result.ready, 'unsupported_cards': rows});
  }
}

const _catalogProofKeys = <String>[
  'indexed_names',
  'card_qualification_policy_commit',
  'card_qualification_restrictions',
  'card_activation_policy_schema',
  'card_activation_restrictions',
  'pin_transition_card_inventory',
  'card_activation_postgresql_evidence_sha256',
  'card_activation_postgresql_rows_sha256',
  'future_card_activation_restrictions',
  'released_missing_card_activation_restrictions',
];

final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

Uri _validatedBaseUri(String value) {
  final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
  final uri = Uri.tryParse(normalized);
  if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.userInfo.isNotEmpty ||
      uri.query.isNotEmpty ||
      uri.fragment.isNotEmpty) {
    throw const InteractiveBattleCoverageException(
      'interactive_coverage_runtime_url_invalid',
    );
  }
  return uri;
}

bool _sameRuntime(Uri left, Uri right) =>
    left.scheme.toLowerCase() == right.scheme.toLowerCase() &&
    left.host.toLowerCase() == right.host.toLowerCase() &&
    left.port == right.port &&
    left.path.replaceAll(RegExp(r'/+$'), '') ==
        right.path.replaceAll(RegExp(r'/+$'), '');
