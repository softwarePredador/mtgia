# BrewTact — mapa operacional do projeto — 2026-09-18

Status: `MAP · STATIC_ANALYSIS · NO_AUTHORITY · NOT_RATIFIED`

Este documento é **mapa, não autorização**. Ele não decide escopo, não abre
capability, não autoriza deploy, migração, escrita live nem promoção. Ele
existe para que alguém entenda o projeto inteiro sem depender de memória.

Tudo aqui foi medido por análise estática deste checkout em 2026-09-18. Ele
**não observa runtime nem produção**. Onde um fato exige o host ou o banco,
está na seção 9 com o comando que o resolve.

Ele **referencia** os documentos canônicos em vez de duplicá-los. Onde um
mecanismo já está descrito, o link é a resposta.

---

## 0. Cadeia de autoridade

Cinco camadas, não intercambiáveis (`docs/execution/README.md:11-20`):

| # | Camada | Decide |
| --- | --- | --- |
| 1 | `docs/status/CURRENT_PRODUCT_DECISION.md` | produto, oferta, escopo de release |
| 2 | `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` | **única autoridade manual** sobre ID, prioridade, estado, dependência, aceite |
| 3 | `docs/generated/TASK_REGISTRY.json` | projeção gerada — nunca editar à mão |
| 4 | `docs/execution/CURRENT_QUEUE.md` | só ordena; WIP 1 |
| 5 | `docs/execution/tasks/*.md` | livro-razão manual, não é receipt validado |

Regra herdada: **nenhum documento, fila, packet ou receipt autoriza deploy,
migração live, escrita live em PostgreSQL, chamada mutante em API live ou
promoção de learning.** Receipt durável vive em `docs/qa/execution/`;
evidência em `/tmp` não conta.

---

## 1. O produto e a decisão vigente

Fonte: `docs/status/CURRENT_PRODUCT_DECISION.md` (2026-08-25).

| Item | Valor |
| --- | --- |
| Estado de release | `NO_GO_PUBLIC_RELEASE` |
| Candidato | `CONTROLLED_FREE_BETA`, coorte pequena e controlada |
| Plataformas | Web e Android |
| Fora por escopo | iOS e VoiceOver (`DEFERRED_BY_SCOPE`) |
| Oferta | beta gratuita — sem preço, plano Pro, assinatura, checkout, renovação, anúncio ou paywall |
| Teto de uso | 120 ações de IA elegíveis por mês UTC |
| Battle | "Jogar contra IA" é a experiência; **nunca** haverá rota, CTA ou modo de espectador público |
| Marca / origem | BrewTact · `https://brewtact.com` |

O teto de 120 está implementado (`server/lib/plan_service.dart:94`) mas é
**inerte hoje**: o middleware de capability responde 404 em todo `/ai/*`
antes do middleware de plano rodar.

---

## 2. Mapa de jornadas

### Os dois portões, ambos fail-closed

- **Servidor** — `server/routes/_middleware.dart:105-116` consulta
  `ReleaseCapabilityPolicy` em toda requisição. Capability negada → **404
  `capability_unavailable`**. Rota não classificada e fora do allowlist →
  **404 `capability_route_unclassified`**. Config inválida → 503 com as 29
  forçadas off. **Não há bypass de desenvolvimento.**
- **App** — `ReleaseCapabilityRouteGuard` (`app/lib/core/config/release_capabilities.dart:350`),
  ligado em `app/lib/main.dart:426`. O snapshot default é `denied()` e
  qualquer falha de refresh volta a `denied()`: backend inalcançável
  equivale a tudo desligado.

### Números medidos

| Medida | Valor |
| --- | --- |
| `GoRoute` no app | **46** |
| Rotas alcançáveis hoje | **10** — `/`, `/login`, `/forgot-password`, `/reset-password`, `/verify-email`, `/legal`, `/home`, `/onboarding/core-flow`, `/plans`, `/profile` |
| Destinos de navegação renderizados | 2 de 5 (Início, Perfil) |
| Arquivos de rota no servidor | **120** |
| └ não nomeados em nenhum fluxo declarado | **99** |
| Fluxos declarados em `project_logic_contracts.json` | 8 |
| Capabilities | 29 · **`allowed=true`: 0** |

