import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _defaultBaseUrl = 'https://evolution-cartinhas.2ta7qx.easypanel.host';
const _defaultCommander = 'Lorehold, the Historian';
const _defaultPrompt =
    'Boros miracle big spells with topdeck setup and interaction';
const _defaultArtifactDir =
    'test/artifacts/lorehold_public_generator_parity_2026-06-16';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('''
Uso:
  dart run bin/lorehold_public_generator_parity_audit.dart \\
    [--base-url=https://evolution-cartinhas.2ta7qx.easypanel.host] \\
    [--commander=Lorehold, the Historian] \\
    [--prompt=Boros miracle big spells with topdeck setup and interaction] \\
    [--artifact-dir=test/artifacts/lorehold_public_generator_parity_2026-06-16]
''');
    return;
  }

  final baseUrl = _readArg(args, '--base-url=') ?? _defaultBaseUrl;
  final commander = _readArg(args, '--commander=') ?? _defaultCommander;
  final prompt = _readArg(args, '--prompt=') ?? _defaultPrompt;
  final artifactDir =
      Directory(_readArg(args, '--artifact-dir=') ?? _defaultArtifactDir);
  await artifactDir.create(recursive: true);

  final startedAt = DateTime.now().toUtc();
  final health = await _getJson(Uri.parse('$baseUrl/health'));
  final token = await _registerProbeUser(baseUrl);

  final generate = await _postJson(
    Uri.parse('$baseUrl/ai/generate'),
    token: token,
    body: {
      'prompt': prompt,
      'format': 'Commander',
      'commander_name': commander,
    },
  );

  final learning = await _getAuthedJson(
    Uri.parse(
      '$baseUrl/ai/commander-learning?commander=${Uri.encodeQueryComponent(commander)}',
    ),
    token: token,
  );

  final reference = await _getAuthedJson(
    Uri.parse(
      '$baseUrl/ai/commander-reference?commander=${Uri.encodeQueryComponent(commander)}&learning=1&include_deck=1',
    ),
    token: token,
  );

  final diagnostics =
      (generate['body']['diagnostics'] as Map?)?.cast<String, dynamic>();
  final learningBody = generateMap(learning['body']);
  final referenceBody = generateMap(reference['body']);

  final summary = <String, dynamic>{
    'status': 'PASS_WITH_RISKS',
    'started_at': startedAt.toIso8601String(),
    'finished_at': DateTime.now().toUtc().toIso8601String(),
    'base_url': baseUrl,
    'health': health,
    'commander': commander,
    'prompt': prompt,
    'generate': {
      'status_code': generate['status_code'],
      'is_mock': generate['body']['is_mock'],
      'generation_mode': generate['body']['generation_mode'],
      'warning_code': generateMap(generate['body']['warnings'])['code'],
      'cache_hit': generateMap(generate['body']['cache'])['hit'],
      'reference_profile_used': diagnostics?['reference_profile_used'],
      'reference_card_stats_used': diagnostics?['reference_card_stats_used'],
      'runtime_profile_origin': diagnostics?['runtime_profile_origin'],
      'archetype_reference_used': diagnostics?['archetype_reference_used'],
      'archetype_candidate_count': diagnostics?['archetype_candidate_count'],
      'archetype_source_commanders':
          diagnostics?['archetype_source_commanders'],
      'generated_commander':
          generateMap(generate['body']['generated_deck'])['commander'] is Map
              ? (generateMap(
                  generateMap(generate['body']['generated_deck'])['commander'],
                ))['name']
              : null,
      'generated_cards_preview':
          (generateMap(generate['body']['generated_deck'])['cards'] as List?)
              ?.take(5)
              .toList(),
    },
    'commander_learning': {
      'status_code': learning['status_code'],
      'source': learningBody['source'],
      'profile_present': learningBody['profile'] != null,
      'card_stats_present': learningBody['card_stats'] != null,
      'deck_corpus_present': learningBody['deck_corpus'] != null,
      'readiness_present': learningBody['readiness'] != null,
      'promoted_deck_present': learningBody['promoted_deck'] != null,
      'recommended_deck_source':
          generateMap(learningBody['recommended_deck'])['source'],
    },
    'commander_reference': {
      'status_code': reference['status_code'],
      'model_type': generateMap(referenceBody['model'])['type'],
      'model_source': generateMap(referenceBody['model'])['source'],
      'meta_decks_found': referenceBody['meta_decks_found'],
      'commander_profile_present': referenceBody['commander_profile'] != null,
      'commander_learning_present': referenceBody['commander_learning'] != null,
      'reference_cards_count':
          (referenceBody['reference_cards'] as List?)?.length ?? 0,
    },
  };

  final reportFile = File('${artifactDir.path}/summary.json');
  await reportFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(summary),
  );

  stdout.writeln(jsonEncode({
    'status': summary['status'],
    'artifact': reportFile.path,
    'generate_reference_profile_used': summary['generate']
        ['reference_profile_used'],
    'learning_profile_present': summary['commander_learning']
        ['profile_present'],
    'reference_model_source': summary['commander_reference']['model_source'],
  }));
}

String? _readArg(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      final value = arg.substring(prefix.length).trim();
      if (value.isNotEmpty) return value;
    }
  }
  return null;
}

Future<String> _registerProbeUser(String baseUrl) async {
  final suffix = DateTime.now().millisecondsSinceEpoch;
  final response = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': 'lorehold_public_audit_$suffix',
      'email': 'lorehold_public_audit_$suffix@example.invalid',
      'password': 'TestPassword123!',
    }),
  );
  final body = _decodeJson(response.body);
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw StateError(
      'Falha ao registrar usuario probe: ${response.statusCode} ${response.body}',
    );
  }
  final token = body['token']?.toString();
  if (token == null || token.isEmpty) {
    throw StateError('Token ausente no register probe.');
  }
  return token;
}

Future<Map<String, dynamic>> _getJson(Uri uri) async {
  final response = await http.get(uri);
  return _decodeJson(response.body);
}

Future<Map<String, dynamic>> _getAuthedJson(
  Uri uri, {
  required String token,
}) async {
  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );
  return {
    'status_code': response.statusCode,
    'body': _decodeJson(response.body),
  };
}

Future<Map<String, dynamic>> _postJson(
  Uri uri, {
  required String token,
  required Map<String, dynamic> body,
}) async {
  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );
  return {
    'status_code': response.statusCode,
    'body': _decodeJson(response.body),
  };
}

Map<String, dynamic> _decodeJson(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(trimmed);
  return generateMap(decoded);
}

Map<String, dynamic> generateMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}
