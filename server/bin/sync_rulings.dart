// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';

import '../lib/database.dart';

/// Reconcilia o snapshot oficial de rulings do Scryfall com `card_rulings`.
///
/// O arquivo bulk e uma lista JSON de objetos contendo `oracle_id`, `source`,
/// `published_at` e `comment`. A aplicacao usa snapshot-replace transacional:
/// dados gerenciados por MTGJSON/Scryfall so sao removidos depois que o novo
/// snapshot foi baixado, parseado e validado integralmente.
///
/// Leitura/validacao sem PostgreSQL:
///   dart run bin/sync_rulings.dart --dry-run [--file=/caminho/rulings.json]
///
/// Aplicacao (exige aprovacao textual explicita para a execucao):
///   MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
///     dart run bin/sync_rulings.dart [--file=/caminho/rulings.json]
const scryfallBulkMetadataUrl = 'https://api.scryfall.com/bulk-data';
const defaultRulingsFile = 'scryfall-rulings.json';
const rulingsWriteApprovalEnvironment = 'MANALOOM_CONFIRM_POSTGRES_WRITES';
const rulingsWriteApprovalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';
const minimumExpectedRulingCount = 50000;
const minimumExpectedOracleIdCount = 15000;

bool hasRulingsWriteApproval(Map<String, String> environment) =>
    environment[rulingsWriteApprovalEnvironment] == rulingsWriteApprovalPhrase;

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final fileArg = args
      .firstWhere((a) => a.startsWith('--file='), orElse: () => '')
      .replaceFirst('--file=', '');

  if (!dryRun && !hasRulingsWriteApproval(Platform.environment)) {
    stderr.writeln(
      'BLOCKED: sincronizar rulings altera PostgreSQL. Defina '
      '$rulingsWriteApprovalEnvironment=$rulingsWriteApprovalPhrase somente '
      'apos aprovacao explicita para esta execucao.',
    );
    exitCode = 2;
    return;
  }

  print('Sync de rulings oficiais do Scryfall${dryRun ? ' [DRY-RUN]' : ''}');

  try {
    final input =
        fileArg.isNotEmpty
            ? await _localInput(File(fileArg))
            : await _downloadCurrentSnapshot(
              File(defaultRulingsFile),
              force: force,
            );
    final decoded = jsonDecode(await input.file.readAsString());
    final rulings = parseScryfallRulings(decoded);
    final snapshot = summarizeRulings(rulings);
    validateRulingsSnapshot(snapshot);
    final contentHash = await _sha256File(input.file);

    print('Arquivo: ${input.file.path}');
    print('Rulings: ${snapshot.rowCount}');
    print('Oracle IDs: ${snapshot.distinctOracleIds}');
    print('Data mais recente: ${snapshot.latestPublishedAt ?? 'n/a'}');
    print('SHA-256: $contentHash');

    if (dryRun) {
      print('DRY-RUN concluido: nenhuma conexao ou escrita PostgreSQL.');
      return;
    }

    final db = Database();
    await db.connect();
    if (!db.isConnected) {
      throw StateError('Sem conexao com PostgreSQL.');
    }
    try {
      await _ensureRequiredTables(db.connection);
      await reconcileRulingsSnapshot(
        db.connection,
        rulings,
        metadata: input.metadata,
        contentHash: contentHash,
        summary: snapshot,
      );
    } finally {
      await db.close();
    }

    print('Sync concluido: snapshot Scryfall reconciliado integralmente.');
  } catch (error, stackTrace) {
    stderr.writeln('Erro no sync de rulings: $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

void _printUsage() {
  print('''
Uso: dart run bin/sync_rulings.dart [opcoes]

  --dry-run       baixa/le o snapshot e valida sem conectar ao PostgreSQL
  --file=<path>   usa um bulk rulings local em vez de baixar
  --force         ignora cache local mesmo quando o metadata nao mudou
  --help          mostra esta ajuda

Aplicar exige $rulingsWriteApprovalEnvironment=$rulingsWriteApprovalPhrase.
''');
}

List<RulingRecord> parseScryfallRulings(Object? decoded) {
  if (decoded is! List) {
    throw const FormatException('Bulk rulings deve ser uma lista JSON.');
  }

  final byIdentity = <String, RulingRecord>{};
  for (final raw in decoded) {
    if (raw is! Map) {
      throw const FormatException('Ruling deve ser um objeto JSON.');
    }
    final oracleId = raw['oracle_id']?.toString().trim() ?? '';
    final comment = raw['comment']?.toString().trim() ?? '';
    final publishedAt = raw['published_at']?.toString().trim() ?? '';
    final upstreamSource = raw['source']?.toString().trim() ?? '';
    if (!_uuidPattern.hasMatch(oracleId)) {
      throw FormatException('oracle_id invalido no bulk: $oracleId');
    }
    // O bulk oficial contem historicamente ao menos um placeholder apenas com
    // NBSP. Ele nao representa uma ruling e deve ser ignorado; os thresholds
    // globais abaixo continuam protegendo contra downloads truncados.
    if (comment.isEmpty) continue;
    if (!_datePattern.hasMatch(publishedAt) ||
        DateTime.tryParse(publishedAt) == null) {
      throw FormatException(
        'published_at invalido para oracle_id=$oracleId: $publishedAt',
      );
    }

    final hash =
        sha256
            .convert(utf8.encode('$publishedAt|$upstreamSource|$comment'))
            .toString();
    byIdentity['$oracleId|$hash'] = RulingRecord(
      oracleId: oracleId,
      upstreamSource: upstreamSource,
      publishedAt: publishedAt,
      comment: comment,
      commentHash: hash,
    );
  }
  return byIdentity.values.toList(growable: false);
}

RulingsSnapshotSummary summarizeRulings(List<RulingRecord> rulings) {
  String? latest;
  final oracleIds = <String>{};
  for (final ruling in rulings) {
    oracleIds.add(ruling.oracleId);
    if (latest == null || ruling.publishedAt.compareTo(latest) > 0) {
      latest = ruling.publishedAt;
    }
  }
  return RulingsSnapshotSummary(
    rowCount: rulings.length,
    distinctOracleIds: oracleIds.length,
    latestPublishedAt: latest,
  );
}

void validateRulingsSnapshot(
  RulingsSnapshotSummary snapshot, {
  int minimumRows = minimumExpectedRulingCount,
  int minimumOracleIds = minimumExpectedOracleIdCount,
}) {
  if (snapshot.rowCount < minimumRows) {
    throw StateError(
      'Snapshot incompleto: ${snapshot.rowCount} rulings; minimo=$minimumRows.',
    );
  }
  if (snapshot.distinctOracleIds < minimumOracleIds) {
    throw StateError(
      'Snapshot incompleto: ${snapshot.distinctOracleIds} Oracle IDs; '
      'minimo=$minimumOracleIds.',
    );
  }
  if (snapshot.latestPublishedAt == null) {
    throw StateError('Snapshot sem published_at valido.');
  }
}

Future<void> reconcileRulingsSnapshot(
  Pool pool,
  List<RulingRecord> rulings, {
  required BulkSnapshotMetadata metadata,
  required String contentHash,
  required RulingsSnapshotSummary summary,
}) async {
  await pool.runTx((tx) async {
    await tx.execute('''
      CREATE TEMP TABLE incoming_card_rulings (
        oracle_id TEXT NOT NULL,
        upstream_source TEXT NOT NULL,
        published_at DATE NOT NULL,
        comment TEXT NOT NULL,
        comment_hash TEXT NOT NULL,
        PRIMARY KEY (oracle_id, comment_hash)
      ) ON COMMIT DROP
    ''');

    const batchSize = 500;
    for (var start = 0; start < rulings.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, rulings.length);
      final batch = rulings.sublist(start, end);
      final rows = <String>[];
      final parameters = <String, dynamic>{};
      for (var i = 0; i < batch.length; i++) {
        final ruling = batch[i];
        rows.add('(@o$i, @s$i, @d$i::date, @c$i, @h$i)');
        parameters['o$i'] = ruling.oracleId;
        parameters['s$i'] = ruling.upstreamSource;
        parameters['d$i'] = ruling.publishedAt;
        parameters['c$i'] = ruling.comment;
        parameters['h$i'] = ruling.commentHash;
      }
      await tx.execute(
        Sql.named('''
          INSERT INTO incoming_card_rulings (
            oracle_id, upstream_source, published_at, comment, comment_hash
          ) VALUES ${rows.join(', ')}
        '''),
        parameters: parameters,
      );
    }

    final stagedResult = await tx.execute(
      'SELECT count(*)::int FROM incoming_card_rulings',
    );
    final stagedCount = stagedResult.first[0] as int? ?? 0;
    if (stagedCount != summary.rowCount) {
      throw StateError(
        'Staging divergente: esperado=${summary.rowCount}, obtido=$stagedCount.',
      );
    }

    // Somente fontes gerenciadas por este pipeline sao substituidas. O DELETE
    // ocorre na mesma transacao que staging, insert e lineage.
    await tx.execute(
      "DELETE FROM card_rulings WHERE source IN ('mtgjson', 'scryfall')",
    );
    await tx.execute('''
      INSERT INTO card_rulings (
        oracle_id, source, ruling_source, published_at, comment, comment_hash,
        created_at
      )
      SELECT oracle_id, 'scryfall', upstream_source, published_at, comment,
             comment_hash, NOW()
      FROM incoming_card_rulings
      ON CONFLICT (oracle_id, comment_hash) DO UPDATE SET
        source = EXCLUDED.source,
        ruling_source = EXCLUDED.ruling_source,
        published_at = EXCLUDED.published_at,
        comment = EXCLUDED.comment
    ''');

    await tx.execute(
      Sql.named('''
        INSERT INTO data_source_snapshots (
          dataset, provider, source_uri, source_version, source_updated_at,
          source_etag, content_sha256, row_count, distinct_identity_count,
          latest_published_at, status, metadata, completed_at
        ) VALUES (
          'card_rulings', 'scryfall', @uri, @version, @updated::timestamptz,
          @etag, @hash, @rows, @identities, @latest::date, 'succeeded',
          @metadata::jsonb, NOW()
        )
        ON CONFLICT (dataset, provider, content_sha256) DO UPDATE SET
          source_uri = EXCLUDED.source_uri,
          source_version = EXCLUDED.source_version,
          source_updated_at = EXCLUDED.source_updated_at,
          source_etag = EXCLUDED.source_etag,
          row_count = EXCLUDED.row_count,
          distinct_identity_count = EXCLUDED.distinct_identity_count,
          latest_published_at = EXCLUDED.latest_published_at,
          status = EXCLUDED.status,
          metadata = EXCLUDED.metadata,
          completed_at = EXCLUDED.completed_at
      '''),
      parameters: {
        'uri': metadata.downloadUri,
        'version': metadata.version,
        'updated': metadata.updatedAt,
        'etag': metadata.etag,
        'hash': contentHash,
        'rows': summary.rowCount,
        'identities': summary.distinctOracleIds,
        'latest': summary.latestPublishedAt,
        'metadata': jsonEncode(metadata.raw),
      },
    );
  });
}

Future<void> _ensureRequiredTables(Pool pool) async {
  final result = await pool.execute('''
    SELECT
      to_regclass('public.card_rulings') IS NOT NULL AS rulings_ok,
      to_regclass('public.data_source_snapshots') IS NOT NULL AS snapshots_ok,
      EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'card_rulings'
          AND column_name = 'ruling_source'
      ) AS ruling_source_ok
  ''');
  final row = result.first.toColumnMap();
  if (row['rulings_ok'] != true ||
      row['snapshots_ok'] != true ||
      row['ruling_source_ok'] != true) {
    throw StateError(
      'Schema incompleto. Rode migrate.dart apos aprovacao explicita; '
      'card_rulings=${row['rulings_ok']}, '
      'data_source_snapshots=${row['snapshots_ok']}, '
      'ruling_source=${row['ruling_source_ok']}.',
    );
  }
}

Future<_SnapshotInput> _localInput(File file) async {
  if (!file.existsSync()) {
    throw ArgumentError('Arquivo local inexistente: ${file.path}');
  }
  final modifiedAt = (await file.stat()).modified.toUtc().toIso8601String();
  return _SnapshotInput(
    file: file,
    metadata: BulkSnapshotMetadata(
      downloadUri: file.absolute.path,
      updatedAt: modifiedAt,
      version: 'local-file',
      etag: '',
      raw: {'kind': 'local_file', 'path': file.absolute.path},
    ),
  );
}

Future<_SnapshotInput> _downloadCurrentSnapshot(
  File target, {
  required bool force,
}) async {
  final metadata = await _fetchBulkMetadata();
  final sidecar = File('${target.path}.metadata.json');
  if (!force && target.existsSync() && sidecar.existsSync()) {
    try {
      final cached = jsonDecode(await sidecar.readAsString());
      if (cached is Map && cached['updated_at'] == metadata.updatedAt) {
        print('Usando cache verificado: ${target.path}');
        return _SnapshotInput(file: target, metadata: metadata);
      }
    } on Object {
      // Sidecar invalido: baixa novamente e o substitui atomicamente.
    }
  }

  final temporary = File('${target.path}.partial');
  if (temporary.existsSync()) await temporary.delete();
  print('Baixando ${metadata.downloadUri}');
  final client = http.Client();
  try {
    final request = http.Request('GET', Uri.parse(metadata.downloadUri));
    request.headers['User-Agent'] = 'ManaLoom/1.0 (rulings-sync)';
    request.headers['Accept'] = 'application/json';
    final response = await client
        .send(request)
        .timeout(const Duration(minutes: 5));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Download falhou: HTTP ${response.statusCode}');
    }
    final sink = temporary.openWrite();
    try {
      await response.stream.pipe(sink);
    } finally {
      await sink.close();
    }
  } finally {
    client.close();
  }

  if (target.existsSync()) await target.delete();
  await temporary.rename(target.path);
  await sidecar.writeAsString(jsonEncode(metadata.raw), flush: true);
  return _SnapshotInput(file: target, metadata: metadata);
}