**Só uma jornada funciona hoje: `auth_session`** — e mesmo ela sem
auto-cadastro (`account_registration` off; o app redireciona `/register` para
`/login`).

### Estado por jornada

| Jornada | Implementado | Alcançável hoje | Capability que segura |
| --- | --- | --- | --- |
| auth_session | sim | **sim** (sem cadastro) | — / `account_registration` |
| card_collection | sim | não | `catalog_private` |
| deck_lifecycle | sim | não | `decks_private` |
| deck_ai — Analyze | sim | não | `ai_analyze_optimize_advisory` |
| deck_ai — Generate | experimental | não | `ai_generate_rebuild` |
| deck_ai — Optimize/Complete | sim, guardado | não | `ai_analyze_optimize_advisory` |
| deck_ai — Rebuild | sim | não | `ai_generate_rebuild` |
| battle / jogar contra IA | **não compilado no artefato** | não | `battle_batch` + trava de compilação |
| life_counter | client-only | parcial | `life_counter_local` (sem rota) |
| social_trade | sim | não | `marketplace` |
| release_operations | sim | n/a | plano de controle |

Para a narrativa detalhada de Deck/IA/Battle, ver
`docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md`. **Ressalva
importante:** a coluna "Funciona hoje" daquela matriz significa
*implementado*, não *alcançável* — ela não menciona a política de capability
em nenhum ponto. Ver contradição C1.

Para o mecanismo de qualidade da geração, ver `docs/DECK_QUALITY_MODEL.md`.

---

## 3. Escopo — o que fica e o que sai

As 29 capabilities de `server/config/release_capabilities.json`
(`policy_version: brewtact_free_beta_2026-08-13`) estão **todas `off`**, e
`live_verified_as_of` é `null`.

O que a decisão declara **fora**: preço, plano Pro, assinatura, checkout,
renovação, anúncio, paywall, iOS, VoiceOver, e qualquer superfície pública de
espectador de Battle.

O que fica **dentro** do candidato: beta gratuita em Web e Android, para
coorte controlada, com teto de 120 ações de IA/mês.

**Gaps entre código e decisão** (ver seção 8): `deck_replace_all` e
`legacy_ai_routes` são portões reais que a decisão não menciona; o schema da
política **não tem campo `reason`**, então não existe motivo documentado para
eles. `/market/card/:id` e `/market/movers` andam sob `catalog_private`, não
sob `marketplace` — abrir o catálogo abriria preço e movers.

---

## 4. Dependências externas e quando atualizar

Esta é a seção que o projeto não tinha.

### 4.1 Os dois motores de regras

| | XMage | Forge |
| --- | --- | --- |
| Repositório | `github.com/magefree/mage` | `github.com/Card-Forge/forge` |
| Licença | MIT | **GPL-3.0-only** |
| Papel | executor primário de regras | secundário, para lacunas estruturadas do XMage |
| Fronteira | sidecar isolado por API | **processo isolado, API apenas, proibido copiar fonte para o backend** |
| Pin canônico | `services/xmage-sidecar/XMAGE_COMMIT` | `services/forge-sidecar/FORGE_COMMIT` |
| Valor atual | `2c43ec8cd…` | `a62915f50…` |
| Atualizado em | 2026-07-28 (**52 dias**) | 2026-07-14 (**66 dias**) |
| Espelhos obrigatórios | **7** | 2 no auditor (+1 de facto fora dele) |

O XMage tem um segundo pin, de **patch governado** —
`XMAGE_PATCH_COMMIT = 991948742…`, atualizado em 2026-08-03 (46 dias) — que
existe para aplicar correções próprias sobre o upstream sem forkar.

A fronteira do Forge é **jurídica, não técnica**: GPL-3.0 contaminaria o
backend se a fonte fosse copiada. Por isso `isolated_process_api_only`.

