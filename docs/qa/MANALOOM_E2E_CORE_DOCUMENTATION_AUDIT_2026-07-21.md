# Auditoria E2E, core e documentação do ManaLoom — 2026-07-21

> Auditoria source-backed do checkout local em 2026-07-21. Este documento
> registra a rodada atual; não promove deploy, não autoriza escrita live e não
> substitui `docs/MANALOOM_E2E_RELEASE_CONTRACT.md`.

## 1. Veredito executivo

O core do ManaLoom está bem coberto por código, testes e documentação técnica,
mas **ainda não é correto afirmar que todas as raízes e lógicas estão
integralmente documentadas ou que o E2E atual está concluído**.

| Dimensão | Veredito | Evidência principal |
| --- | --- | --- |
| Backend determinístico | **PASS** | `1.589/1.589` testes `all-local` |
| Core Flutter de decks | **PASS** | `240/240` testes com Flutter pinado |
| Patrol local | **PASS** | `9/9` jornadas locais |
| Battle canônico | **PASS isolado** | `46/46` checks + `66` testes Dart; o aggregate teve um crash transitório do analysis server |
| Web pública | **PASS** | lint, build de 13 rotas, smoke HTTP e `npm audit` com 0 vulnerabilidades |
| Auth/rate limit alterado | **PASS focado** | app `6/6`; server `16/16` |
| Mecanismo do gate estatístico Lorehold | **PASS focado** | `16/16` testes do mecanismo; não é aprovação do candidato |
| Gate real Lorehold | **BLOCKED** | Candidato `138/384` contra baseline `95/384`, porém com timeouts e regressão Lumra `9/32→5/32`; deck `607` segue protegido |
| E2E determinístico agregado | **FAIL na rodada** | `8 PASS`, `2 FAIL`, `9 SKIP`; Battle caiu por crash transitório e retenção falhou |
| Retenção de relatórios | **FAIL** | 18 arquivos locais ignorados, 371.606 bytes |
| Suíte Flutter completa | **BLOCKED pelo host** | volume temporário sem espaço (`errno 28`) antes de concluir a compilação |
| E2E live/release | **NÃO EXECUTADO** | exige alvo aprovado, autorizações, migrations e cleanup |
| Produção | **NO-GO** | checkout não está limpo/congelado e não há prova live da mesma SHA |

O resultado operacional de hoje é: **core local crítico verde por recortes e
backend completo; E2E agregado ainda vermelho; release pendente**.

## 2. Identidade da rodada

- branch: `codex/free-beta-release-candidate-2026-07-17`;
- HEAD observado no início: `2813152121c4d41069f9ebbb3334eb4c6b8b1110`;
- divergência observada: 6 commits à frente de `origin/master`;
- checkout: dirty, com mudanças locais preexistentes e ajustes desta auditoria;
- Flutter aprovado: `3.44.6`, framework revision
  `ee80f08bbf97172ec030b8751ceab557177a34a6`, engine
  `83675ed27633283e7fc296c8bca22e841224c096`, Dart `3.12.2`;
- `flutter` inicialmente resolvido pelo `PATH`: `3.41.6`, incompatível com o
  código atual (`ScrollCacheExtent`) e capaz de reescrever dependências do
  lockfile. A rodada válida usou `MANALOOM_FLUTTER_BIN` apontando para o SDK
  pinado.

## 3. Mapa das raízes do core

