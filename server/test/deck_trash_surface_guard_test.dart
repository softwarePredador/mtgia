import 'dart:io';

import 'package:test/test.dart';

/// DCK-P0-06 (decisão D-30 do dono): deck na lixeira some de todas as
/// superfícies. As rotas de `routes/decks/[id]/` ficam atrás do guarda de
/// `routes/decks/[id]/_middleware.dart`; fora delas, todo arquivo de
/// `routes/` e `lib/` que lê `decks` precisa filtrar `deleted_at`, ou estar
/// nesta lista com o motivo. Arquivo novo que lê `decks` sem o filtro faz o
/// teste falhar até alguém decidir.
const _readsWithoutTrashFilter = <String, String>{
  'lib/battle/battle_replay_annotation_service.dart':
      'só atende routes/decks/[id]/battle-replays, atrás do guarda',
  'lib/battle/battle_replay_read_service.dart':
      'só atende routes/decks/[id]/battle-replays, atrás do guarda',
  'lib/deck_validation_route_support.dart':
      'só atende routes/decks/[id]/validate, atrás do guarda',
};

final _readsDecks = RegExp(r'\b(FROM|JOIN)\s+decks\b');

void main() {
  test('toda leitura de decks fora de /decks/:id filtra a lixeira', () {
    final offenders = <String>[];
    final readers = <String>{};
    for (final root in const ['routes', 'lib']) {
      for (final file in Directory(root)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))) {
        final path = file.path.replaceAll(r'\', '/');
        final text = file.readAsStringSync();
        if (!_readsDecks.hasMatch(text)) continue;
        readers.add(path);
        if (path.startsWith('routes/decks/[id]/')) continue;
        if (text.contains('deleted_at')) continue;
        if (_readsWithoutTrashFilter.containsKey(path)) continue;
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty, reason: 'lê decks sem filtrar a lixeira');
    // A lista não guarda arquivo que já não lê decks ou que passou a filtrar.
    for (final path in _readsWithoutTrashFilter.keys) {
      expect(readers, contains(path), reason: path);
      expect(
        File(path).readAsStringSync(),
        isNot(contains('deleted_at')),
        reason: path,
      );
    }
  });

  test(
    'o guarda de /decks/:id está no lugar e só deixa o restaurar passar',
    () {
      final middleware =
          File('routes/decks/[id]/_middleware.dart').readAsStringSync();
      expect(middleware, contains('deckTrashGuard()'));
      final support =
          File('lib/decks/deck_trash_support.dart').readAsStringSync();
      expect(support, contains("segments[2] == 'restore'"));
      expect(File('routes/decks/[id]/restore/index.dart').existsSync(), isTrue);
    },
  );
}
