#!/usr/bin/env python3
"""Apply Evolution Oracle changes to Lorehold deck."""
import sqlite3, json
from datetime import datetime, timezone

conn = sqlite3.connect('scripts/knowledge.db')

# Get deck_id
did = conn.execute("""
    SELECT d.id FROM decks d JOIN commanders c ON c.id = d.commander_id
    WHERE c.name LIKE '%Lorehold%' ORDER BY d.id DESC LIMIT 1
""").fetchone()[0]
print(f"Lorehold deck ID: {did}")

changes = [
    ("Furygale Flocking", "Esper Sentinel", "draw"),
    ("Jokulhaups", "Gamble", "tutor"),
    ("Karoo", "Plains", "land"),
]

now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')
log = f"""# Evolution Log — Lorehold

## [{now}] Ciclo #1

### Primeiro ciclo completo do pipeline
- Scout: 4 rodadas em 2h, SCOUT_LOG.md
- Validator: 2 rodadas em 2h, VALIDATOR_LOG.md
- Mulligan: 1 rodada, MULLIGAN_LOG.md
- Evolution: 1a execucao

### Sintese dos Aprendizados

**SCOUT (3 decks EDHREC):**
- 4 staples 100% ausentes: Esper Sentinel, Dance with Calamity, Gamble, Hit the Mother Lode
- 30 cartas com 0% presenca externa — cortaveis
- Lands de referencia: fetch, dual, bond land

**VALIDATOR (metricas vs EDHREC):**
- 6 metricas 🟡 fora do range
- Lands 34 (min 36), Ramp 17 (max 13), Protection 7 (max 5), Wincons 3 (min 4)
- Draw=8 ✅, Recursion=5 ✅

**MULLIGAN (1000 simulacoes):**
- 70.1% jogaveis ✅
- 23.9% mulligan 🟡 (precisa +1-2 lands)
- 13.6% ramp T1 ✅, 3.3% sem play T3 ✅

### Mudancas Aplicadas (max 3)

"""

# Apply changes
for out_name, in_name, tag in changes:
    # Remove outgoing card
    conn.execute("DELETE FROM deck_cards WHERE deck_id = ? AND LOWER(card_name) = LOWER(?)", (did, out_name))
    
    # Check if incoming card already exists
    existing = conn.execute("SELECT id, quantity FROM deck_cards WHERE deck_id = ? AND LOWER(card_name) = LOWER(?)", (did, in_name)).fetchone()
    if existing:
        # Update quantity instead of inserting
        conn.execute("UPDATE deck_cards SET quantity = quantity + 1 WHERE id = ?", (existing[0],))
        print(f"  {in_name}: quantity updated to {existing[1]+1}")
    else:
        conn.execute("INSERT INTO deck_cards (deck_id, card_name, quantity, functional_tag, is_commander, cmc) VALUES (?, ?, 1, ?, 0, 0)", (did, in_name, tag))
    
    log += f"1. **SAI:** {out_name} → **ENTRA:** {in_name} ({tag})\n"
    log += f"   Justificativa: {out_name} com 0% presenca externa. {in_name} e staple 100% SCOUT.\n\n"

conn.commit()

# Verify count
total = conn.execute("SELECT SUM(quantity) FROM deck_cards WHERE deck_id = ?", (did,)).fetchone()[0]
log += f"### Contagem final: {total} cartas (confirmado)\n"
log += f"Status: {'✅ 100 cartas' if total == 100 else '🔴 {} cartas'.format(total)}\n\n"

log += """
### Impacto Esperado
- Lands: 34 → 35
- Draw: 8 → 9
- Board wipes: 6 → 5 (agora max 5 ✅)
- Tutor: 4 → 5
- Mulligan: esperado cair de 23.9% para ~20%

### Licoes Aprendidas
1. **Furygale Flocking (CMC 10):** CMC muito alto mesmo para big spells. Corte imediato.
2. **Jokulhaups (destroi lands):** Muito punitivo. Decks reais preferem Austere Command.
3. **Esper Sentinel (draw 1-drop):** Staple universal. Deveria ser auto-include em qualquer deck com branco.
4. **Gamble (tutor):** Tutor vermelho essencial para consistencia.

### Proximo Ciclo
- Adicionar Dance with Calamity e Hit the Mother Lode (sinergia Lorehold)
- Cortar Obliterate ou Season of the Bold
- Verificar se mulligan melhorou com +1 land
"""

print(f"Changes applied: {len(changes)}")
print(f"Total cards: {total}")

with open('decks/lorehold-the-historian/EVOLUTION_LOG.md', 'w') as f:
    f.write(log)
print("Evolution log saved to EVOLUTION_LOG.md")