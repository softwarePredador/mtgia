# Game Changers — Referencia Completa

> Analise completa dos 53 Game Changers oficiais do formato Commander.
> Fonte primaria da lista: Scryfall `is:gamechanger` / campo API `game_changer`.
> Brackets oficiais: URL solicitada `https://mtgcommander.net/index.php/brackets/` retornou Page not found nesta execucao; texto especifico da pagina = NAO VERIFICADO.
> Ultima atualizacao: 2026-05-27

## O que e um Game Changer?

Game Changers sao cartas que distorcem o jogo ao redor delas. Sao permitidas
em bracket 3 (ate 3) e bracket 4 (sem limite), mas PROIBIDAS em bracket 1-2.

A definicao oficial: "Cartas que frequentemente mudam o rumo da partida
sozinhas, exigindo resposta imediata ou gerando vantagem desproporcional."

## Categorias de Impacto

| Categoria | Descricao | Exemplos |
|:----------|:----------|:---------|
| fast_mana | Mana acelerada muito acima da curva | Ancient Tomb, Chrome Mox, Mana Vault |
| tutor | Busca cartas especificas | Demonic Tutor, Vampiric Tutor |
| card_advantage | Vantagem de cartas desproporcional | Rhystic Study, The One Ring |
| free_interaction | Spells gratis | Force of Will, Fierce Guardianship |
| board_wipe | Reset de mesa unilateral | Cyclonic Rift, Farewell |
| stax | Restringe oponentes | Drannith Magistrate, Opposition Agent |
| value_engine | Gera valor continuo | Seedborn Muse, Tergrid |
| combo_piece | Peca de combo eficiente | Thassa's Oracle, Underworld Breach |
| protection | Protecao absoluta | Teferi's Protection |

## Lista Completa (53 cartas)

A lista completa esta no banco SQLite:
scripts/knowledge.db -> tabela game_changers

Para consultar:
python3 -c "
import sqlite3, json
conn = sqlite3.connect('scripts/knowledge.db')
rows = conn.execute('SELECT card_name, impact_level, impact_category, price_usd, manaloom_detected FROM game_changers ORDER BY impact_level DESC, card_name').fetchall()
print(json.dumps([dict(r) for r in rows], indent=2))
conn.close()
"

## Status do SQLite

Tabela: game_changers (14 colunas)
Registros: 53 cartas inseridas
Campos: card_name, cmc, type_line, mana_cost, oracle_text, price_usd,
        impact_level, impact_category, why_game_changer,
        manaloom_bracket_category, manaloom_detected, restricted_bracket, notes

## O que o ManaLoom Ja Detecta

O `edh_bracket_policy.dart` ja cobre estes Game Changers indiretamente:

| Categoria Bracket | Cartas GC cobertas |
|:-----------------|:-------------------|
| fastMana | Ancient Tomb, Chrome Mox, Mox Diamond, Mana Vault, Grim Monolith, Lion's Eye Diamond |
| tutor | Demonic Tutor, Vampiric, Imperial, Mystical, Enlightened, Worldly, Gamble, Gifts, Intuition, Crop Rotation, Natural Order, Survival |
| freeInteraction | Force of Will, Fierce Guardianship |
| infiniteCombo | Thassa's Oracle, Underworld Breach, Panoptic Mirror |

**Nao detectados (29 de 53):** Rhystic Study, Smothering Tithe, Cyclonic Rift,
The One Ring, Consecrated Sphinx, Necropotence, Ad Nauseam, Gaea's Cradle,
Serra's Sanctum, Field of the Dead, Mishra's Workshop, Teferi's Protection,
Seedborn Muse, e todos os stax pieces.

## Proximo Passo

Os crons vao pesquisar cada carta individualmente (1 por execucao),
documentando o why_game_changer e notes no SQLite.

## Progresso (2026-05-27)

| Status | Count |
|:-------|:-----:|
| Total GCs | 53 |
| With full analysis | 4/53 |
| Remaining | 49 |
| Detected by ManaLoom | 24/53 |

### Analise anterior: Ad Nauseam (2026-05-27)
- **Impact:** 9/10 (`card_advantage`)
- **Fonte Scryfall:** `https://api.scryfall.com/cards/search?q=!%22Ad%20Nauseam%22&unique=cards` retornou `game_changer=true`, `type_line=Instant`, `mana_cost={3}{B}{B}`, `cmc=5.0`, Commander `legal`, `edhrec_rank=1312`, `price_usd=16.21`, e oracle text: "Reveal the top card of your library and put that card into your hand. You lose life equal to its mana value. You may repeat this process any number of times."
- **Fonte EDHREC:** `https://edhrec.com/cards/ad-nauseam` reportou recomendacoes baseadas em **105,733 Ad Nauseam decks**. O painel Top Commanders mostrou Kraum, Ludevic's Opus // Tymna the Weaver em **77.99% de 11,217 decks (8,748)** e Rograkh, Son of Rohgahh // Silas Renn, Seeker Adept em **88.12% de 8,107 decks (7,144)**.
- **Fonte cEDH:** `https://cedh-decklist-database.com/` continha entrada **Rograkh Silas Turbo Naus** com texto "Turbo Ad Nauseam Rograkh Silas Storm Combo". Links Moxfield derivados da DDB confirmaram Ad Nauseam em listas publicas `[Primer] cEDH Rog Grixis Turbo` (`https://moxfield.com/decks/yRsS18tYsE-jVgqmK7_Z0w`, autoBracket 4, 135,239 views) e `[cEDH] Rograkh Silas Storm Combo` (`https://moxfield.com/decks/79hYZQUBdUaA9xD8zLX4vQ`, autoBracket 4, 177,057 views).
- **Bracket oficial:** Scryfall search `is:gamechanger !"Ad Nauseam"` mostrou a carta na Commander Game Changer list; a URL solicitada `https://mtgcommander.net/index.php/brackets/` retornou Page not found nesta execucao, entao o texto especifico da pagina oficial de brackets fica **NAO VERIFICADO**.
- **ManaLoom bracket:** `tagCardForBracket()` em `server/lib/edh_bracket_policy.dart` com o oracle text do Scryfall retornou `NO_CATEGORIES`. Resultado registrado no SQLite: `manaloom_detected=0`, `manaloom_bracket_category=card_advantage_gap`.
- **Discrepancy:** a politica atual cobre `fastMana`, `tutor`, `freeInteraction`, `extraTurns` e `infiniteCombo`, mas nao tem categoria para card-advantage explosivo / draw burst Game Changer como Ad Nauseam.

