import 'dart:convert';
import 'dart:math';

import 'package:postgres/postgres.dart';

import '../deck_schema_support.dart';
import '../scryfall_image_url.dart';

class ShareableReportService {
  ShareableReportService(this.pool);

  final Pool pool;

  static final _random = Random.secure();
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  Future<void> ensureSchema() async {
    await pool.execute(
      Sql.named('''
        CREATE TABLE IF NOT EXISTS shared_deck_reports (
          id TEXT PRIMARY KEY,
          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          deck_id UUID REFERENCES decks(id) ON DELETE SET NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          payload JSONB NOT NULL,
          is_public BOOLEAN NOT NULL DEFAULT TRUE,
          created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
          expires_at TIMESTAMP WITH TIME ZONE
        )
      '''),
    );
    await pool.execute(
      Sql.named('''
        CREATE INDEX IF NOT EXISTS idx_shared_deck_reports_deck_created
        ON shared_deck_reports (deck_id, created_at DESC)
      '''),
    );
    await pool.execute(
      Sql.named('''
        CREATE INDEX IF NOT EXISTS idx_shared_deck_reports_public_updated
        ON shared_deck_reports (is_public, updated_at DESC)
      '''),
    );
  }

  Future<Map<String, dynamic>?> createForDeck({
    required String userId,
    required String deckId,
    required Map<String, dynamic> body,
  }) async {
    await ensureSchema();

    final deck = await _loadOwnedDeck(userId: userId, deckId: deckId);
    if (deck == null) return null;

    final payloadBody = body['payload'];
    final payload = payloadBody is Map
        ? Map<String, dynamic>.from(payloadBody)
        : await _buildDeckSnapshotPayload(deckId: deckId, deck: deck);

    payload.putIfAbsent('deck_id', () => deckId);
    payload.putIfAbsent('deck_name', () => deck['name']?.toString() ?? '');
    payload.putIfAbsent('format', () => deck['format']?.toString() ?? '');

    final id = _newReportId();
    final title = _cleanString(body['title']).isNotEmpty
        ? _cleanString(body['title'])
        : 'Relatorio ManaLoom - ${deck['name']}';
    final description = _cleanString(body['description']).isNotEmpty
        ? _cleanString(body['description'])
        : _defaultDescription(payload, deck);

    final result = await pool.execute(
      Sql.named('''
        INSERT INTO shared_deck_reports (
          id,
          user_id,
          deck_id,
          title,
          description,
          payload,
          is_public,
          created_at,
          updated_at
        )
        VALUES (
          @id,
          CAST(@userId AS uuid),
          CAST(@deckId AS uuid),
          @title,
          @description,
          @payload::jsonb,
          TRUE,
          NOW(),
          NOW()
        )
        RETURNING id, deck_id, title, description, payload, is_public,
                  created_at, updated_at, expires_at
      '''),
      parameters: {
        'id': id,
        'userId': userId,
        'deckId': deckId,
        'title': title,
        'description': description,
        'payload': jsonEncode(payload),
      },
    );

    return result.isEmpty ? null : _rowToJson(result.first);
  }

  Future<Map<String, dynamic>?> getPublicReport(String reportId) async {
    await ensureSchema();
    final result = await pool.execute(
      Sql.named('''
        SELECT id, deck_id, title, description, payload, is_public,
               created_at, updated_at, expires_at
        FROM shared_deck_reports
        WHERE id = @reportId
          AND is_public = TRUE
          AND (expires_at IS NULL OR expires_at > NOW())
        LIMIT 1
      '''),
      parameters: {'reportId': reportId},
    );

    if (result.isEmpty) return null;
    return _rowToJson(result.first);
  }

