import 'dart:io';

import 'package:test/test.dart';

import '../routes/ai/explain/index.dart' as explain_route;

void main() {
  group('AI explain runtime contract', () {
    test('maps provider authentication and throttling away from user auth', () {
      expect(
        explain_route.mapExplainProviderFailureStatus(HttpStatus.unauthorized),
        HttpStatus.serviceUnavailable,
      );
      expect(
        explain_route.mapExplainProviderFailureStatus(
          HttpStatus.tooManyRequests,
        ),
        HttpStatus.serviceUnavailable,
      );
      expect(
        explain_route.mapExplainProviderFailureStatus(HttpStatus.badRequest),
        HttpStatus.badGateway,
      );
    });

    test('binds cached explanations to canonical PostgreSQL card data', () {
      final source = File('routes/ai/explain/index.dart').readAsStringSync();

      expect(
        source,
        contains('SELECT name, type_line, oracle_text, ai_description'),
      );
      expect(source, contains("parameters: {'id': cardId}"));
      expect(source, contains('cardName = _normalizeOptionalText(row[0])'));
      expect(source, contains('oracleText = _normalizeOptionalText(row[2])'));
    });

    test(
      'rejects non-string request fields before provider or database work',
      () {
        final source = File('routes/ai/explain/index.dart').readAsStringSync();

        expect(
          source,
          contains('requireJsonObject(await context.request.json())'),
        );
        expect(source, contains("readOptionalJsonString(body, 'card_id'"));
        expect(
          source,
          contains("'card_name',\n      maxLength: _maxCardNameLength"),
        );
        expect(source, contains('on JsonObjectValidationException'));
      },
    );

    test('invalidates cache when Oracle data or model changes', () {
      final identity = explain_route.buildAiExplainCacheIdentity(
        cardName: 'Lightning Bolt',
        typeLine: 'Instant',
        oracleText: 'Lightning Bolt deals 3 damage to any target.',
        model: 'gpt-4o-mini',
      );
      final cached = explain_route.encodeAiExplainCache(
        'Explicação canônica.',
        identity: identity,
      );

      expect(
        explain_route.decodeAiExplainCache(cached, expectedIdentity: identity),
        'Explicação canônica.',
      );
      expect(
        explain_route.decodeAiExplainCache(
          cached,
          expectedIdentity: explain_route.buildAiExplainCacheIdentity(
            cardName: 'Lightning Bolt',
            typeLine: 'Instant',
            oracleText: 'Texto Oracle alterado.',
            model: 'gpt-4o-mini',
          ),
        ),
        isNull,
      );
      expect(
        explain_route.decodeAiExplainCache(
          cached,
          expectedIdentity: explain_route.buildAiExplainCacheIdentity(
            cardName: 'Lightning Bolt',
            typeLine: 'Instant',
            oracleText: 'Lightning Bolt deals 3 damage to any target.',
            model: 'gpt-5.4-mini',
          ),
        ),
        isNull,
      );
      expect(
        explain_route.decodeAiExplainCache(
          'Cache legado sem identidade',
          expectedIdentity: identity,
        ),
        isNull,
      );
    });

    test('bounds provider time and never exposes provider response bodies', () {
      final source = File('routes/ai/explain/index.dart').readAsStringSync();

      expect(source, contains('.timeout(providerTimeout)'));
      expect(
        source,
        isNot(contains("'Failed to call AI provider: \${response.body}'")),
      );
      expect(source, isNot(contains('print(')));
    });
  });
}
