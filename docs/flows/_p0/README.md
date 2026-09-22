# Quanto realmente falta para fechar a beta controlada: as P0 CORE medidas

- Data: 2026-09-22. Repositório `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`, branch
  `codex/free-beta-release-candidate-2026-07-17`, HEAD `d15beb05b` (2026-09-21). O HEAD está
  **29 commits à frente de `origin/master`** (`704c2c11c`, 2026-08-12), e a árvore de trabalho tem
  62 entradas modificadas por outras sessões.
- Alvo: `CONTROLLED_FREE_BETA`, com coorte pequena, Web e Android, e iOS fora
  (`docs/status/CURRENT_PRODUCT_DECISION.md:3-9`). Não é release público.
- Universo: o registry tem 58 `P0 CORE`, 3 em `PASS` (`BT-GOV-001`, `BT-DOC-001`, `BT-DOC-004`) e
  **55 abertas**. Destas, 49 foram medidas asserção por asserção, em 9 grupos. As outras 6 foram
  registradas no backlog em 2026-09-22 e aqui só foram situadas, sem medição (§2.3).
- Fonte do aceite: `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`. O arquivo da árvore tem
  sha256 `064aec38…`. O `docs/generated/TASK_REGISTRY.json` foi gerado de outro backlog
  (`7584fbd…`), portanto **o registry está defasado** (§5.2).
- Somente leitura. Não rodei teste, build, emulador nem servidor. "PROVADO" significa que existe um
  teste que afirma a asserção inteira e, quando o teste é live, que existe receipt. Não significa
  "passa hoje no HEAD".
- As referências `arquivo:linha` sobre código vêm das medições por grupo, que foram reconferidas por
  verificação adversarial. As marcadas com **(conferido)** eu reabri nesta consolidação.
- Medições por grupo (neste diretório): `auth-conta.md`, `privacidade-telemetria.md`,
  `deck-core.md`, `ux-telas.md`, `catalogo-arte.md`, `banco.md`, `contencao-escopo.md`,
  `infra-release.md`, `gates-qa-web.md`. Os scripts de apoio estão em `work/`: `grafo.py` (grafo
  efetivo), `final_md.json` (números finais) e `quadro_script.json` (o quadro que veio pronto).

## 0. De onde vêm os números

O quadro que veio pronto no enunciado soma **424 asserções** (90 provadas, 47 sem prova, 144
parciais, 143 não encontradas), **526 arquivos** e **274 testes**. Os estados das 49 tarefas batem
com as tabelas finais dos `.md`. As contagens de asserção e de trabalho **não batem em 41 das 49
tarefas**. Cada `.md` tem uma ou mais seções de verificação adversarial que registram as
recontagens (auth-conta passou por duas rodadas, catálogo por quatro passagens), e o quadro
carrega contagens anteriores a elas. Uso os números finais dos `.md`, que são os que têm
`arquivo:linha` e o registro do que caiu. O efeito líquido: **21 asserções provadas a menos**,
9 asserções a mais, **+166 arquivos (+32%)** e **+71 testes (+26%)**. A diferença, tarefa por
tarefa, sai da comparação entre `work/final_md.json` e `work/quadro_script.json`.

---

## 1. A resposta direta, em números

**Nenhuma das 49 P0 CORE medidas está atendida.** As 49 foram decompostas em **433 asserções
verificáveis**:

| Estado | Asserções | % |
| --- | ---: | ---: |
| PRONTO_E_PROVADO | **69** | 15,9% |
| PRONTO_SEM_PROVA | **67** | 15,5% |
| PARCIAL | **154** | 35,6% |
| NAO_ENCONTRADO | **143** | 33,0% |

Pelo status medido de cada tarefa:

| Status medido | Tarefas |
| --- | ---: |
| já atendida | **0** |
| quase lá | **4** (`BT-AUTH-003`, `BT-OFFER-001`, `SCOPE-P0-SOC-00`, `BT-GATE-001`) |
| metade | **12** |
| mal começada | **31** |
| não começada | **2** (`BT-AUTH-006`, `BT-CAP-001`) |

Lido pelos três eixos:

- **IMPLEMENTADO.** 136 das 433 asserções (31,4%) existem por inteiro no código, e outras 154
  existem em parte. Faltam por completo 143. Ou seja, **297 asserções (68,6%) ainda pedem código**.
- **PROVADO.** Só 69 (15,9%) estão provadas, e 29 delas vêm de um único grupo, contenção de escopo.
  **Nas outras 43 tarefas, a prova cobre 40 de 378 asserções (10,6%)**. Boa parte do que é
  "provado" se apoia em receipts de julho que ninguém re-executou no HEAD. É o caso dos testes live
  de conta, com receipts de 2026-07-21 (`auth-conta.md`, aviso no topo). **364 asserções (84,1%)
  ainda pedem prova.**
- **ABERTO.** No repositório, as 29 capabilities estão `off` (`server/config/release_capabilities.json`).
  **Pela última observação registrada, a produção não roda esta contenção.** Essa observação (2026-08-14) mostra o
  servidor em `a6ee09c8f`, com `/capabilities` respondendo 404, migration 057 e runtimes de IA e
  Battle habilitados (`docs/qa/execution/2026-08-14/BT-GOV-001.md:114-124`, **conferido**). O
  baseline all-OFF (`b2d3fc04f`) nem está em `master` (**conferido**:
  `git merge-base --is-ancestor b2d3fc04f origin/master` é falso). No repositório, o que continua
  alcançável com tudo OFF é o plano de controle de conta
  (`server/lib/release_capability_policy.dart:596-617`, **conferido**). É justamente ali que estão
  os buracos abertos: o export sai com um bearer simples (`server/routes/users/_middleware.dart:4-6`,
  **conferido**, só `authMiddleware`); o `DELETE /users/me` reverifica a senha sem teto de tentativas
  (`server/routes/users/me/index.dart:322-339`; o bucket de credenciais só cobre `/auth/*`,
  `server/lib/rate_limit_middleware.dart:348-357`, **conferido**);
  o login devolve o texto da exceção (`server/routes/auth/login.dart:60`, **conferido**) e enumera
  contas por tempo (`server/lib/auth_service.dart:282-283` lança antes do bcrypt de `:294`,
  **conferido**); e `GET /reports/:id` serve o snapshot de um deck mesmo depois de apagado
  (`release_capability_policy.dart:584-585`, **conferido**; `deck-core.md` F4).

O trabalho restante, somado das 49 medições:

- **~692 arquivos tocados** (até ~781 com os condicionais). É soma por tarefa, com repetição, e não
  conta de arquivos únicos. Só `BT-AUTH-001` responde por ~110: são 228 frases de erro em 64
  arquivos de rota.
- **~345 testes novos**, mais pelo menos 14 testes existentes a inverter ou atualizar (8 em
  `BT-DB-002`, 3 em `BT-CAT-02`, 3 em `SCOPE-P0-TRD-00`) e cerca de 20 testes que hoje **travam o
  comportamento errado** (§5.3).
- **Migração nova certa em 8 tarefas**: `BT-AUTH-006`, `BT-PRIV-001`, `BT-PRIV-002`, `BT-KPI-001`,
  `DCK-P0-01`, `DCK-P0-04`, `DCK-P0-06` e `BT-DB-002`. Todas disputam o número `059`.
- **Aplicar ao vivo a 058**, que já existe (`BT-REL-001`).
- **Migração condicional ou provável em outras 7 tarefas.**
- **Prova viva** (captura de UI ou receipt de execução real) em 40 das 49.
- **Decisão humana pendente** em 47 das 49 (48, contando a indireta de `BT-OFFER-001`). Só
  `DCK-P0-07` não tem nenhuma.

Esses números não incluem três coisas:

- **As 6 P0 CORE não medidas.** Duas estão feitas e esperam receipt ou commit. Uma está em 22/23
  manifests, mas a correção que falta zera o que já foi capturado. Três não começaram (§2.3).
