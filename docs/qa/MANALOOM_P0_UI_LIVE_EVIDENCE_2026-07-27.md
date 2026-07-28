# ManaLoom — prova viva P0 Web + Android

**Data:** 2026-07-27

**Branch:** `codex/free-beta-release-candidate-2026-07-17`

**Toolchain:** Flutter `3.44.6`, Dart `3.12.2`

**Digest visual:** `b5af4634e18cda489b0b8d07d7246e6975e7c04d27f4c2643e18acfd5a8fd082`
**Decisão:** `PASS` para S3-05 e S3-07; TalkBack humano continua pendente em S3-04

## Escopo realmente comprovado

A matriz executável possui 53 checkpoints de telas/estados P0. Ela cobre as
rotas públicas e autenticadas correntes e seus estados representativos:
autenticação, cadastro e consentimento, Termos, Privacidade, onboarding, Home,
decks, coleção, cartas e sets, Community e usuários, perfil, Life Counter,
Battle/Replays/Coach/Live disabled, pós-jogo, mensagens, notificações e trades.
Success, empty, error, modal, disabled e conteúdo acima/abaixo da dobra são
declarados no fixture; não foram inferidos de uma única tela feliz.

Foram produzidas e abertas as seguintes capturas:

| Manifesto/perfil | Runtime | Capturas | Dimensão |
|---|---|---:|---:|
| Web mobile | build release real | 53 | viewport 390×844; raster 500×844 |
| Web desktop | build release real | 52 | 1440×900 |
| Web wide | build release real | 52 | 1920×1080 |
| Android físico | profile, `kDebugMode=false` | 53 | 1080×2408; Life Counter 2408×1080 |
| Battle Coach Android | integration test físico | 7 | 1080×2408 |
| Battle Coach teclado Web | build release + teclado físico | 9 | 748×907 |
| **Total revisado** |  | **226** |  |

As 210 imagens da matriz foram divididas em 20 contact sheets e inspecionadas
em resolução útil, além das folhas dedicadas ao Battle Coach Android e teclado
Web. A revisão verificou hierarquia, identidade MTG, contraste, tipografia,
espaçamento, adaptação, clareza de ação, estados, acessibilidade visual e
atratividade. Não restou finding visual bloqueante.

O inventário estrutural continua maior que esta matriz porque também contém
dialogs, sheets, menus, transient states e redirects. A prova acima é o
conjunto de telas/estados P0 definido pelo contrato executável; não apresenta
cada ocorrência transitória do inventário como se fosse uma rota autônoma.

## Falhas encontradas e correções

1. **Cadastro e consentimento legal:** os links de Termos e Privacidade
   quebravam em linhas desconectadas, com hierarquia e alvo de foco fracos.
   O bloco foi refeito com composição responsiva, checkbox material, links
   reais para a seção correta, versões legíveis, ordem de foco, autofill,
   submissão pelo teclado e scroll/foco no erro de consentimento.
2. **Termos e Privacidade:** a página única longa não deixava claro qual
   documento estava sendo lido. A rota agora aceita `?section=terms|privacy`,
   oferece navegação explícita e apresenta os documentos em seções legíveis
   com título, vigência e hierarquia consistente.
3. **Battle/Replays:** Enter no resultado filtrado do seletor de oponente não
   completava a seleção/preflight. O fluxo ganhou ativação determinística e
   teste de regressão.
4. **Community:** a normalização da tab da rota pai expulsava rotas filhas de
   busca, perfil e deck público de volta para Explore. A canonização agora só
   ocorre em `/community`.
5. **Mensagens/notificações:** entradas diretas podiam não oferecer retorno
   explícito. As duas telas receberam ação Voltar com fallback canônico.
6. **Chat indisponível:** o composer continuava parecendo utilizável quando a
   conversa falhava. Campo e envio agora ficam desabilitados com texto e
   contraste coerentes.
7. **Perfil:** o FAB de salvar podia cobrir conteúdo. A ação foi movida para
   uma barra inferior responsiva, full-width no compacto e limitada no
   desktop.
8. **Life Counter:** ao sair do modo de apresentação, alguns aparelhos
   preservavam a última rotação landscape. A saída fixa portrait primeiro,
   aguarda a convergência e só então restaura a lista completa de orientações.
9. **Imagens Web locais:** o servidor de prova passou a servir assets locais e
   o fixture usa URL same-origin, eliminando a dependência de CDN/CORS na
   regressão visual.
10. **Harness Android:** o splash de uma tentativa inicial exibia o banner
    DEBUG do `MaterialApp` do próprio harness; ele foi removido e a captura foi
    repetida.

## Life Counter e platform view

O screenshot da surface Flutter não compõe uma WebView Android e produziu uma
imagem preta. Uma segunda tentativa com conversão da surface capturou um frame
de transição distorcido. Nenhuma das duas foi aceita.

A prova válida executou o Life Counter real sem conversão da surface, aguardou
o marcador `LOTUS_RUNTIME_READY` e capturou o compositor do Samsung via
`adb screencap`. O PNG final:

- possui 2408×1080 em landscape;
- contém 13.708 cores e 536.866 bytes;
- mostra a mesa de quatro jogadores sem overflow;
- passou alvo/semântica automatizados;
- comprovou persistência 40 → 41 após reabrir;
- mediu p95 de update de estado em 8,3 ms, primeiro frame em 42,7 ms e segundo
  frame em 73,6 ms.

O helper `scripts/manaloom_capture_android_platform_view.sh` recusa arquivo que
não seja PNG, captura portrait e arquivo suspeitosamente pequeno.

## Teclado/foco real do Battle Coach Web

