# Receipt de execução — `BT-GOV-001`

Status: `PASS_LOCAL · COMMITTED · NOT_PUSHED`

Este receipt registra somente a execução de `BT-GOV-001`. Ele não autoriza
deploy, migration live, escrita em PostgreSQL live, abertura de capability nem
o início de outro ID.

## Identidade

- Branch: `codex/free-beta-release-candidate-2026-07-17`
- SHA inicial/upstream/remoto observado: `b2d3fc04f823f1c58434349a0cf0b48d74919862`
- SHA final da implementação local: `fd0397a5a97742bcb5127c7b2d08d80aca4bf738`
- Commit organizacional separado: `675f7a2f5`
- Project logic source digest da implementação: `f3628ca3199dce784820a3dc63c9a6d7312a229098ce0ee5fc17a93f3d7e400a`
- Project logic source digest do fechamento: `44ab0563e6703bad2d1a8a47128d318d88401c050fb98b07d38a3b2a299ab042`
- Registry source SHA-256 do fechamento: `baed1f2b2ccd0cbc9620fa073d13311d5a8354513d2222a324881ca70d003016`
- UI source digest: `d517adb65beaa0a759a6ce5304779d21698850bd9212c6e5536b1615d5a11cee`
- Policy: `brewtact_free_beta_2026-08-13`
- Policy blob SHA-256: `ace782b3969a9ba5a2691f5ca3d97360927919739cd16c796d7b36e8124d754d`
- Matriz: `29/29 OFF`, `allowed=false`, sem receipt live por capability
- Início registrado: `2026-08-13T20:44:50Z`
- Checkpoint final deste receipt: `2026-08-24T16:26:57Z`
- Autorização usada: código local, PostgreSQL descartável e produção
  read-only por HTTPS GET

## Resultado implementado

A decisão corrente continua única: BrewTact em beta controlada e gratuita,
Web/Android, sem comércio e com as 29 capabilities fechadas. A implementação
eliminou contradições observáveis e reforçou os limites dessa decisão:

- Profile mantém somente identidade, segurança, privacidade e ciclo da conta
  no plano de controle quando a matriz está all-OFF; superfícies de fichário,
  marketplace, trade, social, localização e IA ficam ocultas;
- o `PATCH /users/me` omite campos de produto ocultos em vez de reenviá-los;
- planos, medidor de IA e textos legais não prometem IA, trade, publicação,
  plano Pro, checkout, preço futuro ou beta pública;
- `/users/me/plan`, o mapa da API e o contrato de arte usam “beta controlada”;
- redirects de aposentadoria da Web pública aceitam apenas `/` e `/pricing`,
  nunca `/app`;
- deploy live do Flutter Web carrega a policy commitada e bloqueia antes de
  aprovação ou mutação enquanto não houver capability ON com timestamps de
  verificação live; a matriz corrente all-OFF é, portanto, inalcançável para
  deploy;
- o contrato operacional declara e valida as 29 capabilities.

Nenhuma capability foi aberta, nenhum dado live foi alterado e nenhum deploy
foi executado.

## Evidência local

| Camada | Resultado |
| --- | --- |
| `project_logic --write/--check` | `PASS`; 9 artefatos gerados pela ferramenta, sem edição manual |
| Auditorias determinísticas | `PASS`; 124 testes |
| Contratos de release | `PASS`; 32 contratos |
| Backend completo | `PASS`; todos os batches determinísticos |
| App completo | `PASS`; 1.564 testes passaram e 1 teste Chrome-only ficou explicitamente skipped no runner VM |
| Web pública real | `PASS`; lint, build Next.js, smoke e `npm run test:contract` |
| UI automatizada | `PASS_AUTOMATED`; matriz de teclado/auditoria com 59 testes |
| PostgreSQL descartável | `PASS`; 79 tabelas, 6 views, 98 FKs, 58 migrations; cluster loopback removido |
| Deck/IA/Learning | `PASS_CODE_ONLY`; contenção local, sem promoção ou escrita live |
| Engine capabilities | `PASS`; 96/96 checks, 20 capabilities |
| Ops/worker | `PASS`; 18 testes do daemon |
| Custom lint | `PASS`; app, backend e pacote de lint |
| Patrol local | `PASS`; 9/9 fluxos do harness; CLI em device não executada |
| Dependências | `PASS`; app, backend, lint e project logic |
| Segredos | `PASS`; gitleaks 8.30.1 e zero credencial live literal |

### Continuação local de 2026-08-24

- A separação atômica fechou em dois commits: `675f7a2f5` para o modelo
  operacional WIP-1 e `fd0397a5a97742bcb5127c7b2d08d80aca4bf738` para a
  implementação/evidência de `BT-GOV-001`. Ambos passaram pelo hook normal;
  não houve `--no-verify`.
