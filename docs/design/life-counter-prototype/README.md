# Protótipo do contador de vida — régua visual

Snapshot do protótipo HTML da mesa (contador de vida de Commander). Ele não é código de produção:
é a **referência visual e de interação** que o app deve igualar, provada no iPhone 17 (simulador) e
por uma suíte de toque real. Nada aqui é lido por gates, digest de UI ou manifesto.

> Estado do snapshot: **todas as telas do contador já estão na linguagem nova** — menu da mesa,
> seletor de jogadores/vida, regras, dados, folha do jogador, plano, turnos e tempo, partidas guardadas,
> a partida aberta, o resumo, o teclado de vida e a escolha de quem fica com a peça. Não sobrou
> nenhuma lista de texto, tabela nem rodapé de botões de formulário.

## Como abrir

- `mesa-brewtact.html` — o protótipo (um arquivo, sem build). `python3 tools/wrap.py` gera `serve/index.html`.
- `python3 tools/probe_arranjo.py` — mede, arranjo por arranjo, o corpo do numeral e a altura que ele
  ocupa no card. Foi essa medição que definiu o catálogo de arranjos (e revelou o limite de 7 jogadores).
- `python3 tools/run_tests.py` — 83 checagens funcionais, de layout, de contraste e de cor
  (Playwright + toque real via CDP). As sete últimas são réguas de aparência: 75 não deixa token de cor
  cair em nada, 76 mede contraste **nos pixels**, 77 mantém a cor de estado ruim longe de toda cor de
  jogador, 78–79 cobrem partidas guardadas e a partida aberta, 80 o teclado de vida, 81 a escolha da
  peça (nada cortado, nada por baixo do ✕, nada abaixo de 44px, apagar só com dois toques) e 82–83 o
  arranjo dos assentos (só divisões que cumprem o piso; escolher arranjo é preferência, não lance).
- `python3 tools/contrast.py` — mede contraste WCAG de verdade: esconde o elemento, fotografa o fundo
  que estava embaixo e compara com a tinta já composta. Imprime `REPROVA` no que fica abaixo do mínimo.
- `python3 tools/look.py menu-vivo|mesa|regras|partidas|partida|resumo|…` — retrato de um estado, para **olhar antes de testar**.
- `tools/shot_check.py <captura.png>` — mede, numa captura do aparelho, o desvio do numeral em relação
  ao centro de cada card e a folga até a borda.
- `design/vitral`, `design/azulejos-vivos` — as duas direções finalistas (mock HTML + PNG). A escolhida
  foi **Vitral com a disciplina dos Azulejos vivos**.
- `provas-iphone/` — capturas do simulador.

## A linguagem

**Tipos.** Fraunces (numerais e títulos, peso 600–700, numerais `lining-nums`) e Inter (UI; rótulos em
caixa alta, peso 800, 11–11,5 px, tracking ~.085em).

**Cores.** Obsidiana `#0B0D12` de fundo, marfim `#F3EFE3` para numerais e texto, latão `#E0A93B`/`#C58B2A`
como único destaque, névoa `#B8C0CC` para apoio. As cores de card (brasa, âmbar, musgo, maré, índigo,
ameixa…) pertencem aos **jogadores**, nunca a botões.

**Mapa de significado — vale em toda tela:**

| Aparência | Quer dizer |
|---|---|
| Vidro escuro com filete marfim | ação neutra, sem estado |
| Cor cheia (vitral, com brilho diagonal) | algo está **valendo** agora (é noite, o plano está ligado, a coroa tem dono) |
| Latão cheio | a jogada principal da tela, e tudo que está **selecionado** |
| Contorno tracejado em latão | vazio, sem dono |
| Brasa | encerra ou destrói; pede dois toques |
| Vinho `#6E1B2A` | um estado **ruim** está valendo (concedeu, encerrar partida) |

