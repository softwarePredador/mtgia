import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:test/test.dart';

import '../lib/legal_acceptance_middleware.dart';
import '../lib/openai_runtime_config.dart';
import '../lib/release_capability_policy.dart';
import '../routes/ai/_middleware.dart' as ai_middleware;

/// BT-AI-029: registry de todas as rotas de IA
/// (`server/config/ai_route_registry.json`).
///
/// Rota de IA é toda rota sob `/ai`, toda rota que a política de capability
/// põe numa capability de IA (a lista `ai_capabilities` do registry) e toda
/// rota cujo handler fala com o provedor direto. Rota nova assim, fora do
/// registry, faz o primeiro teste falhar até alguém registrar consumidor,
/// escritas, capability, dono e substituto. As quatro rotas que a D-31
/// removeu e a que a D-83 removeu pela mesma regra não podem voltar.
void main() {
  final registry =
      jsonDecode(File('config/ai_route_registry.json').readAsStringSync())
          as Map<String, dynamic>;
  final entries = (registry['routes'] as List).cast<Map<String, dynamic>>();
  final removed =
      (registry['removed_routes'] as List).cast<Map<String, dynamic>>();
  final providers = (registry['providers'] as Map).cast<String, dynamic>();
  final aiCapabilities =
      (registry['ai_capabilities'] as List).cast<String>().toSet();
  final vocabulary = registry['vocabulary'] as Map<String, dynamic>;
  final statuses = (vocabulary['status'] as List).cast<String>().toSet();
  final lanes = (vocabulary['lane'] as List).cast<String>().toSet();
  final providerMarkers =
      (registry['provider_markers'] as List).cast<String>().toList();
  final backlog =
      File(
        '../docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md',
      ).readAsStringSync();

  String key(Map<String, dynamic> entry) =>
      '${entry['method']} ${entry['path']}';

  group('registry de rotas de IA (BT-AI-029)', () {
    test('toda rota de IA do servidor está no registry, e só elas', () {
      final discovered = <String>{};
      for (final handler in _routeHandlers()) {
        final source = handler.readAsStringSync();
        final path = _routePattern(handler.path);
        for (final method in _declaredMethods(source)) {
          if (_isAiRoute(
            path: path,
            method: method,
            source: source,
            aiCapabilities: aiCapabilities,
            providerMarkers: providerMarkers,
          )) {
            discovered.add('$method $path');
          }
        }
      }

      final registered = entries.map(key).toSet();
      expect(
        registered.length,
        entries.length,
        reason: 'uma entrada por método e caminho',
      );
      expect(
        discovered.difference(registered),
        isEmpty,
        reason:
            'rota de IA fora do registry: registre consumidor, escritas, '
            'capability, dono e substituto em config/ai_route_registry.json',
      );
      expect(
        registered.difference(discovered),
        isEmpty,
        reason: 'entrada do registry sem rota de IA no servidor',
      );
    });

    test('cada entrada diz consumidor, escritas, capability, dono e '
        'substituto, e bate com o código', () {
      for (final entry in entries) {
        final id = key(entry);
        final method = entry['method'] as String;
        final path = entry['path'] as String;
        final samplePath = _samplePath(path);
        final handler = File('../${entry['handler']}');
        expect(handler.existsSync(), isTrue, reason: '$id: handler');
        final source = handler.readAsStringSync();
        expect(
          _declaredMethods(source),
          contains(method),
          reason: '$id: o handler declara o método',
        );
        expect(
          _routePattern(handler.path),
          path,
          reason: '$id: o caminho sai do arquivo do handler',
        );

        expect(statuses, contains(entry['status']), reason: '$id: status');
        expect(
          entry['capability'],
          requiredCapabilityForRequest(path: samplePath, method: method),
          reason: '$id: capability igual à da política',
        );

        final owner = entry['owner'] as String;
        expect(
          backlog,
          contains('| `$owner` |'),
          reason: '$id: o dono é uma tarefa do backlog',
        );

        final consumers = (entry['consumers'] as List).cast<Map>();
        if (consumers.isEmpty) {
          expect(
            _text(entry['consumer_note']),
            isNotEmpty,
            reason: '$id: rota sem consumidor diz por quê',
          );
        }
        for (final consumer in consumers) {
          final file = File('../${consumer['file']}');
          expect(file.existsSync(), isTrue, reason: '$id: ${consumer['file']}');
          expect(
            file.readAsStringSync(),
            contains(consumer['needle'] as String),
            reason: '$id: ${consumer['file']} chama a rota',
          );
        }

        final writes = (entry['writes'] as List).cast<String>();
        if (_hasDirectWrite(source)) {
          expect(writes, isNotEmpty, reason: '$id: o handler grava');
        }
        for (final table in writes) {
          expect(
            table,
            matches(RegExp(r'^[a-z_][a-z0-9_]*(\.[a-z_][a-z0-9_]*)?$')),
            reason: '$id: tabela',
          );
        }

        final used = (entry['external_providers'] as List).cast<String>();
        for (final provider in used) {
          expect(providers, contains(provider), reason: '$id: provedor');
        }
        if (providerMarkers.any(source.contains)) {
          expect(
            used,
            contains('openai_chat_completions'),
            reason: '$id: o handler fala com o provedor de IA',
          );
        }
        if (used.isNotEmpty) {
          expect(
            _text(entry['without_provider']),
            isNotEmpty,
            reason: '$id: o que acontece sem o provedor',
          );
        }
        expect(lanes, contains(entry['lane']), reason: '$id: raia');

        if (entry['status'] == 'legacy_off') {
          expect(
            _text(entry['substitute']),
            isNotEmpty,
            reason: '$id: rota legada tem substituto',
          );
          expect(
            _text(entry['rule_verdict']),
            isNotEmpty,
            reason: '$id: rota legada tem o veredito da regra da D-31',
          );
        }

        if (path.startsWith('/ai/')) {
          expect(
            entry['access_policy'],
            ai_middleware.aiEndpointAccessPolicyForPath(samplePath).name,
            reason: '$id: política de acesso de /ai',
          );
        }
        expect(
          entry['legal_reacceptance'],
          _legalGated(method, samplePath),
          reason: '$id: trava do reaceite (D-24)',
        );
      }
    });

    test('cada provedor diz a URL, se ela é configurável e o que acontece '
        'sem ele', () {
      for (final MapEntry(key: name, value: raw) in providers.entries) {
        final provider = raw as Map;
        expect(_text(provider['url']), isNotEmpty, reason: name);
        expect(provider['url_configurable'], isA<bool>(), reason: name);
        expect(_text(provider['without_key']), isNotEmpty, reason: name);
      }
    });

    test('toda chamada ao provedor externo está registrada', () {
      final openAi = providers['openai_chat_completions'] as Map;
      final declared = (openAi['callsites'] as List).cast<String>().toSet();
      final url = openAi['url'] as String;
      final marker = openAi['callsite_marker'] as String;
      final urlSource = openAi['url_source'] as String;
      final occurrences = (openAi['callsite_occurrences'] as Map).map(
        (file, count) => MapEntry(file as String, count as int),
      );
      final found = <String, int>{};
      final withHost = <String>{};
      final readsBaseUrl = <String>{};
      for (final root in ['lib', 'routes']) {
        for (final file in Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
          final source = file.readAsStringSync();
          final path = 'server/${file.path.replaceAll(r'\', '/')}';
          if (source.contains(Uri.parse(url).host)) withHost.add(path);
          if (source.contains('OPENAI_BASE_URL')) readsBaseUrl.add(path);
          if (path == urlSource) continue;
          final count = marker.allMatches(source).length;
          if (count > 0) found[path] = count;
        }
      }
      expect(found.keys.toSet(), declared, reason: 'chamada nova ao provedor');
      // Cada ponto conta: um ponto novo num arquivo já registrado também
      // falha (a sessão do gate achou quatro em server/lib).
      expect(found, occurrences, reason: 'ponto novo de chamada ao provedor');
      // D-83: a URL mora num lugar só, e só ele lê OPENAI_BASE_URL.
      expect(withHost, {urlSource}, reason: 'URL fixa fora do config');
      if (openAi['url_configurable'] == true) {
        expect(readsBaseUrl, {urlSource}, reason: 'quem lê OPENAI_BASE_URL');
        expect(openAi['url_env'], 'OPENAI_BASE_URL');
        expect(_text(openAi['url_rule']), isNotEmpty);
      } else {
        expect(readsBaseUrl, isEmpty, reason: 'quem lê OPENAI_BASE_URL');
      }
      // A URL registrada é a que a produção usa, mesmo com a variável.
      final production = OpenAiRuntimeConfig(
        DotEnv()..addAll({
          'ENVIRONMENT': 'production',
          'OPENAI_BASE_URL': 'http://127.0.0.1:9/v1',
        }),
      );
      expect(production.chatCompletionsUri.toString(), url);
    });

    test('as chamadas ao provedor de uma rota apontam para um ponto '
        'registrado e dizem o que é tentado sem chave', () {
      final openAi = providers['openai_chat_completions'] as Map;
      final callsites = (openAi['callsites'] as List).cast<String>().toSet();
      // O POST /ai/optimize tenta o provedor em mais de um ponto, e o Critic
      // IA tenta depois do caminho determinístico (achado da sessão do gate).
      final optimize = entries.singleWhere(
        (entry) => key(entry) == 'POST /ai/optimize',
      );
      expect(
        (optimize['provider_calls'] as List).cast<Map>().map(
          (call) => call['ai_logs_endpoint'],
        ),
        containsAll([
          'provider:optimize',
          'optimization_critic',
          'provider:complete',
        ]),
      );
      for (final entry in entries.where(
        (entry) => entry['provider_calls'] != null,
      )) {
        final id = key(entry);
        expect(
          entry['external_providers'] as List,
          contains('openai_chat_completions'),
          reason: id,
        );
        for (final call in (entry['provider_calls'] as List).cast<Map>()) {
          final name = '$id: ${call['name']}';
          expect(callsites, contains(call['callsite']), reason: name);
          expect(
            File('../${call['callsite']}').readAsStringSync(),
            contains("endpoint: '${call['ai_logs_endpoint']}'"),
            reason: '$name: o ponto grava a chamada em ai_logs',
          );
          expect(_text(call['when']), isNotEmpty, reason: name);
          expect(_text(call['on_failure']), isNotEmpty, reason: name);
        }
        expect(
          _text(entry['provider_calls_without_key']),
          isNotEmpty,
          reason: '$id: o que é tentado sem chave',
        );
      }
    });

    test('as rotas removidas pela regra da D-31 não voltam', () {
      // As quatro da D-31 e o GET /ai/optimize/telemetry, que a D-83 removeu
      // pela mesma regra (sem consumidor e com substituto).
      expect(removed, hasLength(5));
      expect(
        removed.where((entry) => entry['decision'] == 'D-83').map(key),
        ['GET /ai/optimize/telemetry'],
      );
      final live = entries.map(key).toSet();
      for (final entry in removed) {
        final id = key(entry);
        final path = entry['path'] as String;
        expect(entry['decision'], anyOf('D-31', 'D-83'), reason: id);
        expect(_text(entry['substitute']), isNotEmpty, reason: id);
        expect(_text(entry['after_removal']), isNotEmpty, reason: id);
        expect(live, isNot(contains(id)), reason: id);
        expect(
          File('../${entry['handler']}').existsSync(),
          isFalse,
          reason: '$id: o handler saiu',
        );
        if (path.startsWith('/ai/')) {
          // Quem ainda chamar cai em rota não classificada (404).
          expect(
            requiredCapabilityForRequest(
              path: _samplePath(path),
              method: entry['method'] as String,
            ),
            isNull,
            reason: id,
          );
        }
      }
    });
  });
}

