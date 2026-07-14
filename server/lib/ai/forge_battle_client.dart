import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
    http.Client? client,
    Duration timeout = const Duration(seconds: 150),
  })  : _baseUri = Uri.parse(baseUrl.replaceFirst(RegExp(r'/+$'), '')),
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
      throw ForgeServiceException(
        'Forge simulation exceeded ${_timeout.inSeconds} seconds',
      );
    } on http.ClientException catch (error) {
      throw ForgeServiceException('Forge request failed: ${error.message}');
    }

    final body = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
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
