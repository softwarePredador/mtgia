import 'dart:convert';

import 'package:server/ai_provider_usage_support.dart';
import 'package:test/test.dart';

void main() {
  test('parses provider usage without retaining response content', () {
    final usage = parseAiProviderTokenUsage(
      utf8.encode(
        jsonEncode({
          'choices': [
            {
              'message': {'content': 'sensitive generated text'},
            },
          ],
          'usage': {
            'prompt_tokens': 120,
            'completion_tokens': 45,
            'total_tokens': 165,
          },
        }),
      ),
    );

    expect(usage.inputTokens, 120);
    expect(usage.outputTokens, 45);
  });

  test('malformed or missing usage is fail-safe', () {
    expect(parseAiProviderTokenUsage(null).inputTokens, isNull);
    expect(parseAiProviderTokenUsage(const [1, 2, 3]).outputTokens, isNull);
    expect(
      parseAiProviderTokenUsage(utf8.encode('{"usage":{}}')).inputTokens,
      isNull,
    );
  });

  test('persists only usage metadata and never provider content', () async {
    final db = _FakeDb();
    final body = utf8.encode(
      jsonEncode({
        'choices': [
          {
            'message': {'content': 'private generated deck'},
          },
        ],
        'usage': {'prompt_tokens': 20, 'completion_tokens': 10},
      }),
    );

    expect(
      await recordAiProviderCall(
        db: db,
        endpoint: 'generate',
        model: 'gpt-4o-mini',
        latencyMs: 42,
        success: true,
        userId: '00000000-0000-4000-8000-000000000001',
        responseBodyBytes: body,
      ),
      isTrue,
    );
    expect(db.parameters['endpoint'], 'provider:generate');
    expect(db.parameters['inputTokens'], 20);
    expect(db.parameters['outputTokens'], 10);
    expect(db.parameters['promptSummary'], isNull);
    expect(db.parameters['responseSummary'], isNull);
    expect(db.parameters.toString(), isNot(contains('private generated deck')));
  });
}

class _FakeDb {
  Map<String, dynamic> parameters = <String, dynamic>{};

  Future<List<Object?>> execute(
    Object query, {
    Map<String, dynamic>? parameters,
  }) async {
    this.parameters = parameters ?? <String, dynamic>{};
    return const [];
  }
}
