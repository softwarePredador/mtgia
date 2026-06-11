import 'package:test/test.dart';

import '../lib/ai/deck_state_analysis.dart' as deck_state;
import '../lib/ai/optimize_archetype_support.dart';
import '../lib/ai/optimize_runtime_support.dart' as optimize_runtime;

void main() {
  group('resolveEffectiveOptimizeArchetype', () {
    test('uses detected archetype when request is generic', () {
      for (final requested in const [
        'midrange',
        'value',
        'goodstuff',
        'general',
        'tempo',
      ]) {
        expect(
          resolveEffectiveOptimizeArchetype(
            requestedArchetype: requested,
            detectedArchetype: 'control',
          ),
          'control',
          reason: requested,
        );
      }
    });

    test('keeps explicit archetype when detected is generic or unknown', () {
      expect(
        resolveEffectiveOptimizeArchetype(
          requestedArchetype: 'combo',
          detectedArchetype: 'midrange',
        ),
        'combo',
      );
      expect(
        resolveEffectiveOptimizeArchetype(
          requestedArchetype: 'stax',
          detectedArchetype: 'unknown',
        ),
        'stax',
      );
      expect(
        resolveEffectiveOptimizeArchetype(
          requestedArchetype: 'aggro',
          detectedArchetype: '',
        ),
        'aggro',
      );
    });

    test('falls back to detected or midrange when request is absent', () {
      expect(
        resolveEffectiveOptimizeArchetype(
          requestedArchetype: null,
          detectedArchetype: 'spellslinger',
        ),
        'spellslinger',
      );
      expect(
        resolveEffectiveOptimizeArchetype(
          requestedArchetype: '  ',
          detectedArchetype: 'unknown',
        ),
        'midrange',
      );
    });

    test('runtime and deck-state analysis delegate to the same policy', () {
      const cases = [
        ('midrange', 'control', 'control'),
        ('goodstuff', 'tribal', 'tribal'),
        ('general', 'midrange', 'midrange'),
        ('tempo', 'combo', 'combo'),
        ('combo', 'midrange', 'combo'),
        ('stax', 'unknown', 'stax'),
      ];

      for (final (requested, detected, expected) in cases) {
        expect(
          optimize_runtime.resolveOptimizeArchetype(
            requestedArchetype: requested,
            detectedArchetype: detected,
          ),
          expected,
          reason: 'runtime $requested/$detected',
        );
        expect(
          deck_state.resolveOptimizeArchetype(
            requestedArchetype: requested,
            detectedArchetype: detected,
          ),
          expected,
          reason: 'deck-state $requested/$detected',
        );
      }
    });
  });
}
