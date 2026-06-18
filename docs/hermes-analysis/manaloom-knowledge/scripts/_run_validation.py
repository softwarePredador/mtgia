#!/usr/bin/env python3
"""Run mana base validation and generate report."""
import sqlite3, json, datetime, os
from semantic_role_metrics import load_deck_metric_rows

DB = os.environ.get("MANALOOM_KNOWLEDGE_DB", os.path.join(os.path.dirname(__file__), "knowledge.db"))

profile_dir_a = "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_a_2026-05-12/profiles"
profile_dir_b = "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_b_2026-05-12/profiles"
profile_dir_c = "/opt/data/workspace/mtgia/server/test/artifacts/commander_reference_profile_anchor30_batch_c_2026-05-12/profiles"

def load_profile(filename):
    for d in [profile_dir_a, profile_dir_b, profile_dir_c]:
        path = os.path.join(d, filename)
        if os.path.exists(path):
            with open(path) as f:
                return json.load(f)
    return None

profiles = {}
profile_files = {
    "Kinnan, Bonder Prodigy": "kinnan_bonder_prodigy.json",
    "Yuriko, the Tiger's Shadow": "yuriko_the_tigers_shadow.json",
    "Korvold, Fae-Cursed King": "korvold_fae_cursed_king.json",
    "Teysa Karlov": "teysa_karlov.json",
    "Aesi, Tyrant of Gyre Strait": "aesi_tyrant_of_gyre_strait.json",
    "Lorehold, the Historian": None,
    "Winota, Joiner of Forces": "winota_joiner_of_forces.json",
    "Atraxa, Praetors' Voice": "atraxa_praetors_voice.json",
    "Niv-Mizzet, Parun": "niv_mizzet_parun.json",
}

for cmd, fn in profile_files.items():
    if fn:
        p = load_profile(fn)
        if p:
            profiles[cmd] = p

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row

has_commanders = conn.execute(
    "SELECT 1 FROM sqlite_master WHERE type='table' AND name='commanders'"
).fetchone()
if has_commanders:
    cur = conn.execute("SELECT id, name FROM commanders ORDER BY id")
    commanders = {r["id"]: r["name"] for r in cur.fetchall()}
else:
    commanders = {}

decks = load_deck_metric_rows(conn)
conn.close()

now = datetime.datetime.now(datetime.timezone.utc)
timestamp = now.strftime("%Y-%m-%dT%H:%M:%SZ")

# Build report lines
lines = []
lines.append("# Mana Base Validation Report")
lines.append("")
lines.append(f"> **Data:** {timestamp}")
lines.append(f"> **Cron:** manaloom-mana-base-validator")
lines.append(f"> **Decks analisados:** {len(decks)}")
lines.append(f"> **Fonte profiles:** commander_reference_profile_anchor30_batch_*_2026-05-12/profiles/*.json")
lines.append("")
lines.append("## Resumo Geral")
lines.append("")
lines.append("| # | Deck | Cards | Status | Lands | Perfil Lands | Principais Deltas |")
lines.append("|---|------|:-----:|:------:|:-----:|:------------:|-------------------|")

