import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'log_sanitizer.dart';

/// Contrato de leitura do catálogo (BT-CAT-02, decisão D-35 do dono).
///
/// As rotas de catálogo só leem o PostgreSQL: nenhuma grava no banco nem
/// chama a Scryfall. Quem traz carta nova é o job de dado de referência
/// (BT-CAT-01). Carta ausente responde 404 com um código estável e uma frase
/// em português, para o app mostrar sem traduzir código cru.
const cardNotInCatalogCode = 'card_not_in_catalog';

/// Tamanho máximo do nome devolvido na resposta de carta ausente.
const cardNotInCatalogNameLimit = 200;

/// Demanda de cartas ausentes (D-63): cada 404 `card_not_in_catalog` deixa no
/// log uma linha com este marcador e um JSON, e a contagem de demanda sai do
/// log. Sem tabela e sem escrita no banco. A linha leva só o evento, a rota,
/// se a busca incluía tokens e o nome normalizado: nada do usuário (nem id,
/// nem IP, nem cabeçalho).
const catalogCardDemandLogMarker = 'MANALOOM_CATALOG_CARD_DEMAND';

/// Rotas que respondem carta ausente.
const catalogDemandRoutePrintings = 'GET /cards/printings';
const catalogDemandRouteResolve = 'POST /cards/resolve';

String cardNotInCatalogMessage(String name) {
  final shown = _shownName(name);
  return 'A carta "$shown" não está no catálogo do BrewTact. '
      'Confira o nome; carta nova entra na próxima atualização do catálogo.';
}

Response cardNotInCatalogResponse(
  String name, {
  required String route,
  bool includeTokens = false,
}) {
  // O único campo livre da linha, o nome, já passou pelo sanitizador. A linha
  // vai direto ao stdout porque uma segunda passada do sanitizador poderia
  // cortar o fim do JSON.
  // ignore: avoid_print
  print(
    catalogCardDemandLogLine(name, route: route, includeTokens: includeTokens),
  );
  return Response.json(
    statusCode: HttpStatus.notFound,
    body: {
      'error': cardNotInCatalogCode,
      'message': cardNotInCatalogMessage(name),
      'name': _shownName(name),
    },
  );
}

/// A linha de demanda de uma carta ausente (D-63).
String catalogCardDemandLogLine(
  String name, {
  required String route,
  bool includeTokens = false,
}) {
  final fields = <String, Object>{
    'event': cardNotInCatalogCode,
    'route': route,
    'include_tokens': includeTokens,
    'name': normalizeCatalogDemandName(name),
  };
  return '$catalogCardDemandLogMarker ${jsonEncode(fields)}';
}

/// Nome normalizado para a contagem: caractere de controle vira espaço,
/// espaços seguidos viram um, sem espaço nas pontas, em minúsculas, com
/// e-mail e segredo mascarados pelo sanitizador de log e com no máximo
/// [cardNotInCatalogNameLimit] caracteres.
String normalizeCatalogDemandName(String name) {
  final cleaned =
      name
          .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();
  final sanitized = sanitizeLogMessage(cleaned);
  final runes = sanitized.runes;
  if (runes.length <= cardNotInCatalogNameLimit) return sanitized;
  return String.fromCharCodes(runes.take(cardNotInCatalogNameLimit));
}

String _shownName(String name) {
  final trimmed = name.trim();
  if (trimmed.length <= cardNotInCatalogNameLimit) return trimmed;
  return '${trimmed.substring(0, cardNotInCatalogNameLimit)}…';
}
