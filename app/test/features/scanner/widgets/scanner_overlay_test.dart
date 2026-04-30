import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/scanner/widgets/scanner_overlay.dart';

void main() {
  group('ScannerGuideGeometry', () {
    test('keeps the visual guide on MTG card proportions', () {
      final rect = ScannerGuideGeometry.cardRectForSize(const Size(390, 844));

      expect(rect.width, closeTo(253.5, 0.01));
      expect(rect.height / rect.width, closeTo(88 / 63, 0.0001));
      expect(rect.left, closeTo((390 - 253.5) / 2, 0.01));
      expect(rect.top, closeTo((844 - rect.height) / 2 - 30, 0.01));
    });
  });
}