- **9 tarefas fora da classe P0 CORE que o grafo põe no caminho**: 6 P1, 2 P0 AI e 1 P1
  não declarada (§3.1).
- **Três marcos sem ID no registry**, que nenhuma tarefa possui: o merge em `master`, a migration
  058 em produção e o `full` verde no SHA.

**Em uma frase:** falta a maior parte. Dois terços das asserções ainda não existem ou existem pela
metade, só uma em seis está provada, e o caminho mais longo tem **12 elos em série**. Esse caminho
começa por uma auditoria de banco que depende de uma autorização do dono (ou do aceite de um dump
antigo) e passa por 2 tarefas que nem são P0 CORE.

---

## 2. Tarefa por tarefa

### 2.1 As 49 medidas

Legenda:

- **P/S/Pa/N** = provado / sem prova / parcial / não encontrado.
- Estados declarados: `TODO`, `BLOCKED` (`BLOCKED_BY_P0`), `IPC` (`IN_PROGRESS_CONTAINED`),
  `ILPFG` (`IMPLEMENTED_LOCAL_PENDING_FULL_GATE`) e `ER` (`EVIDENCE_REQUIRED`).
- As decisões estão resumidas; o detalhe está em §4.

| ID | Grupo | Declarado → medido | P/S/Pa/N | Arquivos | Testes | Migração | Decisão humana | Prova viva |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BT-AUTH-001 | conta | TODO → mal começada | 1/2/3/0 | ~110 (+~12 app) | 7 | não | nomenclatura; código substitui ou acompanha a frase | condicional |
| BT-AUTH-002 | conta | TODO → mal começada | 0/0/3/4 | ~10 (até ~45) | 4 | não | teto de body; escopo dos limites por campo | não obrigatória |
| BT-AUTH-003 | conta | TODO → **quase lá** | 3/3/0/1 | 3 | 4 (+1) | não | número de "timing aceitável"; bucket por email | receipt (2 execuções do harness) |
| BT-AUTH-004 | conta | TODO → mal começada | 0/0/4/2 | ~10 | 8 | condicional | forma do step-up e janela de frescor | sim |
| BT-AUTH-006 | conta | TODO → **não começada** | 0/1/1/7 | ~12 | 7 | **sim** | política de convites da coorte | sim |
| BT-LEGAL-ACCEPT-001 | conta | TODO → mal começada | 1/0/1/5 | ~13 | 6 | condicional | escopo do bloqueio; histórico (jurídico); pt-BR; onde mora o texto | sim |
| BT-PRIV-001 | privacidade | TODO → mal começada | 1/3/6/3 | ~20 | 11 | **sim** | onde fica o artefato, prazo, canal; IDs devidos; dados de terceiros | sim |
| BT-PRIV-002 | privacidade | TODO → mal começada | 0/2/5/4 | ~22 | 12 | **sim** | consumidores e prazos; Sentry e backups | sim |
| BT-KPI-001 | privacidade | TODO → mal começada | 0/1/6/6 | ~18 | 9 | **sim** | ativação, loops, coortes, retenção; texto jurídico | sim |
| BT-OBS-001 | privacidade | TODO → mal começada | 0/1/6/6 | ~19 | 13 | provável | SLOs, receiver, canal, thresholds | sim |
| DCK-P0-00 | deck | TODO → metade | 3/2/2/1 | 9 (≈15) | 6 | não | editor sem remoção: PATCH, abrir replace-all ou esconder | sim |
| DCK-P0-01 | deck | TODO → mal começada | 0/1/4/3 | 25 | 16 | **sim** | If-Match já ou com transição; undo pré-migration | sim |
| DCK-P0-02 | deck | TODO → metade | 1/1/3/1 | 9 (≈17) | 8 | só se uso único | TTL e uso único do artifact | sim (PG isolado) |
| DCK-P0-03 | deck | BLOCKED → mal começada | 0/1/2/3 | 10 | 8 | não | capability do preview de import | sim |
| DCK-P0-04 | deck | BLOCKED → mal começada | 0/0/3/3 | 13 | 8 | **sim** | retenção do prompt (é da P1 `BT-PRIV-003`) | sim |
| DCK-P0-06 | deck | TODO → mal começada | 0/1/1/5 | 38 | 11 | **sim** | janela de purge; lixeira em limites e export | sim |
| DCK-P0-07 | deck | TODO → mal começada | 0/0/3/3 | 6 | 6 | não | nenhuma | não |
| DCK-P1-04 | deck | BLOCKED → metade | 0/2/3/2 | 13 (16) | 8 | provável | legalidade ausente bloqueante (rebaixa decks) | sim (receipt) |
| BT-UX-IMG-001 | UX | TODO → metade | 3/2/5/0 | 18 | 9 | não | crop/blur da arte (produto e jurídico); selo decorativo | sim |
| BT-UX-FIX-001 | UX | TODO → metade | 0/0/6/3 | 16 (11 num worktree) | 7 | não | "trocas" = Optimize ou Trades; arte real na fixture | sim |
| BT-UX-SWAP-001 | UX | TODO → mal começada | 1/1/4/3 | 13 | 10 | não | ordem frente ao kit; o que é "impacto do par" | sim |
| BT-UX-A11Y-001 | UX | BLOCKED → mal começada | 1/0/6/3 | ≥15 | ≥11 | não | aparelho físico do dono; contraste e 48 dp do kit | sim (humana) |
| BT-UX-PROOF-001 | UX | BLOCKED → mal começada | 1/0/3/3 | 10 | 3 | não | quem assina o visual; físico ou emulador | sim |
| BT-CAT-01 | catálogo | TODO → mal começada | 0/1/4/2 | 8 (≈12) | 6 | de dados, provável | budget; contrato de apply; grão de impressão | não |
| BT-CAT-02 | catálogo | BLOCKED → mal começada | 0/1/0/4 | 7 | 6 (+3 inversões) | não | resposta para carta ausente | não (a UX muda) |
| BT-CAT-03 | catálogo | BLOCKED → mal começada | 0/0/2/4 | 8 | 7 | não | leitura "cara"; idade que torna stale | não |
| BT-ART-01 | catálogo | TODO → metade | 4/0/5/0 | 10 (11) | 4 (5) | não | UA; contrato ou código; políticas Scryfall/Wizards | recomendada |
| BT-DB-001 | banco | TODO → mal começada | 5/0/4/2 | ~10 | ~8 | não | ler o PG de produção ou usar o dump; leitura fresh × real | sim |
| BT-DB-002 | banco | BLOCKED → mal começada | 0/1/3/4 | ~18 | ~10 (+8) | **sim** | conteúdo da 059; ordem das migrations; 058 live | sim |
| BT-DB-003 | banco | BLOCKED → mal começada | 0/0/2/4 | ~9 | ~6 | não | lista fechada do live-drift | sim |
| BT-DB-004 | banco | IPC → mal começada | 0/3/3/4 | ~29 (+2 docs) | ~11 | opcional | destino dos CLIs, resets e 47 pacotes SQL; DDL de `sync_state` | não |
| BT-SCP-001 | contenção | IPC → metade | 10/3/4/0 | 7 (+2) | 3 | não | same-SHA; clean-SHA com `--no-verify`; C17 | sim |
| BT-OFFER-001 | contenção | ILPFG → **quase lá** | 6/1/0/1 | 3 | 0 | não | nenhuma própria (depende do bump e de C17) | sim (gate) |
| BT-AI-029 | contenção | TODO → mal começada | 1/2/1/2 | 19 | 9 | não | adapter, 410 ou remover; janela de telemetria | sim* |
| SCOPE-P0-SOC-00 | contenção | ER → **quase lá** | 7/1/2/1 | 7 | 2 | não | `/reports/:id` público; flags em bloco | sim |
| SCOPE-P0-TRD-00 | contenção | ER → metade | 3/1/2/1 | 12 | 3 (+3) | não | 422 ou zerar; linhas existentes; troca/venda privada | sim |
| BT-SCN-00 | contenção | TODO → metade | 2/1/2/1 | 5 | 2 | não | probe não canônico; remover plugins | sim (APK) |
| BT-CAP-001 | infra | TODO → **não começada** | 0/0/1/7 | 8 | 5 | não | autorizar leitura do host e do PG; headroom (custo) | sim |
| BT-CAP-002 | infra | BLOCKED → mal começada | 0/2/3/4 | 13 | 8 | não | limits (custo); treino em produção | sim |
| BT-DR-001 | infra | TODO → metade | 0/5/4/4 | 10 | 7 | não | provedor e região (LGPD); chave age; RPO/RTO | sim |
| BT-REL-001 | infra | BLOCKED → mal começada | 0/1/4/4 | 13 | 9 | **aplicar a 058 live** | `/app` com tudo OFF; ordem; host Android | sim |
| BT-REL-002 | infra | BLOCKED → mal começada | 2/3/6/3 | 14 | 9 | não | o que fazer com digest divergente | sim |
| BT-REL-003 | infra | BLOCKED → mal começada | 0/1/2/3 | 9 | 5 | não | P0 aplicáveis; política de congelamento | sim |
| BT-GATE-001 | gates | ER → **quase lá** | 3/5/2/1 | 6 | 8 | não | skips como SKIP inventariado | sim |
| BT-GATE-002 | gates | ER → metade | 6/6/1/2 | 7 (+4) | 10 | não | escopo do receipt; leitura do PG | sim |
| BT-GATE-003 | gates | TODO → mal começada | 0/2/1/6 | 8 | 6 | não | deduplicação; receipt de PG por release | sim |
| BT-QA-001 | gates | BLOCKED → mal começada | 1/0/5/4 | 7 (+capturas) | 2 | não | revisor humano; re-escopo das matrizes | sim |
| BT-DEC-001 | gates | BLOCKED → mal começada | 0/1/5/2 | 3 (+4 a 8) | 1 (+2) | não | é a entrega: GO/NO-GO, riscos, coorte, rollback | não |
| BT-WEB-001 | gates | BLOCKED → metade | 3/2/6/2 | 10 | 6 | não | copy, metadata e Termos; merge e deploy | sim |

