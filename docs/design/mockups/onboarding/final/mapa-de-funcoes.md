# Mapa de funções — onde cada item do inventário foi parar

**Tela:** Onboarding "Seu primeiro passo" · versão final (3ª passada)
**Desenho:** `docs/design/mockups/onboarding/final/index.html` — um arquivo, 17 estados por `location.hash`
**Inventário de origem:** `docs/design/mockups/onboarding/inventario.md`
**Régua:** `docs/design/life-counter-prototype` · **Kit:** `docs/design/ui-kit/kit.css` (congelado, usado como está)

> Regra dura do inventário: **nenhuma função se perde**. As linhas marcadas com ⚠ mudaram de forma ou
> de texto de propósito — as de copy precisam do martelo do dono antes de virar código.
> Conferido id por id contra o HTML final: cada linha abaixo cita o `data-key` ou o `#estado` onde a
> função aparece **na tela** (não em `aria-label`).

---

## 0 · O mapa de significado, como esta tela o aplica

| linguagem | significa | onde aparece aqui |
|---|---|---|
| vidro escuro | ação neutra, ainda não vale nada | azulejo de objetivo não escolhido, peça de modo não escolhida, peça-formato |
| **cor cheia (vitral) + aro de marfim** | **está valendo agora** — a escolha feita | objetivo aceso (roxo `plano`), momento aceso (verde `musgo`), modo aceso (índigo `noite`), cena da batida 3, azulejos do resumo |
| **latão cheio** | **a jogada principal** — um por tela | só o herói do pé (`.bt-hero`) e, no nível 2, o azulejão "Commander" |
| tracejado em latão | vazio, sem dono | faixa de ação sem objetivo (`#vazio`), tabuleiro de `#negado`, os três lugares de "Criar do zero", o lugar livre do fichário, os passos ainda não alcançados da trilha (desktop) |
| brasa cheia | estado ruim que está valendo agora (`.rt.bad.on` de vt-05) | a tira de persistência e o herói de `#erro` |

O aro de **marfim** para "escolhido" (em vez de latão) é o `.swatches button[aria-pressed="true"]` de
`vt-05-jogador.png`: numa fileira de cores quem marca a escolha é o marfim. Isso mantém **um único
latão por tela** — o herói — e resolve a duplicação "peça de latão + herói de latão com as mesmas
palavras". O aro é **inset**, então a peça acesa ocupa a mesma caixa das vizinhas e a fileira não
desalinha.

**Nenhum subtítulo cinza explicativo.** Descrição virou caixa alta dentro da própria peça (`.ob-sub`);
confirmação virou linha de tinta escura dentro do herói (`.ob-heroi__conf`) ou linha de tinta clara
dentro da peça acesa (`.ob-conf`). As frases longas do inventário aparecem por inteiro a partir de
1024px (`.ob-longa`), onde há largura para elas.

---

## Os 17 estados desenhados

| hash | batida | o que prova | herói do pé |
|---|---|---|---|
| `#vazio` | 1 | primeira execução, cinco objetivos (ON-33, ON-01, ON-68) | faixa **tracejada** "Escolha um objetivo" (ON-34/ON-66) |
| `#quatro` | 1 | ON-49: `improveDeck` cai por capability, restam quatro | idem |
| `#aviso` | 1 | ON-26: a escolha vale, a gravação falhou | — (tira de brasa) |
| `#leitura` | 1 | ON-23: não deu para ler o progresso | — (tira de brasa) |
| `#sessao` | 1 | ON-24: sessão sem usuário, tabuleiro inerte | "Entrar novamente" ⚠ ação nova |
| `#carregando` | 1 | ON-22 (filete de leitura) + ON-25 (aviso de armazenamento) | — |
| `#negado` | 1 | ON-35 + ON-29: tabuleiro **sem dono** + ON-28 na tira | "Pular por enquanto" (ON-75/ON-07) |
| `#retomado` | 2 | ON-31 + ON-02 (três momentos) + ON-70 | "Gerar uma base para revisar" |
| `#preenchido` | 3 | ON-04: a rima **0 · 99** | "Gerar uma base para revisar" |
| `#semia` | 3 | ON-36/ON-51: IA negada, só "Criar do zero" | "Criar deck do zero" |
| `#lista` | 3 | caminho `importDeck` | "Revisar minha lista" |
| `#colecao` | 3 | caminho `catalogCollection` | "Importar minha coleção" |
| `#jogar` | 3 | caminho `play` + ON-85 (a Home prepara a mesa) | "Continuar para a mesa" |
| `#ajuste` | 3 | ON-32/ON-37/ON-84: reentrada com onboarding resolvido | "Escolher deck para melhorar" |
| `#salvando` | 3 | ON-30: gravando o plano (distinto de ON-22) | rosca + "Salvando seu plano…" |
| `#erro` | 3 | ON-27: navegação cancelada | herói em **brasa** "Tentar novamente" |
| `#formato` | nível 2 | ON-03/ON-05/ON-77/ON-81: os sete formatos | — (o próprio Commander é o herói) |

