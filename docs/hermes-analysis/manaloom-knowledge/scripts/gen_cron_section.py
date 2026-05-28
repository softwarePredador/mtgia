#!/usr/bin/env python3
"""Generate compact Mana Base Validation section for CRON_STATUS.md."""
import json

with open("/tmp/validation_results.json") as f:
    results = json.load(f)

status_icons = {"CRIT": "CRIT", "WARN": "WARN", "BLUE": "BLUE", "OK": "OK"}

def si(s):
    return {"OK": "OK", "BLUE": "BLUE", "WARN": "WARN", "CRIT": "CRIT", "INFO": "INFO"}.get(s, s)

def full_icon(s):
    return {"OK": "OK", "BLUE": "BLUE V", "WARN": "WARN", "CRIT": "CRIT", "INFO": "--"}.get(s, s)

lines = []
lines.append("## Mana Base Validation Report")
lines.append("")
lines.append("> **Ultima execucao:** 2026-05-28T04:21Z (cron `manaloom-mana-base-validator`)")
lines.append(f"> **Decks analisados:** {len(results)}")
lines.append("> **Nota:** Lorehold (deck 6) nao possui perfil de referencia no diretorio de artifacts — sem validacao de role_targets.")
lines.append("")
lines.append("### Resumo")
lines.append("")
lines.append("| Deck | Commander | Status | Total Cards | DB Lands | SQLite Lands | Profile Lands | Problemas |")
lines.append("|------|-----------|--------|-------------|----------|--------------|---------------|-----------|")

for r in results:
    dk = r['deck_id']
    dn = r['deck_name']
    cmd_name = r['profile_key'] if r['profile_key'] else "N/A"
    st = full_icon(r['overall_status'])
    tc = r['sqlite_total']
    dbl = r['db_total_lands']
    sql = r['sqlite_lands']
    pl = r['profile_lands'] or "N/A"
    issues = []
    for ci in r['crit_issues']:
        issues.append("CRIT: " + ci[:55])
    for wi in r['warn_issues']:
        issues.append("WARN: " + wi[:55])
    for bi in r['blue_issues']:
        issues.append("BLUE: " + bi[:55])
    issues_str = "; ".join(issues) if issues else "(nenhum)"
    deck_label = f"{dk} — {dn[:28]}"
    lines.append(f"| {deck_label} | {cmd_name[:25]} | {st} | {tc} | {dbl} | {sql} | {pl} | {issues_str[:80]} |")

lines.append("")
lines.append("### Achados Criticos")
lines.append("")

crit_decks = [r for r in results if r['overall_status'] == 'CRIT']
incomplete = [r for r in results if r['sqlite_total'] < 100]
land_disc = [r for r in results if r['db_total_lands'] != r['sqlite_lands']]

lines.append(f"**{len(crit_decks)} decks com status CRITICO:**")
for r in crit_decks:
    lines.append(f"- Deck {r['deck_id']} ({r['deck_name']})")
lines.append("")

lines.append(f"**{len(incomplete)} decks incompletos (< 100 cartas):**")
for r in incomplete:
    lines.append(f"- Deck {r['deck_id']} ({r['deck_name']}): {r['sqlite_total']}/100 cartas")
lines.append("")

lines.append(f"**{len(land_disc)} decks com divergencia DB vs SQLite lands:**")
for r in land_disc:
    diff = r['sqlite_lands'] - r['db_total_lands']
    lines.append(f"- Deck {r['deck_id']} ({r['deck_name']}): DB={r['db_total_lands']}, SQLite={r['sqlite_lands']}, Diff={diff:+d}")
lines.append("")

lines.append("**Violecoes de role_targets (DB vs perfil):**")
lines.append("")
lines.append("| Deck | Role | DB Valor | Perfil Range | Status |")
lines.append("|------|------|----------|--------------|--------|")
for r in results:
    for pc in r.get('profile_checks', []):
        if pc['status'] in ('CRIT', 'WARN', 'BLUE') and pc['db_val'] is not None:
            st = full_icon(pc['status'])
            lines.append(f"| {r['deck_id']} - {r['deck_name'][:20]} | {pc['role']} | {pc['db_val']} | [{pc['prof_min']}-{pc['prof_max']}] {pc['direction']} | {st} |")
lines.append("")

lines.append("### Divergencias Lands DB vs SQLite")
lines.append("")
lines.append("| Deck | DB total_lands | SQLite lands | Diferenca | Status |")
lines.append("|------|----------------|--------------|------------|--------|")
for r in results:
    diff = r['sqlite_lands'] - r['db_total_lands']
    if diff == 0:
        icon = "OK"
    elif abs(diff) >= 4:
        icon = "CRIT"
    elif abs(diff) >= 2:
        icon = "WARN"
    else:
        icon = "BLUE"
    lines.append(f"| {r['deck_id']} - {r['deck_name'][:25]} | {r['db_total_lands']} | {r['sqlite_lands']} | {diff:+d} | {icon} |")

lines.append("")
lines.append("### Mudancas desde ultima validacao (03:25Z)")
lines.append("")
lines.append("- **Sem mudancas estruturais**: todos os decks mantem os mesmos totais de cartas e lands desde a validacao anterior.")
lines.append("- **Decks 1, 2, 3, 4** continuam com dados incompletos ou parciais nas tabelas (insert parcial durante import anterior).")
lines.append("- **Deck 2 (Yuriko):** DB total_cards=84 mas SQLite SUM=99 — dado desatualizado no DB.")
lines.append("- **Nenhum novo deck inserido ou removido** desde ultima validacao.")
lines.append("")

section = "\n".join(lines)
with open("/tmp/mana_section.md", "w") as f:
    f.write(section)

print(f"Section generated: {len(section)} chars, {len(results)} decks")
