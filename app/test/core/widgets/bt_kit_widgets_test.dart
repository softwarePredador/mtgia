import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/theme/bt_tokens.dart';
import 'package:manaloom/core/widgets/app_action_bar.dart';
import 'package:manaloom/core/widgets/app_choice_piece.dart';
import 'package:manaloom/core/widgets/app_hero_tile.dart';
import 'package:manaloom/core/widgets/app_numeral.dart';
import 'package:manaloom/core/widgets/app_numeral_piece.dart';
import 'package:manaloom/core/widgets/app_plaque.dart';
import 'package:manaloom/core/widgets/app_rule_tile.dart';
import 'package:manaloom/core/widgets/app_tile.dart';
import 'package:manaloom/core/widgets/app_tile_board.dart';
import 'package:manaloom/core/widgets/app_tile_overlay.dart';
import 'package:manaloom/core/widgets/bt_surface.dart';

/// Behaviour of the BrewTact kit (BT-UX-KIT-001): every primitive and
/// derived piece, positive and negative cases, two-tap arming and the
/// fallback without [BtTokens].
Widget _host(
  Widget child, {
  ThemeData? theme,
  double width = 220,
  double? height = 128,
  double textScale = 1,
  bool armedScope = false,
}) {
  Widget body = Center(
    child: SizedBox(width: width, height: height, child: child),
  );
  if (armedScope) body = BtArmedScope(child: body);
  return MaterialApp(
    theme: theme ?? AppTheme.darkTheme,
    home: MediaQuery.withClampedTextScaling(
      minScaleFactor: textScale,
      maxScaleFactor: textScale,
      child: Scaffold(body: body),
    ),
  );
}

BtSurface _surfaceOf(WidgetTester tester, Finder piece) => tester
    .widgetList<BtSurface>(
      find.descendant(of: piece, matching: find.byType(BtSurface)),
    )
    .first;

BtTokens get _t => BtTokens.standard;

int _count = 0;
void _hit() => _count++;

