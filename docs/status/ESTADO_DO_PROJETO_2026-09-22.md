# BrewTact — estado do projeto — 2026-09-22

Lifecycle: `CURRENT_CONTEXT · VERIFIED_STATE · NO_PRIORITY_AUTHORITY`. Este documento descreve
**onde o projeto está de verdade** e **o que falta para a beta controlada**. Não define prioridade
(isso é da decisão e do backlog) e não autoriza mutação. Toda afirmação aqui foi verificada na
fonte primária em 2026-09-22; a evidência linha a linha está em
[`docs/verdade/FATOS.md`](../verdade/FATOS.md) (147 fatos: 129 da auditoria e 18 do adendo pós-medição, pós-leitura da produção e da observação pública de 2026-09-22) e a origem de cada correção em
[`docs/verdade/PLANO_DE_CORRECAO.md`](../verdade/PLANO_DE_CORRECAO.md).

- Checkout: `codex/free-beta-release-candidate-2026-07-17` @ `d15beb05b` (= `origin`), com a
  correção documental de 2026-09-22 **na árvore de trabalho, sem commit**.
- Pedido que originou este documento: "não pode haver mais divergência de dados; 100% de noção do
  projeto num todo; docs errados → corrigir ou remover; deixar só o verdadeiro".
- Método: 7 auditores conferiram 1.913 afirmações de 66 documentos ativos contra código, registry
  e git; 234 divergências encontradas; 39 contradições entre documentos resolvidas no código;
  correções aplicadas em 8 lotes disjuntos e revisadas por diff.

---

## 1. Em uma frase

O BrewTact está **construído e trancado no repositório, mas não em produção**.

- **No repositório:** as 11 jornadas existem em código, mas **0 das 29 capabilities está ligada**.
  Só o plano de controle de conta responde, e ele tem **quatro buracos de segurança**.
- **Em produção:** roda uma versão de 2026-08-03, anterior à tranca, com cadastro aberto, IA e
  Battle ligados e os mesmos quatro buracos. A contenção de capabilities nunca chegou a `master`.
  O banco está parado desde 2026-08-03, sem a migration 058, e cartas e legalidades não se atualizam
  desde 2026-06-06.
- **As tarefas:** **nenhuma das 49 P0 CORE medidas está atendida.** O slot `NOW` (`BT-SCP-001`) está
  aberto há quatro semanas. Um dos dois pontos que o travavam, o `npm audit` do site público, foi resolvido em 2026-09-22 (`BT-WEB-003`, falta o receipt); o outro é o último pack de
  evidência de UI.

---

## 2. O alvo

O alvo **não é release público**. A decisão vigente (`docs/status/CURRENT_PRODUCT_DECISION.md`,
2026-08-25) é `NO_GO_PUBLIC_RELEASE` com candidato **`CONTROLLED_FREE_BETA`**: coorte pequena,
Web e Android, oferta única "Beta gratuita", sem cobrança, teto de 120 ações de IA/mês. iOS e
VoiceOver estão fora de escopo por decisão. "Fechar o app" = abrir essa beta.

O que a abertura exige, por camada (`docs/MANALOOM_E2E_RELEASE_CONTRACT.md` §Critério de conclusão):

1. **Conclusão local**: gates `full`, `deps`, `custom-lint`, `ui-audit`, `patrol-smoke`, `battle`,
   `engine-transition`, `report-retention` e o E2E determinístico sem falha estrutural; toda UI
   alterada com `PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED`.
2. **Conclusão de release**: build instalável, jornada crítica em aparelho representativo, smoke
   live aprovado com cleanup, `/health` e `/ready` batendo com o SHA implantado, nenhuma migração
   pendente, pins XMage qualificados.
3. **Abertura de capability**: cada linha `OFF_UNTIL_P0_RECEIPT` só vira `ON` com receipt da mesma
   revisão. Não é trocar flag: é provar.

---

## 3. Onde estamos — números verificados

