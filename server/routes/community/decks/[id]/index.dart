import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import '../../../../lib/auth_service.dart';
import '../../../../lib/basic_land_utils.dart' as land_utils;
import '../../../../lib/logger.dart';
import '../../../../lib/observability.dart';
import '../../../../lib/scryfall_image_url.dart';
import '../../../../lib/community_request_auth.dart';
import '../following/index.dart' as following_route;

Future<Response> onRequest(RequestContext context, String id) async {
  // Dart Frog mounts /community/decks/<id> before the static /following route.
  // This dispatch contains no feed logic; it delegates to the canonical route.
  if (id == 'following') return following_route.onRequest(context);

  if (context.request.method == HttpMethod.get) {
    return _getPublicDeck(context, id);
  }

  if (context.request.method == HttpMethod.post) {
    return _copyPublicDeck(context, id);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}

/// GET /community/decks/:id — visualizar deck público (sem auth)
Future<Response> _getPublicDeck(RequestContext context, String deckId) async {
  final conn = context.read<Pool>();
  final viewerUserId = await readAuthenticatedUserId(context);

  try {
    // Buscar deck público
    final deckResult = await conn.execute(
      Sql.named('''
        SELECT d.id, d.name, d.format, d.description,
               d.synergy_score, d.strengths, d.weaknesses,
               d.is_public, d.created_at,
               COALESCE(comment_counts.comment_count, 0)::int AS comment_count,
               u.id as owner_id,
               u.username as owner_username
        FROM decks d
        JOIN users u ON u.id = d.user_id
        LEFT JOIN LATERAL (
          SELECT COUNT(*)::int AS comment_count
          FROM deck_comments dcmt
          WHERE dcmt.deck_id = d.id
            AND dcmt.status = 'visible'
        ) comment_counts ON TRUE
        WHERE d.id = @deckId
          AND d.is_public = true
          AND d.deleted_at IS NULL
          AND u.deleted_at IS NULL
          AND u.profile_visibility = 'public'
          AND (
            CAST(@viewerUserId AS uuid) IS NULL
            OR NOT EXISTS (
              SELECT 1
              FROM user_blocks b
              WHERE (
                b.blocker_id = CAST(@viewerUserId AS uuid)
                AND b.blocked_id = d.user_id
              ) OR (
                b.blocked_id = CAST(@viewerUserId AS uuid)
                AND b.blocker_id = d.user_id
              )
            )
          )
      '''),
      parameters: {'deckId': deckId, 'viewerUserId': viewerUserId},
    );

    if (deckResult.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Deck not found or is not public.'},
      );
    }

    final deckInfo = deckResult.first.toColumnMap();
    if (deckInfo['created_at'] is DateTime) {
      deckInfo['created_at'] =
          (deckInfo['created_at'] as DateTime).toIso8601String();
    }

    // Buscar cartas
    final cardsResult = await conn.execute(
      Sql.named('''
        SELECT
          dc.quantity,
          dc.is_commander,
          c.id,
          c.name,
          c.mana_cost,
          c.type_line,
          c.oracle_text,
          c.colors,
          c.color_identity,
          c.image_url,
          c.set_code,
          c.rarity
        FROM deck_cards dc
        JOIN cards c ON dc.card_id = c.id
        WHERE dc.deck_id = @deckId
      '''),
      parameters: {'deckId': deckId},
    );

    final cardsList =
        cardsResult.map((row) {
          final m = row.toColumnMap();
          m['image_url'] = normalizeScryfallImageUrl(
            m['image_url']?.toString(),
          );
          return m;
        }).toList();

    // Organizar
    final commander = <Map<String, dynamic>>[];
    final mainBoard = <String, List<Map<String, dynamic>>>{};

    String getMainType(String typeLine) {
      final t = typeLine.toLowerCase();
      if (land_utils.isLandTypeLine(typeLine)) return 'Land';
      if (t.contains('creature')) return 'Creature';
      if (t.contains('planeswalker')) return 'Planeswalker';
      if (t.contains('artifact')) return 'Artifact';
      if (t.contains('enchantment')) return 'Enchantment';
      if (t.contains('instant')) return 'Instant';
      if (t.contains('sorcery')) return 'Sorcery';
      if (t.contains('battle')) return 'Battle';
      return 'Other';
    }

    int calculateCmc(String? manaCost) {
      if (manaCost == null || manaCost.isEmpty) return 0;
      int cmc = 0;
      final regex = RegExp(r'\{([^}]+)\}');
      for (final match in regex.allMatches(manaCost)) {
        final symbol = match.group(1)!;
        if (int.tryParse(symbol) != null) {
          cmc += int.parse(symbol);
        } else if (symbol.toUpperCase() != 'X') {
          cmc += 1;
        }
      }
      return cmc;
    }

    final manaCurve = <String, int>{};
    final typeDistribution = <String, int>{};
    final colorDistribution = <String, int>{
      'W': 0,
      'U': 0,
      'B': 0,
      'R': 0,
      'G': 0,
      'C': 0,
    };

    for (final card in cardsList) {
      if (card['is_commander'] == true) {
        commander.add(card);
      } else {
        final type = getMainType(card['type_line'] as String? ?? '');
        mainBoard.putIfAbsent(type, () => []).add(card);
        typeDistribution[type] =
            (typeDistribution[type] ?? 0) + (card['quantity'] as int);
      }

      final cost = card['mana_cost'] as String?;
      final typeLine = card['type_line'] as String? ?? '';

      if (!land_utils.isLandTypeLine(typeLine)) {
        final cmc = calculateCmc(cost);
        final cmcKey = cmc >= 7 ? '7+' : cmc.toString();
        manaCurve[cmcKey] =
            (manaCurve[cmcKey] ?? 0) + (card['quantity'] as int);
      }

      final colors = card['colors'] as List?;
      if (colors != null && colors.isNotEmpty) {
        for (final color in colors) {
          if (colorDistribution.containsKey(color)) {
            colorDistribution[color as String] =
                colorDistribution[color]! + (card['quantity'] as int);
          }
        }
      }
    }

    return Response.json(
      body: {
        ...deckInfo,
        'stats': {
          'total_cards': cardsList.fold<int>(
            0,
            (sum, item) => sum + (item['quantity'] as int),
          ),
          'unique_cards': cardsList.length,
          'mana_curve': manaCurve,
          'type_distribution': typeDistribution,
          'color_distribution': colorDistribution,
        },
        'comments_summary': {'comment_count': deckInfo['comment_count'] ?? 0},
        'visual_analysis': _buildVisualAnalysis(
          manaCurve: manaCurve,
          typeDistribution: typeDistribution,
          colorDistribution: colorDistribution,
          commanderName:
              commander.isNotEmpty ? commander.first['name']?.toString() : null,
        ),
        'commander': commander,
        'main_board': mainBoard,
        'all_cards_flat': cardsList,
      },
    );
  } catch (e, st) {
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'community_deck_detail_route',
      extras: {'operation': 'get_public_deck'},
    );
    Log.e(
      '[community_route] server_error endpoint=GET /community/decks/:id error=$e',
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to get public deck'},
    );
  }
}