  Future<Map<String, dynamic>?> _loadOwnedDeck({
    required String userId,
    required String deckId,
  }) async {
    final hasMeta = await hasDeckMetaColumns(pool);
    final result = await pool.execute(
      Sql.named(hasMeta
          ? '''
        SELECT id, name, format, description, bracket, archetype
        FROM decks
        WHERE id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
        LIMIT 1
      '''
          : '''
        SELECT id, name, format, description, NULL::int AS bracket, NULL::text AS archetype
        FROM decks
        WHERE id = CAST(@deckId AS uuid)
          AND user_id = CAST(@userId AS uuid)
        LIMIT 1
      '''),
      parameters: {'deckId': deckId, 'userId': userId},
    );
    return result.isEmpty ? null : result.first.toColumnMap();
  }

  Future<Map<String, dynamic>> _buildDeckSnapshotPayload({
    required String deckId,
    required Map<String, dynamic> deck,
  }) async {
    final cardsResult = await pool.execute(
      Sql.named('''
        SELECT
          dc.quantity,
          dc.is_commander,
          c.id,
          c.name,
          c.mana_cost,
          c.type_line,
          c.image_url,
          c.set_code,
          c.rarity
        FROM deck_cards dc
        JOIN cards c ON c.id = dc.card_id
        WHERE dc.deck_id = CAST(@deckId AS uuid)
        ORDER BY dc.is_commander DESC, c.name
      '''),
      parameters: {'deckId': deckId},
    );

    final cards = cardsResult.map((row) {
      final map = row.toColumnMap();
      return {
        'id': map['id']?.toString(),
        'name': map['name']?.toString() ?? '',
        'quantity': map['quantity'] as int? ?? 1,
        'is_commander': map['is_commander'] == true,
        'mana_cost': map['mana_cost']?.toString(),
        'type_line': map['type_line']?.toString(),
        'image_url': normalizeScryfallImageUrl(map['image_url']?.toString()),
        'set_code': map['set_code']?.toString(),
        'rarity': map['rarity']?.toString(),
      };
    }).toList(growable: false);

    final commander = cards.where((card) => card['is_commander'] == true);
    return {
      'type': 'deck_snapshot',
      'deck': {
        'id': deck['id']?.toString(),
        'name': deck['name']?.toString() ?? '',
        'format': deck['format']?.toString(),
        'description': deck['description']?.toString(),
        'bracket': deck['bracket'],
        'archetype': deck['archetype']?.toString(),
      },
      'commander': commander.isEmpty ? null : commander.first,
      'cards': cards.take(120).toList(growable: false),
      'stats': {
        'total_cards': cards.fold<int>(
          0,
          (sum, card) => sum + (card['quantity'] as int? ?? 1),
        ),
        'unique_cards': cards.length,
      },
    };
  }

  Map<String, dynamic> _rowToJson(ResultRow row) {
    final map = row.toColumnMap();
    return {
      'id': map['id']?.toString() ?? '',
      'deck_id': map['deck_id']?.toString(),
      'title': map['title']?.toString() ?? '',
      'description': map['description']?.toString() ?? '',
      'payload': _jsonMap(map['payload']),
      'is_public': map['is_public'] == true,
      'created_at': _dateString(map['created_at']),
      'updated_at': _dateString(map['updated_at']),
      'expires_at': _dateString(map['expires_at']),
    };
  }

  static String _defaultDescription(
    Map<String, dynamic> payload,
    Map<String, dynamic> deck,
  ) {
    final type = payload['type']?.toString();
    if (type == 'optimization_preview') {
      return 'Relatorio antes/depois gerado pelo ManaLoom para revisar trocas antes de aplicar.';
    }
    return 'Relatorio compartilhavel do deck ${deck['name']}.';
  }

  static Map<String, dynamic> _jsonMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }

  static String? _dateString(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    final text = value?.toString();
    return text == null || text.trim().isEmpty ? null : text;
  }

  static String _cleanString(Object? value) => value?.toString().trim() ?? '';

  static String _newReportId() {
    final suffix = List.generate(
      14,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();
    return 'rpt_${DateTime.now().microsecondsSinceEpoch}_$suffix';
  }
}
