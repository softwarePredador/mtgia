import 'dart:convert';

abstract final class LotusShellMessageTypes {
  static const String analytics = 'analytics';
  static const String blockedLink = 'blocked-link';
  static const String blockedWindowOpen = 'blocked-window-open';
  static const String closeLifeCounter = 'close-life-counter';
  static const String openNativePrefix = 'open-native-';
}

abstract final class LotusDomSelectors {
  static const String playerCard = '.player-card';
  static const String overlay = '[class*="overlay"]';
  static const String mainGameTimer = '.game-timer:not(.current-time-clock)';
  static const String currentTimeClock = '.current-time-clock';
  static const String turnTracker = '.turn-time-tracker';
  static const String menuButton = '.menu-button';
  static const String optionCard = '.player-card-inner.option-card';
  static const String infoCard = '.player-card > .info-card';
  static const String closeControlsBackdrop = '.close-controls-backdrop';
  static const String regularCounters =
      '.player-card .counters-on-card:not(.commander-damage-counters) .counter';
  static const String commanderDamageCounters =
      '.player-card .commander-damage-counters .commander-damage-counter';
  static const String lifeTotal = '.player-card .player-life-count';
  static const String settingsShortcut = '.list > .settings .btn';
  static const String highRollShortcut = '.list > .high-roll .btn';
  static const String diceShortcut = '.menu-button-overlay .dice-btn';
  static const String historyShortcut =
      '.menu-button-overlay .life-history-btn';
  static const String cardSearchShortcut =
      '.menu-button-overlay .card-search-btn';
  static const String monarchShortcut = '.menu-button-overlay .monarch-btn';
  static const String initiativeShortcut =
      '.menu-button-overlay .initiative-btn';
  static const String dayNightShortcut = '.menu-button-overlay .day-night-btn';
  static const String dayNightSurface = '.day-night-switcher';
  static const String planechaseShortcut =
      '.menu-button-overlay .planechase-gamemode-btn';
  static const String planechaseSurface = '.planechase-btn';
  static const String archenemyShortcut =
      '.menu-button-overlay .archenemy-gamemode-btn';
  static const String archenemySurface = '.archenemy-btn';
  static const String bountyShortcut =
      '.menu-button-overlay .bounty-gamemode-btn';
  static const String bountySurface = '.bounty-btn';
}

String get lotusInjectedContractScript {
  final selectors = jsonEncode(<String, String>{
    'playerCard': LotusDomSelectors.playerCard,
    'overlay': LotusDomSelectors.overlay,
    'mainGameTimer': LotusDomSelectors.mainGameTimer,
    'currentTimeClock': LotusDomSelectors.currentTimeClock,
    'turnTracker': LotusDomSelectors.turnTracker,
    'menuButton': LotusDomSelectors.menuButton,
    'optionCard': LotusDomSelectors.optionCard,
    'infoCard': LotusDomSelectors.infoCard,
    'closeControlsBackdrop': LotusDomSelectors.closeControlsBackdrop,
    'regularCounters': LotusDomSelectors.regularCounters,
    'commanderDamageCounters': LotusDomSelectors.commanderDamageCounters,
    'lifeTotal': LotusDomSelectors.lifeTotal,
  });

  return '''
(() => {
  window.__ManaLoomLotusContract = Object.freeze({
    version: '2026-07-17',
    selectors: Object.freeze($selectors),
    messages: Object.freeze({
      analytics: '${LotusShellMessageTypes.analytics}',
      blockedLink: '${LotusShellMessageTypes.blockedLink}',
      blockedWindowOpen: '${LotusShellMessageTypes.blockedWindowOpen}',
      closeLifeCounter: '${LotusShellMessageTypes.closeLifeCounter}',
      openNativePrefix: '${LotusShellMessageTypes.openNativePrefix}',
    }),
  });
})();
''';
}
