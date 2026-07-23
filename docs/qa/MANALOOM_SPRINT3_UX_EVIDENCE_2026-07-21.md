# ManaLoom Sprint 3 — evidência de UX e acessibilidade

**Estado atual:** S3-01, S3-02, S3-03, S3-05, S3-06, S3-07 e S3-08 `PASS`; S3-04 automatizada e pendente de leitor físico
**Branch:** `codex/free-beta-release-candidate-2026-07-17`
**SHA base:** `2813152121c4d41069f9ebbb3334eb4c6b8b1110`
**Owner:** `/root`
**Execução S3-01:** `2026-07-22T00:33:15Z`
**Toolchain aprovada:** Flutter `3.44.6`, Dart `3.12.2`

## S3-01 — inventário executável de rotas e superfícies

**Decisão:** `PASS`

O antigo mapa manual de keys foi preservado e recebeu uma fonte estruturada
executável. O novo guard descobre as superfícies diretamente em `app/lib`,
compara a ordem das rotas e rejeita qualquer ocorrência nova, removida ou
reclassificada sem atualização explícita do inventário.

### Cobertura fechada

| Tipo | Quantidade |
|---|---:|
| `GoRoute` | 36 |
| `ShellRoute` | 1 |
| `MaterialPageRoute` | 12 |
| Dialogs | 37 |
| Bottom sheets | 22 |
| Menus | 5 |
| Tabs | 11 |
| Navegação responsiva | 2 |
| Transientes (`SnackBar`) | 92 |
| **Total** | **218** |

As 36 rotas têm identidade, path declarado, path canônico, tela/destino,
domínio e escopo. As outras 182 ocorrências são atribuídas a 56 contratos de
arquivo e 18 contratos de domínio. Todo domínio declara:

- job e owner;
- source of truth;
- estados relevantes;
- situação/contrato de stable key;
- criticidade;
- ação, sucesso e recuperação;
- política de deep link.

O inventário registra honestamente três condições de escopo:

- `active`: superfície de produto ativa;
- `compatibility_redirect`: `/market` converge para `/community?tab=3` e não é
  uma tela própria;
- `deferred_by_scope`: Scanner/OCR redireciona para busca manual no artefato
  atual e continua dependente da decisão S4-07.

`stable_key=partial:` classifica dívida; não concede crédito de conclusão. As
lacunas passam para as matrizes de estado/foco S3-02 e S3-05. A decisão de rota
canônica de Card Detail e Battle/Replays permanece explicitamente em S3-06.

### Arquivos da task

- `app/test/ui/fixtures/ui_surface_inventory.json`;
- `app/test/ui/ui_surface_inventory_test.dart`;
- `app/doc/UI_TEST_SURFACE_MAP.md`;
- `docs/MANALOOM_PRODUCT_COMPLETION_TRACKER.md`;
- este arquivo de evidência.

### Gates executados

```text
python3 -m json.tool test/ui/fixtures/ui_surface_inventory.json
  exit 0

flutter 3.44.6 pub get --enforce-lockfile
  exit 0
  pubspec.lock idêntico antes/depois

flutter 3.44.6 test test/ui/ui_surface_inventory_test.dart --no-pub
  4/4 PASS

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh ui-audit
  analyzer: No issues found
  testes: 17/17 PASS
  exit 0

git diff --check
  exit 0
```

Hash do log bruto temporário do `ui-audit`:
`4b2fd3ac768538de54c9605640c693b4a1fc8e63b12b610b72a30f28b45e93c8`.

Hashes dos artefatos executáveis:

- inventário JSON:
  `5c1df5768a3c8a2e9a19db3c9dc565347cfb93723a539c02e5246e48fefc1292`;
- teste guard:
  `055bc6d3e9d8922230f5305d22d0bcae05050d91bcfe3bbcb225864398a79115`.

### Incidente de toolchain e correção

O primeiro teste focado encontrou o `flutter` padrão do terminal em `3.41.6`.
Esse SDK tentou rebaixar somente `meta` e `test_api`; as duas alterações foram
revertidas pontualmente. A execução válida foi repetida com o SDK pinado
`3.44.6`; o hash do lockfile permaneceu
`b45820a3861fc43309b390d707473223d8df5e43e42f00d138170b48cfde6d91`
antes e depois do gate aprovado.

### Ambiente, dados e cleanup

- nenhuma API remota, EasyPanel, SSH ou credencial de usuário foi utilizada;
- nenhum banco, migration ou dado persistente foi criado/alterado;
- nenhum servidor, listener ou processo temporário foi iniciado por S3-01;
- logs brutos permanecem somente em `/tmp`;
- nenhum commit, push ou deploy foi executado.

## S3-02 — matriz de estados, preservação e erro seguro

