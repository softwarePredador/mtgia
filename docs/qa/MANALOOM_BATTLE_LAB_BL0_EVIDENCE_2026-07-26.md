# Evidência BL0 — Integridade da evidência e contratos

- Data: 2026-07-26
- Revisão: árvore de trabalho que forma o commit desta entrega
- Ambiente: macOS arm64; Flutter 3.44.6/Dart 3.12.2; PostgreSQL 14
  descartável loopback; XMage/Forge/native locais
- Resultado: `PASS_LOCAL`
- Escrita live: não executada

## Resultado por task

| Task | Estado | Evidência |
|---|---|---|
| BL0-00 | `PASS_LOCAL` | temporários Dart e cache Web ignorado/recriável foram removidos pelos alvos exatos, sem tocar backups ou `app/build/web`; o backend passou a executar arquivos explícitos em lotes de oito e duas execuções `quality_gate.sh full` consecutivas passaram, preservando cerca de 1,8 GiB livres |
| BL0-01 | `PASS_LOCAL` | ADR 0002 separa Battle fechado, Live somente leitura e sessão interativa |
| BL0-02 | `PASS_LOCAL` | migration 052 e `battle_simulation_attempts` usam outcomes fechados, sem converter censura/timeout em conclusão |
| BL0-03 | `PASS_LOCAL` | tentativa guarda engine/build/processo, request/schema/hash, timeout e truncamento consultáveis |
| BL0-04 | `PASS_LOCAL` | hashes/revisões imutáveis dos dois decks e compatibilidade aparecem em tentativa, replay e UI |
| BL0-05 | `PASS_LOCAL` | `battle_replay_event_v2` carrega ator/lado e `subject_deck_key`; testes rejeitam atribuição adversária |
| BL0-06 | `PASS_LOCAL` | XMage, Forge e native convergem para evento público; native permanece identificado como heurístico |
| BL0-07 | `PASS_LOCAL` | sanitização negativa em backend/engines remove zonas, prompts e opções privadas |
| BL0-08 | `PASS_LOCAL` | export/delete de conta cobre tentativa, replay, anotação, job e registros Live; PostgreSQL é a verdade |
| BL0-09 | `PASS_LOCAL` | migrations 001–055, reaplicação/contratos e store real passaram em cluster descartável |

## Provas

- suíte BL5/backend: 86/86 testes verdes;
- engine capabilities: 95/95;
- estratégia XMage: 29/29;
- PostgreSQL descartável: migrations 001–055 e executor/fault/concurrency
  verdes;
- gate oficial de schema: 77 tabelas, 6 views, 91 FKs e 55 migrations; as FKs
  compostas de tentativa/replay agora fazem parte do manifesto gerado;
- `git diff --check` e scripts alterados verificados sem erro.
- `quality_gate.sh full` passou duas vezes consecutivas: 39 lotes backend por
  rodada, análise Flutter limpa, 1.252 testes Flutter + 1 skip declarado, Web
  pública com audit de produção 0 e 17 contratos de performance.

Os comandos agregados e eventuais skips da rodada final ficam também na
evidência BL4. Nenhum resultado local autoriza migration ou consulta ao banco
live.

## Cleanup e risco residual

Cinco clusters PostgreSQL de teste e seus diretórios temporários foram
encerrados/removidos. Um processo órfão do cluster
`/tmp/manaloom_bl5_pg.VbGgou` foi identificado pelo PID/diretório exatos e
encerrado com `pg_ctl -m fast`. O diretório temporário Dart incompleto de
aproximadamente 1,2 GiB e o cache ignorado/recriável
`web-public/node_modules` foram removidos pelos caminhos previamente
inventariados. O volume continua perto do limite, mas duas rodadas integradas
consecutivas terminaram sem acúmulo de kernel temporário; BL0-00 recebe crédito
local, mantendo o monitoramento de capacidade como risco operacional.
