# Hermes Master Optimizer Loop — Battle + Optimizer com maestria

> Status atual: diario tecnico e historico de evidencias.
> Para contrato operacional completo de scripts, bancos, tabelas, parametros e
> guardrails, use `HERMES_E2E_SYSTEM_CONTRACT_2026-06-07.md`.
> Nao use um resultado antigo deste arquivo como autorizacao de apply sem
> revalidar contra o SQLite vivo.

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

Hardening final em Hermes, 2026-06-07:

- Replay turno-a-turno implementado via eventos JSONL em `battle_replay_v10_3.py`.
- `replay_decision_auditor.py` agora gera replays frescos e audita decisoes de combate, removal, tutor, cleanup, Approach e encerramento.
- Auditoria fresca com 3 replays: 895 eventos estruturados, 0 findings turno-a-turno.
- Relatorio local: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_replay_audit_20260607_081614.md`.
- Heuristica de combate corrigida: alvo default agora prioriza vida baixa/ameaca, nao maior vida.
- Heuristica de removal corrigida: removal agora prioriza comandante/maior poder, nao alvo aleatorio.
- `kc_validator.py` agora grava fila de conflitos em Markdown/JSON.
- Validacao KC final: 1970 cartas validadas, 3 correcoes automaticas, 0 conflitos para revisao.
- Relatorio KC final: `docs/hermes-analysis/kc_validator_reports/kc_validator_conflicts_20260607_125916.md`.
- `kc_validator.py` passou a aceitar `KC_VALIDATOR_CHECK_LIMIT=0` para auditoria completa e usa overrides manuais documentados para cartas cuja leitura simplificada do simulador precisa ser deterministica.
- Jobs de agente bloqueados por provider 429 foram inicialmente pausados com backup de `/opt/data/cron/jobs.json`.
- Relatorio provider backoff: `docs/hermes-analysis/master_optimizer_reports/hermes_provider_backoff_20260607_081300.md`.
- Provider foi migrado para `deepseek-pro` com modelo funcional `deepseek-v4-pro` e endpoint `https://opencode.ai/zen/go/v1`.
- O valor literal `opencode` foi testado como modelo e falhou com `HTTP 404`; ele nao deve ser usado como model id.
- Prova provider: `manaloom-hermes-normal-audit` terminou `ok` em `2026-06-07T12:49:11.907701+00:00`.
- Relatorio provider: `docs/hermes-analysis/master_optimizer_reports/hermes_provider_deepseek_pro_20260607_124911.md`.
- Handoff separado para produto criado via `master_optimizer_product_handoff.py`.
- Handoff produto gerado com status `needs_product_owner_approval`; nenhuma mutacao de producao foi feita.
- Relatorio produto: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_product_handoff_20260607_081454.md`.
- Preflight final aprovado: `docs/hermes-analysis/master_optimizer_reports/master_optimizer_preflight_20260607_081631.md`.

Hardening de stale-target em Hermes, 2026-06-07:

- Auditoria criada para pacote Lorehold `86.0%` WR com suspeita de targets stale.
- Artefatos locais: `docs/hermes-analysis/master_optimizer_reports/lorehold_stale_target_audit_20260607/`.
- Prova direta no SQLite real: deck id `6` tem 100 cartas, 33 lands, CMC medio `2.913` e hash `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`.
- Prova direta no SQLite real: `Mana Geyser`, `Blasphemous Act` e `Storm-Kiln Artist` ainda estao presentes.
- Prova direta no SQLite real: `Sticky Fingers`, `Decree of Pain`, `Academy Manufactor`, `Assassin's Trophy`, `Adrix and Nev, Twincasters` e `Damning Verdict` estao ausentes.
- `swap_benchmarks` agora e criado por `ensure_optimizer_tables()`, removendo falha de inicializacao em bancos que ainda nao tinham essa tabela.
- `candidate_rows()` agora aceita fases `best-in-slot` e `phase1`, que correspondem ao formato atual gravado pelo slot scan.
- `quality_gate`, `confirmation`, `handoff` e `apply` agora bloqueiam quando o hash atual do deck nao bate com o hash do ultimo baseline aprovado.
- `temporary_swap()` agora falha imediatamente se o alvo de corte nao existe ou se a carta de entrada ja esta no deck.
- Smoke real em SQLite temporario confirmou o bloqueio: apos remover `Mana Geyser` da copia temporaria, `master_optimizer_handoff.py` recusou gerar handoff por hash divergente.
- Resultado do smoke: `GUARDRAIL_SMOKE_OK`.