**Decisão:** `PASS`
**Execução válida:** `2026-07-22T00:48:40Z`

A matriz `app/test/ui/fixtures/ui_state_matrix.json` usa os 18 domínios de
S3-01 e classifica, sem omissão, 15 estados canônicos:

```text
loading, progress, partial, stale, loading_more, saving, optimistic,
disabled, empty, error, retry, offline, session_expired,
permission_denied, success
```

Cada domínio separa estados cobertos dos não aplicáveis, aponta sources,
anchors e testes executáveis, e declara política de preservação de entrada e
erro sanitizado. Update otimista não existe no produto atual: mutations
visíveis aguardam confirmação ou mostram progresso. O gate passa a exigir
rollback/conflito e teste antes de aceitar uma implementação otimista futura.

### Ajustes implementados

- `AppStatePanel.loading` unifica loading de página, indicador visual e anúncio
  por região viva sem duplicar a leitura semântica;
- 17 anchors críticos de loading foram migrados e protegidos pelo guard:
  Battle, Binder, Cards, Community, Decks, Messages, Notifications, Retention,
  Sets, Social e Trades;
- busca de usuário, chat, set catalog/detail e trade inbox/detail receberam
  keys de loading estáveis onde faltavam;
- erro de validação no preview do deck gerado passa por
  `FriendlyErrorMapper`; payload técnico recebe fallback seguro;
- import, export e cópia de deck usam a política central de resposta 5xx e não
  expõem `error` cru do servidor;
- cópia de deck comunitário exibe copy fixa em vez de payload dinâmico;
- o novo guard rejeita renderização direta de `exception.toString()`,
  interpolação de exception e `result['error']` em `Text` de screen/widget.

### Gates válidos

```text
flutter 3.44.6 test <48 arquivos declarados pela matriz>
  288/288 PASS
  exit 0

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh ui-audit
  analyzer: No issues found
  testes: 21/21 PASS
  exit 0

git diff --check
  exit 0
```

Hashes:

- log dos 288 testes:
  `eaa4cc7d0e3249226e33371af50ac47a64c35530d95c3de45b0056506eedf209`;
- log do `ui-audit`:
  `970cb0a6e6b8706afca8515f5f196cee1150bb55d4ce3b64dc11a2124fe8647f`;
- matriz JSON:
  `065f6e1f59ce37675057dbff21cb7a210216706ebde7d17d5e6a1aa72105dcc9`;
- guard Dart:
  `e602e504527f84bb49636c6768ee1368f1698a5476bd7bb7dbd9ddf7a413e299`;
- `pubspec.lock` permaneceu
  `b45820a3861fc43309b390d707473223d8df5e43e42f00d138170b48cfde6d91`.

### Falhas observadas e correção

A primeira execução do guard encontrou quatro falhas: source incorreto da key
manual do Scanner, renderização de erro de validação sem sanitização e duas
expectativas de copy divergentes da política 5xx central. As quatro foram
corrigidas e reexecutadas.

A primeira tentativa de executar todos os arquivos da matriz também falhou
antes de carregar testes porque o zsh recebeu a lista como um único caminho.
Ela não foi contabilizada como falha do produto nem como PASS. O comando foi
corrigido para passar um arquivo por argumento e a repetição válida fechou
`288/288`.

### Ambiente, dados e cleanup

- nenhuma API remota, EasyPanel, SSH ou credencial foi utilizada;
- nenhum banco, migration ou dado persistente foi criado/alterado;
- nenhum servidor/listener/processo temporário foi iniciado;
- logs brutos permanecem em `/tmp`;
- nenhum commit, push ou deploy foi executado.

## S3-03 — matriz responsiva, teclado e texto 200%

**Decisão:** `PASS`
**Execução válida:** `2026-07-22T00:56:19Z`

A fonte canônica `app/test/ui/fixtures/ui_viewport_matrix.json` declara 16
viewports sem lacunas implícitas:

```text
320×568, 390×844, 412×915, 768×1024, 1024×768,
599/600, 839/840, 1199/1200, 1280×900, 1440×900,
1599/1600 e 1920×1080
```

O guard confirma dimensão, orientação e classe responsiva de cada caso, exige
evidência widget executável nos mesmos 18 domínios do inventário S3-01 e
protege explicitamente teclado virtual e escala de texto 2.0.

### Provas e ajustes

- `ResponsivePageFrame` foi exercitado em todos os 16 viewports; conteúdo
  permaneceu dentro da tela, com gutter e largura máxima canônicos;
- `AdaptiveMasterDetail` foi exercitado nos dois lados exatos de 1200 px,
  empilhando em 1199 e compondo dois panes em 1200;