**Cor de estado nunca é cor de gente.** As dez cores de card pertencem aos jogadores; uma peça acesa em
vermelho ao lado do card de quem é brasa lê como mais um pedaço da cor dele — foi o que apareceu na prova
de aparelho. Por isso o estado ruim tem token próprio, `--vinho: #6E1B2A`, **fora da paleta de jogadores**
(a cor de card "Vinho" saiu e virou "Oliva" `#5F6B22`), e a distância é medida: `ΔE ≥ 25` contra cada uma
das dez cores de card, no código e na tela. No aparelho: card `#A93C29` (L=41) contra peça `#6F1D2C`
(L=25), ΔE = 29 — ver `provas-iphone/vt-09-jogador-concedeu.png` ao lado de `vt-10-jogador-jogando.png`.

**As três regras das telas secundárias** (fixadas pelo júri de design):

1. **Objeto, não campo.** Cada opção é uma peça tocável que mostra o próprio valor dentro dela — numeral
   gigante, miniatura real, ícone próprio. Sem linha de lista, rótulo com caixa, controle segmentado,
   interruptor ou botão "confirmar". A escolha vale no toque.
2. **A mesa continua embaixo e o centro é sagrado.** Toda tela abre sobre a mesa viva, escurecida e
   desfocada. O hub vira ✕ no mesmo ponto e é a saída; quando a tela veio do menu, a seta do cabeçalho
   volta para ele.
3. **Cor e tamanho carregam significado.** Um herói claramente maior por tela, tamanhos variados, estado
   em palavra grande — nunca uma grade de doze peças iguais nem subtítulo cinza.

**Na mesa:** o numeral fica no centro **do card do jogador** (não da tela), ~60% da altura; o card tem
três faces trocadas por arrasto lateral (dano de comandante · vida · marcadores), com pontinhos dizendo
a face; nada de barra de abas fixa.

**O arranjo dos assentos.** A mesa tem **duas fileiras** e o arranjo é quantos sentam na fileira de baixo.
A escolha mora na folha Mesa, ao lado do número de jogadores, e é a **própria miniatura** do arranjo —
a mesma que aparece na peça Mesa do menu. Trocar o arranjo é preferência: não entra na pilha de desfazer,
não mexe em vida nenhuma e sobrevive ao reload.

O catálogo é **medido, não opinado** (`tools/probe_arranjo.py`, em paisagem e em retrato):

| cards na fileira | corpo do numeral | altura no card | veredito |
|---|---|---|---|
| 1 | 168 px | 61% | ok |
| 2 | 165 px | 60% | ok |
| 3 | 109 px | 40% | ok |
| 4 | 81 px | 30% | **abaixo do piso** |
| 5 | 65 px | 23% | **abaixo do piso** |

O piso é 40 px de corpo e 38% da altura do card. Daí sai a regra: **fileira de até três**. Por isso o
catálogo oferece 2+1/1+2 com três jogadores, 3+1/2+2/1+3 com quatro e 3+2/2+3 com cinco; com seis só
existe 3+3, e **de sete em diante nenhuma divisão de duas fileiras cumpre o piso** — nessa faixa fica a
divisão equilibrada, como já era, e o numeral cai para 30% (7 e 8 jogadores) ou 23% (9 e 10).

> **Decisão em aberto para o Rafa:** mesa de 7 a 10 jogadores não cumpre o piso do numeral e **nunca
> cumpriu** — a checagem 41 só olhava de 2 a 6 jogadores, então o buraco era invisível. Sair dele exige
> escolher um: (a) aceitar numeral menor acima de seis jogadores, registrando o piso dessa faixa como
> 23%; (b) deixar o numeral usar mais da largura do card (hoje `38cqw`) — a 62% da largura a faixa de
> cinco volta aos 38%, mas uma vida de três dígitos passa a ocupar a largura inteira; ou (c) limitar a
> mesa a seis jogadores. Nada disso foi decidido: o código mantém o comportamento de hoje.
>
> **Decidido pelo dono em 2026-09-22 (D-43 de `docs/status/DECISOES_PENDENTES_2026-09-22.md`):**
> (a), aceitar o numeral menor acima de seis jogadores, com piso de 23% nessa faixa, documentado.

## Onde isto parou (retomada)