\* `BT-AI-029` só exige prova viva se a janela de telemetria em produção for mantida.
`SCOPE-P0-SOC-00` e `SCOPE-P0-TRD-00` estão `EVIDENCE_REQUIRED` apenas na árvore de trabalho: em HEAD
são `TODO` (`contencao-escopo.md`, cabeçalho).

### 2.2 Por grupo

| Grupo | Tarefas | Asserções | P | S | Pa | N | Implementado (P+S) | Provado | Arquivos | Testes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| auth-conta | 6 | 42 | 5 | 6 | 12 | 19 | 26% | 12% | ~158 | 36 |
| privacidade-telemetria | 4 | 50 | 1 | 7 | 23 | 19 | 16% | 2% | ~79 | 45 |
| deck-core | 8 | 54 | 4 | 8 | 21 | 21 | 22% | 7% | ~123 | 71 |
| ux-telas | 5 | 45 | 6 | 3 | 24 | 12 | 20% | 13% | ~72 | 40 |
| catalogo-arte | 4 | 27 | 4 | 2 | 11 | 10 | 22% | 15% | ~33 | 23 |
| banco | 4 | 35 | 5 | 4 | 12 | 14 | 26% | 14% | ~66 | 35 |
| contencao-escopo | 6 | 55 | 29 | 9 | 11 | 6 | 69% | 53% | ~53 | 19 |
| infra-release | 6 | 59 | 2 | 12 | 20 | 25 | 24% | 3% | ~67 | 43 |
| gates-qa-web | 6 | 66 | 13 | 16 | 20 | 17 | 44% | 20% | ~41 | 33 |
| **Total** | **49** | **433** | **69** | **67** | **154** | **143** | **31%** | **16%** | **~692** | **~345** |

A contenção (manifesto, middleware, guards) é a única área majoritariamente pronta e provada. Três
grupos têm o eixo PROVADO perto de zero:

- **privacidade** (1 asserção provada, por um receipt de julho);
- **infra/release** (2);
- **deck** (4).

### 2.3 As 6 registradas em 2026-09-22 e não medidas (situadas, sem decomposição)

| ID | Declarado | O que existe (evidência) | O que falta | Posição no caminho |
| --- | --- | --- | --- | --- |
| BT-CI-001 | ILPFG | Implementação em `d83e9b1e1` e `07014b431`. A mutação que diverge bootstrap e validação agora falha nas duas direções (`docs/qa/execution/2026-09-21/btscp001-gate-amplo.md:109-115`, **conferido**). O commit `b4473a98a` "close BT-CI-001" | Receipt formal no SHA (backlog `:623`) | Folha. Fecha junto com o `full` verde |
| BT-DOC-006 | ILPFG | Feito **só na árvore**: `docs/MAPA_OPERACIONAL_DO_PROJETO.md:62` ("Os três portões") e `flows[ops_scheduler]` em `docs/project_logic_contracts.json` têm 0 ocorrências em HEAD (**conferido**) | Commit isolado do resto da árvore compartilhada (62 entradas), `--check` e receipt | Folha. Fecha junto com o `full` verde |
| BT-UIEV-001 | IPC | 22 de 23 manifests no digest `8bba809c` (430 capturas). Falta `play-vs-ai-web-real` (digest `865e6041`), e `latest.json` não foi tocado (`docs/qa/execution/2026-09-21/PONTO_DE_RETOMADA.md:20-36`) | Corrigir a corrida de handoff do E2E (`:40-46`). Os dois scripts da corrida estão no escopo do digest (`scripts/manaloom_ui_source_digest.sh:77-78`, **conferido**), então a correção **zera os 22 manifests já capturados**. Depois: recapturar 23, reler todas as capturas e reescrever `latest.json`. Decidir C17 (`:87`) | **Cabeça** da trilha de evidência. Pré-requisito do gate amplo, de `BT-SCP-001` (backlog `:225`), do `BT-UX-KIT-001` (`:348`) e, pelo digest, de toda tarefa que mexe em `app/lib` |
| BT-WEB-003 | TODO | Nada: `web-public/package.json:22` ainda fixa `"next": "15.5.21"` e `:19` fixa `sharp` 0.35.3 (**conferido**) | Bump de 2 a 3 arquivos (`package.json`, `package-lock.json`, `eslint-config-next`). A autorização é contraditória: o backlog não commitado diz "autorizado" (`:632`), e o `PONTO_DE_RETOMADA.md:69-74`, commitado, diz que a autorização repassada por terceiro não foi aceita | **Cabeça** junto com `BT-UIEV-001`. O `npm audit` é o primeiro estágio do `full` que morre. Não mexe no digest de UI |
| BT-GATE-007 | TODO | Nada: `scripts/quality_gate.sh` tem 0 ocorrências de `integration_test`, e há 147 `*_test.dart` em `app/integration_test/` (**conferido**) | Estágio que rode a camada de integração com runtime isolado e derrube o gate. Vai revelar vermelhos em número desconhecido | Raiz independente. Pré-requisito não declarado de `BT-REL-003` (`infra-release.md`, REL-003) |
| BT-UX-KIT-001 | TODO | Zero código: `app/lib/core/theme/` só tem `app_theme.dart`, e não existe `app_tile.dart` nem `bt_tokens.dart` (**conferido**). O packet `docs/design/execution/BT-UX-KIT-001-proposto.md` (222 linhas) está em `docs/design/`, que não é rastreado | ~12 fontes novas ou editadas (5 primitivas, 5 peças, `bt_tokens.dart`, `app_theme.dart`), testes de widget, guarda de regressão e golden. As 4 revogações mudam telas existentes. Decisões A7, C2/C3, D1 e E1 da spec (packet `:45-46`). Prova em 390/834/1440/1920 | Depende de `BT-UIEV-001`. Entra no caminho principal só em `BT-UX-SWAP-001` e tem **folga de 3 elos** no grafo (§3) |

