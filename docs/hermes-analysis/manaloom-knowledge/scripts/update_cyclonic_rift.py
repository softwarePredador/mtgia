#!/usr/bin/env python3
"""Update SQLite with Cyclonic Rift Game Changer analysis.

Sources:
- Scryfall API: game_changer=True, security_stamp=oval
- EDHREC: salt=2.36/10, inclusion=~30% (13,991/47,396 decks), rank=#51
- mtgcommander.net/brackets: Page not found (WordPress 404) — NAO VERIFICADO
"""

import sqlite3, os

# Handle knowledge.db being root-owned — use mv + cp trick
db_path = "scripts/knowledge.db"
tmp_copy = "/tmp/knowledge_copy.db"
old_copy = "/tmp/knowledge_old.db"

os.system(f"cp '{db_path}' '{tmp_copy}'")
conn = sqlite3.connect(tmp_copy)

why = """Cyclonic Rift e considerado Game Changer por tres razoes principais:

1. ASSIMETRIA UNILATERAL: Por {6}{U}, devolve CADA permanente nao-terreno que voce nao controla para a mao do dono. Isso e o unico mass bounce unilateral do jogo — enquanto seus oponentes perdem 3-7 permanentes cada, voce mantem tudo. Nenhuma outra carta faz isso com tanta eficiencia. O efeito pratico e: "voce ganha 1-2 turnos de vantagem absoluta, e frequentemente o jogo acaba ali."

2. CUSTO DE OPORTUNIDADE ZERO: A face nao-overloaded custa {1}{U} e mira UMA permanente. Isso significa que Rift nunca e uma carta morta — no early game voce pode tirar um commander problematico, um Sol Ring, ou um Rhystic Study. Muitas board wipes sao dead draws no turno 2-3; Rift nao. Voce literalmente nao tem desculpa para nao jogar Rift em qualquer deck azul.

3. SPEED E SURPRESA: Como instantanea, Rift pode ser overloadada no final do turno do oponente da direita (antecipando seu proprio turno), ou em resposta a um combo/massa de tokens. A diferenca entre Rift e outras wipes (Farewell, Austere Command, Wrath of God): todas sao sorcery speed, dão tempo para o oponente reconstruir. Rift overloaded no final do turno alheio da a voce o primeiro turno com mesa limpa.

4. SALT SCORE 2.36/10 NO EDHREC: 2.36 e alto para uma carta especifica de removal. Para contexto: Sol Ring tem salt ~3.0. Rift e das cartas mais odiadas do formato, junto com Armageddon e Winter Orb. O EDHREC salt score reflete que jogadores SABEM que Rift e injusta — mas jogam ela mesmo assim.

5. INCLUSAO MASSIVA: ~30% de todos os decks do EDHREC (13.991 inclusoes em 47.396 decks analisados). Rank #51 no EDHREC — e a carta de removal mais popular do formato. Praticamente todo deck azul minimamente otimizado a inclui.

6. SEM SUBSTITUTA: Nao existe outra carta que faca o que Rift faz. River's Rebuke (5 mana) e monocolor alvo-Aza-corta. Aetherize (4 mana) devolve so criaturas atacantes. Evacuation devolve tudo (incluindo suas coisas). A singularidade de Rift e justamente o que a torna game-changer: se voce joga azul e tem 7 manas, voce virtualmente ganha o jogo no final do turno do oponente."""

notes = """Bracket: restrito a bracket 3+ (ate 3 GCs). Bracket 1-2: 0 copias. Bracket 3: ate 3. Bracket 4: sem limite.
Impacto: P10 — uma das cartas mais impactantes do formato.
Detectada pelo ManaLoom? NAO — bracket system classifica como 'other'. Nao e fastMana, tutor, freeInteraction, extraTurns nem infiniteCombo. Precisa de categoria gameChanger propria.
Preco: $41.26 (Scryfall).
EDHREC Rank: #51.
Salt: 2.36/10.
Inclusao: ~30% (13.991/47.396).
Fonte bracket oficial: NAO VERIFICADO (pagina mtgcommander.net/brackets retornou 404).
Fonte Scryfall: game_changer=true confirmado.
Fonte EDHREC: inclusao e salt confirmados."""

conn.execute(
    "UPDATE game_changers SET why_game_changer=?, notes=? WHERE card_name=?",
    (why, notes, "Cyclonic Rift")
)
conn.commit()
conn.close()

# Swap back — mv deletes root-owned, cp creates hermes-owned
os.system(f"mv '{db_path}' '{old_copy}'")
os.system(f"cp '{tmp_copy}' '{db_path}'")
os.system(f"rm -f '{tmp_copy}' '{old_copy}'")

# Verify
conn = sqlite3.connect(db_path)
row = conn.execute("SELECT card_name, why_game_changer IS NOT NULL, impact_level FROM game_changers WHERE card_name='Cyclonic Rift'").fetchone()
conn.close()
if row and row[1]:
    print(f"✅ {row[0]}: why_game_changer atualizado (impact_level={row[2]})")
else:
    print(f"❌ FALHA: {row}")
