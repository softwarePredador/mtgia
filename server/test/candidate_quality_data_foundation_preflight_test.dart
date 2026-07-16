import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:server/ai/optimize_rejection_history_support.dart';
import 'package:test/test.dart';

import '../bin/candidate_quality_data_foundation.dart' as foundation;

void main() {
  group('explicit optimize rejection evidence', () {
    test('accepts only explicit product quality rejections', () {
      expect(
        isExplicitOptimizeQualityRejection(const {
          'status_code': 422,
          'quality_error_code': 'OPTIMIZE_QUALITY_REJECTED',
        }),
        isTrue,
      );
      expect(
        isExplicitOptimizeQualityRejection(const {'status_code': 200}),
        isFalse,
      );
      expect(isExplicitOptimizeQualityRejection(const {}), isFalse);
      expect(
        isExplicitOptimizeQualityRejection(const {
          'status_code': 422,
          'quality_error_code': 'OPTIMIZE_QUALITY_REJECTED',
          'validation_run_token': 'validation_1',
        }),
        isFalse,
      );
      expect(
        isExplicitOptimizeQualityRejection(const {
          'status_code': 500,
          'quality_error_code': 'OPTIMIZE_EXECUTION_FAILED',
        }),
        isFalse,
      );
    });

    test('shared SQL predicate is strict and alias-safe', () {
      final sql = explicitOptimizeQualityRejectionSql('oal');
      expect(sql, contains("status_code' <> '200"));
      expect(sql, contains("? 'validation_run_token'"));
      expect(sql, contains('OPTIMIZE_QUALITY_REJECTED'));
      expect(
        () => explicitOptimizeQualityRejectionSql('oal; drop table cards'),
        throwsArgumentError,
      );
    });

    test('foundation prunes an authoritative empty penalty plan', () {
      final source =
          File('bin/candidate_quality_data_foundation.dart').readAsStringSync();
      final staleStart = source.indexOf(
        'Future<List<Map<String, dynamic>>> _loadStaleRejectionPenalties',
      );
      final staleEnd = source.indexOf(
        'Future<int> _pruneStaleFunctionTags',
        staleStart,
      );
      final pruneStart = source.indexOf(
        'Future<int> _pruneStaleRejectionPenalties',
      );
      final pruneEnd = source.indexOf(
        'Iterable<List<Map<String, dynamic>>> _batches',
        pruneStart,
      );
      expect(staleStart, greaterThanOrEqualTo(0));
      expect(staleEnd, greaterThan(staleStart));
      expect(pruneStart, greaterThanOrEqualTo(0));
      expect(pruneEnd, greaterThan(pruneStart));
      expect(
        source.substring(staleStart, staleEnd),
        isNot(contains('rows.isEmpty')),
      );
      expect(
        source.substring(pruneStart, pruneEnd),
        isNot(contains('rows.isEmpty')),
      );
      expect(
        source,
        contains('refusing to interpret a missing source as an empty'),
      );
      expect(source, contains('SET LOCAL max_parallel_workers_per_gather = 0'));
      expect(source, contains('_loadStaleGeneratedRowsSnapshot('));
    });
  });

  test('rejection penalties aggregate normalized keys deterministically', () {
    final raw = <Map<String, dynamic>>[
      {
        'card_name': 'Snap',
        'commander_name': 'Talrand, Sky Summoner',
        'archetype': 'Spellslinger',
        'reject_count': 4,
      },
      {
        'card_name': ' snap ',
        'commander_name': '  talrand,   sky summoner ',
        'archetype': 'spellslinger',
        'reject_count': 2,
      },
      {
        'card_name': 'Think Twice',
        'commander_name': 'Talrand, Sky Summoner',
        'archetype': 'Spellslinger',
        'reject_count': 3,
      },
      {
        'card_name': 'think twice',
        'commander_name': 'TALRAND, SKY SUMMONER',
        'archetype': ' spellslinger ',
        'reject_count': 1,
      },
      {
        'card_name': '{"invalid":"payload"}',
        'commander_name': 'Talrand, Sky Summoner',
        'archetype': 'spellslinger',
        'reject_count': 99,
      },
    ];

    final forward = foundation.aggregateCandidateQualityRejectionPenaltyRows(
      raw,
    );
    final reversed = foundation.aggregateCandidateQualityRejectionPenaltyRows(
      raw.reversed,
    );

    expect(forward, reversed);
    expect(forward, hasLength(2));
    final byCard = {
      for (final row in forward) row['card_name_normalized']: row,
    };
    expect(byCard['snap'], containsPair('reject_count', 6));
    expect(byCard['snap'], containsPair('penalty', 210));
    expect(byCard['think twice'], containsPair('reject_count', 4));
    expect(byCard['think twice'], containsPair('penalty', 140));

    String digest(List<Map<String, dynamic>> rows) {
      final canonical = rows.map(jsonEncode).toList()..sort();
      return sha256.convert(utf8.encode(canonical.join('\n'))).toString();
    }

    expect(digest(forward), digest(reversed));
  });

  test('planned dataset preflight rejects a duplicate conflict key', () {
    final duplicateTags = <Map<String, dynamic>>[
      {'card_id': 'card-1', 'tag': 'ramp', 'source': 'source-1'},
      {'card_id': 'card-1', 'tag': 'ramp', 'source': 'source-1'},
    ];

    expect(
      () => foundation.validateCandidateQualityPlannedDatasets(
        tagRows: duplicateTags,
        roleRows: const [],
        synergyRows: const [],
        penaltyRows: const [],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('card_function_tags has 1 duplicate'),
        ),
      ),
    );
  });

  test('planned dataset preflight accepts unique keys in all four lanes', () {
    expect(
      () => foundation.validateCandidateQualityPlannedDatasets(
        tagRows: const [
          {'card_id': 'card-1', 'tag': 'ramp', 'source': 'source-1'},
        ],
        roleRows: const [
          {
            'card_id': 'card-1',
            'role': 'ramp',
            'format': 'commander',
            'subformat': 'any',
            'bracket_scope': 'any',
            'source': 'source-1',
          },
        ],
        synergyRows: const [
          {
            'commander_name_normalized': 'talrand',
            'card_id': 'card-1',
            'role': 'ramp',
            'source': 'source-1',
          },
        ],
        penaltyRows: const [
          {
            'card_name_normalized': 'snap',
            'commander_name_normalized': 'talrand',
            'archetype': 'spellslinger',
            'function': '',
            'source': 'source-1',
          },
        ],
      ),
      returnsNormally,
    );
  });
}
