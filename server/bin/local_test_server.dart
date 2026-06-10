import 'dart:io';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final entrypoint = File('.dart_frog/server.dart');
  if (!entrypoint.existsSync()) {
    stderr.writeln(
      'Dart Frog generated server not found at ${entrypoint.path}. '
      'Run `dart_frog build` or use `dart_frog dev` before starting this wrapper.',
    );
    exitCode = 64;
    return;
  }

  final child = await Process.start(
    Platform.resolvedExecutable,
    ['run', entrypoint.path],
    environment: {
      ...Platform.environment,
      'PORT': '$port',
    },
  );

  child.stdout.listen(stdout.add);
  child.stderr.listen(stderr.add);
  stdout.writeln('Local test server listening on http://127.0.0.1:$port');

  final exitCodeFuture = child.exitCode;
  final stopSignalFuture = Future.any<void>([
    ProcessSignal.sigint.watch().first.then((_) {}),
    ProcessSignal.sigterm.watch().first.then((_) {}),
  ]);
  final result = await Future.any<Object?>([
    exitCodeFuture,
    stopSignalFuture,
  ]);

  if (result is int) {
    exitCode = result;
    return;
  }

  child.kill();
  exitCode = await exitCodeFuture;
}