> **Pausa geral pedida em 21/09/2026.** Nada estava no meio: a última onda fechou, foi provada no
> aparelho e o snapshot desta pasta é byte a byte o que rodou.

**Estado:** ondas 1 a 8 fechadas. Todas as telas do contador estão na linguagem nova.
`python3 tools/run_tests.py` → **83/83**. `python3 tools/contrast.py` → "tudo dentro do mínimo".

**Última coisa provada no iPhone 17 (simulador):** o arranjo dos assentos — `provas-iphone/vt-17-mesa-arranjo.png`
(as miniaturas de escolha ao lado de "4 jogadores") e `provas-iphone/vt-18-arranjo-3-1.png` (a mesa em 3+1,
medida com `tools/shot_check.py`: numeral a ±2 px do centro de cada card, 40% na fileira de três e 62% no
card solteiro).

**O que NÃO estava no meio:** nada. A onda 9 (arte do card) e a onda 10 (busca de card) **não começaram**.
Da onda 9 existe apenas uma sondagem de viabilidade, agora guardada aqui em `tools/probe_skin.py` —
ela injeta uma camada `.skin` no protótipo vivo (sem editar arquivo) e re-roda as invariantes das
checagens 24/25/41. Vale ler antes de escrever qualquer coisa: ela já mostra que a arte precisa de véu,
de `text-shadow` no numeral e de ficar **abaixo** das metades de toque. O caminho `ROOT` dentro dela
aponta para o diretório da sessão antiga; ajuste para a pasta onde você copiar este snapshot.

**Próximo passo exato, em ordem:**

1. ~~**Levar ao Rafa a decisão registrada acima**~~ — decidida em 2026-09-22: opção (a). Texto original: (mesa de 7 a 10 jogadores não cumpre o piso do numeral e
   nunca cumpriu): (a) aceitar 23% como piso dessa faixa, (b) deixar o numeral usar mais da largura do
   card, ou (c) limitar a mesa a seis jogadores. **Nada no código assume qualquer uma delas.** Se for a
   (b), medir antes de aplicar, com vida de três dígitos em todas as fileiras.
2. **Onda 9 — arte do card.** Começar relendo `probe_skin.py`, depois desenhar a camada de arte com as
   três regras das telas secundárias valendo. O risco conhecido é contraste: o numeral marfim sobre arte
   clara. `tools/contrast.py` mede sobre a cor de card mais clara e mais escura da paleta; para arte
   precisa de um alvo novo, sobre a imagem real.
3. **Onda 10 — busca de card.** Ainda sem nada.

**Como retomar em três comandos** (tudo o que importa está nesta pasta; a pasta de trabalho da sessão
era temporária e pode já ter sido limpa):

```
cp -R docs/design/life-counter-prototype /tmp/mesa && cd /tmp/mesa
python3 tools/wrap.py && python3 tools/run_tests.py
python3 tools/look.py partidas   # retrato de um estado, para olhar antes de testar
```

Para voltar ao aparelho: `bash tools/push_sim.sh` (com o simulador aberto e o app `com.mtgia.mtgApp`
instalado) e depois `bash tools/sim_shot.sh <nome>`; `tools/vc.py x,y` converte coordenada da captura
girada em ponto de toque do aparelho.

**Regras que valiam nesta sessão e continuam valendo:** não tocar em `app/lib`, `app/assets` nem
`app/web` (o digest de evidência de UI está congelado); não dar `git add` nem commit nesta árvore (outra
sessão mantém o índice montado); esta pasta não é lida por gate, digest ou manifesto.

## Peças reutilizáveis fora do contador

Candidatas a virar um kit Flutter compartilhado:

- **Azulejo com estado** (`.menu .t` + `.lit` / `.livre` / `.danger`): ícone no alto à esquerda, rótulo em
  caixa alta embaixo, estado no alto à direita; quatro aparências do mapa acima.
- **Herói de latão** (`.hero`): numeral serifado gigante + nome + botão redondo escuro de ação.
- **Numeral serifado gigante** (`.life`, `.num`): Fraunces, `lining-nums tabular-nums`, entrelinha .72–.8,
  dimensionado pelo espaço real do contêiner.