---

## 1 · Escolhas

| id | onde foi parar |
|---|---|
| ON-01 | Batida 1 (`#vazio`, `#quatro`, `#aviso`, `#leitura`, `#sessao`, `#carregando`): cinco `.bt-tile` com miniatura real — leque de artes, prévia de lista com quantidades, fichário com um lugar tracejado, mesa com as cores dos assentos, oficina com chevrons de subida. `data-key="onboarding-goal-<nome>"` preservado, ordem de `_goalOrder` preservada. Seleção única (`aria-pressed`), sem "desmarcar". O escolhido acende em **vitral roxo com aro de marfim** (`#aviso`, `#ajuste`). |
| ON-02 | Batida 2 (`#retomado`): três `.bt-piece` com arte real; o escolhido em **vitral verde com aro de marfim**. `data-key="onboarding-experience-<nome>"`. A palavra de estado dentro da peça diz o que a escolha muda ("Mais explicação" / "O que mudou" / "Direto ao ponto") ⚠ copy nova. |
| ON-03 | Nível 2 (`#formato`), aberto pelo azulejo aceso "100 · Commander" do resumo. Commander é o azulejão de latão com numeral **100**; os outros seis são peças-forma com glifo próprio **e a própria linha de valor** ("Só os últimos blocos", "De 2003 para cá", …) ⚠ copy nova. O dropdown morreu. |
| ON-04 | Batida 3 (`#preenchido`): "Criar do zero" = três lugares **tracejados** e numeral **0**; "Gerar uma base" = três **artes reais** e numeral **99**, acesa em vitral índigo. `data-key="onboarding-build-manual"` / `-guided`. |

## 2 · Campos de entrada

| id | onde foi parar |
|---|---|
| ON-05 | Não existe mais chrome de campo: o formato é objeto. A chave `onboarding-format-dropdown` continua no azulejo do resumo (é a âncora de ON-93). A ajuda de ON-77 virou a linha em caixa alta **dentro** do azulejão de Commander. A validação continua sendo de persistência, não de UI. |

## 3 · Ações

| id | onde foi parar |
|---|---|
| ON-06 | `.bt-hero` no pé (`data-key="onboarding-primary-action"` + a chave legada por caminho). Anatomia: frase de confirmação (ON-67) em tinta escura sobre o latão, nome da jogada em Fraunces e botão redondo com a seta. Rótulos em ON-74. Desenhado nos seis caminhos. |
| ON-07 | O ✕ único `.bt-x` (64px) no alto à direita, peça muda como na régua. Some em `#ajuste` (ON-37). Em `#negado`, onde pular é a única jogada, ele ganha o **herói**: "Seu objetivo continua salvo — nada é apagado." / "Pular por enquanto". |
| ON-08 | `data-key="onboarding-persistence-retry"`: o botão redondo com ↻ dentro da tira de brasa (`#aviso`, `#leitura`, `#sessao`, `#carregando`, `#negado`) e, em `#erro`, o **herói inteiro**. Nunca uma barra larga empilhada sobre um painel de texto. |
| ON-09 | `data-key="onboarding-scroll-view"` continua no palco. A tela **não rola** enquanto a batida cabe; abaixo de 360px de largura ou 660px de altura volta a rolar (ON-94). |
| ON-10 | `shell-messages` / `shell-notifications`, alvo 44×44, `Badge` de não lidas (`3` e `99+` em `#retomado`). **Só a partir de 1024px** — é onde a barra é mesmo a do shell, com o rail ao lado. No celular eles saem: ali eram cromo da Home vazando para dentro do fluxo, e as capturas web mobile atuais também não os têm (o bloco vira `SizedBox.shrink()` sem as capabilities). ⚠ decisão de desenho. |
| ON-11 | ≥1024px: rail `data-key="main-scaffold-rail"` com cinco destinos e **nenhum selecionado**. Mobile: sem barra inferior — a Home aparece desfocada embaixo, mas não é alcançável daqui. |
| ON-81 | A "única superfície flutuante" virou o segundo nível `#formato`, com `.bt-back` no cabeçalho e o mesmo ✕. Fecha por seleção ou pela seta. ⚠ deixou de ser rota de menu do `Navigator`. |
| ON-82 | Ordem de foco = ordem visual dentro de cada batida (DOM na mesma ordem). ⚠ o orçamento de `Tab` travado no teste (12/12/6/8) deixa de valer: cada batida tem poucos alvos. O teste precisa ser reescrito junto com a tela. |
| ON-83 | A trilha 1·2·3 (`onboarding-journey-progress`) continua **não interativa**: no celular é o objeto "1 de 3" da cabeça; a partir de 1024px são três peças em faixa (feito · atual · tracejado). Quem volta é a seta do cabeçalho. |

