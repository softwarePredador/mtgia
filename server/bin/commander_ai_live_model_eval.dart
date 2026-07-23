import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:server/ai/commander_ai_live_eval_support.dart';
import 'package:server/ai/commander_ai_prompt_eval_suite.dart';
import 'package:server/runtime_environment.dart';

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final envPath = options['env'] ?? '.env';
  final env = loadRuntimeEnvironment(filenames: [envPath]);
  final apiKey = env['OPENAI_API_KEY']?.trim();
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('OPENAI_API_KEY is required.');
    exitCode = 2;
    return;
  }

  final fixturePath =
      options['fixtures'] ??
      'test/fixtures/commander_ai_prompt_eval_cases.json';
  final suite = loadCommanderAiPromptEvalFixture(fixturePath);
  final caseFilter = options['case']?.trim();
  final cases = ((suite['cases'] as List).cast<Map<String, dynamic>>())
      .where(
        (testCase) =>
            caseFilter == null || testCase['id']?.toString() == caseFilter,
      )
      .toList(growable: false);
  if (cases.isEmpty) {
    stderr.writeln('No eval case matched: ${caseFilter ?? '(none)'}');
    exitCode = 2;
    return;
  }

  final models = (options['models'] ?? 'gpt-4o-mini,gpt-5.4-mini')
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  final systemPrompt =
      File(options['system-prompt'] ?? 'lib/ai/prompt.md').readAsStringSync();
  final client = http.Client();
  final results = <Map<String, dynamic>>[];
  try {
    for (final model in models) {
      for (final testCase in cases) {
        results.add(
          await runCommanderAiLiveEvalCase(
            client: client,
            apiKey: apiKey,
            model: model,
            systemPrompt: systemPrompt,
            testCase: testCase,
          ),
        );
      }
    }
  } finally {
    client.close();
  }

  final summary = summarizeCommanderAiLiveEvalResults(results);

  final outputResults =
      options.containsKey('summary-only')
          ? results
              .map((row) {
                final evaluation = row['evaluation'] as Map?;
                return <String, dynamic>{
                  'status': row['status'],
                  'case_id': row['case_id'],
                  'intensity': row['intensity'],
                  'model_requested': row['model_requested'],
                  'model_returned': row['model_returned'],
                  'latency_ms': row['latency_ms'],
                  'usage': row['usage'],
                  'evaluation_status': evaluation?['status'],
                  'score': evaluation?['score'],
                  'failure_codes': _failureCodes(evaluation),
                  'error_code': row['error_code'],
                };
              })
              .toList(growable: false)
          : results;

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'schema_version': 'commander_ai_live_model_eval_v2_2026_07_22',
      'summary': summary,
      'results': outputResults,
    }),
  );
  if (commanderAiLiveEvalShouldFail(
    results,
    allowQualityFailures: options.containsKey('allow-failures'),
  )) {
    exitCode = 1;
  }
}

List<String> _failureCodes(Map<dynamic, dynamic>? evaluation) {
  final failures = evaluation?['failures'];
  if (failures is! List) return const [];
  return failures
      .whereType<Map>()
      .map((failure) => failure['code']?.toString() ?? '')
      .where((code) => code.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (!arg.startsWith('--')) throw ArgumentError('Unexpected arg: $arg');
    final key = arg.substring(2);
    if (index + 1 >= args.length || args[index + 1].startsWith('--')) {
      result[key] = 'true';
    } else {
      result[key] = args[++index];
    }
  }
  return result;
}
