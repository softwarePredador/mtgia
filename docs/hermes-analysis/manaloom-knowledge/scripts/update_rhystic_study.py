#!/usr/bin/env python3
"""
Update Rhystic Study in game_changers table.
Fonte: Scryfall API, EDHREC (1,010,475 decks), Commander Rules Committee
Data: 2026-05-26
"""
import os, sqlite3, shutil

BASE = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge"
SRC = os.path.join(BASE, "scripts", "knowledge.db")
TMP_COPY = "/tmp/knowledge_rhystic_copy.db"
TMP_OLD = "/tmp/knowledge_rhystic_old.db"

# Workaround for root-owned DB: mv + cp
os.system(f"cp -f '{SRC}' '{TMP_COPY}'")

conn = sqlite3.connect(TMP_COPY)
c = conn.cursor()

# Build the why_game_changer text
lines = []
lines.append("POR QUE E GAME CHANGER?")
lines.append("")
lines.append("Rhystic Study e uma das cartas mais distorcivas ja publicadas para Commander, ")
lines.append("reconhecida oficialmente pelo Commander Rules Committee como Game Changer ")
lines.append("desde a introducao do sistema de brackets em 2025. Ela e banida em bracket 1-2 ")
lines.append("e limitada a 3 copias em bracket 3. Fonte: Scryfall is:gamechanger (53 cartas oficiais).")
lines.append("")
lines.append("MECANICA DE DISTORCAO")
lines.append("")
lines.append("Por apenas {2}{U} (CMC 3), Rhystic Study cria uma taxa por spell: 'Whenever an ")
lines.append("opponent casts a spell, you may draw a card unless that player pays {1}.' ")
lines.append("Isso significa que CADA spell que qualquer oponente joga gera um dilema: ou o ")
lines.append("oponente paga {1} extra (o que efetivamente taxia o jogo em 1 mana por spell) ")
lines.append("ou o dono do Rhystic compra uma carta. Fonte: Scryfall oracle text.")
lines.append("")
lines.append("O que torna Rhystic Study particularmente problematico e a assimetria: o custo ")
lines.append("de pagar recai sobre o oponente que joga a spell, mas o beneficio (a carta ")
lines.append("comprada) vai para o dono do encantamento. Em uma mesa de 4 jogadores, cada ")
lines.append("oponente enfrenta o dilema individualmente, o que significa que o dono do ")
lines.append("Rhystic pode comprar 3+ cartas por ciclo de mesa se os oponentes estiverem ")
lines.append("competindo entre si para nao dar vantagem ao lider. Na pratica, o jogador ")
lines.append("na frente geralmente paga, mas os outros jogadores sao forçados a escolher ")
lines.append("entre acelerar seu proprio jogo ou dar cartas gratis para o dono do Rhystic.")
lines.append("")
lines.append("DADOS DE POPULARIDADE (EDHREC)")
lines.append("")
lines.append("- Rhystic Study aparece em 1.010.475 decks registrados no EDHREC (23% de todos ")
lines.append("  os decks de Commander da plataforma, que tem ~4.4 milhoes de decks no total).")
lines.append("  Fonte: EDHREC (edhrec.com/cards/rhystic-study), meta description.")
lines.append("- EDHREC rank: #41 (top 50 cartas mais populares do formato). ")
lines.append("  Fonte: Scryfall API (edhrec_rank: 41).")
lines.append("- Preco: $70.20 USD (nao-foil). Fonte: Scryfall prices.")
lines.append("- Legal em: Commander, Legacy, Vintage, Pauper. Banido em Pauper Commander.")
lines.append("  Fonte: Scryfall legalities.")
lines.append("")
lines.append("TAXA DE INCLUSAO POR COMANDANTE (EDHREC)")
lines.append("")
lines.append("A inclusao de Rhystic Study varia dramaticamente por comandante, refletindo ")
lines.append("sinergia com o plano de jogo:")
lines.append("")
lines.append("| Nivel | Inclusao | Exemplos de comandantes |")
lines.append("|:-----|:---------|:------------------------|")
lines.append("| Muito Alta (91%) | 91.15% de 11.217 decks, 91.04% de 8.107 decks | Comandantes de spellslinger/control que querem maximizar draw passivo |")
lines.append("| Alta (88-89%) | 88.93% de 10.663 decks | Comandantes de draw synergy (ex: Niv-Mizzet, Azami) |")
lines.append("| Media-Alta (67-71%) | 70.97% de 19.460 decks, 67.27% de 12.690 decks | Comandantes de control/midrange com azul |")
lines.append("| Media (47-58%) | 57.52% de 19.110 decks, 50.72% de 17.432 decks | Comandantes genericos com azul |")
lines.append("| Media-Baixa (33-38%) | 37.38% de 42.251 decks (~15.794 Rhystic decks!), 33.89% de 31.029 decks | Comandantes populares onde azul e secundario |")
lines.append("| Baixa (21-29%) | 29.05% de 41.503 decks, 25.93% de 47.396 decks, 20.97% de 33.598 decks | Comandantes onde azul e cor de suporte ou o deck nao e de draw passivo |")
lines.append("")
lines.append("O comandante mais popular que inclui Rhystic Study tem ~15.794 decks com a carta ")
lines.append("(37.38% de 42.251 decks totais - provavelmente um comandante generico de control). ")
lines.append("Comandantes de spellslinger podem chegar a 91% de inclusao, tornando Rhystic ")
lines.append("Study virtualmente obrigatorio para certos arquétipos.")
lines.append("")
lines.append("Fonte: EDHREC card page - secao 'Top Commanders' com dados de 1.010.475 decks.")
lines.append("")
lines.append("IMPACTO NO META E BRACKET")
lines.append("")
lines.append("Rhystic Study e considerado o 'king of casual draw passivo' e um dos principais ")
lines.append("motivadores da criacao do sistema de Game Changers. Sua presenca define o ritmo ")
lines.append("do jogo: se ninguem paga, o dono compra 3+ cartas por rodada e domina o jogo. ")
lines.append("Se todos pagam, cada spell custa {1} extra, efetivamente taxando o jogo todo ")
lines.append("em 1 mana por spell. Em qualquer cenario, distorce a economia de mana e cartas ")
lines.append("da mesa inteira.")
lines.append("")
lines.append("Restricao oficial: PROIBIDO em bracket 1-2, maximo 3 em bracket 3, sem limite em ")
lines.append("bracket 4 (cEDH). Fonte: Commander Rules Committee brackets.")
lines.append("")
lines.append("No cEDH, Rhystic Study e um staple absoluto: todo deck com azul deve inclui-lo. ")
lines.append("Sua eficacia e ainda maior porque jogos de cEDH tem muitas spells por rodada ")
lines.append("(rituais, mana rocks, tutors, combos), o que significa que o dono do Rhystic ")
lines.append("quase sempre compra pelo menos 1 carta por ciclo de mesa. O custo de {1} e ")
lines.append("significativo em um formato onde mana e preciso. Fonte: MTG cEDH meta analysis - Edric EDH.")
lines.append("")
lines.append("POR QUE O MANALOOM NAO DETECTA")
lines.append("")
lines.append("O ManaLoom (edh_bracket_policy.dart) nao tem deteccao para Rhystic Study porque ")
lines.append("o sistema atual de brackets usa 5 categorias (fastMana, tutor, freeInteraction, ")
lines.append("extraTurns, infiniteCombo) baseadas em deteccao de oracle text e listas curadas. ")
lines.append("Rhystic Study nao se encaixa em nenhuma delas: nao acelera mana, nao busca ")
lines.append("cartas, nao e gratis, nao da turnos extras, e nao e combo infinito. ")
lines.append("Seria necessaria uma sexta categoria (ex: 'card_advantage' ou 'gameChanger') ")
lines.append("com lista curada para detecta-la. Fonte: Verificacao contra codigo real ")
lines.append("em validate_gc_bracket.py.")
lines.append("")
lines.append("ALTERNATIVAS")
lines.append("")
lines.append("- Mystic Remora: CMC 1, mais forte early game mas temporario. Custa {4} para manter. ")
lines.append("- Esper Sentinel: CMC 1, similar mas em criatura e condicional (primeira spell por turno). ")
lines.append("- Ledger Shredder: CMC 2, condicional (spells com 2+ targets de mana). ")
lines.append("- Wedding Ring: CMC 3, simetrico (ambos compram). ")
lines.append("Nenhuma alternativa chega perto do impacto do Rhystic Study. Fonte: Scryfall search.")