Future<BulkSnapshotMetadata> _fetchBulkMetadata() async {
  final client = http.Client();
  try {
    final response = await client
        .get(
          Uri.parse(scryfallBulkMetadataUrl),
          headers: {
            'User-Agent': 'ManaLoom/1.0 (rulings-sync)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('Metadata falhou: HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['data'] is! List) {
      throw const FormatException('Metadata bulk Scryfall invalido.');
    }
    final entries = decoded['data'] as List;
    final raw = entries.cast<Object?>().firstWhere(
      (entry) => entry is Map && entry['type'] == 'rulings',
      orElse:
          () =>
              throw const FormatException(
                'Dataset rulings ausente no metadata Scryfall.',
              ),
    );
    final map = Map<String, dynamic>.from(raw as Map);
    final downloadUri = map['download_uri']?.toString() ?? '';
    final updatedAt = map['updated_at']?.toString() ?? '';
    if (downloadUri.isEmpty || DateTime.tryParse(updatedAt) == null) {
      throw const FormatException('Metadata rulings sem URI/data validas.');
    }
    return BulkSnapshotMetadata(
      downloadUri: downloadUri,
      updatedAt: updatedAt,
      version: updatedAt,
      etag: response.headers['etag'] ?? '',
      raw: map,
    );
  } finally {
    client.close();
  }
}

Future<String> _sha256File(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

class RulingRecord {
  final String oracleId;
  final String upstreamSource;
  final String publishedAt;
  final String comment;
  final String commentHash;

  const RulingRecord({
    required this.oracleId,
    required this.upstreamSource,
    required this.publishedAt,
    required this.comment,
    required this.commentHash,
  });
}

class RulingsSnapshotSummary {
  final int rowCount;
  final int distinctOracleIds;
  final String? latestPublishedAt;

  const RulingsSnapshotSummary({
    required this.rowCount,
    required this.distinctOracleIds,
    required this.latestPublishedAt,
  });
}

class BulkSnapshotMetadata {
  final String downloadUri;
  final String updatedAt;
  final String version;
  final String etag;
  final Map<String, dynamic> raw;

  const BulkSnapshotMetadata({
    required this.downloadUri,
    required this.updatedAt,
    required this.version,
    required this.etag,
    required this.raw,
  });
}

class _SnapshotInput {
  final File file;
  final BulkSnapshotMetadata metadata;

  const _SnapshotInput({required this.file, required this.metadata});
}
