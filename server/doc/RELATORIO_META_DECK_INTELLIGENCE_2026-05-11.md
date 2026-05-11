# Relatorio Meta Deck Intelligence - 2026-05-11

## Escopo

- Repositorio: `softwarePredador/mtgia`
- Branch alvo: `master`
- Objetivo: criar perfil de referencia externo/agregado para
  `Lorehold, the Historian`.
- Superficie alterada: documentacao apenas.
- Codigo runtime: nao alterado.

Perfil persistido:

- `docs/qa/lorehold_reference_profile_2026-05-11.md`

## Veredito

**PASS WITH RISKS**

O perfil externo/agregado foi criado sem promover decklists externas, sem copiar
lista completa e sem tocar no runtime. O risco principal e que a evidencia
Playgroup nao foi provada publicamente nesta rodada e a base local retornou duas
prints enquanto Scryfall retornou tres.

## Fatos locais provados

- A documentacao local ja registra regressao para troca de edicao do comandante
  `Lorehold, the Historian`.
- O backend local temporario retornou duas opcoes em
  `/cards/printings?name=Lorehold%2C%20the%20Historian&limit=50&sync=true`:
  `PSOS #201p` e `SOS #284`.
- As respostas locais carregavam `set_code`, `collector_number`, `rarity`,
  `color_identity` e `type_line`.
- O contrato local testado anteriormente exige multiplas opcoes, elegibilidade
  de comandante, identidade `R/W`, metadados de edicao e ausencia de copia extra
  no `main_board`.

## Achados derivados da web

- Scryfall prova que `Lorehold, the Historian` existe, e uma criatura lendaria
  `R/W`, e legal em Commander.
- Scryfall lista tres prints publicas: `PSOS #201p`, `SOS #284` e `SOS #201`.
- EDHREC, Archidekt e MTGGoldfish fornecem contexto Commander publico para o
  comandante.
- Playgroup nao forneceu evidencia publica utilizavel: busca indexada sem deck
  provado e URL publica redirecionando para login.

## Interpretacao estrategica

O padrao util para ManaLoom e Boros miracle big-spells: usar a habilidade de
miracle `{2}` para transformar instants/sorceries caros em viradas de mesa,
desde que o deck tenha manipulacao de topo, compra em turnos adversarios,
ramp/tesouros e interacao suficientes.

O perfil nao deve ser tratado como cEDH. A relevancia competitiva de Lorehold
nao foi provada nesta rodada.

## Padroes uteis para absorver

- Tag conceitual futura: `boros_miracle_big_spells`.
- Filtro obrigatorio: Commander legal, identidade dentro de `R/W` ou incolor, e
  exclusao de banidas.
- Scoring setup-before-haymaker: cartas de topo/compra aumentam confianca para
  sugerir payoffs caros; sem setup, payoffs caros devem ser penalizados.
- Separacao casual/high-power vs cEDH: usar o perfil para Commander casual/tuned,
  nao para `competitive_commander`.

## Padroes arriscados ou nao transferiveis

- Nao gravar EDHREC, Archidekt, MTGGoldfish ou Playgroup diretamente em
  `external_commander_meta_candidates` a partir desta pesquisa.
- Nao importar pacote blue miracle generico: cartas como `Temporal Mastery` e
  `Devastation Tide` sao off-color para Lorehold.
- Nao recomendar banidas de Commander como fast mana generica.
- Nao tratar Playgroup como fonte validada ate existir pagina publica acessivel.

## Menores proximas acoes tecnicas

1. Auditar sincronizacao local para a print `SOS #201`.
2. Criar fixture nao-runtime para `boros_miracle_big_spells` se o motor passar a
   consumir perfis de referencia.
3. Adicionar teste futuro que rejeite blue miracle/off-color e banidas de
   Commander ao recomendar cartas para Lorehold.