Map<String, dynamic> _buildVisualAnalysis({
  required Map<String, int> manaCurve,
  required Map<String, int> typeDistribution,
  required Map<String, int> colorDistribution,
  String? commanderName,
}) {
  final nonZeroColors = colorDistribution.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toList(growable: false);
  final topTypes =
      typeDistribution.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  final lowCurve =
      (manaCurve['0'] ?? 0) + (manaCurve['1'] ?? 0) + (manaCurve['2'] ?? 0);
  final midCurve = (manaCurve['3'] ?? 0) + (manaCurve['4'] ?? 0);
  final highCurve =
      (manaCurve['5'] ?? 0) + (manaCurve['6'] ?? 0) + (manaCurve['7+'] ?? 0);

  return {
    'headline':
        commanderName == null || commanderName.isEmpty
            ? 'Deck publico ManaLoom'
            : 'Plano publico de $commanderName',
    'color_identity_hint': nonZeroColors.isEmpty ? ['C'] : nonZeroColors,
    'top_type_buckets': topTypes
        .take(4)
        .map((entry) => {'type': entry.key, 'count': entry.value})
        .toList(growable: false),
    'curve_shape': {'low': lowCurve, 'mid': midCurve, 'high': highCurve},
    'reading': _curveReading(
      lowCurve: lowCurve,
      midCurve: midCurve,
      highCurve: highCurve,
    ),
  };
}

