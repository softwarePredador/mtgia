# Contrato Optimize/Rebuild - 2026-03-23

> Documento ativo para o contrato funcional do fluxo `optimize -> rebuild -> validate`.
> Deve ser lido junto com `docs/CONTEXTO_PRODUTO_ATUAL.md`.

## Objetivo

Fixar o contrato mínimo esperado entre:

- backend `server/routes/ai/optimize`
- backend `server/routes/ai/rebuild`
- app `DeckProvider`
- UI de `deck details`

Este documento existe para evitar regressão silenciosa de payload e de UX.

## Optimize

### `200 OK`

Fluxo aceito sem erro de contrato.

Campos esperados:

- `mode`
- `removals`
- `additions`
- `reasoning`
- `removals_detailed` quando houver IDs
- `additions_detailed` quando houver IDs
- `deck_analysis` quando disponível
- `post_analysis` quando disponível

Campos opcionais relevantes:

- `quality_warning`
- `warnings`
- `theme`
- `constraints`

Interpretação:

- `mode=optimize`: trocas pequenas/médias aprovadas
- `mode=complete`: complemento/fechamento do deck

Regra de app:

- permitir preview
- aplicar mudanças
- validar o deck final depois da aplicação

### `202 Accepted`

Fluxo assíncrono.

Campos esperados:

- `job_id`
- `poll_interval_ms`
- `total_stages` quando disponível

Regra de app:

- polling em `/ai/optimize/jobs/:id`
- traduzir stages em feedback humano

### `422 Unprocessable Entity`

Erro funcional esperado, não erro genérico de infraestrutura.

Campos esperados:

- `error`
- `outcome_code`
- `quality_error`

Campos opcionais importantes:

- `deck_state`
- `next_action`
- `theme`

`outcome_code` válidos no fluxo atual:

- `needs_repair`
- `near_peak`
- `no_safe_upgrade_found`

Regra de app:

- `needs_repair`: disparar `rebuild_guided`
- `near_peak`: informar que o deck já está perto do teto
- `no_safe_upgrade_found`: preservar deck e informar ausência de upgrade seguro

## Rebuild

### `200 OK`

Fluxo de rebuild bem sucedido.

Campos esperados:

- `mode=rebuild_guided`
- `outcome_code`

`outcome_code` válidos:

- `rebuild_created`
- `rebuild_preview`

Campos típicos:

- `draft_deck_id`
- `rebuild_scope_selected`
- `validation`
- `target_profile`

Regra de app:

- se houver `draft_deck_id`, abrir o draft ou navegar para ele
- preservar sempre o deck original

### `422 Unprocessable Entity`

Falha estruturada do rebuild.

Campos esperados:

- `error`
- `quality_error` quando disponível

Regra de app:

- não sobrescrever o deck original
- mostrar falha de rebuild como estado tratável, não crash

## Validate

### `POST /decks/:id/validate`

Contrato mínimo esperado:

- `200 OK` com body contendo `valid=true/false`
- `errors` quando `valid=false`

Regra de app:

- depois de `apply` ou `rebuild`, a validação precisa continuar interpretável pelo app

## Smoke mínimo do app

A cobertura mínima que sustenta este contrato agora é:

1. carregar `deck details`
2. chamar `optimize`
3. aplicar com IDs
4. chamar `validate`

Essa cobertura está exercitada em:

- `app/test/features/decks/providers/deck_provider_test.dart`

## Regras de compatibilidade

Qualquer mudança futura no backend precisa preservar pelo menos:

1. `422` estruturado para erros esperados de negócio
2. `next_action` quando o fluxo exigir `rebuild_guided`
3. `removals_detailed/additions_detailed` quando houver IDs
4. contrato estável de `validate` após aplicar mudanças

Se alguma dessas regras mudar, este documento e o app devem ser atualizados juntos.
