import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/ai/commander_learned_deck_support.dart';
import 'package:server/database.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  await runZoned(
    () async => _run(args),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => stderr.writeln(line),
    ),
  );
}

Future<void> _run(List<String> args) async {
  final apply = args.contains('--apply');
  if (apply && args.contains('--dry-run')) {
    throw ArgumentError('Use apenas um modo: --dry-run ou --apply.');
  }
  final rowId = _readArg(args, '--row-id=');
  final sourceRef = _readArg(args, '--source-ref=');
  final limit = _parseIntArg(args, '--limit=') ?? 0;
  final offset = _parseIntArg(args, '--offset=') ?? 0;
  final onlyChanged = !args.contains('--include-unchanged');
  final includeFullMetadata = args.contains('--include-full-metadata');
  final progress = args.contains('--progress');

  final startedAt = DateTime.now().toUtc();
  final database = Database();
  await database.connect();
  final pool = database.connection;

  try {
    final decks = await _loadActiveLearnedDecks(
      pool,
      rowId: rowId,
      sourceRef: sourceRef,
      limit: limit,
      offset: offset,
    );
    final results = <Map<String, dynamic>>[];

    for (var index = 0; index < decks.length; index += 1) {
      final deck = decks[index];
      if (progress) {
        stderr.writeln(
          'canonicalize_learned_deck_metadata '
          '${index + 1}/${decks.length} '
          '${deck.input.sourceRef} ${deck.input.commanderName}',
        );
      }
      final canonicalMetadata =
          await canonicalizeCommanderLearnedDeckMetadata(pool, deck.input);
      final metadataChanged =
          !_jsonDeepEquals(deck.input.metadata, canonicalMetadata);
      if (onlyChanged && !metadataChanged) continue;

      if (apply && metadataChanged) {
        await pool.execute(
          Sql.named('''
            UPDATE commander_learned_decks
            SET metadata = @metadata::jsonb,
                updated_at = NOW()
            WHERE id = @id::uuid
          '''),
          parameters: {
            'id': deck.rowId,
            'metadata': jsonEncode(canonicalMetadata),
          },
        );
      }

      results.add({
        'row_id': deck.rowId,
        'source_ref': deck.input.sourceRef,
        'commander_name': deck.input.commanderName,
        'deck_name': deck.input.deckName,
        'card_count': deck.input.cardCount,
        'parsed_card_count': deck.input.cards.fold<int>(
          0,
          (sum, card) => sum + card.quantity,
        ),
        'changed': metadataChanged,
        'applied': apply && metadataChanged,
        'before': _selectedMetadata(deck.input.metadata),
        'after': _selectedMetadata(canonicalMetadata),
        if (includeFullMetadata) 'before_full': deck.input.metadata,
        if (includeFullMetadata) 'after_full': canonicalMetadata,
      });
    }

    final changedCount =
        results.where((result) => result['changed'] == true).length;
    final output = {
      'status': 'PASS',
      'mode': apply ? 'apply' : 'dry_run',
      'db_mutations': apply,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'filters': {
        if (rowId != null) 'row_id': rowId,
        if (sourceRef != null) 'source_ref': sourceRef,
        if (limit > 0) 'limit': limit,
        if (offset > 0) 'offset': offset,
        'only_changed': onlyChanged,
        'include_full_metadata': includeFullMetadata,
        'progress': progress,
      },
      'checked': decks.length,
      'reported': results.length,
      'changed': changedCount,
      'applied': apply
          ? results.where((result) => result['applied'] == true).length
          : 0,
      'results': results,
    };

    stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));
  } finally {
    await database.close();
  }
}

void _printUsage() {
  stdout.writeln('''
canonicalize_learned_deck_metadata.dart - Recalcula metadata canonica de commander_learned_decks.

Uso:
  dart run bin/canonicalize_learned_deck_metadata.dart --source-ref=learned_deck:82
  dart run bin/canonicalize_learned_deck_metadata.dart --row-id=<uuid>
  dart run bin/canonicalize_learned_deck_metadata.dart --limit=10 --offset=20
  dart run bin/canonicalize_learned_deck_metadata.dart --apply --source-ref=learned_deck:82

Opcoes:
  --apply              Persiste metadata recalculada. Sem esta flag, roda dry-run.
  --dry-run            Explicita modo sem mutacao.
  --row-id=<uuid>      Filtra uma linha especifica de commander_learned_decks.
  --source-ref=<ref>   Filtra por source_ref, por exemplo learned_deck:82.
  --limit=<N>          Limita active rows consultadas.
  --offset=<N>         Pula N active rows na ordenacao canonica.
  --include-unchanged  Inclui linhas sem mudanca no JSON de saida.
  --include-full-metadata
                       Inclui metadata completa antes/depois para pacote de
                       rollback; pode gerar JSON grande.
  --progress           Escreve progresso por row em stderr.

Saida:
  JSON limpo em stdout, sem segredos. Logs de conexao/progresso ficam em stderr.
  O modo padrao nunca escreve no PostgreSQL.
''');
}