void main() {
  setUp(() => _count = 0);

  group('AppTile', () {
    testWidgets('fires onTap and is a button with its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AppTile(icon: Icon(Icons.undo), label: 'Desfazer', onTap: _hit),
        ),
      );
      await tester.tap(find.byType(AppTile));
      expect(_count, 1);
      expect(
        tester.getSemantics(find.byType(AppTile)),
        isSemantics(
          label: 'Desfazer',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(find.text('DESFAZER'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('disabled does not fire and is announced as disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const AppTile(label: 'Desfazer')));
      await tester.tap(find.byType(AppTile), warnIfMissed: false);
      expect(_count, 0);
      expect(
        tester.getSemantics(find.byType(AppTile)),
        isSemantics(isButton: true, isEnabled: false),
      );
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(AppTile),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, _t.metrics.disabledOpacity);
      handle.dispose();
    });

    testWidgets('loading never fires, even with a handler', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppTile(
            label: 'Partidas',
            status: AppTileStatus.carregando,
            onTap: _hit,
          ),
        ),
      );
      await tester.tap(find.byType(AppTile), warnIfMissed: false);
      await tester.pump();
      expect(_count, 0);
      expect(find.byType(BtSweep), findsOneWidget);
      expect(find.byType(BtThread), findsOneWidget);
    });

    testWidgets('selected paints brass with the sheen', (tester) async {
      await tester.pumpWidget(
        _host(const AppTile(label: 'Coroa', selected: true, onTap: _hit)),
      );
      final surface = _surfaceOf(tester, find.byType(AppTile));
      expect(surface.gradient, _t.gradients.brassPiece);
      expect(surface.sheen, isTrue);
    });

    testWidgets('error does not look lit, selected or armed', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AppTile(
            label: 'Mesa',
            status: AppTileStatus.erro,
            selected: true,
            armed: true,
            onTap: _hit,
          ),
        ),
      );
      final surface = _surfaceOf(tester, find.byType(AppTile));
      expect(surface.gradient, _t.gradients.errorGlass);
      expect(surface.gradient, isNot(_t.gradients.brassPiece));
      expect(surface.shadows, _t.shadows.error);
      expect(surface.sheen, isFalse);
      expect(find.text('DE NOVO'), findsOneWidget);
      final label = tester.widget<Text>(find.text('MESA'));
      expect(label.style!.color, _t.palette.ember);
      expect(
        tester.getSemantics(find.byType(AppTile)),
        isSemantics(isSelected: false, value: 'erro, tocar de novo'),
      );
      // The error tile is a retry: the tap still reaches the handler.
      await tester.tap(find.byType(AppTile));
      expect(_count, 1);
      handle.dispose();
    });

    testWidgets('livre/vazio is dashed and never brass', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppTile(
            label: 'Iniciativa',
            tone: AppTileTone.livre,
            estado: AppTileEstado.off('sem dono'),
            onTap: _hit,
          ),
        ),
      );
      final surface = _surfaceOf(tester, find.byType(AppTile));
      expect(surface.dashed, isTrue);
      expect(surface.gradient, _t.gradients.free);
    });

    test('state asserts reject contradictory states', () {
      expect(
        () => AppTile(label: 'x', tone: AppTileTone.livre, selected: true),
        throwsAssertionError,
      );
      expect(
        () => AppTile(
          label: 'x',
          tone: AppTileTone.brasaCheia,
          status: AppTileStatus.erro,
        ),
        throwsAssertionError,
      );
      expect(
        () => AppTile(label: 'x', tone: AppTileTone.vitral),
        throwsAssertionError,
      );
    });

    testWidgets('above 160% text scale the state moves under the label (F2)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const AppTile(
            label: 'Dia',
            estado: AppTileEstado('noite'),
            onTap: _hit,
          ),
          width: 260,
          height: null,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      final label = tester.getRect(find.text('DIA'));
      final state = tester.getRect(find.text('noite'));
      expect(state.top, greaterThan(label.bottom - 1));
    });

    testWidgets('keeps a 48 dp target', (tester) async {
      await tester.pumpWidget(
        _host(const AppTile(label: 'Regras', onTap: _hit), height: null),
      );
      final size = tester.getSize(find.byType(AppTile));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets('Enter activates a focused tile', (tester) async {
      await tester.pumpWidget(
        _host(const AppTile(label: 'Regras', onTap: _hit, autofocus: true)),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_count, 1);
    });
  });

  group('BtArmedScope', () {
    var confirmed = 0;
    void confirm() => confirmed++;
    setUp(() => confirmed = 0);

    Widget pair() => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: BtArmedScope(
          child: Row(
            children: [
              SizedBox(
                width: 160,
                height: 120,
                child: AppTile(
                  key: const ValueKey('a'),
                  label: 'Nova partida',
                  tone: AppTileTone.brasaTinta,
                  onArmedConfirm: confirm,
                ),
              ),
              SizedBox(
                width: 160,
                height: 120,
                child: AppTile(
                  key: const ValueKey('b'),
                  label: 'Encerrar',
                  tone: AppTileTone.brasaTinta,
                  onArmedConfirm: confirm,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    testWidgets('first tap arms, second tap confirms', (tester) async {
      await tester.pumpWidget(pair());
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();
      expect(confirmed, 0);
      expect(find.text('DE NOVO'), findsOneWidget);
      final surface = _surfaceOf(tester, find.byKey(const ValueKey('a')));
      expect(surface.shadows, _t.shadows.armedEmber);
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();
      expect(confirmed, 1);
      expect(find.text('DE NOVO'), findsNothing);
    });

    testWidgets('an armed piece disarms after 6 s', (tester) async {
      await tester.pumpWidget(pair());
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5900));
      expect(find.text('DE NOVO'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('DE NOVO'), findsNothing);
      // After the timeout the next tap arms again instead of confirming.
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();
      expect(confirmed, 0);
      expect(find.text('DE NOVO'), findsOneWidget);
    });

    testWidgets('arming another piece disarms the first', (tester) async {
      await tester.pumpWidget(pair());
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('b')));
      await tester.pump();
      expect(find.text('DE NOVO'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('b')),
          matching: find.text('DE NOVO'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pump();
      expect(confirmed, 0, reason: 'a was disarmed, so this tap re-arms it');
    });
  });

  group('AppNumeral', () {
    testWidgets('keeps the scale size when it fits', (tester) async {
      await tester.pumpWidget(_host(const AppNumeral('40'), width: 300));
      final text = tester.widget<Text>(find.text('40'));
      expect(text.style!.fontSize, 56);
    });

    testWidgets('shrinks to the floor and never below it', (tester) async {
      await tester.pumpWidget(_host(const AppNumeral('4000'), width: 24));
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text('4000'));
      expect(text.style!.fontSize, 20);
    });

    testWidgets('ignores the system text scale', (tester) async {
      await tester.pumpWidget(
        _host(const AppNumeral('12'), width: 300, textScale: 2),
      );
      final context = tester.element(find.text('12'));
      expect(MediaQuery.textScalerOf(context), TextScaler.noScaling);
    });

    testWidgets('speaks its semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AppNumeral(
            '27',
            scale: AppNumeralScale.vivo,
            semanticsLabel: '27 de vida',
          ),
          width: 300,
        ),
      );
      expect(find.bySemanticsLabel('27 de vida'), findsOneWidget);
      handle.dispose();
    });

    test('AppNumeralMesa follows the ruler formula', () {
      const two = AppNumeralMesa('27');
      // min((200 − 76) × 1.38, 300 × .38) = min(171.12, 114) = 114.
      expect(two.fontSizeFor(const Size(300, 200)), closeTo(114, 0.001));
      const three = AppNumeralMesa('120');
      expect(three.fontSizeFor(const Size(300, 200)), closeTo(78, 0.001));
      // The floor wins on a tiny card.
      expect(two.fontSizeFor(const Size(40, 60)), 28);
    });

    testWidgets('AppNumeralMesa renders the computed size', (tester) async {
      await tester.pumpWidget(
        _host(const AppNumeralMesa('27'), width: 300, height: 200),
      );
      final text = tester.widget<Text>(find.text('27'));
      expect(text.style!.fontSize, closeTo(114, 0.001));
    });
  });

  group('AppTileBoard', () {
    Widget board({VoidCallback? onDismiss}) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: AppTileBoard(
          heroRow: 1,
          onDismiss: onDismiss,
          center: AppCloseX(onTap: onDismiss),
          rows: [
            const AppTileRowSpec(
              children: [
                AppTile(label: 'Desfazer', onTap: _hit, autofocus: true),
                AppTile(label: 'Dados', onTap: _hit),
              ],
            ),
            AppTileRowSpec.hero(
              children: [
                AppHeroTile(label: 'Passar a vez', title: 'Léo', onGo: _hit),
                const AppTile(label: 'Plano', onTap: _hit),
              ],
            ),
          ],
        ),
      ),
    );

    testWidgets('lays out at phone and desktop widths', (tester) async {
      for (final size in const [Size(390, 844), Size(1440, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(board(onDismiss: _hit));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AppTile), findsNWidgets(3));
        final boardWidth = tester.getSize(find.byType(AppTileBoard)).width;
        expect(boardWidth, size.width);
        final tile = tester.getSize(find.widgetWithText(AppTile, 'DADOS'));
        expect(tile.height, greaterThanOrEqualTo(48));
      }
      tester.view.reset();
    });

    testWidgets('a tap on the veil and Escape dismiss', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(board(onDismiss: _hit));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      expect(_count, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(_count, 2);
    });

    testWidgets('marks the tiles as veiled (A8)', (tester) async {
      await tester.pumpWidget(board());
      await tester.pumpAndSettle();
      final context = tester.element(find.widgetWithText(AppTile, 'DADOS'));
      expect(BtBoardScope.veiledOf(context), isTrue);
    });
  });

  group('AppTileOverlay', () {
    Widget opener() => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: SizedBox(
              width: 160,
              height: 112,
              child: AppTile(
                label: 'Regras',
                onTap: () => showAppTileOverlay<void>(
                  context: context,
                  builder: (context) => AppTileOverlay(
                    title: 'Regras da mesa',
                    onClose: () => Navigator.of(context).pop(),
                    body: const [
                      AppRuleTile(title: 'Dano de comandante', on: true),
                    ],
                    footer: const AppActionBar(
                      primary: AppAction.principal('Salvar', onTap: _hit),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('opens over a non-opaque route and the × closes it', (
      tester,
    ) async {
      await tester.pumpWidget(opener());
      await tester.tap(find.byType(AppTile));
      await tester.pumpAndSettle();
      expect(find.byType(AppTileOverlay), findsOneWidget);
      // The tile below is still painted: the route is not opaque.
      expect(find.byType(AppTile), findsOneWidget);
      final route = ModalRoute.of(tester.element(find.byType(AppTileOverlay)));
      expect(route, isA<PageRouteBuilder<void>>());
      expect(route!.opaque, isFalse);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      await tester.tap(find.byType(AppCloseX));
      await tester.pumpAndSettle();
      expect(find.byType(AppTileOverlay), findsNothing);
    });

    testWidgets('names the route and has a single ×', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(opener());
      await tester.tap(find.byType(AppTile));
      await tester.pumpAndSettle();
      expect(find.byType(AppCloseX), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(AppTileOverlay)),
        isSemantics(
          label: 'Regras da mesa',
          scopesRoute: true,
          namesRoute: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('Escape closes it', (tester) async {
      await tester.pumpWidget(opener());
      await tester.tap(find.byType(AppTile));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AppTileOverlay), findsNothing);
    });

    testWidgets('disabled × and back arrow do not fire', (tester) async {
      await tester.pumpWidget(
        _host(
          const Row(
            children: [
              AppBackArrow(onTap: null),
              AppCloseX(onTap: null, size: AppCloseXSize.head),
            ],
          ),
          width: 200,
          height: 60,
        ),
      );
      await tester.tap(find.byType(AppCloseX), warnIfMissed: false);
      await tester.tap(find.byType(AppBackArrow), warnIfMissed: false);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AppCloseX)).height, 48);
    });
  });

  group('AppHeroTile', () {
    var go = 0;
    void onGo() => go++;
    setUp(() => go = 0);

    testWidgets('body and round button fire their own handlers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          AppHeroTile(
            label: 'Passar a vez',
            title: 'Léo',
            leadingCaption: 'Turno',
            leadingNumeral: const AppNumeral('3', scale: AppNumeralScale.heroi),
            onGo: onGo,
            onTap: _hit,
          ),
          width: 360,
          height: 136,
        ),
      );
      await tester.tap(find.text('Léo'));
      expect(_count, 1);
      expect(go, 0);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is BtStrokeGlyph && w.shape == BtGlyphShape.arrowForward,
        ),
      );
      expect(go, 1);
    });

    testWidgets('loading fires nothing', (tester) async {
      await tester.pumpWidget(
        _host(
          AppHeroTile(
            label: 'Passar a vez',
            title: 'Léo',
            onGo: onGo,
            loading: true,
          ),
          width: 360,
          height: 136,
        ),
      );
      await tester.tap(find.byType(AppHeroTile), warnIfMissed: false);
      await tester.pump();
      expect(go, 0);
    });

    testWidgets('collapses to idle when too narrow for the turn block', (
      tester,
    ) async {
      Widget hero(double width) => _host(
        AppHeroTile(
          label: 'Passar a vez',
          title: 'Léo',
          leadingCaption: 'Turno',
          leadingNumeral: const AppNumeral('3', scale: AppNumeralScale.heroi),
          onGo: onGo,
        ),
        width: width,
        height: 136,
      );
      await tester.pumpWidget(hero(360));
      expect(find.text('TURNO'), findsOneWidget);
      await tester.pumpWidget(hero(220));
      expect(tester.takeException(), isNull);
      expect(find.text('TURNO'), findsNothing);
    });

    testWidgets('announces label and title as one button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          AppHeroTile(label: 'Passar a vez', title: 'Léo', onGo: onGo),
          width: 360,
          height: 136,
        ),
      );
      expect(find.bySemanticsLabel('Passar a vez, Léo'), findsOneWidget);
      handle.dispose();
    });

    test('takes at most two secondary actions', () {
      expect(
        () => AppHeroTile(
          label: 'x',
          title: 'y',
          secondaryActions: const [
            AppHeroAction(icon: Icon(Icons.pause), label: 'a'),
            AppHeroAction(icon: Icon(Icons.pause), label: 'b'),
            AppHeroAction(icon: Icon(Icons.pause), label: 'c'),
          ],
        ),
        throwsAssertionError,
      );
    });
  });

  group('AppChoicePiece', () {
    testWidgets('selected is brass and announced as checked', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AppChoicePiece(
            label: 'Quatro jogadores',
            numeral: '4',
            selected: true,
            onTap: _hit,
          ),
        ),
      );
      final surface = _surfaceOf(tester, find.byType(AppChoicePiece));
      expect(surface.gradient, _t.gradients.brassPiece);
      expect(
        tester.getSemantics(find.byType(AppChoicePiece)),
        isSemantics(
          label: 'Quatro jogadores: 4',
          isInMutuallyExclusiveGroup: true,
          isChecked: true,
        ),
      );
      await tester.tap(find.byType(AppChoicePiece));
      expect(_count, 1);
      handle.dispose();
    });

    testWidgets('disabled does not fire', (tester) async {
      await tester.pumpWidget(
        _host(const AppChoicePiece(label: 'Seis', numeral: '6')),
      );
      await tester.tap(find.byType(AppChoicePiece), warnIfMissed: false);
      expect(_count, 0);
    });

    testWidgets('error is not brass even when selected', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppChoicePiece(
            label: 'Mesa',
            numeral: '4',
            selected: true,
            status: AppTileStatus.erro,
            onTap: _hit,
          ),
        ),
      );
      final surface = _surfaceOf(tester, find.byType(AppChoicePiece));
      expect(surface.gradient, _t.gradients.errorGlass);
      expect(find.text('TENTAR DE NOVO'), findsOneWidget);
    });

    testWidgets('armed confirms on the second tap', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        _host(
          AppChoicePiece(
            label: 'Cinco',
            numeral: '5',
            onArmedConfirm: () => confirmed++,
          ),
          armedScope: true,
        ),
      );
      await tester.tap(find.byType(AppChoicePiece));
      await tester.pump();
      expect(confirmed, 0);
      await tester.tap(find.byType(AppChoicePiece));
      await tester.pump();
      expect(confirmed, 1);
    });
  });

  group('AppNumeralPiece', () {
    testWidgets('fires and says its label with the value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AppNumeralPiece(
            label: 'Vida inicial',
            value: '40',
            selected: true,
            onTap: _hit,
          ),
          width: 100,
          height: 80,
        ),
      );
      await tester.tap(find.byType(AppNumeralPiece));
      expect(_count, 1);
      expect(
        tester.getSemantics(find.byType(AppNumeralPiece)),
        isSemantics(label: 'Vida inicial: 40', isChecked: true),
      );
      final size = tester.getSize(find.byType(AppNumeralPiece));
      expect(size.height, greaterThanOrEqualTo(48));
      handle.dispose();
    });

    testWidgets('disabled and loading do not fire', (tester) async {
      await tester.pumpWidget(
        _host(
          const Row(
            children: [
              AppNumeralPiece(label: 'Vida', value: '60'),
              AppNumeralPiece(
                label: 'Vida',
                value: '20',
                status: AppTileStatus.carregando,
                onTap: _hit,
              ),
            ],
          ),
          width: 200,
          height: 80,
        ),
      );
      for (final element in find.byType(AppNumeralPiece).evaluate()) {
        await tester.tapAt(tester.getCenter(find.byWidget(element.widget)));
      }
      await tester.pump();
      expect(_count, 0);
    });

    testWidgets('error replaces the numeral and is not brass', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppNumeralPiece(
            label: 'Vida',
            value: '40',
            selected: true,
            status: AppTileStatus.erro,
            onTap: _hit,
          ),
          width: 100,
          height: 80,
        ),
      );
      final surface = _surfaceOf(tester, find.byType(AppNumeralPiece));
      expect(surface.gradient, _t.gradients.errorGlass);
      expect(find.text('40'), findsNothing);
    });
  });

  group('AppRuleTile', () {
    testWidgets('toggles and is announced as toggled with its word', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AppRuleTile(
            title: 'Dano de comandante tira vida',
            on: true,
            onTap: _hit,
          ),
          width: 320,
          height: null,
        ),
      );
      expect(find.text('VALE'), findsOneWidget);
      final surface = _surfaceOf(tester, find.byType(AppRuleTile));
      expect(surface.gradient, _t.gradients.brassPiece);
      expect(
        tester.getSemantics(find.byType(AppRuleTile)),
        isSemantics(
          label: 'Dano de comandante tira vida',
          hasToggledState: true,
          isToggled: true,
          value: 'vale',
        ),
      );
      await tester.tap(find.byType(AppRuleTile));
      expect(_count, 1);
      handle.dispose();
    });

    testWidgets('checkbox role is announced as checked', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const AppRuleTile(
            title: 'Lembrar',
            on: false,
            role: AppRuleTileRole.checkbox,
            onTap: _hit,
          ),
          width: 320,
          height: null,
        ),
      );
      expect(find.text('NÃO VALE'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(AppRuleTile)),
        isSemantics(hasCheckedState: true, isChecked: false),
      );
      handle.dispose();
    });

    testWidgets('disabled does not toggle', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppRuleTile(title: 'Só na mesa', on: false),
          width: 320,
          height: null,
        ),
      );
      await tester.tap(find.byType(AppRuleTile), warnIfMissed: false);
      expect(_count, 0);
    });

    testWidgets('error does not look lit even when on', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppRuleTile(
            title: 'Não deu para salvar',
            on: true,
            status: AppTileStatus.erro,
            onTap: _hit,
          ),
          width: 320,
          height: null,
        ),
      );
      final surface = _surfaceOf(tester, find.byType(AppRuleTile));
      expect(surface.gradient, _t.gradients.errorGlass);
      expect(find.text('VALE'), findsNothing);
      expect(find.text('TOCAR DE NOVO'), findsOneWidget);
    });

    testWidgets('bad and on paints the wine with ivory ink', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppRuleTile(
            title: 'Concedeu',
            on: true,
            bad: true,
            size: AppRuleTileSize.estado,
            onTap: _hit,
          ),
          width: 160,
          height: null,
        ),
      );
      final surface = _surfaceOf(tester, find.byType(AppRuleTile));
      expect(surface.gradient, _t.gradients.wine);
      final title = tester.widget<Text>(find.text('Concedeu'));
      expect(title.style!.color, _t.palette.ivory);
    });

    testWidgets('a rich-text link fires on its own and does not toggle (F4)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await tester.pumpWidget(
        _host(
          AppRuleTile(
            title: 'Li e aceito os Termos de Uso',
            on: false,
            role: AppRuleTileRole.checkbox,
            onTap: _hit,
            titleSpans: [
              const TextSpan(text: 'Li e aceito os '),
              AppRuleTile.link('Termos de Uso', onTap: () => opened++),
            ],
          ),
          width: 320,
          height: null,
        ),
      );
      await tester.tap(find.text('Termos de Uso'));
      await tester.pump();
      expect(opened, 1);
      expect(_count, 0);
      final link = find.bySemanticsLabel('Termos de Uso');
      expect(link, findsOneWidget);
      expect(
        tester.getSemantics(link),
        isSemantics(isLink: true, hasTapAction: true),
      );
      final linkBox = tester.getSize(
        find
            .ancestor(
              of: find.text('Termos de Uso'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(linkBox.height, greaterThanOrEqualTo(48));
      handle.dispose();
    });
  });

  group('AppActionBar', () {
    testWidgets('fires the main action with a 48 dp target', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppActionBar(
            actions: [AppAction('Cancelar', onTap: _hit)],
            primary: AppAction.principal('Salvar', onTap: _hit),
          ),
          width: 400,
          height: null,
        ),
      );
      await tester.tap(find.text('SALVAR'));
      await tester.tap(find.text('CANCELAR'));
      expect(_count, 2);
      expect(
        tester.getSize(find.byType(AppActionButton).first).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('disabled action does not fire', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppActionBar(actions: [AppAction('Cancelar')]),
          width: 400,
          height: null,
        ),
      );
      await tester.tap(find.text('CANCELAR'), warnIfMissed: false);
      expect(_count, 0);
    });

    testWidgets('ember action needs two taps and disarms after 6 s', (
      tester,
    ) async {
      var ended = 0;
      await tester.pumpWidget(
        _host(
          AppActionBar(
            actions: [
              AppAction(
                'Encerrar',
                kind: AppActionKind.brasa,
                onArmedConfirm: () => ended++,
              ),
            ],
          ),
          width: 400,
          height: null,
          armedScope: true,
        ),
      );
      await tester.tap(find.text('ENCERRAR'));
      await tester.pump();
      expect(find.text('TOCAR DE NOVO'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('ENCERRAR'), findsOneWidget);
      await tester.tap(find.text('ENCERRAR'));
      await tester.pump();
      await tester.tap(find.text('TOCAR DE NOVO'));
      await tester.pump();
      expect(ended, 1);
    });

    testWidgets('rejects two main actions', (tester) async {
      await tester.pumpWidget(
        _host(
          const AppActionBar(
            actions: [AppAction.principal('A', onTap: _hit)],
            primary: AppAction.principal('B', onTap: _hit),
          ),
          width: 400,
          height: null,
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('AppPlaque', () {
    testWidgets('edits text and shows the caption above', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          AppPlaque(controller: controller, caption: 'Nome na mesa'),
          width: 320,
          height: null,
        ),
      );
      expect(find.text('NOME NA MESA'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('app-plaque-field')),
        'Bia',
      );
      expect(controller.text, 'Bia');
      expect(
        tester.getSize(find.byType(AppPlaque)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('error word and validator turn the wire ember', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          Form(
            key: formKey,
            child: Column(
              children: [
                AppPlaque(
                  controller: TextEditingController(text: 'Rafa'),
                  caption: 'Nome do deck',
                  errorWord: 'já existe',
                ),
                AppPlaque(
                  controller: controller,
                  kind: AppPlaqueKind.senha,
                  caption: 'Senha',
                  validator: (value) => (value ?? '').length < 8
                      ? 'Use pelo menos 8 caracteres.'
                      : null,
                ),
              ],
            ),
          ),
          width: 320,
          height: 400,
        ),
      );
      expect(find.text('JÁ EXISTE'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(AppPlaque).last,
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(field.obscureText, isTrue);
      expect(field.autocorrect, isFalse);
    });

    testWidgets('disabled plaque does not edit', (tester) async {
      final controller = TextEditingController(text: 'Bia');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          AppPlaque(controller: controller, enabled: false),
          width: 320,
          height: null,
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });
  });

  group('without BtTokens in the theme', () {
    testWidgets('every piece falls back to the standard tokens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Scaffold(
            body: BtArmedScope(
              child: ListView(
                children: [
                  const SizedBox(
                    height: 112,
                    child: AppTile(label: 'Regras', onTap: _hit),
                  ),
                  SizedBox(
                    height: 136,
                    child: AppHeroTile(
                      label: 'Passar a vez',
                      title: 'Léo',
                      onGo: _hit,
                    ),
                  ),
                  const AppNumeral('40'),
                  const SizedBox(
                    height: 128,
                    child: AppChoicePiece(label: 'Quatro', numeral: '4'),
                  ),
                  const Center(
                    child: AppNumeralPiece(label: 'Vida', value: '40'),
                  ),
                  const AppRuleTile(title: 'Regra', on: true, onTap: _hit),
                  const AppActionBar(
                    primary: AppAction.principal('Salvar', onTap: _hit),
                  ),
                  AppPlaque(controller: controller, caption: 'Nome'),
                  const SizedBox(
                    height: 300,
                    child: AppTileOverlay(
                      title: 'Folha',
                      onClose: _hit,
                      body: [SizedBox.shrink()],
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: AppTileBoard(
                      rows: const [
                        AppTileRowSpec(
                          children: [AppTile(label: 'Dados', onTap: _hit)],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      final context = tester.element(find.text('REGRAS'));
      expect(Theme.of(context).extension<BtTokens>(), isNull);
      expect(BtTokens.of(context), same(BtTokens.standard));
      await tester.tap(find.text('REGRAS'));
      expect(_count, 1);
    });
  });
}
