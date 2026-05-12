import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import 'package:server/database.dart';
import 'package:server/mtg_data_integrity_support.dart';

const _defaultArtifactDir =
    'test/artifacts/scryfall_missing_card_backfill_2026-05-12';
const _scryfallNamedUrl = 'https://api.scryfall.com/cards/named';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final namesArg = _readArg(args, '--names=');
  final namesFile = _readArg(args, '--names-file=');
  final names = <String>{
    if (namesArg != null)
      ...namesArg
          .split('|')
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty),
    if (namesFile != null) ..._readNamesFile(namesFile),
  }.toList()
    ..sort();

  if (names.isEmpty) {
    throw ArgumentError('Informe --names="Card A|Card B" ou --names-file.');
  }

  final apply = args.contains('--apply');
  final dryRun = args.contains('--dry-run') || !apply;
  if (apply && args.contains('--dry-run')) {
    throw ArgumentError('Use apenas um modo: --dry-run ou --apply.');
  }

  final artifactDir =
      Directory(_readArg(args, '--artifact-dir=') ?? _defaultArtifactDir);
  await artifactDir.create(recursive: true);

  final db = Database();
  await db.connect();
  final pool = db.connection;
  final startedAt = DateTime.now().toUtc();

  try {
    final rows = <_ScryfallCardRow>[];
    final failures = <Map<String, dynamic>>[];

    for (final name in names) {
      try {
        final row = await _fetchScryfallCard(name);
        rows.add(row);
      } catch (error) {
        failures.add({'name': name, 'error': error.toString()});
      }
    }

    final existingRows = await _findExistingOracleIds(
      pool,
      rows.map((row) => row.oracleId).toList(),
    );
    final missingRows = rows
        .where((row) => !existingRows.contains(row.oracleId))
        .toList(growable: false);

    if (apply && failures.isNotEmpty) {
      throw StateError('Falha ao resolver cartas no Scryfall: $failures');
    }

    if (apply && missingRows.isNotEmpty) {
      await pool.runTx((session) async {
        await _upsertCards(session, missingRows);
        await _upsertLegalities(session, missingRows);
      });
    }

    final summary = {
      'status': failures.isEmpty ? 'PASS' : 'PASS_WITH_RISKS',
      'mode': dryRun ? 'dry_run' : 'apply',
      'db_mutations': apply,
      'started_at': startedAt.toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'requested_count': names.length,
      'scryfall_resolved_count': rows.length,
      'already_present_count': existingRows.length,
      'missing_before_apply_count': missingRows.length,
      'applied_card_count': apply ? missingRows.length : 0,
      'failures': failures,
      'cards': rows.map((row) => row.toSafeJson()).toList(),
    };
    final outputPath =
        '${artifactDir.path}/scryfall_missing_card_backfill_${dryRun ? 'dry_run' : 'apply'}_summary.json';
    await _writeJson(outputPath, summary);
    print(jsonEncode({
      'status': summary['status'],
      'mode': summary['mode'],
      'db_mutations': apply,
      'requested_count': summary['requested_count'],
      'scryfall_resolved_count': summary['scryfall_resolved_count'],
      'missing_before_apply_count': summary['missing_before_apply_count'],
      'applied_card_count': summary['applied_card_count'],
      'artifact': outputPath,
    }));
  } finally {
    await db.close();
  }
}

List<String> _readNamesFile(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is List) {
    return decoded.map((value) => value.toString().trim()).toList();
  }
  if (decoded is Map && decoded['names'] is List) {
    return (decoded['names'] as List)
        .map((value) => value.toString().trim())
        .toList();
  }
  throw ArgumentError('--names-file precisa ser JSON list ou {"names":[]}.');
}

Future<_ScryfallCardRow> _fetchScryfallCard(String exactName) async {
  final uri = Uri.parse(_scryfallNamedUrl).replace(queryParameters: {
    'exact': exactName,
  });
  final response = await http.get(uri, headers: {
    'User-Agent': 'ManaLoom/1.0 data-backfill',
    'Accept': 'application/json',
  }).timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw StateError(
      'Scryfall ${response.statusCode} para $exactName',
    );
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return _ScryfallCardRow.fromJson(json);
}

Future<Set<String>> _findExistingOracleIds(
  Pool pool,
  List<String> oracleIds,
) async {
  if (oracleIds.isEmpty) return const <String>{};
  final result = await pool.execute(
    Sql.named(
      'SELECT scryfall_id::text FROM cards WHERE scryfall_id::text = ANY(@ids)',
    ),
    parameters: {'ids': TypedValue(Type.textArray, oracleIds)},
  );
  return result.map((row) => row[0].toString()).toSet();
}

Future<void> _upsertCards(
  Session session,
  List<_ScryfallCardRow> rows,
) async {
  for (final row in rows) {
    await session.execute(
      Sql.named('''
        INSERT INTO cards (
          scryfall_id, name, mana_cost, type_line, oracle_text,
          colors, color_identity, image_url, set_code, rarity,
          collector_number, foil
        ) VALUES (
          @scryfall_id, @name, @mana_cost, @type_line, @oracle_text,
          @colors, @color_identity, @image_url, @set_code, @rarity,
          @collector_number, @foil
        )
        ON CONFLICT (scryfall_id) DO UPDATE SET
          name = EXCLUDED.name,
          mana_cost = EXCLUDED.mana_cost,
          type_line = EXCLUDED.type_line,
          oracle_text = EXCLUDED.oracle_text,
          colors = EXCLUDED.colors,
          color_identity = EXCLUDED.color_identity,
          image_url = EXCLUDED.image_url,
          set_code = EXCLUDED.set_code,
          rarity = EXCLUDED.rarity,
          collector_number = COALESCE(EXCLUDED.collector_number, cards.collector_number),
          foil = COALESCE(EXCLUDED.foil, cards.foil)
      '''),
      parameters: row.toSqlParameters(),
    );
  }
}