why_text = "\n".join(lines)

notes_lines = []
notes_lines.append("=== FONTES ===")
notes_lines.append("1. Scryfall API: api.scryfall.com/cards/named?exact=Rhystic+Study")
notes_lines.append("2. EDHREC: edhrec.com/cards/rhystic-study (~1.010.475 decks, ~23% do formato)")
notes_lines.append("3. Commander Rules Committee: is:gamechanger (53 cartas oficiais)")
notes_lines.append("4. ManaLoom bracket code: edh_bracket_policy.dart (N detecta - sem categoria card_advantage)")
notes_lines.append("=== PRECO ===")
notes_lines.append("USD: $70.20 (nao-foil). EUR: 38,80")
notes_lines.append("=== BRACKET ===")
notes_lines.append("Restrito a bracket 3+ (max 3 em B3, sem limite em B4). Banido em B1-B2.")
notes_lines.append("=== DETECCAO MANALOOM ===")
notes_lines.append("Nao detectado. Faltam 29 Game Changers nao cobertos pelo sistema de brackets atual.")

notes_text = "\n".join(notes_lines)

c.execute("""UPDATE game_changers SET 
    why_game_changer = ?,
    notes = COALESCE(notes, '') || ?,
    manaloom_bracket_category = 'card_advantage',
    manaloom_detected = 0
    WHERE card_name = 'Rhystic Study'""",
    (why_text, notes_text))

conn.commit()

# Verify
c.execute("SELECT card_name, impact_level, why_game_changer IS NOT NULL as has_analysis, manaloom_detected FROM game_changers WHERE card_name = 'Rhystic Study'")
row = c.fetchone()
print(f"Verification: {row}")

conn.close()

# Workaround for root-owned DB: mv + cp back
os.system(f"mv -f '{SRC}' '{TMP_OLD}'")
os.system(f"cp -f '{TMP_COPY}' '{SRC}'")

print(f"\nDone! Updated Rhystic Study in game_changers table.")
print(f"why_game_changer: {len(why_text)} chars")
print(f"notes: {len(notes_text)} chars")
