import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

import 'runtime_screenshot_crop.dart';

Future<void> main() async {
  final screenshotDir = Platform.environment['MANALOOM_SCREENSHOT_DIR'];
  final driver = await FlutterDriver.connect();

  return integrationDriver(
    driver: driver,
    writeResponseOnFailure: true,
    onScreenshot: (name, screenshotBytes, [args]) async {
      if (screenshotDir == null || screenshotDir.trim().isEmpty) {
        return false;
      }

      final directory = Directory(screenshotDir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
      final file = File('${directory.path}/$safeName.png');
      final crop = cropSolidWebHostMargins(Uint8List.fromList(screenshotBytes));
      await file.writeAsBytes(crop.pngBytes, flush: true);
      if (crop.cropped) {
        stdout.writeln(
          'SCREENSHOT_VIEWPORT_CROP $safeName '
          'original=${crop.originalWidth}x${crop.originalHeight} '
          'result=${crop.width}x${crop.height} '
          'left=${crop.left} right=${crop.right}',
        );
      }
      return true;
    },
  );
}
