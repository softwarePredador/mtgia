# Commander Learning Next Steps - 2026-06-03

## Estado Atual
- Commit `4cf90e57` foi enviado para `origin/master` com a rota `commander-reference` expondo `commander_learning`.
- Backend publico confirmou `/health.git_sha=4cf90e57e2b9f6a837cc3a99135c780491d7c405`.
- O PG de produção contém `commander_learned_decks` com o deck ativo Hermes `learned_deck:82`.
- Validação PG do deck Lorehold aprendido: 100 cartas, 0 `Chrome Mox`, 0 `Mox Diamond`, 0 `Mox Opal`, 0 banidas, 0 legalidade desconhecida.
- `Lorehold, the Historian` foi marcado como `commander|legal` em `card_legalities` para a carta custom existente no PG.

## Endpoint Alvo
```text
GET /ai/commander-reference?commander=Lorehold,%20the%20Historian&learning=1&include_deck=1
```

## Ordem De Execucao
1. Feito: deploy do backend em producao para incluir o commit `4cf90e57`.
2. Feito: validar `/health` em producao e confirmar o `git_sha` esperado.
3. Feito: validar o endpoint alvo em producao.
4. Em andamento: integrar no app/UI o bloco `commander_learning.recommended_deck`.
5. Feito: criar rotina idempotente Hermes -> PG para novos decks aprendidos.
6. Feito: adicionar teste especifico da rota garantindo que `commander_learned_decks` ativo tem prioridade sobre fallback deterministico.
7. Feito: endpoint dedicado `/ai/commander-learning` criado para payload direto de deck aprendido.

## Endpoint Dedicado
```text
GET /ai/commander-learning?commander=Lorehold,%20the%20Historian
```

- Retorna `available`, `promoted_deck` e `recommended_deck` diretamente.
- Fonte runtime: `commander_learned_decks` no PG.
- O app usa este endpoint no atalho `Usar deck aprendido do comandante`.

## Rotina Idempotente Hermes -> PG
```text
dart run bin/commander_learned_deck.dart --input-json=<path> --dry-run
dart run bin/commander_learned_deck.dart --input-json=<path> --apply
```

- Chave idempotente: `source_system + source_ref`.
- Payload bruto Hermes com `id`, `commander`, `deck_name`, `card_list` e metadados e aceito.
- `--apply` cria/atualiza `commander_learned_decks` e, por padrao, desativa outros decks ativos do mesmo comandante.
- `--keep-other-active` preserva outros ativos quando necessario.

## Validacao Publica Executada
Resumo sanitizado com usuario QA descartavel autenticado:
```json
{
  "endpoint_status": 200,
  "learning_available": true,
  "promoted_source_ref": "learned_deck:82",
  "recommended_source": "promoted_learned_deck_pg",
  "total_cards_including_commander": 100,
  "main_quantity": 99,
  "banned_count": 0,
  "unknown_legality_count": 0,
  "invalid_count": 0,
  "validation_is_valid": true,
  "premium_mox_present": [],
  "contains_worldfire": true,
  "contains_lorehold_commander": true
}
```

## Checklist De Validacao Do Endpoint
- `commander_learning.available == true`.
- `commander_learning.promoted_deck.source_ref == "learned_deck:82"`.
- `commander_learning.recommended_deck.source == "promoted_learned_deck_pg"`.
- `commander_learning.recommended_deck.total_cards_including_commander == 100`.
- `commander_learning.recommended_deck.legality.banned_cards == []`.
- `commander_learning.recommended_deck.legality.unknown_legality_cards == []`.
- Decklist nao contem `Chrome Mox`, `Mox Diamond` ou `Mox Opal`.

## Notas Operacionais
- A rota nao depende do Hermes em runtime; Hermes e fonte de materializacao, PG e a fonte runtime.
- Proximo deploy conhecido historicamente: `git pull`, `dart_frog build` dentro do container de backend e `docker commit` da imagem atualizada.
- Antes de deploy destrutivo/restart, confirmar container, imagem e health atual.
