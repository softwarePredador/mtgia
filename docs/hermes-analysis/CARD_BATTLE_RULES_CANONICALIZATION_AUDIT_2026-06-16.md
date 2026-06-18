# Card Battle Rules Canonicalization Audit - 2026-06-16

## Objetivo

Validar se o runtime atual do battle/Hermes ainda depende de overrides manuais
em `HANDCRAFTED_KNOWN_CARDS` para regras que deveriam estar canonicamente em
PostgreSQL `card_battle_rules`.

Este audit e report-only. Nao escreve em PostgreSQL nem em SQLite.

## Ferramenta

Script novo:

- `docs/hermes-analysis/manaloom-knowledge/scripts/audit_handcrafted_battle_rule_canonicalization.py`

Teste focado:

- `docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_handcrafted_battle_rule_canonicalization.py`

Artefatos da rodada local:

- `server/test/artifacts/handcrafted_battle_rule_canonicalization_2026-06-16/summary.json`
- `server/test/artifacts/handcrafted_battle_rule_canonicalization_2026-06-16/summary.md`

## Resultado da primeira rodada

Contagem total:

- `486` overrides manuais em `HANDCRAFTED_KNOWN_CARDS`
- `469` classificados como `card_rule_promotable`
- `17` classificados como `temporary_hotfix`
- `0` `engine_primitive` nesta rodada inicial

Estado contra PostgreSQL:

- `456` com `pg_state=exact_match`
- `30` com `pg_state=drift`

Estado contra SQLite Hermes:

- `452` com `sqlite_state=exact_match`
- `34` com `sqlite_state=drift`

Ação recomendada agregada:

- `452` `already_canonicalized`
- `30` `reconcile_pg_rule`
- `4` `refresh_sqlite_from_pg`

## Leitura correta

O problema existe, mas nao esta espalhado por toda a base manual. A maior parte
dos overrides ja bate com o PostgreSQL e com o cache SQLite. O problema real
esta concentrado em dois blocos:

1. hotfixes recentes que estabilizaram o runtime mas ainda nao foram
   reconciliados no PG/SQLite;
2. um conjunto pequeno de regras promotiveis antigas que estao em drift entre
   codigo e `card_battle_rules`.

Isso confirma a decisao arquitetural:

- override manual em codigo pode ser usado como contenção rapida;
- nao pode ser tratado como estado final;
- `card_battle_rules` deve voltar a ser a fonte canonica efetiva.

## Fila imediata - hotfixes que precisavam sair do codigo

Os `17` `temporary_hotfix` detectados ficaram todos em `pg_state=drift` e
`sqlite_state=drift`:

- `Ancient Den`
- `Ancient Tomb`
- `Birgi, God of Storytelling`
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty`
- `Chrome Mox`
- `Electroduplicate`
- `Everflowing Chalice`
- `Gemstone Caverns`
- `Great Furnace`
- `Hall of Heliod's Generosity`
- `Inventors' Fair`
- `Lightning Greaves`
- `Sunbaked Canyon`
- `Urza's Saga`
- `Valakut Awakening`
- `Valakut Awakening // Valakut Stoneforge`
- `War Room`

Essas cartas eram a primeira fila de canonizacao no PostgreSQL.

## Resultado da segunda rodada

Depois do sync seletivo PG -> SQLite para os `17` hotfixes:

- `486` overrides manuais em `HANDCRAFTED_KNOWN_CARDS`
- `486` classificados como `card_rule_promotable`
- `0` `temporary_hotfix`
- `473` com `pg_state=exact_match`
- `13` com `pg_state=drift`
- `469` com `sqlite_state=exact_match`
- `17` com `sqlite_state=drift`
- `469` `already_canonicalized`
- `13` `reconcile_pg_rule`
- `4` `refresh_sqlite_from_pg`

Interpretacao correta da segunda rodada:

- os `17` hotfixes recentes ja foram reconciliados no PostgreSQL;
- o cache SQLite local consumido pelo runtime tambem recebeu essas `17` regras;
- o bloco restante nao e mais "hotfix urgente", e sim drift antigo promotivel.

## Resultado da terceira rodada

Foi tentada a promocao automatica dos `13` drifts legados restantes, mas surgiu
um bug estrutural no sync:

- `sync_battle_card_rules.py` aplicava `normalize_effect_by_oracle()` tambem em
  regras `source='manual'`;
