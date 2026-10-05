import 'dart:io';

/// Inventário das rotas do servidor lido de `routes/`, para os testes de
/// contenção de escopo (SCOPE-P0-TRD-00 e SCOPE-P0-SOC-00).
///
/// Cada arquivo de rota vira um molde de caminho (`/trades/[id]/respond`) e
/// os métodos que o handler declara (`HttpMethod.put`). Os parâmetros entre
/// colchetes viram valores concretos em [RouteEndpoint.concretePath].

/// Capabilities sociais da SCOPE-P0-SOC-00: galeria, perfis, comentários,
/// follows, busca de usuário, DM, push, fichário público e trocas.
const socialContainmentCapabilities = <String>{
  'gallery_public',
  'profiles_public',
  'comments',
  'follows',
  'user_search',
  'direct_messages',
  'social_push',
  'binder_public',
  'trades',
};

/// Capabilities de comércio da SCOPE-P0-TRD-00: trocas e marketplace.
const commerceContainmentCapabilities = <String>{'trades', 'marketplace'};

/// Tudo o que a contenção de escopo mantém fechado na beta: as flags sociais
/// e, além de `trades` (que já é social), o marketplace.
const scopeContainmentCapabilities = <String>{
  ...socialContainmentCapabilities,
  'marketplace',
};

final class RouteEndpoint {
  const RouteEndpoint(this.file, this.template, this.methods);

  /// Caminho do arquivo, relativo a `server/`.
  final String file;

  /// Caminho com os parâmetros entre colchetes (`/users/[id]/follow`).
  final String template;

  /// Métodos que o handler declara, em maiúsculas.
  final Set<String> methods;

  /// O caminho com cada parâmetro trocado pelo valor de [values] (pelo nome
  /// do parâmetro) ou por [fallback].
  String concretePath({
    Map<String, String> values = const {},
    String fallback = '00000000-0000-4000-8000-00000000c0de',
  }) => template.replaceAllMapped(
    RegExp(r'\[([A-Za-z]+)\]'),
    (match) => values[match.group(1)!] ?? fallback,
  );
}

final _declaredMethod = RegExp(r'HttpMethod\.(get|post|put|patch|delete)\b');

/// As rotas de [root], em ordem de caminho, sem os `_middleware.dart`.
List<RouteEndpoint> routeEndpoints({String root = 'routes'}) {
  final endpoints = <RouteEndpoint>[];
  final files =
      Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.dart') &&
                !file.path.endsWith('_middleware.dart'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final relative = file.path.replaceAll(r'\', '/').substring(root.length);
    var template = relative.substring(0, relative.length - '.dart'.length);
    if (template.endsWith('/index')) {
      template = template.substring(0, template.length - '/index'.length);
    }
    if (template.isEmpty) template = '/';
    final methods = {
      for (final match in _declaredMethod.allMatches(file.readAsStringSync()))
        match.group(1)!.toUpperCase(),
    };
    endpoints.add(
      RouteEndpoint(file.path.replaceAll(r'\', '/'), template, methods),
    );
  }
  return endpoints;
}