| Medida | Valor | Fato |
| --- | --- | --- |
| Capabilities ligadas | **0 de 29** (`allowed`: 0; `release_capability`: 29 `off`; `live_verified_as_of`: 29 `null`) | 2.1 |
| Portões fail-closed que consomem a política | **3**: servidor, app e o scheduler `manaloom_ops_daemon.py` (16 jobs; com tudo off só 1 roda) | 2.4 |
| Rotas do app | 46 `GoRoute` + 1 `ShellRoute`; **10 alcançáveis** hoje (login, recuperação, verificação, legal, home, onboarding, planos, perfil) | 3.1, 3.3 |
| Rotas do servidor | 120 arquivos de handler; **29 pares** método+path no plano de controle (sem capability) | 3.9, 2.5 |
| Coerência app↔servidor | 142 chamadas HTTP, **0 quebradas**, 0 rotas não classificadas | `docs/flows/_coerencia_transversal.md` |
| Jornadas documentadas | **11 de 11**, todas implementadas; alcançável hoje: plataforma (sim), auth e comercial (parcial), as outras 8 **não** | `docs/flows/README.md` |
| Tarefas no índice canônico | **244** depois das decisões do dono de 2026-09-22 (227 da correção documental + 17 criadas pelas decisões): PASS 3 · IN_PROGRESS_CONTAINED 2 · IMPLEMENTED_LOCAL 7 · **EVIDENCE_REQUIRED 12** · TODO 103 · BLOCKED_BY_P0 80 · DEFERRED 33 · WAITING_EXTERNAL 4 | 11.1 |
| P0 que bloqueiam a primeira coorte | **64 `P0 CORE` + 6 `P0 LIFE` abertas = 70** (escopo decidido em 2026-09-22, D-07). As 64 são as 55 da correção documental, mais 9 criadas pelas decisões, mais o `BT-PRIV-003` promovido, menos o `BT-UX-SWAP-001`, que passou a `P0 AI`. Das 146 P0 abertas, as 26 `P0 AI` ficam para a segunda onda e as demais bloqueiam só a própria capability | 11.2 |
| P0 CORE medidas contra o código | 49 de 55: **nenhuma atendida**; 433 asserções, 16% provadas | §5 |
| Produção — código (observada em 2026-09-22) | `a6ee09c8f` (2026-08-03): **39 commits atrás** da branch de trabalho e 10 atrás de `origin/master`; **sem a política de capabilities** (`/capabilities` 404); IA e worker de Battle ligados; cadastro sem trava. A contenção (`b2d3fc04f`) **não está em `master`**; a branch de trabalho tem 29 commits fora dela | 11.4, 11.16, 11.17 |
| Produção — banco (lido em 2026-09-22) | Ledger em **057** (a 058 não foi aplicada); 99 tabelas em `public` (20 fora do repositório, 7 delas usadas pelo código sem migration); 1.033 tabelas de backup em `manaloom_deploy_audit`; **nenhuma atividade desde 2026-08-03**; catálogo parado desde 2026-06-06 | 11.10–11.15 |
| Trabalho não commitado fora da árvore | Triado em 2026-09-22 (D-52): 6 worktrees removidos (5 limpos e o `cold-repro-fix`, superado pelo `BT-CI-001`), 2 registros mortos podados e o classificador do cleanroom trazido para a branch (D-03). Ficam 3 worktrees com trabalho não commitado, todos com backup local em `refs/backup/2026-09-22/`; nenhum no remoto, porque o `pre-push` roda o `full`, vermelho até o `BT-UIEV-001` fechar | §7, 11.6 |
| Testes do produto | ~797 arquivos (server 401 · app 237 · integration 147); a suíte do app deu **1604 verdes, 0 falhas** com o Flutter pinado | 5.11 |
| `integration_test/` no gate | **Nenhum gate executa** os 147 arquivos de integração | `docs/flows/card_catalog.md` |
| Commits desde o último que passou pelo hook (2026-09-04) | **19**; 16 declaram `--no-verify`; 2 sem ID de tarefa; 2 com IDs que não existiam no backlog | 5.7, 4.8 |
| Evidência de UI | 22 dos 23 manifests no digest corrente `8bba809c`, mas **0 casam o hash registrado** em `latest.json` (ainda no digest antigo) → gate falha fechado | 6.3 |
| Drift dos motores | Medido em 2026-09-20: XMage **+775** commits, Forge **+780** upstream; `pin_contract_failures 0`; próxima auditoria será pulada se a árvore continuar suja | 7.4, 7.5 |
| Migrations | 58; `/health/ready` exige `latest_migration = '058'` | 5.14 |

---

## 4. O que bloqueia agora — caminho crítico imediato

Tudo passa por fechar o slot `NOW`:

```
BT-SCP-001 (NOW, há 4 semanas)
├── gate `full` morria no 2º de 6 estágios: `npm audit` do site público
│   └── BT-WEB-003 — next 15.5.21 → 15.5.25 (RCE crítico), sharp 0.35.4   [feito em 2026-09-22: audit 0; falta receipt]
└── gate `ui_live_evidence` falha fechado
    └── BT-UIEV-001 — recapturar play-vs-ai-web-real (corrida de handoff em
        manaloom_play_vs_ai_e2e.sh: 2ª chamada do E2E isolado para em
        "build output has a consumer") + reescrever latest.json com 23 hashes
        [22/23 packs já verdes; ChromeDriver pinado; teste do E2E corrigido em d08c18717]
```

Essas duas dependências agora estão declaradas no backlog (`BT-SCP-001` depende de
`BT-UIEV-001` e `BT-WEB-003`). Até 2026-09-21 o registro dizia o inverso — `BT-UIEV-001`
dependendo de `BT-SCP-001` —, o que era um impasse: nenhum dos dois podia fechar primeiro.

Depois disso, nunca foram alcançados — e podem revelar vermelho — os quatro estágios seguintes do
`melos run quality` (`ui-audit`, `custom-lint`, `patrol-smoke`, `dependency_audit`) e o gate de
schema.

Só com `BT-SCP-001` fechado a fila anda, agora em duas raias (D-02): na de servidor vêm o
`BT-GOV-002` e o `BT-REL-000` (pôr a contenção no ar); na do app, o **`BT-UX-KIT-001`** (kit visual
em `app/lib`), decidido pelo dono em 2026-09-21 e mantido pela D-06 em 2026-09-22.

---

## 5. Quanto falta para a beta — medição das P0 CORE

Método: as 49 P0 CORE de HEAD foram decompostas em asserções verificáveis e conferidas no
código; cada grupo passou por um cético instruído a derrubar a medição; uma consolidação montou
o grafo efetivo de dependências. Nenhum teste foi executado: "provado" significa que existe um
teste que afirma aquilo e ele foi lido. Relatório completo e um relatório por grupo:
[`docs/flows/_p0/README.md`](../flows/_p0/README.md).

**Os 9 céticos julgaram a primeira medição "otimista demais", sem exceção.** Rebaixaram 27
asserções que estavam como provadas: testes que só leem o código-fonte como texto, proteções que
existem só no caminho Web, guardas ausentes. Os números abaixo são os finais.

| Medida | Valor |
| --- | --- |
| Asserções | **433**: 69 prontas e provadas (16%) · 67 prontas sem prova (15%) · 154 parciais (36%) · 143 inexistentes (33%) |
| Tarefas | **nenhuma atendida** · 4 quase lá · 12 pela metade · 31 mal começadas · 2 não começadas |
| Pelos três eixos | existe por inteiro: 31% · provado: 16% (fora da contenção de escopo, 10,6%) · aberto: 0% |
| Trabalho, em unidades | ~692 arquivos tocados (soma com repetição) · ~345 testes novos · 8 migrations novas · aplicar a 058 em produção |
| Exigem prova viva | 40 das 49 |
| Dependem de decisão humana | 47 das 49 — 50 decisões em 23 grupos (§9) |
| Testes que afirmam o contrário do aceite | 15 arquivos; fechar essas tarefas exige reescrevê-los, não só somar testes |

- **Quase lá:** `BT-AUTH-003` (falta igualar o tempo de resposta e o limite por e-mail),
  `BT-OFFER-001` (falta só o receipt, que depende do gate amplo), `SCOPE-P0-SOC-00` (falta um
  teste de negação em runtime por rota social e o receipt) e `BT-GATE-001`.
- **Não começadas:** `BT-AUTH-006` (convite/allowlist da coorte — zero linhas de código) e
  `BT-CAP-001` (capacidade real por serviço).
- **Só falta receipt ou commit:** `BT-CI-001` (`d83e9b1e1`, `07014b431`), `BT-DOC-006` (feito na
  árvore), `BT-OFFER-001`; fora das P0 CORE, `BT-NAV-01` (`b2d3fc04f`).
