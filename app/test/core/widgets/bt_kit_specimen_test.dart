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

/// Specimen of the BrewTact kit (BT-UX-KIT-001), laid out like
/// docs/design/ui-kit/specimen-390.png and specimen-1440.png, so a visual
/// regression of the kit is caught by image and not only by regex.
///
/// Regenerate with:
/// `flutter test --update-goldens test/core/widgets/bt_kit_specimen_test.dart`
Future<void> _loadFonts() async {
  await Future.wait([
    (FontLoader(
      AppTheme.uiFontFamily,
    )..addFont(rootBundle.load('assets/lotus/fonts/Inter.ttf'))).load(),
    (FontLoader(
      AppTheme.displayFontFamily,
    )..addFont(rootBundle.load('assets/lotus/fonts/Fraunces.ttf'))).load(),
    (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
  ]);
}

const _specimenKey = ValueKey<String>('bt-kit-specimen');

void main() {
  setUpAll(_loadFonts);

  for (final profile in const [
    (width: 390.0, ratio: 2.0, golden: 'goldens/bt_kit_specimen_390.png'),
    (width: 1440.0, ratio: 1.0, golden: 'goldens/bt_kit_specimen_1440.png'),
  ]) {
    testWidgets('kit specimen at ${profile.width.toInt()} matches golden', (
      tester,
    ) async {
      tester.view.devicePixelRatio = profile.ratio;
      tester.view.physicalSize = Size(
        profile.width * profile.ratio,
        12000 * profile.ratio,
      );
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_SpecimenApp(width: profile.width));
      await tester.pump();
      final height = tester.getSize(find.byKey(_specimenKey)).height;
      tester.view.physicalSize = Size(
        profile.width * profile.ratio,
        height * profile.ratio,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(_specimenKey),
        matchesGoldenFile(profile.golden),
      );
    });
  }
}

class _SpecimenApp extends StatelessWidget {
  const _SpecimenApp({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        backgroundColor: AppTheme.backgroundAbyss,
        body: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              key: _specimenKey,
              child: ColoredBox(
                color: AppTheme.backgroundAbyss,
                child: _Specimen(width: width),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Specimen extends StatelessWidget {
  const _Specimen({required this.width});

  final double width;

  bool get wide => width >= 840;

  @override
  Widget build(BuildContext context) {
    final gutter = wide ? 64.0 : 16.0;
    final inner = width - 2 * gutter;
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          gutter,
          AppTheme.space24,
          gutter,
          AppTheme.space40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kit BrewTact · vitral com a disciplina dos azulejos vivos',
              style: BtType.display(
                wide ? 26 : 24,
                600,
                height: 1.15,
              ).copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'Cinco primitivas e cinco peças derivadas, nos valores do '
                'protótipo do contador de vida. Vidro = ação neutra · cor '
                'cheia = está valendo · latão = jogada principal e '
                'selecionado · tracejado = vazio, sem dono · brasa = encerra '
                'ou destrói.',
                style: BtType.ui(
                  12,
                  500,
                  height: 1.4,
                ).copyWith(color: AppTheme.textSecondary),
              ),
            ),
            _Section(
              title: '1 · bt-board · bt-tile · bt-hero · bt-overlay (véu + ×)',
              child: _BoardSection(width: inner, wide: wide),
            ),
            _Section(
              title: '2 · bt-tile — todos os estados',
              child: _TileStates(width: inner, wide: wide),
            ),
            _Section(
              title: '3 · bt-numeral — Fraunces, lining-nums tabular-nums',
              child: _Numerals(wide: wide),
            ),
            _Section(
              title: '4 · bt-piece — peça de escolha com miniatura',
              child: _ChoicePieces(width: inner, wide: wide),
            ),
            _Section(
              title: '5 · bt-vpiece — peça-numeral',
              child: const _NumeralPieces(),
            ),
            _Section(
              title: '6 · bt-rule — peça-regra que acende e diz vale',
              child: _Rules(width: inner, wide: wide),
            ),
            _Section(
              title:
                  '7 · bt-overlay — véu sobre a mesa viva, seta de '
                  'volta, × único, rodapé fora da rolagem',
              child: _OverlaySection(wide: wide),
            ),
            _Section(
              title: '8 · vazio como peça, não como parede de texto',
              child: SizedBox(
                width: wide ? 560 : inner,
                child: const AppTile(
                  icon: Icon(Icons.copy_all_outlined),
                  label: 'Nenhuma partida guardada',
                  status: AppTileStatus.vazio,
                  numeral: AppNumeral('0', scale: AppNumeralScale.vazio),
                  onTap: _noop,
                ),
              ),
            ),
            _Section(
              title: '11 · bt-rule (estado) + bt-plaque',
              child: _PlayerSection(width: inner, wide: wide),
            ),
          ],
        ),
      ),
    );
  }
}

