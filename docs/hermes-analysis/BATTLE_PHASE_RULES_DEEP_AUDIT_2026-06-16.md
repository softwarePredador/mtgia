# Battle Phase Rules Deep Audit - 2026-06-16

> Status 2026-06-19: documento historico de auditoria de fases. Use como
> contexto tecnico, nao como prova de cobertura atual. Fonte viva:
> [BATTLE_VALIDATION_REGISTER_2026-06-19.md](BATTLE_VALIDATION_REGISTER_2026-06-19.md).
> Indice: [BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md](BATTLE_DOCUMENTATION_STATUS_INDEX_2026-06-19.md).

## Escopo

Auditoria profunda das etapas de batalha do Hermes contra regras oficiais atuais
e contra o codigo ativo do ManaLoom. O objetivo foi separar:

- regra oficial que precisa ser respeitada;
- comportamento atualmente implementado no `battle_analyst_v9.py`;
- lacuna real ainda pendente;
- correcao segura aplicada neste ciclo.

Este ciclo e Hermes-only. Nao altera app Flutter, contrato publico, PostgreSQL ou
EasyPanel.

## Fontes oficiais consultadas

- Wizards Rules: <https://magic.wizards.com/en/rules>
- Comprehensive Rules PDF efetivo em 2026-04-17:
  <https://media.wizards.com/2026/downloads/MagicCompRules%2020260417.pdf>
- Commander oficial:
  <https://magic.wizards.com/en/formats/commander>

Regras de referencia usadas na leitura:

- CR 103.5 / 103.5c: mulligan e primeiro mulligan livre em multiplayer.
- CR 117: prioridade, APNAP, sem prioridade no untap e prioridade geralmente
  ausente no cleanup.
- CR 500-514: estrutura de turno, fases, combate, end step e cleanup.
- CR 508-511: declare attackers, declare blockers, combat damage, end of combat.
- CR 514.3a: cleanup pode gerar prioridade apenas se SBAs/triggers surgirem.
- Commander oficial: 99+1, singleton, identidade de cor, command zone,
  commander tax, 21 commander damage e ataque a multiplos jogadores.

## Resultado executivo

O engine ativo `battle_analyst_v9.py` esta mais avancado que a documentacao
historica em `BATTLE_SYSTEM_LOGIC.md` indicava. A auditoria confirmou:

- Turno possui untap, upkeep simplificado, draw, main phases, combat phase
  formal, end step e cleanup.
- Prioridade tem APNAP pass sequence e loop limitado em janelas relevantes.
- Combate possui beginning of combat, declare attackers, declare blockers,
  first strike damage, regular damage e end of combat.
- Commander multiplayer ja permite distribuir atacantes entre multiplos
  defensores.
- Mulligan ja nao e apenas contagem de terrenos: avalia lands, cores, curva
  inicial, ramp barato e maos mortas caras.
- Board wipe/wheel, Mox Diamond e land sacrifice ja tinham guardrails recentes.

Achado real corrigido neste ciclo:

- Criaturas com `land_tutor_activated` ainda sacrificavam a primeira land e
  buscavam a primeira land da biblioteca, ignorando os guardrails novos de
  land sacrifice/target scoring. Isso podia reintroduzir o problema de
  sacrificar fonte unica por alvo fraco.

## Mapa regra oficial x engine atual

