# Commander Learning API - 2026-06-03

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
  "source": "pg_commander_learned_decks",
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
      "win_conditions": [
        {"name": "Rite of Dragoncaller", "priority": "primary"}
      ],
      "role_summary": {
        "lands": 33,
        "ramp": 6,
        "wincon": 11
      }
    }
  ]
}
```

Uso no app:
- Descobrir se o comandante digitado possui deck aprendido ativo.
- Mostrar o atalho `Usar deck aprendido do comandante` somente quando houver match.

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
    "role_summary": {}
  },
  "recommended_deck": {
    "source": "promoted_learned_deck_pg",
    "source_confidence": "high",
    "total_cards_including_commander": 100,
    "main_quantity": 99,
    "win_conditions": [],
    "role_summary": {},
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

## Garantias Esperadas Para Lorehold
- `source_ref == "learned_deck:82"`.
- `total_cards_including_commander == 100`.
- `main_quantity == 99`.
- `legality.banned_cards == []`.
- `legality.unknown_legality_cards == []`.
- Nao conter `Chrome Mox`, `Mox Diamond`, `Mox Opal`.