| Área | Entrada/wiring | Lógica que decide ou muta comportamento | Fonte documental | Estado |
| --- | --- | --- | --- | --- |
| Bootstrap Flutter | `app/lib/main.dart` | providers, `GoRouter`, auth redirect, warmup e realtime coordinator | este relatório + mapa de API | **Documentado após correção de drift** |
| Auth e sessão | `AuthProvider`, `/auth/*`, auth middleware | secure token store, validação `/auth/me`, política de senha, rate limit de credenciais | mapa de API | **Documentado; mudança 21/07 registrada** |
| Deckbuilder | telas/providers de decks e `/decks`, `/import` | `DeckRulesService`, identidade, persistência, draft/validated, pricing e análise | mapa de API + relatórios de release | **Forte** |
| IA de decks | `/ai/generate`, `/ai/optimize`, `/ai/rebuild`, jobs | serviços determinísticos, candidate quality, semantic tags, provider, cache e quality gates | mapa de API | **Forte, experimental por contrato** |
| Battle e replay | app Battle, `/ai/simulate`, `/decks/:id/battle-replays` | roteamento XMage/Forge/native, persistência obrigatória e `BattleReplayReadService` | mapa de API + relatório Battle | **Forte após inclusão dos replays** |
| Life Counter e pós-jogo | rotas/telas Lotus e `/post-game-*` | stores locais, sessão, tombstones, watermark e `PostGameNoteService` | relatório 17/07 + mapa de API | **Forte local; live pendente** |
| Cards/sets/import | providers/telas e `/cards`, `/sets`, `/rules` | resolução canônica/localizada, legalidades, cache e sync backend-owned | mapa de API | **Forte; scanner deferred** |
| Binder/trades/social | providers e rotas community/binder/trades | ownership, matching, trust, locks e transições | mapa de API | **Forte; alguns shapes antigos seguem not proven** |
| Engagement/reports | comentários, denúncias, trade matches e relatórios públicos | `CommunityEngagementService`, `ShareableReportService`, migrations 030/031 | mapa de API | **Documentado nesta rodada** |
| Privacidade/comercial | Profile, CommercialProvider, `/users/me/*`, billing | export/delete, anonimização, quota/reservas e beta gratuita fail-closed | mapa de API + candidato beta | **Código/testes fortes; live depende da migration 038** |
| Persistência | PostgreSQL e migrations | `migrate.dart`, serviços transacionais e views internas | data model + mapa de API | **PostgreSQL é verdade; DDL só em migrations** |
| Operação/Hermes | `manaloom_ops_daemon.py`, sidecars, scripts e health | jobs server-owned, PG→SQLite, audits e promotion gates | runbooks + este relatório | **Relatório mestre de junho está defasado** |
| Release | scripts de build/deploy/rollback | SDK pinado, mesma SHA, digest, health, SBOM e rollback | contrato E2E + ops gate | **Bem documentado; execução live aberta** |

## 4. O que estava documentado corretamente

- PostgreSQL como fonte de verdade e Hermes/SQLite como cache/laboratório.
- Separação entre perfis determinístico, mutante isolado, live e release.
- Core Commander `generate/import → analyze → optimize/rebuild → apply → validate`.
- Contratos de decks, cards, sets, import, IA, binder, trades, mensagens,
  notificações, privacidade, billing gratuito e health/readiness.
- Segurança fail-closed para writes, migrations, provider externo e billing.
- Battle com persistência obrigatória, autorização de replay e engines
  explicitamente selecionadas.
- Life Counter local e fronteira entre prova local, device e runtime publicado.

## 5. Drift e lacunas encontradas

### Alta prioridade

1. O relatório `PROJECT_LOGIC_FULL_REPORT_2026-06-11.md` é um snapshot útil,
   mas não representa sozinho a arquitetura atual. Ele omite
   `CommercialProvider`, descreve token em `SharedPreferences`, admite `ensure*`
   como fonte de schema e trata a migração Hermes→ops como futura.
2. O mapa de API não registrava Battle replays, comentários, denúncias,
   trade matches e relatórios compartilháveis, apesar de handlers e
   consumidores ativos.
3. A mudança local de auth não estava documentada: `GET /auth/me` não pertence
   ao bucket de brute force e o app preserva sessão local em `429`, `5xx`,
   timeout ou falha de rede; apenas `401` remove credenciais.
4. O novo gate estatístico Lorehold não estava classificado pelo manifest de
   superfície Battle e quebrava o gate canônico.
5. A Web pública tinha `brace-expansion 1.1.15`, reportado como vulnerabilidade
   alta pelo `npm audit`.

### Pendências ainda abertas

- 18 outputs locais ignorados em `master_optimizer_reports`; não foram apagados
  nem manifestados automaticamente porque podem ser evidência em revisão.
