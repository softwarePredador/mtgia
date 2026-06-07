#!/usr/bin/env python3
"""Generate ManaLoom mana-base validation report for CRON_STATUS.md.

Read-only against knowledge.db: validates stored deck metrics with the generic
thresholds requested by the cron plus local EDHREC profile/corpus context when
available.
"""

from __future__ import annotations

import glob
import json
import os
import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

DB = Path("scripts/knowledge.db")
ARTIFACTS = Path("/opt/data/workspace/mtgia/server/test/artifacts")
STATUS = Path("CRON_STATUS.md")


def slug(name: str) -> str:
    s = name.lower().replace("'", "").replace(",", "").replace("—", " ").replace("-", " ")
    return re.sub(r"[^a-z0-9]+", "_", s).strip("_")


def find_profile(commander: str) -> str | None:
    pattern = str(ARTIFACTS / "commander_reference_profile_*" / "profiles" / f"{slug(commander)}.json")
    matches = sorted(glob.glob(pattern))
    return matches[0] if matches else None


def profile_metrics(commander: str) -> dict | None:
    path = find_profile(commander)
    if not path:
        return None
    data = json.loads(Path(path).read_text())
    targets = data.get("role_targets", {})
    ramp_key = next(
        (k for k in ["ramp", "nonland_mana_sources", "ramp_treasure", "artifact_mana", "mana_dorks"] if k in targets),
        None,
    )
    return {
        "path": path,
        "keys": list(targets.keys()),
        "lands": targets.get("lands"),
        "ramp_key": ramp_key,
        "ramp": targets.get(ramp_key) if ramp_key else None,
        "source_count": data.get("source_count"),
    }


def lorehold_corpus_metrics() -> dict | None:
    candidates = [
        ARTIFACTS / "commander_reference_deck_corpus_lorehold_2026-05-12" / "dry_run_after_backfill" / "lorehold_the_historian_dry_run_summary.json",
        ARTIFACTS / "commander_reference_deck_corpus_lorehold_2026-05-12" / "apply" / "lorehold_the_historian_apply_summary.json",
    ]
    for path in candidates:
        if not path.exists():
            continue
        data = json.loads(path.read_text())
        agg = data.get("aggregate", {}).get("Lorehold, the Historian")
        if agg and agg.get("average_role_counts"):
            return {
                "path": str(path),
                "avg": agg["average_role_counts"],
                "deck_count": agg.get("accepted_deck_count"),
            }
    return None


def quality_label(stored_qty: int, declared: int | None) -> str:
    # SUM(quantity) is the best available proxy for card coverage. Some EDHREC
    # artifacts store total_cards as unique rows rather than full quantity, so
    # show both numbers instead of treating stored_qty > declared as an error.
    suffix = f"qty={stored_qty}" if not declared else f"qty={stored_qty}; declared={declared}"
    if stored_qty >= 99:
        return f"COMPLETA ({suffix})"
    if stored_qty >= 80:
        return f"PARCIAL/EDHREC ({suffix})"
    return f"BAIXA ({suffix})"


