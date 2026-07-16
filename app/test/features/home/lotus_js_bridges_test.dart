import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_js_bridges.dart';

void main() {
  group('LotusStorageMessageQueue', () {
    test('dispatches storage callbacks strictly in arrival order', () async {
      final firstGate = Completer<void>();
      final events = <String>[];
      final queue = LotusStorageMessageQueue((message) async {
        events.add('$message:start');
        if (message == 'first') {
          await firstGate.future;
        }
        events.add('$message:end');
      });

      queue.enqueue('first');
      queue.enqueue('second');
      await Future<void>.delayed(Duration.zero);

      expect(events, const ['first:start']);

      firstGate.complete();
      await queue.idle;

      expect(events, const [
        'first:start',
        'first:end',
        'second:start',
        'second:end',
      ]);
    });

    test('continues draining after a callback failure', () async {
      final processed = <String>[];
      final errors = <Object>[];
      final queue = LotusStorageMessageQueue((message) async {
        if (message == 'broken') {
          throw StateError('broken message');
        }
        processed.add(message);
      }, onError: (error, _) => errors.add(error));

      queue.enqueue('broken');
      queue.enqueue('valid');
      await queue.idle;

      expect(errors, hasLength(1));
      expect(processed, const ['valid']);
    });

    test(
      'keeps native mutation and rebase atomic between Web snapshots',
      () async {
        final messageGate = Completer<void>();
        final events = <String>[];
        final queue = LotusStorageMessageQueue((message) async {
          events.add('$message:start');
          if (message == 'web_before') {
            await messageGate.future;
          }
          events.add('$message:end');
        });

        queue.enqueue('web_before');
        final taskResult = queue.enqueueTask(() async {
          events.add('native:write');
          await Future<void>.delayed(Duration.zero);
          events.add('native:rebase');
          return true;
        });
        queue.enqueue('web_after');
        await Future<void>.delayed(Duration.zero);

        expect(events, const ['web_before:start']);

        messageGate.complete();
        expect(await taskResult, isTrue);
        await queue.idle;
        expect(events, const [
          'web_before:start',
          'web_before:end',
          'native:write',
          'native:rebase',
          'web_after:start',
          'web_after:end',
        ]);
      },
    );

    test('drops messages enqueued after close', () async {
      final processed = <String>[];
      final queue = LotusStorageMessageQueue((message) async {
        processed.add(message);
      });

      queue.enqueue('before_close');
      queue.close();
      queue.enqueue('after_close');
      await queue.idle;

      expect(processed, const ['before_close']);
    });
  });
}