- **Peça de escolha com miniatura** (`.p` + `.seats`): miniatura do objeto real + numeral; selecionada em latão.
- **Peça-numeral** (`.v`): escolher um número entre poucos (20/30/40, 5/10/20).
- **Peça-regra que acende** (`.rt`): substitui o interruptor; acesa em latão e diz "vale". A variante
  `.rt.bad` acende em vinho (`var(--vinho)`), nunca num vermelho solto no CSS.
- **Saída única** (`.x` / hub que vira ✕) e **volta no cabeçalho** (`.back`).
- **Fundo de tela secundária**: véu radial + `backdrop-filter: blur` sobre o conteúdo vivo.
- **Rodapé de ação** (`.sheet > .btns`): fora da área que rola, nunca cobre conteúdo.
- **Resultado herói** (`.dx-hero`): numeral gigante que acende em latão quando há valor, apagado com "?" quando não.
- **Peça-forma** (`.dx-die`): a forma do objeto (dado) desenhada em SVG, com o nome embaixo — substitui botão com texto.
- **Fileira de jogadores com valor** (`.dx-p`): card na cor do jogador, numeral grande, etiqueta de latão no vencedor.
- **Placa de texto** (`.plaque`): campo sem caixa — serifa grande sobre um fio, que acende em latão no foco.
- **Contador com ± e numeral** (`.pl-count`): rótulo em cima, numeral serifado entre dois botões redondos, nota embaixo.
- **Barra de proporção por pessoa** (`.tn-p`): nome, barra na cor do jogador e valor; a linha ativa ganha halo de latão.
- **Herói de comando** (`.tn-hero`): estado grande à esquerda, nome no meio, botões redondos de ação à direita.
- **Modo ligado/desligado** (`.rt` em `.pl-modes`): substitui interruptor de configuração por peça que acende.
- **Ficha de registro** (`.hx-g`): um acontecimento vira um card na cor de quem venceu, com a mesa em
  miniatura em cima (uma bolinha por cadeira, a de quem venceu com aro de latão), o nome em serifa no meio
  e um rodapé de uma linha: data à esquerda, numeral grande à direita. Sem dono → tracejado em latão.
  Três faixas fixas (`grid-template-rows: auto 1fr auto`) e o texto só na coluna da esquerda: é o que
  garante que nome, data e numeral nunca se cruzem, em qualquer tamanho de tela.
- **Linha de resultado** (`.rs-p`): substitui a tabela. Cada jogador é um card na cor dele, com a vida em
  numeral serifado à esquerda, nome e nota no meio e selos (`Cmd 14`, `Veneno 3`, `Venceu` em latão) à
  direita. Quem venceu ganha o aro de latão e numeral maior; quem saiu antes fica dessaturado.
- **Apagar com dois toques** (`.hx-x` + `.is-armed`): o primeiro toque acende o botão em vinho, o segundo
  apaga — sem caixa de confirmação.
- **Herói do que se digita** (`.padout`): o número em edição é um card na cor de quem vai recebê-lo —
  legenda em cima (`novo total` / `total agora`), numeral serifado gigante, e embaixo de quanto era e
  quanto muda (`era 40 · −11`). Sem dono (um valor da mesa) o card é vidro escuro (`.neutro`).
- **Tecla** (`.pad button`): vidro escuro, numeral serifado, 56px (46px em tela baixa); apagar e limpar
  em névoa, para não competirem com os números.
- **Ação principal redonda** (`.pd-go`): botão de latão que **só acende quando há o que aplicar**; apagado
  em vidro escuro enquanto não há. A variante `.wide` vira pílula com a palavra quando a consequência
  precisa ser dita ("Começar partida").
- **Herói com marca d'água** (`.tk-hero`): quem está com a peça, na cor dele, com o desenho da própria peça
  em marca d'água à direita — é o que ancora o lado vazio do herói. Sem dono → tracejado em latão.