def validate() -> list[dict]:
    conn = sqlite3.connect(DB)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT d.id, d.deck_name, c.name AS commander, d.total_lands, d.avg_cmc,
               d.ramp_count, d.bracket, d.total_cards, d.analysis_date,
               d.analysis_md_path, s.name AS source, s.type AS source_type
        FROM decks d
        JOIN commanders c ON d.commander_id = c.id
        JOIN sources s ON d.source_id = s.id
        ORDER BY d.analysis_date DESC, d.id DESC
        """
    ).fetchall()

    results: list[dict] = []
    for row in rows:
        qty_row = conn.execute(
            "SELECT COALESCE(SUM(quantity), 0), COUNT(*) FROM deck_cards WHERE deck_id = ?",
            (row["id"],),
        ).fetchone()
        stored_qty = int(qty_row[0] or 0)
        records = int(qty_row[1] or 0)
        declared = int(row["total_cards"] or 0)
        lands = row["total_lands"]
        cmc = row["avg_cmc"]
        ramp = row["ramp_count"]

        alerts: list[str] = []
        severity = "OK"

        # Data integrity is informational unless a deck claims a full 99/100-card
        # total but has <50% stored. EDHREC average/corpus decks can intentionally
        # declare 11/13/79/80/84 because they are partial analysis artifacts.
        if declared >= 90 and stored_qty < declared * 0.5:
            alerts.append("🔴 INSERT incompleto/corrompido")
            severity = "P0"

        if lands is None or cmc is None:
            alerts.append("⚠️ métricas ausentes")
            if severity == "OK":
                severity = "P1"
        else:
            # User-requested generic thresholds.
            if lands < 30 and cmc > 3.0:
                alerts.append(f"🔴 CRÍTICO: lands={lands} < 30 e CMC={cmc:.2f} > 3.0")
                severity = "P0"
            elif lands < 32:
                alerts.append(f"🟡 ALERTA: lands={lands} < 32")
                if severity == "OK":
                    severity = "P1"
            if cmc > 3.5:
                alerts.append(f"🟡 ALERTA: CMC={cmc:.2f} > 3.5")
                if severity == "OK":
                    severity = "P1"

        prof = profile_metrics(row["commander"])
        lore = None
        if row["commander"] == "Lorehold, the Historian":
            lore = lorehold_corpus_metrics()
            if lore and lands is not None:
                avg_lands = lore["avg"].get("lands")
                if avg_lands is not None:
                    alerts.append(f"ℹ️ Lorehold corpus avg lands={avg_lands:.2f} ({lore['deck_count']} decks EDHREC)")

        if prof:
            land_range = prof.get("lands")
            if land_range and lands is not None:
                mn = land_range.get("min")
                mx = land_range.get("max")
                if mn is not None and lands < mn:
                    alerts.append(f"🟡 EDHREC profile lands min={mn}")
                    if severity == "OK":
                        severity = "P1"
                elif mx is not None and lands > mx:
                    alerts.append(f"🟡 EDHREC profile lands max={mx}")
                    if severity == "OK":
                        severity = "P1"
                else:
                    alerts.append(f"✅ lands dentro do profile ({mn}-{mx})")
            ramp_range = prof.get("ramp")
            if ramp_range and ramp is not None:
                mn = ramp_range.get("min")
                mx = ramp_range.get("max")
                key = prof.get("ramp_key")
                if mn is not None and ramp < mn:
                    alerts.append(f"🟡 ramp={ramp} < profile {key} min={mn}")
                    if severity == "OK":
                        severity = "P1"
                elif mx is not None and ramp > mx:
                    alerts.append(f"🟡 ramp={ramp} > profile {key} max={mx}")
                    if severity == "OK":
                        severity = "P1"
                else:
                    alerts.append(f"✅ ramp dentro do profile {key} ({mn}-{mx})")
        elif row["commander"] != "Lorehold, the Historian":
            alerts.append("ℹ️ sem profile EDHREC local; thresholds genéricos aplicados")

        if not alerts:
            alerts.append("✅ Nenhum")

        result = dict(row)
        result.update(
            {
                "stored_qty": stored_qty,
                "records": records,
                "quality": quality_label(stored_qty, declared),
                "alerts": alerts,
                "severity": severity,
                "profile": prof,
                "lorehold": lore,
            }
        )
        results.append(result)

    conn.close()
    return results


def fmt_cmc(v) -> str:
    return "—" if v is None else f"{float(v):.2f}".rstrip("0").rstrip(".")


def md_escape(s: str) -> str:
    return str(s).replace("|", "\\|")


def build_section(results: list[dict]) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%MZ")
    p0 = [r for r in results if r["severity"] == "P0"]
    p1 = [r for r in results if r["severity"] == "P1"]
    ok = [r for r in results if r["severity"] == "OK"]

    lines: list[str] = []
    lines.append(f"## Mana Base Validation ({now})")
    lines.append("")
    lines.append("**Fonte:** SQLite `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db` + perfis/corpus EDHREC locais quando disponíveis.")
    lines.append("")
    lines.append("**Regras aplicadas nesta rodada:** `lands < 32` => ALERTA; `CMC > 3.5` => ALERTA; `lands < 30 AND CMC > 3.0` => CRÍTICO. Perfis EDHREC locais foram usados como contexto adicional para evitar falsos positivos/negativos.")
    lines.append("")
    lines.append("| Deck | Commander | Fonte | Lands | CMC | Ramp | Bracket | Data Quality | Alertas |")
    lines.append("|:-----|:----------|:------|:-----:|:---:|:----:|:-------:|:-------------|:--------|")
    for r in results:
        alerts = "<br>".join(r["alerts"])
        lines.append(
            f"| {md_escape(r['deck_name'])} | {md_escape(r['commander'])} | {md_escape(r['source'])} | "
            f"{r['total_lands']} | {fmt_cmc(r['avg_cmc'])} | {r['ramp_count']} | {r['bracket']} | "
            f"{r['quality']} | {alerts} |"
        )
    lines.append("")
    lines.append("### Resumo da rodada")
    lines.append(f"- Decks avaliados: **{len(results)}**")
    lines.append(f"- P0 críticos: **{len(p0)}**")
    lines.append(f"- Alertas P1: **{len(p1)}**")
    lines.append(f"- Sem alerta de mana base: **{len(ok)}**")
    lines.append("")
    lines.append("### Alertas Críticos (P0)")
    if p0:
        for r in p0:
            lines.append(f"- **{r['deck_name']} / {r['commander']}:** " + "; ".join(a for a in r["alerts"] if "🔴" in a))
    else:
        lines.append("- Nenhum P0 novo nesta rodada.")
    lines.append("")
    lines.append("### Alertas Moderados / Observações")
    if p1:
        for r in p1:
            non_p0 = [a for a in r["alerts"] if "🔴" not in a]
            lines.append(f"- **{r['deck_name']} / {r['commander']}:** " + "; ".join(non_p0))
    else:
        lines.append("- Nenhum alerta P1 nesta rodada.")
    lines.append("")
    lines.append("### Ações recomendadas")
    if p0:
        for r in p0:
            if r["source_type"] == "aggregator" and (r["total_cards"] or 0) < 90:
                lines.append(f"- **P0/P1 revisar classificação:** {r['commander']} disparou crítico genérico, mas é artefato EDHREC parcial (`total_cards={r['total_cards']}`); validar contra corpus/profile antes de reinserir.")
            else:
                lines.append(f"- **P0:** revisar/reinserir {r['deck_name']} se o total armazenado não representar o deck completo.")
    for r in p1:
        if r["commander"] == "Lorehold, the Historian":
            lines.append("- **P1:** Lorehold tem CMC 3.98 > 3.5; validar se a curva alta é intencional do plano topdeck/miracle ou se precisa reduzir bombas caras.")
        elif r["commander"] == "Kinnan, Bonder Prodigy":
            lines.append("- **P2:** Kinnan tem 29 lands e bracket 4; profile EDHREC aceita 29-34, então o alerta genérico de lands baixas não deve virar bug sem evidência adicional.")
        else:
            lines.append(f"- **P2:** revisar métricas de {r['commander']} contra profile/corpus específico antes de alterar decklist.")
    lines.append("")
    lines.append("### Evidência de profiles/corpus usados")
    seen = set()
    for r in results:
        prof = r.get("profile")
        lore = r.get("lorehold")
        if prof and prof["path"] not in seen:
            seen.add(prof["path"])
            rel = prof["path"].replace(str(ARTIFACTS) + "/", "")
            lines.append(f"- `{rel}` — commander {r['commander']}; keys={', '.join(prof['keys'])}")
        if lore and lore["path"] not in seen:
            seen.add(lore["path"])
            rel = lore["path"].replace(str(ARTIFACTS) + "/", "")
            avg = lore["avg"]
            lines.append(f"- `{rel}` — Lorehold corpus: lands avg={avg.get('lands')}, ramp avg={avg.get('ramp')}, accepted_decks={lore.get('deck_count')}")
    lines.append("")
    lines.append("<!-- mana-base-validator: end -->")
    return "\n".join(lines)


def update_status(section: str) -> None:
    text = STATUS.read_text()
    marker_re = re.compile(r"\n## Mana Base Validation \([^\n]+\).*?(?=\n## |\Z)", re.S)
    if marker_re.search(text):
        text = marker_re.sub("\n" + section + "\n", text, count=1)
    else:
        text = text.rstrip() + "\n\n" + section + "\n"
    STATUS.write_text(text)


if __name__ == "__main__":
    results = validate()
    section = build_section(results)
    update_status(section)
    print(section)