void _noop() {}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppTheme.space28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: BtType.ui(
              11,
              800,
              height: 1.2,
              tracking: 0.1,
            ).copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.space12),
          child,
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text, {this.lead});

  final String text;
  final String? lead;

  @override
  Widget build(BuildContext context) {
    final style = BtType.ui(
      9,
      700,
      height: 1.3,
      tracking: 0.08,
    ).copyWith(color: AppTheme.textHint);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppTheme.space6),
      child: Text.rich(
        TextSpan(
          style: style,
          children: [
            if (lead != null) TextSpan(text: '${lead!.toUpperCase()} · '),
            TextSpan(text: text.toUpperCase()),
          ],
        ),
      ),
    );
  }
}

/// The live table under the board: seat panels with the table numeral.
class _Mesa extends StatelessWidget {
  const _Mesa({required this.columns, required this.values});

  final int columns;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final rows = (values.length / columns).ceil();
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppTheme.space6),
      child: Column(
        children: [
          for (var r = 0; r < rows; r++) ...[
            if (r > 0) const SizedBox(height: AppTheme.space6),
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: AppTheme.space6),
                    Expanded(
                      child: _SeatPanel(
                        color: AppTheme.btSeats[(r * columns + c + 3) % 10],
                        value: values[(r * columns + c) % values.length],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeatPanel extends StatelessWidget {
  const _SeatPanel({required this.color, required this.value});

  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.metrics.radiusPanel),
        gradient: tokens.vitral(color, middle: 0.5),
        border: Border.all(color: tokens.palette.filete),
      ),
      child: AppNumeralMesa(value, semanticsLabel: '$value pontos de vida'),
    );
  }
}

class _BoardSection extends StatelessWidget {
  const _BoardSection({required this.width, required this.wide});

  final double width;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final board = AppTileBoard(
      heroRow: 1,
      center: AppCloseX(onTap: _noop),
      onDismiss: _noop,
      rows: [
        AppTileRowSpec(
          weights: const [1, 2, 1, 1, 1],
          children: [
            const AppTile(
              icon: Icon(Icons.undo),
              label: 'Desfazer',
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.casino_outlined),
              label: 'Dados',
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.explore_outlined),
              label: 'Quem começa',
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.workspace_premium),
              label: 'Coroa',
              tone: AppTileTone.vitral,
              vitralColor: AppTheme.btVitralCrown,
              vitralColorDeep: AppTheme.btVitralCrownDeep,
              estado: AppTileEstado('Bia', dotColor: AppTheme.btSeatAmbar),
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.flag_outlined),
              label: 'Iniciativa',
              tone: AppTileTone.livre,
              estado: AppTileEstado.off('sem dono'),
              onTap: _noop,
            ),
          ],
        ),
        AppTileRowSpec.hero(
          children: [
            AppHeroTile(
              leadingCaption: 'Turno',
              leadingNumeral: const AppNumeral(
                '3',
                scale: AppNumeralScale.heroi,
                semanticsLabel: 'turno 3',
              ),
              label: 'Passar a vez',
              title: 'Léo',
              pips: const [
                AppHeroPip(color: AppTheme.btSeatBrasa),
                AppHeroPip(color: AppTheme.btSeatMusgo, current: true),
                AppHeroPip(color: AppTheme.btSeatIndigo),
                AppHeroPip(color: AppTheme.btSeatAmbar, out: true),
              ],
              onGo: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.dark_mode_outlined),
              label: 'Dia / Noite',
              tone: AppTileTone.vitral,
              vitralColor: AppTheme.btVitralNight,
              vitralColorDeep: AppTheme.btVitralNightDeep,
              estado: AppTileEstado('noite'),
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.layers_outlined),
              label: 'Plano',
              estado: AppTileEstado.off('desligado'),
              onTap: _noop,
            ),
          ],
        ),
        AppTileRowSpec(
          weights: const [2, 1, 1, 1, 1],
          children: [
            const AppTile(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Mesa',
              numeral: AppNumeral('4', semanticsLabel: '4 jogadores'),
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.tune),
              label: 'Regras',
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.copy_all_outlined),
              label: 'Partidas',
              estado: AppNumeral(
                '3',
                scale: AppNumeralScale.canto,
                semanticsLabel: '3 partidas',
              ),
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.refresh),
              label: 'Nova partida',
              tone: AppTileTone.brasaTinta,
              onTap: _noop,
            ),
            const AppTile(
              icon: Icon(Icons.outlined_flag),
              label: 'Encerrar partida',
              onTap: _noop,
            ),
          ],
        ),
      ],
    );
    // Like specimen-390.png, a narrow page shows the board in its 780
    // layout scaled down, not re-flowed.
    final layoutWidth = wide ? width : 780.0;
    final scene = SizedBox(
      width: layoutWidth,
      height: 440,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Mesa(
            columns: wide ? 4 : 2,
            values: const ['34', '21', '18', '9', '40', '27', '120', '12'],
          ),
          board,
        ],
      ),
    );
    if (wide) return scene;
    return SizedBox(
      width: width,
      height: 440 * width / layoutWidth,
      child: FittedBox(child: scene),
    );
  }
}