### 4.2 O que uma transição de pin exige

Fonte: `docs/hermes-analysis/EXTERNAL_ENGINE_PIN_TRANSITION_CONTRACT.json`.

- O relatório semanal é **discovery only** — nunca autoriza avançar.
- Exige **diff Git exato**; a lista truncada da API do GitHub não serve.
- **Toda carta alterada precisa ser classificada nominalmente.**
- Resolver o nome no catálogo **não** é prova semântica.
- Exige reconciliação read-only com o PostgreSQL antes do deploy.
- Deploy exige `qualification_status: pass`.

Gate: `./scripts/quality_gate.sh engine-transition`.

Escala da última transição (`34d81ea…` → `2c43ec8…`): 152 commits, 356 paths,
**169 implementações de carta alteradas**, 34 em escopo de produto, 133
bloqueadas por política de ativação. Atualizar pin não é trocar um SHA.

### 4.3 Detecção de drift — e por que não está funcionando

O mecanismo existe e é bom: `external_engine_upstream_delta_audit.py` compara
o pin contra `master` pela GitHub Compare API, para os dois repositórios.
Cadência pretendida: domingo, 09:17, via LaunchAgent.

**Estado real medido:**

| Relatório | Status |
| --- | --- |
| 2026-07-28 | consultou upstream (`review_required`) |
| 2026-08-25 | consultou upstream (`review_required`) |
| 08-02, 08-10, 08-17, 08-24, 08-31, 09-13 | **`skipped · dirty_worktree`** |
| `latest.json` | `skipped · dirty_worktree` |

**Seis das oito auditorias foram puladas porque a árvore de trabalho está
suja.** Com centenas de arquivos modificados pendentes, a auditoria se recusa
a rodar. O LaunchAgent também não está instalado, e o instalador recusa
checkouts sob `~/Documents` por TCC — que é exatamente onde este repo está.

Consequência: **hoje o projeto não sabe o quanto os dois motores
divergiram.**

### 4.4 Upstreams de dado

| Fonte | Consome | Última checagem | Dias | Checagem automática |
| --- | --- | --- | --- | --- |
| MTGJSON (catálogo) | `sync_cards.dart` | 2026-06-06 | 104 | script existe, **não registrado** |
| Scryfall (legalidades) | `sync_card_legalities_from_scryfall.py` | 2026-06-06 | 104 | job registrado, **dry-run por padrão** |
| Scryfall (rulings) | `sync_rulings.dart` | — | — | script existe, não registrado |
| EDHREC | `cron_snapshot_edhrec.sh` | 2026-06-02 | 108 | não registrado |
| WotC Comprehensive Rules | `sync_rules.dart` | 2026-06-19 | 91 | comparador upstream real, **fora de cron e CI** |
| WotC Game Changers | `commander_game_changers.json` | 2026-07-14 | **66** | gate roda a cada commit mas **nunca compara com a WotC** |
| Corpus de meta interno | `extract_meta_insights.dart` | 2026-03-13 | **189** | nenhuma |

Padrão único e repetido: **os fetchers existem, são determinísticos e têm
provenance; o relógio não existe.** Oito scripts de sync vivem como receita de
crontab em comentário, nunca registrados em `manaloom_ops_daemon.py`.

### 4.5 Regra de atualização sugerida

| Dependência | Quando atualizar | Gate obrigatório |
| --- | --- | --- |
| XMage pin | quando o delta semanal acusar carta em escopo de produto | `engine-transition` completo |
| XMage patch pin | junto com o pin, ou ao corrigir fronteira | `engine-transition` |
| Forge pin | idem XMage, respeitando a fronteira GPL | `engine-transition` |
| Catálogo / legalidades | a cada lançamento de coleção e a cada B&R | `catalog_private` aberto + `BT-CAT-01` |
| Game Changers | a cada anúncio de bracket da WotC | gate estendido para comparar upstream |
| Comprehensive Rules | a cada revisão oficial | `sync_rules.dart --check` em CI |
| Corpus de meta | contínuo, com filtro de formato e decaimento | `deck-quality` sem regressão |

