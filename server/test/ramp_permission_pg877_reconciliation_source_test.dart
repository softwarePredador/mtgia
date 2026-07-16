import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

const _reportDir = '../docs/hermes-analysis/master_optimizer_reports';
const _prefix =
    '$_reportDir/'
    'pg877_ramp_permission_false_positive_reconciliation_20260716';
const _manifestPath =
    '../docs/hermes-analysis/'
    'PG877_RAMP_PERMISSION_FALSE_POSITIVE_MANIFEST_2026-07-16.json';

String _readSql(String suffix) => File('$_prefix$suffix').readAsStringSync();

String _digest(Iterable<String> values) {
  final sorted = values.toSet().toList()..sort();
  return sha256.convert(utf8.encode(sorted.join('\n'))).toString();
}

Set<String> _uuids(String text) =>
    RegExp(
      r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
      caseSensitive: false,
    ).allMatches(text).map((match) => match.group(0)!.toLowerCase()).toSet();

Map<String, dynamic> _manifest() =>
    jsonDecode(File(_manifestPath).readAsStringSync()) as Map<String, dynamic>;

void _expectReadOnly(String sql) {
  expect(sql, contains('BEGIN TRANSACTION READ ONLY'));
  expect(sql, contains('ROLLBACK;'));
  expect(sql, isNot(contains('DELETE FROM public.')));
  expect(sql, isNot(contains('UPDATE public.')));
  expect(sql, isNot(contains('INSERT INTO public.')));
  expect(sql, isNot(contains('CREATE TABLE')));
}

void _expectNoUnrelatedMutation(String sql) {
  for (final table in [
    'cards',
    'card_meta_insights',
    'edhrec_card_snapshots',
    'deck_cards',
    'decks',
    'card_legalities',
    'card_battle_rules',
    'commander_card_usage',
  ]) {
    expect(sql, isNot(contains('DELETE FROM public.$table')));
    expect(sql, isNot(contains('UPDATE public.$table')));
    expect(sql, isNot(contains('INSERT INTO public.$table')));
  }
}

