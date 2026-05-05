import 'package:server/ai/aggressive_candidate_meta_signal_support.dart';
import 'package:test/test.dart';

void main() {
  group('aggressive candidate meta signal support', () {
    test('requires trusted competitive external candidate status', () {
      expect(
        isExternalCommanderCandidateTrusted(
          validationStatus: 'promoted',
          legalStatus: 'valid',
          subformat: 'competitive_commander',
        ),
        isTrue,
      );
      expect(
        isExternalCommanderCandidateTrusted(
          validationStatus: 'candidate',
          legalStatus: 'valid',
          subformat: 'competitive_commander',
        ),
        isFalse,
      );
      expect(
        isExternalCommanderCandidateTrusted(
          validationStatus: 'promoted',
          legalStatus: 'valid',
          subformat: 'commander',
        ),
        isFalse,
      );
    });

    test('confidence separates proven, stale and unresolved signals', () {
      expect(
        confidenceLabel(
          evidenceCount: 14,
          source: 'competitive_commander_meta_decks',
          freshnessDays: 10,
        ),
        equals('high'),
      );
      expect(
        confidenceLabel(
          evidenceCount: 3,
          source: 'edhrec_enrichment',
          freshnessDays: 90,
        ),
        equals('low'),
      );
      expect(
        confidenceLabel(
          evidenceCount: 9,
          source: 'meta_decks',
          commanderIdentityResolved: false,
        ),
        equals('not_proven'),
      );
    });

    test('score rewards competitive evidence and applies rejection demotion',
        () {
      final strong = scoreAggressiveMetaSignal(
        evidenceCount: 8,
        roleScore: 82,
        functionConfidence: 0.9,
        subformat: 'competitive_commander',
        rejectionPenalty: 0,
        freshnessDays: 5,
      );
      final demoted = scoreAggressiveMetaSignal(
        evidenceCount: 8,
        roleScore: 82,
        functionConfidence: 0.9,
        subformat: 'competitive_commander',
        rejectionPenalty: 240,
        freshnessDays: 5,
      );

      expect(strong, greaterThan(demoted));
      expect(strong, greaterThanOrEqualTo(80));
    });

    test('replacement examples keep same role logic', () {
      final examples = buildRoleReplacementExamples(
        const [
          {
            'card_name': 'Weak Ramp Rock',
            'role': 'ramp',
            'reason': 'historical_quality_penalty',
          },
        ],
        const [
          {
            'card_name': 'Arcane Signet',
            'role': 'ramp',
            'score': 88,
            'evidence_count': 12,
            'confidence': 'high',
          },
          {
            'card_name': 'Efficient Draw',
            'role': 'draw',
            'score': 90,
            'evidence_count': 9,
            'confidence': 'medium_high',
          },
        ],
      );

      expect(examples, hasLength(1));
      expect(examples.first['replacement_card'], equals('Arcane Signet'));
      expect(examples.first['logic'], contains('same_role'));
    });
  });
}
