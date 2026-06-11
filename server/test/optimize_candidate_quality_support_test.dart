import 'package:test/test.dart';

import '../lib/ai/aggressive_candidate_meta_signal_support.dart';
import '../lib/ai/optimize_candidate_quality_support.dart';
import '../lib/ai/optimize_runtime_support.dart' as runtime_support;

void main() {
  group('optimize candidate quality support', () {
    test('ranks candidates using role alignment, meta signal and budget safety',
        () {
      final ranked = rankAggressiveCandidateQualityPairs(
        pairs: const [
          {
            'remove': 'Divination',
            'add': 'Budget Draw',
            'remove_role': 'draw',
            'remove_score': 70,
          },
          {
            'remove': 'Divination',
            'add': 'Premium Draw',
            'remove_role': 'draw',
            'remove_score': 70,
          },
        ],
        signalsByName: const {
          'budget draw': AggressiveCandidateQualitySignal(
            cardName: 'budget draw',
            roles: {'draw'},
            roleScore: 70,
            functionConfidence: 0.85,
            synergyScore: 40,
            synergyEvidenceCount: 3,
            rejectionPenalty: 0,
            budgetTier: 'budget',
            bracketScope: 'any',
            sources: {aggressiveCandidateMetaSignalSource},
          ),
          'premium draw': AggressiveCandidateQualitySignal(
            cardName: 'premium draw',
            roles: {'draw'},
            roleScore: 70,
            functionConfidence: 0.85,
            synergyScore: 40,
            synergyEvidenceCount: 3,
            rejectionPenalty: 0,
            budgetTier: 'expensive',
            bracketScope: 'bracket_3_4',
            sources: {aggressiveCandidateMetaSignalSource},
          ),
        },
        bracket: 1,
      );

      expect(ranked.first['add'], equals('Budget Draw'));
      expect(
        ranked.first['candidate_quality_sources'],
        equals([aggressiveCandidateMetaSignalSource]),
      );
    });

    test('bucketOptimizeQualityGateDroppedReasons groups common failures', () {
      final buckets = bucketOptimizeQualityGateDroppedReasons(
        const [
          'dados incompletos para avaliar carta',
          'delta cmc alto demais',
          'perda de papel funcional',
          'mana fora da identidade',
          'rejeitado pelo gate',
        ],
      );

      expect(buckets['incomplete_card_data'], equals(1));
      expect(buckets['curve_or_role_mismatch'], equals(1));
      expect(buckets['role_mismatch'], equals(1));
      expect(buckets['mana_or_land_safety'], equals(1));
      expect(buckets['quality_gate_rejected'], equals(1));
    });

    test('runtime export keeps existing candidate quality API compatible', () {
      final signal = runtime_support.AggressiveCandidateQualitySignal(
        cardName: 'arcane signet',
        roles: const {'ramp'},
        roleScore: 80,
        functionConfidence: 0.9,
        synergyScore: 20,
        synergyEvidenceCount: 1,
        rejectionPenalty: 0,
        budgetTier: 'budget',
        bracketScope: 'any',
        sources: const {aggressiveCandidateMetaSignalSource},
      );

      expect(signal.toJson()['roles'], equals(['ramp']));
    });
  });
}
