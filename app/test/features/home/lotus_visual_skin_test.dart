import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_visual_skin.dart';
import 'package:manaloom/features/home/lotus/lotus_webview_contract.dart';

void main() {
  group('lotus visual skin', () {
    test('injects a dedicated ManaLoom style tag', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusVisualSkinStyleIds.primary),
      );
      expect(lotusInjectedVisualSkinScript, contains("createElement('style')"));
      expect(
        lotusInjectedVisualSkinScript,
        contains('style.textContent = css;'),
      );
    });

    test('targets the safe Phase 1 surfaces', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.playerCard),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.menuButton),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.mainGameTimer),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.turnTracker),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusDomSelectors.optionCard),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('.commander-damage-overlay'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('.turn-tracker-hint-overlay'),
      );
    });

    test('uses ManaLoom typography and visual tokens', () {
      expect(lotusInjectedVisualSkinScript, contains('Inter'));
      expect(lotusInjectedVisualSkinScript, contains('Fraunces'));
      expect(lotusInjectedVisualSkinScript, contains('@font-face'));
      expect(lotusInjectedVisualSkinScript, contains('fonts/Inter.ttf'));
      expect(lotusInjectedVisualSkinScript, contains('fonts/Fraunces.ttf'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('fontSet.load(\'400 16px "Inter"\')'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('fontSet.load(\'650 16px "Fraunces"\')'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        isNot(contains('fonts.googleapis.com')),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('--manaloom-shell-shadow'),
      );
      expect(lotusInjectedVisualSkinScript, contains('--manaloom-shell-panel'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('--manaloom-player-accent'),
      );
      expect(lotusInjectedVisualSkinScript, contains(':nth-of-type(4n + 1)'));
      expect(lotusInjectedVisualSkinScript, contains(':nth-of-type(4n + 2)'));
      expect(lotusInjectedVisualSkinScript, contains(':nth-of-type(4n + 3)'));
      expect(lotusInjectedVisualSkinScript, contains(':nth-of-type(4n)'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('.increase-button.life .font'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('.decrease-button.life .font'),
      );
      expect(lotusInjectedVisualSkinScript, contains('.char-plus'));
      expect(lotusInjectedVisualSkinScript, contains('.char-minus'));
      expect(lotusInjectedVisualSkinScript, contains('content: \\"+\\"'));
      expect(lotusInjectedVisualSkinScript, contains('content: \\"−\\"'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('rgba(247, 241, 226, 0.68)'),
      );
      expect(lotusInjectedVisualSkinScript, contains('clamp(13px, 4vw, 19px)'));
      expect(lotusInjectedVisualSkinScript, contains('white-space: normal'));
      expect(lotusInjectedVisualSkinScript, contains('word-break: break-word'));
    });

    test('keeps the tabletop restrained and touch targets readable', () {
      expect(lotusInjectedVisualSkinScript, contains('background: #02050b'));
      expect(lotusInjectedVisualSkinScript, contains('font-size: 11px'));
      expect(lotusInjectedVisualSkinScript, contains('min-height: 48px'));
      expect(lotusInjectedVisualSkinScript, contains('height: 64px'));
      expect(lotusInjectedVisualSkinScript, contains('box-sizing: border-box'));
      expect(lotusInjectedVisualSkinScript, contains('overflow: hidden'));
      expect(lotusInjectedVisualSkinScript, contains('box-shadow: none'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('calc((100% - 12px) / 3)'),
      );
      expect(lotusInjectedVisualSkinScript, contains('word-break: normal'));
      expect(lotusInjectedVisualSkinScript, contains('Preferências da mesa'));
      expect(lotusInjectedVisualSkinScript, contains('Busca de cartas'));
      expect(
        lotusInjectedVisualSkinScript,
        contains("['Day/Night', 'Dia/Noite']"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("['Archenemy', 'Arqui-inimigo']"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("['Bounty', 'Recompensa']"),
      );
      expect(lotusInjectedVisualSkinScript, contains('label > div'));
      expect(lotusInjectedVisualSkinScript, contains('72px'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('.game-states-wrapper > *.active'),
      );
      expect(
        RegExp(
          r':not\(\.background-image\)',
        ).allMatches(lotusInjectedVisualSkinScript).length,
        greaterThanOrEqualTo(2),
      );
    });

    test('separates table management from readable landscape shortcuts', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains('.menu-button.active .list'),
      );
      expect(lotusInjectedVisualSkinScript, contains('left: -80px'));
      expect(lotusInjectedVisualSkinScript, contains('top: -168px'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('grid-template-columns: repeat(5, minmax(0, 1fr))'),
      );
      expect(lotusInjectedVisualSkinScript, contains('width: min(620px'));
      expect(lotusInjectedVisualSkinScript, contains('hyphens: none'));
      expect(lotusInjectedVisualSkinScript, contains('Desempate por dados'));
      expect(lotusInjectedVisualSkinScript, contains('Reiniciar partida'));
      expect(lotusInjectedVisualSkinScript, contains("'title', entry[1]"));
    });

    test('faces every player card toward its physical table seat', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains('.player-card.rotate-left .player-card-inner'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('.player-card.rotate-right .player-card-inner'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('--sizeWidth: var(--width) !important'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('--sizeHeight: var(--height) !important'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('data-manaloom-seat-facing=\\"opposite\\"'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('data-manaloom-seat-facing=\\"near\\"'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('data-manaloom-seat-facing=\\"left\\"'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('data-manaloom-seat-facing=\\"right\\"'),
      );
      expect(lotusInjectedVisualSkinScript, contains('rotate: 180deg'));
      expect(lotusInjectedVisualSkinScript, contains('rotate: 90deg'));
      expect(lotusInjectedVisualSkinScript, contains('rotate: -90deg'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('const syncTabletopSeatLayout ='),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('window.__ManaLoomTabletopSeatLayout'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("card.style.setProperty(\n            '--aspect-ratio-card'"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('const panelAspectRatio = String(panelWidth / panelHeight)'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        isNot(contains('calc(var(--width) / var(--height))')),
      );
      expect(lotusInjectedVisualSkinScript, contains('transform: none'));
      expect(
        RegExp(
          r'\.player-card\.rotate-right[^\{]*\{[^\}]*transform: none !important',
          dotAll: true,
        ).hasMatch(lotusInjectedVisualSkinScript),
        isFalse,
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('writing-mode: horizontal-tb'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('text-orientation: mixed'),
      );
    });

    test(
      'keeps history actions clear of the close control on narrow screens',
      () {
        expect(
          lotusInjectedVisualSkinScript,
          contains('.life-history-overlay .all-games-btn'),
        );
        expect(lotusInjectedVisualSkinScript, contains('right: 82px'));
        expect(
          lotusInjectedVisualSkinScript,
          contains('max-width: calc(100% - 100px)'),
        );
        expect(
          lotusInjectedVisualSkinScript,
          contains('text-overflow: ellipsis'),
        );
        expect(
          lotusInjectedVisualSkinScript,
          contains('padding-top: calc(env(safe-area-inset-top, 0px) + 78px)'),
        );
      },
    );

    test('adds live status, dialog metadata and reduced-motion support', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains('__ManaLoomLifeCounterAccessibility'),
      );
      expect(lotusInjectedVisualSkinScript, contains("'aria-label'"));
      expect(lotusInjectedVisualSkinScript, contains("'aria-live', 'polite'"));
      expect(lotusInjectedVisualSkinScript, contains("'aria-atomic', 'true'"));
      expect(lotusInjectedVisualSkinScript, contains('decodeVisualNumber'));
      expect(lotusInjectedVisualSkinScript, contains("startsWith('char-')"));
      expect(lotusInjectedVisualSkinScript, contains('MutationObserver'));
      expect(lotusInjectedVisualSkinScript, contains('characterData: true'));
      expect(lotusInjectedVisualSkinScript, contains("'role', 'dialog'"));
      expect(lotusInjectedVisualSkinScript, contains("'aria-modal', 'true'"));
      expect(lotusInjectedVisualSkinScript, contains('.confirm-overlay'));
      expect(
        lotusInjectedVisualSkinScript,
        contains("['.dice-overlay', 'Dados']"),
      );
      expect(lotusInjectedVisualSkinScript, contains('Rolar dado de 20 lados'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('Número de lados do dado personalizado'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("setAttributeIfChanged(input, 'min', '2')"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("setAttributeIfChanged(input, 'max', '999')"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('Math.min(999, Math.max(2, parsed))'),
      );
      expect(lotusInjectedVisualSkinScript, contains('Fechar dados'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('.dice-overlay .rng-list .roller.custom .roll-btn'),
      );
      expect(lotusInjectedVisualSkinScript, contains('min-width: 84px'));
      expect(lotusInjectedVisualSkinScript, contains('manaloomKeyboardBound'));
      expect(lotusInjectedVisualSkinScript, contains('syncDialogFocus'));
      expect(lotusInjectedVisualSkinScript, contains("'role', 'spinbutton'"));
      expect(lotusInjectedVisualSkinScript, contains("'aria-valuenow'"));
      expect(lotusInjectedVisualSkinScript, contains('dispatchAccessibleTap'));
      expect(
        lotusInjectedVisualSkinScript,
        contains("event.key === 'ArrowUp'"),
      );
      expect(lotusInjectedVisualSkinScript, contains("event.key === 'Escape'"));
      expect(lotusInjectedVisualSkinScript, contains(':focus-visible'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('@media (prefers-reduced-motion: reduce)'),
      );
    });

    test('localizes the embedded runtime without changing protocol keys', () {
      expect(lotusInjectedVisualSkinScript, contains('syncPtBrCopy'));
      expect(
        lotusInjectedVisualSkinScript,
        contains("['Settings', 'Configurações']"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("['Restart Game', 'Reiniciar partida']"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("['Current Game', 'Partida atual']"),
      );
      expect(lotusInjectedVisualSkinScript, contains("['Winner', 'Vencedor']"));
      expect(lotusInjectedVisualSkinScript, contains("['Save', 'Salvar']"));
      expect(lotusInjectedVisualSkinScript, contains("['Cancel', 'Cancelar']"));
      expect(
        lotusInjectedVisualSkinScript,
        contains("document.title = 'ManaLoom • Contador de vida'"),
      );
    });

    test('keeps life controls legible over custom player artwork', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains('.player-card-inner.background-image .increase-button.life'),
      );
      expect(lotusInjectedVisualSkinScript, contains('rgba(1, 4, 10, 0.58)'));
      expect(lotusInjectedVisualSkinScript, contains('rgba(1, 4, 10, 0.66)'));
      expect(
        lotusInjectedVisualSkinScript,
        contains('rgba(247, 241, 226, 0.78)'),
      );
    });

    test('exposes an accessible exit only with the table menu', () {
      expect(
        lotusInjectedVisualSkinScript,
        contains('.manaloom-life-counter-exit.is-visible'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("['.menu-button-overlay', 'Controles da mesa']"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("const isMenuDialog = dialog.matches('.menu-button-overlay')"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('event.stopPropagation()'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('menuTrigger.focus({ preventScroll: true })'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("closedDialog.matches('.menu-button-overlay')"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('activeDialog === null && focusTarget.isConnected'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('menuOverlay.appendChild(exitButton)'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains('Sair do contador de vida'),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains("document.createElement('button')"),
      );
      expect(
        lotusInjectedVisualSkinScript,
        contains(LotusShellMessageTypes.closeLifeCounter),
      );
      expect(lotusInjectedVisualSkinScript, contains('table_menu_exit'));
    });
  });
}