---

## 5. O que roda onde

| Componente | Definido em | Deploy por | No caminho hoje |
| --- | --- | --- | --- |
| Backend Dart Frog | `server/` | `manaloom_deploy_backend_image.sh` | sim |
| `manaloom-ops` (scheduler) | `server/Dockerfile.manaloom-ops` | `manaloom_deploy_ops_image.sh` | sim — **1 job ativo** |
| Sidecar XMage | `services/xmage-sidecar/` | `manaloom_deploy_battle_sidecars.sh` | sim |
| Sidecar Forge | `services/forge-sidecar/` | idem | sim |
| Flutter Web | `app/` | `manaloom_deploy_flutter_web.sh` | **bloqueado** — exige capability aberta |
| APK Android | `app/` | `manaloom_publish_android_release.sh` | sim — fixa o snapshot de capabilities na identidade do release |
| Web público (Next.js) | `web-public/` | `manaloom_deploy_public_web.sh` | sim — **único sem nenhuma referência a capability** |
| `hermes-lab` | `server/Dockerfile.hermes-lab` | nenhum | **não** — dormente desde 2026-06-23 |

O `manaloom-ops` sobe em `safe_housekeeping_only` com exatamente um job
habilitado, `hermes_cron_governor_report`, que só resume o próprio scheduler
e **não escreve em PostgreSQL**. Ver `docs/DECK_QUALITY_MODEL.md` seção 5
para os três cadeados independentes.

---

## 6. Etapas e caminho crítico

`TASK_REGISTRY.json`: **220 tasks, 402 arestas de dependência, 3 em `PASS`**.

Slot `NOW`: `BT-SCP-001`, WIP 1. Horizonte de 11 IDs.

O gargalo real não é descobrir trabalho — é vazão. Com 220 IDs e 3 fechados,
produzir mais achados não acelera nada. O caminho crítico passa por destravar
os gates (seção 7) antes de qualquer feature.

Para a proposta da cadeia de qualidade de deck, ver
`docs/execution/PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md`.

---

## 7. Gates — e quais estão quebrados

`scripts/quality_gate.sh` tem ~25 modos. `.githooks/pre-commit` roda
`manaloom_local_ci.sh quick`; `pre-push` roda `full`.

**O bloqueio difere por arm.** `pre-commit` roda `quick`; `pre-push` roda
`full`. Medido em 2026-09-21:

| Gate | Arm | Estado |
| --- | --- | --- |
| contratos de shell | quick | passa |
| fonte de Game Changers | quick | passa |
| MCP local | quick | passa |
| secret scan | quick | passa |
| **project logic** | quick | **passa** — corrigido em `d83e9b1e1` |
| **`ui_live_evidence`** | quick | **falha** — 23 de 35 packs com digest defasado |
| **`manaloom_public_web_surface_contract`** | full | **passa** — corrigido em 2026-09-21 |
| **`npm audit` do web público** | full | **falha** — advisory upstream, `next` critical + `sharp` high |

O gate de project logic era o bloqueio principal e foi resolvido: o teste
chamava `generate()` sem antes rodar `bootstrapWorkspacePackages`, que é o que
amarra cada `package_config.json` ao `PUB_CACHE` isolado que a validação
exige. Ver `docs/execution/PROPOSED_TASKS_DECK_QUALITY_2026-09-18.md`.

O contrato de web público também caiu, e o diagnóstico inicial registrado aqui
— "HTML renderizado / falta build local" — **estava errado**. A causa real era
portabilidade de regex: `manaloom_public_web_assert_free_beta_files` usava as
classes `[aá]` e `[cç]`. Um caractere acentuado ocupa dois bytes em UTF-8, e o
`grep` do BSD trata uma classe como conjunto de **bytes** isolados fora de um
locale UTF-8 — o padrão passa a esperar um byte onde o texto tem dois e nunca
casa. O contrato falhava em qualquer máquina com `LANG` vazio, mesmo com a
landing correta. As classes viraram alternâncias (`gr(a|á)tis`,
`cobran(c|ç)a`), que casam a sequência inteira sob `LC_ALL=C` e sob UTF-8.