- Home passou por todos os tamanhos e boundaries, inclusive 412×915 e
  1024×768 landscape, preservando hero, CTA e ações rápidas sem overflow;
- Deck Generate em 390×844, texto 200% e teclado de 320 px focou realmente o
  prompt, rolou a tela e manteve o CTA primário dentro da área visível;
- a primeira versão desse teste emitiu warning porque o inset foi aplicado
  antes do foco. A ordem foi corrigida para `ensureVisible` → tap/foco →
  teclado → inset; a repetição válida terminou sem warning.

### Gates válidos

```text
flutter 3.44.6 test <evidência responsiva dos 18 domínios + guards>
  125/125 PASS
  exit 0

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh ui-audit
  analyzer: No issues found
  testes: 25/25 PASS
  exit 0

git diff --check
  exit 0
```

Hashes:

- log dos 125 testes:
  `28db39d379d0d58de3f3620e7631387477519ffdf9dcb9c2496883992c3031ad`;
- log do `ui-audit`:
  `24b13b7d85192910547bf33d5c0a4479a9d3c19316c6d9af1ca23478847d902c`;
- matriz JSON:
  `b08facf8d8326e9e522536615d0b8ff11c663b1c8c4e6746bb37e294ac52a054`;
- guard Dart:
  `93ce99eb34f7aac79ef19502b59e09a96128b4648fe88b36afab9e1bf0ba479f`;
- `pubspec.lock` permaneceu
  `b45820a3861fc43309b390d707473223d8df5e43e42f00d138170b48cfde6d91`.

### Ambiente, dados e cleanup

- nenhuma API remota, EasyPanel, SSH ou credencial foi utilizada;
- nenhum banco, migration ou dado persistente foi criado/alterado;
- nenhum servidor/listener/processo temporário foi iniciado;
- logs brutos permanecem em `/tmp`;
- nenhum commit, push ou deploy foi executado.

## S3-04 — acessibilidade móvel

**Decisão atual:** `BLOCKED` — automação `PASS`; fechamento físico depende
de interação humana no TalkBack e de um iPhone físico online para VoiceOver
**Execução automatizada válida:** `2026-07-22T03:22Z`

A nova matriz `app/test/ui/fixtures/ui_accessibility_matrix.json` cobre os 18
domínios do inventário e fixa oito contratos: labels, roles/state,
live-status, alvo 48 px, texto 200%, contraste WCAG, redundância além de cor e
ordem de leitura. O guard também impede que TalkBack/VoiceOver sejam marcados
como executados implicitamente.

### Ajustes e provas automatizadas

- o harness oficial passou a executar `textContrastGuideline` junto de
  `androidTapTargetGuideline` e `labeledTapTargetGuideline`;
- pares canônicos de texto normal cumprem 4.5:1; controles/foco cumprem 3:1;
- todos os `IconButton` ativos passam por scanner lexical e precisam expor
  tooltip;
- dois controles do Binder foram migrados do wrapper genérico de tooltip para
  o `tooltip` nativo do `IconButton.filledTonal`;
- navegação móvel, painel de estado/live-region, Binder, Home, Card Detail e
  Deck Generate com teclado + texto 200% passaram alvo, label e contraste;
- Mana symbols preservam nomes semânticos, e os guards de fields/state mantêm
  validação, labels e erro seguro.

As primeiras execuções encontraram e separaram corretamente falha de produto
dos falsos positivos de harness: match parcial de `IconButtonThemeData`, handle
semântico encerrado após a verificação e testes Deck/Main Scaffold com tema ou
conteúdo fake incompatível com o app. O scanner, os fixtures e a ordem de
cleanup foram corrigidos antes da execução válida.

### Gates automatizados válidos

```text
flutter 3.44.6 test <matriz de acessibilidade + 28 suites de domínio>
  123/123 PASS
  exit 0

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh ui-audit
  analyzer: No issues found
  testes: 35/35 PASS
  exit 0

git diff --check
  exit 0
```

Hashes:

- log dos 123 testes frescos:
  `4f9d33775ba558d649a5d2837d7870326e3be46d1d2c941ef15e4da621ea34ae`;
- log do `ui-audit`:
  `c9955ce12f4a9f29ca2552dc17523d1daa066f4c333f5171e89b7d3f4debf276`;
- matriz JSON:
  `fb827016cd3c5d917b8efb57a2ffe077be3b27ede989b4e21d58e8ce9f6bb3e4`;
- guard Dart:
  `304fcc29ca3115aad225d3a6697db6570b31c5182061a8998226f274deb47af4`.

### Prova física executada e bloqueio restante