### Ultima analise SQLite: Rhystic Study (2026-05-27)
- **Impact:** 10/10 (`card_advantage`)
- **Fonte Scryfall:** `https://api.scryfall.com/cards/named?exact=Rhystic%20Study` retornou `game_changer=true`, `type_line=Enchantment`, `mana_cost={2}{U}`, `cmc=3.0`, Commander `legal`, `edhrec_rank=41`, `price_usd=69.44`, `rarity=rare`, `oracle_text="Whenever an opponent casts a spell, you may draw a card unless that player pays {1}."`
- **Fonte EDHREC:** `https://edhrec.com/cards/rhystic-study` — aparece em 1.010.475 decks (~23% do formato EDHREC). Inclusao por comandante: 91% em spellslinger, 88% em draw synergy (Niv-Mizzet), 67-71% em control/midrange, 47-58% em genericos, 21-37% em decks onde azul e secundario. Preco: $70.20 USD.
- **Fonte ManaLoom:** `tagCardForBracket()` em `server/lib/edh_bracket_policy.dart` com oracle text retornou `NO_CATEGORIES`. Rhystic Study nao se encaixa nas 5 categorias atuais (fastMana, tutor, freeInteraction, extraTurns, infiniteCombo). `manaloom_detected=0`, `manaloom_bracket_category=card_advantage`.
- **Bracket oficial:** Scryfall `is:gamechanger !"Rhystic Study"` confirmou GC. URL brackets mtgcommander.net retornou Page not found. Texto oficial = **NAO VERIFICADO**.
- **Restricao oficial:** PROIBIDO bracket 1-2, max 3 em bracket 3, sem limites bracket 4 (cEDH).
- **Discrepancy:** mesmo sendo o king do draw passivo em Commander (23% do formato), o sistema de brackets do ManaLoom nao o detecta por falta de categoria `card_advantage`. Necessario adicionar sexta categoria.

### Analise anterior: Cyclonic Rift (2026-05-27)
- **Impact:** 10/10 (`board_wipe`)
- **Fonte Scryfall:** `https://api.scryfall.com/cards/named?exact=Cyclonic%20Rift` retornou `game_changer=true`, `security_stamp=oval`, `type_line=Instant`, `mana_cost={1}{U}`, `cmc=2.0`, Commander `legal`, `price_usd=41.26`, `rarity=mythic`, e oracle text: "Return target nonland permanent you don't control to its owner's hand. Overload {6}{U} (You may cast this spell for its overload cost. If you do, change 'target' in its text to 'each.'")".
- **Fonte Edhrec (artefatos do projeto):** Cyclonic Rift aparece em 69 artefatos JSON do projeto MTGIA. Confirmado como interação esperada nos perfis EDHREC de Yuriko (pacote `interaction`), Kinnan (pacote `tutors_interaction`), Niv-Mizzet (4 temas de corpus EDHREC), e mais (Aesi, Miirym, Atraxa, Urza). Perfis de `commander_reference_profile_anchor30_batch_a_2026-05-12` e `batch_b_2026-05-12`.
- **Fonte ManaLoom:** `tagCardForBracket()` em `server/lib/edh_bracket_policy.dart` com oracle text do Scryfall retornou `NO_CATEGORIES`. Cyclonic Rift não é fastMana (não está na lista curada), não é tutor (não contém "search your library"), não é freeInteraction (não tem "rather than pay" / pitch pattern), não é extraTurns, não é infiniteCombo. Resultado: `manaloom_detected=0`, `manaloom_bracket_category=board_wipe_gap`.
- **Bracket oficial:** Scryfall search `is:gamechanger !"Cyclonic Rift"` confirmou a carta na Commander Game Changer list; a URL solicitada `https://mtgcommander.net/index.php/brackets/` retornou Page not found nesta execucao, entao o texto especifico da pagina oficial de brackets fica **NAO VERIFICADO**.
- **Discrepancy:** a politica atual de bracket nao tem categoria para `board_wipe` unilateral. Cyclonic Rift é o único mass bounce unilateral do jogo e não se encaixa em nenhuma das 5 categorias atuais. Necessário adicionar categoria `board_wipe` ao `BracketCategory` enum e heurística para board wipes assimétricas/destrutivas em `tagCardForBracket()`.
- **Nota:** ManaLoom detecta Cyclonic Rift como interação (pacote `interaction` nos profiles), mas não a reconhece como Game Changer. O bracket system e o sistema de functional_tags operam em camadas diferentes.