O erro de diagnóstico tem uma lição própria: a verificação manual passava
porque o `grep` do meu shell é **ugrep 7.8.4**, enquanto os scripts resolvem
`/usr/bin/grep` (BSD). Comprovar um contrato de shell exige rodá-lo pelo mesmo
caminho que o CI usa, não pelo `grep` do PATH interativo.

Com aquele contrato corrigido, o `full` passou a chegar ao **último** estágio e
revelou o bloqueio que estava escondido atrás de todos os outros:
`manaloom_public_web_smoke.sh:199` roda
`npm audit --omit=dev --audit-level=moderate`, e `web-public` tem duas
vulnerabilidades — `next` (**critical**, RCE não autenticado) e `sharp`
(**high**). Ambas caem com `next@15.5.25`, que não é semver-major.
`package.json` fixa `"next": "15.5.21"` exato e força
`"overrides": {"sharp": "0.35.3"}`, abaixo do `0.35.4` corrigido.

Medido isoladamente, fora do gate: `npm audit` falha por conta própria. Não é
regressão de nenhum trabalho em curso — é advisory upstream que só ficou
visível quando o gate passou a chegar lá. **É hoje o único ponto do `full` sem
nenhuma falha de teste associada**, e envolve bumpar dependência do artefato
público deployável: decisão do dono, não da fila.

**O bloqueio restante é `ui_live_evidence`, e tem duas camadas.** O digest de
UI é **global por desenho** (`scripts/manaloom_ui_source_digest.sh` cobre
`app/lib`, `app/assets`, `app/web`, Android, pubspecs, 11 testes de prova
visual, drivers e fixtures), então qualquer mudança em `app/lib` invalida os
35 packs de uma vez — não há granularidade por superfície. E a recaptura está
travada por versão: o ChromeDriver pinado em 6 scripts é o 150, o Chrome
instalado é o 153, e nenhum script do repositório baixa driver.

**Consequência séria:** hoje nenhum commit nem push passa sem `--no-verify`.
Três bypasses foram usados em 2026-09-18 sob autorização explícita, e estão
registrados em `docs/qa/execution/2026-09-18/deck-quality-harness.md`. Um gate
que sempre é contornado deixa de proteger.

Some-se o Node: o do PATH é `v20.11.1`, abaixo do mínimo, e o fallback do
Homebrew está quebrado. O caminho que funciona é
`MANALOOM_NODE_BIN=/opt/homebrew/opt/node@22/bin/node`.

E a árvore suja bloqueia a auditoria de drift das engines (seção 4.3). Ou
seja: **o estado sujo do checkout tem custo operacional real, não só
cosmético.**

---

## 8. Contradições registradas

Achados de divergência entre dois documentos, ou entre documento e código.
Esta é a seção mais acionável.

