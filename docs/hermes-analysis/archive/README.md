# Hermes Analysis Historical Contract Evidence

Status: `historical_evidence_archive`.

Este diretório preserva os diários que estavam embutidos nos entrypoints
canônicos antes do fechamento S9-03 em 2026-07-23. Os snapshots são
byte-identical aos arquivos de origem no commit
`2139ec9f6f902a8b266fbb852db6e834b25bceff`.

Eles existem para auditoria, recuperação, hashes e resolução de referências.
Não são contratos atuais, handoffs, fonte de produto, input de runtime ou
autorização para PostgreSQL, Hermes sync, Battle, deck promotion ou deploy.

| Snapshot histórico | Origem canônica anterior | Linhas | Bytes | SHA-256 | Disposição |
| --- | --- | ---: | ---: | --- | --- |
| `HERMES_ANALYSIS_README_SNAPSHOT_2026-07-23.md` | `../README.md` | 1.640 | 105.627 | `d6f592010e67ad410ad37f3f65f1a8e9b824e06fa8bf9fdb6ecbf4012b5f0a64` | índice+diário arquivado; entrypoint reescrito |
| `COMMANDER_DECKBUILDING_EVIDENCE_LOG_2026-06-29_TO_2026-07-15.md` | `../COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md` | 3.904 | 250.108 | `cbc6941a004649fcb688d1b0bcb63adb752a78fbd6bbb16f2e397e0029a9d38a` | norma destilada; decisões/pacotes preservados |
| `XMAGE_NATIVE_ADAPTATION_EVIDENCE_LOG_2026-06-29_TO_2026-07-15.md` | `../XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md` | 20.719 | 1.228.971 | `65cb926682c3bd75c48d14d78d76b9155c68263377b7190e02d570021ed83cb2` | compatibilidade compacta; programa nativo histórico preservado |

Entry points atuais:

- `../README.md`;
- `../COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`;
- `../GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md`;
- `../EXTERNAL_BATTLE_EXECUTION_CONTRACT.md`;
- `../EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json`.

Política:

- não anexar novas rodadas a estes snapshots;
- novos outputs brutos ficam em `/tmp`;
- uma evidência só volta ao checkout com owner, consumidor e retenção;
- o auditor pode ler os snapshots para manter links históricos válidos;
- a norma deve permanecer somente nos entrypoints compactos.
