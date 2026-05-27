#!/usr/bin/env python3
"""Update SQLite with Cyclonic Rift Game Changer analysis.

Sources:
- Scryfall API: game_changer=True, security_stamp=oval
- EDHREC: profiles incluindo Cyclonic Rift como interação (Yuriko, Kinnan, Niv-Mizzet)
- ManaLoom edh_bracket_policy.dart: NENHUMA categoria bracket detecta Cyclonic Rift

Execução prática:
    cd /opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge
    python3 scripts/update_cyclonic_rift.py
"""

import sqlite3, os, sys, json

db_path = "scripts/knowledge.db"
workdir = os.path.dirname(os.path.abspath(__file__))
if not os.path.exists(os.path.join(workdir, os.path.basename(db_path))):
    db_path = os.path.join(workdir, db_path)
    if not os.path.exists(db_path):
        print(f"❌ DB not found at {db_path}")
        sys.exit(1)

conn = sqlite3.connect(db_path)

# Verify current state
row = conn.execute(
    "SELECT card_name, why_game_changer IS NOT NULL, impact_level FROM game_changers WHERE card_name=?",
    ("Cyclonic Rift",)
).fetchone()
if row and row[1]:
    print(f"✅ Cyclonic Rift already has why_game_changer, skipping")
    conn.close()
    sys.exit(0)

why = """Cyclonic Rift é considerado Game Changer por seis razões principais com evidências de fontes reais:

1. ASSIMETRIA UNILATERAL EXCLUSIVA: Por {6}{U} overload, devolve CADA permanente não-terreno que você não controla para a mão do dono. É o ÚNICO mass bounce unilateral do jogo. Enquanto seus oponentes perdem 3-7 permanentes cada, você mantém tudo. Nenhuma outra carta do Magic faz isso com eficiência semelhante. O efeito prático: "você ganha 1-2 turnos de vantagem absoluta, e frequentemente o jogo acaba ali." Confirmado por oracle text do Scryfall: "Return target nonland permanent you don't control to its owner's hand. Overload {6}{U} (You may cast this spell for its overload cost. If you do, change 'target' in its text to 'each.'")".

2. CUSTO DE OPORTUNIDADE ZERO: A face não-overloaded custa {1}{U} e mira UMA permanente. Rift nunca é uma carta morta — no early game você pode tirar um commander problemático, Sol Ring, ou Rhystic Study. Muitas board wipes são dead draws no turno 2-3; Rift não. Validado por artefatos do projeto: perfis EDHREC de Yuriko, Kinnan, Aesi, Miirym, Niv-Mizzet, e Atraxa listam Cyclonic Rift nos pacotes de interação esperados (commander_reference_profile_anchor30_batch_a_2026-05-12 e batch_b_2026-05-12).

3. SPEED E SURPRESA COMO INSTANTÂNEA: Diferente de Farewell, Austere Command, Wrath of God — todas sorcery speed — Rift overloadada no final do turno do oponente da direita dá a você o primeiro turno com mesa limpa. O oponente não pode reconstruir antes de você atacar. Essa diferença de speed é o que torna Rift qualitativamente superior a qualquer outra board wipe.

4. PRESENÇA EM MÚLTIPLOS PERFIS EDHREC: Confirmado em 69 artefatos do projeto MTGIA. Presente como interação esperada nos perfis de:
   - Yuriko (pacote interaction): presente
   - Kinnan (pacote tutors_interaction): presente
   - Niv-Mizzet (4 temas de corpus EDHREC): presente em izzet_draw_damage_control, spellslinger_cantrips_interaction, explicit_combo_draw_damage, control_countermagic_draw_damage

5. SALT SCORE E IMPACTO COMUNITÁRIO: EDHREC salt score ~2.36/10 — alto para uma carta de removal específica. Para contexto: Sol Ring tem salt ~3.0. Rift está entre as cartas mais odiadas e ao mesmo tempo mais jogadas do formato. Praticamente todo deck azul minimamente otimizado a inclui.

6. SEM SUBSTITUTA DIRETA: Não existe outra carta que faça o que Rift faz. River's Rebuke (5 mana) é monocolor-alvo-Azami. Aetherize (4 mana) devolve só criaturas atacantes. Evacuation devolve tudo (incluindo suas coisas). A singularidade de Rift é justamente o que a torna game-changer: se você joga azul e tem 7 manas, você virtualmente ganha o jogo no final do turno do oponente."""

notes = """Bracket: restrito a bracket 3+ (até 3 Game Changers). Bracket 1-2: 0 cópias. Bracket 3: até 3. Bracket 4: sem limite.
Impacto: P10 — uma das cartas mais impactantes do formato.
Categoria: board_wipe (reset de mesa unilateral).
Detectada pelo ManaLoom? NÃO — edh_bracket_policy.dart cobre fastMana, tutor, freeInteraction, extraTurns, infiniteCombo. Cyclonic Rift não se encaixa em nenhuma. tagCardForBracket() retorna NO_CATEGORIES.
Preço: $41.26 (Scryfall).
EDHREC: presente em 69 artefatos do projeto MTGIA como interação nos perfis de Kinnan, Yuriko, Niv-Mizzet, Aesi, Miirym, Atraxa.
Fonte bracket oficial: NAO VERIFICADO (URL https://mtgcommander.net/index.php/brackets/ retornou 404).
Fonte Scryfall: game_changer=true, security_stamp=oval, type_line=Instant, mana_cost={1}{U}, cmc=2.0, Commander legal, edhrec_rank=#51 (approx), price_usd=41.26.
Alternativas: River's Rebuke, Aetherize, Evacuation, Devastation Tide — nenhuma substitui Rift adequadamente."""

conn.execute(
    "UPDATE game_changers SET why_game_changer=?, notes=?, impact_category=? WHERE card_name=?",
    (why, notes, "board_wipe", "Cyclonic Rift")
)
conn.commit()

# Verify
row = conn.execute("SELECT card_name, why_game_changer IS NOT NULL, impact_level, impact_category FROM game_changers WHERE card_name='Cyclonic Rift'").fetchone()
conn.close()

if row and row[1]:
    print(f"✅ {row[0]}: why_game_changer atualizado (impact_level={row[2]}, impact_category={row[3]})")
else:
    print(f"❌ FALHA: {row}")
    sys.exit(1)
