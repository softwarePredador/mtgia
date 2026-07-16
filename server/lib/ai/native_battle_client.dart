import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class NativeBattleCoverageIncomplete implements Exception {
  NativeBattleCoverageIncomplete(this.unsupportedCards, this.message);

  final List<Map<String, dynamic>> unsupportedCards;
  final String message;

  @override
  String toString() => 'NativeBattleCoverageIncomplete: $message';
}

class NativeBattleServiceException implements Exception {
  NativeBattleServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'NativeBattleServiceException($statusCode): $message';
}

class NativeBattleClient {
  NativeBattleClient({
    required String baseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 50),
  }) : _baseUri = Uri.parse(baseUrl.replaceFirst(RegExp(r'/+$'), '')),
       _client = client ?? http.Client(),
       _timeout = timeout;

  final Uri _baseUri;
  final http.Client _client;
  final Duration _timeout;

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
      throw NativeBattleServiceException(
        'Native battle simulation exceeded ${_timeout.inSeconds} seconds',
        statusCode: 504,
      );
    } on http.ClientException catch (error) {
      throw NativeBattleServiceException(
        'Native battle request failed: ${error.message}',
      );
    }

    final body = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body['engine'] != 'manaloom_native_reviewed' ||
          body['engine_contract'] != 'native_reviewed_rules_execution') {
        throw NativeBattleServiceException(
          'Native battle returned an untrusted engine contract',
          statusCode: response.statusCode,
        );
      }
      final turns = body['turns'];
      if (body['status'] != 'completed' ||
          body['error'] != null ||
          turns is! int ||
          turns <= 0) {
        throw NativeBattleServiceException(
          'Native battle returned an invalid completed battle payload',
          statusCode: 502,
        );
      }
      return body;
    }
    if (response.statusCode == 422 &&
        body['error'] == 'native_coverage_incomplete') {
      final unsupported = (body['unsupported_cards'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList(growable: false);
      throw NativeBattleCoverageIncomplete(
        unsupported,
        body['message']?.toString() ?? 'Native battle coverage is incomplete',
      );
    }
    throw NativeBattleServiceException(
      body['message']?.toString() ??
          body['error']?.toString() ??
          'Native battle returned an invalid response',
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // The status-aware error below preserves the useful HTTP context.
    }
    throw NativeBattleServiceException(
      'Native battle returned non-JSON content',
      statusCode: response.statusCode,
    );
  }
}