- O lock Gradle stale deixado pela remoção de `url_launcher_android` foi
  regenerado e validado por `:app:checkProfileAarMetadata`, pelo build profile e
  pela instalação no Samsung físico.
- A fixture autenticada usou PostgreSQL loopback descartável. O cleanup
  confirmou banco removido, listeners zerados e credenciais temporárias
  apagadas; nenhum PostgreSQL live, Hermes ou SQLite foi escrito.
- O Samsung SM-A135M físico (`R58T300SREH`, Android 14, `ro.kernel.qemu=0`)
  concluiu 54/54 checkpoints. Chrome/WebDriver real concluiu mobile, desktop,
  wide, Battle Live e Packs 02–08.
- Os 26 manifests referenciam 456 capturas no digest UI `d517adb65b…`. Todas
  foram abertas em 42 pranchas, sem bloqueador novo; as pranchas auxiliares e o
  ChromeDriver temporário foram movidos para a Lixeira após a revisão.
- `./scripts/manaloom_local_ci.sh full` passou integralmente no perfil
  determinístico, incluindo project logic, 124 auditorias, 32 contratos de
  release, backend completo, 1.564 testes Flutter com um skip de ambiente,
  Web pública, UI audit/proof, custom lint, Patrol 9/9, dependências e schema
  PostgreSQL/tbls descartável.
- Nenhum push, deploy, migration live, capability ON, promoção de deck/regra ou
  escrita em runtime foi executado.

## Evidência UI

- `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED`: `PASS` no mesmo
  digest `d517adb65beaa0a759a6ce5304779d21698850bd9212c6e5536b1615d5a11cee`.
- Cobertura: 26 manifests, 26 perfis, 456 screenshots únicos e zero entrada
  proibida de console; os hashes, dimensões e caminhos foram reconciliados.
- Runtime físico: Samsung SM-A135M, 54 checkpoints, incluindo Life Counter
  nativo em landscape; o target está atestado como `android_physical`.
- Revisão humana/agente: 42/42 pranchas abertas. Não há finding bloqueante.
- Follow-ups não bloqueantes permanecem no aggregate: densidade wide,
  truncamento de identidades longas, affordance de carrossel, tab compacta e
  ajustes de contexto/anchor em fixtures.
- TalkBack humano, hardware smoke Android e teclado Web real continuam gates
  separados de release e não receberam crédito.

## Produção read-only

Observação pública anterior, feita somente com HTTPS GET em
`2026-08-14T17:55:26Z`:

- candidato commitado: `b2d3fc04f823f1c58434349a0cf0b48d74919862`;
- servidor: `a6ee09c8f16cf17c2867de4b089e5e65b3527254`;
- relação Git: `SERVER_BEHIND`, 11 commits;
- `/health`: `200`, saudável, mas sem resumo de release capabilities;
- `/ready` e `/health/ready`: `200`, ainda no contrato anterior, migration 057
  e runtimes AI/Battle habilitados;
- `/capabilities`: `404 Route not found`;
- request IDs foram ecoados.

Isso prova liveness da revisão antiga anunciada, não a implementação local,
same-SHA, image digest ou prontidão do candidato. Não houve deploy, SSH, DML,
migration ou chamada HTTP mutante.

## Auditoria e rollback

- Auditoria independente das fontes: `GO`; nenhuma contradição material
  residual encontrada entre decisão, app, API, Web pública e deploy.
- Auditoria do snapshot documental/final: `GO`; a separação atômica foi
  concluída, os hashes do aggregate UI foram reconciliados e o gate `full`
  terminou verde no SHA de implementação.
- Rollback local: reverter apenas o patch de `BT-GOV-001` e regenerar os 9
  artefatos de project logic; não existe estado live para restaurar.
- Risco residual intencional: o loader canônico aceita apenas a matriz all-OFF,
  então uma abertura futura exige revisão deliberada do contrato. O helper
  atual verifica ON + timestamps, mas ainda não valida receipt durável, SHA ou
  target; essa prova forte pertence a `BT-GATE-002` e não recebe crédito aqui.

### Atomicidade do worktree

O pacote organizacional preexistente foi isolado em `675f7a2f5`. O delta
funcional, testes, fontes geradas e evidência UI oficial foram commitados em
`fd0397a5a97742bcb5127c7b2d08d80aca4bf738`. `git diff --cached --check`, o
hook `quick` e o gate `full` passaram; os documentos de fechamento ficam em
commit posterior para poder referenciar o SHA imutável da implementação.

## Veredito

`PASS` local para `BT-GOV-001`.

Gate-eligible: `true` para fechamento local. Git SHA da implementação:
`fd0397a5a97742bcb5127c7b2d08d80aca4bf738`. Push/deploy não executados.
Produção continua classificada como `SERVER_BEHIND` na última observação; isso
não invalida o fechamento local nem autoriza promoção. A fila avança para
`BT-DOC-001`.
