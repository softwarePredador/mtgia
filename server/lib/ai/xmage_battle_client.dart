import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class XmageCoverageIncomplete implements Exception {
  XmageCoverageIncomplete(this.unsupportedCards, this.message);

  final List<Map<String, dynamic>> unsupportedCards;
  final String message;

  @override
  String toString() => 'XmageCoverageIncomplete: $message';
}

class XmageServiceException implements Exception {
  XmageServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'XmageServiceException($statusCode): $message';
}

class XmageBattleClient {
  XmageBattleClient({
    required String baseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 130),
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
      throw XmageServiceException(
        'XMage simulation exceeded ${_timeout.inSeconds} seconds',
        statusCode: 504,
      );
    } on http.ClientException catch (error) {
      throw XmageServiceException('XMage request failed: ${error.message}');
    }

    final body = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _validateCompletedBattle(body);
      return body;
    }
    if (response.statusCode == 422 &&
        body['error'] == 'xmage_coverage_incomplete') {
      final unsupported = (body['unsupported_cards'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList(growable: false);
      throw XmageCoverageIncomplete(
        unsupported,
        body['message']?.toString() ?? 'XMage coverage is incomplete',
      );
    }
    throw XmageServiceException(
      body['message']?.toString() ??
          body['error']?.toString() ??
          'XMage returned an invalid response',
      statusCode: response.statusCode,
    );
  }

  void _validateCompletedBattle(Map<String, dynamic> body) {
    final turns = body['turns'];
    if (body['status'] != 'completed' ||
        body['engine'] != 'xmage' ||
        body['error'] != null ||
        turns is! int ||
        turns <= 0) {
      throw XmageServiceException(
        'XMage returned an invalid completed battle payload',
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
    throw XmageServiceException(
      'XMage returned non-JSON content',
      statusCode: response.statusCode,
    );
  }
}
