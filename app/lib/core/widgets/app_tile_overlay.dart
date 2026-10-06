import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/bt_tokens.dart';
import 'app_tile_board.dart';
import 'bt_surface.dart';

/// Which veil an [AppTileOverlay] lays over the live surface.
enum AppOverlayVeil {
  /// `.sheet`: radial `.80 → .93` of obsidian, `blur(8px) saturate(.8)`.
  folha,

  /// `.menu`: radial `.42 → .78`, `blur(3px) saturate(.8)`.
  menu,
}

/// The secondary screen (`.sheet`, docs/design/ui-kit-spec.md §4.4).
///
/// Opens over the previous surface, darkened and blurred, never as an
/// opaque route or a boxed dialog. One exit only — the [onClose] ✕; the
/// optional [onBack] arrow returns to the menu and is not a second exit.
/// The [footer] stays outside the scroll and never covers content. The
/// column is at most 560 wide, centered, at every width.
class AppTileOverlay extends StatelessWidget {
  const AppTileOverlay({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.onBack,
    required this.onClose,
    this.veil = AppOverlayVeil.folha,
    this.maxContentWidth = 560,
    this.leading,
  });

  /// Fraunces 600 22px.
  final String title;

  /// Free slots, 16 apart.
  final List<Widget> body;

  /// Usually an [AppActionBar]; outside the scroll.
  final Widget? footer;

  /// The ‹ arrow back to the menu.
  final VoidCallback? onBack;

  /// The single ✕. Closes this overlay (`Navigator.pop`), not the stack.
  final VoidCallback onClose;
  final AppOverlayVeil veil;
  final double maxContentWidth;

  /// Player dot + name, before the title (vt-05).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final metrics = tokens.metrics;
    final isSheet = veil == AppOverlayVeil.folha;

    final head = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTheme.space18,
        AppTheme.space12,
        AppTheme.space10,
        AppTheme.space6,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            AppBackArrow(onTap: onBack!),
            const SizedBox(width: AppTheme.space10),
          ],
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTheme.space10),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tokens.typography.sheetTitle.copyWith(
                color: tokens.palette.ivory,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space10),
          AppCloseX(onTap: onClose, size: AppCloseXSize.head),
        ],
      ),
    );

    final bodyColumn = FocusScope(
      autofocus: true,
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppTheme.space18,
          AppTheme.space4,
          AppTheme.space18,
          AppTheme.space18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < body.length; i++) ...[
              if (i > 0) const SizedBox(height: AppTheme.space16),
              body[i],
            ],
          ],
        ),
      ),
    );

    final column = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            head,
            Expanded(child: bodyColumn),
            if (footer != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: tokens.palette.filete)),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppTheme.space18,
                    AppTheme.space10,
                    AppTheme.space18,
                    AppTheme.space14,
                  ),
                  child: footer,
                ),
              ),
          ],
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): onClose,
      },
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: BtBackdrop.filter(
                  isSheet ? metrics.blurSheet : metrics.blurMenu,
                  metrics.backdropSaturation,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: isSheet
                        ? tokens.gradients.veilSheet
                        : tokens.gradients.veilMenu,
                  ),
                ),
              ),
            ),
            SafeArea(child: column),
          ],
        ),
      ),
    );
  }
}

/// The two drawings of the single ✕ (§2 rule 3).
enum AppCloseXSize {
  /// On the board: 64×64 obsidian, brass rim (`--bt-sombra-x`), icon 24
  /// stroke 2.6, in the 80px hole of the hero row.
  board,

  /// In a sheet header: 44×44 slate-850 with a slate-750 filet, icon 18;
  /// the touch target grows to 48 with transparent room.
  head,
}

/// The single ✕ of a secondary screen.
class AppCloseX extends StatelessWidget {
  const AppCloseX({
    super.key,
    required this.onTap,
    this.size = AppCloseXSize.board,
    this.semanticsLabel = 'Fechar',
  });

  final VoidCallback? onTap;
  final AppCloseXSize size;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    final board = size == AppCloseXSize.board;
    final dimension = board ? 64.0 : 44.0;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: BtPressable(
          radius: dimension / 2,
          shape: BoxShape.circle,
          onTap: onTap,
          child: BtTouchTarget(
            child: SizedBox.square(
              dimension: dimension,
              child: BtSurface(
                gradient: LinearGradient(
                  colors: board
                      ? [tokens.palette.obsidian, tokens.palette.obsidian]
                      : [tokens.palette.slate850, tokens.palette.slate850],
                ),
                radius: dimension / 2,
                shadows: board ? tokens.shadows.x : tokens.shadows.headX,
                child: Center(
                  child: BtStrokeGlyph(
                    BtGlyphShape.close,
                    size: board ? 24 : 18,
                    strokeWidth: board ? 2.6 : 2,
                    color: tokens.palette.ivory,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ‹ arrow of a sheet header (`.back`): 44×44, mist, stroke 2 (F5);
/// touch target 48.
class AppBackArrow extends StatelessWidget {
  const AppBackArrow({
    super.key,
    required this.onTap,
    this.semanticsLabel = 'Voltar ao menu',
  });

  final VoidCallback? onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = BtTokens.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: BtPressable(
          radius: 22,
          shape: BoxShape.circle,
          onTap: onTap,
          child: BtTouchTarget(
            child: SizedBox.square(
              dimension: 44,
              child: Center(
                child: BtStrokeGlyph(
                  BtGlyphShape.chevronBack,
                  size: 20,
                  strokeWidth: 2,
                  color: tokens.palette.mist,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [builder] over the live surface. Never a boxed dialog or a modal
/// sheet: a non-opaque [PageRouteBuilder] whose veil belongs to the widget,
/// not to the route (§4.4d).
Future<T?> showAppTileOverlay<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final still = MediaQuery.disableAnimationsOf(context);
  final fade = BtTokens.of(context).metrics.fadeDuration;
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      transitionDuration: still ? Duration.zero : fade,
      reverseTransitionDuration: still ? Duration.zero : fade,
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (context, animation, secondary) => builder(context),
    ),
  );
}
