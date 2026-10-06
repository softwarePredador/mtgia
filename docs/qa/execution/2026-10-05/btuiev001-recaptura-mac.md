# Receipt de trabalho — BT-UIEV-001: recaptura no Mac (overlays, P0 e Jogar contra IA)

Status: `PARCIAL · 22/23_MANIFESTS_NO_DIGEST_CORRENTE · PLAY_VS_AI_BLOQUEADO_POR_BUG_NO_ESCOPO_DO_DIGEST`

Não autoriza merge, deploy, migration, DML live, capability `ON` nem promoção
de deck/regra. `docs/qa/ui-live/latest.json` ficou intocado de propósito: ele
só pode ser reescrito quando os 23 manifests estiverem no mesmo digest, e o
dono escolheu fechar em 22/23 (opção "Fechar 22/23 agora").

Continua `btuiev001-recaptura-web-nuvem.md`, que recapturou 15 manifests na
nuvem e deixou 8 para o Mac.

## Identidade

- Branch: `claude/project-thread-ijg1xw` sobre `11308c5a0`, em worktree
  separado (o checkout principal tinha mudanças não commitadas de outra frente)
- Digest de UI: `4fc91724eb8a8f8a64e53725dd245086c3689c06ec2e0ecd63c0fe6ece6637af`,
  conferido antes, durante e depois; nada no escopo de
  `manaloom_ui_source_digest.sh` foi alterado
- Ambiente: Mac mini arm64, Flutter pinado `3.44.6`, Chrome for Testing
  `153.0.8010.52` com ChromeDriver `153.0.8010.52` pinado (`CHROME_EXECUTABLE`),
  headless; AVD `manaloom_api34` recriado (Pixel 6, `system-images;android-34;google_apis;arm64-v8a`)
  e executado com `-no-window -no-audio -no-boot-anim`; PostgreSQL 17.9 local em
  `127.0.0.1:5432` para a fixture descartável
- Agente: Claude Code (Anthropic)
- Autorização: o dono aprovou em 2026-10-05 a troca do golden e as frases de
  confirmação só para PostgreSQL, API e XMage descartáveis em loopback; as
  corridas que exigem as frases foram coladas pelo próprio dono no Terminal

## Guarda de egress

O script de critical overlays não passa `API_BASE_URL`. Para que nenhuma
requisição do app saísse para o servidor no ar, ele e as três capturas P0 Web
rodaram sob `sandbox-exec` com perfil só-loopback (o mesmo de
`manaloom_server_contract_e2e_isolated.sh`, mais sockets Unix locais). O
auto-teste confirmou o bloqueio do host público antes das corridas. As capturas
P0 usaram `API_BASE_URL=http://127.0.0.1:53167` da fixture.

## Golden `deck_gallery_card_1880.png`

A suíte de widgets que antecede os overlays falhava também no Mac (4 px, 0,00%,
antialias num canto). A imagem renderizada no Mac é byte a byte igual
(`sha1 4a95165b…`) à versão já regenerada pelo dono no checkout principal; o
baseline commitado estava desatualizado. O arquivo fica fora do digest. Trocado
com aprovação do dono; a suíte passou inteira em seguida.

## Recaptura

| manifest | perfis | telas | resultado |
| --- | --- | --- | --- |
| 08 critical-overlays | Web mobile/desktop/wide | 3 × 22 | `PASS_RUNTIME` em `4fc91724` |
| P0 `web_mobile_390x844` | Web | 54 | `PASS_RUNTIME` em `4fc91724` |
| P0 `web_desktop_1440x900` | Web | 53 | `PASS_RUNTIME` em `4fc91724` |
| P0 `web_wide_1920x1080` | Web | 53 | `PASS_RUNTIME` em `4fc91724` |
| P0 `android_emulator_manaloom_api34` | `sdk_gphone64_arm64`, Android 14, 1080x2400 | 54 | `PASS_RUNTIME` em `4fc91724` |
| `play-vs-ai-web-real` | Web 1440x900 | 9 | não recapturado (ver abaixo); evidência anterior restaurada byte a byte |

A matriz P0 foi indexada com `--index-p0-matrix` (`MANALOOM_P0_INDEX_SCOPE=all`).
A fixture autenticada (`20261005T193124Z_98765_19190`) encerrou com cleanup
`pass`: banco `manaloom_s1_api_20261005T193124Z_98809` removido, zero listeners.

Com isso, 22 dos 23 manifests do agregado estão em `4fc91724`.

## Revisão visual

Foram abertas 430 telas em pranchas de contato: as 66 de critical overlays,
as 160 Web P0, as 54 Android P0 e as 150 dos packs 02/03/05/06/07 recapturados
na nuvem. Nenhum bloqueio. Seguem os follow-ups já registrados:

- títulos longos truncados no clamp (`Marina — Arquivista de Co…`,
  `Izzet Phoenix…`) e nomes de fixture muito longos quebrando em duas linhas;
- telas desktop/wide com estado único subutilizando o canvas;
- pack 05 e P0 mostrando Marketplace, `Compra`/`Misto`/`Venda` e preços, ainda
  rotulados como evidência de capability futura (D-40, C17);
- a prova de recuperação do comandante isolada, com grande área vazia.

## Jogar contra IA: por que não fechou

