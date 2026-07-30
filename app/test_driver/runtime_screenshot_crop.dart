import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class RuntimeScreenshotCropResult {
  const RuntimeScreenshotCropResult({
    required this.pngBytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.width,
    required this.height,
    required this.left,
    required this.right,
    required this.cropped,
  });

  final Uint8List pngBytes;
  final int originalWidth;
  final int originalHeight;
  final int width;
  final int height;
  final int left;
  final int right;
  final bool cropped;
}

RuntimeScreenshotCropResult cropSolidWebHostMargins(Uint8List pngBytes) {
  final image = img.decodePng(pngBytes);
  if (image == null) {
    throw const FormatException('Runtime screenshot is not a valid PNG.');
  }

  RuntimeScreenshotCropResult unchanged() => RuntimeScreenshotCropResult(
    pngBytes: pngBytes,
    originalWidth: image.width,
    originalHeight: image.height,
    width: image.width,
    height: image.height,
    left: 0,
    right: 0,
    cropped: false,
  );

  if (image.width < 336 || image.height < 568) return unchanged();

  final hostBackground = image.getPixel(0, 0);
  if (!_isNearWhite(hostBackground)) return unchanged();

  final sampleRows = <int>[
    0,
    image.height ~/ 4,
    image.height ~/ 2,
    (image.height * 3) ~/ 4,
    image.height - 1,
  ];

  bool belongsToFlutterSurface(int x) {
    var nonHostSamples = 0;
    for (final y in sampleRows) {
      if (!_matchesHostBackground(image.getPixel(x, y), hostBackground)) {
        nonHostSamples++;
      }
    }
    return nonHostSamples >= 3;
  }

  int? firstSurfaceColumn;
  int? lastSurfaceColumn;
  for (var x = 0; x < image.width; x++) {
    if (!belongsToFlutterSurface(x)) continue;
    firstSurfaceColumn ??= x;
    lastSurfaceColumn = x;
  }
  if (firstSurfaceColumn == null || lastSurfaceColumn == null) {
    return unchanged();
  }

  final detectedLeftMargin = firstSurfaceColumn;
  final detectedRightMargin = image.width - lastSurfaceColumn - 1;
  final symmetryTolerance = math.max(4, (image.width * 0.005).round());
  if (detectedLeftMargin < 8 ||
      detectedRightMargin < 8 ||
      (detectedLeftMargin - detectedRightMargin).abs() >
          symmetryTolerance) {
    return unchanged();
  }

  // The Flutter surface is centred by the Web test host. Animated splash
  // shadows can temporarily paint a few pixels into only one host margin and
  // make content-bound detection wider than the actual viewport. Cropping by
  // the larger symmetric margin preserves the physical viewport and excludes
  // that host-only spill.
  final hostMargin = math.max(detectedLeftMargin, detectedRightMargin);
  final croppedWidth = image.width - (hostMargin * 2);
  if (croppedWidth < 320 || croppedWidth >= image.width) return unchanged();

  final cropped = img.copyCrop(
    image,
    x: hostMargin,
    y: 0,
    width: croppedWidth,
    height: image.height,
  );
  return RuntimeScreenshotCropResult(
    pngBytes: img.encodePng(cropped),
    originalWidth: image.width,
    originalHeight: image.height,
    width: cropped.width,
    height: cropped.height,
    left: hostMargin,
    right: hostMargin,
    cropped: true,
  );
}

bool _isNearWhite(img.Pixel pixel) {
  return pixel.r >= 248 && pixel.g >= 248 && pixel.b >= 248 && pixel.a >= 248;
}

bool _matchesHostBackground(img.Pixel pixel, img.Pixel background) {
  const tolerance = 3;
  return (pixel.r - background.r).abs() <= tolerance &&
      (pixel.g - background.g).abs() <= tolerance &&
      (pixel.b - background.b).abs() <= tolerance &&
      (pixel.a - background.a).abs() <= tolerance;
}