- **Miniatura como escolha** (`.arow` + `.a`): escolher um arranjo é tocar no desenho dele — duas fileiras
  de retângulos na proporção real dos cards, em névoa quando não está valendo e em latão quando está.
  A mesma miniatura serve de estado na peça Mesa do menu; 46×44 px é o menor tamanho que ainda respeita
  o alvo de toque.
- **Grade de escolha com a peça vazia** (`.tk-grid` + `.tk-p` + `.tk-p.livre`): cada jogador é um card na
  cor dele; quem tem a peça mostra a marca e ganha aro de latão; quem está fora fica dessaturado e
  desligado; e **"ninguém" é a peça tracejada da mesma grade**, não um botão de rodapé.

## Armadilhas já pagas

- Classes genéricas colidem: `.half` e `.picker` já existiam e quebraram telas novas em silêncio. Prefixe.
- Depois de um toque o navegador manda um clique tardio na mesma coordenada; se a tela mudou, ele fecha
  o que acabou de abrir. Suprimir **pela posição do dedo**, não por tempo.
- Arrasto lento não pode virar "segurar": passou de poucos pixels, cancela o toque longo.
- Centralizar pelo card, não pela tela: a área segura (ilha dinâmica) só afasta o que mora na borda.
- Cortar um bloco de função por índice de texto pode levar junto helpers vizinhos (aconteceu com as formas
  dos dados ao reescrever a tela de turnos): confira `node --check` **e** a suíte depois de cada troca grande.
- `inner_text()` devolve o texto já em caixa alta quando há `text-transform`: compare com `.upper()`.
- Token de cor usado sem declarar cai em nada e ninguém vê (foi o caso de `--frost-400`). A checagem 75 agora
  compara todo `var(--x)` do arquivo com o que está declarado.
- Olhe o PNG antes de confiar no teste. Três defeitos desta fase passaram na suíte e só apareceram na imagem.
- `.seats` já era do arranjo de cadeiras e virou uma caixa escura atrás das bolinhas da ficha. É a segunda
  vez que uma classe genérica colide: prefixe **sempre** (`.hx-seats`).
- A folha entra com `animation: fade .16s`. Medir cor logo depois do clique mede a **mesa por baixo**,
  não a peça — o medidor de contraste espera 400 ms antes de qualquer leitura.
- Para medir contraste de texto sobre uma peça com fundo próprio (um selo de latão, por exemplo), apague
  só a **tinta** (`color: transparent`), não o elemento: escondendo o elemento inteiro você mede o que há
  atrás da peça, e o selo "Venceu" aparecia com 2.0 quando na verdade tem 9.2.
- `scrollHeight > clientHeight` acusa corte falso em serifa com entrelinha apertada: a régua só olha altura
  onde o `overflow` realmente esconde, e o nome da ficha passou a ter entrelinha 1.2.
- A mesa de exemplo **não** começa com todo mundo na vida inicial (ela vem com números variados, de
  propósito). Teste que supõe 40 quebra sem motivo: leia o valor antes e compare com ele.
- Uma régua que só olha parte do domínio esconde o defeito no resto: a checagem do numeral cobria 2 a 6
  jogadores e por isso ninguém viu que de 7 a 10 o piso nunca foi cumprido. Ao fixar um piso, cubra
  **toda** a faixa que o produto oferece.
- `shot_check.py` supunha uma grade única de colunas para a captura inteira e, no arranjo 3+1, juntou a
  fileira de baixo num card só — reportando um desvio de +878 px que não existia. Cada fileira precisa
  da sua própria segmentação. Ferramenta que dá alarme falso é pior que ferramenta nenhuma.
- Contraste calculado a partir do CSS mente: `color-mix`, sombra e gradiente mudam o que o olho recebe.
  Meça no pixel (é o que `tools/contrast.py` faz), e amostre o **fundo sem o texto** — amostrar dentro da
  caixa do texto pega o glifo e dá número sem sentido.
- Trocar o token e esquecer de apontar a regra para ele não muda nada na tela: `.rt.bad.on` continuou com
  um `#B5402B` no meio do gradiente depois que `--vinho` já existia, e só a captura do aparelho mostrou.
  A checagem 77 agora proíbe hex solto nessa regra.