Validacao full-flow Lorehold em Hermes, 2026-06-07:

- Rodada real executada no container `d5fe57bf9de2`.
- Artefatos locais: `docs/hermes-analysis/master_optimizer_reports/lorehold_full_flow_20260607_144021/`.
- O `slot_optimizer.py` legado foi interrompido porque testava cartas off-color e deixou uma mutacao parcial no SQLite.
- Mutacao parcial corrigida: `Chaos Warp` removido e `Deflecting Swat` restaurado.
- Hash do deck restaurado e validado: `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`.
- `slot_optimizer.py` foi substituido por scan seguro: filtra identidade de cor, exige legalidade Commander explicita, usa `run_battle()` temporario e grava `deck_id`, `baseline_id` e `baseline_hash`.
- Baseline fresco id `3`: `87.0%` WR, `261W/10L/29S`, 300 jogos.
- Slot scan seguro: 120 candidatos legais testados; 851 candidatos off-color filtrados.
- Full confirmation: `Fork` sobre `Past in Flames` passou com `88.0%` WR, delta `+1.0pp`, `264W/6L/30S`.
- Full confirmation: `Harness the Storm` sobre `Past in Flames` passou com `88.0%` WR, delta `+1.0pp`, `264W/8L/28S`.
- `Expedition Map`, `Lotus Bloom` e `Astral Cornucopia` nao passaram o corte de aprovacao final.
- Replay audit inicialmente apontou falsos positivos de board wipe.
- `battle_analyst_v8.py` agora emite `creatures_seen` e `unprotected_seen` em `board_wipe_resolved`.
- `replay_decision_auditor.py` agora bloqueia board wipe apenas quando havia criatura desprotegida e zero foram destruidas.
- Replay audit fresco apos correcoes: `turn_by_turn_clean`, 1334 eventos estruturados, 0 findings turno-a-turno.
- Handoff final: `approved_swaps_ready_for_manual_apply`.
- Nenhum swap foi aplicado automaticamente.
- Como `Fork` e `Harness the Storm` cortam a mesma carta, apenas um deles pode ser aplicado sem nova rodada de baseline/confirmacao.

Revalidacao de `Fork` em Hermes, 2026-06-07:

- Artefatos locais: `docs/hermes-analysis/master_optimizer_reports/lorehold_fork_revalidation_20260607_153114/`.
- O SQLite Hermes atual nao tinha mais tabelas `optimizer_*`/`slot_benchmarks`/`swap_benchmarks`, entao a evidencia foi recriada antes de qualquer apply.
- Baseline fresco id `1`: `86.7%` WR, `260W/6L/34S`, 300 jogos.
- Slot scan focado em `engine` testou 15 candidatos legais sobre o corte `Past in Flames`.
- `Fork` revalidou com `86.7%` WR, delta `+0.0pp`, `260W/9L/31S`.
- `master_optimizer_apply.py` bloqueou corretamente o apply de `Fork` porque ele nao atingiu o delta minimo seguro de `+0.5pp`.
- Nenhuma mutacao foi feita: `Past in Flames` continua presente e `Fork` continua ausente.
- Confirmacao adicional encontrou candidato melhor: `Reversal of Fortune` sobre `Past in Flames`, `90.7%` WR, delta `+4.0pp`, `272W/4L/24S`.
- `Flare of Duplication` tambem passou: `89.0%` WR, delta `+2.3pp`, `267W/5L/28S`.
- `Underworld Breach` foi rejeitado/retest: `86.3%` WR, delta `-0.4pp`, alem de warning de Game Changer.
- Proxima decisao recomendada: escolher `Reversal of Fortune` se o objetivo for ganho medido; nao forcar `Fork` sem uma razao de design/deck owner.

Revalidacao de `Reversal of Fortune` em Hermes, 2026-06-07:

- Artefatos locais: `docs/hermes-analysis/master_optimizer_reports/lorehold_reversal_revalidation_20260607_154522/`.
- A evidencia foi recriada no SQLite Hermes atual antes de qualquer apply.
- Baseline fresco id `2`: `86.7%` WR, `260W/11L/29S`, 300 jogos.
- `Reversal of Fortune` nao reproduziu o ganho anterior: scan `83.3%`, full confirmation `85.3%`, delta `-1.4pp`, `256W/7L/37S`.
- `master_optimizer_apply.py` bloqueou corretamente o apply porque nao havia candidato aprovado com delta minimo seguro.
- Nenhuma mutacao foi feita: `Past in Flames` continua presente e `Reversal of Fortune` continua ausente.
- Rechecagem adicional encontrou apenas ganhos marginais: `Invoke Calamity` `+0.6pp` e `Restoration Seminar` `+0.6pp`.
- Estado recomendado: nao aplicar `Reversal of Fortune` com a evidencia atual; se ainda quiser otimizar o slot `Past in Flames`, rodar amostra maior para `Invoke Calamity`/`Restoration Seminar` ou ampliar o scan.

E2E corrigido + apply local seguro em Hermes, 2026-06-07:

- Artefatos locais: `docs/hermes-analysis/master_optimizer_reports/lorehold_e2e_apply_20260607_162220/`.
- Script instalado no Hermes: `/opt/data/scripts/manaloom-master-optimizer-end-to-end.sh`.
- Correcoes validadas no fluxo: E2E agora roda `slot_optimizer.py` e `full_confirmation` antes do handoff.
- Metadata sync: 2428 nomes solicitados, 2629 cartas Postgres correspondidas, 2501 aliases no SQLite, 2 unresolved.
- Preflight: `approved`.
- Baseline fresco id `3`: `85.3%` WR, `256W/10L/34S`, 300 jogos, hash `110ce10b8152085ec589ed09b15ab1e0c21a5656b60b366f59a34e369b2ff811`.
- Slot scan seguro: 120 candidatos testados, 851 off-color filtrados, 18 ilegais filtrados.
- Full confirmation aprovou:
  - `Cloudshift` sobre `Generous Gift`: `89.0%`, delta `+3.7pp`, mas nao aplicado por risco de role mismatch e reducao de removal/interacao.
  - `Wheel of Misfortune` sobre `Reforge the Soul`: `88.0%`, delta `+2.7pp`.
  - `Return the Favor` sobre `Past in Flames`: `87.7%`, delta `+2.4pp`.
- Replay audit pre-apply: `turn_by_turn_clean`, 1423 eventos estruturados, 0 findings turno-a-turno.
- Apply local Hermes executado apenas para `Wheel of Misfortune` sobre `Reforge the Soul`.
- Rollback gerado no servidor: `/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports/master_optimizer_rollback_20260607T162657677855+0000.json`.
- Hash apos apply: `12c55613ae4f7bcd4c934fae4253cfa75fcc4946352a18a61365835427e90c08`.
- Verificacao direta no SQLite Hermes: `Wheel of Misfortune` presente; `Reforge the Soul` ausente.
- Baseline pos-apply id `4`: `89.3%` WR, `268W/6L/26S`, 300 jogos, 33 lands, 100 cartas.
- Replay audit pos-apply: `turn_by_turn_clean`, 1303 eventos estruturados, 0 findings turno-a-turno.
- Handoff produto criado com status `needs_product_owner_approval`.
- Nenhum banco de producao/app foi alterado.

Importante: nao houve apply automatico. O apply feito foi manual, com rollback, usando apenas swap aprovado por full confirmation. Nenhum banco de producao foi alterado.

Hardening de oponentes reais em Hermes, 2026-06-07:

- Problema encontrado: `battle_analyst_v8.py` buscava apenas os 12 `learned_decks` mais recentes; esses registros recentes eram meta decks pequenos/incompletos com `card_list` de 69-88 bytes, entao o battle voltava para os 6 perfis genericos.
- Fonte real validada no Postgres: `meta_decks` contem 581 decks com `card_list` preenchido; `commander_reference_decks` contem 22 decks aceitos com 90+ cartas resolvidas; `commander_learned_decks` contem 5 decks ativos validos, alem de Lorehold.
- Novo script versionado: `sync_pg_meta_decks_to_hermes.py`.
- Contrato do novo sync: le `meta_decks` no Postgres real, converte decklists texto (`1 Card Name`) para JSON local e escreve somente no SQLite Hermes em `learned_decks` com `source='pg_meta_decks'`.
- Sync real aplicado no container: 120 decks PG importados para `learned_decks`, todos com pelo menos 80 cartas; amostra inclui Kinnan, Rograkh, Tayam, Thrasios, Umbris, Kenrith, Kefka e Najeela.
- `sync_pg_card_metadata_to_hermes.py` rerodado apos o sync: 3377 nomes solicitados, 3573 cartas Postgres correspondidas, 3464 aliases no `card_oracle_cache`, 10 unresolved.
- `battle_analyst_v8.py` agora prefere candidatos reais validos, ignora registros pequenos, remove comandante duplicado, monta comandante + 99, infere `land/ramp/removal/counter/draw/tutor/wincon` via `card_oracle_cache` e embaralha o pool por seed.
- Variacao controlada:
  - `MANALOOM_BATTLE_REAL_OPPONENT_CANDIDATES`, default `96`.
  - `MANALOOM_BATTLE_REAL_OPPONENT_LIMIT`, default `12`.
  - `MANALOOM_BATTLE_REAL_OPPONENT_MIN_CARDS`, default `80`.
  - `MANALOOM_BATTLE_REAL_OPPONENT_SEED`; se ausente, varia por hora UTC.
