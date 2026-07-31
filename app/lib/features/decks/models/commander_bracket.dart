class CommanderBracketOption {
  const CommanderBracketOption({required this.value, required this.label});

  final int value;
  final String label;

  String get menuLabel => '$value - $label';
}

const commanderBracketOptions = <CommanderBracketOption>[
  CommanderBracketOption(value: 1, label: 'Exhibition'),
  CommanderBracketOption(value: 2, label: 'Core'),
  CommanderBracketOption(value: 3, label: 'Upgraded'),
  CommanderBracketOption(value: 4, label: 'Optimized'),
  CommanderBracketOption(value: 5, label: 'cEDH'),
];

bool isCommanderBracket(int? value) =>
    value != null && value >= 1 && value <= 5;

String commanderBracketLabel(int value) {
  for (final option in commanderBracketOptions) {
    if (option.value == value) return option.label;
  }
  return 'Bracket desconhecido';
}

String commanderBracketGuidance(int value) {
  return switch (value) {
    1 =>
      'Exhibition: tema acima de poder, 0 Game Changers e partidas pensadas '
          'para chegar ao turno 9 ou além.',
    2 =>
      'Core: plano direto e não otimizado, 0 Game Changers e vitórias '
          'telegrafadas e interrompíveis a partir do turno 8.',
    3 =>
      'Upgraded: alta sinergia, até 3 Game Changers e grandes turnos '
          'construídos por recursos acumulados a partir do turno 6.',
    4 =>
      'Optimized: alta eficiência e consistência a partir do turno 4, sem '
          'tratar a mesa como cEDH; Game Changers não têm limite numérico.',
    5 =>
      'cEDH: metagame competitivo, vitória como prioridade e sem piso de '
          'turno; Game Changers não têm limite numérico.',
    _ => 'Selecione um Bracket Commander válido entre 1 e 5.',
  };
}
