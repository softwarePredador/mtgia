import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/collection/set_icon_svg_cache.dart';

void main() {
  test('deduplicates successful icon fetches until the success TTL', () async {
    var now = DateTime.utc(2026, 7, 21);
    var calls = 0;
    final cache = SetIconSvgCache(
      successTtl: const Duration(hours: 1),
      clock: () => now,
    );

    Future<String?> loader(String _) async {
      calls += 1;
      return '<svg />';
    }

    expect(
      await cache.resolve('https://example.test/set.svg', loader),
      '<svg />',
    );
    expect(
      await cache.resolve('https://example.test/set.svg', loader),
      '<svg />',
    );
    expect(calls, 1);

    now = now.add(const Duration(hours: 1, seconds: 1));
    expect(
      await cache.resolve('https://example.test/set.svg', loader),
      '<svg />',
    );
    expect(calls, 2);
  });

  test('retries a failed icon after the short negative-cache TTL', () async {
    var now = DateTime.utc(2026, 7, 21);
    var calls = 0;
    final cache = SetIconSvgCache(
      failureTtl: const Duration(seconds: 10),
      clock: () => now,
    );

    Future<String?> loader(String _) async {
      calls += 1;
      return calls == 1 ? null : '<svg />';
    }

    expect(await cache.resolve('https://example.test/set.svg', loader), isNull);
    expect(await cache.resolve('https://example.test/set.svg', loader), isNull);
    expect(calls, 1);

    now = now.add(const Duration(seconds: 11));
    expect(
      await cache.resolve('https://example.test/set.svg', loader),
      '<svg />',
    );
    expect(calls, 2);
  });
}
