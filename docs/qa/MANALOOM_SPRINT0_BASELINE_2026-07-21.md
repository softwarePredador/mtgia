# ManaLoom Sprint 0 — baseline de execução — 2026-07-21

Este registro inicia a execução de
`docs/MANALOOM_PRODUCT_COMPLETION_SPRINTS.md`. Ele não herda resultados de
rodadas anteriores e não autoriza escrita PostgreSQL, deploy ou promoção.

## Identidade inicial

- branch: `codex/free-beta-release-candidate-2026-07-17`;
- HEAD: `2813152121c4d41069f9ebbb3334eb4c6b8b1110`;
- hash SHA-256 do patch rastreado inicial: `ad0407cee5679e6dfe671243aa2c4792458b0ba50360b2075a5499ae6bb9572c`;
- Flutter do `PATH`: `3.41.6` / Dart `3.11.4`, rejeitado para os gates;
- SDK obrigatório: `/Users/desenvolvimentomobile/.manaloom/toolchains/flutter-3.44.6/bin/flutter`, Flutter `3.44.6` / Dart `3.12.2`;
- PostgreSQL local observado em `127.0.0.1:5432`; nenhum servidor Web ManaLoom
  foi encontrado nas portas `8088`, `8080` ou `3000`.

## S0-01 — capacidade do host

| Medição | Antes | Depois |
|---|---:|---:|
| Espaço livre em `/System/Volumes/Data` | `7.6 GiB` (`99%`) | `53 GiB` (`87%`) |
| Cache Gradle | `16 GiB` | `80 MiB` |
| Xcode DerivedData | `2.6 GiB` | `0 B` |
| Android system images | `40 GiB` | `6.4 GiB` |

Foram removidos apenas caches regeneráveis e imagens de sistema Android sem
AVD consumidor configurado. Permaneceram as imagens estáveis Android 34 e 36,
os SDKs, os arquivos do projeto, os arquivos em Downloads, os archives Xcode,
os simuladores e os dados PostgreSQL. A remoção foi precedida por inventário de
tamanho e processo. Não havia build Gradle/Xcode iniciado por esta execução.

## S0-02 — atribuição do worktree inicial

Nenhum arquivo abaixo pode ser descartado ou reescrito em massa. `/root` é o
owner de integração; `preexistente` significa que o conteúdo já estava no
checkout antes desta execução e deve ser preservado durante a validação.

| Arquivo(s) | Task | Owner de integração | Origem |
|---|---|---|---|
| `ROADMAP.md`, `docs/MANALOOM_PRODUCT_COMPLETION_SPRINTS.md`, `docs/MANALOOM_PRODUCT_COMPLETION_TRACKER.md` | S0-02 | `/root` | plano criado antes da execução |
| `docs/CONTEXTO_PRODUTO_ATUAL.md`, `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`, `docs/README.md`, `server/doc/API_CONTRACTS_AND_DATA_MAP.md`, `server/manual-de-instrucao.md` | S0-03 | `/root` | auditoria preexistente |
| `docs/qa/MANALOOM_E2E_CORE_DOCUMENTATION_AUDIT_2026-07-21.md` | S0-07 | `/root` | evidência preexistente |
| `app/lib/features/auth/providers/auth_provider.dart`, `app/test/features/auth/providers/auth_provider_initialize_test.dart`, `server/lib/rate_limit_middleware.dart`, `server/routes/auth/_middleware.dart`, `server/test/rate_limit_middleware_test.dart` | S1-02 | `/root` | correção preexistente de sessão/rate limit |
| `app/patrol_test/manaloom_patrol_smoke_test.dart` | S1-09 | `/root` | fixture preexistente de cadastro |
| `server/test/api_contracts_data_map_guard_test.dart` | S0-03 | `/root` | guard documental preexistente |
| `server/test/deploy_rollback_convergence_contract_test.dart` | S10-03 | `/root` | guard preexistente de rollback |
| `web-public/package-lock.json` | S8-08 | `/root` | correção preexistente de supply chain |
| `docs/hermes-analysis/manaloom-knowledge/scripts/battle_runtime_surface_manifest.py` | S5-01 | `/root` | classificação preexistente de Battle |
| `docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_paired_battle_statistical_gate.py`, `docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_paired_battle_statistical_gate.py`, `docs/hermes-analysis/master_optimizer_reports/lorehold_archidekt_collection_20260718.decklist.txt` | S6-06 | `/root` | gate/candidato Lorehold preexistente |