O Samsung SM-A135M Android 14 conectado recebeu o APK release recém-gerado de
`com.mtgia.mtg_app`. O artefato instalado preservou a assinatura esperada e tem
SHA-256
`e7eb297b4e64a6ae792c9e05d66b77038462452571ccfb276b5ea8f74f3ceda1`.
O build exigiu completar o checksum do POM
`com.google.guava:guava-parent:33.5.0-android`; o arquivo cacheado foi comparado
byte a byte com Maven Central antes de registrar SHA-256
`bd77cc2dad91912f1a3bffa7bf7e576ecf57992f58f9afa132fd61ef250baadf`
no metadata de verificação do Gradle.

O tutorial inicial do TalkBack foi concluído; a permissão inesperada para
telefonia foi explicitamente negada. O leitor abriu o ManaLoom, mostrou foco
azul real no logo e manteve a tela de Login operável. A opção temporária
`Mostrar saída de voz` também foi ativada e depois restaurada. Injeções ADB de
gesto/teclado não equivaleram a toque humano para avançar de forma confiável
por todos os campos, portanto essa parte não recebeu crédito manual falso.

O DOM Web revelou e permitiu remover uma tentativa incorreta de wrapper
`Semantics` que duplicava Email/Senha. A implementação final usa os rótulos
nativos de `TextFormField`; o browser expõe exatamente um textbox `Email` e um
`Senha`, e o teste de widget confirma `isTextField`/`isObscured`.

Ao final, TalkBack e `Mostrar saída de voz` foram desligados e as leituras
seguras confirmaram:

```text
accessibility_enabled=0
enabled_accessibility_services=null
```

Há simuladores iOS disponíveis, mas todos os iPhones físicos aparecem offline
em `xcrun xctrace list devices`. A condição verificável para desbloquear S3-04
é: um operador executar o roteiro de toque no Samsung e conectar/desbloquear
um iPhone físico para o roteiro VoiceOver. Simulador não foi promovido a prova
física.

### Ambiente e dados

- nenhuma API remota, EasyPanel, SSH, credencial ou banco foi utilizado nesta
  prova física;
- nenhum dado de produto foi criado/alterado;
- TalkBack foi encerrado e sua configuração temporária foi restaurada;
- nenhum servidor/listener local foi iniciado;
- logs/capturas temporários permanecem somente em `/tmp`;
- nenhum commit, push ou deploy foi executado.

## S3-05 — teclado e foco Web

**Decisão:** `PASS`
**Execução final:** `2026-07-22T03:21Z`

A matriz estruturada
`app/test/ui/fixtures/ui_keyboard_focus_matrix.json` liga cada interação do
aceite a uma prova executável. Os testes usam `LoginScreen`,
`ShellAppBarActions`, o dialog real de descrição de deck e o tema real; não
usam uma maquete visual paralela.

### Provas automatizadas

- Tab e Shift+Tab percorrem Email e Senha em ordem e no sentido inverso;
- Enter e Space acionam, respectivamente, Mensagens e Notificações no shell;
- o dialog pede foco no campo, mantém seis avanços de Tab dentro do modal,
  fecha com Escape e devolve foco ao launcher;
- browser back fecha o modal e também devolve foco;
- o tema possui cor de foco não transparente e borda Brass explícita;
- reduced motion elimina a animação de entrada da Home.

```text
flutter 3.44.6 test --no-pub \
  test/ui/ui_keyboard_focus_matrix_test.dart \
  test/features/home/home_screen_test.dart \
  test/features/profile/profile_screen_test.dart \
  test/features/auth/screens/auth_screens_test.dart
  25/25 PASS
  exit 0

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh ui-audit
  analyzer: No issues found
  testes: 35/35 PASS
  exit 0
```

Hashes:

- log dos 25 testes focados:
  `877452b0f5a08d7c3ef9635a12ab9acf48da30530a45b4b0e1a6abbaa7ccba9f`;
- log do `ui-audit`:
  `c9955ce12f4a9f29ca2552dc17523d1daa066f4c333f5171e89b7d3f4debf276`;
- matriz JSON:
  `f86d7b76ae5ecbaeccfae4d0cf1a8aa38a0fde17ead234d31765ac4cbc891967`;
- guard Dart:
  `e21aa676a19da00c1e23f8a62277cd8ee6760698c96490658a98fe2a696aee82`.

### Roteiro no build Web real

Foi produzido um build release com `--base-href /app/` e
`API_BASE_URL=http://127.0.0.1:8088/api`, servido pelo helper loopback que
valida TLS e encaminha apenas `/api` ao upstream HTTPS. O bundle final tem
SHA-256
`b3dcdfb74c8aefa60672b9cddc1659552c546b94abf610059cda1ecaf0a24def`.

O roteiro público anterior foi repetido e o trecho autenticado usou uma conta
descartável `@example.invalid`, criada pela própria UI com aceite legal. Foram
confirmados:

