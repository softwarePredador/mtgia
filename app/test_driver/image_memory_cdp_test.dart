import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  final environment = Platform.environment;
  final sessionId = environment['DRIVER_SESSION_ID'];
  final webdriverUrl = environment['DRIVER_SESSION_URI'];
  final capabilitiesJson = environment['DRIVER_SESSION_CAPABILITIES'];
  final fixtureStatsUrl = environment['MANALOOM_IMAGE_FIXTURE_STATS_URL'];
  final finalOutputPath =
      environment['MANALOOM_IMAGE_MEMORY_OUTPUT'] ??
      'build/manaloom_web_image_memory.json';
  if (sessionId == null || sessionId.isEmpty) {
    throw StateError('DRIVER_SESSION_ID was not provided by flutter drive.');
  }
  if (webdriverUrl == null || webdriverUrl.isEmpty) {
    throw StateError('DRIVER_SESSION_URI was not provided by flutter drive.');
  }
  if (capabilitiesJson == null || capabilitiesJson.isEmpty) {
    throw StateError(
      'DRIVER_SESSION_CAPABILITIES was not provided by flutter drive.',
    );
  }
  if (fixtureStatsUrl == null || fixtureStatsUrl.isEmpty) {
    throw StateError('MANALOOM_IMAGE_FIXTURE_STATS_URL was not provided.');
  }

  final monitorOutput = File(
    '${Directory.systemTemp.path}/'
    'manaloom_web_image_memory_${pid}_${DateTime.now().microsecondsSinceEpoch}.json',
  );
  final monitor = await Process.start('python3', <String>[
    'tool/measure_web_image_memory.py',
    '--webdriver-url',
    webdriverUrl,
    '--session-id',
    sessionId,
    '--capabilities-json',
    capabilitiesJson,
    '--fixture-stats-url',
    fixtureStatsUrl,
    '--output',
    monitorOutput.path,
  ]);
  final monitorStdout = monitor.stdout.transform(utf8.decoder).join();
  final monitorStderr = monitor.stderr.transform(utf8.decoder).join();

  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      final exitCode = await monitor.exitCode.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          monitor.kill();
          return 124;
        },
      );
      final monitorStdoutText = await monitorStdout;
      final monitorStderrText = await monitorStderr;
      Map<String, dynamic>? webCdp;
      if (monitorOutput.existsSync()) {
        webCdp =
            jsonDecode(await monitorOutput.readAsString())
                as Map<String, dynamic>;
      }

      final output = File(finalOutputPath);
      await output.parent.create(recursive: true);
      await output.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(<String, dynamic>{'flutter': data, 'web_cdp': webCdp})}\n',
      );
      if (monitorOutput.existsSync()) {
        await monitorOutput.delete();
      }

      if (exitCode != 0 || webCdp?['result'] != 'pass') {
        throw StateError(
          'Web image memory monitor failed with exit $exitCode.\n'
          'stdout:\n$monitorStdoutText\n'
          'stderr:\n$monitorStderrText',
        );
      }
      stdout.write(monitorStdoutText);
      if (monitorStderrText.isNotEmpty) {
        stderr.write(monitorStderrText);
      }
      stdout.writeln('Web image memory evidence: ${output.absolute.path}');
    },
  );
}
