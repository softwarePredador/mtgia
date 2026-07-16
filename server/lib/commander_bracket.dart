const commanderBracketMin = 1;
const commanderBracketMax = 5;

class CommanderBracketParseResult {
  const CommanderBracketParseResult({
    required this.wasProvided,
    required this.value,
    required this.error,
  });

  final bool wasProvided;
  final int? value;
  final String? error;
}

CommanderBracketParseResult parseCommanderBracket(
  Object? raw, {
  String fieldName = 'bracket',
}) {
  if (raw == null) {
    return const CommanderBracketParseResult(
      wasProvided: false,
      value: null,
      error: null,
    );
  }

  final parsed = switch (raw) {
    int value => value,
    String value => int.tryParse(value.trim()),
    _ => null,
  };
  if (parsed == null) {
    return CommanderBracketParseResult(
      wasProvided: true,
      value: null,
      error: '$fieldName must be an integer',
    );
  }
  if (parsed < commanderBracketMin || parsed > commanderBracketMax) {
    return CommanderBracketParseResult(
      wasProvided: true,
      value: null,
      error:
          '$fieldName must be between '
          '$commanderBracketMin and $commanderBracketMax',
    );
  }

  return CommanderBracketParseResult(
    wasProvided: true,
    value: parsed,
    error: null,
  );
}
