import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_lifecycle_diagnostic_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LotusLifecycleDiagnosticStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists and loads lifecycle trace entries', () async {
      final store = LotusLifecycleDiagnosticStore();

      await store.append(<String, Object?>{
        'timestamp': '2026-04-03T00:00:00.000Z',
        'event': 'native_lifecycle_signal',
        'data': <String, Object?>{'method': 'userLeaveHint'},
      });

      final entries = await store.load();
      expect(entries, hasLength(1));
      expect(entries.first['event'], 'native_lifecycle_signal');
      expect(entries.first['data'], <String, dynamic>{'method': 'userLeaveHint'});
    });

    test('keeps only the most recent entries', () async {
      final store = LotusLifecycleDiagnosticStore(maxEntries: 2);

      await store.append(<String, Object?>{
        'timestamp': '1',
        'event': 'first',
        'data': <String, Object?>{},
      });
      await store.append(<String, Object?>{
        'timestamp': '2',
        'event': 'second',
        'data': <String, Object?>{},
      });
      await store.append(<String, Object?>{
        'timestamp': '3',
        'event': 'third',
        'data': <String, Object?>{},
      });

      final entries = await store.load();
      expect(entries, hasLength(2));
      expect(entries.first['event'], 'second');
      expect(entries.last['event'], 'third');
    });
  });
}