void main() {
  group('PG877 permission false-positive reconciliation', () {
    test('manifest is exact, unambiguous and preserves six accelerators', () {
      final manifest = _manifest();
      final scope = manifest['scope']! as Map<String, dynamic>;
      final targets =
          (manifest['target_cards']! as List).cast<Map<String, dynamic>>();
      final preservedScope =
          manifest['preserved_scope']! as Map<String, dynamic>;
      final persistedImpact =
          manifest['persisted_surface_impact']! as Map<String, dynamic>;
      final postgresImpact =
          persistedImpact['postgresql']! as Map<String, dynamic>;
      final hermesImpact =
          persistedImpact['hermes_sqlite']! as Map<String, dynamic>;
      final semanticTransform =
          manifest['semantic_transform']! as Map<String, dynamic>;
      final preserved =
          (preservedScope['cards']! as List).cast<Map<String, dynamic>>();

      expect(manifest['status'], 'applied_postchecked');
      expect(manifest['postgresql_writes_executed'], isTrue);
      expect(manifest['precheck_status'], 'PG877_PRECHECK_PASS');
      expect(manifest['apply_status'], 'PG877_APPLY_COMMITTED');
      expect(manifest['postcheck_status'], 'PG877_POSTCHECK_PASS');
      expect(targets, hasLength(115));
      expect(preserved, hasLength(6));

      final targetIds = targets.map((row) => row['card_id']! as String);
      final preservedIds = preserved.map((row) => row['card_id']! as String);
      expect(
        _digest(targetIds),
        'b8e4fa337a747efadfd6cb1ab57ed5796e75de7387f3c85fd39cb3f4e742cc98',
      );
      expect(
        _digest(
          targets.map((row) => '${row['card_id']}|${row['classification']}'),
        ),
        '592c05966f7d8555543b4207c2ba38d423479db9e5812f9a0f7be4ed3c635ded',
      );
      expect(
        _digest(preservedIds),
        '02338acac46be3814fcbbb2e33de82b25ee078f6eea56daa3c0bd87376030e6e',
      );
      expect(targetIds.toSet().intersection(preservedIds.toSet()), isEmpty);
      expect(
        targets.map((row) => row['classification']),
        isNot(contains('other_review_required')),
      );
      expect(scope['classification_counts'], {
        'payment_permission_as_though_any': 71,
        'payment_permission_any_type_can_be_spent': 32,
        'payment_permission_spend_any_type': 2,
        'commander_color_identity_phrase_collision': 10,
      });
      expect(preserved.map((row) => row['card_name']).toSet(), {
        'Fallaji Wayfarer',
        'Gonti, Canny Acquisitor',
        'Gonti, Night Minister',
        'Manascape Refractor',
        'The Paradise Bird',
        'The Snapstone Wielder',
      });
      expect(postgresImpact['deck_cards_rows'], 28);
      expect(postgresImpact['deck_count'], 24);
      expect(postgresImpact['commander_card_usage_rows'], 8);
      expect(postgresImpact['sync_required'], isFalse);
      expect(hermesImpact['deck_cards_rows'], 12);
      expect(hermesImpact['ramp_rows'], 0);
      expect(hermesImpact['protected_deck_target_rows'], 0);
      expect(hermesImpact['sync_required'], isFalse);
      expect(
        semanticTransform['rebuilt_content_sha256'],
        'd06f7f53ec19b866e6b9e9160af69ca6b977ef623bf72eaf7d0c4926c236d4fa',
      );
      expect(semanticTransform['role_confidence_storage_type'], 'numeric(4,3)');
      expect(semanticTransform['role_confidence_typmod_rows'], 83);
    });

    test('precheck is read only and matches exact prestate hashes', () {
      final sql = _readSql('_precheck.sql');
      final manifest = _manifest();
      final targetIds =
          (manifest['target_cards']! as List)
              .cast<Map<String, dynamic>>()
              .map((row) => row['card_id']! as String)
              .toSet();
      final preservedIds =
          ((manifest['preserved_scope']! as Map<String, dynamic>)['cards']!
                  as List)
              .cast<Map<String, dynamic>>()
              .map((row) => row['card_id']! as String)
              .toSet();

      _expectReadOnly(sql);
      expect(_uuids(sql), targetIds.union(preservedIds));
      expect(sql, contains('PG877_PRECHECK_PASS'));
      expect(sql, contains('target_count = 115'));
      expect(sql, contains('heuristic_function_count = 105'));
      expect(sql, contains('semantic_function_count = 105'));
      expect(sql, contains('role_count = 115'));
      expect(sql, contains('semantic_empty_count = 22'));
      expect(sql, contains('semantic_post_count = 83'));
      expect(sql, contains('deck_ref_count = 28'));
      expect(sql, contains('deck_ref_deck_count = 24'));
      expect(sql, contains('usage_ref_count = 8'));
      expect(sql, contains('usage_ref_total = 54'));
      expect(
        sql,
        contains(
          '8183fd629f26d7030f1ee5b0b3f9b95516f70a4829838290ec6f37a8d4534dce',
        ),
      );
      expect(
        sql,
        contains(
          '42aa361635ba609e18b987a924bf350fbd828c6c0b1ad51821592a4a764413a1',
        ),
      );
      expect(
        sql,
        contains(
          'd06f7f53ec19b866e6b9e9160af69ca6b977ef623bf72eaf7d0c4926c236d4fa',
        ),
      );
      expect(sql, contains(')::numeric(4,3) AS role_confidence'));
      expect(
        sql,
        isNot(
          contains(
            'c12f7877dc14d02cf1843ee4bd4cb3e3986609962314609de46f22a928f45d99',
          ),
        ),
      );
    });

    test('apply is remove-only, exact and snapshots preserved rows', () {
      final sql = _readSql('_apply.sql');
      final manifest = _manifest();
      final targetIds =
          (manifest['target_cards']! as List)
              .cast<Map<String, dynamic>>()
              .map((row) => row['card_id']! as String)
              .toSet();
      final preservedIds =
          ((manifest['preserved_scope']! as Map<String, dynamic>)['cards']!
                  as List)
              .cast<Map<String, dynamic>>()
              .map((row) => row['card_id']! as String)
              .toSet();

      expect(sql, startsWith('-- MUTATING.'));
      expect(_uuids(sql), targetIds.union(preservedIds));
      for (final suffix in [
        'target',
        'function_backup',
        'role_backup',
        'semantic_backup',
        'function_untouched',
        'role_untouched',
        'semantic_untouched',
        'preserved_function',
        'preserved_role',
        'preserved_semantic',
        'semantic_post',
        'deck_refs',
        'usage_refs',
      ]) {
        expect(
          sql,
          contains('pg877_ramp_${suffix}_20260716'),
          reason: 'missing audit snapshot $suffix',
        );
      }
      expect(sql, contains('DELETE FROM public.card_function_tags'));
      expect(sql, contains('DELETE FROM public.card_role_scores'));
      expect(sql, contains('UPDATE public.card_semantic_tags_v2'));
      expect(sql, contains('DELETE FROM public.card_semantic_tags_v2'));
      expect(sql, isNot(contains('INSERT INTO public.')));
      expect(sql, contains('v_semantic_post_count <> 83'));
      expect(sql, contains(')::numeric(4,3) AS role_confidence'));
      expect(
        sql,
        contains(
          'd06f7f53ec19b866e6b9e9160af69ca6b977ef623bf72eaf7d0c4926c236d4fa',
        ),
      );
      expect(sql, contains('semantic_hash=%'));
      expect(sql, contains('preserved function rows changed'));
      expect(sql, contains('preserved role rows changed'));
      expect(sql, contains('preserved semantic rows changed'));
      expect(sql, contains('LOCK TABLE public.deck_cards IN SHARE MODE'));
      expect(
        sql,
        contains('LOCK TABLE public.commander_card_usage IN SHARE MODE'),
      );
      expect(sql, contains('deck references changed'));
      expect(sql, contains('commander usage references changed'));
      _expectNoUnrelatedMutation(sql);
    });

    test('postcheck is read only and verifies every captured diff', () {
      final sql = _readSql('_postcheck.sql');

      _expectReadOnly(sql);
      expect(sql, contains('PG877_POSTCHECK_PASS'));
      expect(sql, contains('bad_function_count = 0'));
      expect(sql, contains('bad_role_count = 0'));
      expect(sql, contains('bad_semantic_count = 0'));
      expect(sql, contains('semantic_post_diff = 0'));
      expect(
        sql,
        contains(
          'd06f7f53ec19b866e6b9e9160af69ca6b977ef623bf72eaf7d0c4926c236d4fa',
        ),
      );
      expect(sql, contains('untouched_function_diff = 0'));
      expect(sql, contains('untouched_role_diff = 0'));
      expect(sql, contains('untouched_semantic_diff = 0'));
      expect(sql, contains('preserved_function_diff = 0'));
      expect(sql, contains('preserved_role_diff = 0'));
      expect(sql, contains('preserved_semantic_diff = 0'));
      expect(sql, contains('deck_ref_diff = 0'));
      expect(sql, contains('usage_ref_diff = 0'));
    });

    test('rollback guards exact poststate and restores every backup', () {
      final sql = _readSql('_rollback.sql');

      expect(sql, startsWith('-- MUTATING ROLLBACK.'));
      expect(sql, contains('target function poststate drifted'));
      expect(sql, contains('target role poststate drifted'));
      expect(sql, contains('target semantic ramp reappeared'));
      expect(sql, contains('semantic poststate drifted'));
      expect(sql, contains('untouched function rows changed'));
      expect(sql, contains('untouched role rows changed'));
      expect(sql, contains('untouched semantic rows changed'));
      expect(sql, contains('preserved function rows changed'));
      expect(sql, contains('preserved role rows changed'));
      expect(sql, contains('preserved semantic rows changed'));
      expect(sql, contains('deck references changed'));
      expect(sql, contains('commander usage references changed'));
      expect(sql, contains('function restore differs'));
      expect(sql, contains('role restore differs'));
      expect(sql, contains('semantic restore differs'));
      expect(sql, contains('INSERT INTO public.card_function_tags'));
      expect(sql, contains('INSERT INTO public.card_role_scores'));
      expect(sql, contains('INSERT INTO public.card_semantic_tags_v2'));
      _expectNoUnrelatedMutation(sql);
    });

    test('handoff records committed apply and exact postcheck', () {
      final handoff =
          File(
            '../docs/hermes-analysis/'
            'PG877_RAMP_PERMISSION_FALSE_POSITIVE_RECONCILIATION_2026-07-16.md',
          ).readAsStringSync();

      expect(handoff, contains('applied_postchecked'));
      expect(handoff, contains('PG877_PRECHECK_PASS'));
      expect(handoff, contains('PG877_POSTCHECK_PASS'));
      expect(handoff, contains('corrected apply committed'));
      expect(handoff, contains('`115`'));
      expect(handoff, contains('`6`'));
      expect(handoff, contains('PG877_HERMES_SURFACE_GUARD_PASS'));
      expect(
        File(
          '../docs/hermes-analysis/manaloom-knowledge/scripts/'
          'pg877_ramp_permission_surface_guard.py',
        ).readAsStringSync(),
        allOf(
          contains('mode=ro'),
          contains('PRAGMA query_only=ON'),
          isNot(contains('INSERT INTO')),
          isNot(contains('UPDATE ')),
          isNot(contains('DELETE FROM')),
        ),
      );
    });
  });
}
