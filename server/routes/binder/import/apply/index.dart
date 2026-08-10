import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/binder_import_contract.dart';
import '../../../../lib/observability.dart';

/// POST /binder/import/apply
///
/// Applies each reviewed physical identity independently. A row is written
/// only when its current quantity still matches `baseline_quantity`. Replaying
/// the same plan after a lost response is safe because `target_quantity` is
/// recognized as already applied instead of being added again.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final decoded = await context.request.json();
    if (decoded is! Map<String, dynamic>) {
      throw const BinderImportInputException(
        'binder_import_body_invalid',
        'Corpo da requisição inválido.',
      );
    }
    final batchId = readBinderImportBatchId(decoded['batch_id']);
    final items = readBinderImportItems(
      decoded['items'],
      requireApplyPlan: true,
    );
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final results = <Map<String, dynamic>>[];

    for (final item in items) {
      try {
        results.add(await _applyItem(pool, userId, item));
      } catch (error, stackTrace) {
        await captureRouteException(
          context,
          error,
          stackTrace: stackTrace,
          source: 'binder_import_apply_route',
          extras: {
            'operation': 'apply_binder_import_item',
            'batch_id': batchId,
            'input_id': item.inputId,
          },
        );
        results.add({
          'input_id': item.inputId,
          'status': 'failed',
          'code': 'binder_import_temporary_failure',
          'message': 'Falha temporária. A carta ficou disponível para retry.',
        });
      }
    }

    final appliedStatuses = {'created', 'updated', 'unchanged'};
    final applied =
        results
            .where((result) => appliedStatuses.contains(result['status']))
            .length;
    final failed = results.length - applied;
    final summary = await _availabilitySummary(pool, userId);
    return Response.json(
      body: {
        'batch_id': batchId,
        'data': results,
        'summary': summary,
        'total_input': results.length,
        'total_applied': applied,
        'total_failed': failed,
        'partial_failure': applied > 0 && failed > 0,
        'replay_safe': true,
      },
    );
  } on BinderImportInputException catch (error) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error.message, 'code': error.code},
    );
  } catch (error, stackTrace) {
    await captureRouteException(
      context,
      error,
      stackTrace: stackTrace,
      source: 'binder_import_apply_route',
      extras: {'operation': 'apply_binder_import'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Não foi possível aplicar o lote agora.'},
    );
  }
}

Future<Map<String, dynamic>> _applyItem(
  Pool pool,
  String userId,
  BinderImportItem item,
) {
  return pool.runTx((transaction) async {
    final card = await transaction.execute(
      Sql.named('SELECT id FROM cards WHERE id = @cardId'),
      parameters: {'cardId': item.cardId},
    );
    if (card.isEmpty) {
      return {
        'input_id': item.inputId,
        'status': 'failed',
        'code': 'binder_import_card_not_found',
        'message': 'A impressão não existe mais no catálogo.',
      };
    }

    final parameters = <String, dynamic>{
      'userId': userId,
      'cardId': item.cardId,
      'condition': item.condition,
      'isFoil': item.isFoil,
      'language': item.language,
      'listType': item.listType,
      'targetQuantity': item.targetQuantity,
    };
    var existing = await transaction.execute(
      Sql.named(r'''
        SELECT id::text AS id, quantity
        FROM user_binder_items
        WHERE user_id = @userId
          AND card_id = @cardId
          AND condition = @condition
          AND is_foil = @isFoil
          AND language = @language
          AND list_type = @listType
        FOR UPDATE
      '''),
      parameters: parameters,
    );

    if (existing.isEmpty) {
      if (item.baselineQuantity != 0) {
        return _inventoryChanged(item, currentQuantity: 0);
      }
      final inserted = await transaction.execute(
        Sql.named(r'''
          INSERT INTO user_binder_items (
            user_id,
            card_id,
            quantity,
            condition,
            is_foil,
            for_trade,
            for_sale,
            language,
            list_type
          ) VALUES (
            @userId,
            @cardId,
            @targetQuantity,
            @condition,
            @isFoil,
            FALSE,
            FALSE,
            @language,
            @listType
          )
          ON CONFLICT (
            user_id, card_id, condition, is_foil, language, list_type
          ) DO NOTHING
          RETURNING id::text AS id
        '''),
        parameters: parameters,
      );
      if (inserted.isNotEmpty) {
        return {
          'input_id': item.inputId,
          'status': 'created',
          'item_id': inserted.first.toColumnMap()['id'],
          'baseline_quantity': item.baselineQuantity,
          'target_quantity': item.targetQuantity,
        };
      }

      existing = await transaction.execute(
        Sql.named(r'''
          SELECT id::text AS id, quantity
          FROM user_binder_items
          WHERE user_id = @userId
            AND card_id = @cardId
            AND condition = @condition
            AND is_foil = @isFoil
            AND language = @language
            AND list_type = @listType
          FOR UPDATE
        '''),
        parameters: parameters,
      );
    }

    if (existing.isEmpty) {
      return _inventoryChanged(item, currentQuantity: 0);
    }
    final values = existing.first.toColumnMap();
    final currentQuantity = _quantity(values['quantity']);
    final itemId = values['id']?.toString();
    if (currentQuantity == item.targetQuantity) {
      return {
        'input_id': item.inputId,
        'status': 'unchanged',
        'item_id': itemId,
        'baseline_quantity': item.baselineQuantity,
        'target_quantity': item.targetQuantity,
        'message': 'Este item já havia sido aplicado.',
      };
    }
    if (currentQuantity != item.baselineQuantity) {
      return _inventoryChanged(item, currentQuantity: currentQuantity);
    }

    await transaction.execute(
      Sql.named(r'''
        UPDATE user_binder_items
        SET quantity = @targetQuantity,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @itemId AND user_id = @userId
      '''),
      parameters: {...parameters, 'itemId': itemId},
    );
    return {
      'input_id': item.inputId,
      'status': 'updated',
      'item_id': itemId,
      'baseline_quantity': item.baselineQuantity,
      'target_quantity': item.targetQuantity,
    };
  });
}

Map<String, dynamic> _inventoryChanged(
  BinderImportItem item, {
  required int currentQuantity,
}) {
  return {
    'input_id': item.inputId,
    'status': 'failed',
    'code': 'binder_import_inventory_changed',
    'message': 'A quantidade mudou desde a revisão. Revise este item de novo.',
    'baseline_quantity': item.baselineQuantity,
    'target_quantity': item.targetQuantity,
    'current_quantity': currentQuantity,
  };
}

Future<Map<String, int>> _availabilitySummary(Pool pool, String userId) async {
  final result = await pool.execute(
    Sql.named(r'''
      SELECT
        COALESCE(SUM(owned_quantity), 0)::int AS owned_quantity,
        COALESCE(SUM(allocated_quantity), 0)::int AS allocated_quantity,
        COALESCE(SUM(committed_trade_quantity), 0)::int
          AS committed_trade_quantity,
        COALESCE(SUM(free_quantity), 0)::int AS free_quantity,
        COALESCE(SUM(missing_quantity), 0)::int AS missing_quantity
      FROM collection_availability_snapshot
      WHERE user_id = @userId
    '''),
    parameters: {'userId': userId},
  );
  final values = result.first.toColumnMap();
  return {
    'owned_quantity': _quantity(values['owned_quantity']),
    'allocated_quantity': _quantity(values['allocated_quantity']),
    'committed_trade_quantity': _quantity(values['committed_trade_quantity']),
    'free_quantity': _quantity(values['free_quantity']),
    'missing_quantity': _quantity(values['missing_quantity']),
  };
}

int _quantity(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