1. foco visual no Logo, Email, Senha, mostrar senha e Recuperar senha;
2. Tab avançando Email → Senha → mostrar senha → Recuperar senha;
3. Shift+Tab retornando de mostrar senha para Senha;
4. Enter e Space abrindo Recuperar senha;
5. botão Voltar do navegador restaurando Login;
6. rotas autenticadas Home, Decks, Collection, Community, Profile e
   Battle/Replays, incluindo criação de um deck descartável;
7. trap de foco dentro do modal de segurança e do modal real de criação de
   deck;
8. `Escape` fechando o modal e foco Brass restaurado em `Excluir minha conta`
   e `Criar novo deck`;
9. `prefers-reduced-motion: reduce` emulado via CDP, Home totalmente visível na
   primeira captura, seguido de restauração para `false`;
10. exatamente um textbox `Email` e um `Senha` no DOM acessível final;
11. zero entradas `warn/error` em 311 logs de browser revisados.

O primeiro teste manual encontrou que os diálogos de segurança com
`barrierDismissible: false` ignoravam Escape. Eles agora mantêm o bloqueio de
clique externo, mas usam `CallbackShortcuts` para fechar com Escape. O teste de
widget e o browser real comprovaram o fechamento e a restauração de foco.

### Ambiente e dados

- execução final do browser: `2026-07-22T03:21Z`, build Flutter 3.44.6;
- o backend público foi acessado somente pelo proxy loopback HTTPS validado;
- uma conta e um deck de QA descartáveis foram criados; a conta foi excluída
  pelo próprio fluxo do app e o retorno a `/login` exibiu
  `Conta excluída e dados pessoais removidos.`;
- nenhuma credencial pessoal, EasyPanel, SSH ou acesso direto ao banco foi
  utilizado;
- a emulação de reduced motion foi restaurada e a sessão descartável foi
  removida;
- nenhum commit, push ou deploy foi executado.

## S3-06 — navegação, deep links e retomada

**Decisão:** `PASS` local
**Execução final:** `2026-07-22T04:28Z`

A navegação Web passou a ter URLs canônicas e retomada determinística. A matriz
executável registra 38 `GoRoute`, seis `MaterialPageRoute` e 214 superfícies no
inventário atual. A redução em relação ao inventário histórico de S3-01 decorre
da conversão de navegações imperativas para rotas declarativas; não representa
perda de superfície de produto.

### Implementação fechada

- tabs da Collection sincronizam nos dois sentidos com `?tab=`, limitam valores
  inválidos e reagem a back/forward do navegador;
- `GoRouter.optionURLReflectsImperativeAPIs` mantém a URL visível coerente
  também quando o fluxo usa `push` imperativo;
- Battle/Replays usa `/decks/:id/battle-replays`, inclusive em reload direto;
- Card Detail usa `/cards/:cardId`; o app busca o identificador local exato no
  backend canônico PostgreSQL e nunca usa Scryfall como source of truth;
- o backend aceita `GET /cards?id=<uuid>` e o provider rejeita resposta cujo
  identificador não corresponda exatamente ao solicitado;
- Card Detail tem estado seguro de indisponibilidade quando o contrato ainda
  não existe no backend publicado;
- expiração de sessão centraliza 401/403 de autenticação, deduplica eventos,
  remove credenciais locais e redireciona para Login; erros de senha inválida
  não são confundidos com sessão expirada;
- Generate e Import preservam rascunhos por usuário em armazenamento local,
  restauram após reload e removem o rascunho somente no sucesso;
- logout limpa a mensagem transitória anterior, evitando erro de segurança
  obsoleto na tela de Login.

### Provas automatizadas e gates

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh full
  backend: 1618/1618 PASS
  app: 1056 PASS, 1 skip explicitamente inventariado
  web pública: eslint PASS e next build PASS
  exit 0

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh ui-audit
  analyzer: No issues found
  testes: 38/38 PASS
  exit 0

MANALOOM_DART_BIN=<dart-3.12.2> ./scripts/manaloom_project_logic.sh --write
  oito artefatos gerados
  exit 0

MANALOOM_DART_BIN=<dart-3.12.2> ./scripts/manaloom_project_logic.sh --check
  oito artefatos sincronizados
  exit 0

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh project-logic
  gerador: 9/9 PASS
  dart doc: app, server, manaloom_lints e project_logic sem warnings/erros
  exit 0

git diff --check
  exit 0
