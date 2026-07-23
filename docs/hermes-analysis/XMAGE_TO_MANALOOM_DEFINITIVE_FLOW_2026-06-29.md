# XMage -> ManaLoom Definitive Flow - 2026-06-29

Status: `historical_native-adaptation_evidence`; superseded for current
operation by `GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md`.

Este caminho é um índice histórico de compatibilidade. O diário completo de
20.719 linhas foi preservado byte a byte em
`archive/XMAGE_NATIVE_ADAPTATION_EVIDENCE_LOG_2026-06-29_TO_2026-07-15.md`.
Ele must not be used as a current handoff, queue owner ou autorização de
tradução massiva de classes Java.

## Current operational owner

Use:

- `GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md`;
- `scripts/manaloom_global_battle_closure.sh`;
- `EXTERNAL_BATTLE_EXECUTION_CONTRACT.md`;
- `BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md`;
- `NEW_SERVER_POSTGRES_WORKFLOW_2026-07-06.md`.

PostgreSQL remains the durable source of truth. Hermes is cache/runtime evidence, not truth.
Qualquer operação PostgreSQL atual passa por
`server/bin/with_new_server_pg.sh`.

## Preserved historical decision

O fluxo histórico usava:

1. identidade/Oracle/legalidade de fontes oficiais;
2. Local XMage as the authoritative open rules-engine behavior source;
3. Pinned Forge as a secondary executable rules engine;
4. extração de source-authoritative adapter candidates;
5. adapter/runtime de escopo exato;
6. pacote PostgreSQL somente após precheck/testes;
7. sync PostgreSQL → Hermes e replay após apply.

If the contract checkpoint passes, a fila seguia para family/subpattern sem
reabrir toda a estratégia.

A pinned XMage or Forge battle prova execução externa. Não cria
`card_battle_rules`. Para a lane nativa, a candidate becomes executable
ManaLoom battle truth only when its matching runtime adapter exists e o pacote
passa precheck/apply/postcheck. Uma classe Java local continua source candidate
até reconciliação com o catálogo pinado; nunca autoriza pular o gate nativo.

Timeout externo falha fechado. Battle agregado não prova carta individual.
If a candidate card is not drawn/used in battle, rode exposição natural
adicional ou teste focado; não conclua ausência de efeito.

## Current historical checkpoint

O último checkpoint retido é o PG267/PG271 runtime-rule checkpoint:

- `xmage_current_replay_batch_pipeline_20260630_post_pg276_assemble_the_players_manifest.md`;
- `ready_for_structured_xmage_pull_review_required=64`;
- `xmage_source_valid_mapper_required=61`;
- `runtime_family_required_count=0`.

Essas contagens são snapshot histórico, não readiness atual.

## Historical tooling boundary

`xmage_authoritative_adaptation_queue.py` permanece disponível para reconstruir
evidência histórica e artefatos compatíveis. Não é runner operacional atual.

Exemplo histórico como `Hazel's Brewmaster` permanece no evidence log para
linhagem de escopo; não autoriza promoção de regra ou deck.

Cobertura externa confirmada executa no engine pinado. Adapter nativo só abre
para residual explícito que ainda não tenha cobertura XMage/Forge e que possua
scope, runtime e testes revisados.

## Archive and recovery

O snapshot completo, hash e tamanho ficam em `archive/README.md`. Ferramentas
que precisam apenas do contrato usam este arquivo compacto. Auditores de
retenção podem consultar o snapshot histórico, mas runtime/produto não pode
consumi-lo.
