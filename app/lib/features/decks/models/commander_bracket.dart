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
  if (value == 5) {
    return 'cEDH: prioriza eficiência competitiva e referências de meta quando '
        'existirem, mantendo legalidade, identidade e segurança.';
  }
  if (value == 4) {
    return 'Optimized: busca alta eficiência sem tratar a mesa como cEDH; '
        'legalidade, identidade e Game Changers continuam validados.';
  }
  return 'Faixa social: preserva a experiência do bracket escolhido e oferece '
      'rebuild guiado quando trocas pontuais não forem seguras.';
}