```

Hashes:

- gate `full`:
  `6f6a052112505c29c3eccebbf082acf48b9c8ebbab027bae699eb4c8b677ca2f`;
- `ui-audit`:
  `13f231430094d7064d60e3e7353ffc1fe8560826adeb81c3f183fb3cde0ed167`;
- gate `project-logic`:
  `2975e843ef552cb5720474357c89cf5b6204d668aa2b3f647346842aa53b6e24`;
- matriz de navegação:
  `4a8a847aa99e024c6dde1981834fbd3efe49d5d68778413db4567813dc320d89`;
- guard da matriz:
  `0a55afe27bffb431f9fd8edb78c4b619282890fa12c36727e30e058b4b39146d`;
- manifesto de lógica:
  `a89e10f985bad49a29c6a91ac58f4683e7dcaa0d9c815d2fb13a83d7758646e1`.

### Browser real e cleanup

O build release servido em loopback tem `main.dart.js` SHA-256
`66fdbfcd6b229ea9e4b1dcf554b627afe1bd2fff06d2215dfc9de82f827ed5c3`.
No browser foram exercitados tab inválida, troca de tab, back/forward, reload
de Generate/Import com rascunho, Battle/Replays direto, URL de set e Card
Detail direto. A execução final abriu Login sem erro obsoleto e teve zero
`warn/error` em 13 logs novos do console.

Uma conta e um deck descartáveis foram criados pelo app, usados somente no
roteiro e removidos pelo próprio fluxo. Nenhuma credencial pessoal, SSH,
EasyPanel, acesso direto ao banco, commit, push ou deploy foi utilizado. O
servidor Web loopback permanece ligado porque foi solicitado para teste do
usuário.

### Verificações retidas para pós-deploy

O backend público observado ainda não contém esta revisão: responde 404 em
`/auth/revoke-sessions` e não entrega o novo filtro exato `GET /cards?id=`.
Por isso, a matriz manual fica `partial` para duas provas de ambiente, sem
rebaixar o aceite local já coberto por contrato/teste:

1. reload de Card Detail com dados reais após publicação do backend;
2. interceptação de uma resposta 401 real pelo runtime publicado.

Esses itens são verificação de convergência pós-deploy, não autorização para
publicar. Nenhum deploy foi executado nesta sprint.

## S3-07 — regressão visual autenticada

**Decisão:** `PASS` local
**Execução:** `2026-07-22T05:16Z` até `2026-07-22T06:00Z`

A task criou um fixture PostgreSQL/API/Web inteiramente loopback e descartável,
sem coordenada de produção. Usuário, card, deck e set representativo foram
seedados antes da captura; o fluxo visual não contém cadastro. O card usa uma
imagem same-origin do bundle real e o modo explícito
`MANALOOM_VISUAL_FIXTURE_MODE=true` estabiliza apenas os textos relativos a
tempo.

### Matriz e aprovação visual

Foram capturados os mesmos 20 checkpoints em quatro plataformas:

| Plataforma | Runner/dimensão | Resultado |
|---|---|---:|
| Web mobile | build release real, 390×844 | 20/20 aprovadas |
| Web desktop | build release real, 1440×900 | 20/20 aprovadas |
| Web wide | build release real, 1920×1080 | 20/20 aprovadas |
| Android físico | Samsung SM-A135M, Android 14, profile, 1080×2408 | 20/20 aprovadas |

Os checkpoints cobrem Login, Home, Decks, modal real de criação, Deck Detail
acima/abaixo da dobra, Generate, Import com lista detectada, Collection, catálogo
com imagem representativa, Card Detail sucesso/erro, Community, Profile,
Battle/Replays, Plans, Upgrade, Checkout e Legal. A revisão dos quatro painéis
e das imagens críticas não encontrou overflow, corte de conteúdo obrigatório,
modal substituído por menu, card estourado ou erro técnico visível.

O `flutter drive` rejeita `--release` em plataforma não Web. Por isso, a prova
física é declarada honestamente como `--profile`, com `kDebugMode=false`; a
execução terminou `All tests passed`, 2/2, e deixou zero `adb reverse`.

### Baseline, diff e console

Os 80 PNGs aprovados foram promovidos a
`app/test/ui/goldens/runtime/{web_mobile,web_desktop,web_wide,android_physical}`.
O comparador novo valida conjunto exato, dimensões e pixels e produz artefatos
de falha quando necessário.

```text
authenticated_visual_diff.dart
  total_files: 80
  passed_files: 80
  failed_files: 0
  maximum_observed_changed_pixel_ratio: 0.0
  threshold: 0.001

browser Web autenticado
  console entries observadas: 100
  warning/error: 0
