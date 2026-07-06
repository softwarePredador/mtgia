import 'dart:convert';
import 'dart:io';

import 'package:server/ai/commander_ai_prompt_eval_suite.dart';

void main(List<String> args) {
  final options = _parseArgs(args);
  if (options.containsKey('help')) {
    _printUsage();
    return;
  }

  final fixturePath = options['fixtures'] ??
      'test/fixtures/commander_ai_prompt_eval_cases.json';
  final suite = loadCommanderAiPromptEvalFixture(fixturePath);
  final responsePath = options['response'];
  final responseOverride = responsePath == null
      ? null
      : jsonDecode(File(responsePath).readAsStringSync())
          as Map<String, dynamic>;
  final minimumScore = options['minimum-score'] == null
      ? null
      : int.tryParse(options['minimum-score']!);

  final report = evaluateCommanderAiPromptSuite(
    suite,
    responseOverride: responseOverride,
    onlyCaseId: options['case'],
    minimumScoreOverride: minimumScore,
  );

  final outPrefix = options['out-prefix'];
  if (outPrefix != null && outPrefix.trim().isNotEmpty) {
    File('$outPrefix.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
    File('$outPrefix.md')
      ..createSync(recursive: true)
      ..writeAsStringSync(commanderAiPromptEvalMarkdown(report));
  }

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  if (report['status'] != 'pass') {
    exitCode = 1;
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '-h' || arg == '--help') {
      options['help'] = '1';
      continue;
    }
    if (!arg.startsWith('--')) {
      throw ArgumentError('Unexpected argument: $arg');
    }
    final withoutPrefix = arg.substring(2);
    if (withoutPrefix.contains('=')) {
      final parts = withoutPrefix.split('=');
      options[parts.first] = parts.sublist(1).join('=');
      continue;
    }
    if (i + 1 >= args.length || args[i + 1].startsWith('--')) {
      options[withoutPrefix] = '1';
      continue;
    }
    options[withoutPrefix] = args[++i];
  }
  return options;
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run bin/commander_ai_prompt_eval.dart [options]

Options:
  --fixtures <path>      Fixture suite path.
  --case <id>            Evaluate one fixture case.
  --response <path>      Override candidate_response for the selected case.
  --minimum-score <int>  Override suite minimum score.
  --out-prefix <path>    Write <path>.json and <path>.md reports.
''');
}