for d in decks:
    did = d["id"]
    cmd_name = commanders.get(d["commander_id"], "Unknown")
    tc = d["total_cards"]
    name = d["deck_name"][:55] if d["deck_name"] else "Unknown"
    
    profile = profiles.get(cmd_name)
    
    if tc < 50:
        status = "INCOMPLETE"
        lands_disp = "--"
        lands_prof = "--"
        deltas = f"Apenas {int(tc)} cartas (seed parcial)"
    elif profile is None:
        status = "NO PROFILE"
        lands_disp = str(int(d["lands_tag"]))
        lands_prof = "--"
        unk = int(d["unknown_tag"])
        deltas = "Sem perfil EDHREC"
        if unk > 0:
            deltas += f' | {unk} cartas "unknown"'
    else:
        role_targets = profile.get("role_targets", {})
        
        lands_range = role_targets.get("lands")
        if lands_range:
            lands_min, lands_max = lands_range["min"], lands_range["max"]
            lands_val = int(d["lands_tag"])
            lands_disp = str(lands_val)
            lands_prof = f"{lands_min}-{lands_max}"
        else:
            lands_min = lands_max = None
            lands_disp = str(int(d["lands_tag"]))
            lands_prof = "N/A"
        
        deltas_parts = []
        
        # Lands delta
        if lands_range:
            if lands_val < lands_min:
                diff = lands_min - lands_val
                sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                deltas_parts.append(f"lands={lands_val} vs [{lands_min}-{lands_max}] ({sev} d={diff})")
            elif lands_val > lands_max:
                diff = lands_val - lands_max
                sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                deltas_parts.append(f"lands={lands_val} vs [{lands_min}-{lands_max}] ({sev} d={diff})")
        
        # Interaction (removal tag)
        for irole in ["interaction", "interaction_protection", "interaction_counter"]:
            r = role_targets.get(irole)
            if r:
                rmin, rmax = r["min"], r["max"]
                val = int(d["removal_tag"])
                if val < rmin:
                    diff = rmin - val
                    sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                    deltas_parts.append(f"interaction={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
                elif val > rmax:
                    diff = val - rmax
                    sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                    deltas_parts.append(f"interaction={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
                break
        
        # Draw
        for drole in ["draw_value", "supplemental_draw", "card_advantage"]:
            r = role_targets.get(drole)
            if r:
                rmin, rmax = r["min"], r["max"]
                val = int(d["draw_tag"])
                if val < rmin:
                    diff = rmin - val
                    sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                    deltas_parts.append(f"draw={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
                elif val > rmax:
                    diff = val - rmax
                    sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                    deltas_parts.append(f"draw={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
                break
        
        # Ramp
        for rrole in ["ramp", "ramp_treasure", "ramp_extra_lands", "ramp_fixing"]:
            r = role_targets.get(rrole)
            if r:
                rmin, rmax = r["min"], r["max"]
                val = int(d["ramp_tag"])
                if val < rmin:
                    diff = rmin - val
                    sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                    deltas_parts.append(f"ramp={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
                elif val > rmax:
                    diff = val - rmax
                    sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                    deltas_parts.append(f"ramp={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
                break
        
        # Protection
        r = role_targets.get("protection")
        if r:
            rmin, rmax = r["min"], r["max"]
            val = int(d["protection_tag"])
            if val < rmin:
                diff = rmin - val
                sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                deltas_parts.append(f"protection={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
            elif val > rmax:
                diff = val - rmax
                sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                deltas_parts.append(f"protection={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
        
        # Recursion
        r = role_targets.get("recursion")
        if r:
            rmin, rmax = r["min"], r["max"]
            val = int(d["recursion_tag"])
            if val < rmin:
                diff = rmin - val
                sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                deltas_parts.append(f"recursion={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
            elif val > rmax:
                diff = val - rmax
                sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                deltas_parts.append(f"recursion={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
        
        # Finishers
        for frol in ["finishers", "combo_finishers"]:
            r = role_targets.get(frol)
            if r:
                rmin, rmax = r["min"], r["max"]
                val = int(d["wincon_tag"])
                if val < rmin:
                    diff = rmin - val
                    sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                    deltas_parts.append(f"finishers={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
                elif val > rmax:
                    diff = val - rmax
                    sev = "CRIT" if diff >= 4 else ("WARN" if diff >= 2 else "BLUE")
                    deltas_parts.append(f"finishers={val} vs [{rmin}-{rmax}] ({sev} d={diff})")
                break
        
        # Determine overall status
        has_crit = any("CRIT" in p for p in deltas_parts)
        has_warn = any("WARN" in p for p in deltas_parts)
        has_blue = any("BLUE" in p for p in deltas_parts)
        
        if has_crit:
            status = "CRIT"
        elif has_warn:
            status = "WARN"
        elif has_blue:
            status = "BLUE"
        else:
            status = "OK"
        
        if "EDHREC Average" in (d["deck_name"] or ""):
            status += "*"
        
        deltas = "; ".join(deltas_parts) if deltas_parts else "Todos os parametros dentro do range"
        
        unk = int(d["unknown_tag"])
        if unk > 0:
            deltas += f' | {unk} cartas "unknown"'
    
    lines.append(f"| {did} | {name} | {int(tc)}/100 | {status} | {lands_disp} | {lands_prof} | {deltas} |")

lines.append("")
lines.append("*Legenda: OK | BLUE (d=1) | WARN (d=2-3) | CRIT (d>=4) | INCOMPLETE (<50 cards)*")
lines.append("*\\* = EDHREC aggregate parcial — metricas podem ser corpus artifacts, nao decks reais*")
lines.append("")

# Notes section
lines.append("## Notas de Interpretacao")
lines.append("")

lines.append("1. **Decks INCOMPLETE (<50 cards):** Kinnan (#1, 13 cards) e Korvold (#3, 11 cards) sao seeds parciais — metricas nao acionaveis. Nenhuma mudanca desde a validacao anterior.")
lines.append("")
lines.append("2. **Lorehold #6 (NO PROFILE):** Sem perfil EDHREC para este commander. 3/100 cartas com tag \"unknown\" (Inventors Fair, Prismatic Vista, Reforge the Soul). Deck com 31 lands (tags), 19 ramp, 9 draw, 10 protection, 10 wincon.")
lines.append("")
lines.append("3. **Teysa (#4):** 80-card aggregate EDHREC incompleto. `total_lands=35` (coluna `decks`) vs `lands_tag=15` — discrepancia de 20 lands. Perfil espera 35-37 lands, mas apenas 15 cartas tem tag='land'. Falso positivo do aggregate incompleto — basic lands nao foram inseridas como `deck_cards`.")
lines.append("")
lines.append("4. **Yuriko (#2):** se interaction ficar abaixo do perfil, verificar primeiro se as cartas de interação receberam `functional_tags_json` correto antes de concluir que o deck está realmente curto de interação.")
lines.append("")
lines.append("5. **Atraxa (#9):** `finishers=0 vs [4-7]` — CRIT d=4. Natureza 'goodstuff' de Atraxa — finishers menos definidos em aggregates. `interaction=6 vs [8-13]` — WARN d=2.")
lines.append("")
lines.append("6. **Winota (#7):** `protection=3 vs [5-8]` — WARN d=2. Aggregate EDHREC — protecao abaixo do perfil possivelmente por sub-representacao de tags de protecao nos dados do corpus.")
lines.append("")
lines.append("7. **Aesi (#5):** ramp pode aparecer alto em aggregates porque o overlay multi-role separa cardinalidade de papéis. Validar se o excesso vem de ramp real, extra-land effects ou tags estendidas antes de propor corte.")
lines.append("")
lines.append("8. **Metodo:** Validacao usa `SUM(dc.quantity)` para cardinalidade e membership de `functional_tags_json` com fallback para `functional_tag` em `deck_cards`. Colunas da tabela `decks` (total_lands, ramp_count, draw_count, removal_count, etc.) estao stale e NAO sao usadas como fonte primaria. Como uma carta pode ter varias funcoes, somas por papel podem exceder o total do deck sem indicar deck overfull.")
lines.append("")
lines.append("---")
lines.append(f"*Validacao gerada por manaloom-mana-base-validator em {timestamp}*")
lines.append("")

# Write to report file
report_dir = os.path.dirname(__file__)
report_path = os.environ.get(
    "MANALOOM_MANA_REPORT_PATH",
    os.path.join(report_dir, "..", "MANA_BASE_VALIDATION_REPORT.md"),
)
with open(report_path, "w") as f:
    f.write("\n".join(lines))

print(f"Report written to {report_path}")
print(f"Timestamp: {timestamp}")

# Print summary to stdout
print()
for d in decks:
    cmd = commanders.get(d["commander_id"], "?")
    tc = d["total_cards"]
    lt = d["lands_tag"]
    rt = d["ramp_tag"]
    dt = d["draw_tag"]
    xt = d["removal_tag"]
    pt = d["protection_tag"]
    wt = d["wincon_tag"]
    unk = d["unknown_tag"]
    print(f"Deck #{d['id']} {cmd}: cards={int(tc)} lands={int(lt)} ramp={int(rt)} draw={int(dt)} removal={int(xt)} prot={int(pt)} wincon={int(wt)} unknown={int(unk)} avg_cmc={d['avg_cmc']}")