## 4 · Navegação

| id | onde foi parar |
|---|---|
| ON-12 | Sem superfície: a entrada é do router. O desenho cobre a primeira execução em `#vazio` e o carregamento em `#carregando`. |
| ON-13 | `#carregando` abre já com a tira de brasa de ON-25, coexistindo com o filete de leitura — exatamente como o inventário descreve. |
| ON-14 · ON-15 · ON-16 · ON-17 · ON-18 | Sem superfície própria: são o destino do botão redondo do herói. O herói diz **para onde vai** (nome) e **o que vai acontecer** (confirmação, ON-67). Um estado por destino: `#semia`, `#preenchido`, `#lista`, `#colecao`, `#jogar`, `#ajuste`. |
| ON-19 | Saída pelo ✕ (`onboarding-skip-action`) e, em `#negado`, pelo herói. |
| ON-20 | `.bt-back` no cabeçalho volta uma batida; voltar não apaga escolha nenhuma. |
| ON-21 | Sem superfície: a conclusão é do router. Registrado aqui porque a tela **não** tem estado de sucesso (ON-40). |
| ON-84 | `#ajuste`: etiqueta "Ajuste sua rota", pergunta "Qual é sua próxima jogada?", **sem ✕** (ON-37), com a seta de volta para a Home e o plano já preenchido. |
| ON-85 | `#jogar`: a cena acesa "Sua mesa · 4 lugares abertos" com os quatro assentos e a vida inicial, e a linha "Na Home: um deck revisado ou um modo rápido sem deck". É o único momento em que o onboarding **faz** algo com o app em vez de só perguntar. |
| ON-86 | Sem superfície: consequência do destino. Registrado no texto de `#ajuste` ("rota já resolvida" pela ausência do ✕). |

## 5 · Estados

