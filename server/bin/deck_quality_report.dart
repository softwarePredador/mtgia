/// Deterministic deck-quality gate.
///
/// Scores every deck in a committed fixture with `buildDeckQualityReport`
/// and compares the result against a committed baseline. Because
/// `GoldfishSimulator` seeds from a stable deck hash, identical input always
/// produces an identical score -- so any difference is a real behavioural
/// change in the scoring path, never flakiness. Tolerance is therefore 0.
///
/// This binary touches no network, no LLM and no database.
///
/// Usage:
///   dart run bin/deck_quality_report.dart --check
///   dart run bin/deck_quality_report.dart --update-baseline
///   dart run bin/deck_quality_report.dart --check --json-out=/tmp/report.json
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:server/ai/deck_quality_report.dart';

const _baselineSchemaVersion = 'deck_quality_baseline_v1';
const _defaultFixture = 'test/fixtures/deck_quality_fixture.json';
const _defaultBaseline = 'test/fixtures/deck_quality_baseline.json';

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

Map<String, dynamic> _readJsonObject(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('file not found: $path');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Digest computed here, over the parsed deck content, rather than trusting
/// the `content_digest_sha256` the fixture carries. A hand-edited fixture
/// keeps its stale stored digest, so trusting that field would let an edit
/// slip past the integrity check.
///
/// `oracle_text` is included deliberately: it is the SOLE input for colour
/// sources on every non-basic land, so omitting it let an edit that flips a
/// colour verdict pass the digest unnoticed.
String _computeDeckDigest(List<Map<String, dynamic>> decks) {
  final canonical = jsonEncode([
    for (final deck in decks)
      {
        'deck_id': deck['deck_id'],
        'cards': [
          for (final card in (deck['cards'] as List).cast<Map<String, dynamic>>())
            {
              'name': card['name'],
              'quantity': card['quantity'],
              'type_line': card['type_line'],
              'mana_cost': card['mana_cost'],
              'cmc': card['cmc'],
              'oracle_text': card['oracle_text'],
            },
        ],
      },
  ]);
  return sha256.convert(utf8.encode(canonical)).toString();
}

/// The subset of a report that the baseline pins. Deliberately narrow: the
/// full simulation payload carries floating-point rates whose last digits
/// would make the gate noisy without adding signal.
Map<String, dynamic> _baselineEntry(Map<String, dynamic> report) {
  final mana = report['mana_foundation'] as Map<String, dynamic>;
  return {
    'consistency_score': report['consistency_score'],
    'land_count': mana['land_count'],
    'mana_foundation_satisfied': mana['satisfied'],
    'total_strict_pips': report['total_strict_pips'],
    'issue_codes': report['issue_codes'],
  };
}

void _printUsage() {
  stdout.writeln('''
Deterministic deck-quality gate.

  --check                  score the fixture and compare to the baseline (default)
  --update-baseline        rewrite the baseline from the current scoring
  --fixture=<path>         default: $_defaultFixture
  --baseline=<path>        default: $_defaultBaseline
  --json-out=<path>        also write the full per-deck report
  --simulations=<n>        default: 1000

Exit 0 when the baseline matches, 1 on any drift or failure.
''');
}

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final fixturePath = _readArg(args, '--fixture=') ?? _defaultFixture;
  final baselinePath = _readArg(args, '--baseline=') ?? _defaultBaseline;
  final jsonOut = _readArg(args, '--json-out=');
  final simulationsArg = _readArg(args, '--simulations=');
  final simulations = simulationsArg == null ? 1000 : int.tryParse(simulationsArg) ?? -1;
  if (simulations <= 0) {
    // Silently falling back would green-light a run the operator did not ask
    // for; 0 or a negative makes GoldfishSimulator divide by zero and throw a
    // stack trace instead of failing as a gate.
    stderr.writeln('invalid --simulations=${simulationsArg ?? ''}: expected a positive integer');
    exit(1);
  }
  final updateBaseline = args.contains('--update-baseline');

  // A gate must fail readably. An unguarded cast here surfaced as exit 255
  // plus a Dart stack trace, which reads as tooling breakage rather than as
  // a verdict.
  late final Map<String, dynamic> fixture;
  late final List<Map<String, dynamic>> decks;
  try {
    fixture = _readJsonObject(fixturePath);
    final raw = fixture['decks'];
    if (raw is! List) {
      throw StateError("fixture key 'decks' must be a list, got ${raw.runtimeType}");
    }
    decks = raw.cast<Map<String, dynamic>>();
  } on Object catch (error) {
    stderr.writeln('cannot read fixture $fixturePath: $error');
    exit(1);
  }
  if (decks.isEmpty) {
    stderr.writeln('fixture contains no decks: $fixturePath');
    exit(1);
  }
  final duplicateIds =
      decks.length - decks.map((d) => d['deck_id'].toString()).toSet().length;
  if (duplicateIds > 0) {
    // Reports are keyed by deck_id; duplicates would silently collapse and
    // shrink the corpus without the gate noticing.
    stderr.writeln('fixture has $duplicateIds duplicate deck_id(s)');
    exit(1);
  }

  final reports = <String, Map<String, dynamic>>{};
  final entries = <String, dynamic>{};
  for (final deck in decks) {
    final key = deck['deck_id'].toString();
    final cards = (deck['cards'] as List).cast<Map<String, dynamic>>();
    final report = buildDeckQualityReport(
      cards: cards,
      simulations: simulations,
    );
    report['deck_id'] = deck['deck_id'];
    report['deck_name'] = deck['deck_name'];
    report['commander'] = deck['commander'];
    reports[key] = report;
    entries[key] = _baselineEntry(report);
  }

  final computedDigest = _computeDeckDigest(decks);

  final payload = {
    'schema_version': _baselineSchemaVersion,
    'report_schema_version': deckQualityReportSchemaVersion,
    'fixture_content_digest_sha256': computedDigest,
    'fixture_declared_digest_sha256': fixture['content_digest_sha256'],
    'simulations': simulations,
    'deck_count': decks.length,
    'decks': entries,
  };

  if (jsonOut != null) {
    File(jsonOut)
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(reports)}\n',
      );
  }

  if (updateBaseline) {
    File(baselinePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
      );
    stdout.writeln('baseline written: $baselinePath (${decks.length} decks)');
    return;
  }

  if (!File(baselinePath).existsSync()) {
    stderr.writeln(
      'baseline not found: $baselinePath\n'
      'Run with --update-baseline to create it, then review the diff.',
    );
    exit(1);
  }

  final baseline = _readJsonObject(baselinePath);
  final failures = <String>[];

  if (baseline['fixture_content_digest_sha256'] != computedDigest) {
    failures.add(
      'fixture content changed: baseline='
      '${baseline['fixture_content_digest_sha256']} current=$computedDigest',
    );
  }
  if (baseline['simulations'] != simulations) {
    failures.add(
      'simulations differ: baseline=${baseline['simulations']} run=$simulations',
    );
  }

  final baselineDecks = (baseline['decks'] as Map).cast<String, dynamic>();
  for (final key in {...baselineDecks.keys, ...entries.keys}.toList()..sort()) {
    final expected = baselineDecks[key];
    final actual = entries[key];
    if (expected == null) {
      failures.add('deck $key present in run but missing from baseline');
      continue;
    }
    if (actual == null) {
      failures.add('deck $key present in baseline but missing from run');
      continue;
    }
    final expectedJson = jsonEncode(expected);
    final actualJson = jsonEncode(actual);
    if (expectedJson != actualJson) {
      failures.add('deck $key drifted\n  baseline: $expectedJson\n  current:  $actualJson');
    }
  }

  final scores = reports.values
      .map((r) => r['consistency_score'] as int)
      .toList()
    ..sort();
  final withIssues =
      reports.values.where((r) => (r['issue_codes'] as List).isNotEmpty).length;

  stdout.writeln('decks scored: ${reports.length}');
  stdout.writeln(
    'consistency_score: min=${scores.first} median=${scores[scores.length ~/ 2]} max=${scores.last}',
  );
  stdout.writeln('decks with issues: $withIssues/${reports.length}');

  if (failures.isEmpty) {
    stdout.writeln('PASS: baseline matches');
    return;
  }

  stderr.writeln('\nFAIL: ${failures.length} drift(s)');
  for (final failure in failures) {
    stderr.writeln('  - $failure');
  }
  exit(1);
}
