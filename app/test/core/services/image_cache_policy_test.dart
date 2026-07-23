import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/services/image_cache_policy.dart';

void main() {
  test('applies bounded global memory cache policy', () {
    final cache = ImageCache();

    AppImageCachePolicy.apply(cache: cache);

    expect(cache.maximumSize, AppImageCachePolicy.maximumLiveEntries);
    expect(cache.maximumSizeBytes, AppImageCachePolicy.maximumBytes);
  });

  test('buckets physical decode width and caps oversized artwork', () {
    final thumbnail = AppImageCachePolicy.targetFor(
      width: 60,
      height: 84,
      devicePixelRatio: 3,
    );
    final artwork = AppImageCachePolicy.targetFor(
      width: double.infinity,
      constrainedWidth: 315,
      devicePixelRatio: 3,
    );
    final gridThumbnail = AppImageCachePolicy.targetFor(
      constrainedWidth: 120,
      devicePixelRatio: 3,
    );
    final oversized = AppImageCachePolicy.targetFor(
      width: 4000,
      devicePixelRatio: 4,
    );

    expect(thumbnail.width, 256);
    expect(thumbnail.height, isNull);
    expect(
      gridThumbnail.width,
      AppImageCachePolicy.maximumThumbnailDecodeDimension,
    );
    expect(artwork.width, 1024);
    expect(oversized.width, AppImageCachePolicy.maximumDecodeDimension);
  });

  test('falls back to height when width is unbounded', () {
    final target = AppImageCachePolicy.targetFor(
      constrainedWidth: double.infinity,
      constrainedHeight: 64,
      devicePixelRatio: 2,
    );

    expect(target.width, isNull);
    expect(target.height, 128);
  });
}