O roteiro usou eventos físicos no build release, sem chamar diretamente
callbacks Flutter:

1. estado base com foco em Voltar;
2. Tab para Abrir replays;
3. Tab para Escolher adversário;
4. Shift+Tab de volta a Abrir replays;
5. Tab + Enter abre o dialog e foca a busca;
6. Escape fecha e restaura foco em Escolher adversário;
7. Space reabre e foca a busca;
8. digitação física filtra o rival público;
9. Enter seleciona e executa o preflight real.

O preflight final bloqueia corretamente a simulação porque o motor do fixture
não está configurado; o CTA fica disabled em vez de iniciar uma operação
inválida. O log sanitizado contém 9/9 `PASS`, nenhuma credencial e zero entrada
proibida.

O navegador exportou inicialmente JPEG com extensão `.png`. O indexador
recusou a evidência como inválida. Os nove arquivos foram convertidos para PNG
real, reindexados e abertos novamente; somente esse conjunto entrou no
aggregate.

## Tentativas recusadas

Não contam como aprovação:

- SDK Flutter global `3.41.6` misturado com package config/engine `3.44.6`;
- assertion de Material ausente no primeiro harness do cadastro;
- screenshot Flutter preto da platform view;
- frame Android distorcido após conversão da surface;
- banner DEBUG introduzido pelo harness;
- arquivos JPEG apenas renomeados como PNG.

Cada causa foi eliminada e o cenário inteiro relevante foi repetido com a
toolchain pinada.

## Dados, segurança e cleanup

Usuários, peer, deck, card e set pertencem exclusivamente a
PostgreSQL/API loopback descartáveis. As imagens da fixture são same-origin.
Nenhuma coordenada de produção, EasyPanel, SSH, identidade pessoal ou mutation
live foi usada. Credenciais efêmeras não entram nos manifestos nem nos logs
versionados. Ao final, banco, listeners temporários, `adb reverse` e arquivo de
credenciais devem convergir a zero; essa condição é verificada no fechamento
do gate.

## Evidência versionada

- aggregate revisado: `docs/qa/ui-live/latest.json`;
- P0: `docs/qa/ui-live/current/p0-matrix`;
- Battle Coach Android:
  `docs/qa/ui-live/current/battle-coach-android`;
- Battle Coach Web:
  `docs/qa/ui-live/current/battle-coach-web-keyboard`;
- baselines: `app/test/ui/goldens/runtime`;
- matriz: `app/test/ui/fixtures/ui_authenticated_visual_matrix.json`;
- teclado: `app/test/ui/fixtures/ui_keyboard_focus_matrix.json`.

O aggregate foi verificado com 226 screenshots e os três níveis:
`PASS_AUTOMATED`, `PASS_RUNTIME` e `PASS_VISUAL_REVIEWED`.

## Pendência honesta

S3-04 continua `BLOCKED` somente pelo roteiro humano TalkBack no Samsung alvo.
A revisão de imagem e os testes de semantics não substituem uma pessoa
navegando com o leitor ligado. VoiceOver/iOS permanece
`DEFERRED_BY_SCOPE` para a beta Web + Android e não é apresentado como
executado.

## Validação final

A recertificação fechou com:

- 80/80 testes focados dos fluxos alterados;
- `flutter analyze` sem issues;
- 51/51 checks do gate `ui-audit`;
- 226/226 screenshots aceitos pelo gate `ui-proof`;
- 9/9 passos físicos de teclado/foco do Battle Coach Web;
- 9/9 cenários Patrol;
- 1.896 testes backend aprovados;
- 1.289 testes Flutter aprovados e 1 skip Web preexistente/documentado;
- schema descartável aprovado com 79 tabelas, 6 views, 98 FKs e 56 migrations;
- build Web release e smoke test em `/app/` aprovados;
- resolução Gradle profile/release offline aprovada;
- auditoria npm com 0 vulnerabilidades;
- CI local `quick` e `full` aprovadas.

Hashes dos logs de fechamento:

- analyzer:
  `b38e6871959976908d50ccfee1128576c6452e42f7eca5baa7b59e945393b1a4`;
- UI audit:
  `0c047ee82f24c228605ebe090090deced8d682c08715f957a9488c15bf1ba8a4`;
- UI proof:
  `b34ecf148ea2cf074c1d408c1d780723223203827011c587564b7e8df8bb4fbf`;
- project logic check:
  `1e9e7ff40ce1a16e235e87d19bdda59692c54f91f3140fa1cbd85b75201de320`;
- project logic gate:
  `98d60b1206e36dbdb1183e0a64bfb5de42338cb99f4ef5cbe60c5a4c1ab1d8a2`;
- Gradle profile:
  `ada9d304c8e3e06a2f717f79dcd89ba1519006bede0a51ce0632ee1f96a541f2`;
- Gradle release:
  `9d4cca16cecf53ee39ded8317309844fafc97618676a5b94ca4fac2213a161bf`;
- build Web:
  `bbcfef0161ede865e902bd60268a80b08688ea8139a2a2f0ec30cbca245d7ac7`;
- CI local quick:
  `d5b8270c3022d83169bd6b62753244c24a0ab43973e9746c26ae4bc2374646a0`;
- CI local full:
  `02139f0f903a8c8247e7257f7014efece57578c48635b1e0c8a8101776084c7f`.

O bundle Web validado tem SHA-256
`e31abae7f8d94435f0d40e34911f1633f6a03989acde6f222224a8b0d2039fc4`.
O digest definitivo das fontes da UI é
`b5af4634e18cda489b0b8d07d7246e6975e7c04d27f4c2643e18acfd5a8fd082`.