| # | Contradição | Evidência |
| --- | --- | --- |
| C1 | 6 linhas da matriz de prontidão dizem "funciona hoje: sim" para jornadas que respondem 404 | `…CURRENT_FLOW:376-381` vs capabilities `allowed=false` |
| C2 | A mesma matriz **nunca menciona** a política de capability — zero ocorrências de `release_capabilit` | o próprio arquivo |
| C3 | Pelo critério do commit `d93867b68`, a matriz qualificava como documento a marcar e **não foi marcada** | é um sétimo caso |
| C4 | Battle descrito como "guardado" quando **não é compilado no artefato** | `main.dart:675,690,704,713` |
| C5 | `OFF_UNTIL_P0_RECEIPT` não é valor legal do schema; o JSON guarda `off` puro | decisão vs `policy:65-69` |
| C6 | Cabeçalho do wrapper de rulings cita MTGJSON; o código consome Scryfall | `cron_sync_rulings.sh:5` vs `sync_rulings.dart:25` |
| C7 | Cadência semanal de drift declarada como instalada; não está, e não pode ser neste caminho | schedule vs `~/Library/LaunchAgents` |
| C8 | O Forge tem um terceiro espelho de pin **fora** do auditor de drift | `battle_engine_config.dart:12` |
| C9 | 26 IDs `P0 CORE` não são ancestrais de `BT-DEC-001`, contra a prosa do backlog | DAG do registry |
| C10 | A fila registra hash de abertura diferente do hash atual do backlog | `CURRENT_QUEUE.md:12-13` |
| C11 | Um fluxo funde Life Counter (client-only) com sync de pós-jogo (bloqueado) | `project_logic_contracts.json` |
| C12 | `/market/card/:id` e `/market/movers` andam em `catalog_private`, não em `marketplace` | `policy:531` |
| C13 | `/decks/:id/reports` exige `gallery_public` enquanto `/reports` é plano de controle | `policy:474-476` |
| C14 | `deck_replace_all` e `legacy_ai_routes` são portões reais sem motivo documentado | o schema não tem campo `reason` |
| C15 | O web público é o único deploy **sem nenhuma** referência a capability — zero ocorrências, verificado | `manaloom_deploy_public_web.sh` |
| C16 | O contrato de egress do harness isolado cobrava quatro trechos que `f6f791098` já havia refatorado — 18 das 22 asserções continuavam válidas, então a deriva passou despercebida | `mutating_e2e_entrypoint_guard_test.dart:371-380` vs `manaloom_server_contract_e2e_isolated.sh:440,674,817` |

C16 já foi corrigido nesta rodada: só o teste mudou, o script do dono ficou
intacto, e o guard de egress nunca se perdeu (`run_pg` é `run_no_egress` com
`PGPASSWORD`, ainda sob `sandbox-exec` loopback-only). A lição é sobre a forma
do contrato: asserções que fixam **texto literal** de um script quebram em
qualquer refactor legítimo, e quando 18 de 22 continuam passando a deriva não
grita. Contratos de shell deveriam cobrar a **propriedade** — "todo passo
privilegiado executa sob `EGRESS_GUARD`, e depois do self-test" — e não o
recorte exato da linha.

C1, C2 e C3 recomendam a mesma correção: separar **implementado** de
**alcançável** na matriz de prontidão. O repositório já rastreia as duas
coisas (`implementation_status` vs `allowed`); o documento é que as funde.

---

## 9. Desconhecidos declarados

Nada abaixo deve ser afirmado sem verificar.

```bash
# cobertura real de perfis de referência — muda a escala do problema de geração
psql "$DATABASE_URL" -c "select commander_name, source, updated_at from commander_reference_profiles order by updated_at desc;"

# estado do container hermes-lab
python3 server/bin/audit_easypanel_cron_runtime.py --require-hermes-lab

# quanto os motores divergiram (exige árvore limpa)
./scripts/manaloom_external_engine_delta_audit.sh
```

Também desconhecido: o estado de produção depois de 2026-08-03 (data do
backup local usado para medir banco); as variáveis de runtime que decidem
qual ramo de geração executa; e se existe revisão das Comprehensive Rules
posterior a 2026-06-19.

---

## 10. Índice — o que ler e para quê

| Documento | Responde |
| --- | --- |
| `docs/status/CURRENT_PRODUCT_DECISION.md` | o que é o produto e o que está decidido |
| `docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md` | o trabalho, sua ordem e seu aceite |
| `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md` | a narrativa de Deck/IA/Battle por jornada |
| `docs/DECK_QUALITY_MODEL.md` | **por que** o deck gerado não é preciso |
| `docs/execution/README.md` | como o trabalho é conduzido e provado |
| **este documento** | como as peças se encaixam, e quando atualizar o que vem de fora |

Material sob `docs/hermes-analysis/` é histórico e não tem autoridade atual.

---

## Procedência

Análise estática deste checkout em 2026-09-18, sobre `0677762d7`. Números de
banco vêm do backup local de 2026-08-03. Nenhum acesso a produção, nenhuma
chamada de rede. Este documento ainda não está em `canonical_documents` de
`docs/project_logic_contracts.json` — registrá-lo é decisão de governança.
