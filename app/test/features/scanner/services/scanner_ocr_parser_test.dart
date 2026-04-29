import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/scanner/services/scanner_ocr_parser.dart';

void main() {
  group('ScannerOcrParser', () {
    test(
      'extracts card name and collector metadata from controlled OCR text',
      () {
        final result = ScannerOcrParser.parseControlledText('''
Lightning Bolt
Instant
157/274 ★ BLB ★ EN
''');

        expect(result.success, isTrue);
        expect(result.primaryName, 'Lightning Bolt');
        expect(result.setCodeCandidates, contains('BLB'));
        expect(result.setCodeCandidates, isNot(contains('EN')));
        expect(result.collectorInfo?.collectorNumber, '157');
        expect(result.collectorInfo?.totalInSet, '274');
        expect(result.collectorInfo?.setCode, 'BLB');
        expect(result.collectorInfo?.isFoil, isTrue);
        expect(result.collectorInfo?.language, 'EN');
      },
    );

    test('extracts non-foil collector metadata from modern bottom text', () {
      final collector = ScannerOcrParser.extractCollectorInfo(
        '0397/0400 • FIC • PT',
      );

      expect(collector?.collectorNumber, '0397');
      expect(collector?.totalInSet, '0400');
      expect(collector?.setCode, 'FIC');
      expect(collector?.isFoil, isFalse);
      expect(collector?.language, 'PT');
    });

    test('returns failed result for OCR text without a usable card name', () {
      final result = ScannerOcrParser.parseControlledText('''
157/274 • BLB • EN
© 2026 Wizards of the Coast
''');

      expect(result.success, isFalse);
      expect(result.error, contains('Nenhum nome valido'));
    });
  });
}
