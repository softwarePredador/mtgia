import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot.dart';
import 'package:manaloom/features/home/lotus/lotus_storage_snapshot_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LotusStorageSnapshotStore', () {
    late LotusStorageSnapshotStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = LotusStorageSnapshotStore();
    });

    test('saves and restores a raw localStorage snapshot', () async {
      const snapshot = LotusStorageSnapshot(
        values: {
          'players': '[{"name":"Player 1"}]',
          'gameSettings': '{"showClockOnMainScreen":true}',
          'startingLifeMP': '40',
          'reviewPrompt': 'true',
        },
      );

      await store.save(snapshot);
      final restored = await store.load();

      expect(restored, isNotNull);
      expect(restored!.toJson(), snapshot.toJson());
    });

    test('ignores invalid payloads', () async {
      SharedPreferences.setMockInitialValues({
        lotusStorageSnapshotPrefsKey: jsonEncode({
          'values': 'not-a-map',
        }),
      });
      store = LotusStorageSnapshotStore();

      final restored = await store.load();

      expect(restored, isNull);
    });

    test('drops null values while parsing', () async {
      SharedPreferences.setMockInitialValues({
        lotusStorageSnapshotPrefsKey: jsonEncode({
          'values': {
            'players': '[1,2,3]',
            'gameSettings': null,
            'startingLife2P': 20,
          },
        }),
      });
      store = LotusStorageSnapshotStore();

      final restored = await store.load();

      expect(restored, isNotNull);
      expect(
        restored!.values,
        const {
          'players': '[1,2,3]',
          'startingLife2P': '20',
        },
      );
    });

    test('clears the persisted snapshot', () async {
      await store.save(
        const LotusStorageSnapshot(
          values: {
            'players': '[]',
          },
        ),
      );

      await store.clear();

      expect(await store.load(), isNull);
    });
  });
}
