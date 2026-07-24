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
import 'support/web_image_memory_probe_stub.dart'
    if (dart.library.js_interop) 'support/web_image_memory_probe_web.dart'
    as web_probe;

const _fixtureBaseUrl = String.fromEnvironment(
  'MANALOOM_IMAGE_FIXTURE_BASE_URL',
);
const _imageCount = 180;
const _rssGrowthBudgetBytes = 192 * 1024 * 1024;
const _loadingPlaceholderKey = Key('image-memory-loading');
const _webCdpProbeEnabled = bool.fromEnvironment(
  'MANALOOM_ENABLE_WEB_CDP_IMAGE_PROBE',
);

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

    if (kIsWeb) {
      expect(
        _webCdpProbeEnabled,
        isTrue,
        reason:
            'Web image memory must run with the external Chrome/CDP probe; '
            'PaintingBinding.imageCache is not a valid HtmlImage metric.',
      );
      web_probe.markWebImageMemoryPhase('awaiting_cdp');
      expect(
        await web_probe.waitForWebImageMemoryProbeReady(),
        isTrue,
        reason: 'The external Chrome/CDP probe did not attach.',
      );
      await _webCheckpoint('baseline');
    }

    var peakCacheBytes = 0;
    var peakCacheEntries = 0;
    var peakVisibleImageFallbackCount = 0;
    var loadingTimeoutCount = 0;

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _ImageMemoryGrid())),
    );
    final initialSettlement = await _settleVisibleImages(tester);
    peakVisibleImageFallbackCount = initialSettlement.fallbackCount;
    if (initialSettlement.timedOut) loadingTimeoutCount++;

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
      final settlement = await _settleVisibleImages(tester);
      if (settlement.fallbackCount > peakVisibleImageFallbackCount) {
        peakVisibleImageFallbackCount = settlement.fallbackCount;
      }
      if (settlement.timedOut) loadingTimeoutCount++;
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
    await tester.pump(const Duration(milliseconds: 300));
    final firstPassSettledRss = process_memory.currentRssBytes();
    if (firstPassSettledRss != null && firstPassSettledRss > peakRss) {
      peakRss = firstPassSettledRss;
    }
    final firstPassPeakRss = peakRss;
    if (kIsWeb) {
      await _webCheckpoint('first_pass');
    }

    position.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 300));
    var repeatSteps = 0;
    while (position.pixels < position.maxScrollExtent && repeatSteps < 80) {
      await tester.drag(scrollable, const Offset(0, -520));
      await tester.pump(const Duration(milliseconds: 120));
      final settlement = await _settleVisibleImages(tester);
      if (settlement.fallbackCount > peakVisibleImageFallbackCount) {
        peakVisibleImageFallbackCount = settlement.fallbackCount;
      }
      if (settlement.timedOut) loadingTimeoutCount++;
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
    await tester.pump(const Duration(milliseconds: 300));
    final repeatSettledRss = process_memory.currentRssBytes();
    if (repeatSettledRss != null && repeatSettledRss > peakRss) {
      peakRss = repeatSettledRss;
    }
    if (kIsWeb) {
      await _webCheckpoint('repeat_pass');
    }

    final finalCacheEntries = cache.currentSize;
    final finalCacheBytes = cache.currentSizeBytes;
    final finalScrollPixels = position.pixels;
    final summary = <String, dynamic>{
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'metric_source': kIsWeb
          ? 'external_chrome_cdp_process_tree_and_resource_timing'
          : 'flutter_image_cache_and_process_rss',
      'image_count': _imageCount,
      'scroll_steps': steps,
      'repeat_scroll_steps': repeatSteps,
      'visible_image_fallback_count': peakVisibleImageFallbackCount,
      'loading_timeout_count': loadingTimeoutCount,
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

    Object? cleanupError;
    StackTrace? cleanupStackTrace;
    try {
      await tester.pumpWidget(const SizedBox.shrink());
      cache.clear();
      cache.clearLiveImages();
      await DefaultCacheManager().emptyCache();
    } catch (error, stackTrace) {
      cleanupError = error;
      cleanupStackTrace = stackTrace;
    } finally {
      if (kIsWeb) {
        await _webCheckpoint('cleaned');
      }
    }
    if (cleanupError != null && cleanupStackTrace != null) {
      Error.throwWithStackTrace(cleanupError, cleanupStackTrace);
    }

    expect(finalScrollPixels, greaterThan(0));
    expect(steps, greaterThan(10));
    expect(repeatSteps, greaterThan(10));
    if (!kIsWeb) {
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
    }
    expect(
      peakVisibleImageFallbackCount,
      0,
      reason: 'The visible image sample must load instead of using fallback.',
    );
    expect(
      loadingTimeoutCount,
      0,
      reason: 'Every visible image viewport must finish loading before scroll.',
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
  });
}

Future<({int fallbackCount, bool timedOut})> _settleVisibleImages(
  WidgetTester tester,
) async {
  await tester.pump(const Duration(milliseconds: 300));
  const attempts = 20;
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byKey(_loadingPlaceholderKey).evaluate().isEmpty) {
      return (
        fallbackCount: find
            .byIcon(Icons.image_not_supported)
            .hitTestable()
            .evaluate()
            .length,
        timedOut: false,
      );
    }
  }
  return (
    fallbackCount: find
        .byIcon(Icons.image_not_supported)
        .hitTestable()
        .evaluate()
        .length,
    timedOut: true,
  );
}

Future<void> _webCheckpoint(String phase) async {
  web_probe.markWebImageMemoryPhase(phase);
  expect(
    await web_probe.waitForWebImageMemoryCheckpoint(phase),
    isTrue,
    reason: 'The Chrome/CDP probe did not acknowledge checkpoint $phase.',
  );
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
        loadingPlaceholder: const SizedBox(key: _loadingPlaceholderKey),
      ),
    );
  }
}