| id | onde foi parar |
|---|---|
| ON-22 | `#carregando`: `data-key="onboarding-loading-progress"`, etiqueta "Carregando progresso" + `.bt-carga` correndo, e os cinco azulejos em `.bt-is-carregando` (o fio de luz do kit). O ✕ continua aceso. **Desenho próprio, distinto de ON-30.** |
| ON-23 | `#leitura`: tabuleiro normal (valores padrão) + tira de brasa com o texto exato + ↻. |
| ON-24 | `#sessao`: tabuleiro **inerte** (nada é lido nem gravado) + tira de brasa + herói "Entrar novamente" ⚠ ação nova, porque o inventário manda reautenticar e a tela não tinha caminho. |
| ON-25 | `#carregando`: tira de brasa junto do filete de leitura. |
| ON-26 | `#aviso`: o objetivo **continua aceso** (a escolha vale) e a tira diz que só a gravação falhou. |
| ON-27 | `#erro`: o herói **sobrevive**, vira brasa cheia, diz o que falhou e o botão redondo dele tenta de novo. |
| ON-28 | `#negado`: tira de brasa — o pular que não confirmou. |
| ON-29 | `#negado`: a linha de estado **dentro** do tabuleiro tracejado, junto do numeral 0. |
| ON-30 | `#salvando`: tudo apaga (`.ob-apagado`/`.ob-inerte`), o herói fica aceso com a rosca e o rótulo "Salvando seu plano…" — **e o ✕ continua aceso** (corrige ON-87). Desenho distinto de ON-22. |
| ON-31 | `#retomado`: etiqueta "Plano retomado", pergunta "Continue de onde você parou.", controles já preenchidos e o resumo com as três portas. |
| ON-32 | `#ajuste`: "Ajuste sua rota" / "Qual é sua próxima jogada?". |
| ON-33 | `#vazio`: "Comece pelo seu jogo" / "O que você quer fazer primeiro?". |
| ON-34 | `#vazio` e `#quatro`: a faixa **tracejada** no lugar do herói — o slot da ação existe e ainda não tem dono. Carrega "Escolha um objetivo" + a promessa de ON-66; a frase de ON-34 aparece por inteiro a partir de 1024px. |
| ON-35 | `#negado`: o tabuleiro inteiro tracejado, com os cinco caminhos em planta (silhueta + nome) e numeral **0**. Nada de caixa vazia: o que existe está desenhado, e o que ainda dá para fazer é o herói de pular. |
| ON-36 · ON-51 | `#semia`: a peça "Gerar uma base" **não é renderizada**; "Criar do zero" ocupa a largura inteira, acesa, com numeral 0. Copy alternativa em todos os lugares: pergunta ("Comece manualmente."), descrição do objetivo no resumo ("Do zero, carta por carta"), confirmação do herói e rótulo da ação ("Criar deck do zero"). |
| ON-37 | `#ajuste`: sem ✕. |
| ON-38 | Sem superfície própria: é o mesmo desenho de ON-34 (`#vazio`), por definição do inventário. |
| ON-39 | Registrado, não inventado: nenhuma tela de cota de IA, offline ou sessão expirada. |
| ON-40 | Registrado: não existe estado de sucesso — o sucesso é a navegação. |
| ON-87 | Corrigido pelo desenho: em `#salvando` o ✕ continua aceso. ⚠ implica `setState` de saída no código. |
| ON-88 | Corrigido pelo desenho: não existe frase "escolha também seu momento" — a razão de a ação não existir é o **objeto tracejado** no lugar dela, que nunca mente. |

## 6 · Feedback

| id | onde foi parar |
|---|---|
| ON-41 | `data-key="onboarding-persistence-error"` = a tira de **brasa cheia** com tinta marfim, `role="alert"`, sempre no pé do palco, acima do herói. Carrega as sete mensagens de ON-23..ON-29 (seis na tira, ON-29 dentro do tabuleiro de `#negado`). |
| ON-42 | Morreu como frase. A pendência agora é a **faixa tracejada** (ON-34). |
| ON-43 | Ver ON-34. `role="status"` na faixa. |
| ON-44 | Celular: o objeto "1 de 3" da cabeça, com `aria-label` compondo a frase de ON-80. Desktop: as três peças "1 Objetivo · 2 Contexto · 3 Ação" (feito, atual com aro de latão, pendente tracejado). |
| ON-45 · ON-67 | A confirmação do objetivo escolhido mora **dentro do herói** (`.ob-heroi__conf`) nos seis caminhos e **dentro do azulejo aceso** em `#aviso`. As seis frases estão no HTML e na tela. |
| ON-46 | `aria-pressed` em todo objetivo, momento, modo e formato; `role="group"` na trilha; `role="alert"` na tira; `role="status"` no filete de leitura, na faixa tracejada e no herói de `#salvando`. |
| ON-47 | Sem superfície (transição). O arranjo não colapsa nem remonta: cada batida é uma tela. |
| ON-48 | Mantido: nenhum snackbar, dialog ou bottom sheet. A única superfície extra é `#formato`, que é uma folha do próprio fluxo. |

## 7 · Regras de negócio