| Area | Regra/fonte | Status atual | Evidencia local | Pendencia |
|---|---|---|---|---|
| Mulligan | CR 103.5c | Parcial bom | `play_mulligan`, `mulligan_evaluation`, `battle_turn_flow_tests.py` | Escolha das cartas que vao para o fundo ainda e aleatoria; precisa bottom-score |
| Prioridade | CR 117 | Basico bom | `priority_order_from`, `emit_priority_pass_sequence`, `run_priority_loop`, `battle_stack_casting_tests.py` | Sem escolha humana/interativa; respostas seguem heuristicas |
| Untap | CR 502/117.3a | Basico bom | `play_turn_v8`: nao chama prioridade no untap | Phasing retorna no bloco do untap/upkeep de forma simplificada |
| Upkeep | CR 503/117.3a | Parcial | Burden/The One Ring e alguns triggers especificos | Janela generica de upkeep/trigger choice ainda limitada |
| Draw | CR 504 | Basico bom | draw de turno, miracle/Lorehold, deck-out SBA | Efeitos de substituicao de draw card-specific continuam parciais |
| Main phases | CR 505/117 | Basico bom | `run_priority_loop(..., precombat_main/postcombat_main)` | Planejamento estrategico ainda heuristico |
| Beginning combat | CR 507 | Basico bom | `beginning_of_combat_step` + priority loop | Triggers/restrictions raras precisam corpus |
| Declare attackers | CR 508 | Parcial bom | `declare_attackers_step`, `apply_basic_attack_requirements` | Requirements/restrictions por defensor e custos de ataque complexos |
| Declare blockers | CR 509 | Parcial bom | `declare_blockers_step`, multi-block, evasao basica | Must-block/cannot-block-by-N e politicas avancadas |
| Combat damage | CR 510 | Basico bom | first strike, double strike, deathtouch, trample, lifelink, commander damage | Damage assignment choices ainda deterministicas, nao interativas |
| End combat | CR 511 | Basico bom | `end_of_combat_step`, APNAP triggers | Triggers raras/aninhadas continuam corpus-driven |
| End step | CR 513 | Parcial | end-step draw engines, warp, instants de oponentes | Prioridade/end-step interaction ainda simplificada por limite 1 instant por oponente |
| Cleanup | CR 514/514.3a | Basico | descarte ate 7, clear EOT, SBA final | Excecao 514.3a com nova prioridade/repeticao de cleanup nao modelada por completo |
| Commander | Oficial Commander | Basico bom | construction report, command zone replacement, tax, damage ledger | Partner/background UX/battle completo ainda parcial |

## Correcao aplicada

Arquivo:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`

Alteracao:

- `activate_land_tutor_creatures()` agora usa:
  - `choose_land_for_resource_cost()` para escolher a land a sacrificar;
  - `choose_land_ramp_targets()` para escolher a land alvo;
  - `land_sacrifice_has_strategic_benefit()` para bloquear gasto de land
    escassa sem beneficio claro.
- Quando a ativacao seria legal, mas estrategicamente ruim, o replay emite
  `activated_ability_skipped` com:
  - `reason`;
  - `land_options`;
  - `land_ramp_target_options`;
  - `strategic_risk_flags`;
  - `strategic_guardrail_reason`.
- Quando a ativacao ocorre, `activated_ability` passa a registrar:
  - land sacrificada;
  - target escolhido;
  - motivo de selecao;
  - riscos estrategicos;
  - beneficio estrategico.

Testes novos:

- `test_elvish_reclaimer_does_not_sacrifice_unique_color_for_tapped_basic`
- `test_elvish_reclaimer_prefers_redundant_tapped_land_for_high_value_target`

## Pendencias mantidas

### P1

- Bottom-card selection do London Mulligan: substituir escolha aleatoria por
  score de carta. Priorizar colocar no fundo cartas off-plan, custo alto,
  redundantes, off-color ou de baixa utilidade na curva inicial.
- Registrar rejected reasons mais ricos para spells jogaveis nao conjuradas.
- Ampliar decision trace de pass/no-action para todos os passes relevantes,
  diferenciando: sem opcao, segurando instant, recurso preservado, jogada ruim,
  risco de counter/removal e politica multiplayer.

### P2

- Cleanup 514.3a: modelar caso raro em que SBA/trigger no cleanup gera
  prioridade e novo cleanup.
- Upkeep generico: criar janela/trigger queue mais ampla sem hardcodar apenas
  burden/draw engine.
- Attack/block restrictions avancadas: custos de ataque, must-block,
  cannot-block-by-N, requisitos por defensor, planeswalkers/battles.
- Threat assessment por player/permanent para respostas, combate e tutor.

### P3

- Persistir decision traces em SQLite Hermes quando o schema estabilizar.
- Promover estatisticas de decisao para PostgreSQL apenas depois de
  estabilidade, revisao e contrato backend-owned.

## Validacoes executadas

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_summoning_sickness_tests.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

Resultado: suite focada passou, incluindo regressao completa do battle v9.

## Conclusao

A logica de battle esta coerente para seguir evoluindo como simulador Commander
heuristico/auditavel, nao como judge engine completo. A pendencia concreta
encontrada nesta auditoria foi corrigida. Os proximos ganhos reais estao em
decision quality: bottom-card selection, pass reasons, threat assessment e
cleanup/upkeep edge cases.
