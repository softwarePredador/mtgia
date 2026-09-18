import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
// FileInfo exposes package:file.File; use its already-locked implementation.
// ignore: depend_on_referenced_packages
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';
import 'package:manaloom/core/widgets/manaloom_glyph.dart';

void main() {
  // Do not initialize the lazy platform cache in this isolated widget suite.
  CachedNetworkImageProvider.defaultCacheManager = ArtworkTestCache(
    allowUnconfigured: true,
  );
  addArtworkCacheLifecycleTests();

  test('defaults to containing the complete card image', () {
    const image = CachedCardImage(imageUrl: 'https://example.test/card.jpg');

    expect(image.fit, BoxFit.contain);
  });

  testWidgets('reports a missing source through the shared image taxonomy', (
    tester,
  ) async {
    CardImageLoadState? observed;
    await tester.pumpWidget(
      MaterialApp(
        home: CachedCardImage(
          imageUrl: null,
          onLoadStateChanged: (state) => observed = state,
        ),
      ),
    );
    await tester.pump();

    expect(observed, CardImageLoadState.missing);
  });

  testWidgets('uses an original card-frame fallback when artwork is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: CachedCardImage(imageUrl: null, width: 80, height: 112),
        ),
      ),
    );

    expect(
      find.byKey(const Key('cached-card-image-placeholder')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('manaloom-card-back')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ManaLoomGlyph && widget.kind == ManaLoomGlyphKind.brand,
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.style), findsNothing);
    expect(find.byIcon(Icons.image_not_supported), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('HTTP image URLs stay secure outside an explicit loopback fixture', () {
    expect(
      CachedCardImage.sanitizeImageUrlForTesting(
        'http://images.example.test/card.png',
      ),
      'https://images.example.test/card.png',
    );
    expect(
      CachedCardImage.sanitizeImageUrlForTesting(
        'http://127.0.0.1:8080/card.png',
      ),
      'https://127.0.0.1:8080/card.png',
    );
    expect(
      CachedCardImage.sanitizeImageUrlForTesting(
        'http://127.0.0.1:8080/card.png',
        allowLoopbackHttp: true,
      ),
      'http://127.0.0.1:8080/card.png',
    );
    expect(
      CachedCardImage.sanitizeImageUrlForTesting(
        'http://images.example.test/card.png',
        allowLoopbackHttp: true,
      ),
      'https://images.example.test/card.png',
    );
  });

  test('selects a bounded Scryfall CDN variant for the decode target', () {
    const normal =
        'https://cards.scryfall.io/normal/front/a/b/card.jpg?version=1';
    const artCrop =
        'https://cards.scryfall.io/art_crop/front/a/b/card.jpg?version=1';

    expect(
      CachedCardImage.sizeScryfallImageUrlForTesting(normal, decodeWidth: 128),
      'https://cards.scryfall.io/small/front/a/b/card.jpg?version=1',
    );
    expect(
      CachedCardImage.sizeScryfallImageUrlForTesting(normal, decodeWidth: 384),
      normal,
    );
    expect(
      CachedCardImage.sizeScryfallImageUrlForTesting(normal, decodeWidth: 1024),
      'https://cards.scryfall.io/large/front/a/b/card.jpg?version=1',
    );
    expect(
      CachedCardImage.sizeScryfallImageUrlForTesting(artCrop, decodeWidth: 128),
      artCrop,
    );
  });

  testWidgets('removes fragile set filter from Scryfall named image URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CachedCardImage(
          imageUrl:
              'https://api.scryfall.com/cards/named?exact=Jin-Gitaxias&set=mom&format=image',
        ),
      ),
    );

    if (kIsWeb) {
      await tester.pump(const Duration(milliseconds: 200));
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      final uri = Uri.parse(provider.url);
      expect(uri.queryParameters['exact'], 'Jin-Gitaxias');
      expect(uri.queryParameters.containsKey('set'), isFalse);
      expect(uri.queryParameters['version'], 'normal');
      expect(provider.headers, isNull);
      expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
    } else {
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final uri = Uri.parse(image.imageUrl);
      expect(uri.queryParameters['exact'], 'Jin-Gitaxias');
      expect(uri.queryParameters.containsKey('set'), isFalse);
      expect(uri.queryParameters['version'], 'normal');
      expect(image.httpHeaders?['User-Agent'], 'ManaLoom/1.0');
      expect(image.httpHeaders?['Accept'], 'image/*');
    }
  });

  testWidgets('uses the HTML element strategy for direct Scryfall CDN art', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CachedCardImage(
          imageUrl: 'https://cards.scryfall.io/normal/front/a/b/card.jpg',
        ),
      ),
    );

    if (kIsWeb) {
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.headers, isNull);
      expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
    } else {
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    }
  });

  testWidgets('bounds thumbnail decode without a second disk resize', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(devicePixelRatio: 3),
          child: Center(
            child: SizedBox(
              width: 60,
              height: 84,
              child: CachedCardImage(
                imageUrl: 'https://cards.scryfall.io/large/front/a/b/card.png',
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );

    if (kIsWeb) {
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.prefer);
      expect(provider.headers, isNull);
    } else {
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.memCacheWidth, 256);
      expect(image.memCacheHeight, isNull);
      expect(image.maxWidthDiskCache, isNull);
      expect(image.maxHeightDiskCache, isNull);
    }
  });
}

