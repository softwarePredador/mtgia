import 'package:server/openai_structured_output_support.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAI structured output support', () {
    test('uses strict JSON Schema for supported production models', () {
      final format = openAiStructuredResponseFormat(
        model: 'gpt-4o-mini',
        name: 'deck_analysis',
        schema: openAiDeckAnalysisSchema,
      );

      expect(format['type'], 'json_schema');
      final jsonSchema = format['json_schema'] as Map<String, dynamic>;
      expect(jsonSchema['strict'], isTrue);
      expect(jsonSchema['schema'], same(openAiDeckAnalysisSchema));
    });

    test('keeps JSON mode for explicitly configured legacy models', () {
      expect(
        openAiStructuredResponseFormat(
          model: 'gpt-4-turbo',
          name: 'legacy',
          schema: openAiDeckAnalysisSchema,
        ),
        {'type': 'json_object'},
      );
    });

    test('uses the token limit parameter required by each model family', () {
      expect(openAiTokenLimitPayload(model: 'gpt-5.4-mini', maxTokens: 700), {
        'max_completion_tokens': 700,
      });
      expect(openAiTokenLimitPayload(model: 'gpt-4o-mini', maxTokens: 700), {
        'max_tokens': 700,
      });
    });

    test('schemas close object shapes and required fields', () {
      for (final schema in [
        openAiDeckGenerationSchema,
        openAiArchetypesSchema,
        openAiDeckRecommendationsSchema,
        openAiDeckOptimizationSchema,
        openAiDeckCompletionSchema,
        openAiOptimizationCriticSchema,
        openAiDeckAnalysisSchema,
      ]) {
        expect(schema['type'], 'object');
        expect(schema['additionalProperties'], isFalse);
        expect(schema['required'], isNotEmpty);
      }
    });
  });
}