Iterable<File> _routeHandlers() => Directory('routes')
    .listSync(recursive: true)
    .whereType<File>()
    .where(
      (file) =>
          file.path.endsWith('.dart') &&
          !file.path.endsWith('_middleware.dart'),
    );

/// Caminho da rota com os parâmetros como `:nome` (o registry usa essa
/// forma; `[id].dart` vira `:id`).
String _routePattern(String filePath) {
  var relative = filePath.replaceAll(r'\', '/');
  relative = relative.substring(relative.indexOf('routes/') + 'routes'.length);
  if (relative.endsWith('/index.dart')) {
    relative = relative.substring(0, relative.length - '/index.dart'.length);
  } else {
    relative = relative.substring(0, relative.length - '.dart'.length);
  }
  relative = relative.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]'),
    (match) => ':${match.group(1)}',
  );
  return relative.isEmpty ? '/' : relative;
}

String _samplePath(String pattern) =>
    pattern.replaceAll(RegExp(r':[A-Za-z]+'), 'sample');

Set<String> _declaredMethods(String source) =>
    RegExp(
      r'HttpMethod\.(get|post|put|patch|delete)',
    ).allMatches(source).map((match) => match.group(1)!.toUpperCase()).toSet();

bool _isAiRoute({
  required String path,
  required String method,
  required String source,
  required Set<String> aiCapabilities,
  required List<String> providerMarkers,
}) {
  if (path == '/ai' || path.startsWith('/ai/')) return true;
  final capability = requiredCapabilityForRequest(
    path: _samplePath(path),
    method: method,
  );
  if (capability != null && aiCapabilities.contains(capability)) return true;
  return providerMarkers.any(source.contains);
}

bool _hasDirectWrite(String source) => RegExp(
  r'\b(INSERT\s+INTO|UPDATE\s+[a-z_]+\s+SET|DELETE\s+FROM)\b',
  caseSensitive: false,
).hasMatch(source);

bool _legalGated(String method, String samplePath) {
  final request = Request(method, Uri.parse('http://localhost$samplePath'));
  return isLegalGatedAiRequest(request) ||
      isLegalGatedDeckRequest(request) ||
      isLegalGatedImportRequest(request) ||
      isLegalGatedBinderRequest(request);
}

String _text(Object? value) => value is String ? value.trim() : '';
