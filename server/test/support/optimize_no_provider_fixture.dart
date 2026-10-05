/// Fixture da D-82 (POST /ai/optimize sem provedor de IA), compartilhada pelo
/// teste de banco e pelo E2E: catálogo sintético com ids fixos e dois decks
/// Commander de 100 cartas, um com shortlist determinística e outro sem.
library;

import 'package:postgres/postgres.dart';

const _commanderBlue = '50000000-0000-4000-8000-000000000001';
const _commanderBlack = '50000000-0000-4000-8000-000000000002';

String _id(String prefix, int index) =>
    '$prefix-0000-4000-8000-${index.toString().padLeft(12, '0')}';

/// Catálogo sintético mínimo, com gatilhos em inglês (os classificadores do
/// otimizador casam texto em inglês), no desenho do
/// `scripts/lib/manaloom_seed_deck_otimizavel.sql` da sessão do gate:
/// - deck azul: 18 Ilhas + 18 Ermos, 10 pedras incolores, 8 contramágicas,
///   3 varridas, 30 compras, 12 criaturas e o comandante azul;
/// - 12 candidatas azuis FORA de qualquer deck (a shortlist do deck azul);
/// - deck preto: 18 Pântanos + os mesmos 18 Ermos e 10 pedras, e cartas
///   pretas próprias. Nenhuma carta do banco fica elegível para ele (as
///   candidatas são azuis), então a shortlist dele sai vazia.
Future<void> seedOptimizeNoProviderCatalog(Pool pool) async {
  Future<void> card({
    required String id,
    required String name,
    required String typeLine,
    required String oracle,
    required List<String> identity,
    String? manaCost,
    int cmc = 0,
  }) async {
    await pool.execute(
      Sql.named('''
        INSERT INTO cards (
          id, scryfall_id, name, mana_cost, cmc, type_line, oracle_text,
          colors, color_identity, set_code, rarity, price_usd, is_reserved
        ) VALUES (
          CAST(@id AS uuid), gen_random_uuid(), @name, @manaCost, @cmc,
          @typeLine, @oracle, CAST(@identity AS text[]),
          CAST(@identity AS text[]), 'TST', 'common', 0.75, FALSE
        )
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          mana_cost = EXCLUDED.mana_cost,
          cmc = EXCLUDED.cmc,
          type_line = EXCLUDED.type_line,
          oracle_text = EXCLUDED.oracle_text,
          colors = EXCLUDED.colors,
          color_identity = EXCLUDED.color_identity
      '''),
      parameters: {
        'id': id,
        'name': name,
        'manaCost': manaCost,
        'cmc': cmc,
        'typeLine': typeLine,
        'oracle': oracle,
        'identity': identity,
      },
    );
    // D-28 (DCK-P1-04): carta sem linha de legalidade não é legal, e a
    // shortlist determinística só aceita carta legal no formato do deck.
    await pool.execute(
      Sql.named('''
        INSERT INTO card_legalities (card_id, format, status)
        VALUES (CAST(@id AS uuid), 'commander', 'legal')
        ON CONFLICT (card_id, format) DO UPDATE SET status = EXCLUDED.status
      '''),
      parameters: {'id': id},
    );
  }

  await card(
    id: _commanderBlue,
    name: 'D82 Comandante Azul',
    typeLine: 'Legendary Creature — Merfolk Wizard',
    oracle: 'Whenever you cast an instant or sorcery spell, draw a card.',
    identity: const ['U'],
    manaCost: '{2}{U}{U}',
    cmc: 4,
  );
  await card(
    id: _commanderBlack,
    name: 'D82 Comandante Preto',
    typeLine: 'Legendary Creature — Human Warlock',
    oracle: 'Whenever you cast an instant or sorcery spell, draw a card.',
    identity: const ['B'],
    manaCost: '{2}{B}{B}',
    cmc: 4,
  );
  for (var i = 1; i <= 18; i++) {
    await card(
      id: _id('51000000', i),
      name: 'D82 Ilha $i',
      typeLine: 'Basic Land — Island',
      oracle: '{T}: Add {U}.',
      identity: const ['U'],
    );
    await card(
      id: _id('51000001', i),
      name: 'D82 Ermo $i',
      typeLine: 'Basic Land — Wastes',
      oracle: '{T}: Add {C}.',
      identity: const [],
    );
    await card(
      id: _id('51000002', i),
      name: 'D82 Pantano $i',
      typeLine: 'Basic Land — Swamp',
      oracle: '{T}: Add {B}.',
      identity: const ['B'],
    );
  }
  for (var i = 1; i <= 10; i++) {
    await card(
      id: _id('52000000', i),
      name: 'D82 Pedra $i',
      typeLine: 'Artifact',
      oracle: '{T}: Add {C}.',
      identity: const [],
      manaCost: '{2}',
      cmc: 2,
    );
  }
  for (final (prefix, color, symbol) in const [
    ('52000001', 'U', 'Azul'),
    ('52000002', 'B', 'Preta'),
  ]) {
    for (var i = 1; i <= 53; i++) {
      final (typeLine, oracle, cmc) = switch (i) {
        <= 8 => ('Instant', 'Counter target spell.', 2),
        <= 11 => ('Sorcery', 'Destroy all creatures.', 5),
        <= 41 => ('Sorcery', 'Draw a card.', 3 + i % 3),
        _ => ('Creature — Merfolk Wizard', 'Flying.', 2 + i % 4),
      };
      await card(
        id: _id(prefix, i),
        name: 'D82 $symbol $i',
        typeLine: typeLine,
        oracle: oracle,
        identity: [color],
        manaCost: '{${cmc - 1}}{$color}',
        cmc: cmc,
      );
    }
  }
  for (var i = 1; i <= 12; i++) {
    final (typeLine, oracle) = switch (i) {
      <= 4 => (
        'Creature — Merfolk Wizard',
        'Flying. When this creature enters the battlefield, draw a card.',
      ),
      <= 8 => ('Artifact', '{T}: Add {U}. When this enters, draw a card.'),
      _ => ('Instant', 'Counter target spell. Draw a card.'),
    };
    await card(
      id: _id('53000000', i),
      name: 'D82 Candidata $i',
      typeLine: typeLine,
      oracle: oracle,
      identity: const ['U'],
      manaCost: '{1}{U}',
      cmc: 2,
    );
  }
}

