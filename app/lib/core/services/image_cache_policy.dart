import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class ImageDecodeTarget {
  const ImageDecodeTarget({this.width, this.height});

  final int? width;
  final int? height;
}

class AppImageCachePolicy {
  static const int maximumLiveEntries = 96;
  static const int maximumBytes = 32 * 1024 * 1024;
  static const int maximumThumbnailDecodeDimension = 256;
  static const double maximumThumbnailLogicalWidth = 180;
  static const int maximumDecodeDimension = 1400;
  static const List<int> decodeBuckets = <int>[
    128,
    256,
    384,
    512,
    768,
    1024,
    maximumDecodeDimension,
  ];

  static void apply({ImageCache? cache}) {
    final target = cache ?? PaintingBinding.instance.imageCache;
    target.maximumSize = maximumLiveEntries;
    target.maximumSizeBytes = maximumBytes;
  }

  static ImageDecodeTarget targetFor({
    double? width,
    double? height,
    double? constrainedWidth,
    double? constrainedHeight,
    required double devicePixelRatio,
  }) {
    final logicalWidth =
        _finitePositive(width) ?? _finitePositive(constrainedWidth);
    if (logicalWidth != null) {
      final physicalWidth = logicalWidth * devicePixelRatio.clamp(1, 4);
      return ImageDecodeTarget(
        width: _bucket(
          logicalWidth <= maximumThumbnailLogicalWidth
              ? physicalWidth
                    .clamp(1, maximumThumbnailDecodeDimension)
                    .toDouble()
              : physicalWidth,
        ),
      );
    }

    final logicalHeight =
        _finitePositive(height) ?? _finitePositive(constrainedHeight);
    if (logicalHeight != null) {
      return ImageDecodeTarget(
        height: _bucket(logicalHeight * devicePixelRatio.clamp(1, 4)),
      );
    }

    return const ImageDecodeTarget();
  }

  static double? _finitePositive(double? value) {
    if (value == null || !value.isFinite || value <= 0) return null;
    return value;
  }

  static int _bucket(double value) {
    final pixels = value.ceil().clamp(1, maximumDecodeDimension);
    return decodeBuckets.firstWhere(
      (bucket) => pixels <= bucket,
      orElse: () => maximumDecodeDimension,
    );
  }
}
