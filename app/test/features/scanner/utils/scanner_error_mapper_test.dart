import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/scanner/utils/scanner_error_mapper.dart';

void main() {
  group('ScannerErrorMapper', () {
    test('hides technical camera exception and gives a recovery action', () {
      final message = ScannerErrorMapper.friendly(
        Exception('CameraException(cameraInUse, AVFoundation -11800)'),
        stage: ScannerErrorStage.camera,
      );

      expect(message, contains('outro app'));
      expect(message, isNot(contains('CameraException')));
      expect(message, isNot(contains('AVFoundation')));
    });

    test('maps transport exception to connection guidance', () {
      final message = ScannerErrorMapper.friendly(
        Exception('SocketException: Failed host lookup api.example.test'),
        stage: ScannerErrorStage.search,
      );

      expect(message, contains('reconecte'));
      expect(message, contains('continuam nesta tela'));
      expect(message, isNot(contains('SocketException')));
      expect(message, isNot(contains('api.example.test')));
    });

    test('uses image guidance for unknown OCR errors', () {
      final message = ScannerErrorMapper.friendly(
        StateError('native OCR pipeline failed'),
        stage: ScannerErrorStage.processing,
      );

      expect(message, contains('Melhore a iluminação'));
      expect(message, isNot(contains('pipeline')));
    });
  });
}
