#!/usr/bin/env python3
"""Update SQLite with Smothering Tithe Game Changer analysis.

Sources:
- Scryfall API: game_changer=True, cmc=4, mono-white enchantment
- EDHREC card page (2026-05-27): salt=2.58, num_decks=15,374, potential=42,251
- ManaLoom code analysis (edh_bracket_policy.dart, optimization_functional_roles.dart)
- Dart scryfall_classifier.py for functional tag classification
"""

import sqlite3, os

db_path = "scripts/knowledge.db"
tmp_copy = "/tmp/knowledge_copy.db"
old_copy = "/tmp/knowledge_old.db"

os.system(f"cp '{db_path}' '{tmp_copy}'")
conn = sqlite3.connect(tmp_copy)

why = """Smothering Tithe e considerada Game Changer por quatro razoes:

1. VANTAGEM PASSIVA INSTITUCIONALIZADA: Smothering Tithe muda a estrutura basica do jogo sem voce fazer nada. Enquanto oponentes compram cartas (a acao mais basica de Magic), eles pagam {2} para nao te dar um tesouro. Em uma mesa de Commander com 3 oponentes, cada draw de oponente e um Dilema do Prisioneiro: se todo mundo paga, voce ja esta na vantagem (oponentes gastaram 6 manas acumuladas no seu turno). Se alguem nao paga, voce fica com mais mana que o normal. A mana extra de tesouros brancos e o que torna mono-white viavel em Commander, mas distorce a balanca de poder.

2. POTENCIAL DE SNOWBALLING: Cada tesouro que voce nao gasta vira mana para ativar Tithe novamente no turno seguinte -- ou para pagar Rhystic Study, Mystic Remora, ou qualquer outra taxa. Smothering Tithe + Rhystic Study na mesma mesa e uma combinacao que praticamente paralyza o jogo: cada draw de oponente aciona ambos, drenando manas e gerando tesouros ao mesmo tempo. Uma vez que voce tem 4-5 tesouros, voce pode jogar qualquer spell, pagar qualquer taxa, e ainda ter mana sobrando.

3. SALT SCORE 2.58/10 NO EDHREC: 2.58 e altissimo para uma encantamento de 4 manas que nao faz nada no turno que entra. Significa que jogadores a consideram frustrante de jogar contra -- nao porque e forte de forma obvia, mas porque ela muda o ritmo do jogo de forma silenciosa. Uma Tithe que fica 3 turnos na mesa pode gerar 6-9 tesouros, o que e mais ramp que qualquer carta verde.

4. INCLUSAO MASSIVA: ~36% de todos os decks EDHREC (15.374 inclusoes em 42.251 decks potenciais). Para contexto, isso e maior que a taxa de inclusao de muitas cartas iconicas como Demonic Tutor ou Cyclonic Rift. Praticamente todo deck branco que pode incluir Tithe o faz -- so nao inclui quem nao tem {W} na identidade ou quem esta em bracket 1-2.

5. SEM SUBSTITUTA DIRETA: Nao existe outra carta que gere ramp passivo em branco na escala de Smothering Tithe. Monologue Tax (2W) cria um tesouro so quando um oponente conjura seu segundo feitico no turno -- muito mais restrito. Land Tax (W) busca terrenos basicos, nao da mana imediata. A singularidade de Tithe e justamente o que a torna game-changer: ela e a unica fonte de ramp passivo em branco que escala com o numero de oponentes.

6. PRECO ELEVADO: $53.94 USD (Scryfall). Cartas que custam mais de $50 sao barreiras de entrada. Nao e a mais cara, mas e cara o suficiente para criar um gap entre quem tem e quem nao tem."""

notes = """Bracket: restrito a bracket 3+ (ate 3 GCs). Bracket 1-2: 0 copias. Bracket 3: ate 3. Bracket 4: sem limite.
Impacto: P10 — uma das cartas mais impactantes do formato, especialmente em decks brancos.
Detectada pelo ManaLoom? NAO COMPLETAMENTE:
- Bracket system (edh_bracket_policy.dart): NAO detectada em NENHUMA categoria (fastMana, tutor, freeInteraction, extraTurns, infiniteCombo). Precisa de categoria gameChanger propria ou deteccao de "passive ramp" / "treasure generator".
- Single-tag classification (optimization_functional_roles.dart): Classificada como 'draw' porque oracle_text contem "draw a card" e o if-else da prioridade a draw sobre ramp. Isso e um falso positivo funcional — ela NAO compra cartas, ela REAGE a oponentes comprando. A tag correta seria ramp.
- Multi-tag (functional_card_tags.py): ramp (0.88), token_maker (0.82), sacrifice_outlet (0.80), artifact_synergy (0.74), engine (0.70). Nota: sacrifice_outlet (0.80) e falso positivo — o script detecta "Sacrifice" no texto do token, mas o outlet e do tesouro, nao um sacrifice outlet generico.
Preco: $53.94 (Scryfall, Commander Masters).
Salt EDHREC: 2.58/10 — muito alto para ramp passivo.
Inclusao EDHREC: ~36% (15.374/42.251 decks).
Fonte Scryfall: game_changer=true confirmado.
Fonte EDHREC: salt e inclusao confirmados via page scrape 2026-05-27.
Alternativas: Monologue Tax (mais fraco, so 1 tesouro por turno se oponente conjurar 2+), Boreas Charger (condicional), Land Tax (busca terrenos, nao ramp direta).
Nenhuma alternativa chega perto da eficiencia de Tithe."""

conn.execute(
    "UPDATE game_changers SET why_game_changer=?, notes=? WHERE card_name=?",
    (why, notes, "Smothering Tithe")
)
conn.commit()
conn.close()

# Swap back
os.system(f"mv '{db_path}' '{old_copy}'")
os.system(f"cp '{tmp_copy}' '{db_path}'")
os.system(f"rm -f '{tmp_copy}' '{old_copy}'")

# Verify
conn = sqlite3.connect(db_path)
row = conn.execute("SELECT card_name, why_game_changer IS NOT NULL, impact_level FROM game_changers WHERE card_name='Smothering Tithe'").fetchone()
conn.close()
if row and row[1]:
    print(f"✅ {row[0]}: why_game_changer atualizado (impact_level={row[2]})")
    # Check what's still missing
    conn2 = sqlite3.connect(db_path)
    missing = conn2.execute("SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NULL").fetchone()[0]
    filled = conn2.execute("SELECT COUNT(*) FROM game_changers WHERE why_game_changer IS NOT NULL").fetchone()[0]
    conn2.close()
    print(f"📊 Status: {filled}/53 GCs preenchidos, {missing} faltando")
else:
    print(f"❌ FALHA: {row}")
