# Receipt de trabalho — BT-UIEV-001: pin do ChromeDriver e recaptura de UI

Status: `PARCIAL · GATE_NAO_FECHADO · BLOQUEADO_POR_REDE_DO_EMULADOR`

Registra o destravamento de `BT-UIEV-001`, que hoje impede `BT-SCP-001` de
fechar a cláusula de gate amplo. Não autoriza PR, merge, deploy, migration, DML
live, capability `ON` nem promoção de deck/regra.

## Identidade

- Branch: `codex/free-beta-release-candidate-2026-07-17`
- SHA base: `d26f23a16`
- Dart SDK: `3.12.2 (stable)` · Flutter pinado `3.44.6`
- PostgreSQL: 17.9 (Homebrew), subido ad hoc com `pg_ctl`, não como serviço
- Digest de UI das capturas finais: `8bba809cb761…`
- Árvore compartilhada com outras sessões durante o trabalho — ver 3b
- Autorização usada: *"voce esta autorixado a fazer o download e oque for
  necessario"* (2026-09-21), para baixar o ChromeDriver e o que fosse preciso

## O bloqueio, como estava

Seis scripts de visual QA carregavam, cada um na linha 7, o mesmo caminho
literal com o ChromeDriver **150.0.7871.124**. Outros quatro consumidores
(`binder_import`, `web_image_memory_profile`, `p0_runtime_capture`,
`ui_live_evidence_gate`) não tinham pin nenhum e caíam em
`command -v chromedriver`. Medido nesta máquina:

| onde | versão |
| --- | --- |
| pin dos 6 scripts | 150.0.7871.124 |
| cache, baixado à mão e nunca usado | 151.0.7922.77 |
| `chromedriver` do PATH (Homebrew) | **147**.0.7727.50 |
| Chrome instalado | **153**.0.8010.50 |

Cada script decidia sozinho e todos decidiam errado: os seis falhavam no
`ChromeDriver major 150 does not match Chrome major 153`, e os quatro sem pin
teriam usado o 147. Nenhum script do repositório baixava driver.

## O que foi feito

### 1. Um pin, num lugar só

`scripts/lib/manaloom_chromedriver.sh` concentra versão, plataforma, SHA-256,
URL e cache, e resolve fechado: override explícito → pin em cache → `BLOCKED`
apontando para o bootstrap. **O PATH nunca entra** — é a mesma armadilha do
`flutter` do PATH que reescreve `pubspec.lock`.

`scripts/manaloom_chromedriver_bootstrap.sh` baixa do Chrome for Testing,
confere SHA-256 e desempacota. Idempotente e fechado: hash divergente apaga o
arquivo e sai com 2.

Driver instalado: **153.0.8010.52**, 9.277.002 bytes, SHA-256
`23dc682b73c6473562b4b0d6ddd5b8a0823dbeeccd32a901d085df5f8d87b5cd`, baixado da
URL que o JSON oficial do CfT informa — não montada à mão. O 153.0.8010.50 do
Chrome instalado não existe como build de CfT; o `.52` é o par publicado, mesmo
major, e foi provado dirigindo o Chrome real:

```
sessao: 67132007fa5c13c5645a5840ac588a04
title : manaloom-ok
```

Provas do bootstrap e do resolver:

| prova | resultado |
| --- | --- |
| bootstrap com cache vazio (`HOME` temporário) | baixa, confere, desempacota, `rc=0` |
| bootstrap com driver já em cache | não toca na rede, `rc=0` |
| SHA-256 divergente | apaga o arquivo e sai com 2 |
| `MANALOOM_CHROMEDRIVER_BIN` inexistente | `rc=2`, não cai no pin em silêncio |
| major do driver ≠ major do Chrome | falha fechado |

### 2. Contrato de propriedade, não de literal

`server/test/flutter_release_sdk_contract_test.dart` ganhou
`every ChromeDriver consumer resolves through the shared pin`: **todo** script
que menciona chromedriver precisa sourcear a biblioteca, não pode consultar o
PATH e não pode carregar pin próprio. Mutação:

| mutação | resultado |
| --- | --- |
| script volta a consultar o PATH | falha |
| script carrega pin próprio | falha |
| script deixa de sourcear a lib | falha |
| lib perde o SHA-256 | falha |
| pristino | passa |

### 3. Regressão minha, achada antes de commitar

Extrair o pin para a biblioteca **tirou o pin do escopo do digest de UI**. A
versão vivia inline nos seis scripts de visual QA, que estão na lista de
`manaloom_ui_source_digest.sh`; a biblioteca nova não estava. Trocar o driver
deixaria de invalidar evidência alguma — capturas velhas passariam por frescas,
que é exatamente o defeito que `BT-UIEV-001` existe para consertar.