1. **1ª tentativa** (`20261005T195707Z_22185_23600`): falhou em
   `natural_full_match_spike`. A partida automática contra a IA do XMage chegou
   ao turno 12 com 46 decisões aceitas e nenhum vazamento de mão, mas travou
   (`deadlocks=1`, `idle_timeout`); o harness concedeu e o gate, que exige
   término natural, falhou fechado. Intermitência do motor.
2. **2ª tentativa** (`20261005T200013Z_25617_12950`): a partida natural passou
   (19 turnos, `deadlocks=0`, `normal_completion=true`). Falhou em
   `real_api_postgresql_xmage_contract` com `400 auth_username_too_long`.

Causa determinística: desde o BT-AUTH-002 `auth/register` limita o nome de
usuário a `accountUsernameMaxChars = 30`. A corrida verde de 2026-09-29 é
anterior. Dois cadastros fixos ultrapassam o teto:

- `server/test/play_vs_ai_real_xmage_e2e_test.dart`: `play_vs_ai_<micros>_<pid>`
  (~33). **Corrigido** para `pvai_<micros>_<pid>` (27); fora do digest;
  `dart analyze` e `dart format` limpos.
- `scripts/manaloom_play_vs_ai_e2e.sh:764`: `play_vs_ai_browser_<12 hex>` (31).
  **Não corrigido**: o script está no escopo do digest de UI, e a correção
  invalidaria os 22 manifests em `4fc91724`. Falharia em
  `seed_browser_qa_player_and_decks`.

Decisão do dono: fechar 22/23 agora. A correção da linha 764 entra na próxima
recaptura única, junto com as mudanças de UI dos PRs #20 e #22, para não gastar
duas recapturas completas. Nas duas tentativas o cleanup terminou sem processo
remanescente.

## Próximo passo

Na próxima rodada: trocar o usuário da linha 764 por um de até 30 caracteres
(por exemplo `pvai_browser_<12 hex>`), recapturar os 23 manifests no digest
novo, revisar e então reescrever `latest.json` e rodar
`./scripts/manaloom_ui_live_evidence_gate.sh --check`.

## Passo 7: gate de schema e vermelhos da nuvem

Rodado depois das capturas, sem frases de confirmação (o gate de schema usa a
aprovação permanente `manaloom.localGates.disposablePostgres=true` do checkout).

- **Schema (`./scripts/manaloom_local_ci.sh schema`, PostgreSQL 17.9):**
  `database_setup.sql`, `bin/migrate.dart` (até a 076) e o ensaio de migration
  passaram num cluster descartável em `$TMPDIR`. O gate parou nos testes DB
  live, antes da comparação `tbls`/manifesto:
  - No macOS o `pg_ctl` só sobe com `LC_ALL` definido (`postmaster became
    multithreaded during startup`); é ambiente, resolvido com
    `LC_ALL=en_US.UTF-8`.
  - `server/test/interactive_battle_store_live_test.dart` enviava cinco blocos
    com vários comandos SQL em prepared statement (`42601`). Corrigido com
    `queryMode: QueryMode.simple` só nesses blocos.
  - Com isso, o mesmo teste chega à asserção real e falha na linha 762:
    `deleteDeckAfterBattleGuard` devolve `deleted` enquanto
    `finalizeRuntimeSnapshot` ainda está em curso (esperado `activeBattle`).
    Pode ser corrida real entre exclusão de deck e finalização da partida em
    `server/lib` ou temporização do teste; não investigado aqui (fora do
    escopo do passo). **Schema gate segue vermelho por esse teste.**
- **Goldens:** os 4 `home_hero_*` (1440, 1920, sma135m, web; 0,14–0,42%)
  falham também no Mac. Não é diferença de Linux. O dono tem versões
  regeneradas não commitadas no checkout principal.
- **Validador de dependências:** vermelho no Mac — `file` usado fora de `lib/`
  sem estar em `dev_dependencies`. O checkout principal tem uma alteração
  staged em `app/dart_dependency_validator.yaml` que provavelmente cobre isso.
- **custom-lint:** verde no Mac (exit 0). **patrol-smoke:** verde.
- **Checks do pre-push que dependem de launchd, psycopg2 e histórico git
  completo:** verdes no Mac (contratos dos gates, secret scan, auditorias
  determinísticas e contratos de release passaram antes da etapa de qualidade).
- **Pre-push `full`:** vermelho só nos 4 goldens acima. O push saiu com
  `--no-verify` pela D-86 e ficou registrado em
  `~/.manaloom/coordenacao/receipts/pushes.log`.
- **Gate em worktree novo:** o pre-commit acusa `.dart_tool residual em
  tools/project_logic` quando a pasta não existia antes; contornado com
  `dart pub get` nela. Ajuste futuro em `manaloom_project_logic.sh`.
- **Efeito colateral:** uma das corridas manuais deste passo (schema,
  custom-lint, patrol-smoke ou auditoria de dependências) reescreveu
  `app/pubspec.lock` (`meta` 1.18.0→1.17.0, `test_api` 0.7.11→0.7.10). O lock
  está no digest de UI; foi restaurado ao commitado e o digest voltou a
  `4fc91724`. Vale identificar qual gate resolve dependências sem
  `--enforce-lockfile`.
