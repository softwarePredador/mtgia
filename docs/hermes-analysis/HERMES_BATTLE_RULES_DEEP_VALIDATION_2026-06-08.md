# Hermes Battle Rules Deep Validation - 2026-06-08

## Objetivo

Validar e endurecer regras basicas de MTG no engine ativo `battle_analyst_v9.py`, principalmente:

- criaturas atacam/tapam corretamente;
- enjoo de invocacao impede ataque e mana abilities com `{T}`;
- haste libera ataque no turno em que a criatura entra;
- vigilance ataca sem tapar;
- keywords importadas nao podem ser aplicadas fora de contexto;
- permanentes com habilidades ativadas nao podem virar spell gratuita;
- cartas heuristicas usadas em replay real nao podem ficar em `needs_review`.

Referencia normativa: Wizards Comprehensive Rules (`https://magic.wizards.com/en/rules`).

## Correcoes feitas

- `card_has_keyword()` e `enrich_card()` agora so aplicam keyword propria quando:
  - existe campo booleano explicito;
  - a primeira linha do oracle e uma lista de keyword abilities propria, como `Flying, vigilance`;
  - ou a carta foi marcada explicitamente como metadata manual confiavel.
- `prepare_entering_permanent()` padroniza permanentes que tambem sao criaturas, mesmo quando o efeito principal e engine/ramp/draw/copy.
- Permanentes com texto ativado contendo `destroy target` ou `exile target` nao sao mais normalizados como remocao imediata, salvo efeito manual/removal explicito.
- Engine creatures agora entram com `summoning_sick`, `tapped=false`, `haste` real e power/toughness coerentes.
- Cartas curadas para substituir heuristicas em replay:
  - `Counterspell`
  - `Nature's Claim`
  - `Formidable Speaker`
  - `Soul-Guide Lantern`
  - `Open the Omenpaths`
  - `Jaxis, the Troublemaker`
  - `Jin-Gitaxias, Progress Tyrant`
  - `Mirrormade`
  - `Nezahal, Primal Tide`
  - `Ugin, Eye of the Storms`
  - `Squee, the Immortal`
  - `Fierce Empath`
  - `Rionya, Fire Dancer`
  - `Cursed Mirror`
  - `Mystic Forge`

## Testes executados

Comandos locais:

```powershell
python docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
python -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py
```

Resultado:

- suite `test_battle_analyst_v10_3.py`: PASS em todos os casos;
- `py_compile`: PASS;
- regras especificas cobertas por regressao:
  - criatura doente nao ataca;
  - criatura perde enjoo no turno correto e tapa para atacar;
  - criatura com haste ataca doente e tapa;
  - criatura com vigilance ataca sem tapar;
  - engine creature entra doente;
  - token nasce doente salvo token haste;
  - mana creature respeita enjoo;
  - keyword contextual `haste` nao vira haste propria;
  - artefato com remocao ativada nao vira remocao gratuita.

## Auditoria forense de replays

Comandos principais:

```powershell
$env:MANALOOM_KNOWLEDGE_DB=(Resolve-Path 'docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db').Path
$env:MANALOOM_KNOWLEDGE_DIR=(Resolve-Path 'docs/hermes-analysis/manaloom-knowledge').Path
python docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py --generate 20 --seed 920 --sqlite-db $env:MANALOOM_KNOWLEDGE_DB --report --json-report docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_local_20260608_rules_deep_seed920_939_after_keyword_hardening.json --fail-on-high
python docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py --generate 20 --seed 940 --sqlite-db $env:MANALOOM_KNOWLEDGE_DB --report --json-report docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_local_20260608_rules_deep_seed940_959_after_curations.json --fail-on-high
python docs/hermes-analysis/manaloom-knowledge/scripts/battle_forensic_audit.py --generate 10 --seed 960 --sqlite-db $env:MANALOOM_KNOWLEDGE_DB --report --json-report docs/hermes-analysis/master_optimizer_reports/battle_forensic_audit_local_20260608_rules_deep_seed960_969_after_curations.json --fail-on-high
```

Resultado final:

- seeds 920-939: 20 replays, 5.504 eventos estruturados, 268 cartas vistas, 0 findings;
- seeds 940-959: 20 replays, 5.230 eventos estruturados, 251 cartas vistas, 0 findings;
- seeds 960-969: 10 replays, 2.626 eventos estruturados, 211 cartas vistas, 0 findings.

Total desta bateria final: 50 replays, 13.360 eventos estruturados, 0 findings criticos/altos/medios/baixos.

## Limites honestos

Esta validacao nao transforma o Hermes em um juiz completo de MTG. O motor ficou mais seguro para o optimizer porque:

- nao aceita mais heuristica impactante sem promocao;
- nao inventa efeitos quando a semantica e complexa demais;
- captura erros basicos de turno/combat/keyword em teste e replay.

Ainda precisam de modelagem dedicada se forem relevantes para swaps:

- habilidades ativadas complexas com custos/timing especificos;
- replacement effects e triggers condicionais profundas;
- efeitos de copia permanentes/temporarios mais fieis;
- planeswalkers completos;
- loops/combo lines que exigem prioridade e escolhas multi-etapa.
