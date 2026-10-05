import 'dart:io';

import 'package:server/analytics/activation_event_catalog.dart';
import 'package:server/deck_format_support.dart';
import 'package:test/test.dart';

/// BT-KPI-001, achado 13 dos fluxos: o app e o servidor concordam no catálogo
/// de eventos de ativação. O teste lê as chamadas de telemetria do app
/// (`trackOnce`, `_trackActivationInBackground` e `_queueProgressWrite`) e
/// confere nome, origem, chaves de metadado e valores fechados contra
/// `activation_events_v1`. Evento novo no app sem entrada no catálogo, ou
/// entrada no catálogo que nenhum ponto do app emite, faz o teste falhar.
const _emitterFiles = <String>[
  '../app/lib/main.dart',
  '../app/lib/features/home/home_screen.dart',
  '../app/lib/features/home/onboarding_core_flow_screen.dart',
  '../app/lib/features/decks/providers/deck_provider.dart',
];

final _literal = RegExp(r"'([a-z][a-zA-Z0-9_.]*)'");

/// O texto dos argumentos de cada chamada de [function] em [source].
List<String> _callArguments(String source, String function) {
  final calls = <String>[];
  var from = 0;
  while (true) {
    final start = source.indexOf('$function(', from);
    if (start < 0) return calls;
    final open = start + function.length;
    final close = _matching(source, open);
    calls.add(source.substring(open + 1, close));
    from = close;
  }
}

/// A posição do fechamento do parêntese, colchete ou chave em [open].
int _matching(String source, int open) {
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    final char = source[i];
    if (char == "'") {
      i = source.indexOf("'", i + 1);
      continue;
    }
    if (char == '(' || char == '[' || char == '{') depth++;
    if (char == ')' || char == ']' || char == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  throw StateError('parêntese sem par');
}

/// Os argumentos de primeiro nível de uma chamada.
List<String> _split(String arguments) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < arguments.length; i++) {
    final char = arguments[i];
    if (char == "'") {
      i = arguments.indexOf("'", i + 1);
      continue;
    }
    if (char == '(' || char == '[' || char == '{') depth++;
    if (char == ')' || char == ']' || char == '}') depth--;
    if (char == ',' && depth == 0) {
      parts.add(arguments.substring(start, i).trim());
      start = i + 1;
    }
  }
  final last = arguments.substring(start).trim();
  if (last.isNotEmpty) parts.add(last);
  return parts;
}

String? _named(List<String> arguments, String name) {
  for (final argument in arguments) {
    if (argument.startsWith('$name:')) {
      return argument.substring(name.length + 1).trim();
    }
  }
  return null;
}

Set<String> _literals(String? expression) => {
  if (expression != null)
    for (final match in _literal.allMatches(expression)) match.group(1)!,
};

/// As chaves de um mapa literal (`'chave': valor`), só do primeiro nível.
Set<String> _mapKeys(String? expression) {
  if (expression == null || !expression.startsWith('{')) return {};
  final body = expression.substring(1, _matching(expression, 0));
  return {
    for (final entry in _split(body))
      if (RegExp(r"^(?:if \([^)]*\)\s*)?'([a-z_]+)'\s*:").firstMatch(entry)
          case final match?)
        match.group(1)!,
  };
}

/// Os valores de um `enum` do app (`enum Nome { a, b }`).
Set<String> _enumValues(String source, String name) {
  final start = source.indexOf('enum $name ');
  expect(start, greaterThanOrEqualTo(0), reason: 'enum $name no app');
  final open = source.indexOf('{', start);
  final body = source.substring(open + 1, _matching(source, open));
  return {
    for (final part in body.split(';').first.split(','))
      if (RegExp(r'^\s*([a-zA-Z]+)').firstMatch(part) case final match?)
        match.group(1)!,
  };
}

/// Uma chamada de telemetria do app: os eventos possíveis, a origem e as
/// chaves do metadado.
class _Emission {
  _Emission(this.file, this.events, this.source, this.metadataKeys);

  final String file;
  final Set<String> events;
  final String? source;
  final Set<String> metadataKeys;
}

List<_Emission> _emissions() {
  final emissions = <_Emission>[];
  for (final path in _emitterFiles) {
    final source = File(path).readAsStringSync();
    // O onboarding encaminha quatro eventos por _queueProgressWrite; a
    // chamada interna usa o parâmetro `eventName`.
    final forwarded = <String>{
      for (final call in _callArguments(source, '_queueProgressWrite'))
        ..._literals(_named(_split(call), 'eventName')),
    };
    for (final call in _callArguments(source, 'trackOnce')) {
      final arguments = _split(call);
      if (arguments.length < 2 || arguments[0].startsWith('String ')) continue;
      final expression = arguments[1];
      emissions.add(
        _Emission(
          path,
          expression == 'eventName' ? forwarded : _literals(expression),
          _literals(_named(arguments, 'source')).singleOrNull,
          _mapKeys(_named(arguments, 'metadata')),
        ),
      );
    }
    for (final call in _callArguments(source, '_trackActivationInBackground')) {
      final arguments = _split(call);
      if (arguments.first.startsWith('String ')) continue;
      emissions.add(
        _Emission(
          path,
          _literals(arguments.first),
          _literals(_named(arguments, 'source')).singleOrNull,
          _mapKeys(_named(arguments, 'metadata')),
        ),
      );
    }
  }
  return emissions;
}