Corrigido adicionando `scripts/lib/manaloom_chromedriver.sh` ao escopo, com o
porquê escrito no lugar. Provado:

| pin na lib | digest de UI |
| --- | --- |
| 153.0.8010.52 | `4fa7504234cb…` |
| 151.0.7922.77 | `f76f0db81918…` |

O digest **move**. (Os dois valores absolutos acima foram medidos antes de eu
descobrir o lockfile corrompido descrito em 3b, então correspondem àquele
estado de árvore; o que a tabela prova é a **diferença** entre os dois pins,
que é o ponto. O digest da árvore limpa é `8bba809cb761…`.) E uma asserção nova impede a recorrência: remover a lib da
lista faz o contrato falhar.

Custo assumido: mover o digest invalidou as 18 capturas que eu já tinha feito,
e elas foram refeitas. A ordem correta teria sido corrigir o escopo antes de
capturar.

### 3b. O digest que congelei estava errado — outra sessão corrompeu o lockfile

Ao recapturar, o primeiro pack falhou a compilar:

```
Failed to build bundle
_TestFlutterView implements FlutterView   <- sem 'displayCornerRadii'
```

Erro que não existia na captura anterior. Causa: `app/pubspec.lock` apareceu
modificado na árvore sem eu ter tocado — `meta 1.18.0 → 1.17.0` e
`test_api 0.7.11 → 0.7.10`. É a assinatura exata de um `pub get` implícito com
o `flutter` do PATH, que nesta máquina é mais antigo que o SDK pinado. Outra
sessão trabalhando na mesma árvore caiu na armadilha que eu mesmo tinha caído
horas antes, e que já estava registrada.

**Consequência que quase passou:** `app/pubspec.lock` está no escopo do digest
de UI. O digest que eu havia congelado para recapturar, `4fa75042`, foi
calculado **já com o lockfile corrompido**. Recapturar contra ele teria
produzido 216 capturas atestando um estado de origem que não existe.

| estado da árvore | digest |
| --- | --- |
| lockfile corrompido (o que congelei por engano) | `4fa7504234cb…` |
| lockfile restaurado (o correto) | `8bba809cb761…` |

Restaurado com `git checkout --` e ressincronizado com o Flutter **pinado**
(`flutter-3.44.6/bin/flutter pub get --enforce-lockfile`), o lockfile voltou
intacto e o build passou. A lição é de sequência: **recalcular o digest
imediatamente antes de capturar, com `git status` limpo**, e não confiar num
valor congelado minutos antes numa árvore compartilhada.

### 4. Recaptura

Os seis scripts rodaram com o driver 153, `rc=0` em todos, produzindo 18 packs
web em três viewports (mobile 390×844, desktop 1440×900, wide 1920×1080):

| pack | checkpoints por viewport |
| --- | --- |
| 02 collection-import | 7 |
| 03 deck-workshop | 12 |
| 05 social-trade | 16 |
| 06 onboarding-intent | 5 |
| 07 visual-system | 10 |
| 08 critical-overlays | 22 |

**216 screenshots**, todos `PASS_RUNTIME`.

`p0-matrix`: os três perfis web capturados e indexados contra a fixture
autenticada isolada, 53 checkpoints cada, em `8bba809c`. A fixture encerrou com
`exit 0` nas duas vezes que subiu, o que é o próprio contrato de cleanup dela
(banco descartável removido, sem listener remanescente).

Detalhe do fluxo que vale registrar: `--index-p0-matrix` chama
`attest_android_runtime` **antes** de indexar qualquer perfil, então mesmo para
indexar só os três perfis web é preciso ter um Android conectado. O emulador
foi religado apenas para essa atestação — não para capturar.

### Estado final por artefato

| artefato | digest | estado |
| --- | --- | --- |
| 18 packs web (216 screenshots) | `8bba809c` | `PASS_RUNTIME` |
| `p0-matrix` web mobile/desktop/wide (159 checkpoints) | `8bba809c` | `PASS_RUNTIME` |
| `p0-matrix` android emulator | `865e6041` | **não capturado** |
| `p0-matrix` android físico | `d517adb6` | não tentado |
| `docs/qa/ui-live/latest.json` | `865e6041` | **não atualizado** |

`latest.json` ficou intocado de propósito: ele é a atestação agregada, e
atestar um conjunto incompleto seria falsificar evidência. Ele só pode ser
reescrito quando os 23 manifests que referencia estiverem todos no digest
corrente.

