import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/features/retention/screens/post_game_notes_screen.dart';
import 'package:manaloom/features/retention/services/post_game_note_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('post-game keeps one column and full-width save at 390px', (
    tester,
  ) async {
    await _pumpPostGame(tester, const Size(390, 900));

    expect(find.byKey(const Key('post-game-mobile-layout')), findsOneWidget);
    expect(find.byKey(const Key('post-game-desktop-layout')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('post-game-save-button'))).width,
      greaterThan(300),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'post-game uses summary inspector and compact actions at 1280px',
    (tester) async {
      await _pumpPostGame(tester, const Size(1280, 900));

      expect(find.byKey(const Key('post-game-desktop-layout')), findsOneWidget);
      expect(find.byKey(const Key('post-game-mobile-layout')), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const Key('post-game-evolution-summary')))
            .width,
        closeTo(AppTheme.inspectorWidth, 0.1),
      );
      expect(
        tester.getSize(find.byKey(const Key('post-game-save-button'))).width,
        closeTo(210, 0.1),
      );
      expect(
        tester
            .getSize(
              find.byKey(const Key('post-game-optimize-from-summary-button')),
            )
            .width,
        closeTo(150, 0.1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpPostGame(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      home: PostGameNotesScreen(
        deckId: 'deck-responsive',
        store: PostGameNoteStore(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