// Shared only by these two widget suites; no provider/widget/codec is mocked.
class ArtworkTestCache implements BaseCacheManager, ImageCacheManager {
  ArtworkTestCache({this.allowUnconfigured = false});
  final bool allowUnconfigured;
  final _outcomes = <String, Completer<bool>>{};
  final requests = <String>[];
  var activeStreams = 0;
  var closed = false;

  void register(String url) => _outcomes[url] = Completer<bool>();
  void complete(String url, {bool success = true}) =>
      _outcomes[url]!.complete(success);

  @override
  Stream<FileResponse> getImageFile(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
    int? maxHeight,
    int? maxWidth,
  }) => getFileStream(url, key: key, headers: headers);

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    if (!_outcomes.containsKey(url) && allowUnconfigured) {
      return const Stream<FileResponse>.empty();
    }
    if (closed || !_outcomes.containsKey(url) || requests.length >= 32) {
      throw StateError(
        'Unexpected image consumer: $url, count=${requests.length}',
      );
    }
    requests.add(url);
    return _response(url);
  }

  Stream<FileResponse> _response(String url) async* {
    activeStreams++;
    try {
      final success = await _outcomes[url]!.future;
      if (closed) return;
      if (!success) throw StateError('Controlled image failure: $url');
      yield FileInfo(
        const LocalFileSystem().file(
          'assets/branding/visual_fixture_arcane_ring.webp',
        ),
        FileSource.Cache,
        DateTime.now().add(const Duration(minutes: 5)),
        url,
      );
    } finally {
      activeStreams--;
    }
  }

  void closePending() {
    closed = true;
    for (final pending in _outcomes.values) {
      if (!pending.isCompleted) pending.complete(false);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected cache method: ${invocation.memberName}');
}

bool artworkDecoded(WidgetTester tester) => tester
    .widgetList<RawImage>(
      find.descendant(
        of: find.byType(CachedNetworkImage),
        matching: find.byType(RawImage),
      ),
    )
    .any((image) => image.image != null);

Future<void> pumpArtworkUntil(
  WidgetTester tester,
  bool Function() ready,
) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (ready()) return;
  }
  fail('Image condition was not reached within the bounded async observation');
}

Future<void> settleArtwork(WidgetTester tester) => tester
    .pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 2),
    )
    .then((_) {});