- **Três estados estavam errados e foram corrigidos no backlog** (a evidência está na linha):
  `SCOPE-P0-TRD-00` e `BT-GATE-002` saíram de `EVIDENCE_REQUIRED` para `TODO` (falta código,
  não só receipt); `BT-DB-004` saiu de `IN_PROGRESS_CONTAINED` para `TODO` (a contenção não vale
  para 11 CLIs e 47 pacotes SQL que ainda alteram schema). Em outras 12 tarefas o estado ficou,
  mas a linha agora diz o que já existe, para ninguém recomeçar do zero.

### O escopo foi decidido em 2026-09-22 (D-07)

- **Primeira coorte:** núcleo + contador de vida = **64 P0 CORE + 6 P0 LIFE = 70**. Das 64, 48
  foram medidas (as 49 de HEAD menos o `BT-UX-SWAP-001`); as outras 16 (as 6 registradas antes da
  medição, o `BT-PRIV-003` e as 9 criadas pelas decisões) e as 6 P0 LIFE não foram.
- **Segunda onda:** Analyze/Optimize, com as 26 P0 AI (24 + `BT-UX-SWAP-001` + `BT-AI-033`).

Antes da decisão, as opções eram a beta mínima (55 P0 CORE) e a pretendida pelo §2.2 do backlog
(55 + 24 P0 AI + 4 P0 LIFE = 83).

### O caminho crítico

Depois das decisões de 2026-09-22 (D-08), `BT-UX-A11Y-001` e `BT-UX-PROOF-001` não dependem mais
das P1 `BT-UX-DECK-*` nem das `BT-UX-SWAP-*`, e o `BT-REL-003` não depende mais do `BT-GATE-005`.
No grafo declarado, a corrente mais longa até o GO tem agora 7 elos (`BT-UIEV-001 → BT-SCP-001 →
BT-REL-001 → BT-REL-002 → BT-REL-003 → BT-QA-001 → BT-DEC-001`). O grafo efetivo abaixo é o da
medição, com arestas não declaradas, e precisa ser recalculado na próxima medição.

- **Corrente mais longa do grafo efetivo: 12 elos, do banco ao GO/NO-GO:**
  `BT-DB-001 → BT-DB-004 → BT-DB-002 → DCK-P0-01 → DCK-P1-04 → BT-UX-DECK-001 → BT-UX-DECK-003 →
  BT-UX-A11Y-001 → BT-UX-PROOF-001 → BT-REL-003 → BT-QA-001 → BT-DEC-001`. Passa por duas
  tarefas que não são P0 CORE. O grafo declarado dá 10 elos e deixa **32 P0 CORE fora dos
  ancestrais do GO/NO-GO**: a decisão de abrir não as exige formalmente.
- **O que mais destrava:** `BT-UIEV-001`, com 29 descendentes. **Cabeça da corrente:**
  `BT-DB-001`, com folga zero e 27 descendentes; só mexe em servidor e scripts.
- **Ciclo escondido:** `BT-REL-001` depende de `BT-OBS-001`, mas o alerta de release de
  `BT-OBS-001` precisa da identidade de `BT-REL-002`, que depende de `BT-REL-001`. Como está, não
  fecha; é preciso partir `BT-OBS-001`.
- **16 tarefas podem começar hoje** sem pré-requisito aberto: 14 P0 CORE e 2 não-CORE.

### As duas travas de processo

Nenhuma é código; as duas são decisão do dono.

1. **WIP-1.** Mantida a regra, o caminho real não é a corrente de 12. É a soma das 55 P0 CORE,
   mais 9 não-CORE puxadas pelo grafo, **em série**.
2. **O digest de UI é global.** 27 das 55 tarefas (mais 2 condicionais) mexem em `app/lib` ou
   `app/web`. Cada uma deixa o pre-push vermelho até alguém recapturar os 23 manifests (439
   capturas) e reler todas. É por isso que 16 commits saíram com `--no-verify`. Sem política de
   lote, a prova de UI se paga uma vez por tarefa.

Decididas em 2026-09-22: D-02 (duas raias, com WIP-1 em cada uma; o contrato da fila muda no
`BT-GOV-002`) e D-03 (recaptura em lote). O classificador de escopo staged entrou em `ac70f3d98`:
commit sem UI passa pelo `pre-commit` sem a prova de UI, e os cinco commits de 2026-09-22 saíram
sem `--no-verify`.

### A ordem que a medição sugere para começar

1. `BT-WEB-003`: o desbloqueio mais barato (2 a 3 arquivos, sem teste novo, fora do digest); tira
   um RCE crítico do site público e é o primeiro estágio a derrubar o gate.