String _curveReading({
  required int lowCurve,
  required int midCurve,
  required int highCurve,
}) {
  if (highCurve > lowCurve + midCurve) {
    return 'Curva pesada: revisar ramp e primeiros turnos antes de subir o nivel da mesa.';
  }
  if (lowCurve >= midCurve + highCurve) {
    return 'Curva baixa: deck tende a agir cedo, mas precisa manter compra e recursos.';
  }
  return 'Curva intermediaria: boa candidata para comparar ajustes por funcao e bracket.';
}

/// POST /community/decks/:id — copiar deck público para conta do usuário (requer auth)
Future<Response> _copyPublicDeck(RequestContext context, String deckId) async {
  // Autenticação manual (não há middleware de auth nesta rota)
  final authHeader = context.request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'Token de autenticação necessário para copiar decks.'},
    );
  }

  final token = authHeader.substring(7);
  final authService = AuthService();
  final user = await authService.getUserFromToken(token);
  if (user == null) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'Token inválido ou expirado.'},
    );
  }

  final userId = user['id'] as String;
  final conn = context.read<Pool>();

  try {
    final newDeck = await conn.runTx((session) async {
      // 1. Verificar que o deck original existe e é público
      final original = await session.execute(
        Sql.named('''
          SELECT d.id, d.name, d.format, d.description
          FROM decks d
          JOIN users u ON u.id = d.user_id
          WHERE d.id = @deckId
            AND d.is_public = true
            AND d.deleted_at IS NULL
            AND u.deleted_at IS NULL
            AND u.profile_visibility = 'public'
            AND NOT EXISTS (
              SELECT 1
              FROM user_blocks b
              WHERE (
                b.blocker_id = CAST(@userId AS uuid)
                AND b.blocked_id = d.user_id
              ) OR (
                b.blocked_id = CAST(@userId AS uuid)
                AND b.blocker_id = d.user_id
              )
            )
        '''),
        parameters: {'deckId': deckId, 'userId': userId},
      );

      if (original.isEmpty) {
        throw Exception('Deck not found or is not public.');
      }

      final origMap = original.first.toColumnMap();
      final newName = 'Cópia de ${origMap['name']}';

      // 2. Criar novo deck para o usuário
      final insertResult = await session.execute(
        Sql.named('''
          INSERT INTO decks (user_id, name, format, description)
          VALUES (@userId, @name, @format, @desc)
          RETURNING id, name, format, description, created_at
        '''),
        parameters: {
          'userId': userId,
          'name': newName,
          'format': origMap['format'],
          'desc': origMap['description'],
        },
      );

      final newDeckMap = insertResult.first.toColumnMap();
      if (newDeckMap['created_at'] is DateTime) {
        newDeckMap['created_at'] =
            (newDeckMap['created_at'] as DateTime).toIso8601String();
      }

      final newDeckId = newDeckMap['id'];

      // 3. Copiar todas as cartas
      await session.execute(
        Sql.named('''
          INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
          SELECT @newDeckId, card_id, quantity, is_commander
          FROM deck_cards WHERE deck_id = @deckId
        '''),
        parameters: {'newDeckId': newDeckId, 'deckId': deckId},
      );

      return newDeckMap;
    });

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'success': true, 'deck': newDeck},
    );
  } on Exception catch (e, st) {
    Log.e(
      '[community_route] server_error endpoint=POST /community/decks/:id error=$e',
    );
    final msg = e.toString();
    if (msg.contains('not found') || msg.contains('not public')) {
      return Response.json(statusCode: 404, body: {'error': msg});
    }
    await captureRouteException(
      context,
      e,
      stackTrace: st,
      source: 'community_deck_copy_route',
      extras: {'operation': 'copy_public_deck'},
    );
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to copy deck'},
    );
  }
}