- isso degradava a semantica canônica antes de gravar em PG/SQLite;
- exemplos observados:
  - `Aether Spellbomb`: `passive` virava `remove_permanent`
  - `Momentary Blink` / `Turn to Mist`: `phase_creatures` virava
    `remove_creature`
  - `Rise of the Eldrazi`: `extra_turn` virava `remove_permanent`

O bug foi corrigido: oracle normalization agora ocorre apenas em regras
`generated`. Regras `manual` sao persistidas exatamente como estao em
`HANDCRAFTED_KNOWN_CARDS`.

Depois da correcao:

- os `13` drifts legados foram promovidos novamente para PG/SQLite;
- os `4` casos `refresh_sqlite_from_pg` foram atualizados;
- o auditor final fechou em:
  - `486` `pg_state=exact_match`
  - `486` `sqlite_state=exact_match`
  - `486` `already_canonicalized`

## Prova runtime do fallback canonico

Havia um falso negativo local: `battle_analyst_v9.py` apontava por default para
`/opt/data/workspace/.../knowledge.db`, entao o runtime do Mac local nao
enxergava o `knowledge.db` real do repositorio e qualquer teste de fallback
retornava `_rule_source=unknown`.

Isso foi corrigido no proprio runtime:

- primeiro respeita `MANALOOM_KNOWLEDGE_DB` e `MANALOOM_KNOWLEDGE_DIR`;
- se o path remoto `/opt/...` existir, usa ele;
- senao cai para `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
  e `docs/hermes-analysis/manaloom-knowledge`.

Com esse ajuste, o teste focado
`test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` passou e provou que as
cartas canonizadas resolvem via SQLite/PG mesmo sem o override manual em
`KNOWN_CARDS`.

Esse teste tambem foi acoplado ao regression pack principal
`test_battle_analyst_v10_3.py`, virando guard rail continuo do simulador.

Na rodada final ele cobre:

- os `17` hotfixes recentes;
- os `13` drifts legados promotiveis;
- os `4` casos que exigiam apenas refresh do SQLite.

## Runtime canônico efetivo

O `battle_analyst_v9.py#get_card_effect()` foi invertido para usar a ordem:

1. waiver manual-first explicito (`MANUAL_RULE_RUNTIME_WAIVERS`);
2. SQLite/PG `card_battle_rules`;
3. fallback manual `HANDCRAFTED_KNOWN_CARDS`;
4. fallback generated/tags heuristicas.

Estado atual:

- `MANUAL_RULE_RUNTIME_WAIVERS` existe e esta vazio por padrao;
- o banco passou a ser a fonte canônica efetiva do runtime;
- override manual-first so acontece se alguem registrar waiver explicitamente.

Isso muda o status da tratativa:

- a canonizacao de dados para essas `17` cartas esta validada;
- o gap restante e de precedencia/limpeza de runtime, nao de ausencia de regra.

## Fila secundária - regras promotiveis em drift

As regras abaixo nao sao hotfixes recentes, mas o auditor marcou drift entre o
override manual e o `card_battle_rules` vigente:

- `Aether Spellbomb`
- `Eldrazi Confluence`
- `Emerald Charm`
- `Feed the Swarm`
- `Hullbreaker Horror`
- `Momentary Blink`
- `Rise of the Eldrazi`
- `Scour for Scrap`
- `Sink into Stupor`
- `Snap`
- `Snapback`
- `Surge to Victory`
- `Turn to Mist`

Essas entradas devem ser reconciliadas depois do pacote hotfix.

## Drift somente no SQLite

Quatro cartas ja estavam corretas no PostgreSQL mas ainda divergiam no cache
SQLite antes do refresh seletivo:

- `Crop Rotation`
- `Harrow`
- `Mox Diamond`
- `Roiling Regrowth`

Aqui a acao correta continua sendo refresh do cache SQLite a partir do PG.

## Resultado da quarta rodada - primeira limpeza do código

Depois de validar a precedencia PG-first e o bootstrap deterministico do
`knowledge.db`, foi executado o primeiro lote seguro de limpeza do runtime:

- `34` cartas ja canonizadas foram removidas de `KNOWN_CARDS` /
  `HANDCRAFTED_KNOWN_CARDS`;
- o regression guard
  `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` foi reescrito para
  provar o comportamento novo:
  - a carta nao pode estar em `HANDCRAFTED_KNOWN_CARDS`;
  - a carta precisa existir no registry SQLite/PG;
  - `get_card_effect()` precisa resolver o mesmo `logical_rule_key` do registry;
