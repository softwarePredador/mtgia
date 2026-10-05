import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'scryfall_image_request_policy.dart';

/// Brings the Scryfall rate gate and retry policy to the native image path
/// (BT-ART-01, D-37).
///
/// The Web path already gates `api.scryfall.com/cards/...` lookups inside
/// `_ScryfallWebCardImage`. On Android and iOS the bytes are fetched by
/// `flutter_cache_manager`, which has no pre-fetch hook, so the gate lives in
/// the [FileService] instead: every attempt for a Scryfall API image waits for
/// a permit, and a transient failure (429, 5xx or a network error) is retried
/// with the shared [ScryfallImageRetryPolicy]. CDN images
/// (`cards.scryfall.io`) and any other host go straight through.
class ScryfallGatedFileService extends FileService {
  ScryfallGatedFileService({
    FileService? inner,
    ScryfallImageRequestGate? gate,
    ScryfallImageRetryPolicy retryPolicy = scryfallImageRetryPolicy,
    Future<void> Function(Duration duration)? retryDelay,
  }) : _inner = inner ?? HttpFileService(),
       _gate = gate ?? scryfallImageRequestGate,
       _retryPolicy = retryPolicy,
       _retryDelay = retryDelay ?? Future<void>.delayed;

  final FileService _inner;
  final ScryfallImageRequestGate _gate;
  final ScryfallImageRetryPolicy _retryPolicy;
  final Future<void> Function(Duration duration) _retryDelay;

  @override
  int get concurrentFetches => _inner.concurrentFetches;

  @override
  set concurrentFetches(int value) => _inner.concurrentFetches = value;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (!isScryfallApiImageUrl(url)) {
      return _inner.get(url, headers: headers);
    }

    for (var retryIndex = 0; ; retryIndex++) {
      await _gate.acquire();
      final retryDelay = _retryPolicy.delayForRetry(retryIndex);
      try {
        final response = await _inner.get(url, headers: headers);
        if (!_isTransient(response.statusCode) || retryDelay == null) {
          return response;
        }
        unawaited(response.content.drain<void>().catchError((Object _) {}));
      } catch (_) {
        if (retryDelay == null) rethrow;
      }
      await _retryDelay(retryDelay);
    }
  }

  static bool _isTransient(int statusCode) =>
      statusCode == 429 || statusCode >= 500;
}

/// Cache manager for card artwork on native platforms.
///
/// It has its own store (two managers must never share a key) with the
/// package defaults for size and age; only the file service changes.
class CardImageCacheManager extends CacheManager with ImageCacheManager {
  CardImageCacheManager._()
    : super(Config(key, fileService: ScryfallGatedFileService()));

  static const key = 'brewtactCardImages';

  static final CardImageCacheManager instance = CardImageCacheManager._();

  /// Makes every native `CachedNetworkImage` use this manager. Web keeps the
  /// package default: it renders Scryfall through `_ScryfallWebCardImage`,
  /// which already applies the gate.
  static void install({bool isWeb = kIsWeb}) {
    if (isWeb) return;
    CachedNetworkImageProvider.defaultCacheManager = instance;
  }
}
