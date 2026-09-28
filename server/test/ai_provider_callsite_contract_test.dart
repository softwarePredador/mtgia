import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('the provider URL lives only in OpenAiRuntimeConfig (D-83)', () {
    final withUrl = <String>[];
    for (final root in [Directory('lib'), Directory('routes')]) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.readAsStringSync().contains('api.openai.com')) {
          withUrl.add(entity.path.replaceAll(r'\', '/'));
        }
      }
    }
    expect(withUrl, ['lib/openai_runtime_config.dart']);
  });

  test('every direct OpenAI call is bounded and identifies users safely', () {
    // Toda chamada ao provedor usa o endpoint do OpenAiRuntimeConfig.
    final callsites = <File>[];
    for (final root in [Directory('lib'), Directory('routes')]) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('openai_runtime_config.dart')) continue;
        final source = entity.readAsStringSync();
        if (source.contains('chatCompletionsUri')) callsites.add(entity);
      }
    }

    expect(callsites, hasLength(7));
    for (final file in callsites) {
      final source = file.readAsStringSync();
      expect(
        source,
        contains('.timeout('),
        reason: '${file.path} must bound provider latency',
      );
      expect(
        source,
        contains('aiSafetyIdentifierPayload('),
        reason: '${file.path} must send a hashed safety identifier',
      );
      expect(
        source,
        contains('openAiTokenLimitPayload('),
        reason: '${file.path} must bound provider output tokens',
      );
      expect(
        source,
        isNot(contains("'safety_identifier': userId")),
        reason: '${file.path} must not send raw user identifiers',
      );
      if (source.contains("'response_format':")) {
        expect(
          source,
          contains('openAiStructuredResponseFormat('),
          reason: '${file.path} must enforce structured provider output',
        );
      }
      if (!file.path.endsWith('commander_ai_live_eval_support.dart')) {
        expect(
          source,
          anyOf(
            contains('recordAiProviderCall('),
            contains("endpoint: 'provider:"),
          ),
          reason: '${file.path} must record provider cost telemetry',
        );
      }
    }
  });

  test('optimizer propagates authenticated identity to provider calls', () {
    final route = File('routes/ai/optimize/index.dart').readAsStringSync();
    final completeRuntime =
        File('lib/ai/optimize_route_internal.dart').readAsStringSync();
    final completeLoop =
        File('lib/ai/optimize_complete_support.dart').readAsStringSync();

    expect(route, contains('userId: authenticatedUserId'));
    expect(route, contains('deckId: deckId'));
    expect(route, contains('preferCollection:'));
    expect(completeRuntime, contains('userId: userId'));
    expect(completeRuntime, contains('deckId: deckId'));
    expect(completeLoop, contains('userId: userId'));
    expect(completeLoop, contains('deckId: deckId'));
  });

  test('commander reference refresh has request and total time budgets', () {
    final source =
        File('routes/ai/commander-reference/index.dart').readAsStringSync();

    expect(source, contains('_mtgTop8RequestTimeout'));
    expect(source, contains('_mtgTop8RefreshBudget'));
    expect(source, contains('.timeout(_mtgTop8RequestTimeout)'));
    expect(source, contains("'timed_out': timedOut"));
    expect(source, isNot(contains('await http.get(Uri.parse(formatUrl))')));
    expect(source, isNot(contains('await http.get(Uri.parse(eventUrl))')));
    expect(source, isNot(contains('await http.get(Uri.parse(exportUrl))')));
  });
}