2. `BT-UIEV-001`: o que mais destrava. Antes, juntar todas as mudanças de `app/lib` da
   contenção, para pagar a recaptura **uma vez**.
3. `BT-SCP-001`: fecha o NOW. A mesma execução verde dá receipt a `BT-OFFER-001`, `BT-CI-001` e
   `BT-DOC-006`.
4. `BT-DB-001`: cabeça da corrente, folga zero. A leitura de produção que ela exige foi feita em
   2026-09-22 (inventário e diff no receipt `docs/qa/execution/2026-09-22/prod-readonly-estrutura-e-contagens.md`); falta torná-la reproduzível e
   fechar o receipt da tarefa.
5. `BT-DB-004`: próximo elo, mecânico e fora do digest.

**Isso diverge da ordem decidida pelo dono em 2026-09-21** (kit visual logo depois do
`BT-SCP-001`). A decisão continua valendo, porque prioridade é dele. O que a medição acrescenta: o
kit tem folga de 3 elos no caminho crítico e força outra recaptura de UI; `BT-DB-001` e
`BT-DB-004` estão na corrente com folga zero e não tocam no digest. Resolvido em 2026-09-22 pela
D-06: banco e kit andam juntos, cada um na sua raia. `BT-WEB-003` foi feito no mesmo dia
(`8f9427bb4`).

---

## 6. O que quebra a jornada antes de qualquer capability abrir

### Alcançável hoje, mesmo com tudo desligado

O plano de controle de conta responde com 29/29 capabilities off, e é ali que estão quatro
buracos. Todos foram confirmados no código:

1. **A exportação de todos os dados sai só com o token de sessão**, sem reautenticação: o
   middleware de `/users` tem apenas `authMiddleware` (`server/routes/users/_middleware.dart`).
   Um teste afirma que isso deve dar 200 (`server/test/privacy_account_live_test.dart:145-149`).
2. **`DELETE /users/me` confere a senha sem limite de tentativas**: o bucket de credenciais do
   rate limit só cobre `/auth/*` (`server/lib/rate_limit_middleware.dart:348-357`).
3. **O login denuncia quais e-mails têm conta**: conta inexistente lança antes do bcrypt
   (`server/lib/auth_service.dart:282-283`, contra `:294`), então o tempo de resposta difere. O
   login também devolve o texto da exceção (`server/routes/auth/login.dart:60`).
4. **`GET /reports/:id` continua servindo o snapshot de um deck depois de o deck ser apagado**
   (`server/lib/release_capability_policy.dart:584-585`).

**E a produção não roda este código.** A contenção de capabilities (`b2d3fc04f`, 2026-08-13)
**não está em `master`**, e a branch de trabalho tem 29 commits fora dela. Observada em 2026-09-22
por `GET` público, a produção roda `a6ee09c8f` (2026-08-03):
- sem a política de capabilities (`/capabilities` 404);
- com a IA e o worker de Battle ligados;
- com o cadastro sem trava, e cada conta nova ganha 120 chamadas de IA por mês.

Os quatro buracos acima existem também nessa versão. O marketplace dela não filtra nem visibilidade
nem bloqueio (FATOS 11.16–11.17). O "tudo desligado" descreve o repositório, não o que está no ar.

### Quebram a jornada quando as capabilities abrirem

Achados **confirmados** pela verificação adversarial dos 11 fluxos (detalhe e arquivo:linha em
`docs/flows/README.md`, "Os 15 achados mais graves"). Só o 12 tem ID (`BT-AI-032`); os demais
entram como tarefas quando o dono priorizar (D-53 do registro de decisões, §9).