---

## 3. O caminho crítico real

### 3.1 O grafo declarado mente de três jeitos

1. **Está defasado.** No registry, `BT-UIEV-001` depende de `BT-SCP-001`, e `BT-SCP-001` só de
   `BT-GOV-001`. O backlog da árvore já inverteu isso: `BT-SCP-001` depende de `BT-GOV-001`,
   `BT-UIEV-001` e `BT-WEB-003` (`:225`), e `BT-UIEV-001` não depende de ninguém (`:624`). A correção
   não está commitada.
2. **Deixa 32 das 55 P0 CORE fora dos ancestrais de `BT-DEC-001`.** O GO/NO-GO tem 30 ancestrais
   abertos (33 com os `PASS`). Pelo grafo, a decisão sai sem auth, sem privacidade, sem banco, sem
   catálogo e sem a landing (`gates-qa-web.md`, achado 6; recalculado em `work/grafo.py`).
3. **Puxa trabalho de fora da classe P0 CORE.** O fecho transitivo das 55 inclui:
   - 6 P1: `BT-UX-DECK-001..004`, `BT-UX-SWAP-002` e `-003`, via `BT-UX-A11Y-001` e `BT-UX-PROOF-001`;
   - 2 P0 AI: `DCK-P1-06`, via `BT-UX-DECK-003`, e `BT-GATE-005`, via `BT-REL-003`;
   - 1 P1 não declarada: `BT-PRIV-003`, pré-requisito real de `DCK-P0-04` (`deck-core.md`, achado 16) e insumo de
     `BT-PRIV-001/002`. O registry põe `BT-PRIV-003` **depois** das duas, e o medidor mostrou que a
     ordem é a inversa (`privacidade-telemetria.md`, PRIV-001).

### 3.2 O grafo efetivo (o que os medidores descobriram)

Arestas **retiradas**, porque os medidores mostraram que não bloqueiam:

- `AUTH-003 → AUTH-004`: já satisfeita (`auth_service.dart:553-566` provado);
- `AUTH-004 → PRIV-002`: a exclusão já exige senha;
- `KPI-001 → OBS-001`: SLO não depende de métrica de produto;
- `AUTH-001/002 → AUTH-006`: conveniência de contrato. Fica como retrabalho, não como bloqueio.

Arestas **acrescentadas** (não declaradas):

