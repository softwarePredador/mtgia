import 'package:flutter/foundation.dart';

import 'life_counter_settings.dart';

enum LifeCounterSettingsSectionId {
  gameplay,
  counters,
  timers,
  visuals,
  advanced,
}

enum LifeCounterSettingFieldId {
  autoKill,
  lifeLossOnCommanderDamage,
  showCountersOnPlayerCard,
  showRegularCounters,
  showCommanderDamageCounters,
  clickableCommanderDamageCounters,
  keepZeroCountersOnPlayerCard,
  saltyDefeatMessages,
  cycleSaltyDefeatMessages,
  gameTimer,
  gameTimerMainScreen,
  showClockOnMainScreen,
  randomPlayerColors,
  preserveBackgroundImagesOnShuffle,
  setLifeByTappingNumber,
  verticalTapAreas,
  cleanLook,
  criticalDamageWarning,
  customLongTapEnabled,
  customLongTapValue,
  whitelabelIcon,
}

enum LifeCounterSettingValueKind { toggle, number, text }

@immutable
class LifeCounterSettingEntry {
  const LifeCounterSettingEntry._({
    required this.id,
    required this.sectionId,
    required this.label,
    required this.description,
    required this.kind,
    this.toggleValue,
    this.numberValue,
    this.textValue,
  });

  const LifeCounterSettingEntry.toggle({
    required LifeCounterSettingFieldId id,
    required LifeCounterSettingsSectionId sectionId,
    required String label,
    required String description,
    required bool value,
  }) : this._(
         id: id,
         sectionId: sectionId,
         label: label,
         description: description,
         kind: LifeCounterSettingValueKind.toggle,
         toggleValue: value,
       );

  const LifeCounterSettingEntry.number({
    required LifeCounterSettingFieldId id,
    required LifeCounterSettingsSectionId sectionId,
    required String label,
    required String description,
    required int value,
  }) : this._(
         id: id,
         sectionId: sectionId,
         label: label,
         description: description,
         kind: LifeCounterSettingValueKind.number,
         numberValue: value,
       );

  const LifeCounterSettingEntry.text({
    required LifeCounterSettingFieldId id,
    required LifeCounterSettingsSectionId sectionId,
    required String label,
    required String description,
    required String? value,
  }) : this._(
         id: id,
         sectionId: sectionId,
         label: label,
         description: description,
         kind: LifeCounterSettingValueKind.text,
         textValue: value,
       );

  final LifeCounterSettingFieldId id;
  final LifeCounterSettingsSectionId sectionId;
  final String label;
  final String description;
  final LifeCounterSettingValueKind kind;
  final bool? toggleValue;
  final int? numberValue;
  final String? textValue;
}

@immutable
class LifeCounterSettingsSection {
  const LifeCounterSettingsSection({
    required this.id,
    required this.title,
    required this.entries,
  });

  final LifeCounterSettingsSectionId id;
  final String title;
  final List<LifeCounterSettingEntry> entries;
}