### 5. Leitura de cada captura

A política é explícita: `reviewer_must_open_every_screenshot: true`. **216 de
216 screenshots abertos, 18 de 18 packs**, cada um avaliado nos 10 critérios
obrigatórios, com achados bloqueantes passando por refutadores independentes.

Nenhum defeito de layout bloqueante sobreviveu. Os follow-ups recorrentes:
truncagem de metadados longos no clamp de duas linhas, quebras órfãs em rodapés
de status, miniaturas de fallback com selo de imagem quebrada em cards marcados
como prontos, e telas desktop/wide com estado único subutilizando o canvas —
este último já estava na revisão anterior e continua.

## O que NÃO fechou, e por quê

### Perfil Android do `p0-matrix`: rede do emulador

`android_emulator_manaloom_api34` falhou na indexação:

```
Runtime console contains forbidden entries: [🖼️ CachedCardImage] falha.
```

13 falhas de carregamento de imagem, todas
`Failed host lookup: 'api.scryfall.com'`. A causa não é o app: **o emulador
desta máquina não tem rede.**

```
$ adb shell ip addr show
1: lo          <LOOPBACK,UP>
15: eth0       <BROADCAST,MULTICAST> state DOWN
16: wlan0      <NO-CARRIER,BROADCAST,MULTICAST,UP> state DOWN
$ adb shell ip route
(vazio — sem rota default)
$ adb shell toybox nc api.scryfall.com 443
nc: No address associated with hostname
```

Quatro configurações tentadas, mesmo resultado: padrão; `-dns-server`;
`-feature -Wifi` (que faz `eth0`/`wlan0` aparecerem, mas `DOWN`); e ciclo limpo
matando `netsimd` órfão e os locks do AVD. O host alcança o Scryfall
normalmente (HTTP 302), então é o stack de rede do emulador, não a máquina.

Os três perfis web não sofrem disso porque a fixture serve as imagens por
`fixture_image_url` em loopback; no emulador, parte das cartas semeadas aponta
para o Scryfall real.

Os 53 goldens que a corrida falha produziu foram **revertidos** — não fica no
repositório captura de corrida que não passou.

### Consequência para o gate

`docs/qa/ui-live/latest.json` referencia 23 manifests, entre eles o do emulador.
Enquanto ele não for capturado, o agregado não pode virar `PASS`, e portanto:

1. `ui_live_evidence` continua vermelho;
2. `BT-UIEV-001` não fecha;
3. `BT-SCP-001` continua sem a cláusula de gate amplo;
4. commits continuam precisando de `--no-verify`.

O único outro caminho é o perfil `android_physical_sm_a135m` no aparelho físico
conectado (`R58T300SREH`). **Não fiz isso**: é o celular do dono, e instalar e
dirigir o app nele é efeito colateral no aparelho pessoal dele. Precisa de
autorização explícita.

## Contradição registrada: C17

Três revisores independentes abriram os 48 screenshots do pack 05 e
classificaram como bloqueio de escopo de Beta: chip `Venda`, `R$ 18,50`, tipo
de negociação `Compra` com carrinho, `Resumo de valor`, `Explorar Marketplace`.
`server/config/release_capabilities.json` tem `marketplace` e `trades` em
`allowed=false` — como as 29 capabilities.

**Não é falha de gating.** O pack monta as telas diretamente —
`home: const Scaffold(body: MarketplaceTabContent())` e
`home: const CreateTradeScreen(...)` em
`social_trade_visual_runtime_proof_test.dart:713,747` — e nunca passa pelo
router, onde `/marketplace` tem `redirect` (`app/lib/main.dart:804-805`). As
telas existem no código e são inalcançáveis no app entregue.

O que sobra é higiene de evidência: 48 capturas apresentam comércio como
superfície viva, sem marcador de que está desligado. Quem auditar sem ler o
teste conclui que o Beta vende cartas — foi o que três revisores concluíram.
Registrado como C17 no mapa operacional; a decisão (marcar o pack ou aposentá-lo
enquanto a capability estiver off) é do dono.

## Ambiente, para reprodução

- `PostgreSQL` precisa de locale válido no macOS. Sem ele:
  `FATAL: postmaster became multithreaded during startup`. Subir com
  `LC_ALL=en_US.UTF-8 pg_ctl -D /opt/homebrew/var/postgresql@17 start`.
  É o mesmo `LANG` vazio que quebrava o contrato de grep do web público.
