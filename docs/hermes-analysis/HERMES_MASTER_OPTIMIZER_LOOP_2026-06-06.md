# Hermes Master Optimizer Loop — Battle + Optimizer com maestria

> Objetivo: transformar o Hermes em um ciclo confiavel de otimizacao por evidencia:
> simular, detectar erro, propor swap, testar isolado, confirmar em massa, validar regras,
> aplicar somente se aprovado e documentar o motivo.

## Estado atual

O battle ja passou da fase de bugs basicos. Existem testes cobrindo:

- cleanup/discard com mao acima de 7;
- fim imediato de jogo por Approach of the Second Sun;
- evento estruturado de combate;
- mana colorida real;
- multiplos bloqueadores;
- trample;
- deathtouch;
- first strike;
- double strike + trample;
- enriquecimento via `card_oracle_cache`.

Validacao operacional em Hermes, 2026-06-06:

- `sync_pg_card_metadata_to_hermes.py` aplicado no SQLite do container.
- `card_oracle_cache` criado com 1269 aliases.
- `master_optimizer_loop.py --preflight --report` aprovado no container.
- Relatorio salvo em `docs/hermes-analysis/master_optimizer_reports/master_optimizer_preflight_hermes_20260606_234524.md`.

Validacao operacional do cron em Hermes, 2026-06-07:

- Job registrado em `/opt/data/cron/jobs.json` como `manaloom-master-optimizer-preflight`.
- Script instalado em `/opt/data/scripts/manaloom-master-optimizer-preflight.sh`.
- Origem versionada em `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_preflight_cron.sh`.
- Schedule atual: `every 20m`.
- Status do scheduler apos validacao manual: `ok`.
- Proxima execucao registrada apos ajuste: `2026-06-07T00:28:16.898797+00:00`.
- Relatorio fresco salvo em `docs/hermes-analysis/master_optimizer_reports/master_optimizer_preflight_cron_hermes_20260607_000346.md`.
- Artefato vivo no container: `/opt/data/artifacts/hermes_master_optimizer/latest_master_optimizer_preflight.md`.

Importante: este cron nao aplica swaps. Ele mantem o Hermes pronto para entrar no optimizer ao validar regressao do battle, sincronizar metadata do Postgres real para o SQLite e registrar se o ambiente esta aprovado ou bloqueado.

Cron auxiliar de swap/slot scan:

- Job registrado em `/opt/data/cron/jobs.json` como `manaloom-master-optimizer-slot-scan`.
- Script: `/opt/data/scripts/manaloom-master-optimizer-slot-scan.sh`.
- Origem versionada: `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_slot_scan_cron.sh`.
- Funcao: rodar sync de metadata, preflight e `slot_optimizer.py`.
- Seguranca: usa `slot_optimizer.py` porque ele testa swaps isolados e restaura o deck; nao usa `universal_optimizer.py` como cron automatico porque ele ainda possui auto-apply de swaps.
- Estado atual: `paused`, `enabled=false`.
- Motivo: ativar apenas quando o baseline estiver aprovado, porque o slot scan e pesado e pode durar horas.
- Schedule preparado: `every 720m`.
- Artefato esperado: `/opt/data/artifacts/hermes_master_optimizer/latest_master_optimizer_slot_scan.log`.

Validacao end-to-end real em Hermes, 2026-06-07:

- Pipeline instalado como `/opt/data/scripts/manaloom-master-optimizer-end-to-end.sh`.
- Job registrado como `manaloom-master-optimizer-end-to-end`, em modo `paused`, manual-only.
- Sync de metadata expandido para incluir `known_cards_generated.json`, `slot_benchmarks` e `swap_benchmarks`.
- `card_oracle_cache` subiu para 2479 aliases; `mana_cost_filled=2228`; `oracle_text_filled=2478`; `keywords_filled=1121`.
- Baseline real curto congelado: `45.0%` WR, `27W/31L/2S`, 60 jogos.
- Quality gate bloqueou candidatos fora da identidade RW e liberou candidatos Boros/legais.
- `Sticky Fingers` por `Storm-Kiln Artist` passou na confirmacao curta e na `full_confirmation`.
- Full confirmation real: `55.8%` WR, `67W/53L/0S`, delta `+10.8pp`, 120 jogos.
- Relatorio: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_confirmation_hermes_20260607_041142.md`.
- Handoff: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_handoff_hermes_20260607_041200.md`.
- O deck foi restaurado apos os testes de scan/confirmacao: nenhuma mutacao permanente ocorreu nessas fases.

Validacao de apply manual seguro em Hermes, 2026-06-07:

- Script `master_optimizer_apply.py` criado com rollback antes de alterar deck.
- Apply real executado apenas no SQLite local do Hermes, sem mutar banco de producao.
- Swap aplicado: `Sticky Fingers` entrou sobre `Storm-Kiln Artist`.
- Confirmacao usada para aprovar: `55.8%` WR, delta `+10.8pp`, `67W/53L/0S`, 120 jogos.
- Hash antes: `a5adcf8e0bb65cb293ff375320ff41b3c3a6162e60498effdc1be1b0d6f8a84e`.
- Hash depois: `4af984e0cea47c781321a9fe4e99f579d02f70dd2a5f8c980c94463abd5563ee`.
- Estado do deck apos apply: 100 cartas, 35 lands, CMC medio 2.5.
- Verificacao direta no deck: `Sticky Fingers` presente com count `1`; `Storm-Kiln Artist` ausente com count `0`.
- Verificacao direta em `swap_benchmarks`: linha `full_confirmation` marcada como `applied=1`.
- Rollback gerado no servidor: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/master_optimizer_rollback_20260607T041841557329+0000.json`.
- Rollback nao versionado localmente porque contem decklist completa.
- Relatorio local: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_apply_hermes_20260607_041841.md`.