class _TileStates extends StatelessWidget {
  const _TileStates({required this.width, required this.wide});

  final double width;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tileWidth = wide ? 164.0 : (width - AppTheme.space8) / 2;
    Widget cell(Widget tile, String caption, [String? lead]) => SizedBox(
      width: tileWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 112, child: tile),
          _Caption(caption, lead: lead),
        ],
      ),
    );
    return Wrap(
      spacing: AppTheme.space8,
      runSpacing: AppTheme.space14,
      children: [
        cell(
          const AppTile(
            icon: Icon(Icons.layers_outlined),
            label: 'Neutro',
            onTap: _noop,
          ),
          'ação sem estado',
          'vidro',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.layers_outlined),
            label: 'Valendo',
            tone: AppTileTone.vitral,
            vitralColor: AppTheme.btVitralPlane,
            vitralColorDeep: AppTheme.btVitralPlaneDeep,
            estado: AppTileEstado('caos'),
            onTap: _noop,
          ),
          'está valendo',
          'vitral',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.workspace_premium),
            label: 'Selecionado',
            selected: true,
            onTap: _noop,
          ),
          'jogada principal',
          'latão',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.flag_outlined),
            label: 'Livre',
            tone: AppTileTone.livre,
            estado: AppTileEstado.off('sem dono'),
            onTap: _noop,
          ),
          'vazio',
          'tracejado',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.flag),
            label: 'Brasa',
            tone: AppTileTone.brasaTinta,
            onTap: _noop,
          ),
          'destrói',
          'brasa na tinta',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.flag),
            label: 'Armado',
            tone: AppTileTone.brasaTinta,
            armed: true,
            onTap: _noop,
            onArmedConfirm: _noop,
          ),
          'dois toques',
          'aro de brasa',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.flag),
            label: 'Brasa cheia',
            tone: AppTileTone.brasaCheia,
            onTap: _noop,
          ),
          'estado ruim valendo',
          'vinho',
        ),
        cell(
          const AppTile(icon: Icon(Icons.undo), label: 'Desabilitado'),
          'opacidade .38',
          'derivado',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.copy_all_outlined),
            label: 'Carregando',
            status: AppTileStatus.carregando,
            estado: AppTileEstado('3'),
          ),
          'brilho que atravessa',
          'derivado',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.refresh),
            label: 'Erro',
            status: AppTileStatus.erro,
            onTap: _noop,
          ),
          'brasa na tinta, sem brasa cheia',
          'derivado',
        ),
        cell(
          const AppTile(
            icon: Icon(Icons.copy_all_outlined),
            label: 'Vazio',
            status: AppTileStatus.vazio,
            estado: AppTileEstado.off('nenhuma'),
            onTap: _noop,
          ),
          'tracejado em latão',
          'derivado',
        ),
      ],
    );
  }
}