Future<void> withArtworkCache(
  WidgetTester tester,
  Future<void> Function(ArtworkTestCache cache) body,
) async {
  final previous = CachedNetworkImageProvider.defaultCacheManager;
  final cache = ArtworkTestCache();
  CachedNetworkImageProvider.defaultCacheManager = cache;
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
  try {
    await body(cache);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    cache.closePending();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    for (var i = 0; i < 100 && cache.activeStreams != 0; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
    CachedNetworkImageProvider.defaultCacheManager = previous;
    await tester.pump();
    expect(cache.activeStreams, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  }
}

Widget artworkTestHost(Widget child) => MaterialApp(
  home: Center(child: SizedBox(width: 160, height: 225, child: child)),
);

void addArtworkCacheLifecycleTests() {
  const a = 'https://artwork-lifecycle.invalid/normal/a.webp';
  const b = 'https://artwork-lifecycle.invalid/normal/b.webp';

  testWidgets('a new URL loads again after the same State was ready', (
    tester,
  ) async {
    await withArtworkCache(tester, (cache) async {
      cache.register(a);
      cache.register(b);
      const key = ValueKey('ready-to-new-url');
      final states = <String>[];
      Widget image(String url) => CachedCardImage(
        key: key,
        imageUrl: url,
        onLoadStateChanged: (state) => states.add('$url:${state.name}'),
      );
      await tester.pumpWidget(artworkTestHost(image(a)));
      final firstState = tester.state(find.byKey(key));
      cache.complete(a);
      await pumpArtworkUntil(tester, () => artworkDecoded(tester));
      await settleArtwork(tester);
      await tester.pumpWidget(artworkTestHost(image(b)));
      await tester.pump();
      expect(tester.state(find.byKey(key)), same(firstState));
      expect(states.last, '$b:loading');
      cache.complete(b);
      await pumpArtworkUntil(tester, () => states.contains('$b:primaryReady'));
      await settleArtwork(tester);
      expect(states, [
        '$a:loading',
        '$a:primaryReady',
        '$b:loading',
        '$b:primaryReady',
      ]);
    });
  });

  testWidgets('ready queued by the real A builder is rejected after B update', (
    tester,
  ) async {
    await withArtworkCache(tester, (cache) async {
      cache.register(a);
      cache.register(b);
      const key = ValueKey('queued-ready');
      final states = <String>[];
      Widget image(String url) => CachedCardImage(
        key: key,
        imageUrl: url,
        onLoadStateChanged: (state) => states.add('$url:${state.name}'),
      );
      await tester.pumpWidget(artworkTestHost(image(a)));
      var switched = false;
      var observations = 0;
      void switchBeforeNotification(Duration _) {
        if (find.byKey(key).evaluate().isEmpty) return;
        if (++observations > 100) return; // Bounded diagnostic window.
        final originalProviderWasBuilt = tester
            .widgetList<Image>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Image),
              ),
            )
            .any((image) => image.image is CachedNetworkImageProvider);
        if (!originalProviderWasBuilt) {
          tester.binding.addPostFrameCallback(switchBeforeNotification);
          return;
        }
        // Registered before this frame: executes before A's queued readiness.
        final element = tester.element(find.byKey(key)) as StatefulElement;
        element.owner!.buildScope(element, () {
          element.update(image(b) as StatefulWidget);
        });
        switched = true;
      }

      tester.binding.addPostFrameCallback(switchBeforeNotification);
      cache.complete(a);
      await pumpArtworkUntil(tester, () => switched);
      await tester.pump();
      expect(states, ['$a:loading', '$b:loading']);
      cache.complete(b);
      await pumpArtworkUntil(tester, () => artworkDecoded(tester));
      await settleArtwork(tester);
      expect(states, ['$a:loading', '$b:loading', '$b:primaryReady']);
    });
  });

  testWidgets('async ready lifecycle stays stable through parent rebuild', (
    tester,
  ) async {
    await withArtworkCache(tester, (cache) async {
      cache.register(a);
      final states = <CardImageLoadState>[];
      Widget image() =>
          CachedCardImage(imageUrl: a, onLoadStateChanged: states.add);
      await tester.pumpWidget(artworkTestHost(image()));
      expect(artworkDecoded(tester), isFalse);
      expect(states, [CardImageLoadState.loading]);
      cache.complete(a);
      await pumpArtworkUntil(tester, () => artworkDecoded(tester));
      await settleArtwork(tester);
      final requests = cache.requests.length;
      await tester.pumpWidget(artworkTestHost(image()));
      await settleArtwork(tester);
      expect(states, [
        CardImageLoadState.loading,
        CardImageLoadState.primaryReady,
      ]);
      expect(cache.requests.length, requests);
    });
  });

  testWidgets('fallback readiness and exhausted failure are stable', (
    tester,
  ) async {
    for (final fallbackWorks in [true, false]) {
      await withArtworkCache(tester, (cache) async {
        cache.register(a);
        cache.register(b);
        final states = <CardImageLoadState>[];
        await tester.pumpWidget(
          artworkTestHost(
            CachedCardImage(
              imageUrl: a,
              fallbackImageUrl: b,
              onLoadStateChanged: states.add,
            ),
          ),
        );
        cache.complete(a, success: false);
        await pumpArtworkUntil(tester, () => cache.requests.contains(b));
        cache.complete(b, success: fallbackWorks);
        final expected = fallbackWorks
            ? CardImageLoadState.fallbackReady
            : CardImageLoadState.failed;
        await pumpArtworkUntil(tester, () => states.contains(expected));
        if (fallbackWorks) {
          await pumpArtworkUntil(tester, () => artworkDecoded(tester));
        }
        await settleArtwork(tester);
        expect(states, [CardImageLoadState.loading, expected]);
      });
    }
  });

  testWidgets('queued A and late bytes cannot override B in the same State', (
    tester,
  ) async {
    await withArtworkCache(tester, (cache) async {
      cache.register(a);
      cache.register(b);
      const key = ValueKey('same-image');
      final states = <String>[];
      Widget image(String url) => CachedCardImage(
        key: key,
        imageUrl: url,
        onLoadStateChanged: (state) => states.add('$url:${state.name}'),
      );
      State? originalState;
      // Run before the notification queued by A's real placeholder builder.
      tester.binding.addPostFrameCallback((_) {
        final element = tester.element(find.byKey(key)) as StatefulElement;
        originalState = element.state;
        element.owner!.buildScope(element, () {
          element.update(image(b) as StatefulWidget);
        });
      });
      await tester.pumpWidget(artworkTestHost(image(a)));
      await tester.pump();
      expect(tester.state(find.byKey(key)), same(originalState));
      expect(states, ['$b:loading']);
      cache.complete(b);
      await pumpArtworkUntil(tester, () => artworkDecoded(tester));
      await settleArtwork(tester);
      final requests = cache.requests.length;
      cache.complete(a);
      await pumpArtworkUntil(tester, () => cache.activeStreams == 0);
      await settleArtwork(tester);
      expect(states, ['$b:loading', '$b:primaryReady']);
      expect(cache.requests.length, requests);
    });
  });

  testWidgets('disposed generation cannot notify a remounted image', (
    tester,
  ) async {
    await withArtworkCache(tester, (cache) async {
      cache.register(a);
      cache.register(b);
      final oldStates = <CardImageLoadState>[];
      final newStates = <CardImageLoadState>[];
      await tester.pumpWidget(
        artworkTestHost(
          CachedCardImage(imageUrl: a, onLoadStateChanged: oldStates.add),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      final oldCount = oldStates.length;
      await tester.pumpWidget(
        artworkTestHost(
          CachedCardImage(imageUrl: b, onLoadStateChanged: newStates.add),
        ),
      );
      cache.complete(b);
      await pumpArtworkUntil(tester, () => artworkDecoded(tester));
      cache.complete(a);
      await pumpArtworkUntil(tester, () => cache.activeStreams == 0);
      await settleArtwork(tester);
      expect(oldStates.length, oldCount);
      expect(newStates, [
        CardImageLoadState.loading,
        CardImageLoadState.primaryReady,
      ]);
    });
  });
}
