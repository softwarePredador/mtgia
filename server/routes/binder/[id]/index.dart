import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// PUT /binder/:id  → Atualiza item do binder
/// DELETE /binder/:id → Remove item do binder
Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;
  if (method == HttpMethod.put) return _updateBinderItem(context, id);
  if (method == HttpMethod.delete) return _deleteBinderItem(context, id);
  return Response(statusCode: HttpStatus.methodNotAllowed);
}

/// PUT /binder/:id
/// Body: { quantity?, condition?, is_foil?, for_trade?, for_sale?, price?, notes?, language? }
Future<Response> _updateBinderItem(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final body = await context.request.json() as Map<String, dynamic>;

    // Verifica ownership
    final check = await pool.execute(Sql.named('''
      SELECT id FROM user_binder_items WHERE id = @id AND user_id = @userId
    '''), parameters: {'id': id, 'userId': userId});

    if (check.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Item não encontrado ou não pertence a você'},
      );
    }

    // Build dynamic SET
    final setClauses = <String>['updated_at = CURRENT_TIMESTAMP'];
    final params = <String, dynamic>{'id': id, 'userId': userId};

    if (body.containsKey('quantity')) {
      final qty = body['quantity'] as int? ?? 1;
      if (qty < 1) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'Quantidade deve ser >= 1'},
        );
      }
      setClauses.add('quantity = @quantity');
      params['quantity'] = qty;
    }

    if (body.containsKey('condition')) {
      final cond = body['condition'] as String;
      if (!['NM', 'LP', 'MP', 'HP', 'DMG'].contains(cond)) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'Condição inválida. Use: NM, LP, MP, HP, DMG'},
        );
      }
      setClauses.add('condition = @condition');
      params['condition'] = cond;
    }

    if (body.containsKey('is_foil')) {
      setClauses.add('is_foil = @isFoil');
      params['isFoil'] = body['is_foil'] as bool? ?? false;
    }

    if (body.containsKey('for_trade')) {
      setClauses.add('for_trade = @forTrade');
      params['forTrade'] = body['for_trade'] as bool? ?? false;
    }

    if (body.containsKey('for_sale')) {
      setClauses.add('for_sale = @forSale');
      params['forSale'] = body['for_sale'] as bool? ?? false;
    }

    if (body.containsKey('price')) {
      setClauses.add('price = @price');
      params['price'] = body['price'] != null
          ? double.tryParse(body['price'].toString())
          : null;
    }

    if (body.containsKey('notes')) {
      setClauses.add('notes = @notes');
      params['notes'] = body['notes'] as String?;
    }

    if (body.containsKey('language')) {
      setClauses.add('language = @language');
      params['language'] = body['language'] as String? ?? 'en';
    }

    await pool.execute(Sql.named('''
      UPDATE user_binder_items
      SET ${setClauses.join(', ')}
      WHERE id = @id AND user_id = @userId
    '''), parameters: params);

    return Response.json(body: {'message': 'Item atualizado', 'id': id});
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao atualizar item: $e'},
    );
  }
}

/// DELETE /binder/:id
Future<Response> _deleteBinderItem(RequestContext context, String id) async {
  try {
    final userId = context.read<String>();
    final pool = context.read<Pool>();

    final result = await pool.execute(Sql.named('''
      DELETE FROM user_binder_items
      WHERE id = @id AND user_id = @userId
      RETURNING id
    '''), parameters: {'id': id, 'userId': userId});

    if (result.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Item não encontrado ou não pertence a você'},
      );
    }

    return Response(statusCode: HttpStatus.noContent);
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Erro ao remover item: $e'},
    );
  }
}
