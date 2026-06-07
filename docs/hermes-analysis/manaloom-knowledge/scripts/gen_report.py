#!/usr/bin/env python3
"""Generate full mana base validation report markdown."""
import json, sys

results_json = sys.stdin.read()
results = json.loads(results_json)

lines = []
lines.append("# Mana Base Validation Report")
lines.append("")
lines.append(f"**Generated:** 2026-05-28T04:21Z")
lines.append(f"**Decks analyzed:** {len(results)}")
lines.append(f"**Pipeline:** mana-base-validator (cron)")
lines.append("")

# Summary table
lines.append("## Summary Table")
lines.append("")
lines.append("| Deck | Commander | Status | Total Cards | DB Lands | SQLite Lands | Profile Lands | Issues |")
lines.append("|------|-----------|--------|-------------|----------|--------------|---------------|--------|")

status_icons = {"CRIT": "🔴 CRIT", "WARN": "🟡 WARN", "BLUE": "🔵 BLUE", "OK": "✅ OK"}

for r in results:
    dk = r['deck_id']
    dn = r['deck_name']
    pk = r['profile_key'] or "N/A"
    st = status_icons.get(r['overall_status'], r['overall_status'])
    tc = r['sqlite_total']
    dbl = r['db_total_lands']
    sql = r['sqlite_lands']
    pl = r['profile_lands'] or "N/A"
    issues = []
    if r['crit_issues']:
        issues.append(f"🔴 {len(r['crit_issues'])} crit")
    if r['warn_issues']:
        issues.append(f"🟡 {len(r['warn_issues'])} warn")
    if r['blue_issues']:
        issues.append(f"🔵 {len(r['blue_issues'])} blue")
    issues_str = "; ".join(issues) if issues else "none"
    lines.append(f"| {dk} — {dn[:30]} | {pk[:25]} | {st} | {tc} | {dbl} | {sql} | {pl} | {issues_str} |")

lines.append("")

# Detailed per-deck analysis
lines.append("## Detailed Per-Deck Analysis")
lines.append("")

for r in results:
    lines.append(f"### Deck {r['deck_id']}: {r['deck_name']}")
    lines.append("")
    lines.append(f"- **Commander ID:** {r['cmd_id']}")
    lines.append(f"- **Profile key:** {r['profile_key'] or 'None'}")
    lines.append(f"- **Overall status:** {status_icons.get(r['overall_status'], r['overall_status'])}")
    lines.append(f"- **Total cards (SQLite SUM):** {r['sqlite_total']}/100")
    lines.append(f"- **Total cards (DB):** {r['db_total_cards']}/100")
    lines.append(f"- **Lands (SQLite SUM):** {r['sqlite_lands']}")
    lines.append(f"- **Lands (DB):** {r['db_total_lands']}")
    lines.append(f"- **Profile lands range:** {r['profile_lands'] or 'N/A'}")
    lines.append(f"- **Lands check:** {r['lands_check'] or 'N/A'}")
    lines.append(f"- **Total cards check:** {r['total_cards_check']}")
    lines.append("")

    if r['discrepancies']:
        lines.append("**DB vs SQLite Discrepancies:**")
        for d in r['discrepancies']:
            lines.append(f"- ⚠️ {d}")
        lines.append("")

    if r['profile_checks']:
        lines.append("**Profile Role Target Checks:**")
        lines.append("")
        lines.append("| Role | DB Value | Profile Range | Status | Diff | Direction |")
        lines.append("|------|----------|---------------|--------|------|-----------|")
        for pc in r['profile_checks']:
            dv = str(pc['db_val']) if pc['db_val'] is not None else "N/A"
            st = status_icons.get(pc['status'], pc['status'])
            lines.append(f"| {pc['role']} | {dv} | [{pc['prof_min']}-{pc['prof_max']}] | {st} | {pc['diff']} | {pc['direction']} |")
        lines.append("")

    if r['crit_issues']:
        lines.append("**🔴 Critical Issues:**")
        for i in r['crit_issues']:
            lines.append(f"- 🔴 {i}")
        lines.append("")

    if r['warn_issues']:
        lines.append("🟡 **Warnings:**")
        for i in r['warn_issues']:
            lines.append(f"- 🟡 {i}")
        lines.append("")

    if r['blue_issues']:
        lines.append("🔵 **Blue (minor) Issues:**")
        for i in r['blue_issues']:
            lines.append(f"- 🔵 {i}")
        lines.append("")

    if r['ok_issues']:
        lines.append("✅ **OK Items:**")
        for i in r['ok_issues']:
            lines.append(f"- ✅ {i}")
        lines.append("")

# DB vs SQLite land discrepancies
lines.append("## DB vs SQLite Land Discrepancies")
lines.append("")
lines.append("| Deck | DB total_lands | SQLite lands | Difference | Status |")
lines.append("|------|----------------|--------------|------------|--------|")

for r in results:
    diff = r['sqlite_lands'] - r['db_total_lands']
    if diff == 0:
        icon = "✅"
    elif abs(diff) >= 4:
        icon = "🔴"
    elif abs(diff) >= 2:
        icon = "🟡"
    else:
        icon = "🔵"
    lines.append(f"| {r['deck_id']} — {r['deck_name'][:25]} | {r['db_total_lands']} | {r['sqlite_lands']} | {diff:+d} | {icon} |")

lines.append("")

# Critical findings
lines.append("## Critical Findings")
lines.append("")

crit_decks = [r for r in results if r['overall_status'] == 'CRIT']
incomplete = [r for r in results if r['sqlite_total'] < 100]
land_disc = [r for r in results if r['db_total_lands'] != r['sqlite_lands']]

lines.append(f"**{len(crit_decks)} decks with CRITICAL status:**")
for r in crit_decks:
    lines.append(f"- Deck {r['deck_id']} ({r['deck_name']})")
lines.append("")

lines.append(f"**{len(incomplete)} incomplete decks (< 100 cards):**")
for r in incomplete:
    lines.append(f"- Deck {r['deck_id']} ({r['deck_name']}): {r['sqlite_total']}/100 cards")
lines.append("")

lines.append(f"**{len(land_disc)} decks with DB vs SQLite land discrepancies:**")
for r in land_disc:
    diff = r['sqlite_lands'] - r['db_total_lands']
    lines.append(f"- Deck {r['deck_id']} ({r['deck_name']}): DB={r['db_total_lands']}, SQLite={r['sqlite_lands']}, diff={diff:+d}")
lines.append("")

lines.append("### Notes")
lines.append("")
lines.append("- Decks 1 (Kinnan), 3 (Korvold), 4 (Teysa) have incomplete card inserts — partial imports mean DB metrics (ramp_count, draw_count, etc.) are unreliable/partial.")
lines.append("- Deck 2 (Yuriko): DB total_cards=84 but SQLite SUM=99 — another partial insert discrepancy.")
lines.append("- Deck 6 (Lorehold) has no commander reference profile — role_target validation is skipped.")
lines.append("- Profile role keys with 'no DB col' status are specialized roles (ramp_fixing, proliferate_engines, etc.) not tracked in the DB metrics columns — these cannot be validated without DB tag cross-referencing.")
lines.append("- All 5 complete decks (5=Aesi, 6=Lorehold, 7=Winota, 9=Atraxa, and partially 2=Yuriko) show matching DB/SQLite lands.")

print("\n".join(lines))
