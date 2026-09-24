import 'dart:io';

import 'package:test/test.dart';

import '../lib/decks/deck_revision_support.dart';

/// DCK-P0-01 (decisão D-29 do dono): as partes puras da revisão otimista e do
/// ledger de mudanças do deck. O comportamento no banco está em
/// `deck_revision_ledger_db_live_test.dart`.
void main() {
  group('If-Match', () {
    test('aceita "7", W/"7", 7 e *', () {
      expect(readDeckIfMatch({'If-Match': '"7"'}).revision, 7);
      expect(readDeckIfMatch({'if-match': 'W/"7"'}).revision, 7);
      expect(readDeckIfMatch({'IF-MATCH': ' 7 '}).revision, 7);
      final any = readDeckIfMatch({'If-Match': '*'});
      expect(any.present, isTrue);
      expect(any.revision, isNull);
      expect(any.malformed, isFalse);
    });

    test('recusa o que não é revisão', () {
      for (final value in ['abc', '"0"', '-1', '""', 'W/', '"7']) {
        final read = readDeckIfMatch({'If-Match': value});
        expect(read.present, isTrue, reason: value);
        expect(read.malformed, isTrue, reason: value);
        expect(read.revision, isNull, reason: value);
      }
    });

    test('sem cabeçalho não há revisão pedida', () {
      final read = readDeckIfMatch(const {});
      expect(read.present, isFalse);
      expect(read.malformed, isFalse);
    });

    test('a exigência sai do ambiente e começa desligada (transição)', () {
      expect(deckIfMatchRequired(environment: const {}), isFalse);
      expect(
        deckIfMatchRequired(
          environment: const {deckIfMatchRequiredEnvironment: '1'},
        ),
        isTrue,
      );
      expect(
        deckIfMatchRequired(
          environment: const {deckIfMatchRequiredEnvironment: 'true'},
        ),
        isTrue,
      );
      expect(
        deckIfMatchRequired(
          environment: const {deckIfMatchRequiredEnvironment: '0'},
        ),
        isFalse,
      );
    });
  });

  group('Idempotency-Key', () {
    DeckMutationRequest request(
      Map<String, String> headers, {
      Object? body = const {'card_id': 'a', 'quantity': 1},
      String operation = 'card_add',
      String deckId = 'deck-1',
    }) => DeckMutationRequest.fromHeaders(
      headers,
      operation: operation,
      deckId: deckId,
      requireIfMatch: false,
      body: body,
    );

    test('a mesma chave e o mesmo pedido dão a mesma impressão', () {
      final first = request({'Idempotency-Key': 'k-1'});
      final again = request(
        {'idempotency-key': 'k-1'},
        body: const {'quantity': 1, 'card_id': 'a'},
      );

      expect(first.idempotencyKey, 'k-1');
      expect(first.requestFingerprint, hasLength(64));
      expect(again.requestFingerprint, first.requestFingerprint);
    });

    test('corpo, operação ou deck diferente mudam a impressão', () {
      final base = request({'Idempotency-Key': 'k-1'}).requestFingerprint;

      expect(
        request(
          {'Idempotency-Key': 'k-1'},
          body: const {'card_id': 'a', 'quantity': 2},
        ).requestFingerprint,
        isNot(base),
      );
      expect(
        request({
          'Idempotency-Key': 'k-1',
        }, operation: 'card_bulk').requestFingerprint,
        isNot(base),
      );
      expect(
        request({
          'Idempotency-Key': 'k-1',
        }, deckId: 'deck-2').requestFingerprint,
        isNot(base),
      );
    });

    test('chave vazia, longa ou com espaço é inválida', () {
      for (final value in [' ', 'com espaço', 'x' * 201, 'ção']) {
        final read = request({'Idempotency-Key': value});
        expect(read.idempotencyKeyMalformed, isTrue, reason: value);
        expect(read.idempotencyKey, isNull, reason: value);
        expect(read.requestFingerprint, isNull, reason: value);
      }
      expect(
        request({'Idempotency-Key': 'x' * 200}).idempotencyKeyMalformed,
        isFalse,
      );
    });

    test('operação fora do ledger é erro de programação', () {
      expect(
        () => request(const {}, operation: 'deck_delete'),
        throwsArgumentError,
      );
    });
  });

  group('diferença que vai para o ledger', () {
    Map<String, Object?> card(String id, int quantity) => {
      'card_id': id,
      'quantity': quantity,
      'is_commander': false,
      'condition': 'NM',
    };

    test('só as linhas que mudaram, antes e depois', () {
      final diff =
          diffDeckCards(
            [card('a', 1), card('b', 2), card('c', 4)],
            [card('a', 1), card('b', 3), card('d', 1)],
          )!;

      expect(diff.before, [card('b', 2), card('c', 4)]);
      expect(diff.after, [card('b', 3), card('d', 1)]);
    });

    test('nada mudou é null', () {
      expect(diffDeckCards([card('a', 1)], [card('a', 1)]), isNull);
    });

    test('condição e comandante também são mudança', () {
      final diff =
          diffDeckCards(
            [card('a', 1)],
            [
              {...card('a', 1), 'condition': 'LP'},
            ],
          )!;
      expect(diff.before.single['condition'], 'NM');
      expect(diff.after.single['condition'], 'LP');
    });

    test('metadados: só os campos que mudaram', () {
      final diff = diffDeckMetadata(
        {'name': 'A', 'format': 'modern', 'is_public': true, 'bracket': null},
        {'name': 'B', 'format': 'modern', 'is_public': false, 'bracket': null},
      );

      expect(diff.before, {'name': 'A', 'is_public': true});
      expect(diff.after, {'name': 'B', 'is_public': false});
    });
  });

  group('recibo', () {
    test(
      'leva a revisão nova, a de antes, o evento e o aviso da transição',
      () {
        const receipt = DeckMutationReceipt(
          revisionBefore: 4,
          revision: 5,
          eventId: 'e-1',
          operation: 'card_add',
          ifMatchMissing: true,
        );

        expect(receipt.toJson(), {
          'revision': 5,
          'revision_before': 4,
          'change_event_id': 'e-1',
          'change_operation': 'card_add',
          'revision_warning': deckIfMatchMissingWarning,
        });
        expect(receipt.headers, {'ETag': '"5"'});
        expect(deckRevisionHeadersOf(receipt.toJson()), {'ETag': '"5"'});
      },
    );

    test('sem aviso quando o If-Match veio; sem evento quando nada mudou', () {
      const receipt = DeckMutationReceipt(
        revisionBefore: 5,
        revision: 5,
        eventId: null,
        operation: 'card_set',
        ifMatchMissing: false,
      );

      expect(receipt.changed, isFalse);
      expect(receipt.toJson().containsKey('revision_warning'), isFalse);
    });
  });

  test('todo mutator de deck existente passa pela revisão e pelo ledger', () {
    const mutators = {
      'routes/decks/[id]/cards/index.dart': 'card_add',
      'routes/decks/[id]/cards/set/index.dart': 'card_set',
      'routes/decks/[id]/cards/replace/index.dart': 'card_replace',
      'routes/decks/[id]/cards/remove/index.dart': 'card_remove',
      'routes/decks/[id]/cards/bulk/index.dart': 'card_bulk',
      'routes/decks/[id]/index.dart': 'deck_patch',
      'routes/decks/[id]/optimizations/[eventId]/rollback/index.dart':
          'optimization_rollback',
      'routes/decks/[id]/changes/[eventId]/undo/index.dart': 'undo',
      'routes/import/to-deck/index.dart': 'import_to_deck',
    };
    for (final MapEntry(key: path, value: operation) in mutators.entries) {
      final source = File(path).readAsStringSync();
      expect(source, contains("'$operation'"), reason: path);
      expect(source, contains('lockDeckForMutation('), reason: path);
      expect(source, contains('recordDeckMutation('), reason: path);
      expect(source, contains('on DeckMutationInterrupt'), reason: path);
    }
    final item = File('routes/decks/[id]/index.dart').readAsStringSync();
    expect(item, contains("'deck_replace'"));
    expect(item, contains('readDeckIfMatch('));
    expect(item, contains('expectedRevision: ifMatch.revision'));
  });
}
