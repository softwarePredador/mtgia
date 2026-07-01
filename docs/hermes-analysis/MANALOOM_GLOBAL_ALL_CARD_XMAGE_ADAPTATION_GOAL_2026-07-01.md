# ManaLoom Global All-Card XMage Adaptation Goal

Data: 2026-07-01

Status: `active_until_zero_remaining_queue`

Fonte operacional:

- `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`
- `docs/hermes-analysis/BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg311_permanent_activated_recursion_to_hand_wave.md`

## Objetivo

Zerar a adaptacao global XMage -> ManaLoom para todas as cartas restantes do
escopo all-card/Commander-legal aplicavel, usando XMage local como fonte final
de comportamento para toda carta com classe Java resolvida e tratando o restante
como excecao documentada.

Este goal nao e melhorar Lorehold, deck `607`, nem decks atualmente cadastrados.
Esses decks podem ser usados como QA, mas nao definem o escopo. O escopo e a
fila global de cartas conhecidas pelo ManaLoom.

## Estado atual

Checkpoint: pos-PG311, `xmage_permanent_simple_activated_graveyard_to_hand_v1`.

| Metrica | Valor |
| --- | ---: |
| `target_identity_count` | 27534 |
| `xmage_authoritative_source_count` | 27220 |
| `xmage_missing_source_exception_count` | 314 |
| `xmage_authoritative_parser_gap_count` | 0 |
| `xmage_authoritative_adapter_required_count` | 27220 |
| `manual_semantic_decision_units_remaining` | 314 |
| `adapter_work_unit_count` | 11429 |

Leitura correta:

- `27220` identidades ja tem verdade comportamental no XMage local.
- O trabalho restante nelas e traduzir XMage para adapters/runtime ManaLoom por
  familia/subpadrao, nao revisar semanticamente carta por carta.
- `314` identidades nao resolveram classe local no XMage e ficam em trilha
  separada: fonte oficial/Forge/modelagem manual/exclusao de produto.

## Condicao de parada

O goal so pode parar quando uma fila global recem-gerada mostrar tudo abaixo:

1. `xmage_authoritative_adapter_required_count = 0`.
2. `xmage_authoritative_parser_gap_count = 0`.
3. Toda `xmage_missing_source_exception` classificada com evidencia em uma
   trilha explicita: `official_oracle_manual_model`, `forge_crosscheck_model`,
   `manual_runtime_model`, ou `product_exclusion`.
4. Nenhum scope generico `xmage_*_review_v1` promovido como regra executavel.
5. Todas as regras promovidas com `battle_model_scope` exato, `oracle_hash`,
   `confidence=auto`, `review_status=verified`, e pacote PostgreSQL com
   precheck/apply/postcheck/rollback documentados.
6. PostgreSQL, Hermes SQLite, `card_intelligence_snapshot`, runtime
   `get_card_effect` e auditorias E2E concordando para os lotes promovidos.
7. Testes focados de runtime cobrindo positivo, negativo e limite relevante da
   familia antes do apply PostgreSQL.
8. Documentos e reports atuais apontando para o ultimo checkpoint, sem runner
   vazio, artefato velho ou default historico conduzindo a resultado divergente.
9. Commit e push das evidencias, scripts, testes e documentos do ultimo lote.

Se qualquer item acima falhar, o goal continua ativo.

## Metodo de execucao

O ciclo de cada onda deve ser:

1. Regerar ou consumir a fila autoritativa mais recente.
2. Escolher uma familia/subpadrao por volume e seguranca de traducao.
3. Minerar XMage por classes de efeito, habilidade, alvo, custo e condicoes.
4. Criar ou ampliar splitter exato somente para o subpadrao suportado.
5. Implementar runtime ManaLoom correspondente.
6. Adicionar testes focados do splitter e do runtime.
7. Gerar pacote PostgreSQL com apenas regras executaveis.
8. Aplicar PostgreSQL com precheck, apply, postcheck e rollback salvo.
9. Sincronizar Hermes/SQLite e snapshot.
10. Rodar E2E do pacote e auditorias de alinhamento.
11. Recalcular fila global e registrar delta.
12. Commitar e pushar a evidencia.

## Priorizacao

Prioridade primaria:

- Maior reducao segura de `xmage_authoritative_adapter_required_count`.
- Familias que reaproveitam runtime existente com baixo risco de regra errada.
- Familias globais de alto impacto para decks futuros, nao apenas cartas ja
  cadastradas.

Prioridade secundaria:

- Popularidade externa/staple apenas para ordenar QA e smoke, nunca para limitar
  escopo.
- Lorehold/deck `607` apenas como semente de teste natural depois que a regra
  da familia estiver correta.

## Proxima etapa concreta

PG311 fechou o subpadrao de permanente com habilidade ativada simples que
retorna card do cemiterio para a mao. Foram promovidas 11 cartas: Adun
Oakenshield, Argivian Archaeologist, Corpse Hauler, Dowsing Shaman, Font of
Return, Groundskeeper, Hanna, Ship's Navigator, Rootwater Diver, Salvage Scout,
Skull of Orm e Spellkeeper Weird.

Evidencias PG311:

- `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_pg_apply_evidence.md`
- `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg311_existing_supported_recheck.md`

O splitter exato pos-PG311 retorna `proposal_count=0` sobre `7362` linhas
suportadas consideradas. Portanto, a proxima etapa nao e repetir este
subpadrao, e sim escolher outro subpadrao runtime-backed a partir da fila
pos-PG311.

Maiores work units atuais para priorizacao:

- `recursion`: 1984
- `draw_engine`: 1660
- `grant_protection`: 1179
- `direct_damage`: 928
- `add_counters` por fonte: 795
- `life_gain`: 754
- `draw_cards`: 676
- `removal_destroy`: 655
- `tutor`: 626

O proximo lote deve seguir a mesma disciplina: minerar uma assinatura XMage
estreita, implementar splitter exato, runtime e testes, aplicar PostgreSQL,
sincronizar Hermes/SQLite, rodar E2E/auditorias e recalcular a fila.

Subpadrao PG311 ja fechado:

- `ReturnFromGraveyardToHandTargetEffect`
- `SimpleActivatedAbility`
- permanente no campo de batalha
- custos suportados: mana simples, tap e sacrificio da propria fonte
- alvos suportados: criatura, artefato, encantamento, instant/sorcery,
  artefato ou encantamento, artifact creature, permanent, any card quando a
  fonte e o Oracle concordarem

Nome sugerido:

- `xmage_permanent_simple_activated_graveyard_to_hand_v1`

Bloqueios reais deixados para sublotes posteriores:

- custos de descarte, exilio de cards do cemiterio, OrCost/CompositeCost,
  fontes ativadas do cemiterio, subtipo especifico ainda nao mapeado como
  Arcane, condicoes de watcher e efeitos compostos com multiplas zonas.

## Regra contra desvio

Se durante a execucao surgir vontade de trabalhar em deckbuilding, release app,
UX, Lorehold ou qualidade comercial, isso deve ficar fora deste goal, salvo se a
validacao do lote de cartas exigir um smoke de batalha. O objetivo deste goal e
terminar a traducao global de regras de cartas.
