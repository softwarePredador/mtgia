import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/services/image_cache_policy.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';

import 'support/process_memory_stub.dart'
    if (dart.library.io) 'support/process_memory_io.dart'
    as process_memory;

const _fixtureBaseUrl = String.fromEnvironment(
  'MANALOOM_IMAGE_FIXTURE_BASE_URL',
);
const _imageCount = 180;
const _rssGrowthBudgetBytes = 192 * 1024 * 1024;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  }

  testWidgets('card image scroll stays inside memory and cache budgets', (
    tester,
  ) async {
    expect(_fixtureBaseUrl, isNotEmpty);
    AppImageCachePolicy.apply();
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
    await DefaultCacheManager().emptyCache();
    addTearDown(() async {
      cache.clear();
      cache.clearLiveImages();
      await DefaultCacheManager().emptyCache();
    });

    var peakCacheBytes = 0;
    var peakCacheEntries = 0;

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _ImageMemoryGrid())),
    );
    await tester.pump(const Duration(seconds: 1));

    final scrollable = find.byKey(const Key('image-memory-grid'));
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: scrollable, matching: find.byType(Scrollable)),
        )
        .position;
    final initialRss = process_memory.currentRssBytes();
    var peakRss = initialRss ?? 0;

    var steps = 0;
    while (position.pixels < position.maxScrollExtent && steps < 80) {
      await tester.drag(scrollable, const Offset(0, -520));
      await tester.pump(const Duration(milliseconds: 120));
      peakCacheBytes = peakCacheBytes < cache.currentSizeBytes
          ? cache.currentSizeBytes
          : peakCacheBytes;
      peakCacheEntries = peakCacheEntries < cache.currentSize
          ? cache.currentSize
          : peakCacheEntries;
      final rss = process_memory.currentRssBytes();
      if (rss != null && rss > peakRss) peakRss = rss;
      steps++;
    }
    await tester.pump(const Duration(seconds: 1));
    final firstPassSettledRss = process_memory.currentRssBytes();
    if (firstPassSettledRss != null && firstPassSettledRss > peakRss) {
      peakRss = firstPassSettledRss;
    }
    final firstPassPeakRss = peakRss;

    position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 300));
    var repeatSteps = 0;
    while (position.pixels < position.maxScrollExtent && repeatSteps < 80) {
      await tester.drag(scrollable, const Offset(0, -520));
      await tester.pump(const Duration(milliseconds: 120));
      peakCacheBytes = peakCacheBytes < cache.currentSizeBytes
          ? cache.currentSizeBytes
          : peakCacheBytes;
      peakCacheEntries = peakCacheEntries < cache.currentSize
          ? cache.currentSize
          : peakCacheEntries;
      final rss = process_memory.currentRssBytes();
      if (rss != null && rss > peakRss) peakRss = rss;
      repeatSteps++;
    }
    await tester.pump(const Duration(seconds: 1));
    final repeatSettledRss = process_memory.currentRssBytes();
    if (repeatSettledRss != null && repeatSettledRss > peakRss) {
      peakRss = repeatSettledRss;
    }

    final finalCacheEntries = cache.currentSize;
    final finalCacheBytes = cache.currentSizeBytes;
    final summary = <String, dynamic>{
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'image_count': _imageCount,
      'scroll_steps': steps,
      'repeat_scroll_steps': repeatSteps,
      'cache': <String, dynamic>{
        'peak_entries': peakCacheEntries,
        'peak_bytes': peakCacheBytes,
        'final_entries': finalCacheEntries,
        'final_bytes': finalCacheBytes,
        'entry_budget': AppImageCachePolicy.maximumLiveEntries,
        'byte_budget': AppImageCachePolicy.maximumBytes,
      },
      'rss': <String, dynamic>{
        'initial_bytes': initialRss,
        'peak_bytes': initialRss == null ? null : peakRss,
        'growth_bytes': initialRss == null ? null : peakRss - initialRss,
        'growth_budget_bytes': initialRss == null
            ? null
            : _rssGrowthBudgetBytes,
        'repeat_growth_bytes': initialRss == null
            ? null
            : peakRss - firstPassPeakRss,
        'repeat_growth_budget_bytes': initialRss == null
            ? null
            : AppImageCachePolicy.maximumBytes,
      },
    };
    binding.reportData = <String, dynamic>{'image_memory': summary};
    // ignore: avoid_print
    print('MANALOOM_IMAGE_MEMORY ${jsonEncode(summary)}');

    expect(position.pixels, greaterThan(0));
    expect(steps, greaterThan(10));
    expect(repeatSteps, greaterThan(10));
    expect(
      peakCacheEntries,
      greaterThan(0),
      reason: 'The memory gate is invalid when no image was decoded.',
    );
    expect(
      peakCacheBytes,
      greaterThan(0),
      reason: 'The memory gate is invalid when decoded bytes stay at zero.',
    );
    expect(
      find.byIcon(Icons.image_not_supported),
      findsNothing,
      reason: 'The visible image sample must load instead of using fallback.',
    );
    expect(
      finalCacheBytes,
      lessThanOrEqualTo(AppImageCachePolicy.maximumBytes),
    );
    expect(peakCacheBytes, lessThanOrEqualTo(AppImageCachePolicy.maximumBytes));
    expect(
      peakCacheEntries,
      lessThanOrEqualTo(AppImageCachePolicy.maximumLiveEntries),
    );
    if (initialRss != null) {
      expect(peakRss - initialRss, lessThanOrEqualTo(_rssGrowthBudgetBytes));
      expect(
        peakRss - firstPassPeakRss,
        lessThanOrEqualTo(AppImageCachePolicy.maximumBytes),
        reason: 'A repeated pass must reuse bounded caches instead of growing.',
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
    cache.clear();
    cache.clearLiveImages();
    await DefaultCacheManager().emptyCache();
  });
}

class _ImageMemoryGrid extends StatelessWidget {
  const _ImageMemoryGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const Key('image-memory-grid'),
      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 488 / 680,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _imageCount,
      itemBuilder: (_, index) => CachedCardImage(
        imageUrl:
            '$_fixtureBaseUrl/assets/symbols/logo.png?memory_sample=$index',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
