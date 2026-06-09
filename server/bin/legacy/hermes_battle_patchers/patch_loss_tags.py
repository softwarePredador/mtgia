#!/usr/bin/env python3
"""Patch battle_analyst_v8.py: adiciona root-cause loss tagging.

Adiciona tracking de dados durante o jogo e classifica cada derrota
com tags: screw, flood, out-comboed, out-valued, bad-mulligan, commander-removed.
"""

import os, re

TARGET = "/opt/data/workspace/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v8.py"
BACKUP = TARGET + ".bak_loss_tags"

if not os.path.exists(BACKUP):
    with open(TARGET) as f:
        original = f.read()
    with open(BACKUP, "w") as f:
        f.write(original)
    print("Backup: " + BACKUP)
else:
    with open(BACKUP) as f:
        original = f.read()
    with open(TARGET, "w") as f:
        f.write(original)
    print("Restored from backup")

with open(TARGET) as f:
    content = f.read()

changes = 0

# ── 1. Add tracking to Player.__init__ ──────────────────────────
old_init = """        self.life_cant_change = False
        self.eliminated = False"""
new_init = """        self.life_cant_change = False
        self.eliminated = False
        # Loss tracking stats
        self.total_mana_produced = 0
        self.nonland_spells_cast = 0
        self.mulligan_count = 0
        self.commander_times_cast = 0
        self.commander_times_removed = 0
        self.opponent_combo_detected = False
        self.max_life_lost_in_one_turn = 0"""
if old_init in content:
    content = content.replace(old_init, new_init)
    changes += 1
    print("1. Added Player tracking vars")

# ── 2. Track mana production in Player.play_mana_source ─────────
old_mana = """            self.mana_pool.add(color, produced)
            emit_replay_event("mana_produced", player=self.name, color=color, amount=produced, source=source_name,
            mana_pool=self.mana_pool.snapshot(),"""
if old_mana in content:
    new_mana = """            self.total_mana_produced += produced
            self.mana_pool.add(color, produced)
            emit_replay_event("mana_produced", player=self.name, color=color, amount=produced, source=source_name,
            mana_pool=self.mana_pool.snapshot(),"""
    content = content.replace(old_mana, new_mana)
    changes += 1
    print("2. Added mana tracking")

# ── 3. Track mulligans ──────────────────────────────────────────
old_mulligan = "def play_mulligan(player, rng):"
if old_mulligan in content:
    new_mulligan = "def play_mulligan(player, rng):\n    player.mulligan_count += 1"
    content = content.replace(old_mulligan, new_mulligan)
    changes += 1
    print("3. Added mulligan tracking")

# ── 4. Track commander cast ─────────────────────────────────────
old_cmd = "player.commander_cast_count += 1"
if old_cmd not in content:
    # Find commander cast logic
    old_cmd2 = "emit_replay_event(\"commander_cast\""
    if old_cmd2 in content:
        # Find the line before this
        idx = content.find(old_cmd2)
        before = content[idx-200:idx]
        if "commander_zone_moves" in before:
            content = content.replace(old_cmd2, 'player.commander_times_cast += 1\n            emit_replay_event("commander_cast"')
            changes += 1
            print("4. Added commander cast tracking")

# ── 5. Track commander removed ──────────────────────────────────
old_cmd_remove = "emit_replay_event(\"commander_zone_move\""
if old_cmd_remove in content:
    # Find the one where it goes back to command zone
    idx = content.find(old_cmd_remove)
    zone_block = content[idx:idx+200]
    if "command" in zone_block.lower():
        content = content.replace(old_cmd_remove, 'player.commander_times_removed += 1\n                emit_replay_event("commander_zone_move"', 1)
        changes += 1
        print("5. Added commander removed tracking (partial)")

# ── 6. Track nonland spells cast ────────────────────────────────
old_spell = "emit_replay_event(\"spell_cast\""
if old_spell in content:
    # Count: find all spell_cast for nonland, add counter for lorehold player
    # Simpler approach: add after spell_resolved for nonland
    old_resolved = "emit_replay_event(\"spell_resolved\""
    if old_resolved in content:
        content = content.replace(old_resolved, 'player.nonland_spells_cast += 1\n                emit_replay_event("spell_resolved"')
        changes += 1
        print("6. Added spell tracking")

# ── 7. Add classify_loss function ───────────────────────────────
loss_func = """
def classify_loss(player, opponents, turn, result, reason):
    tags = []

    if result != "loss":
        return tags

    # Screw: morreu sem nunca ter 4+ mana disponivel
    if player.total_mana_produced < 4:
        tags.append("screw")

    # Flood: morreu com 12+ mana mas jogou <= 3 nao-terrenos
    elif player.total_mana_produced >= 12 and player.nonland_spells_cast <= 3:
        tags.append("flood")

    # Bad mulligan: mulligan >= 2 e morreu antes do turno 6
    if player.mulligan_count >= 2 and turn < 6:
        tags.append("bad-mulligan")

    # Commander removed: commander foi removido 3+ vezes
    if player.commander_times_removed >= 3:
        tags.append("commander-removed")

    # Out-comboed: oponentes executaram combo (2+ spells no mesmo turno causando kill)
    if player.opponent_combo_detected:
        tags.append("out-comboed")

    # Out-valued: jogo longo (turno 10+), morreu sem ser combo
    if turn >= 10 and "out-comboed" not in tags and "screw" not in tags and "flood" not in tags:
        tags.append("out-valued")

    if not tags:
        tags.append("combat-damage")

    return tags

"""

# Insert before simulate_game_v8
old_sim = "def simulate_game_v8("
if old_sim in content:
    content = content.replace(old_sim, loss_func + "\n" + old_sim)
    changes += 1
    print("7. Added classify_loss function")

# ── 8. Call classify_loss in simulate_game_v8 ───────────────────
# Modify the loss return to include tags
old_ret_loss = 'return "loss", turn, "life_zero"'
new_ret_loss = 'loss_tags = classify_loss(lorehold, opponents, turn, "loss", "life_zero"); return "loss", turn, "life_zero|tags=" + "+".join(loss_tags)'
if old_ret_loss in content:
    content = content.replace(old_ret_loss, new_ret_loss)
    changes += 1
    print("8. Added loss tag to life_zero return")

old_ret_loss2 = 'return "loss", turn, f"life_zero|found='
if old_ret_loss2 in content:
    new_ret_loss2 = 'loss_tags = classify_loss(lorehold, opponents, turn, "loss", "life_zero"); return "loss", turn, f"life_zero|tags={"+".join(loss_tags)}|found='
    content = content.replace(old_ret_loss2, new_ret_loss2)
    changes += 1
    print("8b. Added loss tag to approach loss return")

# ── 9. Also tag stall as its own category ────────────────────────
# Nothing needed for stall - it's not a loss

with open(TARGET, "w") as f:
    f.write(content)

print(f"\nTotal changes: {changes}")
print("DONE - battle_analyst_v8.py patched with loss tags")