class _Numerals extends StatelessWidget {
  const _Numerals({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    Widget item(Widget numeral, String caption) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [numeral, _Caption(caption)],
    );
    Widget panel(String value, Color color, String caption) => item(
      SizedBox(
        width: wide ? 140 : 160,
        height: 110,
        child: _SeatPanel(color: color, value: value),
      ),
      caption,
    );
    return Wrap(
      spacing: AppTheme.space24,
      runSpacing: AppTheme.space16,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        item(const AppNumeral('40'), 'tile · 56 px / .8'),
        item(
          const AppNumeral('3', scale: AppNumeralScale.heroi),
          'herói · 70 px / .8',
        ),
        item(
          const AppNumeral('12', scale: AppNumeralScale.canto),
          'canto · 32 px',
        ),
        panel('27', AppTheme.btSeatMusgo, 'mesa · medido pelo card'),
        panel('120', AppTheme.btSeatBrasa, 'mesa · três dígitos'),
      ],
    );
  }
}

class _Seats extends StatelessWidget {
  const _Seats({required this.top, required this.bottom});

  final List<Color> top;
  final List<Color> bottom;

  @override
  Widget build(BuildContext context) {
    Widget line(List<Color> colors, bool up) => Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < colors.length; i++) ...[
            if (i > 0) const SizedBox(width: AppTheme.space4),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors[i],
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(up ? 6 : 3),
                    bottom: Radius.circular(up ? 3 : 6),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return Column(
      children: [
        line(top, true),
        const SizedBox(height: AppTheme.space4),
        line(bottom, false),
      ],
    );
  }
}

class _ChoicePieces extends StatelessWidget {
  const _ChoicePieces({required this.width, required this.wide});

  final double width;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    const s = AppTheme.btSeats;
    final pieceWidth = wide ? 164.0 : (width - AppTheme.space8) / 2;
    Widget cell(Widget piece, String caption) => SizedBox(
      width: pieceWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 128, child: piece),
          _Caption(caption),
        ],
      ),
    );
    final three = _Seats(top: [s[2], s[3]], bottom: [s[0]]);
    final four = _Seats(top: [s[2], s[3]], bottom: [s[0], s[1]]);
    final five = _Seats(top: [s[2], s[4], s[5]], bottom: [s[0], s[1]]);
    return Wrap(
      spacing: AppTheme.space8,
      runSpacing: AppTheme.space14,
      children: [
        cell(
          AppChoicePiece(
            label: 'Três jogadores',
            thumbnail: three,
            numeral: '3',
            onTap: _noop,
          ),
          'neutro',
        ),
        cell(
          AppChoicePiece(
            label: 'Quatro jogadores',
            thumbnail: four,
            numeral: '4',
            caption: 'atual',
            selected: true,
            onTap: _noop,
          ),
          'selecionado',
        ),
        cell(
          AppChoicePiece(
            label: 'Cinco jogadores',
            thumbnail: five,
            numeral: '5',
            caption: 'confirmar',
            armed: true,
            onTap: _noop,
            onArmedConfirm: _noop,
          ),
          'armado',
        ),
        cell(
          AppChoicePiece(
            label: 'Seis jogadores',
            thumbnail: five,
            numeral: '6',
          ),
          'desabilitado (derivado)',
        ),
        cell(
          const AppChoicePiece(
            label: 'Carregando',
            numeral: '4',
            status: AppTileStatus.carregando,
          ),
          'carregando (derivado)',
        ),
        cell(
          AppChoicePiece(
            label: 'Mesa',
            thumbnail: four,
            status: AppTileStatus.erro,
            onTap: _noop,
          ),
          'erro (derivado)',
        ),
        cell(
          const AppChoicePiece(
            label: 'Sem mesa',
            caption: 'sem mesa',
            status: AppTileStatus.vazio,
            onTap: _noop,
          ),
          'vazio (derivado)',
        ),
      ],
    );
  }
}