| # | Achado | Efeito para quem usa | Onde |
| --- | --- | --- | --- |
| 1 | O portão de rota nega **tudo** durante cada refresh de capabilities | usuário expulso de `/notifications`, `/decks`, `/collection` a cada retomada do app; ninguém é devolvido | `app/lib/main.dart:422`; `release_capabilities.dart:273-277` |
| 2 | A primeira tela autenticada é `/onboarding/core-flow`, e sob a política vigente é **beco sem saída** | usuário da beta entra e não sai do onboarding | `auth_provider.dart:32`; `main.dart:518-528` |
| 3 | `deck_version_at` é `DateTime.now()` a cada requisição | seletor de cartas do pós-jogo morto em qualquer partida > 5 min | `server/routes/decks/[id]/index.dart:831` |
| 4 | Apply da otimização de IA passa por `PUT /decks/:id` (`deck_replace_all`) mas o app libera só por `ai_analyze_optimize_advisory` | usuário gasta a cota de IA, aceita, e o apply morre em 404 | `deck_details_screen.dart:2538`; `release_capability_policy.dart:389-392` |
| 5 | `capability_unavailable` chega **cru** na tela; o tradutor prefere `error` a `message` | textos técnicos em inglês como mensagem de produto; mensagens em português do servidor descartadas | `friendly_error_mapper.dart:266,316-318` |
| 6 | Trocar senha devolve `user` truncado e o app sobrescreve o completo | e-mail verificado vira "pendente", nome e avatar somem — **alcançável hoje** | `auth_service.dart:778-781`; `auth_provider.dart:485-518` |
| 7 | Splash navega antes de validar o token | sessão válida + rede lenta = tela de login pisca | `splash_screen.dart:50-71` |
| 8 | Quem já está logado não consegue usar o link de recuperação de senha | `/reset-password?token=` é rota de auth e redireciona para `/home`, descartando o token | `main.dart:334-338,414-424` |
| 9 | `GET /cards/printings?sync=true` é anônimo, escreve no banco e chama a Scryfall sem timeout nem cache | amplificação permanente contra terceiro; DML por chamador anônimo | `server/routes/cards/printings/index.dart:44,318` |
| 10 | OpenAPI gerado declara `bearerAuth` em 9 rotas anônimas | qualquer auditoria de segurança que leia o spec conclui o oposto da verdade | `project_logic_generator.dart:3642-3645,3677-3680` |
| 11 | `POST /import/to-deck` cria deck **sem e-mail verificado** | fronteira de verificação assimétrica: `binder` exige, `import` não | `server/routes/import/_middleware.dart:8` |
| 12 | Um cron apaga em 30 min os jobs de IA cuja retomada o app implementa | job perdido para quem fecha o app | `cleanup_optimize_telemetry.dart`; `AI_JOB_RETENTION_MINUTES=30` → **`BT-AI-032`** |
| 13 | 4 eventos de ativação do onboarding rejeitados pelo allowlist do servidor, em silêncio | esses passos não existem no funil | `activation-events/index.dart:10` |
| 14 | Segunda nota do mesmo pós-jogo dá 409 engolido; `deleteNote` trata 404 como sucesso | nota que nunca sincroniza; nota apagada que ressuscita | `post_game_note_store.dart:83,174` |
| 15 | `GET /community/marketplace` expunha fichário ignorando privacidade e bloqueios | **corrigido na árvore** (não commitado), com teste por mutação | `server/routes/community/marketplace/index.dart` |

---

## 7. As quatro frentes de 2026-09-21, reconciliadas com o índice canônico

Quatro sessões trabalharam em paralelo em 2026-09-21 (violando `WIP-1`; registrado na fila como
exceção não autorizada). O que cada uma produziu, e onde isso entra no backlog:

| Frente | Produziu | Estado | Entra no backlog como |
| --- | --- | --- | --- |
| **Gate de evidência** (`BT-UIEV-001`) | ChromeDriver pinado em um lugar; 22/23 packs recapturados; perfil Android capturado (AVD consertado com `-wipe-data`); E2E do play-vs-ai corrigido | 5 commits no origin; falta 1 pack + `latest.json` | `BT-UIEV-001` (Épico J, criado hoje) · `BT-CI-001` (fechado, receipt pendente) |
| **Contador de vida** | Protótipo HTML com a linguagem nova (azulejos, numerais, vidro escuro); 13 telas secundárias convertidas e provadas no iPhone (18 provas); suíte própria 83/83; regra ΔE ≥ 25 para cor de estado | `docs/design/life-counter-prototype/`, untracked; ondas 9–10 não começaram | Insumo de `BT-UX-KIT-001` e do Épico H (`LC-P0-*`); **a porta do protótipo para Flutter ainda não tem ID** |
| **Consistência visual** | Auditoria de 85 telas (4–5/10 contra o contador; 213 cheiros de formulário; errata de 12/92 linhas); kit CSS + 114 tokens; spec de 1.635 linhas; packet `BT-UX-KIT-001`; mockups de onboarding (6,5/10) e gerador (júri fechado: "Bancada do comandante") | `docs/design/`, untracked | `BT-UX-KIT-001` (Épico D, criado hoje, próximo do horizonte) · alimenta `BT-UX-IMG/FIX/SWAP/A11Y/PROOF-001` |
| **Fluxos** (esta) | 11 fluxos documentados com cético; coerência app↔servidor; superfícies não cobertas; correção do marketplace; tabela de fatos; correção documental | `docs/flows/`, `docs/verdade/`, árvore de trabalho | `TRD-P0-01` (marketplace como evidência de contenção) · achados de §6 → IDs a criar · `BT-DOC-006` (3º portão, criado hoje) |