| id | onde foi parar |
|---|---|
| ON-49 | `#quatro` prova a filtragem: sem `ai_analyze_optimize_advisory` o objetivo "Melhorar um deck" **não é renderizado** e "Jogar uma partida" ocupa a linha inteira. Sem cadeado e sem explicação, como no código. |
| ON-50 | Só `#preenchido`, `#semia`, `#salvando` e `#erro` (caminho `buildDeck`) têm peças de modo. `#lista`, `#colecao`, `#jogar` e `#ajuste` mostram a cena do próprio caminho. |
| ON-51 | Ver ON-36. |
| ON-52 | O herói só existe nas telas com objetivo **e** momento escolhidos. Em batida 1 o lugar dele é a faixa tracejada. |
| ON-53 | `#carregando` (azulejos em `.bt-is-carregando`), `#salvando` e `#sessao` (`.ob-inerte`) desenham o bloqueio. |
| ON-54 · ON-37 | `#ajuste` sem ✕. |
| ON-55 · ON-56 · ON-57 · ON-58 · ON-59 · ON-89 · ON-90 | Sem superfície: contrato de rota, de gravação e de telemetria. Nada no desenho os contraria — em especial, não existe "limpar plano" nem desmarcar. |
| ON-60 | `#retomado` só aparece com plano salvo de verdade; `#vazio` é a primeira execução. |
| ON-61 · ON-92 | Três arranjos: celular (uma coluna, batida por tela), ≥1024px (rail de 92px, cabeça em faixa larga com a trilha à direita, palco na largura inteira — mosaico de quatro colunas na batida 1, decisão grande + plano em pé na batida 3), ≥1200px (rail estendido de 204px). Provado em `vazio-1440.png`, `preenchido-1440.png`, `carregando-1440.png` e `preenchido-1920.png`. |
| ON-62 | ✕ 64px, glifos do shell 44px, seta de volta 44px, botão do herói 50px (58px no desktop), botão ↻ da tira 44px. Animações zeradas em `prefers-reduced-motion`. |
| ON-91 | Sem arraste próprio: nenhum carrossel, nenhum azulejo deslizante. A rolagem só existe no piso (ON-94) e é vertical. |
| ON-93 | `onboarding-format-dropdown` preservado (no azulejo de formato do resumo) junto com todas as outras chaves do contrato. |
| ON-94 | Abaixo de 360px de largura **ou** 660px de altura a batida volta a rolar e as linhas ganham altura mínima — os pares continuam lado a lado e o herói continua alto. Prova: `vazio-320.png` (320×568, página inteira). ⚠ a prova com `textScaler` 2,0× continua sendo do teste de widget: Chromium não simula textScaler. |

## 8 · Copy essencial

| id | onde foi parar (texto na tela) |
|---|---|
| ON-63 | "Seu primeiro passo" / "Formato principal" no cabeçalho, uma linha, com reticências se faltar espaço. |
| ON-64 | "Comece pelo seu jogo" / "Plano retomado" / "Ajuste sua rota" — etiqueta em latão ao lado do passo. |
| ON-65 | "O que você quer fazer primeiro?" / "Continue de onde você parou." / "Qual é sua próxima jogada?" · e as perguntas por caminho de ON-71. |
| ON-66 | Dentro da faixa tracejada de `#vazio`: **"Escolha um objetivo" + "O BrewTact prepara somente o caminho necessário"**. ⚠ virou objeto (título em serifa + linha em caixa alta), não um terceiro parágrafo cinza. |
| ON-67 | As seis frases, dentro do herói: `#preenchido`/`#aviso`/`#retomado` (IA on), `#semia` (IA off), `#lista`, `#colecao`, `#jogar`, `#ajuste`. |
| ON-68 | As cinco descrições, em caixa alta **dentro** do azulejo: "Do zero ou com uma base", "De texto ou de outro site", "Cópias, impressão e estado", "Com ou sem deck vinculado", "Revise mudanças com contexto". Variante de IA off ("Do zero, carta por carta") no resumo de `#semia`. ⚠ encurtadas para caber como estado da peça; o sentido é o mesmo. |
| ON-69 | A promessa de reversibilidade não virou cabeçalho de banda: ela está na faixa tracejada (ON-66) e no herói de `#negado` ("Seu objetivo continua salvo — nada é apagado"). ⚠ copy comprimida. |
| ON-70 | Etiqueta única de `#retomado`: **"Seu momento muda a orientação, não as regras"**. ⚠ funde o cabeçalho do passo 2 com a cláusula. |
| ON-71 | As perguntas por caminho viraram o `<h1>` de cada batida 3: "Escolha como começar." / "Comece manualmente." / "Prepare sua lista." / "Traga suas cartas." / "Prepare a mesa." / "Qual é sua próxima jogada?". As descrições por caminho estão em caixa alta dentro da cena acesa ("Cole, confira as cartas e resolva pendências antes de salvar", "Em lote: impressão, idioma, acabamento e condição", "Na Home: um deck revisado ou um modo rápido sem deck", "Preview, fontes e undo antes de qualquer mudança") e por inteiro a partir de 1024px. |
| ON-72 | Dentro das duas peças de modo: caixa alta no celular ("Carta por carta · nome, formato e comandante" / "Mais rápido · você revisa antes de salvar") e a **frase inteira do inventário** a partir de 1024px ("Você começa com nome, formato e comandante…" / "A IA prepara uma base para você revisar. Nada é aplicado sem sua confirmação."). |
| ON-73 | Idem: as duas linhas em caixa alta são os rótulos de modo, agora unidos à promessa de ON-72. |
| ON-74 | Os seis rótulos, cada um desenhado no seu estado: "Criar deck do zero" (`#semia`), "Gerar uma base para revisar" (`#preenchido`, `#retomado`, `#salvando`), "Revisar minha lista" (`#lista`), "Importar minha coleção" (`#colecao`), "Continuar para a mesa" (`#jogar`), "Escolher deck para melhorar" (`#ajuste`). Em progresso: "Salvando seu plano…" (`#salvando`). |
| ON-75 | No herói de `#negado`: "Pular por enquanto" + "Seu objetivo continua salvo — nada é apagado." ⚠ a frase do inventário aparece partida entre nome e estado do objeto, porque o ✕ é peça muda na régua. O `aria-label` do ✕ continua com a frase inteira. |
| ON-76 | "Começando agora" / "Voltando ao Magic" / "Jogo com frequência", nas três peças de `#retomado`. |
| ON-77 | Dentro do azulejão de Commander: "Vale agora · é o contexto do caminho". |
| ON-78 | As sete frases, uma por estado: ON-23 (`#leitura`), ON-24 (`#sessao`), ON-25 (`#carregando`), ON-26 (`#aviso`), ON-27 (`#erro`, dentro do herói), ON-28 (`#negado`), ON-29 (`#negado`, dentro do tabuleiro). Nenhuma truncada. |
| ON-79 | "Tentar novamente": nome do herói de `#erro`; nas tiras é o botão redondo com ↻ e `aria-label`. |
| ON-80 | `aria-label` da trilha, do filete de leitura e de cada objetivo. |

