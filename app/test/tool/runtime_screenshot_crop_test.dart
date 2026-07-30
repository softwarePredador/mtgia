import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../test_driver/runtime_screenshot_crop.dart';

void main() {
  test('crops symmetric white host margins around the Flutter surface', () {
    final screenshot = img.Image(width: 1600, height: 881);
    img.fill(screenshot, color: img.ColorRgb8(255, 255, 255));
    img.fillRect(
      screenshot,
      x1: 596,
      y1: 0,
      x2: 1003,
      y2: 880,
      color: img.ColorRgb8(15, 17, 21),
    );

    final result = cropSolidWebHostMargins(img.encodePng(screenshot));

    expect(result.cropped, isTrue);
    expect(result.originalWidth, 1600);
    expect(result.originalHeight, 881);
    expect(result.width, 408);
    expect(result.height, 881);
    expect(result.left, 596);
    expect(result.right, 596);
    expect(img.decodePng(result.pngBytes)?.width, 408);
  });

  test('keeps a full dark app screenshot unchanged', () {
    final screenshot = img.Image(width: 1080, height: 2408);
    img.fill(screenshot, color: img.ColorRgb8(15, 17, 21));
    final encoded = img.encodePng(screenshot);

    final result = cropSolidWebHostMargins(encoded);

    expect(result.cropped, isFalse);
    expect(result.width, 1080);
    expect(result.height, 2408);
    expect(result.pngBytes, same(encoded));
  });

  test('ignores an animated splash spill outside the centred viewport', () {
    final screenshot = img.Image(width: 500, height: 844);
    img.fill(screenshot, color: img.ColorRgb8(251, 251, 251));
    img.fillRect(
      screenshot,
      x1: 55,
      y1: 0,
      x2: 444,
      y2: 843,
      color: img.ColorRgb8(8, 9, 14),
    );
    for (final y in <int>[211, 422, 633]) {
      img.fillRect(
        screenshot,
        x1: 52,
        y1: y - 2,
        x2: 54,
        y2: y + 2,
        color: img.ColorRgb8(30, 22, 12),
      );
    }

    final result = cropSolidWebHostMargins(img.encodePng(screenshot));
    final cropped = img.decodePng(result.pngBytes)!;

    expect(result.cropped, isTrue);
    expect(result.width, 390);
    expect(result.left, 55);
    expect(result.right, 55);
    expect(cropped.getPixel(0, 0).r, 8);
    expect(cropped.getPixel(389, 843).r, 8);
  });

  test(
    'refuses an asymmetric white layout instead of cropping app content',
    () {
      final screenshot = img.Image(width: 800, height: 700);
      img.fill(screenshot, color: img.ColorRgb8(255, 255, 255));
      img.fillRect(
        screenshot,
        x1: 20,
        y1: 0,
        x2: 699,
        y2: 699,
        color: img.ColorRgb8(15, 17, 21),
      );

      final result = cropSolidWebHostMargins(img.encodePng(screenshot));

      expect(result.cropped, isFalse);
      expect(result.width, 800);
      expect(result.height, 700);
    },
  );
}