| Aresta | Por quê |
| --- | --- |
| `BT-WEB-003`, `BT-UIEV-001` → **full verde** → `BT-SCP-001`, `BT-OFFER-001`, `BT-CI-001`, `BT-DOC-006`, receipt de `BT-GATE-001` | O `full` morre no `npm audit` e depois no `ui-audit` (`contencao-escopo.md`, achado 1) |
| full verde e `BT-SCP-001` → **merge em `master`** → `BT-CAP-002` (treino), `BT-REL-001/003`, `BT-QA-001`, `BT-WEB-001` | Todo deploy exige SHA == `origin/master` (`scripts/manaloom_release_identity.sh:46-54`), e o pre-push roda o `full` (`.githooks/pre-push:13`, **conferido**) |
| `BT-DB-004` → `BT-DB-002` | Com CLIs ainda executando DDL, nenhum perfil fecha (`banco.md`, DB-002) |
| `BT-DB-002` → `DCK-P0-01`, `DCK-P0-04`, `DCK-P0-06`, `DCK-P1-04`, `BT-AUTH-006`, `BT-PRIV-001/002`, `BT-KPI-001` | Toda migration nova tem de passar pela disciplina de perfis, preflight e postcheck, e todas disputam o número `059` (`banco.md`, achado 8; `deck-core.md`, achado 12) |
| `BT-DR-001` e `BT-DB-003` → **058 em produção** → `BT-REL-001` | Pela última observação, a produção está em 057, e a 058 tem rollback `manualOnly` (`server/bin/migrate.dart:4100`), ou seja, só se desfaz por restore (`infra-release.md`, REL-001 #6) |
| `BT-UX-KIT-001` → `BT-UX-SWAP-001` | O kit redesenha a mesma superfície. Fazer SWAP antes é fazer duas vezes (`ux-telas.md`, SWAP-001) |
| `BT-UIEV-001` → `BT-UX-IMG-001`, `BT-UX-FIX-001`, `BT-UX-PROOF-001` | O digest de UI está congelado |
| `BT-LEGAL-ACCEPT-001` → `BT-KPI-001` | Publicar a política de telemetria muda a versão de Privacidade, e o reaceite não existe |
| `BT-CAP-001` → `BT-OBS-001` | Thresholds de PG e host precisam de capacidade medida |
| `BT-DR-001` → `BT-PRIV-002` | Backups são consumidor da exclusão |
| `BT-GATE-007` → `BT-REL-003` | Muda o que o `full` executa |
| `BT-AUTH-006` → `BT-DEC-001` | Não existe mecanismo de admissão da coorte (`gates-qa-web.md`, DEC-001 #5) |
| `BT-PRIV-003` (P1) → `DCK-P0-04`, `BT-PRIV-001/002` | A classificação por coluna é insumo das três |

**Ciclo escondido.** `BT-REL-001` depende de `BT-OBS-001` (declarado). Mas o alerta de release de
`BT-OBS-001` precisa da identidade por superfície de `BT-REL-002` (`privacidade-telemetria.md`,
OBS-001), e `BT-REL-002` depende de `BT-REL-001`. Do jeito que está, não fecha. É preciso partir
`BT-OBS-001` e deixar o alerta de release para depois de `BT-REL-002`.

### 3.3 A corrente mais longa

Ligando todas as P0 CORE a `BT-DEC-001` (o GO/NO-GO exige os P0 aplicáveis), a corrente mais longa
do grafo efetivo tem **12 elos**. O grafo declarado dá 10.

```
BT-DB-001 → BT-DB-004 → BT-DB-002 → DCK-P0-01 → DCK-P1-04 → BT-UX-DECK-001 (P1)
  → BT-UX-DECK-003 (P1) → BT-UX-A11Y-001 → BT-UX-PROOF-001 → BT-REL-003 → BT-QA-001 → BT-DEC-001
```

Há duas variantes empatadas, também com 12 elos. O `work/grafo.py` imprime qualquer uma das três,
conforme a ordem de iteração; a saída guardada está em `work/grafo_saida.txt`.

- `… DCK-P1-04 → DCK-P1-06 (P0 AI) → BT-UX-DECK-003 …`
- `… DCK-P0-01 → DCK-P0-02 → BT-UX-SWAP-001 → BT-UX-SWAP-002 (P1) → BT-UX-A11Y-001 …`

**17 nós têm folga zero.** Se o dono re-escopar `A11Y/PROOF/REL-003` para dependerem só de P0 CORE
(§4, B2), a corrente cai para **11 elos**:
`BT-DB-001 → BT-DB-004 → BT-DB-002 → DCK-P0-01 → DCK-P0-02 → BT-UX-SWAP-001 → BT-UX-A11Y-001 → BT-UX-PROOF-001 → BT-REL-003 → BT-QA-001 → BT-DEC-001`.

A espinha é **banco → revisão de deck → telas de deck → acessibilidade → prova visual → candidato →
homologação → decisão**.

Existe uma segunda espinha, de release, com 10 elos:
`BT-WEB-003/BT-UIEV-001 → [full verde] → BT-SCP-001 → [merge em master] → BT-CAP-002 → BT-REL-001 → BT-REL-002 → BT-REL-003 → BT-QA-001 → BT-DEC-001`.
Ela tem um ramo que passa pela migration 058 ao vivo:
`BT-DB-001 → BT-DR-001 → [058 ao vivo] → BT-REL-001`.

### 3.4 O que pode andar em paralelo

Sem nenhum pré-requisito efetivo aberto, 16 nós podem começar já:

- 14 P0 CORE: `BT-ART-01`, `BT-AUTH-001`, `BT-AUTH-002`, `BT-AUTH-003`, `BT-AUTH-004`, `BT-CAP-001`,
  `BT-CAT-01`, `BT-DB-001`, `BT-GATE-002`, `BT-GATE-007`, `BT-LEGAL-ACCEPT-001`, `BT-UIEV-001`,
  `BT-WEB-003` e `DCK-P0-07`;
- 2 não-CORE: `BT-GATE-005` (P0 AI) e `BT-PRIV-003` (P1).

Há ainda as metades que os medidores liberaram: rate limit, fail-closed e teto do cache de
`BT-CAT-03`; H4/H7 de `DCK-P1-04`; os itens #2, #4-#6, #8 e #9 de `BT-DB-004`; a parte local de
`BT-DR-001`; e o registry de `BT-AI-029`. Dividindo pelo que realmente trava:

- **Raia de servidor, banco e gates.** Não mexe na evidência de UI: `BT-DB-001`, `BT-DB-004`,
  `BT-AUTH-002`, `BT-AUTH-003`, `BT-CAT-01`, metade de `BT-CAT-03`, `BT-CAP-001`, `BT-DR-001`
  (local), `BT-GATE-002`, `BT-GATE-007`, `BT-WEB-003` e `BT-AUTH-001`, se o código vier ao lado da
  frase.
- **Raia de app.** Move o digest de UI: `BT-AUTH-004`, `BT-LEGAL-ACCEPT-001`, `DCK-P0-07`, `BT-ART-01`
  e `BT-UX-KIT-001`, este depois de `BT-UIEV-001`.

**Duas travas de processo anulam esse paralelismo.** As duas são decisão humana (§4, E1/E2):

1. **WIP-1.** "Nenhum outro ID pode receber implementação enquanto este slot estiver aberto"
   (`docs/execution/CURRENT_QUEUE.md:41`). Mantida a regra, o caminho real não é a corrente de 12:
   é a **soma das 55, mais as 9 não-CORE, em série**.
2. **Multiplicador do digest de UI.** O pre-push roda `local_ci full` (`.githooks/pre-push:13`), o
   `full` chama `melos run quality` (`scripts/manaloom_local_ci.sh:186-189`), e o `quality` inclui
   `ui-audit` (`melos.yaml:96-98`). O `ui-audit` recusa captura com digest velho
   (`app/tool/ui_runtime_evidence.dart:598-599`). E o digest cobre 33 caminhos do app, entre eles
   `app/lib` e `app/web`, mais 15 scripts (`scripts/manaloom_ui_source_digest.sh:26-81`). Tudo isso
   **conferido**. **27 das 55 tarefas (mais 2 condicionais) mexem nesse escopo.** Cada uma deixa o
   pre-push vermelho até alguém recapturar os 23 manifests (439 capturas) e reler todas. É por isso
   que `git log -i --grep=no-verify` devolve 16 commits (**conferido**), dos quais pelo menos 13
   declaram o próprio bypass (`gates-qa-web.md`, achado 2). Sem política de lote, o custo de prova de
   UI se paga uma vez por tarefa.

### 3.5 Qual tarefa destrava mais

Contando os descendentes no grafo efetivo, sem o sumidouro `BT-DEC-001`:

| Tarefa | Descendentes |
| --- | ---: |
| **`BT-UIEV-001`** | **29** |
| `BT-DB-001` | 27 |
| `BT-DB-004` | 25 |
| `BT-DB-002` | 24 |
| `BT-WEB-003` | 19 |
| `DCK-P0-01` | 15 |
| `BT-SCP-001` | 12 |

**`BT-UIEV-001` é a que destrava mais.** Junto com `BT-WEB-003`, abre o `full`, e o `full` abre o
fechamento de `BT-SCP-001`, que é o NOW e hoje segura o slot de todo o resto. Abre também os
receipts de `OFFER-001`, `CI-001`, `DOC-006` e `GATE-001`, o pre-push e o merge, o kit e toda
tarefa de app.

**`BT-DB-001` é a cabeça da corrente mais longa**, com folga zero. Das duas, é a que precisa de uma
autorização do dono (ou do aceite do dump antigo) para começar.

---

## 4. Decisões humanas: o que não se resolve programando

Contei **50 decisões** distintas: 10 autorizações, 25 de produto e escopo, 5 jurídicas, 4 de custo
e 6 de processo. Enquanto não forem tomadas, a engenharia só consegue fazer a metade mecânica.

**A. Autorizações de ação ao vivo ou de acesso**

| # | Autorização | Tarefas afetadas |
| --- | --- | --- |
| A1 | Confirmar **diretamente** o bump do `npm audit` (`next` 15.5.25, `sharp` 0.35.4). Hoje há conflito entre backlog `:632` e `PONTO_DE_RETOMADA.md:69-74` | `BT-WEB-003`, e por ele o gate amplo, `SCP-001`, `OFFER-001`, `WEB-001` e o pre-push |
| A2 | Leitura read-only do PostgreSQL de produção, com o fingerprint SSH aprovado; ou aceitar o dump local de 2026-08-03 (em 056, com PII, restaurável só com schema) | `DB-001`, `GATE-002`, `CAP-001`, o censo do grão Oracle (`CAT-01/02`), a contagem de decks afetados (`DCK-P1-04`) e a de `for_sale` (`TRD-00`) |
| A3 | Leitura read-only via SSH do host | `CAP-001` |
| A4 | **Merge dos 29 commits em `master`**. Sem ID no registry; o pre-push roda o `full` ou exige bypass autorizado | `CAP-002`, `REL-001/002/003`, `QA-001`, `WEB-001` |
| A5 | **Aplicar a 058 em produção**. Sem ID no registry; último ledger conhecido é 057; o deploy e o `/health/ready` de HEAD exigem 058 (`banco.md`, achado 10) | `REL-001`, `DB-002` |
| A6 | Deploy e treino de rollback em produção (não há staging) | `CAP-002`, `REL-001` |
| A7 | Dump de produção e envio off-site | `DR-001` |
| A8 | Usar o aparelho físico do dono (TalkBack, Android físico) | `A11Y-001`, `QA-001`, `PROOF-001` |
| A9 | Janela de telemetria em produção, ou dispensa formal | `AI-029` |
| A10 | DML ao vivo para limpar `for_sale=true`, se a escolha for limpar | `TRD-00` |

**B. Escopo e produto**

| # | Decisão | Tarefas afetadas |
| --- | --- | --- |
| B1 | **A beta abre com Analyze/Optimize e Life Counter?** A matriz marca os dois como `OFF_UNTIL_P0_RECEIPT` (`CURRENT_PRODUCT_DECISION.md:59,61`), e o backlog §2.2 os põe na beta core (`:48-60`). Se sim, 24 P0 AI e 4 P0 LIFE (não medidas) entram no caminho. Se não, `BT-UX-SWAP-001` vira superfície inalcançável e precisa sair do P0 CORE | escopo da beta |
| B2 | Re-escopar as dependências de `A11Y-001`, `PROOF-001` e `REL-003` que apontam para 6 P1 e 2 P0 AI, ou aceitar que fechar P0 CORE exige fechá-las | `A11Y-001`, `PROOF-001`, `REL-003` |
| B3 | Com `deck_replace_all` OFF, o editor não remove carta, não edita descrição e estratégia, não alterna público e não troca edição. Opções: PATCH/remoção incremental, abrir `deck_replace_all` ou esconder as ações | `DCK-P0-00` |
| B4 | Admissão da coorte: quem emite convites, quantos, por qual canal, se há lista de espera, e o destino dos convites quando a beta abrir | `AUTH-006`, `DEC-001` |
| B5 | Resposta para carta ausente do catálogo (404, 409 ou fila); fonte e volume do grão de impressão; destino das linhas-alias Oracle | `CAT-02`, `CAT-01` |
| B6 | Tornar bloqueante a legalidade ausente. Pode rebaixar decks `validated` e esvaziar pools | `DCK-P1-04` |
| B7 | Step-up: senha por requisição ou token com tabela; janela de frescor | `AUTH-004` |
| B8 | Reaceite: o que o bloqueio impede; se a beta é só pt-BR; onde mora o texto legal | `LEGAL-ACCEPT-001` |
| B9 | Export: onde fica o artefato, por quanto tempo e por qual canal; quais IDs e hashes são devidos; dados de terceiros | `PRIV-001` |
| B10 | Exclusão: consumidores e prazos; se Sentry e backups entram; IDs de deck no outbox | `PRIV-002` |
| B11 | Ativação, loops, coortes, guardrails e retenção | `KPI-001` |
| B12 | SLOs, receiver e on-call, canal de alerta, thresholds | `OBS-001` |
| B13 | Lixeira: janela de purge; se conta em limites e export; se o restore republica relatórios | `DCK-P0-06` |
| B14 | If-Match obrigatório já ou com transição (`DCK-P0-01`); TTL e uso único do artifact (`DCK-P0-02`); capability do preview de import (`DCK-P0-03`); retenção do prompt bruto, que pertence à P1 `BT-PRIV-003` (`DCK-P0-04`) | `DCK-P0-01..04` |
| B15 | Ordem entre `BT-UX-KIT-001` e `BT-UX-SWAP-001`; o que "impacto do par" mede; se "trocas" são do Optimize ou Trades; se a fixture pode usar arte real | `SWAP-001`, `FIX-001` |
| B16 | Decisões visuais A7, C2/C3, D1 e E1 da spec do kit; contraste da §11; 48 dp para as peças | `UX-KIT-001`, `A11Y-001` |
| B17 | Quem assina `PASS_VISUAL_REVIEWED`; Android físico (onda 07) ou emulador; re-escopo das matrizes de TalkBack e teclado, que exigem Generate, social e Battle, todos OFF (`gates-qa-web.md`, achado 13) | `PROOF-001`, `QA-001` |
| B18 | Flags sociais abrem em bloco ou uma a uma. Os endpoints compostos vazam o dado de outras flags (`contencao-escopo.md`, achado 13). Troca/venda do fichário como metadado privado ou superfície de trades; 422 ou zerar; C17 | `SOC-00`, `TRD-00`, `UIEV-001` |
| B19 | "Fora do artefato" exige remover os plugins de câmera no Android e no Web (`app/web/nginx.conf:41` concede `camera=(self)`); aceitar probe de APK não canônico | `SCN-00` |
| B20 | Rotas de IA legadas: adapter, 410 ou remover; owner e substituto | `AI-029` |
| B21 | `/app` com a matriz toda OFF é implantável? Hoje o loader exige tudo OFF e o gate do `/app` exige algo ON (`infra-release.md`, achado 4). Também: ordem das superfícies e host Android na beta (`REL-001`); digest divergente no app (`REL-002`); P0 aplicáveis e congelamento (`REL-003`) | `REL-001/002/003` |
| B22 | Códigos de erro: nomenclatura, e se substituem ou acompanham a frase (`AUTH-001`); teto de body (`AUTH-002`); número de "timing aceitável" e bucket por email (`AUTH-003`); **dono do oráculo de enumeração do login, que nenhuma tarefa cobre** | `AUTH-001/002/003` |
| B23 | Banco: leitura "só fresh" ou "real × fresh"; conteúdo da 059 e ordem das migrations; lista do live-drift; destino de `setup_database.dart`, `--full`, `database_indexes.sql` e dos 47 pacotes SQL; DDL de `sync_state` | `DB-001..004` |
| B24 | Skips como SKIP inventariado (`GATE-001`); escopo do receipt forte (`GATE-002`); deduplicação e receipt de PG por release (`GATE-003`) | `GATE-001/002/003` |
| B25 | O próprio GO/NO-GO, com os riscos aceitos e os critérios de rollback | `DEC-001` |

**C. Jurídico**

1. Crop, blur ou cover da arte (a auditoria visual propõe; o contrato de arte proíbe); re-verificar as
   políticas Scryfall/Wizards por causa da marca; o UA `ManaLoom/1.0`. Afeta `ART-01` e `UX-IMG-001`.
2. Histórico de aceites legais. Se for necessário, vira migração (`LEGAL-ACCEPT-001`).
3. Texto da política de telemetria, que muda a versão de Privacidade (`KPI-001`).
4. Termos e metadata da landing ("IA explicável", "relatórios compartilháveis") (`WEB-001`).
5. PII fora do país ou com terceiro, pela LGPD (`DR-001`).

**D. Custo**

1. Headroom e thresholds, com possível upgrade do VPS (`CAP-001`); limits e reservations por serviço
   (`CAP-002`).
2. Provedor, bucket e região do backup; metas de RPO e RTO (`DR-001`).
3. Budget por execução do refresh de catálogo (`CAT-01`).
4. Canal de alerta e, se a série não for em PG, um TSDB (`OBS-001`).

**E. Processo e governança**

1. Manter WIP-1 (tudo em série) ou abrir raias paralelas com exceção de contenção.
2. Política de prova de UI: recapturar por tarefa, em lote, ou só no `PROOF-001`. São 27 (+2)
   tarefas que movem o digest.
3. Same-SHA de `SCP-001`: aceitar a prova de mecanismo ou exigir merge e observação; aceitar
   clean-SHA sobre os commits feitos com `--no-verify` (16 citam o bypass; pelo menos 13 o declaram).
4. Contrato de autorização de apply para escrita autônoma de catálogo. O daemon neutraliza o apply
   (`catalogo-arte.md`, achado 7).
5. Absorver as correções de UI de SOC, TRD e SCN no slot de `SCP-001`, antes da recaptura.
6. Uma P0 CORE (`DCK-P0-04`) depende de uma P1 (`BT-PRIV-003`): repriorizar, ou decidir a retenção
   fora dela.

---

## 5. Já atendidas, estados errados e testes que travam o errado

### 5.1 Atendidas de fato, só falta receipt ou commit

| Tarefa | Situação |
| --- | --- |
| **`BT-CI-001`** | Implementada. A prova de mutação existe dentro do receipt de `SCP-001` (`btscp001-gate-amplo.md:109-115`). Falta o receipt próprio |
| **`BT-DOC-006`** | Feita na árvore. Falta commit isolado, `--check` e receipt |
| **`BT-OFFER-001`** | Sem trabalho próprio: 6 de 8 asserções provadas e 0 commits nas superfícies de oferta desde `fd0397a5a`. Falta o receipt no SHA corrente, que depende do `full` (`BT-WEB-003`, `BT-UIEV-001`) |

Quase só receipt, mas ainda com trabalho real:

- **`SCOPE-P0-SOC-00`**: o aceite literal é atendido com as 9 flags OFF. Faltam o teste parametrizado
  das 40 combinações, o teste de push/polling e o CTA do fichário.
- **`BT-GATE-001`**: faltam os testes de wrapper.
- **`BT-AUTH-003`**: falta o timing, que exige tirar a entrega de email do caminho da requisição.

### 5.2 Estado declarado errado

| Tarefa | Declarado | O que o código mostra |
| --- | --- | --- |
| `BT-ART-01` | `TODO` | 4 de 9 asserções provadas por commits anteriores (`776b9e25d`, `e6737c53b`, `f6f791098`) |
| `BT-UX-IMG-001` | `TODO` | O widget de carta faz 63:88, `contain`, exact-first e rótulos, com teste (`card_artwork.dart:66,74-93`; `card_artwork_test.dart:114-125`) |
| `BT-UX-FIX-001` | `TODO` | 11 arquivos já escritos no worktree `~/.codex/worktrees/manaloom-bt-ux-fix-001`, não commitado. O bloqueio registrado na ficha (cold-repro) caiu em `354983a1e`/`d83e9b1e1` |
| `DCK-P0-00` | `TODO` | Metade entregue por `b2d3fc04f`: o portão `deck_replace_all` está provado em `release_capability_policy_test.dart:195-197` |
| `BT-AI-029` | `TODO` | A metade "OFF antes do PG" já foi entregue por `b2d3fc04f`/`406d7dd53` |
| `BT-SCN-00` | `TODO` | Capability, CTA, rota e manifesto Android já existem (`app/android/app/src/release/AndroidManifest.xml:3-15`) |
| `SCOPE-P0-TRD-00` | `EVIDENCE_REQUIRED` (só na árvore; `TODO` em HEAD) | O rótulo sugere código pronto, e falta código. `POST`/`PUT /binder` gravam `for_sale`/`for_trade`/`price` sem checar capability (`server/routes/binder/index.dart:335-364`; `[id]/index.dart:572-585`), e o app mostra troca e venda (`binder_item_editor.dart:1093-1160`) |
| `SCOPE-P0-SOC-00` | `EVIDENCE_REQUIRED` | O rótulo existe só na árvore; em HEAD é `TODO` |
| `BT-GATE-002` | `EVIDENCE_REQUIRED` | Falta implementação, não só receipt: o receipt do E2E não tem SHA nem digest (`manaloom_e2e_suite.sh:516-532`), e o `local_ci` apaga o próprio `RUN_DIR` (`manaloom_local_ci.sh:68-75`) |
| `BT-DB-004` | `IN_PROGRESS_CONTAINED` | 4 de 5 cláusulas abertas: 11 CLIs, `setup_database.dart` e 47 pacotes SQL ainda fazem DDL fora de migration, e `sync_state` tem 3 DDLs divergentes |
| `BT-CAT-03` e `DCK-P1-04` | `BLOCKED_BY_P0` | Metade de cada uma pode andar hoje |
| `BT-UIEV-001` e `BT-SCP-001` | (registry) | Dependência invertida no registry; o backlog só foi corrigido na árvore |
| `BT-PRIV-003` (P1) | (registry) | Posta **depois** de `PRIV-001/002`, quando é insumo das duas |
| `BT-KPI-001` | `TODO` | O rótulo esconde retrabalho: o código atual faz o que o aceite proíbe, contando eventos e dividindo por signups, e um teste consagra isso |

### 5.3 Testes que afirmam o contrário do aceite

Fechar as tarefas exige reescrever estes testes, não só somar novos:

- `server/test/privacy_account_live_test.dart:145-149`: afirma 200 para export com bearer simples
  (AUTH-004, PRIV-001).
- `server/test/decks_crud_test.dart:184-212`: afirma que um deck vazio nasce público (DCK-P0-00).
- `server/test/deck_optimization_apply_rollback_live_test.dart`: obsoleto, quebraria hoje na `:188`
  (DCK-P0-01).
- `app/test/features/decks/widgets/deck_diagnostic_panel_test.dart:1012-1176`: exige "Base pronta para testar" num deck
  nunca validado (DCK-P1-04).
- `server/test/cards_route_test.dart:56` e `:84`, e `app/test/features/cards/providers/card_provider_search_test.dart:312-320`:
  travam a escrita e o `sync=true` (CAT-02).
- `server/test/user_data_privacy_contract_test.dart:60`: afirma "sem `request_fingerprint`", mas três
  tabelas exportam o campo (PRIV-001).
- `server/test/activation_events_contract_test.dart:7-35` e `server/test/commercial_metrics_service_test.dart:8-18`: o
  primeiro diz aceitar todos os eventos, mas 4 são rejeitados; o segundo consagra a soma de eventos
  (KPI-001).
- `server/test/observability_test.dart:88`: consagra o UUID cru no Sentry. `server/test/operational_alerts_test.dart:27`
  compara uma constante com ela mesma (OBS-001).
- `app/test/core/config/release_capabilities_test.dart:34-49`: aceita digest arbitrário (REL-002).
- `app/test/features/decks/widgets/deck_details_overview_tab_test.dart:388`: trava o selo desligado no herói. `app/test/core/widgets/card_artwork_test.dart:127-135`:
  trava `cover` nas variantes com corte (UX-IMG-001).
- `scripts/manaloom_release_ops_contract_test.sh:286`: exige `camera=(self)` no Web (SCN-00).
- `app/test/features/binder/widgets/binder_item_editor_validation_test.dart:184-255,294-339`: exercita a venda como feature (TRD-00).
- `app/test/ui/ui_accessibility_matrix_test.dart:142-150`: trava o estado `pending` (QA-001).
- `server/test/api_contracts_data_map_guard_test.dart:91-128`: trava as rotas legadas como contrato
  vivo (AI-029).
- `server/test/error_contract_test.dart`: 49 chamadas aceitam 404, e por isso passam pelo gate de
  capability sem tocar a rota (AUTH-001).

---

## 6. Sobreposições: trabalho que uma tarefa resolve para outra

1. **`BT-ART-01` ≈ `BT-UX-IMG-001`.** Contain, exact-first e fallback rotulado são as mesmas
   asserções. IMG-001 só acrescenta a regra 63:88, o nome sem imagem e a ausência de layout shift.
   Fazer as duas juntas.
2. **Catálogo e scanner.** A cláusula "usuário não dispara upstream" de `BT-CAT-01` é o aceite inteiro
   de `BT-CAT-02`. O F5 de `BT-SCN-00` também é o aceite de `CAT-02`: o backlog conta a mesma frase
   três vezes.
3. **Um teste para quatro tarefas.** O teste parametrizado rota→capability, fechado por tabela,
   resolve `SCP-001` A6b, `TRD-00` E7, `AI-029` C1 e a parte de rota de `SOC-00` D4.
4. **Uma mudança para três tarefas.** O CTA de matches e a troca/venda do fichário são `SCP-001` A8,
   `SOC-00` D5c e `TRD-00` E6. É uma mudança em `binder_screen.dart` e `binder_item_editor.dart`.
5. **O teste de push/polling** é `SCP-001` A9 e `SOC-00` D5b ao mesmo tempo.
6. **Um `full` verde** fecha os receipts de `SCP-001`, `OFFER-001`, `CI-001`, `DOC-006` e `GATE-001`
   (e o smoke de `WEB-001`). Mas só se as mudanças de `app/lib` de SOC e TRD entrarem antes da
   recaptura. Senão são dois ciclos.
7. **`BT-AUTH-001` é a base do formato de erro** de `AUTH-002` (413), `AUTH-006` (negação),
   `LEGAL-ACCEPT-001` (`legal_acceptance_required`) e dos `details: e` de `KPI-001`. O lado app
   (`FriendlyErrorMapper` mostra o código cru) é o mesmo trabalho de LEGAL #4 e #5.
8. **Um mecanismo, três políticas.** O padrão "estado da conta barra a requisição"
   (`verified_email_middleware.dart`) serve ao step-up de `AUTH-004` e ao reaceite de `LEGAL`.
9. **`AUTH-004`, `PRIV-001` e `PRIV-002` mexem nas mesmas rotas `/users/me/*`.** O step-up precisa
   ser desenhado para o job de export, ou será refeito.
10. **`AUTH-006` e `LEGAL-ACCEPT-001` mexem na mesma tela e no mesmo fluxo de cadastro.** Em paralelo,
    colidem.
11. **Uma classificação por coluna** serve a `PRIV-001` (allowlist), `PRIV-002` (consumidores),
    `PRIV-003` (retenção), `KPI-001` (schema) e `SEC-AI-002` (sinks).
12. **Deck.** B5 de `DCK-P0-01` = H6 de `DCK-P1-04`. A7 de `DCK-P0-00` = `DCK-P1-01`. A5 =
    `DCK-P1-03`. A8 é fechada por `DCK-P0-04` e `DCK-P1-08`.
13. **Banco.** `DB-002` e `DB-003` usam o mesmo mecanismo de perfil. O inventário de `DB-001` serve a
    `DB-005` e ao "schema validado" de `DR-001`. O restore de `DB-003` serve a `DR-001`.
14. **Release.** A identidade de `REL-002` fecha a A13 de `SCP-001` e o alerta de release de
    `OBS-001`. A restauração de env de `CAP-002` fecha a #14 de `REL-002`.
15. **Prova de UI.** `A11Y-001`, `QA-001`, `PROOF-001` e `UIEV-001` precisam da mesma sessão física e
    das mesmas capturas. As correções de reflow do worktree de `FIX-001` adiantam `A11Y-001` e
    `UX-DECK-004`.
16. **Receipt forte.** O de `GATE-002` é exigido por `GATE-003` e fica inválido quando a `059` de
    `DB-002` entrar: o `058` está fixado em 5 lugares.
17. **`WEB-001` e `OFFER-001`** compartilham a asserção "sem Pro na landing" e o mesmo smoke de
    `WEB-003`.
18. **`AUTH-002` e `BT-SEC-001`** mexem no mesmo middleware raiz. Podem ser um PR só. O `await` que
    falta em `rate_limit_middleware.dart:263` corrige ao mesmo tempo `CAT-03` e o limiter de
    `/auth`.

---

## 7. O que NÃO foi medido, e por quê

1. **As 6 P0 CORE de 2026-09-22.** `CI-001`, `UIEV-001`, `WEB-003`, `DOC-006`, `GATE-007` e
   `UX-KIT-001` entraram no backlog depois do lote. Foram situadas com evidência conferida (§2.3),
   mas não decompostas em asserções.
2. **As 9 tarefas não-CORE que o grafo exige.** São `BT-UX-DECK-001..004`, `BT-UX-SWAP-002/003`,
   `DCK-P1-06`, `BT-GATE-005` e `BT-PRIV-003`. Estão fora da classe medida. Além delas, há vizinhas
   citadas como sobreposição e também não medidas: `BT-SEC-001`, `BT-BAT-002`, `DCK-P1-03`,
   `BT-AI-030`, `BT-DB-005`, `BT-GATE-004` e `BT-GATE-006`.
3. **As outras 78 P0 de capability.** São 24 AI, 18 BATTLE, 10 SOCIAL, 7 TRADE, 6 LEARNING,
   5 COMMERCIAL, 4 LIFE, 2 GENERATE e 2 SCANNER. Pela §5.1 do backlog (`:150-161`), cada uma bloqueia
   só a própria capability, e a beta pode avançar com elas "comprovadamente OFF". **A leitura se
   sustenta, com quatro ressalvas:**
   - "Comprovadamente OFF" é, ela mesma, trabalho P0 CORE: `SCP-001`, `SOC-00`, `TRD-00`, `SCN-00`,
     `AI-029` e `DCK-P0-00`, com portas laterais ainda abertas no fichário, em `is_public` e em rota
     nova sob prefixo core.
   - O grafo declarado já puxa 2 P0 AI para dentro do caminho das P0 CORE (§3.1).
   - A matriz põe Analyze/Optimize e Life Counter como `OFF_UNTIL_P0_RECEIPT`, e o backlog §2.2 os
     inclui na beta core. Se o dono quiser os dois na beta, **28 P0 (24 AI e 4 LIFE) entram no
     caminho sem nenhuma medição**. Se não quiser, `BT-UX-SWAP-001` não tem superfície alcançável
     (§4, B1).
   - `BT-QA-001` não fecha com Generate, social e Battle OFF enquanto as matrizes exigirem essas
     rotas.
4. **Nada foi executado.** Nenhum "provado" aqui garante que o teste passa hoje. E três estágios do
   gate (`custom-lint`, `patrol-smoke`, `dependency_audit`) **nunca rodaram neste SHA**: o número de
   arquivos que vão exigir é desconhecido.
5. **A produção não foi observada.** O eixo ABERTO em produção é o de 2026-08-14.
6. **Dados de produção.** Ficaram sem medir: quanto do catálogo está no grão Oracle, quantas contas
   têm versão legal `NULL`, quantos decks `validated` caem com legalidade bloqueante e quantas linhas
   têm `for_sale=true`. Todos exigem a autorização A2.
7. **Arquivos únicos.** Os ~692 são soma por tarefa, com repetição. Não houve deduplicação.
8. **Tempo.** Não estimei dias nem semanas; não há base de velocidade.

---

## 8. Se fosse para começar amanhã

Ordem das 5 primeiras tarefas, pela leitura do grafo:

1. **`BT-WEB-003`.** É o desbloqueio mais barato do projeto: 2 a 3 arquivos, sem teste novo e sem
   mexer no digest de UI. Tira um RCE crítico do site público. É o primeiro estágio do `full` a
   morrer, e por isso segura `SCP-001`, `OFFER-001`, `GATE-001`, o smoke de `WEB-001` e o pre-push
   (19 descendentes). Antes de mexer, é preciso a confirmação **direta** do dono, que hoje está em
   conflito (§4, A1).
2. **`BT-UIEV-001`.** É a que mais destrava (29 descendentes), e a ordem interna importa para pagar a
   recaptura uma vez só:
   1. rodar isolados os três estágios que nunca rodaram;
   2. decidir C17;
   3. aplicar juntas as mudanças de `app/lib` e `app/web` da família de contenção: A8 e A9 de `SCP`,
      E6 de `TRD`, D5c de `SOC`, a câmera do `nginx` de `SCN` e, se o dono aprovar, a linha de
      `interactive_battle_not_waiting` (`PONTO_DE_RETOMADA.md:55-63`);
   4. consertar a corrida do E2E;
   5. recapturar os 23 manifests e reescrever `latest.json`.
3. **`BT-SCP-001`.** Fecha o NOW com o gate amplo. O que falta: ~10 mutações do parser Dart, o teste
   de push, o teste de rotas fechado por tabela e as decisões same-SHA e clean-SHA. A mesma execução
   verde dá receipt a `OFFER-001`, `CI-001` e `DOC-006`, e dá a `GATE-001` o receipt de ponta a ponta
   que ela ainda precisa (os testes de wrapper continuam por fazer). Também libera o slot WIP-1 e
   deixa o pre-push verde, que é pré-condição do merge em `master` (A4).
4. **`BT-DB-001`.** É a cabeça da corrente mais longa: folga zero, 27 descendentes. Mexe só em
   servidor e scripts, sem tocar no digest. Peça a autorização A2 **no primeiro dia**, para que a
   espera corra em paralelo com os passos 1 a 3. Se o dono preferir, o dump de 2026-08-03 restaurado
   só com schema dispensa o acesso ao vivo. Fixe o mesmo major de PG da produção (17; a máquina tem
   14.18, `banco.md`, achado 4).
5. **`BT-DB-004`.** É o próximo elo da espinha e destrava `DB-002` (25 descendentes), que por sua vez
   é a porta das 8 migrations novas. É mecânico: 11 CLIs e 4 helpers passam de DDL para verificação
   que falha fechado, mais o auditor. Não mexe no digest. Os itens #2, #4-#6, #8 e #9 podem começar
   junto com `DB-001`.

**Onde isso diverge da fila do dono.** A fila da árvore põe `BT-UX-KIT-001` na posição 2, logo
depois de `UIEV-001` (`CURRENT_QUEUE.md:55`), e o packet registra essa decisão do dono. No grafo, o
kit tem **folga de 3 elos**: ele só entra na espinha em `BT-UX-SWAP-001`, que também espera
`DB-001 → DB-004 → DB-002 → DCK-P0-01 → DCK-P0-02`. Além disso, as quatro revogações dele mudam telas
existentes e forçam outra recaptura completa.

Se o dono mantiver WIP-1, a ordem acima adianta o que está em folga zero. Se abrir uma raia de app em
paralelo (decisão E1), o kit pode andar junto com `DB-001` e `DB-004` sem colisão, porque um mexe só
em `app/lib` e o outro só em servidor e scripts. Nesse caso, junte o kit à próxima onda de telas, para
pagar a recaptura uma vez.
