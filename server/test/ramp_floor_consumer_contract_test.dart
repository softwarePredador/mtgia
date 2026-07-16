import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('generic ramp floor consumers', () {
    test('deck analysis keeps inclusive ramp but warns on ramp_floor', () {
      final source =
          File('routes/decks/[id]/analysis/index.dart').readAsStringSync();

      expect(source, contains('summarizeOptimizationRampProfilesForDeck'));
      expect(source, contains('if (rampFloorCount < 10)'));
      expect(source, contains("'ramp': rampCount"));
      expect(source, contains("'ramp_floor': rampFloorCount"));
      expect(source, contains("'ramp_contextual': rampContextualCount"));
    });

    test('AI analysis scores and prompts from structural ramp only', () {
      final source =
          File('routes/decks/[id]/ai-analysis/index.dart').readAsStringSync();

      expect(source, contains('final int rampFloorCount;'));
      expect(source, contains('final int rampContextualCount;'));
      expect(
        source,
        contains(
          'score += min(10, (metrics.rampFloorCount * 10 / 10).round())',
        ),
      );
      expect(source, contains('if (metrics.rampFloorCount < 8)'));
      expect(source, contains('use exclusivamente metrics.ramp_floor'));
      expect(source, contains("'ramp_count': rampCount"));
      expect(source, contains("'ramp_floor': rampFloorCount"));
      expect(source, contains("'ramp_contextual': rampContextualCount"));
    });

    test('weakness analysis filters recommendations through the floor', () {
      final source =
          File('routes/ai/weakness-analysis/index.dart').readAsStringSync();

      expect(source, contains('if (rampFloorCount < 8)'));
      expect(source, contains("'current_value': rampFloorCount"));
      expect(source, contains('genericRampFloorOnly: true'));
      expect(source, contains('!optimizationRampProfileForCard({'));
      expect(source, contains('}).countsTowardGenericFloor'));
      expect(source, isNot(contains("roles: const ['ramp', 'ritual']")));
    });

    test('rebuild fills ramp target from ramp_floor, not inclusive role', () {
      final source =
          File('lib/ai/rebuild_guided_service.dart').readAsStringSync();

      expect(source, contains("'ramp_floor': ramp"));
      expect(source, contains("roleCounts['ramp_floor']"));
      expect(source, contains('rampProfile.countsTowardGenericFloor'));
      expect(source, contains('rampProfile.requiresContextualPolicy'));
      expect(source, contains("case 'ramp':\n        return false;"));
      expect(source, contains("'ramp_profile_before'"));
      expect(source, contains("'ramp_profile_after'"));
    });
  });
}