class _NumeralPieces extends StatelessWidget {
  const _NumeralPieces();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTheme.space8,
          runSpacing: AppTheme.space10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const _BandCaption(icon: Icons.favorite, text: 'Vida\ninicial'),
            const AppNumeralPiece(
              label: 'Vida inicial',
              value: '20',
              onTap: _noop,
            ),
            const AppNumeralPiece(
              label: 'Vida inicial',
              value: '30',
              onTap: _noop,
            ),
            const AppNumeralPiece(
              label: 'Vida inicial',
              value: '40',
              selected: true,
              onTap: _noop,
            ),
            const AppNumeralPiece(
              label: 'Vida inicial',
              value: '50',
              armed: true,
              onTap: _noop,
              onArmedConfirm: _noop,
            ),
            const AppNumeralPiece(label: 'Vida inicial', value: '60'),
            const AppNumeralPiece(
              label: 'Vida inicial',
              value: '—',
              status: AppTileStatus.carregando,
            ),
            const AppNumeralPiece(
              label: 'Vida inicial',
              value: '—',
              status: AppTileStatus.erro,
              onTap: _noop,
            ),
            const AppNumeralPiece(
              label: 'Vida inicial',
              value: '0',
              status: AppTileStatus.vazio,
              onTap: _noop,
            ),
          ],
        ),
        const _Caption(
          'neutro · neutro · selecionado · armado · desabilitado · '
          'carregando · erro · vazio',
        ),
      ],
    );
  }
}

class _BandCaption extends StatelessWidget {
  const _BandCaption({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: tokens.palette.heart),
        const SizedBox(height: AppTheme.space3),
        Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: BtType.ui(
            10.5,
            800,
            height: 1.15,
            tracking: 0.1,
          ).copyWith(color: tokens.palette.mist),
        ),
      ],
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules({required this.width, required this.wide});

  final double width;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final gap = tokens.metrics.gapPiece;
    final half = ((wide ? width : width) - gap) / 2;
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: half, child: a),
        SizedBox(width: gap),
        SizedBox(width: half, child: b),
      ],
    );
    final caption = tokens.typography.bandCaption.copyWith(
      color: tokens.palette.mist,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pair(
          const AppRuleTile(
            icon: Icon(Icons.shield),
            title: 'Dano de comandante tira vida',
            on: true,
            onTap: _noop,
          ),
          const AppRuleTile(
            icon: Icon(Icons.favorite),
            title: 'Tocar no número abre o teclado',
            on: true,
            onTap: _noop,
          ),
        ),
        SizedBox(height: gap),
        pair(
          const AppRuleTile(
            icon: Icon(Icons.water_drop),
            title: 'Marcadores no próprio card',
            on: false,
            onTap: _noop,
          ),
          const AppRuleTile(
            icon: Icon(Icons.shield_outlined),
            title: 'Carregando',
            on: false,
            status: AppTileStatus.carregando,
          ),
        ),
        SizedBox(height: gap),
        pair(
          const AppRuleTile(
            icon: Icon(Icons.shield),
            title: 'Não deu para salvar a regra',
            on: true,
            status: AppTileStatus.erro,
            onTap: _noop,
          ),
          const AppRuleTile(
            icon: Icon(Icons.favorite_border),
            title: 'Só na mesa de duas faixas',
            on: false,
            offWord: 'desabilitado',
          ),
        ),
        SizedBox(height: gap),
        pair(
          AppRuleTile(
            icon: const Icon(Icons.verified_user_outlined),
            title: 'Li e aceito os Termos de Uso e a Política de Privacidade',
            titleSpans: [
              const TextSpan(text: 'Li e aceito os '),
              AppRuleTile.link('Termos de Uso', onTap: _noop),
              const TextSpan(text: ' e a '),
              AppRuleTile.link('Política de Privacidade', onTap: _noop),
            ],
            on: true,
            role: AppRuleTileRole.checkbox,
            onWord: 'aceito',
            offWord: 'não aceito',
            onTap: _noop,
          ),
          const SizedBox.shrink(),
        ),
        const SizedBox(height: AppTheme.space16),
        Text('DIA E NOITE', style: caption),
        const SizedBox(height: AppTheme.space7),
        const Wrap(
          spacing: AppTheme.space8,
          children: [
            AppRuleTile(
              icon: Icon(Icons.close),
              title: 'Sem',
              on: false,
              size: AppRuleTileSize.small,
              onTap: _noop,
            ),
            AppRuleTile(
              icon: Icon(Icons.wb_sunny_outlined),
              title: 'Dia',
              on: false,
              size: AppRuleTileSize.small,
              onTap: _noop,
            ),
            AppRuleTile(
              icon: Icon(Icons.dark_mode),
              title: 'Noite',
              on: true,
              size: AppRuleTileSize.small,
              onTap: _noop,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space16),
        Text('SEGURAR MUDA DE', style: caption),
        const SizedBox(height: AppTheme.space7),
        const Wrap(
          spacing: AppTheme.space8,
          children: [
            AppNumeralPiece(label: 'Segurar muda de', value: '5', onTap: _noop),
            AppNumeralPiece(
              label: 'Segurar muda de',
              value: '10',
              selected: true,
              onTap: _noop,
            ),
            AppNumeralPiece(
              label: 'Segurar muda de',
              value: '20',
              onTap: _noop,
            ),
          ],
        ),
      ],
    );
  }
}

