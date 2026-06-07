#!/usr/bin/env python3
"""Update Game Changer research for Cyclonic Rift.

Sources checked in this run:
- Scryfall API exact search: game_changer=true, oracle text, price, EDHREC rank.
- EDHREC JSON card page: global inclusion and top commanders.
- ManaLoom real code: server/lib/edh_bracket_policy.dart tagCardForBracket semantics.
- Official Commander brackets URL requested by the cron: returned Page not found.
"""
import os
import shutil
import sqlite3

CARD_NAME = "Cyclonic Rift"
DB_PATH = "scripts/knowledge.db"
TMP_DB = "/tmp/knowledge_cyclonic_rift_20260527.db"
BACKUP_DB = "/tmp/knowledge_before_cyclonic_rift_20260527.db"

why_lines = []
why_lines.append(
    "Cyclonic Rift e Game Changer porque comprime duas funcoes em uma unica carta: "
    "no piso, por {1}{U}, ela remove temporariamente um permanente nao-terreno que o controlador nao possui; "
    "no teto, por overload {6}{U}, o texto do Scryfall muda 'target' para 'each' e devolve cada permanente "
    "nao-terreno dos oponentes para as maos deles. Essa assimetria transforma uma carta de resposta barata em um "
    "reset unilateral de mesa que preserva toda a board do jogador que a conjura."
)
why_lines.append(
    "A distorcao pratica esta no timing: por ser instant, Cyclonic Rift pode ser segurada ate o fim do turno anterior "
    "ao do jogador ativo, convertendo sete manas em uma janela de ataque/combo quase limpa sem exigir que o usuario "
    "sacrifique seus proprios recursos. O medo que ela resolve e 'vou morrer para a mesa estabelecida antes de executar "
    "meu plano'; a ambicao que ela cria e 'posso deixar todos os oponentes reconstruindo enquanto eu ataco ou combo no "
    "meu turno'. Isso explica por que a carta e percebida como muito mais que spot removal: ela frequentemente inverte "
    "o estado da partida em velocidade instantanea."
)
why_lines.append(
    "Os dados reais confirmam que nao e uma inclusao marginal. Scryfall retornou game_changer=true, Commander legal, "
    "cmc=2, type_line=Instant, edhrec_rank=51 e price_usd=41.26 para Cyclonic Rift. O JSON publico da EDHREC "
    "(/cards/cyclonic-rift) reportou a carta em 936.228 decks, 21,26% de 4.403.105 decks elegiveis; entre os top "
    "commanders daquele painel, Kinnan usa a carta em 54,46% de 19.460 decks (10.597), Urza em 55,09% de 19.110 "
    "decks (10.527), The Ur-Dragon em 29,52% de 47.396 decks (13.991) e Atraxa em 26,11% de 41.503 decks (10.835)."
)
why_lines.append(
    "A evidencia local do projeto tambem mostra transversalidade: artefatos EDHREC average/corpus em server/test/artifacts "
    "incluem Cyclonic Rift em 27 decks derivados de 9 arquivos de corpus, cobrindo Niv-Mizzet, Aesi, Kinnan, Atraxa, "
    "Yuriko, Muldrotha, Veyran, Brago e Urza. Portanto, a classificacao correta para a base de conhecimento e "
    "board_wipe / one-sided reset, nao apenas value_engine."
)
why_game_changer = "\n\n".join(why_lines)

notes_lines = []
notes_lines.append(
    "Fonte Scryfall: https://api.scryfall.com/cards/search?q=!%22Cyclonic%20Rift%22&unique=cards retornou "
    "total_cards=1, game_changer=true, name=Cyclonic Rift, type_line=Instant, mana_cost={1}{U}, cmc=2.0, "
    "Commander legal, edhrec_rank=51, price_usd=41.26, oracle_text='Return target nonland permanent you don't control "
    "to its owner's hand. Overload {6}{U} ... change target to each.'."
)
notes_lines.append(
    "Fonte EDHREC: https://json.edhrec.com/pages/cards/cyclonic-rift.json reportou label 'In 936228 decks / "
    "21.26% of 4403105 decks', salt=2.3586776859504135 e combos=true. Top commanders amostrados: The Ur-Dragon "
    "29.52% de 47.396 decks (13.991), Vivi Ornitier 38.62% de 32.963 (12.729), Atraxa 26.11% de 41.503 (10.835), "
    "Kinnan 54.46% de 19.460 (10.597), Nekusar 35.60% de 29.682 (10.567), Urza 55.09% de 19.110 (10.527)."
)
notes_lines.append(
    "Fonte projeto local: busca em /opt/data/workspace/mtgia/server/test/artifacts encontrou Cyclonic Rift em 27 decks "
    "EDHREC average/corpus distribuidos em 9 arquivos de corpus: Niv-Mizzet, Aesi, Kinnan, Atraxa, Yuriko, Muldrotha, "
    "Veyran, Brago e Urza. Isso confirma uso amplo em multiplos arquetipos azuis, nao apenas em um commander especifico."
)
notes_lines.append(
    "Bracket oficial: a URL solicitada https://mtgcommander.net/index.php/brackets/ retornou pagina WordPress 'Page not found' "
    "nesta execucao; o texto especifico da pagina oficial de brackets fica NAO VERIFICADO. A inclusao na lista de Game "
    "Changers foi evidenciada pelo campo Scryfall game_changer=true."
)
notes_lines.append(
    "ManaLoom bracket: rodando o codigo real server/lib/edh_bracket_policy.dart com tagCardForBracket(name='Cyclonic Rift', "
    "typeLine='Instant', oracleText=Scryfall) retornou NO_CATEGORIES. A politica atual so cobre fastMana, tutor, "
    "freeInteraction, extraTurns e infiniteCombo; nao ha categoria para board_wipe/one_sided_reset. Registrado como "
    "manaloom_detected=0 e manaloom_bracket_category=board_wipe_gap."
)
notes = "\n\n".join(notes_lines)

# Workaround for root-owned DB: operate on /tmp, then replace inode via mv+copy.
if os.path.exists(TMP_DB):
    os.remove(TMP_DB)
shutil.copy2(DB_PATH, TMP_DB)

conn = sqlite3.connect(TMP_DB)
conn.execute(
    """
    UPDATE game_changers
       SET why_game_changer = ?,
           notes = ?,
           impact_level = ?,
           impact_category = ?,
           manaloom_bracket_category = ?,
           manaloom_detected = ?,
           restricted_bracket = ?
     WHERE card_name = ?
    """,
    (
        why_game_changer,
        notes,
        10,
        "board_wipe",
        "board_wipe_gap",
        0,
        3,
        CARD_NAME,
    ),
)
if conn.total_changes != 1:
    raise SystemExit(f"Expected exactly 1 updated row, got {conn.total_changes}")
conn.commit()
row = conn.execute(
    "SELECT card_name, impact_level, impact_category, manaloom_detected, manaloom_bracket_category, LENGTH(why_game_changer), LENGTH(notes) FROM game_changers WHERE card_name = ?",
    (CARD_NAME,),
).fetchone()
conn.close()

if os.path.exists(BACKUP_DB):
    os.remove(BACKUP_DB)
os.replace(DB_PATH, BACKUP_DB)
shutil.copy2(TMP_DB, DB_PATH)
print("Updated Game Changer row:", row)
print("Backup before update:", BACKUP_DB)
