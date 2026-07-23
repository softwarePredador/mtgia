import 'dart:io';

import 'package:manaloom_project_logic/project_logic_generator.dart';

const _requiredDartSdk = '3.12.2';

Future<void> main(List<String> arguments) async {
  final dartSdk = Platform.version.split(' ').first;
  if (dartSdk != _requiredDartSdk) {
    stderr.writeln(
      'Project logic requires Dart $_requiredDartSdk; found $dartSdk.',
    );
    exitCode = 2;
    return;
  }

  final check = arguments.contains('--check');
  final write = arguments.contains('--write') || !check;
  final rootArgument = _valueAfter(arguments, '--root') ?? '../..';
  final root = Directory(rootArgument).absolute;

  if (!root.existsSync()) {
    stderr.writeln('Project root does not exist: ${root.path}');
    exitCode = 2;
    return;
  }

  final generator = ProjectLogicGenerator(root);
  try {
    final result = await generator.generate();
    if (check) {
      final drift = result.driftedFiles();
      if (drift.isNotEmpty) {
        stderr.writeln('Project logic documentation drift detected:');
        for (final path in drift) {
          stderr.writeln(' - $path');
        }
        stderr.writeln(
          'Run scripts/manaloom_project_logic.sh --write and review the diff.',
        );
        exitCode = 1;
        return;
      }
      stdout.writeln(
        'Project logic is synchronized (${result.outputs.length} artifacts).',
      );
      return;
    }

    if (write) {
      result.write();
      stdout.writeln(
        'Generated ${result.outputs.length} project logic artifacts.',
      );
    }
  } on ProjectLogicException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}

String? _valueAfter(List<String> arguments, String flag) {
  final index = arguments.indexOf(flag);
  if (index == -1 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}
