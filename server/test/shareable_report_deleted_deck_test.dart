import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/reports/shareable_report_service.dart';
import '../routes/reports/[id].dart' as report_route;
import 'support/scripted_pool.dart';

/// Buraco 4 da D-19 (parte do DCK-P0-06): o relatório público só é servido
/// enquanto o deck existe e não está na lixeira. A prova com PostgreSQL de
/// verdade está em `shareable_report_deleted_deck_db_live_test.dart`.
void main() {
  const columns = [
    'id',
    'deck_id',
    'title',
    'description',
    'payload',
    'is_public',
    'created_at',
    'updated_at',
    'expires_at',
  ];

  test('a leitura pública exige o deck vivo', () async {
    final pool = ScriptedPool([scriptedResult(columns: columns)]);

    final report = await ShareableReportService(pool).getPublicReport('rpt_x');

    expect(report, isNull);
    final sql = pool.queries.single.replaceAll(RegExp(r'\s+'), ' ');
    expect(sql, contains('FROM shared_deck_reports r JOIN decks d'));
    expect(sql, contains('ON d.id = r.deck_id AND d.deleted_at IS NULL'));
    expect(sql, contains('r.is_public = TRUE'));
    expect(pool.parameters.single, {'reportId': 'rpt_x'});
  });

  test('relatório de deck vivo continua público', () async {
    final pool = ScriptedPool([
      scriptedResult(
        columns: columns,
        rows: [
          [
            'rpt_vivo',
            '33333333-3333-4333-8333-333333333333',
            'Relatorio BrewTact - Deck',
            'Relatorio compartilhavel do deck Deck.',
            {'type': 'deck_snapshot'},
            true,
            DateTime.utc(2026, 9, 1),
            DateTime.utc(2026, 9, 1),
            null,
          ],
        ],
      ),
    ]);

    final report = await ShareableReportService(
      pool,
    ).getPublicReport('rpt_vivo');

    expect(report?['deck_id'], '33333333-3333-4333-8333-333333333333');
    expect(report?['payload'], {'type': 'deck_snapshot'});
  });

  test('GET /reports/:id responde 404 quando o deck sumiu', () async {
    final pool = ScriptedPool([scriptedResult(columns: columns)]);

    final response = await report_route.onRequest(
      ScriptedRequestContext(
        Request.get(Uri.parse('http://localhost/reports/rpt_orfao')),
        providers: {Pool: pool},
      ),
      'rpt_orfao',
    );

    expect(response.statusCode, HttpStatus.notFound);
  });
}
