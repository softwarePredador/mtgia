#!/usr/bin/env python3
"""
Update Rhystic Study Game Changer analysis.
Sources: Scryfall API (game_changer=True), EDHREC (salt=2.73, num_decks=15794),
         Project artifacts (91+ files, 21 corpus entries)
"""

import sqlite3, sys, os

DB = "scripts/knowledge.db"
if not os.path.exists(DB):
    print(f"ERROR: {DB} not found")
    sys.exit(1)

why_game_changer_lines = []
why_game_changer_lines.append("Rhystic Study e o Game Changer definidor da categoria card_advantage no Commander. ")
why_game_changer_lines.append("E uma encantamento de {2}{U} que diz: "Whenever an opponent casts a spell, you may draw a card unless that player pays {1}." ")
why_game_changer_lines.append("Na pratica, isso significa que: (a) oponentes pagam 1 mana extra por spell ou voce compra uma carta; ")
why_game_changer_lines.append("(b) em mesas de 4 jogadores, voce compra 3+ cartas por ciclo completo de turnos; ")
why_game_changer_lines.append("(c) no late game, quando oponentes tem poucas terras extras, eles param de pagar e voce compra tudo. ")
why_game_changer_lines.append("")
why_game_changer_lines.append("O que torna Rhystic Study um Game Changer: ")
why_game_changer_lines.append("1. CARD ADVANTAGE DESPROPORCIONAL — Uma carta de {2}{U} que gera 3-6+ cartas por giro de mesa nao tem paralelo. ")
why_game_changer_lines.append("   Mystic Remora (o similar mais proximo) so compra no primeiro spell e tem cumulative upkeep. ")
why_game_changer_lines.append("   Rhystic Study nao tem upkeep e compra em TODAS as spells, inclusive as instantaneas dos oponentes. ")
why_game_changer_lines.append("2. TAXA IMPLICITA — O simples fato de estar na mesa custa 1 mana extra por spell a cada oponente. ")
why_game_changer_lines.append("   Isso e equivalente a um Thalia, Guardian of Thraben que afeta so os outros. ")
why_game_changer_lines.append("   Em pratica, e um stax piece disfarcado de card draw. ")
why_game_changer_lines.append("3. UNIVERSALIDADE — Aparece em todo deck azul de Commander independente do arquétipo. ")
why_game_changer_lines.append("   Dos projetos do ManaLoom: Kinnan, Atraxa, Yuriko, Muldrotha, Brago, Urza, Niv-Mizzet, ")
why_game_changer_lines.append("   Veyran — todos com Rhystic Study nos average decks EDHREC. ")
why_game_changer_lines.append("4. LOW CUSTO, ALTO RETORNO — CMC 3 e incrivelmente baixo para o que faz. ")
why_game_changer_lines.append("   Nao requer sinergia, nao requer comandante especifico, so precisa de {U} na pool. ")
why_game_changer_lines.append("5. SKEW DE HABILIDADE — O jogador habilidoso sabe quando forcar o oponente a pagar ")
why_game_changer_lines.append("   (quando ele precisa de mana para algo importante) e quando deixar comprar ")
why_game_changer_lines.append("   (quando a mana do oponente e mais valiosa que uma carta). ")
why_game_changer_lines.append("")
why_game_changer_lines.append("Evidencias de fontes reais:")
why_game_changer_lines.append("- Scryfall API: search 'is:gamechanger !"Rhystic Study"' -> 1 resultado, game_changer=True")
why_game_changer_lines.append("- EDHREC: salt=2.73/10 (extremamente salgado), num_decks=15.794, potential=42.251")
why_game_changer_lines.append("- Artefatos do projeto: 91+ arquivos, 21+ entradas em corpus EDHREC de 9+ comandantes diferentes")
why_game_changer_lines.append("- Preco medio: $69.44 USD — carta cara porque e essencial em azul")

why_game_changer = "\n".join(why_game_changer_lines)

notes_lines = []
notes_lines.append("Bracket: 3+ (oficial). Proibida em B1-2. Ate 3 em B3. Sem limite em B4.")
notes_lines.append("Alternativas de menor poder: Mystic Remora (cumulative upkeep, so primeiro spell),")
notes_lines.append("  Esper Sentinel (soldier trigger, so criaturas),")
notes_lines.append("  Archivist of Oghma (so busca de grimorio),")
notes_lines.append("  Ledger Shredder (connive, so jogador com CMC mais alto).")
notes_lines.append("Nenhuma alternativa chega perto da eficiencia de Rhystic Study.")
notes_lines.append("Alternativas de maior poder (cEDH): Mystic Remora e melhor em turnos 1-2,")
notes_lines.append("  mas Rhystic Study escala melhor nos turnos 3-7.")
notes_lines.append("Decks que mais usam (dados EDHREC): Kinnan, Atraxa, Yuriko, Urza, Brago, Niv-Mizzet.")
notes_lines.append("Fonte Scryfall: https://api.scryfall.com/cards/named?exact=Rhystic%20Study")
notes_lines.append("Fonte EDHREC: https://edhrec.com/cards/rhystic-study")
notes_lines.append("Gap ManaLoom: Nao detectada. Nao esta em tagCardForBracket() nem em listas curadas.")
notes_lines.append("  Precisa de categoria card_advantage ou gameChanger com lista curada das 53 cartas.")

notes = "\n".join(notes_lines)

# Connect with workaround for root-owned file
conn = sqlite3.connect(DB)
try:
    conn.execute("UPDATE game_changers SET "
                 "why_game_changer = ?, "
                 "notes = ?, "
                 "manaloom_bracket_category = ? "
                 "WHERE card_name = ?",
                 (why_game_changer, notes, "card_advantage_gap", "Rhystic Study"))
    conn.commit()
    print(f"Updated: {conn.execute('SELECT changes() FROM game_changers LIMIT 1').fetchone()[0]} rows affected")
    
    # Verify
    r = conn.execute("SELECT card_name, why_game_changer IS NOT NULL, manaloom_bracket_category, notes IS NOT NULL, impact_category "
                     "FROM game_changers WHERE card_name = 'Rhystic Study'").fetchone()
    print(f"Verification: {r[0]} | why_gc={'YES' if r[1] else 'NO'} | bracket={r[2]} | notes={'YES' if r[3] else 'NO'} | category={r[4]}")
    
    # Count remaining
    remaining = conn.execute("SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NULL").fetchone()[0]
    print(f"\nRemaining GCs without analysis: {remaining}/53")
    
except Exception as e:
    print(f"ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    conn.close()
