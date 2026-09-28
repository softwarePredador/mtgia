import 'dart:io';

import 'package:test/test.dart';

/// DCK-P0-04: o POST /ai/generate assíncrono grava o pedido durável logo
/// depois de criar o job, e o job, ao terminar, grava o resultado nele; a
/// materialização só usa o que está gravado.
void main() {
  final generate = File('routes/ai/generate/index.dart').readAsStringSync();

  test('o pedido é gravado junto com o job e devolvido na resposta 202', () {
    final job = generate.indexOf('AiGenerateJobStore.createOrReuse(');
    final request = generate.indexOf('AiGenerateRequestStore.record(');
    final background = generate.indexOf('unawaited(', request);

    expect(job, greaterThanOrEqualTo(0));
    expect(request, greaterThan(job));
    expect(background, greaterThan(request));
    expect(generate, contains("'generate_request_id': generateRequestId"));
    expect(generate, contains('on AiGenerateRequestConflict'));
  });

  test('o resultado entra no pedido só depois de o job concluir', () {
    final complete = generate.indexOf('AiGenerateJobStore.complete(');
    final record = generate.indexOf('AiGenerateRequestStore.recordResult(');

    expect(record, greaterThan(complete));
    expect(
      generate.substring(record, record + 400),
      contains('_aiGenerateBodyIsValidWithoutInvalidCards(resultBody)'),
    );
  });

  test('a materialização não lê cartas do app', () {
    final route =
        File(
          'routes/ai/generate/requests/[id]/materialize.dart',
        ).readAsStringSync();
    expect(route, isNot(contains("decoded['cards']")));
    expect(route, contains('verifiedEmailRequiredResponse'));
  });
}