### Hashes dos novos arquivos no início

| SHA-256 | Arquivo |
|---|---|
| `94f983e1513c2857284f000bd8aab23215a9cdf334ba19d6004a013a595568aa` | `app/test/features/auth/providers/auth_provider_initialize_test.dart` |
| `74132f4e94ce5dba2d4bb5088a597afa317112cf4c7c097c57b387278a976645` | `docs/MANALOOM_PRODUCT_COMPLETION_SPRINTS.md` |
| `d2d7a980b707c40b51c3b3e4ffdb394cd8bf441c633067f3a8a6ea9fc6235a2e` | `docs/MANALOOM_PRODUCT_COMPLETION_TRACKER.md` |
| `f65e19e1505e32264208bfa9818ab112896e1a3836757e68335459fcfb508247` | `docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_paired_battle_statistical_gate.py` |
| `97cbdb01cfe17d742a841dc6766d4060bc462432ca21e828041827c8e295fcd7` | `docs/hermes-analysis/manaloom-knowledge/scripts/test_lorehold_paired_battle_statistical_gate.py` |
| `02d4fb43209bbbd31033cd97efeb82591dc2a1dfe9d70078efd24ceed4dd1964` | `docs/hermes-analysis/master_optimizer_reports/lorehold_archidekt_collection_20260718.decklist.txt` |
| `36312e74ca323ce27ecb9425e31906e44761f2422942d082126c3aaaddbc9701` | `docs/qa/MANALOOM_E2E_CORE_DOCUMENTATION_AUDIT_2026-07-21.md` |

## Próximo gate

## S0-03 — status documental reconciliado

- `test_lorehold_paired_battle_statistical_gate.py`: `17/17` PASS;
- `api_contracts_data_map_guard_test.dart` + `rate_limit_middleware_test.dart`:
  `22/22` PASS;
- `auth_provider_initialize_test.dart`: `6/6` PASS;
- `git diff --check`: PASS;
- SDK confirmado: Flutter `3.44.6` / Dart `3.12.2`.

Os guards cobrem a separação entre mecanismo e gate real Lorehold, a semântica
de `GET /auth/me` e o shape `deck_id`/`match_count` de trade matches.

## Próximo gate

S0-04 deve classificar individualmente os outputs locais e fazer
`report-retention` passar. Depois, o aggregate será reexecutado sem converter
retry ou skip em sucesso.

## S0-04 — retenção de relatórios

- primeira execução: FAIL, `ignored_local_count=18`, `371606` bytes;
- 16 checkpoints intermediários sem consumidor: removidos;
- `lorehold_archidekt_collection_20260718.decklist.txt`: consolidado na seção
  “Lista canônica — 100 cartas” do relatório Markdown;
- `lorehold_archidekt_collection_20260718_validation.md`: preservado no
  manifesto com SHA-256
  `48941497dfb8aa148765ccd985529df9e41561629f6230f2c076371dd9468f0a`;
- segunda execução: PASS, `13/13` testes do auditor.

## Próximo gate

S0-05 executa o aggregate duas vezes na ordem completa com o Flutter pinado e
registra separadamente qualquer primeira tentativa, crash ou retry.

## S0-05 — Battle dentro do aggregate

| Rodada | Resultado | PASS | FAIL | BLOCKED | SKIP | SHA-256 do summary |
|---|---|---:|---:|---:|---:|---|
| `20260721T193749Z` | `partial` | 10 | 0 | 0 | 9 | `751c4acdada80f97cab77ae0ebf6f6d2bddec54bc4c111ece72a712bee15817a` |
| `20260721T194027Z` | `partial` | 10 | 0 | 0 | 9 | `77a20462bf06c57c035ae11e3abe59181b35707aa76c4e0edb89ff10c79c9cd4` |