### Trabalho fora da árvore principal

Além das quatro sessões, há trabalho de agentes anteriores em worktrees do Codex que nenhum
documento enxergava. **Nenhuma das quatro branches com trabalho está no remoto**: se este disco
falhar, o trabalho se perde.

| Worktree (`~/.codex/worktrees/`) | Branch local | Não commitado | O que contém | Leitura |
| --- | --- | ---: | --- | --- |
| `manaloom-bt-scp-001-cleanroom` | `codex/project-logic-cold-repro-fix-v2` | 12 staged | Classificador de escopo para o pre-commit rodar a evidência de UI só quando há UI no commit (`scripts/manaloom_staged_ui_scope.py` + 2 testes), ajustes no hook, no `AGENTS.md` e no contrato E2E | Trabalho de `BT-SCP-001` não incorporado; ataca a trava 2 da §5 **Trazido para a branch em 2026-09-22 (D-03)**, com um conserto no parser; o worktree fica, com backup em `refs/backup/2026-09-22/` |
| `manaloom-bt-ux-fix-001` | `codex/bt-ux-fix-001` | 11 | Fixtures patológicas de layout (deck e trade) e a ficha `BT-UX-FIX-001.md` | Trabalho de `BT-UX-FIX-001` não incorporado Backup local em `refs/backup/2026-09-22/` (D-52); publicar como branch remota espera o `pre-push` verde |
| `manaloom-project-logic-cold-repro-fix` | `codex/project-logic-cold-repro-fix` | 11 staged | Correção de cold-repro do project logic | Provavelmente superado: o teste de cold-repro já está na árvore via `BT-CI-001`; conferir antes de descartar **Conferido e removido em 2026-09-22 (D-52)**: o HEAD tem versões mais novas de todos os arquivos; o estado ficou em `refs/backup/2026-09-22/` |
| `manaloom-ui-home-wave-01` | `codex/ui-home-wave-01` | 8 | Tema, `main_scaffold` e home (base `406d7dd53`, 2026-08-25) e a ficha `BT-UX-SYS-001.md` | `BT-UX-SYS-001` **não existe no backlog**; trabalho visual anterior à régua do contador Backup local em `refs/backup/2026-09-22/` (D-52); revisitar depois do kit |
| `38e8`, `91ba`, `d18b`, `f931` | destacados em `704c2c11c` | 0 | nada | **Removidos em 2026-09-22 (D-52)** |
| `manaloom-project-logic-delivery` | `codex/project-logic-reproducible-delivery` (igual ao remoto) | 0 | nada | **Removido em 2026-09-22 (D-52)**; o commit `354983a1e` já estava na branch de trabalho |
| 2 registros em `/private/tmp` | — | — | a pasta já não existia | **Podados em 2026-09-22** |

