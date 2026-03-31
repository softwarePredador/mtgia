import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_ui_snapshot.dart';

void main() {
  group('LotusUiSnapshot', () {
    test('parses timer and clock counters from runtime payload', () {
      final snapshot = LotusUiSnapshot.tryFromJson(const {
        'captured_at_epoch_ms': 123456,
        'body_class_name': 'clean-look',
        'viewport_width': 412.0,
        'viewport_height': 915.0,
        'screen_width': 412.0,
        'screen_height': 915.0,
        'set_life_by_tap_enabled': true,
        'vertical_tap_areas_enabled': false,
        'clean_look_enabled': true,
        'first_player_card_width': 199.8,
        'first_player_card_height': 451.3,
        'regular_counter_count': 6,
        'commander_damage_counter_count': 2,
        'game_timer_count': 1,
        'game_timer_paused_count': 0,
        'game_timer_text': '01:05',
        'clock_count': 1,
        'clock_with_game_timer_count': 1,
        'player_card_count': 4,
      });

      expect(snapshot, isNotNull);
      expect(snapshot!.gameTimerCount, 1);
      expect(snapshot.gameTimerPausedCount, 0);
      expect(snapshot.gameTimerText, '01:05');
      expect(snapshot.clockCount, 1);
      expect(snapshot.clockWithGameTimerCount, 1);
      expect(snapshot.viewportWidth, 412.0);
      expect(snapshot.viewportHeight, 915.0);
      expect(snapshot.firstPlayerCardWidth, 199.8);
    });

    test('rejects payloads without game timer counters', () {
      final snapshot = LotusUiSnapshot.tryFromJson(const {
        'captured_at_epoch_ms': 123456,
        'body_class_name': 'clean-look',
        'viewport_width': 412.0,
        'viewport_height': 915.0,
        'screen_width': 412.0,
        'screen_height': 915.0,
        'set_life_by_tap_enabled': true,
        'vertical_tap_areas_enabled': false,
        'clean_look_enabled': true,
        'first_player_card_width': 199.8,
        'first_player_card_height': 451.3,
        'regular_counter_count': 6,
        'commander_damage_counter_count': 2,
        'clock_count': 1,
        'clock_with_game_timer_count': 1,
        'player_card_count': 4,
      });

      expect(snapshot, isNull);
    });
  });
}
