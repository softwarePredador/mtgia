import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import 'logger.dart';

/// BT-CAT-03 (aceite: alerta de DML ou chamada a terceiro numa leitura; D-35).
///
/// As leituras do catálogo (`/cards`, `/sets` e `/rules`) não chamam serviço de
/// fora: a sincronização com a Scryfall é só do job de catálogo (BT-CAT-01).
/// [catalogReadGuard] roda o handler numa zona em que abrir um cliente HTTP
/// (inclusive o do `package:http`) conta em [CatalogReadGuard.upstreamBlocked]
/// e falha antes de qualquer conexão. `/health/metrics` publica a contagem, e o
/// avaliador de SLO alerta com uma só (`catalog_read_upstream`). A escrita nas
/// tabelas do catálogo fora do job é vigiada no PostgreSQL
/// (`catalog_written_outside_job`).
class CatalogReadGuard {
  CatalogReadGuard._();

  static int _upstreamBlocked = 0;

  /// Tentativas de chamada a terceiro bloqueadas desde o início do processo.
  static int get upstreamBlocked => _upstreamBlocked;

  static Map<String, int> snapshot() => {'upstream_blocked': _upstreamBlocked};

  @visibleForTesting
  static void resetForTesting() => _upstreamBlocked = 0;
}

/// A leitura do catálogo tentou chamar um serviço de fora.
class CatalogUpstreamBlocked extends StateError {
  CatalogUpstreamBlocked(String route)
    : super('leitura do catálogo não chama serviço de fora (D-35): $route');
}

final _identifierSegment = RegExp(
  r'/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);

/// Middleware das rotas de catálogo.
Middleware catalogReadGuard() {
  return (handler) {
    return (context) {
      final route = context.request.uri.path.replaceAll(
        _identifierSegment,
        '/:id',
      );
      return HttpOverrides.runZoned(
        () => handler(context),
        createHttpClient: (_) {
          CatalogReadGuard._upstreamBlocked++;
          Log.w('[catalog] catalog_read_upstream_blocked route=$route');
          throw CatalogUpstreamBlocked(route);
        },
      );
    };
  };
}