List<LifeCounterSettingsSection> buildLifeCounterSettingsCatalog(
  LifeCounterSettings settings,
) {
  return <LifeCounterSettingsSection>[
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.gameplay,
      title: 'Gameplay',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.autoKill,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Auto-kill',
          description:
              'Eliminate players automatically from life, poison, or commander damage.',
          value: settings.autoKill,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.lifeLossOnCommanderDamage,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Life loss on commander damage',
          description:
              'Apply commander damage changes to life totals as well as tracked damage.',
          value: settings.lifeLossOnCommanderDamage,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.setLifeByTappingNumber,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Set life by tapping number',
          description:
              'Allow direct life input by tapping the life total on a player card.',
          value: settings.setLifeByTappingNumber,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.verticalTapAreas,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Vertical tap areas',
          description:
              'Use vertical tap zones for life adjustments on the player card.',
          value: settings.verticalTapAreas,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.criticalDamageWarning,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Critical damage warning',
          description:
              'Highlight players that are close to elimination from low life.',
          value: settings.criticalDamageWarning,
        ),
      ],
    ),
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.counters,
      title: 'Counters',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.showCountersOnPlayerCard,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Counters on player card',
          description:
              'Render counters directly on the player card instead of hiding them.',
          value: settings.showCountersOnPlayerCard,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.showRegularCounters,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Regular counters',
          description:
              'Show poison, energy, experience and related counters on the card.',
          value: settings.showRegularCounters,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.showCommanderDamageCounters,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Commander damage counters',
          description:
              'Render commander damage counters on player cards.',
          value: settings.showCommanderDamageCounters,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.clickableCommanderDamageCounters,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Clickable commander damage counters',
          description:
              'Let commander damage counters act as direct interaction targets.',
          value: settings.clickableCommanderDamageCounters,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.keepZeroCountersOnPlayerCard,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Keep zero counters visible',
          description:
              'Keep counter chips on the player card even when their value is zero.',
          value: settings.keepZeroCountersOnPlayerCard,
        ),
      ],
    ),
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.timers,
      title: 'Timers',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.gameTimer,
          sectionId: LifeCounterSettingsSectionId.timers,
          label: 'Game timer',
          description: 'Track the overall match duration.',
          value: settings.gameTimer,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.gameTimerMainScreen,
          sectionId: LifeCounterSettingsSectionId.timers,
          label: 'Game timer on main screen',
          description: 'Show the match timer directly on the tabletop.',
          value: settings.gameTimerMainScreen,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.showClockOnMainScreen,
          sectionId: LifeCounterSettingsSectionId.timers,
          label: 'Clock on main screen',
          description: 'Show the current clock time on the tabletop.',
          value: settings.showClockOnMainScreen,
        ),
      ],
    ),
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.visuals,
      title: 'Visuals',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.randomPlayerColors,
          sectionId: LifeCounterSettingsSectionId.visuals,
          label: 'Random player colors',
          description:
              'Shuffle player card colors when the table is regenerated.',
          value: settings.randomPlayerColors,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.preserveBackgroundImagesOnShuffle,
          sectionId: LifeCounterSettingsSectionId.visuals,
          label: 'Preserve backgrounds on shuffle',
          description:
              'Keep custom player background images when colors are reshuffled.',
          value: settings.preserveBackgroundImagesOnShuffle,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.cleanLook,
          sectionId: LifeCounterSettingsSectionId.visuals,
          label: 'Clean look',
          description:
              'Reduce UI noise and extra visual treatments on the tabletop.',
          value: settings.cleanLook,
        ),
        LifeCounterSettingEntry.text(
          id: LifeCounterSettingFieldId.whitelabelIcon,
          sectionId: LifeCounterSettingsSectionId.visuals,
          label: 'Whitelabel icon',
          description:
              'Optional icon identifier used to customize the menu button shell.',
          value: settings.whitelabelIcon,
        ),
      ],
    ),
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.advanced,
      title: 'Advanced',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.saltyDefeatMessages,
          sectionId: LifeCounterSettingsSectionId.advanced,
          label: 'Salty defeat messages',
          description:
              'Show the rotating defeat messages from the original tabletop flow.',
          value: settings.saltyDefeatMessages,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.cycleSaltyDefeatMessages,
          sectionId: LifeCounterSettingsSectionId.advanced,
          label: 'Cycle defeat messages',
          description:
              'Rotate defeat messages instead of repeating the same message.',
          value: settings.cycleSaltyDefeatMessages,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.customLongTapEnabled,
          sectionId: LifeCounterSettingsSectionId.advanced,
          label: 'Custom long tap',
          description:
              'Enable a custom increment/decrement value on long press.',
          value: settings.customLongTapEnabled,
        ),
        LifeCounterSettingEntry.number(
          id: LifeCounterSettingFieldId.customLongTapValue,
          sectionId: LifeCounterSettingsSectionId.advanced,
          label: 'Custom long tap value',
          description:
              'Numeric value used when the custom long tap behavior is enabled.',
          value: settings.customLongTapValue,
        ),
      ],
    ),
  ];
}
