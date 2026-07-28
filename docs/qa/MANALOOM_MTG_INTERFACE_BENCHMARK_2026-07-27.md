# ManaLoom — benchmark de interfaces MTG

**Data:** 2026-07-27
**Decisão:** adotar a linguagem `arcane tabletop utility`

## Resultado

A base Obsidian/Frost/Brass do ManaLoom já era coesa, legível e premium, mas
cor escura com dourado, isoladamente, ainda podia ser lida como fantasia
genérica ou SaaS. A identidade de Magic aparece de forma convincente quando a
interface prioriza os objetos e estados do jogo: cartas, decks, formatos,
legalidade, identidade de cinco cores, mão, pilha, campo, prioridade, vida,
zonas e replay.

A revisão qualitativa das provas anteriores encontrou a maior força no Battle
Coach ativo, Auth/Splash e Home. As superfícies mais genéricas eram vazios e
erros de cartas/coleção, busca social, trades e algumas composições Web largas.
Essas lacunas orientaram a implementação; a avaliação não é uma métrica
automática de qualidade.

## Referências pesquisadas

- [MTG Arena](https://magic.wizards.com/en/mtgarena): usa campo, deck, formato,
  legalidade e as cinco cores como estrutura de produto, não apenas decoração.
- [Magic Companion](https://magic.wizards.com/en/products/companion-app):
  privilegia clareza operacional de vida, rodada, oponente e próxima ação no
  uso presencial.
- [Atualização de perfis do Companion](https://magic.wizards.com/en/news/announcements/companion-app-update-magic-player-profiles):
  organiza histórico, local e resultados como memória de jogo.
- [Novo Gatherer](https://magic.wizards.com/en/news/announcements/a-fresh-look-for-gatherer):
  mantém a carta e o texto Oracle como objetos centrais em uma composição mais
  limpa e responsiva.
- [Scryfall](https://scryfall.com/) e
  [busca avançada](https://scryfall.com/advanced): demonstram densidade
  funcional, filtros próprios de Magic e hierarquia centrada na carta.
- [Archidekt](https://archidekt.com/landing): aproxima o deckbuilder da
  manipulação tátil de pilhas de cartas e conecta construção, coleção e
  playtest.
- [ManaBox](https://manabox.app/) e seu
  [guia de decks](https://www.manabox.app/guides/decks/getting-started/):
  conectam carta, coleção física, curva de mana, tipos, tokens e simulador.

## Padrões aproveitados

1. **Objeto antes do ornamento:** arte real, moldura de carta, deck, set,
   jogador ou zona devem carregar a identidade principal.
2. **Cinco cores como dados:** WUBRG informa identidade, distribuição e estado;
   não funciona como logotipo decorativo.
3. **Mesa como modelo mental:** mão, pilha, campo, prioridade e orientação dos
   jogadores tornam Battle e Life Counter imediatamente reconhecíveis.
4. **Vocabulário do jogo:** formato, legalidade, Commander, mulligan, mana,
   cemitério e replay são sinais mais fortes que ícones genéricos.
5. **Utilidade primeiro:** ações universais continuam usando símbolos
   familiares; conceitos próprios do produto recebem glifos ManaLoom.

## Implementação resultante

- estados vazios, loading e erro receberam um motivo original de cartas/mesa
  com baixa intensidade;
- fallbacks de imagens passaram a usar um verso autoral ManaLoom, preservando
  proporção de carta, moldura e cinco pontos de identidade;
- navegação ganhou glifos originais para marca, comunidade e jogador;
- busca social e estados de comunidade passaram a falar em jogadores, decks e
  mesa, sem ilustrações genéricas;
- Battle Coach ganhou campo, zonas e a leitura
  `MÃO · PILHA · CAMPO · PRIORIDADE`;
- Battle Replays passou a usar o objeto de replay e o motivo de campo;
- Life Counter ganhou um halo discreto de cinco cores ao redor do controle
  central;
- o contrato visual principal agora documenta hierarquia, interação e limite
  de propriedade intelectual.

## Limite de propriedade intelectual

A solução não copia logos da Wizards, marca de Planeswalker, símbolos de set,
o verso oficial das cartas, trade dress nem layouts proprietários. O verso
ManaLoom, os glifos e os motivos são originais e usam proporções de carta,
zonas e cores como informação.
Essa decisão também segue a
[Política de Conteúdo de Fãs da Wizards](https://company.wizards.com/pt-BR/legal/fancontentpolicy),
que restringe logos e marcas registradas.

## Critério de aceite

A mudança só recebe aceite depois de:

- recaptura das 214 telas/estados P0 em Web mobile, desktop, wide e Android
  físico;
- sete estados dedicados do Battle Coach Android;
- nove checkpoints de teclado/foco real no Battle Coach Web;
- uma prova dedicada do verso autoral quando a arte está indisponível;
- inspeção visual de todas as imagens, inclusive a platform view do Life
  Counter capturada pelo compositor Android;
- `flutter analyze`, testes focados, gates `ui-audit` e `ui-proof`, drift
  documental e CI local verdes.
