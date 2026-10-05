import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/services/scryfall_image_cache_manager.dart';
import 'package:manaloom/core/services/scryfall_image_request_policy.dart';

class _Response implements FileServiceResponse {
  _Response(this.statusCode);

  @override
  final int statusCode;

  @override
  Stream<List<int>> get content => Stream.value(const [1, 2, 3]);

  @override
  int? get contentLength => 3;

  @override
  String? get eTag => null;

  @override
  String get fileExtension => '.jpg';

  @override
  DateTime get validTill => DateTime.utc(2030);
}

class _ScriptedFileService extends FileService {
  _ScriptedFileService(this.script, {this.onCall});

  final List<Object> script;
  final void Function()? onCall;
  final calls = <String>[];
  final headersSeen = <Map<String, String>?>[];

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    calls.add(url);
    headersSeen.add(headers);
    onCall?.call();
    final next = script.removeAt(0);
    if (next is int) return _Response(next);
    throw next;
  }
}

class _CountingGate extends ScryfallImageRequestGate {
  var permits = 0;

  @override
  Future<void> acquire() async => permits++;
}

const _apiImage =
    'https://api.scryfall.com/cards/named?exact=Sol%20Ring&format=image&version=normal';
const _cdnImage = 'https://cards.scryfall.io/normal/front/0/0/abc.jpg';

void main() {
  group('ScryfallGatedFileService (BT-ART-01)', () {
    test('every Scryfall API attempt waits for a gate permit', () async {
      final inner = _ScriptedFileService([200]);
      final gate = _CountingGate();
      final service = ScryfallGatedFileService(inner: inner, gate: gate);

      final response = await service.get(
        _apiImage,
        headers: const {'User-Agent': 'BrewTact/1.0 (+https://brewtact.com)'},
      );

      expect(response.statusCode, 200);
      expect(gate.permits, 1);
      expect(inner.headersSeen.single?['User-Agent'], contains('BrewTact'));
    });

    test('retries 429 and 5xx within the shared policy, then stops', () async {
      final inner = _ScriptedFileService([429, 503, 503]);
      final gate = _CountingGate();
      final delays = <Duration>[];
      final service = ScryfallGatedFileService(
        inner: inner,
        gate: gate,
        retryDelay: (duration) async => delays.add(duration),
      );

      final response = await service.get(_apiImage);

      expect(response.statusCode, 503);
      expect(inner.calls, hasLength(3));
      expect(gate.permits, 3);
      expect(delays, const [
        Duration(milliseconds: 500),
        Duration(milliseconds: 1500),
      ]);
    });

    test('a network error is retried and recovers', () async {
      final inner = _ScriptedFileService([StateError('offline'), 200]);
      final service = ScryfallGatedFileService(
        inner: inner,
        gate: _CountingGate(),
        retryDelay: (_) async {},
      );

      expect((await service.get(_apiImage)).statusCode, 200);
      expect(inner.calls, hasLength(2));
    });

    test('a 404 is final and is not retried', () async {
      final inner = _ScriptedFileService([404]);
      final service = ScryfallGatedFileService(
        inner: inner,
        gate: _CountingGate(),
        retryDelay: (_) async => fail('must not retry a 404'),
      );

      expect((await service.get(_apiImage)).statusCode, 404);
    });

    test('CDN artwork and other hosts skip the gate', () async {
      final inner = _ScriptedFileService([200, 200]);
      final gate = _CountingGate();
      final service = ScryfallGatedFileService(inner: inner, gate: gate);

      await service.get(_cdnImage);
      await service.get('https://images.example.test/avatar.png');

      expect(gate.permits, 0);
      expect(inner.calls, hasLength(2));
    });

    test('the real gate spaces concurrent permits', () async {
      final starts = <DateTime>[];
      final gate = ScryfallImageRequestGate();
      final service = ScryfallGatedFileService(
        inner: _ScriptedFileService([
          200,
          200,
          200,
        ], onCall: () => starts.add(DateTime.now())),
        gate: gate,
      );

      await Future.wait([for (var i = 0; i < 3; i++) service.get(_apiImage)]);

      expect(starts, hasLength(3));
      for (var i = 1; i < starts.length; i++) {
        expect(
          starts[i].difference(starts[i - 1]),
          greaterThanOrEqualTo(const Duration(milliseconds: 120)),
        );
      }
    });
  });

  test('install sets the gated manager as default only off the Web', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = Directory.systemTemp.createTempSync('card-image-cache');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => tempDir.path,
        );
    final previous = CachedNetworkImageProvider.defaultCacheManager;
    addTearDown(
      () => CachedNetworkImageProvider.defaultCacheManager = previous,
    );

    CardImageCacheManager.install(isWeb: true);
    expect(
      CachedNetworkImageProvider.defaultCacheManager,
      isNot(same(CardImageCacheManager.instance)),
    );

    CardImageCacheManager.install(isWeb: false);
    expect(
      CachedNetworkImageProvider.defaultCacheManager,
      same(CardImageCacheManager.instance),
    );
  });
}
