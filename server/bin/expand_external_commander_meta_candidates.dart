import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../lib/meta/external_commander_deck_expansion_support.dart';

const _defaultSourceUrl =
    'https://edhtop16.com/tournament/cedh-arcanum-sanctorum-57';
const _defaultOutputPath =
    'test/artifacts/topdeck_edhtop16_expansion_dry_run_latest.json';

Future<void> main(List<String> args) async {
  final config = _ExpandConfig.parse(args);

  stdout.writeln('Expansion dry-run: ${config.sourceUrl}');
  stdout.writeln('Limit: ${config.limit}');
  stdout.writeln('Output: ${config.outputPath}');

  final tournamentId = edhTop16TournamentIdFromUrl(config.sourceUrl);
  final graphqlPayload = await _fetchEdhTop16Tournament(
    tournamentId: tournamentId,
    limit: config.limit,
  );
  final entries = parseEdhTop16TournamentEntries(graphqlPayload);

  final results = <Map<String, dynamic>>[];
  for (final entry in entries.take(config.limit)) {
    results.add(await _expandEntry(
      tournamentUrl: config.sourceUrl,
      tournamentId: tournamentId,
      entry: entry,
    ));
  }

  final expandedCount = results
      .where((result) => result['expansion_status'] == 'expanded')
      .length;
  final rejectedCount = results.length - expandedCount;
  final candidates = results
      .where((result) => result['expansion_status'] == 'expanded')
      .map((result) => result['candidate'])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final payload = <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'mode': 'dry_run',
    'source_name': 'EDHTop16',
    'source_url': config.sourceUrl,
    'event_tid': tournamentId,
    'expansion_path': <String>['edhtop16_graphql', 'topdeck_deck_page'],
    'expanded_count': expandedCount,
    'rejected_count': rejectedCount,
    'candidates': candidates,
    'results': results,
  };

  final outputFile = File(config.outputPath);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );

  for (final result in results) {
    final status = result['expansion_status'];
    final deckUrl = result['deck_url'];
    final totalCards = result['total_cards'];
    final reason = result['rejection_reason'];
    stdout.writeln(
      status == 'expanded'
          ? '[EXPANDED] total=$totalCards | $deckUrl'
          : '[REJECTED] ${reason ?? 'unknown'} | $deckUrl',
    );
  }
  stdout.writeln(
    'Expansion dry-run finalizado: expanded=$expandedCount rejected=$rejectedCount',
  );
}

Future<Map<String, dynamic>> _fetchEdhTop16Tournament({
  required String tournamentId,
  required int limit,
}) async {
  const query = r'''
query($tid: String!, $maxStanding: Int!) {
  tournament(TID: $tid) {
    TID
    name
    size
    entries(maxStanding: $maxStanding) {
      standing
      decklist
      player { name }
      commander { name }
    }
  }
}
''';

  final response = await http
      .post(
        Uri.parse('https://edhtop16.com/api/graphql'),
        headers: const <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'query': query,
          'variables': <String, dynamic>{
            'tid': tournamentId,
            'maxStanding': limit,
          },
        }),
      )
      .timeout(const Duration(seconds: 25));

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError(
      'EDHTop16 GraphQL falhou: HTTP ${response.statusCode} ${response.body.substring(0, response.body.length.clamp(0, 200))}',
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Resposta GraphQL nao e objeto JSON.');
  }
  if (decoded['errors'] != null) {
    throw StateError('EDHTop16 GraphQL retornou errors: ${decoded['errors']}');
  }
  return decoded;
}

Future<Map<String, dynamic>> _expandEntry({
  required String tournamentUrl,
  required String tournamentId,
  required EdhTop16TournamentEntry entry,
}) async {
  final deckUri = Uri.tryParse(entry.decklistUrl);
  if (deckUri == null ||
      deckUri.host.toLowerCase().replaceFirst('www.', '') != 'topdeck.gg' ||
      !deckUri.path.startsWith('/deck/')) {
    return _rejectedEntry(entry, 'decklist_not_topdeck_deck_page');
  }

  try {
    final response = await http.get(deckUri, headers: const <String, String>{
      'Accept': 'text/html'
    }).timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _rejectedEntry(entry, 'topdeck_http_${response.statusCode}');
    }

    final expandedDeck = parseTopDeckDeckObjectFromHtml(response.body);
    if (expandedDeck.commanderCount <= 0) {
      return _rejectedEntry(entry, 'missing_commanders');
    }
    if (expandedDeck.totalCards != 100) {
      return _rejectedEntry(
          entry, 'invalid_total_cards_${expandedDeck.totalCards}');
    }

    return <String, dynamic>{
      'expansion_status': 'expanded',
      'source_name': 'EDHTop16',
      'source_url': tournamentUrl,
      'event_tid': tournamentId,
      'standing': entry.standing,
      'player_name': entry.playerName,
      'deck_url': entry.decklistUrl,
      'commanders': expandedDeck.commanderNames,
      'mainboard_count': expandedDeck.mainboardCount,
      'commander_count': expandedDeck.commanderCount,
      'total_cards': expandedDeck.totalCards,
      'card_list': expandedDeck.cardList,
      'candidate': buildExternalCommanderCandidateFromExpansion(
        tournamentUrl: tournamentUrl,
        tournamentId: tournamentId,
        entry: entry,
        expandedDeck: expandedDeck,
      ),
    };
  } on FormatException catch (error) {
    final message = error.message.toLowerCase();
    if (message.contains('deckobj')) {
      return _rejectedEntry(entry, 'topdeck_deckobj_missing');
    }
    return _rejectedEntry(entry, 'topdeck_parse_error');
  } catch (error) {
    return _rejectedEntry(entry, 'exception_${error.runtimeType}');
  }
}

Map<String, dynamic> _rejectedEntry(
  EdhTop16TournamentEntry entry,
  String reason,
) {
  return <String, dynamic>{
    'expansion_status': 'rejected',
    'rejection_reason': reason,
    'standing': entry.standing,
    'player_name': entry.playerName,
    'deck_url': entry.decklistUrl,
  };
}

class _ExpandConfig {
  const _ExpandConfig({
    required this.sourceUrl,
    required this.limit,
    required this.outputPath,
  });

  final String sourceUrl;
  final int limit;
  final String outputPath;

  factory _ExpandConfig.parse(List<String> args) {
    var sourceUrl = _defaultSourceUrl;
    var limit = 4;
    var outputPath = _defaultOutputPath;

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        stdout.writeln('''
Usage:
  dart run bin/expand_external_commander_meta_candidates.dart [options]

Options:
  --source-url=<url>  EDHTop16 tournament URL. Default: $_defaultSourceUrl
  --limit=<n>         Max standings/decks to expand. Default: 4
  --output=<path>     Artifact JSON path. Default: $_defaultOutputPath

This script is dry-run only. It never writes to the database.
''');
        exit(0);
      }
      if (arg.startsWith('--source-url=')) {
        sourceUrl = arg.substring('--source-url='.length).trim();
        continue;
      }
      if (arg.startsWith('--limit=')) {
        limit = int.tryParse(arg.substring('--limit='.length).trim()) ?? limit;
        continue;
      }
      if (arg.startsWith('--output=')) {
        outputPath = arg.substring('--output='.length).trim();
        continue;
      }
    }

    if (limit <= 0) {
      throw ArgumentError('--limit precisa ser maior que zero.');
    }

    return _ExpandConfig(
      sourceUrl: sourceUrl,
      limit: limit,
      outputPath: outputPath,
    );
  }
}
