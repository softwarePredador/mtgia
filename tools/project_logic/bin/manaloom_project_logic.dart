import 'dart:io';

import 'package:manaloom_project_logic/project_logic_generator.dart';

const _requiredDartSdk = '3.12.2';

Future<void> main(List<String> arguments) async {
  try {
    final dartSdk = Platform.version.split(' ').first;
    if (dartSdk != _requiredDartSdk) {
      throw ProjectLogicException(
        'Project logic requires Dart $_requiredDartSdk; found $dartSdk.',
      );
    }

    final check = arguments.contains('--check');
    final write = arguments.contains('--write');
    if (check == write) {
      throw ProjectLogicException(
        'Select exactly one project logic mode: --check or --write.',
      );
    }
    final rootArgument = _valueAfter(arguments, '--root') ?? '../..';
    final root = _canonicalRoot(rootArgument);
    _validateTaskCacheEnvironment();
    await _bootstrapWorkspacePackages(root);

    final generator = ProjectLogicGenerator(root);
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

Directory _canonicalRoot(String value) {
  final absolute = Directory(value).absolute;
  if (!absolute.existsSync()) {
    throw ProjectLogicException(
      'Project root does not exist: ${absolute.path}',
    );
  }
  try {
    return Directory(absolute.resolveSymbolicLinksSync());
  } on FileSystemException catch (error) {
    throw ProjectLogicException(
      'Project root cannot be resolved physically: ${error.message}.',
    );
  }
}

void _validateTaskCacheEnvironment() {
  final pubCache = Platform.environment['PUB_CACHE'];
  final taskCache =
      Platform.environment['MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE'];
  if (pubCache == null ||
      pubCache.isEmpty ||
      taskCache == null ||
      taskCache.isEmpty) {
    throw ProjectLogicException(
      'Project logic requires a task-scoped PUB_CACHE.',
    );
  }
  String canonical(String value, String label) {
    final directory = Directory(value);
    if (!directory.existsSync()) {
      throw ProjectLogicException('$label does not exist: $value.');
    }
    try {
      return directory.resolveSymbolicLinksSync();
    } on FileSystemException catch (error) {
      throw ProjectLogicException(
        '$label cannot be resolved physically: ${error.message}.',
      );
    }
  }

  if (canonical(pubCache, 'PUB_CACHE') !=
      canonical(taskCache, 'MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE')) {
    throw ProjectLogicException(
      'PUB_CACHE must equal MANALOOM_PROJECT_LOGIC_TASK_PUB_CACHE.',
    );
  }
  final globalCache =
      Platform.environment['MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE'];
  if (globalCache != null &&
      globalCache.isNotEmpty &&
      canonical(globalCache, 'MANALOOM_PROJECT_LOGIC_GLOBAL_PUB_CACHE') ==
          canonical(pubCache, 'PUB_CACHE')) {
    throw ProjectLogicException(
      'Project logic task PUB_CACHE must not alias the global cache.',
    );
  }
}

Future<void> _bootstrapWorkspacePackages(Directory root) async {
  for (final relative in const ['', 'app', 'server']) {
    final directory = Directory(
      relative.isEmpty
          ? root.path
          : Directory.fromUri(root.uri.resolve('$relative/')).path,
    );
    final label = relative.isEmpty ? '.' : relative;
    for (final name in const ['pubspec.yaml', 'pubspec.lock']) {
      if (!File.fromUri(directory.uri.resolve(name)).existsSync()) {
        throw ProjectLogicException(
          'Required package input is missing: $label/$name.',
        );
      }
    }
    final result = await Process.run(
      Platform.resolvedExecutable,
      const [
        'pub',
        'get',
        '--offline',
        '--enforce-lockfile',
        '--no-precompile',
      ],
      workingDirectory: directory.path,
      includeParentEnvironment: true,
    );
    if (result.exitCode != 0) {
      throw ProjectLogicException(
        'Offline package bootstrap failed for $label: ${result.stderr}',
      );
    }
  }
}

String? _valueAfter(List<String> arguments, String flag) {
  final index = arguments.indexOf(flag);
  if (index == -1) return null;
  if (index + 1 >= arguments.length || arguments[index + 1].startsWith('--')) {
    throw ProjectLogicException('$flag requires a value.');
  }
  if (arguments.indexOf(flag, index + 1) != -1) {
    throw ProjectLogicException('$flag may be provided only once.');
  }
  return arguments[index + 1];
}
