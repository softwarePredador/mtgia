import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// GET /binder/stats → Estatísticas do fichário do usuário autenticado
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    final result = await pool.execute(Sql.named('''
      SELECT
        COALESCE(SUM(quantity), 0) AS total_items,
        COUNT(*) FILTER (WHERE for_trade = TRUE) AS for_trade_count,
        COUNT(*) FILTER (WHERE for_sale = TRUE) AS for_sale_count,
        COALESCE(SUM(CASE WHEN for_sale = TRUE AND price IS NOT NULL THEN price * quantity ELSE 0 END), 0) AS estimated_value,
        COUNT(DISTINCT card_id) AS unique_cards
      FROM user_binder_items
      WHERE user_id = @userId
    '''), parameters: {'userId': userId});

    final row = result.first.toColumnMap();

    return Response.json(body: {
      'total_items': row['total_items'] ?? 0,
      'unique_cards': row['unique_cards'] ?? 0,
      'for_trade_count': row['for_trade_count'] ?? 0,
      'for_sale_count': row['for_sale_count'] ?? 0,
      'estimated_value': double.tryParse(row['estimated_value'].toString()) ?? 0.0,
    });
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao calcular estatísticas: $e'},
    );
  }
}
