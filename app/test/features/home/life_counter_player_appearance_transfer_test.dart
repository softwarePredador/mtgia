import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/life_counter/life_counter_player_appearance_transfer.dart';
import 'package:manaloom/features/home/life_counter/life_counter_session.dart';

void main() {
  group('LifeCounterPlayerAppearanceTransfer', () {
    test('round-trips a full player appearance payload', () {
      const appearance = LifeCounterPlayerAppearance(
        background: '#CF7AEF',
        nickname: 'Partner Pilot',
        backgroundImage: 'main-image-ref',
        backgroundImagePartner: 'partner-image-ref',
      );

      final transfer = LifeCounterPlayerAppearanceTransfer.fromAppearance(
        appearance,
      );
      final parsed = LifeCounterPlayerAppearanceTransfer.tryParse(
        transfer.toJsonString(),
      );

      expect(parsed, isNotNull);
      expect(parsed!.version, lifeCounterPlayerAppearanceTransferVersion);
      expect(parsed.appearance, appearance);
    });

    test('rejects invalid payloads', () {
      expect(
        LifeCounterPlayerAppearanceTransfer.tryParse('{"version":0}'),
        isNull,
      );
      expect(
        LifeCounterPlayerAppearanceTransfer.tryParse('{"version":1}'),
        isNull,
      );
      expect(LifeCounterPlayerAppearanceTransfer.tryParse('not-json'), isNull);
    });
  });
}