Future<void> _upsertLegalities(
  Session session,
  List<_ScryfallCardRow> rows,
) async {
  for (final row in rows) {
    final cardResult = await session.execute(
      Sql.named('SELECT id::text FROM cards WHERE scryfall_id = @scryfall_id'),
      parameters: {'scryfall_id': row.oracleId},
    );
    if (cardResult.isEmpty) {
      throw StateError('Card nao encontrado apos upsert: ${row.name}');
    }
    final cardId = cardResult.first[0].toString();
    for (final entry in row.legalities.entries) {
      await session.execute(
        Sql.named('''
          INSERT INTO card_legalities (card_id, format, status)
          VALUES (@card_id, @format, @status)
          ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status
        '''),
        parameters: {
          'card_id': cardId,
          'format': entry.key,
          'status': entry.value,
        },
      );
    }
  }
}

Future<void> _writeJson(String path, Map<String, dynamic> payload) async {
  const encoder = JsonEncoder.withIndent('  ');
  await File(path).writeAsString('${encoder.convert(payload)}\n');
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

class _ScryfallCardRow {
  const _ScryfallCardRow({
    required this.oracleId,
    required this.name,
    required this.manaCost,
    required this.typeLine,
    required this.oracleText,
    required this.colors,
    required this.colorIdentity,
    required this.imageUrl,
    required this.setCode,
    required this.rarity,
    required this.collectorNumber,
    required this.foil,
    required this.legalities,
  });

  final String oracleId;
  final String name;
  final String? manaCost;
  final String? typeLine;
  final String? oracleText;
  final List<String> colors;
  final List<String> colorIdentity;
  final String? imageUrl;
  final String? setCode;
  final String? rarity;
  final String? collectorNumber;
  final bool? foil;
  final Map<String, String> legalities;

  factory _ScryfallCardRow.fromJson(Map<String, dynamic> json) {
    final oracleId = json['oracle_id']?.toString();
    if (oracleId == null || oracleId.isEmpty) {
      throw StateError('Scryfall payload sem oracle_id.');
    }
    final faces = (json['card_faces'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];
    final imageUris = (json['image_uris'] as Map?) ??
        faces.firstOrNull?['image_uris'] as Map?;
    final colors = _stringList(json['colors']);
    final faceColors = faces.expand((face) => _stringList(face['colors']));
    final foil = json['foil'] == true && json['nonfoil'] != true
        ? true
        : json['nonfoil'] == true && json['foil'] != true
            ? false
            : null;

    return _ScryfallCardRow(
      oracleId: oracleId,
      name: json['name']?.toString() ?? '',
      manaCost: json['mana_cost']?.toString().isNotEmpty == true
          ? json['mana_cost'].toString()
          : _joinFaces(faces, 'mana_cost'),
      typeLine: json['type_line']?.toString().isNotEmpty == true
          ? json['type_line'].toString()
          : _joinFaces(faces, 'type_line'),
      oracleText: json['oracle_text']?.toString().isNotEmpty == true
          ? json['oracle_text'].toString()
          : _joinFaces(faces, 'oracle_text'),
      colors: colors.isNotEmpty ? colors : faceColors.toSet().toList()
        ..sort(),
      colorIdentity: _stringList(json['color_identity']),
      imageUrl: imageUris?['normal']?.toString(),
      setCode: normalizeMtgSetCode(json['set']?.toString()),
      rarity: json['rarity']?.toString(),
      collectorNumber: json['collector_number']?.toString(),
      foil: foil,
      legalities: (json['legalities'] as Map? ?? const {})
          .map((key, value) => MapEntry(key.toString(), value.toString())),
    );
  }

  Map<String, dynamic> toSqlParameters() => {
        'scryfall_id': oracleId,
        'name': name,
        'mana_cost': manaCost,
        'type_line': typeLine,
        'oracle_text': oracleText,
        'colors': colors,
        'color_identity': colorIdentity,
        'image_url': imageUrl,
        'set_code': setCode,
        'rarity': rarity,
        'collector_number': collectorNumber,
        'foil': foil,
      };

  Map<String, dynamic> toSafeJson() => {
        'oracle_id': oracleId,
        'name': name,
        'set_code': setCode,
        'collector_number': collectorNumber,
        'type_line': typeLine,
        'color_identity': colorIdentity,
        'commander_legality': legalities['commander'],
      };
}

List<String> _stringList(Object? raw) =>
    (raw as List?)?.map((value) => value.toString()).toList() ??
    const <String>[];

String? _joinFaces(List<Map<String, dynamic>> faces, String key) {
  final values = faces
      .map((face) => face[key]?.toString().trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  return values.isEmpty ? null : values.join('\n---\n');
}

void _printUsage() {
  print('''
Usage:
  dart run bin/backfill_missing_scryfall_cards.dart --names="Card A|Card B" --dry-run
  dart run bin/backfill_missing_scryfall_cards.dart --names-file=cards.json --apply

Dry-run e o modo padrao. O --apply busca cartas por nome exato no Scryfall,
faz upsert por oracle_id na tabela cards e atualiza card_legalities.
Use apenas para sanar lacunas pontuais de freshness antes de importar corpus
real validado.
''');
}
