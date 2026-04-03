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
  static const String closeControlsBackdrop = '.close-controls-backdrop';
  static const String regularCounters =
      '.player-card .counters-on-card:not(.commander-damage-counters) .counter';
  static const String commanderDamageCounters =
      '.player-card .commander-damage-counters .commander-damage-counter';
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
    'closeControlsBackdrop': LotusDomSelectors.closeControlsBackdrop,
  });

  return '''
(() => {
  window.__ManaLoomLotusContract = Object.freeze({
    version: '2026-04-03',
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
