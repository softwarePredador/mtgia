import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final screenshotDir = Platform.environment['MANALOOM_SCREENSHOT_DIR'];

  final driver = await FlutterDriver.connect();
  return integrationDriver(
    driver: driver,
    onScreenshot: (name, screenshotBytes, [args]) async {
      if (screenshotDir == null || screenshotDir.trim().isEmpty) {
        return true;
      }

      final directory = Directory(screenshotDir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final file = File('${directory.path}/$safeName.png');
      await file.writeAsBytes(screenshotBytes);
      return true;
    },
  );
}