```

Hashes:

- bundle Web `main.dart.js`:
  `160c5cae6ccb046c1df87509c1805a3ee127d17d8b9b834330585db841ba2d3d`;
- manifesto das 80 capturas:
  `d84119af03c9ee5ba16d921f228c01e1a17e0877a86437640d007f52f5a63100`;
- teste focado final 18/18:
  `6dc25084369eebc8ea9ca181afe33090d61039d9283574d0ea27ba5b60349506`.

### Gate completo e dependência vulnerável

A primeira repetição do gate `full` após a aprovação visual não foi aceita:
backend e Flutter passaram, mas `npm audit` bloqueou o site público por duas
ocorrências de severidade alta em `sharp <0.35.0`. O override transitivo foi
fixado em `sharp 0.35.3`, sem alterar o Next `15.5.19`, e o lockfile foi
regenerado de forma determinística.

A validação isolada da correção terminou com instalação limpa, lint e build de
produção aprovados, `npm ls` resolvendo `sharp@0.35.3` e auditoria com zero
vulnerabilidades. Hash do log dessa validação:
`f396d43956d3755dc2981d2010e6bbf480c35fb0236fbfd3043c1a7777e2f697`.

O log da execução recusada foi preservado, sem ser apresentado como PASS, com
hash `0b1ec903e9a3385e00e02aca75e2d362af35db4bc9edfd9cc2c460ec42723d49`.

Depois da sincronização do manifesto, o gate integral foi repetido do início e
aprovou backend `1618/1618`, Flutter `1067/1067` com um skip explicitamente
declarado, lint/build/smoke do site público e `npm audit` com zero
vulnerabilidades. Hash do log completo aprovado:
`c722e3c6db13f414e15376794939e2f7891959edecfc97733e68b706732b3208`.

### Cleanup e correção do processo filho

Ao encerrar, o sumário do trap registrou banco restante `0`, Web listener `0`
e credencial removida. Ele amostrou o listener da API como `1` enquanto o
processo Dart terminava; a verificação independente imediatamente posterior
confirmou API `0`, Web `0`, arquivo de credencial ausente e preservou somente o
listener do usuário em `8088`.

A causa era o servidor compilado iniciado dentro de subshell sem `exec`; o
wrapper podia terminar antes do processo Dart filho. O entrypoint foi corrigido
para `exec dart build/bin/server.dart` e um guard passou a exigir essa
propriedade. Nenhum banco, identidade, listener ou credencial da fixture ficou
ativo.

Nenhuma credencial pessoal, EasyPanel, SSH, commit, push ou deploy foi usado.
Warnings de migração do Flutter Secure Storage e mensagens `gralloc4` do
aparelho foram registrados como limitações do ambiente; não houve assertion,
falha do app ou screenshot ausente.

## S3-08 — onboarding, primeiro uso e retomada

**Decisão:** `PASS` local
**Execução:** `2026-07-22T06:04Z` até `2026-07-22T07:58Z`

O onboarding deixou de ser uma rota visitável sem estado e passou a ter uma
decisão persistida por usuário. O estado versionado distingue `pending`,
`completed` e `skipped`, preserva o formato selecionado e trata payload ausente,
malformado ou de versão futura como pendente seguro. Falha de armazenamento não
é confundida com conclusão: a tela mantém o usuário no fluxo, expõe aviso com
região viva e oferece retry.

Login, cadastro, inicialização de sessão e verificação de e-mail agora resolvem
o destino autenticado pela mesma regra: deep link explícito e seguro tem
prioridade; sem deep link, usuário pendente abre onboarding e usuário concluído
ou que pulou abre Home. Logout limpa somente a decisão em memória; o estado por
usuário permanece e foi comprovado após novo login.

### Cobertura funcional e acessível

- retomada offline do formato escolhido após reconstrução completa do app;
- persistência obrigatória antes de avançar, concluir ou pular;
- bloqueio e retry quando a gravação falha;
- texto 200% em 320×568 sem overflow e aviso de persistência legível;
- dropdown expandido, elipse controlada, alvos mínimos de 48 px e foco por
  teclado;
- telemetria `trackOnce` coalescida em concorrência, com receipt persistente
  gravado somente após resposta 2xx e chave de idempotência;
- backend aceitando `onboarding_skipped` no contrato canônico.

O `ui-audit` passou a executar explicitamente
`test/features/home/onboarding_core_flow_screen_test.dart`, impedindo que o
fluxo saia do gate visual por estar fora de `test/ui`.

### Provas automatizadas

```text
testes focados de onboarding/redirect/analytics
  22/22 PASS
  log SHA-256: 12fc0cbe60a4fff0b87222b399d9c9228588b999ea2f3b77eebb3bc52f87ea00

regressão de autenticação
  31/31 PASS
  log SHA-256: e8e8d432f58bedef3518cf1eb40fc4968ccd63e9bd452acf99c01b1ddf9ca620

contrato server de activation events
  2/2 PASS
  log SHA-256: 92ea77c2c7b666438c5a5458f8bb40af604fc383f34f991bb0d276999a824b97

