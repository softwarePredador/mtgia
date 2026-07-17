import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_web_document.dart';

void main() {
  const source = '''
<!doctype html>
<html>
  <head><script src="flutter_bootstrap.js"></script></head>
  <body><main>Lotus</main></body>
</html>
''';

  test('installs the isolated bridge before Lotus boot and keeps the skin', () {
    final document = buildLotusWebDocument(
      sourceHtml: source,
      assetBaseUrl: 'https://example.test/app/assets/assets/lotus/',
      bridgeToken: 'test-token',
      initialStorage: const <String, String>{'playerCount': '4'},
      injectedScripts: const <String>['window.__skinApplied = true;'],
    );

    expect(
      document.indexOf("Object.defineProperty(window, 'localStorage'"),
      lessThan(document.indexOf('flutter_bootstrap.js')),
    );
    expect(document, isNot(contains(lotusWebStorageKey)));
    expect(document, contains('"playerCount":"4"'));
    expect(document, contains('window.__skinApplied = true;'));
    expect(document, contains('kind: \'ready\''));
    expect(
      document,
      contains('<base href="https://example.test/app/assets/assets/lotus/">'),
    );
  });

  test('escapes closing script tags from persisted values and injections', () {
    final document = buildLotusWebDocument(
      sourceHtml: source,
      assetBaseUrl: 'https://example.test/',
      bridgeToken: 'test-token',
      initialStorage: const <String, String>{'unsafe': '</script><p>bad</p>'},
      injectedScripts: const <String>['window.value = "</script>";'],
    );

    expect(document, isNot(contains('</script><p>bad</p>')));
    expect(document, contains(r'<\/script><p>bad</p>'));
    expect(document, contains(r'window.value = "<\/script>";'));
  });

  test('rejects malformed source documents', () {
    expect(
      () => buildLotusWebDocument(
        sourceHtml: '<html></html>',
        assetBaseUrl: 'https://example.test/',
        bridgeToken: 'test-token',
        initialStorage: const <String, String>{},
        injectedScripts: const <String>[],
      ),
      throwsFormatException,
    );
  });

  test('only clears a pending mirror after that exact state completes', () {
    expect(
      shouldClearLotusWebStoragePendingFingerprint(
        pendingFingerprint: 'new-state',
        completedFingerprint: 'old-state',
        currentStorageFingerprint: 'new-state',
      ),
      isFalse,
    );
    expect(
      shouldClearLotusWebStoragePendingFingerprint(
        pendingFingerprint: 'new-state',
        completedFingerprint: 'new-state',
        currentStorageFingerprint: 'new-state',
      ),
      isTrue,
    );
    expect(
      shouldClearLotusWebStoragePendingFingerprint(
        pendingFingerprint: null,
        completedFingerprint: 'new-state',
        currentStorageFingerprint: 'new-state',
      ),
      isFalse,
    );
  });
}