void main() {
  final emissions = _emissions();

  test('o app emite exatamente os eventos do catálogo v1', () {
    final emitted = {for (final emission in emissions) ...emission.events};
    expect(emitted, activationEventCatalog.keys.toSet());
    expect(emitted.intersection(retiredActivationEvents), isEmpty);
    // Cada chamada achou o nome: um refactor que esconda o nome falha aqui.
    for (final emission in emissions) {
      expect(emission.events, isNotEmpty, reason: emission.file);
    }
    expect(emissions.length, greaterThanOrEqualTo(9));
  });

  test('cada chamada usa uma origem aceita e só chaves do esquema', () {
    for (final emission in emissions) {
      for (final event in emission.events) {
        final spec = activationEventCatalog[event]!;
        final reason = '${emission.file}: $event';
        expect(spec.sources, contains(emission.source), reason: reason);
        final known = {...spec.metadata.fields.keys, ...spec.metadata.dropped};
        expect(
          emission.metadataKeys.difference(known),
          isEmpty,
          reason: reason,
        );
      }
    }
  });

  test('o contexto de recomendação do Optimize cabe no esquema aninhado', () {
    final source =
        File(
          '../app/lib/features/decks/widgets/deck_optimize_flow_support.dart',
        ).readAsStringSync();
    final builder = source.indexOf('buildOptimizeRecommendationContext(');
    final open = source.indexOf('return {', builder) + 'return '.length;
    final keys = _mapKeys(source.substring(open, _matching(source, open) + 1));
    final rule =
        activationEventCatalog['optimize_preview_received']!
                .metadata
                .fields['recommendation_context']!
            as ActivationObjectRule;
    expect(keys, isNotEmpty);
    expect(keys.difference({...rule.fields.keys, ...rule.dropped}), isEmpty);
    expect(rule.dropped, {'post_game_note_id'});
  });

  test('os valores fechados do app batem com o catálogo', () {
    final store =
        File(
          '../app/lib/features/home/services/onboarding_state_store.dart',
        ).readAsStringSync();
    final selection =
        activationEventCatalog['onboarding_task_started']!.metadata.fields;
    Set<String> values(
      Map<String, ActivationMetadataRule> fields,
      String key,
    ) => (fields[key]! as ActivationEnumRule).values;

    expect(values(selection, 'goal'), _enumValues(store, 'OnboardingGoal'));
    expect(
      values(selection, 'experience'),
      _enumValues(store, 'OnboardingExperience'),
    );
    expect(
      values(selection, 'build_mode'),
      _enumValues(store, 'OnboardingBuildMode'),
    );
    final dispositions = _enumValues(store, 'OnboardingDisposition');
    for (final event in const ['onboarding_completed', 'onboarding_skipped']) {
      final allowed = values(
        activationEventCatalog[event]!.metadata.fields,
        'disposition',
      );
      expect(dispositions, containsAll(allowed));
    }

    final common =
        File(
          '../app/lib/features/decks/providers/deck_provider_support_common.dart',
        ).readAsStringSync();
    final intensityStart = common.indexOf('enum OptimizeIntensity');
    final intensityBody = common.substring(
      intensityStart,
      common.indexOf(';', intensityStart),
    );
    expect(
      values(
        activationEventCatalog['optimize_preview_received']!.metadata.fields,
        'intensity',
      ),
      _literals(intensityBody),
    );

    final onboarding =
        File(
          '../app/lib/features/home/onboarding_core_flow_screen.dart',
        ).readAsStringSync();
    final formatsStart = onboarding.indexOf('static const _formats');
    final formats = _literals(
      onboarding.substring(
        formatsStart,
        onboarding.indexOf('];', formatsStart),
      ),
    );
    expect(formats, isNotEmpty);
    expect(supportedDeckFormats, containsAll(formats));
  });

  test('a rota grava só pelo catálogo, com posse do deck e deduplicação', () {
    final route =
        File('routes/users/me/activation-events/index.dart').readAsStringSync();
    expect(route, contains('validateActivationEvent(body)'));
    expect(route, contains('deckNotFoundResponse()'));
    expect(route, contains('AND user_id = CAST(@userId AS uuid)'));
    expect(
      route,
      contains(
        'ON CONFLICT (user_id, dedupe_key) WHERE dedupe_key IS NOT NULL',
      ),
    );
    expect(route, isNot(contains('details:')));
    expect(route, isNot(contains('_allowedEvents')));
  });
}