Future<String> insertOptimizeNoProviderUser(Pool pool) async {
  final suffix = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rows = await pool.execute(
    Sql.named('''
      INSERT INTO users (username, email, password_hash, email_verified_at)
      VALUES (@username, @email, 'x', CURRENT_TIMESTAMP)
      RETURNING id::text
    '''),
    parameters: {
      'username': 'd82_$suffix',
      'email': 'd82_$suffix@example.invalid',
    },
  );
  return rows.single[0]! as String;
}

/// Deck Commander de 100: 36 terrenos, 10 pedras, 53 cartas da cor e o
/// comandante.
Future<String> insertOptimizeNoProviderDeck(
  Pool pool,
  String userId, {
  required bool blue,
}) async {
  final deck = await pool.execute(
    Sql.named('''
      INSERT INTO decks (user_id, name, format, is_public)
      VALUES (CAST(@userId AS uuid), @name, 'commander', FALSE)
      RETURNING id::text
    '''),
    parameters: {'userId': userId, 'name': blue ? 'D82 azul' : 'D82 preto'},
  );
  final deckId = deck.single[0]! as String;
  final cardIds = <String>[
    for (var i = 1; i <= 18; i++) _id(blue ? '51000000' : '51000002', i),
    for (var i = 1; i <= 18; i++) _id('51000001', i),
    for (var i = 1; i <= 10; i++) _id('52000000', i),
    for (var i = 1; i <= 53; i++) _id(blue ? '52000001' : '52000002', i),
  ];
  for (final cardId in cardIds) {
    await pool.execute(
      Sql.named('''
        INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
        VALUES (CAST(@deckId AS uuid), CAST(@cardId AS uuid), 1, FALSE)
      '''),
      parameters: {'deckId': deckId, 'cardId': cardId},
    );
  }
  await pool.execute(
    Sql.named('''
      INSERT INTO deck_cards (deck_id, card_id, quantity, is_commander)
      VALUES (CAST(@deckId AS uuid), CAST(@cardId AS uuid), 1, TRUE)
    '''),
    parameters: {
      'deckId': deckId,
      'cardId': blue ? _commanderBlue : _commanderBlack,
    },
  );
  return deckId;
}
