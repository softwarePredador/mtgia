import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_profile_store.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LifeCounterPlayerAppearanceProfileStore', () {
    late LifeCounterPlayerAppearanceProfileStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = LifeCounterPlayerAppearanceProfileStore();
    });

    test('saves and restores appearance profiles', () async {
      await store.saveProfile(
        name: 'Partner Pod',
        appearance: const LifeCounterPlayerAppearance(
          background: '#CF7AEF',
          nickname: 'Partner Pilot',
          backgroundImage: 'main-image-ref',
          backgroundImagePartner: 'partner-image-ref',
        ),
      );

      final profiles = await store.load();

      expect(profiles, hasLength(1));
      expect(profiles.first.name, 'Partner Pod');
      expect(
        profiles.first.appearance,
        const LifeCounterPlayerAppearance(
          background: '#CF7AEF',
          nickname: 'Partner Pilot',
          backgroundImage: 'main-image-ref',
          backgroundImagePartner: 'partner-image-ref',
        ),
      );
    });

    test('upserts profiles by case-insensitive name', () async {
      await store.saveProfile(
        name: 'Partner Pod',
        appearance: const LifeCounterPlayerAppearance(background: '#CF7AEF'),
      );

      final saved = await store.saveProfile(
        name: 'partner pod',
        appearance: const LifeCounterPlayerAppearance(
          background: '#40B9FF',
          nickname: 'Updated',
        ),
      );

      expect(saved, hasLength(1));
      expect(saved.first.name, 'partner pod');
      expect(saved.first.appearance.background, '#40B9FF');
      expect(saved.first.appearance.nickname, 'Updated');
    });

    test('deletes profiles by id', () async {
      final saved = await store.saveProfile(
        name: 'Partner Pod',
        appearance: const LifeCounterPlayerAppearance(background: '#CF7AEF'),
      );

      final remaining = await store.deleteProfile(saved.first.id);

      expect(remaining, isEmpty);
      expect(await store.load(), isEmpty);
    });
  });
}