class _OverlaySection extends StatelessWidget {
  const _OverlaySection({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    return SizedBox(
      height: wide ? 480 : 560,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Mesa(
            columns: wide ? 4 : 2,
            values: const ['34', '21', '18', '9', '40', '27', '12', '7'],
          ),
          AppTileOverlay(
            title: 'Regras da mesa',
            onBack: _noop,
            onClose: _noop,
            body: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppRuleTile(
                      icon: Icon(Icons.shield),
                      title: 'Dano de comandante tira vida',
                      on: true,
                      onTap: _noop,
                    ),
                  ),
                  SizedBox(width: AppTheme.space10),
                  Expanded(
                    child: AppRuleTile(
                      icon: Icon(Icons.favorite),
                      title: 'Tocar no número abre o teclado',
                      on: true,
                      onTap: _noop,
                    ),
                  ),
                ],
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.palette.hintSurface,
                  borderRadius: BorderRadius.circular(
                    tokens.metrics.radiusHint,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppTheme.space12,
                    AppTheme.space10,
                    AppTheme.space12,
                    AppTheme.space10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.add, size: 20, color: tokens.palette.brass),
                      const SizedBox(width: AppTheme.space10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: tokens.typography.hint.copyWith(
                              color: tokens.palette.mist,
                            ),
                            children: [
                              TextSpan(
                                text: 'Toque',
                                style: TextStyle(color: tokens.palette.ivory),
                              ),
                              const TextSpan(
                                text:
                                    ' na direita soma 1, na esquerda tira 1. '
                                    'Segure para mudar de 10 em 10.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            footer: const AppActionBar(
              primary: AppAction.principal('Salvar regras', onTap: _noop),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSection extends StatefulWidget {
  const _PlayerSection({required this.width, required this.wide});

  final double width;
  final bool wide;

  @override
  State<_PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<_PlayerSection> {
  final _name = TextEditingController(text: 'Bia');
  final _empty = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _empty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final column = widget.wide ? 560.0 : widget.width;
    final third = (column - 2 * AppTheme.space8) / 3;
    final caption = tokens.typography.bandCaption.copyWith(
      color: tokens.palette.mist,
    );
    return SizedBox(
      width: column,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NA PARTIDA', style: caption),
          const SizedBox(height: AppTheme.space7),
          Row(
            children: [
              SizedBox(
                width: third,
                child: const AppRuleTile(
                  icon: Icon(Icons.workspace_premium),
                  title: 'Coroa',
                  on: true,
                  onWord: 'com ela',
                  offWord: 'sem ela',
                  size: AppRuleTileSize.estado,
                  onTap: _noop,
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              SizedBox(
                width: third,
                child: const AppRuleTile(
                  icon: Icon(Icons.flag_outlined),
                  title: 'Iniciativa',
                  on: false,
                  onWord: 'tem',
                  offWord: 'não tem',
                  size: AppRuleTileSize.estado,
                  onTap: _noop,
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              SizedBox(
                width: third,
                child: const AppRuleTile(
                  icon: Icon(Icons.outlined_flag),
                  title: 'Concedeu',
                  on: true,
                  bad: true,
                  onWord: 'concedeu',
                  offWord: 'jogando',
                  size: AppRuleTileSize.estado,
                  onTap: _noop,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),
          AppPlaque(controller: _name, caption: 'Nome na mesa'),
          const SizedBox(height: AppTheme.space16),
          AppPlaque(
            controller: _empty,
            caption: 'Nome do deck',
            placeholder: 'Rafa · Atraxa',
            errorWord: 'já existe',
          ),
        ],
      ),
    );
  }
}