Future<List<_LearnedDeckRow>> _loadActiveLearnedDecks(
  Pool pool, {
  String? rowId,
  String? sourceRef,
  int limit = 0,
  int offset = 0,
}) async {
  final filters = <String>['is_active = TRUE'];
  final parameters = <String, dynamic>{};
  if (rowId != null && rowId.trim().isNotEmpty) {
    filters.add('id = @row_id::uuid');
    parameters['row_id'] = rowId.trim();
  }
  if (sourceRef != null && sourceRef.trim().isNotEmpty) {
    filters.add('source_ref = @source_ref');
    parameters['source_ref'] = sourceRef.trim();
  }
  final limitClause = limit > 0 ? 'LIMIT @limit' : '';
  if (limit > 0) parameters['limit'] = limit;
  final offsetClause = offset > 0 ? 'OFFSET @offset' : '';
  if (offset > 0) parameters['offset'] = offset;

  final rows = await pool.execute(
    Sql.named('''
      SELECT
        id::text,
        commander_name,
        deck_name,
        source_system,
        source_ref,
        source_url,
        archetype,
        card_list,
        card_count,
        score,
        wincon_primary,
        wincon_backup,
        legal_status,
        notes,
        metadata,
        is_active,
        promoted_at,
        updated_at
      FROM commander_learned_decks
      WHERE ${filters.join(' AND ')}
      ORDER BY commander_name, deck_name, source_ref
      $limitClause
      $offsetClause
    '''),
    parameters: parameters,
  );

  return rows.map(_learnedDeckRowFromResult).toList(growable: false);
}

_LearnedDeckRow _learnedDeckRowFromResult(ResultRow row) {
  final commanderName = row[1]?.toString() ?? '';
  return _LearnedDeckRow(
    rowId: row[0]?.toString() ?? '',
    input: CommanderLearnedDeckInput(
      commanderName: commanderName,
      deckName: row[2]?.toString() ?? commanderName,
      sourceSystem: row[3]?.toString() ?? 'unknown',
      sourceRef: row[4]?.toString() ?? 'unknown',
      sourceUrl: row[5]?.toString(),
      archetype: row[6]?.toString(),
      cardList: row[7]?.toString() ?? '',
      cardCount: _intValue(row[8]),
      score: _nullableDouble(row[9]),
      winconPrimary: row[10]?.toString(),
      winconBackup: row[11]?.toString(),
      legalStatus: row[12]?.toString(),
      notes: row[13]?.toString(),
      metadata: _jsonObject(row[14]),
      isActive: row[15] == true,
      promotedAt: _dateTimeValue(row[16]),
      updatedAt: _dateTimeValue(row[17]),
    ),
  );
}

Map<String, dynamic> _selectedMetadata(Map<String, dynamic> metadata) {
  return {
    for (final key in [
      'total_lands',
      'ramp_count',
      'draw_count',
      'removal_count',
      'tutor_count',
      'engine_count',
      'wincon_count',
      'protection_count',
      'recursion_count',
      'board_wipe_count',
    ])
      key: metadata[key],
  };
}

bool _jsonDeepEquals(Object? left, Object? right) {
  return jsonEncode(_normalizeJson(left)) == jsonEncode(_normalizeJson(right));
}

Object? _normalizeJson(Object? value) {
  if (value is Map) {
    return {
      for (final key
          in value.keys.map((key) => key.toString()).toList()..sort())
        key: _normalizeJson(value[key]),
    };
  }
  if (value is Iterable) {
    return value.map(_normalizeJson).toList(growable: false);
  }
  return value;
}

Map<String, dynamic> _jsonObject(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  if (value is String && value.trim().isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map) {
      return decoded.map((key, item) => MapEntry(key.toString(), item));
    }
  }
  return <String, dynamic>{};
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _dateTimeValue(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

int? _parseIntArg(List<String> args, String prefix) {
  final value = _readArg(args, prefix);
  if (value == null || value.trim().isEmpty) return null;
  return int.tryParse(value.trim());
}

class _LearnedDeckRow {
  const _LearnedDeckRow({
    required this.rowId,
    required this.input,
  });

  final String rowId;
  final CommanderLearnedDeckInput input;
}
