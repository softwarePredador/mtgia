import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'battle_engine_config.dart';

class ForgeCoverageIncomplete implements Exception {
  ForgeCoverageIncomplete(this.unsupportedCards, this.message);

  final List<Map<String, dynamic>> unsupportedCards;
  final String message;

  @override
  String toString() => 'ForgeCoverageIncomplete: $message';
}

class ForgeServiceException implements Exception {
  ForgeServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ForgeServiceException($statusCode): $message';
}

class ForgeBattleClient {
  ForgeBattleClient({
    required String baseUrl,
    required ExternalBattleEngineIdentity expectedIdentity,
    http.Client? client,
    Duration timeout = const Duration(seconds: 150),
    bool allowLegacyIdentity = false,
  }) : _baseUri = Uri.parse(baseUrl.replaceFirst(RegExp(r'/+$'), '')),
       _client = client ?? http.Client(),
       _timeout = timeout,
       _expectedIdentity = expectedIdentity,
       _allowLegacyIdentity = allowLegacyIdentity;

  final Uri _baseUri;
  final http.Client _client;
  final Duration _timeout;
  final ExternalBattleEngineIdentity _expectedIdentity;
  final bool _allowLegacyIdentity;

  void close() => _client.close();

  Future<Map<String, dynamic>> simulate(Map<String, dynamic> request) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            _baseUri.resolve('/simulate'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(request),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw ForgeServiceException(
        'Forge simulation exceeded ${_timeout.inSeconds} seconds',
        statusCode: 504,
      );
    } on http.ClientException catch (error) {
      throw ForgeServiceException('Forge request failed: ${error.message}');
    }

    final body = _decodeBody(response);
    _validateIdentity(body);
    if (request['request_schema_version'] == externalBattleRequestSchema) {
      final correlationError = externalBattleCorrelationValidationError(
        body,
        request,
      );
      if (correlationError != null) {
        throw ForgeServiceException(
          'Forge response correlation failed: $correlationError',
          statusCode: 502,
        );
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _validateCompletedBattle(body, request);
      return body;
    }
    if (response.statusCode == 422 &&
        body['error'] == 'forge_coverage_incomplete') {
      final unsupported = (body['unsupported_cards'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList(growable: false);
      throw ForgeCoverageIncomplete(
        unsupported,
        body['message']?.toString() ?? 'Forge coverage is incomplete',
      );
    }
    throw ForgeServiceException(
      body['message']?.toString() ??
          body['error']?.toString() ??
          'Forge returned an invalid response',
      statusCode: response.statusCode,
    );
  }

  void _validateCompletedBattle(
    Map<String, dynamic> body,
    Map<String, dynamic> request,
  ) {
    if (request['request_schema_version'] == externalBattleRequestSchema) {
      final validationError = externalBattleSuccessValidationError(
        body,
        request,
      );
      if (validationError != null) {
        throw ForgeServiceException(
          'Forge returned an invalid v2 battle payload: $validationError',
          statusCode: 502,
        );
      }
      return;
    }
    final turns = body['turns'];
    if (body['status'] != 'completed' ||
        body['engine'] != 'forge' ||
        body['error'] != null ||
        turns is! int ||
        turns <= 0) {
      throw ForgeServiceException(
        'Forge returned an invalid completed battle payload',
        statusCode: 502,
      );
    }
  }

  void _validateIdentity(Map<String, dynamic> body) {
    final identityError = externalBattleIdentityValidationError(
      body,
      expected: _expectedIdentity,
      allowLegacy: _allowLegacyIdentity,
    );
    if (identityError != null) {
      throw ForgeServiceException(
        'Forge sidecar identity rejected: $identityError',
        statusCode: 502,
      );
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      // The status-aware error below preserves the useful HTTP context.
    }
    throw ForgeServiceException(
      'Forge returned non-JSON content',
      statusCode: response.statusCode,
    );
  }
}