Validacao pos-apply em Hermes, 2026-06-07:

- Baseline novo rodado apos a mutacao: baseline id `3`.
- Total: 120 jogos contra 12 oponentes reais aprendidos.
- Resultado pos-apply: `47.5%` WR, `57W/63L/0S`.
- Deck continua valido: 100 cartas, 35 lands, CMC medio 2.5.
- Relatorio local: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_post_apply_baseline_hermes_20260607_041859.md`.

Importante: nao houve apply automatico. O apply feito foi manual, com rollback, usando apenas swap aprovado por full confirmation. Nenhum banco de producao foi alterado.

Arquivos principais:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

## O que ainda falta no battle

1. Validacao massiva com decks reais, nao apenas testes unitarios.
2. Analise automatica de replay para detectar jogadas ruins.
3. Melhor heuristica de prioridade:
   - quando atacar;
   - quando segurar bloqueador;
   - quando gastar removal;
   - quando gastar counter;
   - quando tutorizar;
   - quando preservar wincon.
4. Relatorio por partida com motivo de vitoria/derrota.
5. Metricas persistidas por matchup:
   - winrate;
   - turnos ate vitoria;
   - cartas mortas na mao;
   - screw/flood;
   - dano perdido por ataque ruim;
   - spells relevantes seguradas ou gastas cedo demais.

## O que falta para o optimizer ficar excelente

O optimizer nao deve apenas testar carta por carta. Ele precisa de cinco camadas:

1. Baseline confiavel do deck atual.
2. Teste isolado por slot.
3. Confirmacao estatistica dos candidatos promissores.
4. Quality gate estrutural antes de aplicar.
5. Handoff explicavel para humano/agente.

## Regras obrigatorias

- Nunca aplicar swap automaticamente na fase quick.
- Nunca aplicar swap sem baseline salvo.
- Nunca aplicar swap com menos de 2 rodadas de confirmacao.
- Nunca cortar comandante, land essencial, wincon primaria, protecao critica ou carta travada por regra do plano.
- Sempre restaurar o deck apos teste isolado.
- Sempre gerar relatorio antes de aplicar.
- Sempre rodar regressao do battle antes de otimizar.
- Sempre rodar `sync_pg_card_metadata_to_hermes.py` antes de long-run quando o cache estiver desatualizado.

## Fluxo mestre

### Fase 0 — Preflight

Comando:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py --preflight --report
```

O preflight deve validar:

- `knowledge.db` existe;
- tabelas essenciais existem;
- `battle_analyst_v8.py` compila;
- `test_battle_analyst_v10_3.py` passa;
- `card_oracle_cache` existe;
- cobertura minima de metadata esta aceitavel;
- `slot_optimizer.py` e `universal_optimizer.py` existem.

### Fase 1 — Baseline

Rodar battle sem swaps e salvar:

- winrate geral;
- matchups;
- turnos;
- mulligan/mana;
- motivo das derrotas.

O baseline deve ser imutavel durante uma rodada de teste.

### Fase 2 — Slot scan

Usar `slot_optimizer.py` para testar candidato isolado por categoria.

Regra:

- swap entra;
- battle roda;
- resultado e salvo;
- swap sai;
- deck volta ao baseline.

Nenhuma aplicacao permanente nesta fase.

### Fase 3 — Confirmacao

Pegar apenas candidatos com ganho real e rodar mais jogos.

Criterios minimos recomendados:

- quick: candidato nao pode ficar abaixo de `baseline - 2pp`;
- full: candidato precisa ficar pelo menos `+0.5pp`;
- master: candidato precisa passar quality gate estrutural e nao piorar papel critico.

### Fase 4 — Quality gate

Antes de aplicar qualquer swap, validar:

- numero de cartas;
- numero de lands;
- curva;
- CMC seguro;
- identidade de cor;
- bracket;
- Game Changers;
- funcoes criticas;
- plano do commander;
- nao piorar mana colorida.

### Fase 5 — Aplicacao

Aplicar somente se:

- passou no full test;
- passou no quality gate;
- tem explicacao objetiva;
- nao contradiz o plano do deck;
- nao aumenta fragilidade sem ganho claro.

### Fase 6 — Replay audit

Depois de aplicar, gerar replays novos e procurar:

- ataque perdido;
- bloqueio ruim;
- spell desperdicada;
- counter mal usado;
- wincon ignorada;
- tutor sem alvo correto;
- mana mal gasta.

Se o replay mostrar decisao ruim, o problema volta para o battle, nao para o optimizer.

## Criterios de aprovacao

Um pacote de otimizacao so fica aprovado quando tiver:

- preflight verde;
- baseline salvo;
- pelo menos uma rodada quick;
- confirmacao full para swaps aprovados;
- quality gate verde;
- replay audit sem erro critico;
- relatorio final com antes/depois.

## Comando para agentes

Use este prompt no Copilot/Codex:

```text
Use o Hermes Master Optimizer Loop. Primeiro rode o preflight com relatorio.
Se passar, rode baseline do battle, slot scan isolado e confirmacao full para os candidatos promissores.
Nao aplique swaps automaticamente. Gere handoff com winrate, delta, motivo de cada swap, riscos, replays auditados e proximas correcoes do battle.
Se encontrar erro de decisao no replay, pare a otimizacao e abra tarefa de fix no battle_analyst_v8.py com teste novo em test_battle_analyst_v10_3.py.
```

## Proximo passo tecnico recomendado

Criar o analisador de replay:

```text
replay_decision_auditor.py
```

Responsabilidades:

- ler replay estruturado;
- marcar decisoes ruins;
- classificar severidade;
- sugerir teste de regressao;
- impedir que o optimizer aplique swap baseado em battle com decisao obviamente ruim.
