import 'package:dart_frog/dart_frog.dart';

import '../../../lib/decks/deck_trash_support.dart';

/// DCK-P0-06 (decisão D-30 do dono): deck na lixeira some de toda rota de
/// `/decks/:id` com a resposta de deck inexistente; só o restaurar passa.
/// A regra está em `lib/decks/deck_trash_support.dart` ([deckTrashGuard]).
Handler middleware(Handler handler) => handler.use(deckTrashGuard());
