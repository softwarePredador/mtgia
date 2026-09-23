import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Contrato de leitura do catálogo (BT-CAT-02, decisão D-35 do dono).
///
/// As rotas de catálogo só leem o PostgreSQL: nenhuma grava no banco nem
/// chama a Scryfall. Quem traz carta nova é o job de dado de referência
/// (BT-CAT-01). Carta ausente responde 404 com um código estável e uma frase
/// em português, para o app mostrar sem traduzir código cru.
const cardNotInCatalogCode = 'card_not_in_catalog';

/// Tamanho máximo do nome devolvido na resposta de carta ausente.
const cardNotInCatalogNameLimit = 200;

String cardNotInCatalogMessage(String name) {
  final shown = _shownName(name);
  return 'A carta "$shown" não está no catálogo do BrewTact. '
      'Confira o nome; carta nova entra na próxima atualização do catálogo.';
}

Response cardNotInCatalogResponse(String name) {
  return Response.json(
    statusCode: HttpStatus.notFound,
    body: {
      'error': cardNotInCatalogCode,
      'message': cardNotInCatalogMessage(name),
      'name': _shownName(name),
    },
  );
}

String _shownName(String name) {
  final trimmed = name.trim();
  if (trimmed.length <= cardNotInCatalogNameLimit) return trimmed;
  return '${trimmed.substring(0, cardNotInCatalogNameLimit)}…';
}