---

## O que mudou nesta passada (e por quê)

1. **Um latão por tela.** A peça escolhida deixou de ser latão e passou a ser vitral cheio com aro de
   marfim. Acaba a colisão "99 Gerar uma base" (peça) × "Gerar uma base" (herói).
2. **Morreu a tira cinza com ícone de brilho** em `#vazio` e `#preenchido`. A informação foi para
   dentro das peças (caixa alta) e para dentro do herói (confirmação em tinta escura).
3. **Os glifos do shell saíram da barra no celular** e aparecem a partir de 1024px, onde a barra é a
   do shell de verdade.
4. **A Home embaixo virou forma legível**: desfoque curto (5px), barra, faixa com arte e uma grade de
   decks que vai até a borda de baixo. Sem barra de navegação borrada no pé.
5. **O azulejo-herói ganhou a mesma anatomia dos outros** (moldura com o objeto em cima, título e
   estado embaixo): acabou o vão escuro à esquerda.
6. **`#negado` encolheu e ganhou conteúdo**: o tabuleiro tracejado mostra os cinco caminhos em planta
   (silhueta + nome), o numeral 0, a frase de estado, a tira de brasa e o herói de pular.
7. **Alinhamento da fileira de momentos** corrigido: o aro de "escolhido" é inset.
8. **Desktop sem quadrante morto**: a cabeça virou faixa larga (pergunta à esquerda, trilha 1·2·3 à
   direita) e o palco ocupa a largura inteira.
9. **Nada trunca**: o nome da jogada no herói quebra em duas linhas; o nome da rota no cabeçalho é uma
   linha com reticências e foi provado de 320px a 1920px.
10. **Seis estados novos** para cobrir função que não tinha desenho: `#semia` (IA negada), `#ajuste`
    (reentrada resolvida), `#lista`, `#colecao`, `#leitura`, `#sessao`.

## Pendências

- ⚠ **Copy nova** (precisa do martelo do dono): as palavras de estado dos momentos, as linhas de valor
  dos seis formatos, as compressões de ON-68/ON-69/ON-70/ON-72/ON-73 e a ação "Entrar novamente".
- ⚠ **Prova de aparelho**: tudo aqui é Chromium em `--device-scale-factor 2`. Simulador de iPhone e
  medição de contraste no pixel ainda não passaram por estes layouts.
- ⚠ **ON-82**: o orçamento de `Tab` do teste de widget precisa ser reescrito junto com a tela.
- ⚠ **ON-87**: o desenho mantém o ✕ aceso em `#salvando`; o código precisa de uma saída de fato.