- `battle_replay_v10_3.py` agora sorteia os 3 oponentes do replay em vez de fixar sempre `source[0]`, e registra `Opponents picked`.
- Prova direta do battle: `MANALOOM_BATTLE_REAL_OPPONENT_LIMIT=6` rodou 300 jogos contra 6 oponentes reais PG e registrou `Using 6 REAL learned opponent decks`; resultado `57.3%` WR, `172W/126L/2S`.
- Prova do optimizer: baseline id `12`, 240 jogos contra 12 oponentes reais PG, `56.2%` WR, `135W/103L/2S`; relatorio `docs/hermes-analysis/master_optimizer_reports/master_optimizer_baseline_20260607_173227.md`.
- Prova de replay: `/opt/data/artifacts/hermes_master_optimizer/replay_real_opponents_20260607.txt` escolheu `Sisay, Weatherlight Captain`, `Urza, Lord High Artificer` e `Magda, Brazen Outlaw` como oponentes reais.
- Cron `/opt/data/scripts/manaloom-master-optimizer-auto-cycle.sh` atualizado no servidor para rodar `sync_pg_meta_decks_to_hermes.py --apply` antes de `sync_pg_card_metadata_to_hermes.py`, baseline e slot scan.
- Estado importante: a comparacao com baselines antigos mudou de dificuldade; os resultados contra perfis genericos nao devem ser comparados diretamente com os novos resultados contra decks reais PG.

Hardening de regras de battle em Hermes, 2026-06-07:

- Problema revisado: o battle ainda era um simulador heuristico, nao um rules engine completo; os pontos mais perigosos eram `miracle`, duracao de efeitos temporarios, `Boros Charm`, `Akroma's Will`, `silence_opponents` e `life_cant_change`.
- `Player.draw()` agora conta `cards_drawn_this_turn`.
- `play_turn_v8()` zera o contador no inicio do turno e `miracle` so pode disparar se a carta comprada foi a primeira compra real do turno.
- `miracle` continua exigindo `Lorehold, the Historian` em campo e mana suficiente; o simulador ainda escolhe automaticamente castar se puder pagar.
- `Boros Charm` em resposta a board wipe agora concede `indestructible` temporario as criaturas, em vez de apenas marcar `player.indestructible`.
- `Boros Charm` modo double strike nao dobra poder e passa a ser ate o fim do turno.
- `Akroma's Will` agora concede `flying`, `double_strike`, `lifelink` e `indestructible` ate o fim do turno e nao dobra poder.
- Sistema `until end of turn` criado com restauracao de atributos originais no cleanup.
- `silence_opponents` agora bloqueia counters/respostas dos oponentes contra spells do controlador e tambem bloqueia instants no end step do jogador ativo.
- `life_cant_change`/`protection_from_everything` agora bloqueiam dano e ganho de vida nos helpers de vida usados pelo battle.
- Testes adicionados em `test_battle_analyst_v10_3.py`:
  - miracle exige Lorehold em campo;
  - miracle dispara so na primeira compra do turno;
  - miracle nao dispara na segunda compra se houve draw no upkeep;
  - Boros Charm protege criaturas ate cleanup;
  - Akroma's Will limpa keywords no cleanup e nao muda poder permanentemente;
  - silence bloqueia counterspell;
  - life can't change bloqueia dano/ganho de vida.