- A fixture autenticada exige `MANALOOM_CONFIRM_POSTGRES_WRITES` e
  `MANALOOM_CONFIRM_LIVE_MUTATIONS` com a frase de aprovação explícita. Elas
  autorizam apenas os dados descartáveis da rotina local.

---

## Adendo: `play-vs-ai-web-real`, o 23º manifest

O E2E que recaptura este pack falhava numa asserção de produto. Investigado até
o fim; são **dois** defeitos distintos, e nenhum dos dois é este trabalho.

### 1. A asserção nunca pôde passar — corrigida

`play_vs_ai_real_xmage_e2e_test.dart:357` exigia
`interactive_battle_action_stale`. O servidor devolve
`interactive_battle_not_waiting`. Medido duas vezes, ambas falhando aos 3
segundos — determinístico, não flaky.

A causa está na ordem das checagens de `reserveAction`
(`interactive_battle_store.dart:560-640`):

| # | checagem | erro |
| --- | --- | --- |
| 1 | chave de idempotência já vista | `duplicate` |
| 2 | status terminal | terminal |
| **3** | **`status != waitingForAction` ou `prompt == null`** | **`not_waiting`** |
| 4 | expirado | `session_expired` |
| 6 | `UPDATE … WHERE status='waiting_for_action' AND state_version=@v AND active_prompt_id=@p` casa 0 linhas | `action_stale` |

A primeira ação aceita executa o `UPDATE` que põe `status='action_pending'` e
`active_prompt_id=NULL` (linhas 600-626). O reenvio sequencial da mesma ação
com chave nova, portanto, bate na checagem 3 e **nunca chega** à 6.
`action_stale` só é alcançável em corrida real — duas requisições simultâneas
passando a checagem 3 e só uma vencendo o `UPDATE`. Um teste sequencial com
`await` não consegue produzi-lo por construção.

**O teste nunca passou, e não é regressão.** O histórico prova: o arquivo
nasceu em `f6f791098` (um único commit, sem ancestral), e o mesmo commit não
tocou a ordem das checagens do store — só o tratamento de status terminal. E
ninguém percebeu porque o teste exige **seis** variáveis de ambiente
simultâneas, incluindo as duas frases de aprovação e um `DB_NAME` casando
`^manaloom_s1_api_[A-Za-z0-9_]+$`. É a mesma classe de problema do `full` nunca
cobrir `app/integration_test/`: teste que não roda não protege.

Corrigido para aceitar os dois códigos — ambos são rejeição legítima do mesmo
replay — com o raciocínio acima escrito no lugar. Verificado: o estágio
`real_api_postgresql_xmage_contract` passa a passar.

### 2. Bug de produto que a investigação revelou — NÃO corrigido

`app/lib/features/battle/services/interactive_battle_service.dart:265-275`
traduz `interactive_battle_action_stale` para *"A mesa avançou antes desta
escolha. O estado será atualizado."* e **não tem ramo para
`interactive_battle_not_waiting`** — que é o erro que o servidor realmente
devolve nesse cenário. O jogador recebe o fallback genérico *"Não foi possível
atualizar a mesa."*

A diferença importa: uma mensagem diz que o app se recupera sozinho, a outra
parece falha. E o cenário é comum — duplo toque numa opção, ou tocar de novo
quando a rede demora.

A correção é uma linha, acrescentar `'interactive_battle_not_waiting' ||` ao
mesmo ramo. **Não fiz**: `app/lib` está no escopo do digest `8bba809c`, e
mexer ali invalidaria os 216 screenshots recém-capturados. Entra quando o
conjunto fechar.

### 3. O que ainda bloqueia a recaptura

Com a asserção corrigida, o E2E avança e passa a falhar no estágio seguinte,
`start_browser_qa_api_fixture`:

```
BLOCKED: build output has a consumer
Browser QA API fixture exited before readiness
```

`manaloom_server_contract_e2e_isolated.sh:353-365` recusa começar se `lsof`
encontra qualquer processo segurando `server/build`. O E2E invoca esse script
**duas vezes** — contrato e depois fixture de browser — e o servidor da
primeira invocação ainda não soltou o diretório quando a guarda da segunda
verifica. Medido: logo após a falha, `lsof +D server/build` não devolve nada;
o consumidor existe apenas durante a transição.

Reproduzido duas vezes seguidas. É corrida de handoff na orquestração, não
ambiente e não este trabalho. A guarda em si está certa — o que falta é o
estágio esperar a liberação antes de checar.

**Estado final: 22 de 23 manifests no digest corrente.** `latest.json` segue
intocado, e a evidência antiga do pack foi restaurada byte a byte ao estado
commitado depois de cada tentativa.
