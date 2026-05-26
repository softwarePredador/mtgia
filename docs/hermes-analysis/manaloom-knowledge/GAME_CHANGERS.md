# Game Changers — Referencia Completa

> Analise completa dos 53 Game Changers oficiais do formato Commander.
> Fonte: Scryfall `is:gamechanger` + Commander Rules Committee bracket system.
> Ultima atualizacao: 2026-05-26

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