- o regression pack principal `test_battle_analyst_v10_3.py` continuou verde;
- o auditor pos-limpeza fechou em:
  - `452` overrides manuais restantes em `HANDCRAFTED_KNOWN_CARDS`
  - `452` `pg_state=exact_match`
  - `452` `sqlite_state=exact_match`
  - `452` `already_canonicalized`

O lote removido do código foi:

- hotfixes reconciliados: `Ancient Den`, `Ancient Tomb`,
  `Birgi, God of Storytelling`,
  `Birgi, God of Storytelling // Harnfel, Horn of Bounty`, `Chrome Mox`,
  `Electroduplicate`, `Everflowing Chalice`, `Gemstone Caverns`,
  `Great Furnace`, `Hall of Heliod's Generosity`, `Inventors' Fair`,
  `Lightning Greaves`, `Sunbaked Canyon`, `Urza's Saga`,
  `Valakut Awakening`, `Valakut Awakening // Valakut Stoneforge`, `War Room`
- drifts legados promovidos: `Aether Spellbomb`, `Eldrazi Confluence`,
  `Emerald Charm`, `Feed the Swarm`, `Hullbreaker Horror`, `Momentary Blink`,
  `Rise of the Eldrazi`, `Scour for Scrap`, `Sink into Stupor`, `Snap`,
  `Snapback`, `Surge to Victory`, `Turn to Mist`
- casos SQLite refresh-only: `Crop Rotation`, `Harrow`, `Mox Diamond`,
  `Roiling Regrowth`

## Próximo slice recomendado

1. Adicionar guard rail impedindo nova carta promotivel de ficar so no codigo
   sem waiver explicito.
2. Continuar removendo do runtime apenas as cartas que ja tenham prova de
   bootstrap deterministico via registry.
3. Manter em codigo apenas primitivas reais do motor e hotfixes com waiver
   temporal explicito.

## Resultado da quinta rodada - inventario manual ativo zerado

Depois do primeiro lote seguro, o runtime ainda mantinha `452` entradas
canonizadas como snapshot manual inerte. A quinta rodada encerrou a tratativa
operacional:

- `HANDCRAFTED_KNOWN_CARDS` e zerado imediatamente apos o import;
- `KNOWN_CARDS` remove do runtime ativo todas as entradas historicas
  canonizadas antes de carregar `known_cards_generated.json`;
- regras manuais so reaparecem quando um teste ou incidente injeta
  explicitamente um waiver em `HANDCRAFTED_KNOWN_CARDS` +
  `MANUAL_RULE_RUNTIME_WAIVERS`;
- `sync_battle_card_rules.py --skip-generated` passou a produzir `0` linhas
  manuais no estado normal;
- o auditor final pos-remocao total do inventario ativo fechou em:
  - `handcrafted_count=0`
  - classificacoes vazias
  - `pg_error=null`

Artefatos finais desta rodada:

- `server/test/artifacts/handcrafted_battle_rule_canonicalization_2026-06-16/summary_after_full_manual_inventory_removal.json`
- `server/test/artifacts/handcrafted_battle_rule_canonicalization_2026-06-16/summary_after_full_manual_inventory_removal.md`

Prova de seguranca:

- `test_runtime_pg_rule_fallback_for_promoted_hotfixes.py` agora valida tanto
  `HANDCRAFTED_KNOWN_CARDS == set()` quanto a resolucao canonical via
  SQLite/PG.
- `test_battle_analyst_v10_3.py` permaneceu 100% verde nesse estado.

Estado final desta atividade:

- inventario manual ativo removido do runtime;
- PostgreSQL/SQLite viraram a unica fonte normal de regras executaveis;
- fallback manual ficou reduzido a mecanismo de waiver explicito.

## Comandos da rodada

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/audit_handcrafted_battle_rule_canonicalization.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_audit_handcrafted_battle_rule_canonicalization.py

cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts
python3 test_audit_handcrafted_battle_rule_canonicalization.py

cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
mkdir -p server/test/artifacts/handcrafted_battle_rule_canonicalization_2026-06-16
python3 docs/hermes-analysis/manaloom-knowledge/scripts/audit_handcrafted_battle_rule_canonicalization.py \
  --report-json server/test/artifacts/handcrafted_battle_rule_canonicalization_2026-06-16/summary.json \
  --report-md server/test/artifacts/handcrafted_battle_rule_canonicalization_2026-06-16/summary.md
```