flutter analyze
  No issues found
  log SHA-256: fc098f9fe4150632e2c33ed4fe222f1b89de43e962694ca95fe449744fcaf5b7
```

### E2E físico e incidente de toolchain

O cenário `onboarding_first_run_runtime_test.dart` executou o app real contra
API/PostgreSQL descartáveis no Samsung SM-A135M, Android 14, em `--profile` e
com a toolchain aprovada Flutter 3.44.6/Dart 3.12.2. Ele comprovou login UI,
primeira entrada no onboarding, escolha de Modern, retomada após reconstrução,
skip persistido, Home, logout, novo login e ausência de repetição do onboarding.

```text
Android físico Flutter 3.44.6
  All tests passed
  log SHA-256: d5c240df7b2301f24864408ba383bfbd4a51921583fcaa33d8741284e676c232

fixture backend isolada
  log SHA-256: e8bddde8f2dc3e4dce823c2e7c00bb212ba65030b27fb6b2d583a93c580a53ab
```

Uma tentativa inicial com o `flutter` global 3.41.6 expôs mistura de engine
nativa e embedding causada pelo lock do projeto estar corretamente pinado para
3.44.6. Essa execução foi recusada. O lock aprovado foi preservado e a prova
válida foi repetida do zero com o SDK pinado. O driver físico também exigiu
preenchimento determinístico dos controllers: teclado/foco reais permanecem
cobertos pela matriz S3-05 e pelo teste widget de onboarding, enquanto este E2E
mede persistência, API e roteamento sem depender do IME Samsung.

O runner Web release chegou a executar, mas não produziu diagnóstico utilizável;
o modo debug ficou bloqueado no DWDS. Essas tentativas não foram apresentadas
como PASS. Responsividade, teclado, texto 200% e deep link Web são cobertos pelas
matrizes S3-03, S3-05 e S3-06, e o aceite E2E desta task é a prova física acima.

### Gates finais e regressão encontrada

O primeiro `quality_gate.sh full` encontrou uma regressão apenas no harness
legado `deck_runtime_widget_flow_test.dart`: depois da verificação de e-mail, o
cenário continuava supondo que um cadastro novo abriria diretamente a lista de
decks. O produto agora direciona corretamente novos usuários ao onboarding. O
harness foi tornado explícito como cenário de usuário estabelecido, sem alterar
o roteamento de produção nem retirar a cobertura first-run. O teste isolado
`register -> generate -> save -> details -> optimize -> apply -> validate`
voltou a passar ponta a ponta.

Uma repetição posterior foi recusada por mistura local de SDK: o executável era
Flutter 3.44.6, mas `.dart_tool/package_config.json` ainda referenciava o
`flutter_test` global. `flutter pub get` foi executado com o SDK pinado e a prova
final partiu de metadados coerentes. Os dois runs rejeitados permanecem
rastreáveis pelos hashes `5050bdbb3c0ce13ebf49c6d114d3a3c7d261e94d498f081be54abd943130e08e`
e `2b99cd310a063ac3cca8bbf1943f97299c4a91404f32f4cf9592a9f2f7daed9b`;
nenhum deles é contabilizado como PASS.

```text
MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh ui-audit
  analyzer: No issues found
  testes: 48/48 PASS
  exit 0
  log SHA-256: 3418c752b4171c148780383da59f7692301b80d76989228bdff5906093a3b14f

MANALOOM_FLUTTER_BIN=<flutter-3.44.6> ./scripts/quality_gate.sh full
  backend: 1618/1618 PASS
  app: 1084 PASS, 1 skip explícito
  web pública: eslint PASS, next build PASS, npm audit 0, smoke HTTP PASS
  exit 0
  log SHA-256: a07e8c82d69c5c6a5eaff62e71c8e1e02699da27287f2c6f92b3b0214701608b

./scripts/manaloom_project_logic.sh --write
./scripts/manaloom_project_logic.sh --check
  8 artefatos sincronizados
  check log SHA-256: 1e9e7ff40ce1a16e235e87d19bdda59692c54f91f3140fa1cbd85b75201de320
```

### Cleanup

Após a prova válida: banco descartável ausente, listeners API/ChromeDriver zero,
`adb reverse` zero e nenhuma credencial gravada no repositório. O servidor Web
do usuário continuou como único listener em `127.0.0.1:8088`. Nenhum EasyPanel,
SSH, commit, push ou deploy foi utilizado.

## Próxima task

S3-08 está fechada localmente. S3-04 continua bloqueada apenas pelas duas ações
físicas descritas acima, e as duas provas pós-deploy de S3-06 permanecem
vinculadas ao gate de release. A sequência de produto passa para S4-01.