- Validacao local: `python -m py_compile ...` aprovado e 31 testes passaram.
- Validacao Hermes container: `python3 test_battle_analyst_v10_3.py` aprovado com 31 testes.
- Smoke baseline Hermes: baseline id `13`, 15 jogos contra 3 oponentes reais, `73.3%` WR; relatorio `docs/hermes-analysis/master_optimizer_reports/master_optimizer_baseline_20260607_174845.md`.
- Batalha volumetrica Hermes: 300 jogos contra 6 oponentes reais, `64.3%` WR, `193W/103L/4S`.
- Replay estruturado Hermes: `/opt/data/artifacts/hermes_master_optimizer/replay_rules_hardening_20260607.txt`, com oponentes reais `Sisay`, `Urza` e `Magda`.
- Ainda nao e rules engine 100% MTG: custos modais completos, todos os tipos de replacement/prevention effects, escolha humana de miracle, alvo modal exato e todas as camadas de continuous effects continuam simplificados.

Auditoria de cobertura de efeitos em Hermes, 2026-06-07:

- Problema revisado: corrigir efeitos do Lorehold nao garante que os oponentes reais estejam modelados corretamente; decks reais trazem centenas de triggers, efeitos temporarios, permissoes de cast e lands utilitarias.
- Novo script versionado: `battle_effect_coverage_audit.py`.
- A auditoria classifica cada carta por fonte de efeito: `handcrafted`, `generated`, `tag`, `effect_map`, `type_land`, `type_creature` ou `unknown`.
- `battle_analyst_v8.py` agora preserva `HANDCRAFTED_KNOWN_CARDS` para diferenciar regras escritas a mao de entradas geradas.
- `get_card_effect()` agora normaliza erros perigosos via oracle text: target removal, counterspells, board wipe de nonland permanent e falso `silence_opponents` causado por "can't be countered".
- Lands agora sao tratadas primariamente como `land`; habilidades utilitarias como channel/ativacoes entram no relatorio como `land_utility_ability_not_modeled`, nao como removal/counter gratis.
- Nomes de oponentes reais agora incluem o id do deck aprendido, evitando relatorios que pareciam somar dois decks diferentes do mesmo comandante em uma lista de 198 cartas.
- Cron `manaloom-master-optimizer-preflight` agora sincroniza `meta_decks` do Postgres real antes do sync de metadata.
- Cron `manaloom-master-optimizer-auto-cycle` agora roda sync de `meta_decks` antes de metadata e gera auditoria de cobertura antes do handoff/apply.
- Validacao local: `py_compile` aprovado, 31 testes de battle passaram, preflight local aprovado.
- Validacao Hermes container: `bash -n` dos scripts de cron aprovado, `py_compile` aprovado, 31 testes de battle passaram, preflight aprovado.
- Auditoria fresca Hermes: `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260607_180414.md`.
- JSON fresco Hermes: `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260607_180414.json`.
- Snapshot da auditoria Hermes: 12 oponentes reais, 1288 instancias de cartas, 554 cartas unicas.
- Fontes de efeito na auditoria Hermes: `handcrafted=98`, `generated=599`, `tag=71`, `effect_map=123`, `type_land=377`, `unknown=20`.
- Flags de risco na auditoria Hermes: `heuristic_effect=793`, `trigger_not_explicit=133`, `temporary_effect_not_explicit=63`, `cast_permission_not_explicit=77`, `land_utility_ability_not_modeled=48`, `oracle_target_removal_mismatch=9`, `oracle_silence_mismatch=1`, `copy_effect_mismatch=1`, `unknown_effect=20`.
- Conclusao operacional: o battle ainda nao cobre "todas as regras sem excecao"; agora ele mede a lacuna e impede que a equipe trate heuristica como regra completa.
- Proxima evolucao correta: transformar as cartas mais influentes marcadas pela auditoria em regras explicitas de `KNOWN_CARDS`, começando por cartas que aparecem nos candidatos aprovados, nos commanders oponentes e nos flags `oracle_*_mismatch`.

Arquitetura correta para battle + montagem de deck, 2026-06-07:

- Novo documento canonico: `docs/hermes-analysis/HERMES_BATTLE_DECKBUILDING_RULE_REGISTRY_2026-06-07.md`.
- Nova tabela operacional: `battle_card_rules`.
- Novo modulo: `battle_rule_registry.py`.
- Novo sync: `sync_battle_card_rules.py`.
- A tabela separa fatos de carta (`card_oracle_cache`) de interpretacao do simulador (`battle_card_rules`).
- `effect_json` passa a ser a semantica usada pelo battle.
- `deck_role_json` passa a ser a semantica usada pela montagem/optimizer.
- `battle_analyst_v8.py` agora consulta `battle_card_rules` antes de `KNOWN_CARDS`, JSON gerado, tags e heuristicas.
- `slot_optimizer.py` agora mescla `battle_card_rules` por cima de `known_cards_generated.json`; categoria de deck da tabela tem prioridade.
- Criaturas genericas nao viram categoria confiavel de deckbuilding; continuam `unknown` ate receberem papel explicito.
- `battle_effect_coverage_audit.py` agora diferencia `battle_rule_manual` e `battle_rule_generated`.
- Preflight, auto-cycle e slot-scan cron agora sincronizam `battle_card_rules`.
- Validacao local: `sync_battle_card_rules.py` populou 1970 regras em banco temporario (`manual=40`, `generated=1930`) e os 32 testes do battle passaram.
- Validacao Hermes: `sync_battle_card_rules.py --apply` populou o SQLite real com `manual=40` e `generated=689`; os 32 testes passaram; preflight aprovou; smoke de battle com 3 oponentes reais e 6 jogos rodou sem crash (`83.3%` WR, `5W/0L/1S`).
- Auditoria Hermes apos tabela: `docs/hermes-analysis/master_optimizer_reports/battle_effect_coverage_audit_20260607_210708.md`.

Arquivos principais:

- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_rule_registry.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_effect_coverage_audit.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_analyst_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/slot_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/universal_optimizer.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_loop.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_apply.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/master_optimizer_product_handoff.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/replay_decision_auditor.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_replay_v10_3.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/hermes_provider_backoff.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/kc_validator.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_card_metadata_to_hermes.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_meta_decks_to_hermes.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`

## O que ainda falta no battle

1. Validacao massiva com amostras maiores e mais seeds, alem dos 3 replays frescos ja auditados.
2. Evoluir a auditoria para medir qualidade de counter/removal com valor esperado por alvo.
3. Persistir metricas mais finas por matchup:
   - winrate;
   - turnos ate vitoria;
   - cartas mortas na mao;
   - screw/flood;
   - dano perdido por ataque ruim;
   - spells relevantes seguradas ou gastas cedo demais.
4. Investigar matchups agregados fracos, especialmente Winota e Tivit, antes de qualquer mutacao product-facing.

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
- Nunca confirmar, gerar handoff ou aplicar swap se o hash atual do deck divergir do hash do baseline aprovado.
- Nunca aplicar swap com menos de 2 rodadas de confirmacao.
- Nunca testar swap se a carta cortada nao existe no deck atual ou se a carta adicionada ja existe no deck atual.
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

Se qualquer job detectar hash divergente entre deck atual e baseline aprovado, a rodada deve ser descartada e reiniciada por esta fase.

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

Antes de testar, a confirmacao deve validar que o deck atual ainda e exatamente o deck congelado no baseline. Candidatos com alvo stale devem ser bloqueados, nao corrigidos implicitamente.

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
- o hash atual do deck ainda bate com o baseline aprovado;
- o alvo de corte ainda esta presente;
- a carta de entrada ainda esta ausente.

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

Estado atual: implementado. O auditor turno-a-turno bloqueia findings `critical/high`, exige revisao para `medium` antes de produto e aceita `low` apenas como polish de Hermes-local.

## Cron auto-cycle funcional em Hermes, 2026-06-07

Estado vivo validado no container `d5fe57bf9de2`:

- `lorehold-knowncards-generator`: reativado com wrapper seguro `known_cards_generator_cron.sh`, schedule `every 120m`.
- `lorehold-knowncards-validator`: trocado para wrapper seguro `known_cards_validator_cron.sh`, schedule `every 30m`.
- `manaloom-master-optimizer-preflight`: ativo, schedule `every 20m`.
- `manaloom-master-optimizer-auto-cycle`: criado e ativo, script `manaloom-master-optimizer-auto-cycle.sh`, schedule `every 180m`.
- `manaloom-master-optimizer-slot-scan`: mantido pausado porque o auto-cycle ja executa baseline, scan, quality gate, confirmation e full confirmation.
- `manaloom-master-optimizer-end-to-end`: mantido manual-only para prova completa sob demanda.

Correcoes aplicadas para cron confiavel:

- `generate_known_cards.py` e `kc_validator.py` deixaram de depender de credenciais hardcoded e passam a usar `PGHOST/PGDATABASE/PGUSER/PGPASSWORD` ou `DATABASE_URL` do ambiente do servidor.
- `known_cards_generated.json` agora e escrito de forma atomica, reduzindo risco de arquivo parcial durante cron.
- `replay_decision_auditor.py` agora escolhe diretorio gravavel para replays e cai para `/opt/data/artifacts/hermes_master_optimizer/replays` se `master_optimizer_reports/replays` estiver sem permissao.
- `battle_replay_v10_3.py` cria os diretorios de saida antes de escrever replay/eventos.
- `master_optimizer_confirmation.py` agora usa candidatos da fase `confirmation` como fonte primaria para `full_confirmation`.
- `master_optimizer_common.py` ganhou gate de papel critico para impedir cortes que reduzam funcoes escassas como removal, wipe, draw e ramp sem reposicao de papel equivalente.
- `master_optimizer_rollback.py` restaura deck Hermes local por rollback JSON e marca `swap_benchmarks.applied=-1` para nao reaplicar candidato revertido.
- `master_optimizer_post_apply_gate.py` compara baseline antes/depois e faz rollback automatico quando o ganho nao se sustenta.
- `master_optimizer_auto_cycle_cron.sh` executa o ciclo completo e aplica no maximo um swap Hermes-local por rodada, nunca no produto.

Validacoes reais executadas:

- `known_cards_generator_cron.sh`: `known_cards_generator=ok`; 689 entradas salvas na rodada de geracao direta.
- `known_cards_validator_cron.sh`: `known_cards_validator=ok`; pool expandido para 1968 entradas filtradas na rodada de validacao curta.
- Auto-cycle smoke pos-patch: `master_optimizer_auto_cycle=ok`, com apply bloqueado por falta de full confirmation aprovada.
- Auto-cycle real: baseline `85.0%`, slot scan de 96 candidatos, full confirmation aprovou `Plaza of Heroes` sobre `Rise of the Eldrazi` com `+2.3pp`, apply Hermes-local executado.
- Post-apply gate real: baseline pos-apply caiu para `83.7%`; rollback automatico executado com motivo `post_apply_delta_below_threshold:-1.3pp < +0.0pp`.
- Verificacao direta SQLite: `Plaza of Heroes` ausente, `Rise of the Eldrazi` presente, `Wheel of Misfortune` presente, `Reforge the Soul` ausente.
- Handoff de produto do swap revertido foi marcado como `superseded_by_rollback`.
- Baseline final serio apos rollback: baseline id `11`, hash `12c55613ae4f7bcd4c934fae4253cfa75fcc4946352a18a61365835427e90c08`, 300 jogos, `87.3%` WR, 100 cartas, 33 lands.

Interpretação atual:

- As crons agora estao funcionais para evoluir o Lorehold em Hermes com seguranca operacional.
- A automacao pode aprender, testar, aplicar no SQLite Hermes e desfazer se o resultado pos-apply piorar.
- Produto/app continuam protegidos: qualquer copia para deck real exige `optimizer_product_handoffs.status = needs_product_owner_approval` e checklist humano.

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
Pode aplicar no SQLite Hermes local apenas se houver full confirmation aprovada, quality gate verde, hash atual compativel, rollback gerado e post-apply gate configurado.
Nao aplique no produto automaticamente. Gere handoff com winrate, delta, motivo de cada swap, riscos, replays auditados e proximas correcoes do battle.
Se encontrar erro de decisao no replay, pare a otimizacao e abra tarefa de fix no battle_analyst_v8.py com teste novo em test_battle_analyst_v10_3.py.
```

## Proximo passo tecnico recomendado

Proximos passos agora sao de maturidade, nao de infraestrutura basica:

- deixar o auto-cycle rodar algumas janelas e revisar apenas os handoffs que sobreviverem ao post-apply gate;
- aumentar amostra de replay audit para mais seeds quando for promover qualquer swap a produto;
- criar um apply product-facing separado apenas depois do checklist `needs_product_owner_approval`;
- limpar prompts antigos de jobs que ainda citam IDs/schema legados;
- considerar limpar `last_error` antigos apenas apos cada job rodar de novo com `last_run_at` posterior a `2026-06-07T12:49:11+00:00`.