Os três primeiros partem do commit **`0779595e2`** (2026-08-28, "checkpoint Android proof
containment", 10 arquivos: capabilities, push, telas de deck), que **não tem equivalente na
branch de trabalho** (`git cherry`), mas está no remoto (`origin/codex/BT-SCP-001-cleanroom`); o
trabalho não commitado em cima dele, não. A triagem é decisão do dono (D-52 do registro de
decisões, §9).

**Regra que saiu disso e vale daqui para a frente:** trabalho sem ID no backlog não existe para a
governança. `BT-CI-001` e `BT-UIEV-001` foram trabalho real de dias, commitados com IDs que não
existiam; hoje têm linha.

---

## 8. O que foi corrigido na documentação em 2026-09-22

| Ação | Qtde | O quê |
| --- | --- | --- |
| Corrigidos | 28 documentos | decisão de produto (`/app`, rota do play-vs-ai, 2 capabilities fora da matriz); mapa operacional (três portões, gates de hoje, ChromeDriver, 19 commits); backlog (3 tarefas já feitas, 12 que alegavam implementação sem evidência, 3 estados desmentidos pela medição, dependências do NOW, 7 linhas novas, notas de medição); contrato de lógica (8 → 13 fluxos, entrypoints reais, `public_api_paths` com `/capabilities`, 20 overrides novos); fila e ficha do NOW; 7 ADRs; contratos E2E, de evidência de UI e de coleção; mapas de API e de UI; roteadores |
| Marcados históricos | 20 | 9 documentos de março, `LAYOUT_TEST_MAP`, `PROPOSED_QUEUE_REORDER`, `EASYPANEL_RUNBOOK`, `PROJECT_LOGIC_FULL_REPORT`, `READINESS_RUNBOOK`, os 2 de `server/doc/`, o ponto de retomada de 2026-09-21 e as 3 fichas fechadas; todos com banner `HISTORICAL_EVIDENCE · NO_MUTATION_AUTHORITY`, e override no contrato para os 17 que não são fichas |
| Movidos para arquivo | 2 | `HERMES_SQLITE_EASYPANEL_BRIDGE_AUDIT` → `docs/archive/2026-06/` (zero referências); corpo de `CONTEXTO_PRODUTO_ATUAL.md` (816 → 44 linhas) → `docs/archive/2026-09/` |
| Retirado das listas | 1 | `CLAUDE.md`, que nunca existiu no repositório |
| Código | 2 | correção de privacidade do marketplace (teste novo, provado por mutação) e o teste do gerador ajustado ao contrato corrigido |
| Regenerados | 9 artefatos | project-logic sincronizado (`--check`); suíte do gerador 40/40 |

**Ficou fora, ainda sem ID no backlog** (registrado em `docs/verdade/PLANO_DE_CORRECAO.md` §F e
entra na priorização da D-53 do registro de decisões, §9): normalizar a coluna Status do mapa de API (26 valores → 5)
e adicionar coluna Auth; derivar `bearerAuth` no gerador da presença de `authMiddleware` (F1 —
é o achado 10 da §6); quebra de contagens por raiz no `CURRENT_SYSTEM.md` (F2/F3); expressar no
contrato o modo do gate (`quality_gate.sh full`) e testes só-live, que o schema atual não aceita.

---

## 9. Decisões do dono

O registro, com a recomendação de cada item, é
[`docs/status/DECISOES_PENDENTES_2026-09-22.md`](DECISOES_PENDENTES_2026-09-22.md): 55 decisões,
que cobrem as 50 da medição das P0 (`docs/flows/_p0/README.md` §4) e as abertas pela leitura da
produção. **Em 2026-09-22 o dono aceitou todas.** Elas foram registradas na decisão de produto, no
backlog (§2.5 e linha a linha) e na fila; o registro diz onde cada uma ficou e quais passos ainda
pedem a palavra dele na hora da execução.

As que destravavam primeiro:

1. **Pôr a contenção no ar** (item 0 do registro). A produção roda uma versão sem a política de
   capabilities, com cadastro aberto e IA ligada. A sequência: backup cifrado → merge → 058 →
   deploy com tudo off → same-SHA.
2. **Bump do `npm audit`** (D-01), confirmado direto com quem for executar.
3. **Raias paralelas e prova de UI em lote** (D-02, D-03).
4. **Escopo da beta** (D-07): com ou sem Analyze/Optimize e contador de vida.
5. **Os quatro buracos da §6** (D-19), fechados antes de qualquer abertura.

---

## 10. Como ler daqui para a frente

- **Prioridade**: só `docs/status/CURRENT_PRODUCT_DECISION.md` e o backlog.
- **Estado verificado**: este documento + `docs/verdade/FATOS.md`.
- **Decisões pendentes, com a recomendação de cada uma**: `docs/status/DECISOES_PENDENTES_2026-09-22.md`.
- **Como cada jornada funciona e o que falha**: `docs/flows/<fluxo>.md`.
- **O que cada tarefa exige de verdade**: `docs/flows/_p0/` (medição).
- **Padrão visual que o app inteiro deve seguir**: `docs/design/life-counter-prototype/README.md`
  e `docs/design/ui-kit-spec.md`.
- Documento com banner `HISTORICAL_EVIDENCE · NO_MUTATION_AUTHORITY` é fotografia: não executar,
  não priorizar por ele.
