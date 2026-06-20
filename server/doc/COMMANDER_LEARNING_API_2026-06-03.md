# Commander Learning API - 2026-06-03

Nota reconciliada em 2026-06-19: este documento descreve o contrato atual da
rota. O modo lista e apenas um resumo seguro de disponibilidade; payloads de
deck, `win_conditions` e `role_summary` pertencem somente ao modo detalhe com
`commander`.

## Auth
As rotas ficam sob `/ai` e exigem `Authorization: Bearer <token>`.

## Listar Decks Aprendidos Ativos
```text
GET /ai/commander-learning
```

Resposta resumida:
```json
{
  "available": true,
  "source": "pg_commander_learned_deck_summary",
  "count": 1,
  "commanders": [
    {
      "commander": "Lorehold, the Historian",
      "deck_name": "Lorehold Best-of Learned No Premium Mox 2026-06-02",
      "source_system": "hermes",
      "source_ref": "learned_deck:82",
      "card_count": 100,
      "score": 136.5,
      "legal_status": "commander_legal",
      "last_synced_at": "2026-06-03T...",
      "active_learned_deck_count": 1,
      "learned_archetypes": [
        "fast-mana-copy-combo-big-spells-no-premium-mox"
      ]
    }
  ]
}
```

Uso no app:
- Descobrir se o comandante digitado possui deck aprendido ativo.
- Mostrar o atalho `Usar deck aprendido do comandante` somente quando houver match.

Contrato de `source` neste modo:
- `pg_commander_learned_deck_summary` identifica a lista resumida de comandantes
  ativos, retornada quando a query nao recebe `commander`.
- A lista e derivada de `commander_learned_decks`, mas nao carrega o deck
  completo nem o `recommended_deck`.

Contrato de campos neste modo:
- Raiz: `available`, `source`, `count`, `commanders`.
- Cada item em `commanders[]` pode retornar `commander`, `deck_name`,
  `source_system`, `source_ref`, `source_url`, `archetype`, `card_count`,
  `score`, `legal_status`, `promoted_at`, `last_synced_at`,
  `active_learned_deck_count` e `learned_archetypes`.
- Nao retorna `win_conditions`, `role_summary`, `promoted_deck`,
  `recommended_deck`, `decklist`, `cards` nem `metadata` bruta.

## Buscar Deck Aprendido De Um Comandante
```text
GET /ai/commander-learning?commander=Lorehold,%20the%20Historian
```

Resposta quando existe deck ativo:
```json
{
  "commander": "Lorehold, the Historian",
  "available": true,
  "source": "pg_commander_learned_decks",
  "promoted_deck": {
    "source_system": "hermes",
    "source_ref": "learned_deck:82",
    "legal_status": "commander_legal",
    "last_synced_at": "2026-06-03T...",
    "win_conditions": [],
    "role_summary": {},
    "role_summary_source": "card_list_canonicalized"
  },
  "recommended_deck": {
    "source": "promoted_learned_deck_pg",
    "source_confidence": "high",
    "total_cards_including_commander": 100,
    "main_quantity": 99,
    "win_conditions": [],
    "role_summary": {},
    "role_summary_source": "card_list_canonicalized",
    "commander": {"name": "Lorehold, the Historian"},
    "decklist": [],
    "cards": [],
    "legality": {
      "format": "commander",
      "is_valid": true,
      "banned_cards": [],
      "unknown_legality_cards": [],
      "invalid_cards": [],
      "errors": []
    },
    "validation": {"is_valid": true}
  }
}
```

Resposta quando nao existe deck ativo:
```json
{
  "commander": "Nome Informado",
  "available": false,
  "message": "Nenhum deck aprendido ativo encontrado para esse comandante."
}
```

## Fonte De Dados
- Runtime: tabela PG `commander_learned_decks`.
- Materializacao: Hermes/ManaLoom via `dart run bin/commander_learned_deck.dart --input-json=<path> --apply`.
- A rota nao depende do SQLite Hermes em runtime.
- `source = pg_commander_learned_deck_summary`: modo lista sem `commander`;
  resume comandantes ativos a partir de `commander_learned_decks`.
- `source = pg_commander_learned_decks`: modo detalhe com `commander`; carrega
  o learned deck ativo e monta `promoted_deck` + `recommended_deck`.
- No modo detalhe, `promoted_deck.role_summary` e
  `recommended_deck.role_summary` sao recomputados em tempo de leitura por
  `canonicalizeCommanderLearnedDeckMetadataWithStatus(pool, learnedDeck)` a
  partir do `card_list` persistido. O `metadata` armazenado em
  `commander_learned_decks` pode continuar defasado ate um backfill aprovado e
  nao e exposto cru ao app.
- O modo detalhe tambem retorna `role_summary_source` em `promoted_deck` e
  `recommended_deck`. O valor normal e `card_list_canonicalized`. Se a
  canonicalizacao nao puder rodar, a resposta preserva o resumo derivado do
  metadata persistido, mas sinaliza `role_summary_source =
  persisted_metadata_fallback` e inclui `role_summary_fallback_reason` com uma
  razao segura, por exemplo `metadata_canonicalization_failed`.

## Garantias Esperadas Para Lorehold
- `source_ref == "learned_deck:82"`.
- `total_cards_including_commander == 100`.
- `main_quantity == 99`.
- `legality.banned_cards == []`.
- `legality.unknown_legality_cards == []`.
- Nao conter `Chrome Mox`, `Mox Diamond`, `Mox Opal`.
