import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/config/launch_features.dart';
import 'package:manaloom/features/scanner/models/card_recognition_result.dart';
import 'package:manaloom/features/scanner/services/card_recognition_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'physical back camera initializes and its frame is accepted by ML Kit',
    (tester) async {
      expect(
        LaunchFeatures.scannerEnabled,
        isTrue,
        reason: 'The physical proof must exercise a scanner-enabled build.',
      );
      final permission = await Permission.camera.request();
      expect(
        permission.isGranted,
        isTrue,
        reason: 'The physical scanner proof requires camera permission.',
      );

      final cameras = await availableCameras();
      expect(cameras, isNotEmpty);
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      final recognition = CardRecognitionService();

      try {
        await controller.initialize();
        expect(controller.value.isInitialized, isTrue);

        final frameCompleter = Completer<CameraImage>();
        await controller.startImageStream((frame) {
          if (!frameCompleter.isCompleted) frameCompleter.complete(frame);
        });
        final frame = await frameCompleter.future.timeout(
          const Duration(seconds: 20),
        );
        await controller.stopImageStream();

        expect(frame.width, greaterThan(0));
        expect(frame.height, greaterThan(0));
        expect(frame.planes, isNotEmpty);

        Object? conversionError;
        final result = await recognition.recognizeFromCameraImage(
          frame,
          backCamera,
          onError: (error) => conversionError = error,
        );
        expect(
          conversionError,
          isNull,
          reason: 'The production CameraImage → ML Kit conversion must work.',
        );
        expect(result, anyOf(isNull, isA<CardRecognitionResult>()));
      } finally {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
        await controller.dispose();
        recognition.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'physical ML Kit recognizes a controlled MTG card layout',
    (tester) async {
      final fixture = await _writeControlledCardFixture();
      final recognition = CardRecognitionService();
      try {
        final result = await recognition.recognizeCard(fixture);
        expect(result.success, isTrue, reason: result.error);
        expect(result.primaryName, 'Lightning Bolt');
        expect(result.setCodeCandidates, contains('BLB'));
      } finally {
        recognition.dispose();
        if (await fixture.exists()) await fixture.delete();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<File> _writeControlledCardFixture() async {
  const width = 630;
  const height = 880;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 630, 880),
    ui.Paint()..color = const ui.Color(0xFFF6F1E5),
  );
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(12, 12, 606, 856),
      const ui.Radius.circular(24),
    ),
    ui.Paint()
      ..color = const ui.Color(0xFF171717)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 12,
  );

  _paintText(canvas, 'Lightning Bolt', 44, 42, FontWeight.w700);
  _paintText(canvas, 'Instant', 54, 520, FontWeight.w600);
  _paintText(canvas, 'Lightning Bolt deals 3 damage to any target.', 54, 610);
  _paintText(canvas, '157/274   BLB   EN', 54, 816, FontWeight.w600);

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    throw StateError('Could not encode the controlled scanner fixture.');
  }

  final file = File(
    '${Directory.systemTemp.path}/manaloom_scanner_physical_fixture.png',
  );
  await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
  return file;
}

void _paintText(
  ui.Canvas canvas,
  String text,
  double left,
  double top, [
  FontWeight weight = FontWeight.w400,
]) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: text == 'Lightning Bolt' ? 52 : 32,
        fontWeight: weight,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 520);
  painter.paint(canvas, ui.Offset(left, top));
}
