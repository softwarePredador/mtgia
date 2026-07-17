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
      title: 'Partida',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.autoKill,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Nocaute automático',
          description:
              'Elimine jogadores automaticamente por vida, veneno ou dano de comandante.',
          value: settings.autoKill,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.lifeLossOnCommanderDamage,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Perder vida com dano de comandante',
          description:
              'Aplique o dano de comandante também ao total de vida do jogador.',
          value: settings.lifeLossOnCommanderDamage,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.setLifeByTappingNumber,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Definir vida ao tocar no número',
          description:
              'Permita inserir a vida diretamente ao tocar no total do jogador.',
          value: settings.setLifeByTappingNumber,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.verticalTapAreas,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Áreas de toque verticais',
          description:
              'Use zonas verticais de toque para ajustar a vida no painel do jogador.',
          value: settings.verticalTapAreas,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.criticalDamageWarning,
          sectionId: LifeCounterSettingsSectionId.gameplay,
          label: 'Aviso de dano crítico',
          description:
              'Destaque jogadores próximos da eliminação por vida baixa.',
          value: settings.criticalDamageWarning,
        ),
      ],
    ),
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.counters,
      title: 'Marcadores',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.showCountersOnPlayerCard,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Marcadores no painel do jogador',
          description: 'Exiba os marcadores diretamente no painel do jogador.',
          value: settings.showCountersOnPlayerCard,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.showRegularCounters,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Marcadores gerais',
          description:
              'Mostre marcadores de veneno, energia, experiência e semelhantes.',
          value: settings.showRegularCounters,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.showCommanderDamageCounters,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Marcadores de dano de comandante',
          description: 'Exiba o dano de comandante nos painéis dos jogadores.',
          value: settings.showCommanderDamageCounters,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.clickableCommanderDamageCounters,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Dano de comandante interativo',
          description:
              'Permita ajustar o dano de comandante diretamente pelos marcadores.',
          value: settings.clickableCommanderDamageCounters,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.keepZeroCountersOnPlayerCard,
          sectionId: LifeCounterSettingsSectionId.counters,
          label: 'Manter marcadores zerados visíveis',
          description:
              'Mantenha os marcadores no painel mesmo quando o valor for zero.',
          value: settings.keepZeroCountersOnPlayerCard,
        ),
      ],
    ),
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.timers,
      title: 'Cronômetros',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.gameTimer,
          sectionId: LifeCounterSettingsSectionId.timers,
          label: 'Cronômetro da partida',
          description: 'Acompanhe a duração total da partida.',
          value: settings.gameTimer,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.gameTimerMainScreen,
          sectionId: LifeCounterSettingsSectionId.timers,
          label: 'Cronômetro na tela principal',
          description: 'Mostre o cronômetro da partida diretamente na mesa.',
          value: settings.gameTimerMainScreen,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.showClockOnMainScreen,
          sectionId: LifeCounterSettingsSectionId.timers,
          label: 'Relógio na tela principal',
          description: 'Mostre o horário atual diretamente na mesa.',
          value: settings.showClockOnMainScreen,
        ),
      ],
    ),
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.visuals,
      title: 'Visual',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.randomPlayerColors,
          sectionId: LifeCounterSettingsSectionId.visuals,
          label: 'Cores aleatórias dos jogadores',
          description: 'Alterne as cores dos painéis ao reorganizar a mesa.',
          value: settings.randomPlayerColors,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.preserveBackgroundImagesOnShuffle,
          sectionId: LifeCounterSettingsSectionId.visuals,
          label: 'Preservar fundos ao embaralhar',
          description:
              'Mantenha as imagens de fundo ao reorganizar as cores dos jogadores.',
          value: settings.preserveBackgroundImagesOnShuffle,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.cleanLook,
          sectionId: LifeCounterSettingsSectionId.visuals,
          label: 'Visual limpo',
          description: 'Reduza elementos e efeitos visuais extras na mesa.',
          value: settings.cleanLook,
        ),
        LifeCounterSettingEntry.text(
          id: LifeCounterSettingFieldId.whitelabelIcon,
          sectionId: LifeCounterSettingsSectionId.visuals,
          label: 'Ícone personalizado',
          description:
              'Identificador opcional para personalizar o ícone do menu.',
          value: settings.whitelabelIcon,
        ),
      ],
    ),
    LifeCounterSettingsSection(
      id: LifeCounterSettingsSectionId.advanced,
      title: 'Avançado',
      entries: <LifeCounterSettingEntry>[
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.saltyDefeatMessages,
          sectionId: LifeCounterSettingsSectionId.advanced,
          label: 'Mensagens irreverentes de derrota',
          description:
              'Mostre mensagens variadas quando um jogador for derrotado.',
          value: settings.saltyDefeatMessages,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.cycleSaltyDefeatMessages,
          sectionId: LifeCounterSettingsSectionId.advanced,
          label: 'Alternar mensagens de derrota',
          description:
              'Alterne as mensagens de derrota em vez de repetir sempre a mesma.',
          value: settings.cycleSaltyDefeatMessages,
        ),
        LifeCounterSettingEntry.toggle(
          id: LifeCounterSettingFieldId.customLongTapEnabled,
          sectionId: LifeCounterSettingsSectionId.advanced,
          label: 'Toque longo personalizado',
          description:
              'Use um valor personalizado para aumentar ou reduzir ao manter pressionado.',
          value: settings.customLongTapEnabled,
        ),
        LifeCounterSettingEntry.number(
          id: LifeCounterSettingFieldId.customLongTapValue,
          sectionId: LifeCounterSettingsSectionId.advanced,
          label: 'Valor do toque longo',
          description:
              'Valor usado quando o toque longo personalizado estiver ativo.',
          value: settings.customLongTapValue,
        ),
      ],
    ),
  ];
}
