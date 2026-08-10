import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/binder_import_contract.dart';
import '../../../../lib/observability.dart';
import '../../../../lib/scryfall_image_url.dart';

/// POST /binder/import/preview
///
/// Read-only preflight for a physical collection batch. It resolves the
/// current quantity for each exact physical identity and returns the immutable
/// baseline/target pair later consumed by `/binder/import/apply`.
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
    final items = readBinderImportItems(
      decoded['items'],
      requireApplyPlan: false,
    );
    final userId = context.read<String>();
    final pool = context.read<Pool>();
    final result = await pool.execute(
      Sql.named(r'''
        WITH requested AS (
          SELECT *
          FROM jsonb_to_recordset(CAST(@items AS jsonb)) AS item(
            input_id text,
            card_id uuid,
            quantity integer,
            condition text,
            is_foil boolean,
            language text,
            list_type text
          )
        ),
        canonical_sets AS (
          SELECT DISTINCT ON (LOWER(code))
            code,
            name,
            release_date
          FROM sets
          ORDER BY LOWER(code), release_date DESC NULLS LAST, code
        )
        SELECT
          requested.input_id,
          requested.quantity,
          requested.condition,
          requested.is_foil,
          requested.language,
          requested.list_type,
          card.id::text AS card_id,
          card.scryfall_id::text AS scryfall_id,
          card.oracle_id::text AS oracle_id,
          card.name,
          card.image_url,
          card.layout,
          card.card_faces_json AS card_faces,
          card.set_code,
          card.collector_number,
          card.rarity,
          card.foil AS foil_available,
          canonical_set.name AS set_name,
          canonical_set.release_date AS set_release_date,
          binder_item.id::text AS existing_id,
          COALESCE(binder_item.quantity, 0)::int AS baseline_quantity,
          COALESCE(binder_item.quantity, 0)::int + requested.quantity
            AS target_quantity,
          COALESCE(card.oracle_id, card.id)::text AS playable_card_id,
          COALESCE(availability.owned_quantity, 0)::int AS owned_quantity,
          COALESCE(availability.allocated_quantity, 0)::int
            AS allocated_quantity,
          COALESCE(availability.committed_trade_quantity, 0)::int
            AS committed_trade_quantity,
          COALESCE(availability.free_quantity, 0)::int AS free_quantity,
          COALESCE(availability.missing_quantity, 0)::int AS missing_quantity
        FROM requested
        LEFT JOIN cards card ON card.id = requested.card_id
        LEFT JOIN canonical_sets canonical_set
          ON LOWER(canonical_set.code) = LOWER(card.set_code)
        LEFT JOIN user_binder_items binder_item
          ON binder_item.user_id = @userId
         AND binder_item.card_id = requested.card_id
         AND binder_item.condition = requested.condition
         AND binder_item.is_foil = requested.is_foil
         AND binder_item.language = requested.language
         AND binder_item.list_type = requested.list_type
        LEFT JOIN collection_availability_snapshot availability
          ON availability.user_id = @userId
         AND availability.playable_card_id = COALESCE(card.oracle_id, card.id)
      '''),
      parameters: {
        'items': jsonEncode(
          items.map((item) => item.toSqlJson()).toList(growable: false),
        ),
        'userId': userId,
      },
    );

    final rowsByInputId = <String, Map<String, dynamic>>{};
    for (final row in result) {
      final values = row.toColumnMap();
      final inputId = values['input_id']?.toString() ?? '';
      if (values['card_id'] == null) {
        rowsByInputId[inputId] = {
          'input_id': inputId,
          'status': 'rejected',
          'code': 'binder_import_card_not_found',
          'message': 'A impressão não existe mais no catálogo.',
        };
        continue;
      }
      final baseline = _quantity(values['baseline_quantity']);
      final target = _quantity(values['target_quantity']);
      rowsByInputId[inputId] = {
        'input_id': inputId,
        'status': 'ready',
        'action': baseline == 0 ? 'create' : 'update',
        'card': {
          'id': values['card_id'],
          'scryfall_id': values['scryfall_id'],
          'oracle_id': values['oracle_id'],
          'name': values['name'],
          'image_url': normalizeScryfallImageUrl(
            values['image_url']?.toString(),
            printingId: values['scryfall_id']?.toString(),
            oracleId: values['oracle_id']?.toString(),
          ),
          'layout': values['layout'],
          'card_faces': values['card_faces'],
          'set_code': values['set_code'],
          'collector_number': values['collector_number'],
          'set_name': values['set_name'],
          'set_release_date': _date(values['set_release_date']),
          'rarity': values['rarity'],
          'foil': values['foil_available'],
        },
        'quantity': _quantity(values['quantity']),
        'condition': values['condition'],
        'is_foil': values['is_foil'],
        'language': values['language'],
        'list_type': values['list_type'],
        'existing_id': values['existing_id'],
        'baseline_quantity': baseline,
        'target_quantity': target,
        'availability': {
          'playable_card_id': values['playable_card_id'],
          'owned_quantity': _quantity(values['owned_quantity']),
          'allocated_quantity': _quantity(values['allocated_quantity']),
          'committed_trade_quantity': _quantity(
            values['committed_trade_quantity'],
          ),
          'free_quantity': _quantity(values['free_quantity']),
          'missing_quantity': _quantity(values['missing_quantity']),
        },
      };
    }

    final plans = items
        .map(
          (item) =>
              rowsByInputId[item.inputId] ??
              {
                'input_id': item.inputId,
                'status': 'rejected',
                'code': 'binder_import_card_not_found',
                'message': 'A impressão não existe mais no catálogo.',
              },
        )
        .toList(growable: false);
    final summary = await _availabilitySummary(pool, userId);

    return Response.json(
      body: {
        'data': plans,
        'summary': summary,
        'total_input': items.length,
        'total_ready': plans.where((plan) => plan['status'] == 'ready').length,
        'total_rejected':
            plans.where((plan) => plan['status'] == 'rejected').length,
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
      source: 'binder_import_preview_route',
      extras: {'operation': 'preview_binder_import'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Não foi possível revisar o lote agora.'},
    );
  }
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

String? _date(Object? value) {
  if (value is DateTime) return value.toIso8601String().split('T').first;
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