O Battle canônico passou dentro das duas ordens completas. O crash do analysis
server não foi reproduzido depois da recuperação de espaço e da fixação do SDK;
nenhum retry ocorreu. Os nove skips são camadas guardadas PostgreSQL/live ou
runtime de device e mantêm o aggregate como `partial`, não como PASS de release.

## Próximo gate

S0-06 executa cada gate determinístico canônico separadamente para preservar
evidência por superfície.

## S0-06 — baseline determinística

Todos os comandos abaixo terminaram com exit code `0` usando o SDK pinado
quando o gate envolve Flutter:

| Gate | Resultado | Observação |
|---|---|---|
| `quality_gate.sh full` | PASS | backend, Flutter e Web públicos verdes; Web com 13 rotas e `npm audit` sem vulnerabilidade |
| `quality_gate.sh deps` | PASS | configuração ativa exclui fontes geradas; somente o pin deliberado de `dart_frog_cli` é ignorado pelo validator e permanece coberto pelo contrato de supply chain |
| `quality_gate.sh custom-lint` | PASS | lint package, app e backend sem issue |
| `quality_gate.sh ui-audit` | PASS | analyze verde e 13 testes de UI/golden/acessibilidade |
| `quality_gate.sh patrol-smoke` | PASS | 9 testes locais; device/Chrome continuam opt-in e não contam como prova física |
| `quality_gate.sh battle` | PASS | pin/manifest/Java/Python/Dart/contratos canônicos verdes |
| `quality_gate.sh server-target` | PASS | zero referência ativa ao servidor legado |
| `quality_gate.sh report-retention` | PASS | 13/13 testes |
| `quality_gate.sh e2e` | PARTIAL controlado | 10 PASS, 0 FAIL, 0 BLOCKED e 9 SKIP por capability guard |
| `git diff --check` | PASS | nenhuma falha de whitespace |

O warning de engine do pacote `eslint-visitor-keys@5.0.1` informa suporte a
Node `^20.19.0 || ^22.13.0 || >=24`, enquanto o host está em `20.11.1`. Ele não
falhou o build nem o `npm audit`, mas permanece dívida explícita de S8-08 e não
é tratado como certificação de supply chain.

## S0-07 — baseline congelada

- branch/HEAD: `codex/free-beta-release-candidate-2026-07-17` /
  `2813152121c4d41069f9ebbb3334eb4c6b8b1110`;
- snapshot SHA-256 do patch rastreado imediatamente antes deste registro:
  `b2b5955db64f5635bc0d4ba71c013862ecdd43168f89887ff235285dada85c6d`;
- snapshot SHA-256 do inventário `git status --porcelain=v1 -uall`:
  `82d828e06d2dead9586668127bbcc1a6b49f41dc146ce1b61ed79ffb309961ad`;
- SDK: Flutter `3.44.6`, framework revision
  `ee80f08bbf97172ec030b8751ceab557177a34a6`, Dart `3.12.2`;
- aggregate final:
  `/tmp/manaloom_e2e_suite_reports/manaloom_e2e_suite_20260721T195718Z/summary.json`;
- SHA-256 do aggregate final:
  `7d43441681dcfc813049b5554ddfdbbd263e8da5d4679965b628e1617a29f78d`;
- resultado: `partial`, 10 PASS, 0 FAIL, 0 BLOCKED e 9 SKIP;
- espaço livre final em `/System/Volumes/Data`: `53 GiB`.

Os nove skips são exclusivamente os runners opt-in de mutação PostgreSQL,
runtime/live API/device. Eles estão inventariados com razão individual no JSON
do aggregate e continuam impedindo qualquer claim de release `GO`. Nenhum
resultado anterior a esta execução foi herdado como PASS.

**Gate de saída S0:** PASS. O checkout permanece dirty, porém integralmente
inventariado e atribuído; zero falha no aggregate, zero report ungoverned e SDK
correto confirmado.
