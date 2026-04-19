import 'dart:io';

import '../.dart_frog/server.dart' as generated;

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await generated.createServer(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Local test server listening on http://127.0.0.1:$port');
  await ProcessSignal.sigint.watch().first;
  await server.close(force: true);
}