- Scanner/câmera/OCR continua `DEFERRED / NOT PROVEN` para a release non-scanner.
- FCM foreground/background em aparelho físico, Sentry da SHA final, backup
  off-site e restore dessa cadeia continuam sem prova atual.
- Migrations live 038–040, deploy da mesma SHA e E2E autenticado publicado
  continuam pendentes conforme os documentos de 16–17/07.
- Alguns contratos sociais/analytics legados mantêm campos `not proven` até
  existir teste de shape dedicado.
- O gate real Lorehold permanece bloqueado apesar do agregado superior do
  candidato: timeouts e a regressão no matchup Lumra impedem promoção. A saída
  válida é manter `607` ou testar uma nova hipótese same-lane desde o início,
  nunca repetir o mesmo candidato até obter PASS.
- O aggregate E2E mostrou fragilidade de ordem: o analysis server Dart caiu no
  gate Battle depois das suítes Flutter, embora o mesmo gate tenha passado
  imediatamente antes e depois de forma isolada.
- O host ficou sem espaço temporário durante `full`/Flutter completo. A rodada
  não converte esse bloqueio de ambiente em PASS.

## 6. Validações executadas

| Comando/recorte | Resultado |
| --- | --- |
| `server/test/rate_limit_middleware_test.dart` | 16 PASS |
| `app/test/features/auth/providers/auth_provider_initialize_test.dart` | 6 PASS |
| `test_lorehold_paired_battle_statistical_gate.py` | 16 PASS |
| `dart test -P all-local` | 1.589 PASS |
| Flutter `test/features/decks` com SDK pinado | 240 PASS |
| `quality_gate.sh patrol-smoke` com SDK pinado | 9 PASS |
| `quality_gate.sh web` | PASS; 13 rotas; 0 vulnerabilidades |
| `quality_gate.sh battle` | PASS; 46/46 checks; 66 testes Dart |
| `quality_gate.sh e2e` run `20260721T140445Z` | 8 PASS, 2 FAIL, 9 SKIP |
| `quality_gate.sh report-retention` | FAIL; 18 arquivos locais |
| `quality_gate.sh full` | BLOCKED em 1.546 testes server por `errno 28` |
| Flutter completo | BLOCKED na compilação por `errno 28` |
| `git diff --check` | PASS |

Resumo estruturado do aggregate:
`/tmp/manaloom_e2e_suite_reports/manaloom_e2e_suite_20260721T140445Z/summary.json`.

## 7. Correções feitas na rodada

- classificação dos dois arquivos do gate estatístico Lorehold como
  `focused evidence/promotion`;
- atualização do lock da Web para `brace-expansion 1.1.16`;
- fixture Patrol de cadastro alinhada à política real de senha forte;
- contrato de rollback Flutter Web alinhado ao mecanismo atual de marcador
  externo `release.json`/bootstrap, mantendo digest imutável;
- documentação da semântica de sessão/rate-limit e das rotas app-facing antes
  ausentes;
- relatório e índices canônicos atualizados sem alterar status live.

## 8. Próximas ações

1. Revisar os 18 artefatos locais e decidir, por arquivo, entre remover,
   manifestar com hash revisado ou preservar como evidência ativa.
2. Liberar espaço de disco suficiente e repetir `quality_gate.sh full` e a
   suíte Flutter completa com o SDK pinado.
3. Tornar o gate E2E resiliente ao crash transitório do analysis server sem
   transformar retry em mascaramento de falha.
4. Completar a sincronização do mapa de API com guards que exijam as novas
   rotas documentadas.
5. Só depois avançar para migrations/deploy/smoke live com as autorizações e o
   cleanup exigidos pelo contrato E2E.

## 9. Critério de interpretação

- **PASS isolado** não substitui o status do aggregate.
- **SKIP** não é sucesso.
- Prova local não é prova publicada.
- Documento datado não substitui código vivo nem contrato canônico.
- Nenhuma afirmação de produção deve ser feita antes de mesma SHA, migrations,
  health/readiness, smoke autenticado e cleanup.
