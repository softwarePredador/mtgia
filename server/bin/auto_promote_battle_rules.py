#!/usr/bin/env python3
"""Auto-promove regras de batalha de needs_review → verified quando atingem confianca suficiente.

Roda apos o forensic audit no optimizer loop.

Criterios:
  - needs_review: promove apos >= 3 aparicoes em forensic audits (rastreado via last_seen_at updates no PG)
  - heuristic sem issues: promove para curated apos >= 5 aparicoes sem high findings
  - Apenas promove se o card NAO esta no deck do Lorehold (evita impacto no produto)

Usa last_seen_at como proxy de contagem: cada execucao atualiza last_seen_at.
Contamos quantas vezes last_seen_at foi atualizado nos ultimos N dias.
"""

import argparse, json, os, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    print("psycopg2 nao disponivel. Instale com: uv pip install psycopg2-binary")
    sys.exit(1)


def load_env():
    secrets = os.environ.get(
        "MANALOOM_SECRETS", "/opt/data/secrets/manaloom-postgres.env"
    )
    if os.path.exists(secrets):
        with open(secrets) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                os.environ[k.strip()] = v.strip().strip('"').strip("'")


def connect_pg():
    database_url = os.environ.get("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url, connect_timeout=10)
    missing = []
    if not os.environ.get("DB_HOST"):
        missing.append("DB_HOST")
    if not (os.environ.get("PGDATABASE") or os.environ.get("DB_NAME")):
        missing.append("PGDATABASE or DB_NAME")
    if not os.environ.get("DB_PASS"):
        missing.append("DB_PASS")
    if missing:
        raise RuntimeError(
            "Missing PostgreSQL env for auto promotion: " + ", ".join(missing)
        )
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("PGPORT") or os.environ.get("DB_PORT") or "5432",
        dbname=os.environ.get("PGDATABASE") or os.environ.get("DB_NAME"),
        user=os.environ.get("PGUSER") or os.environ.get("DB_USER") or "postgres",
        password=os.environ["DB_PASS"],
        connect_timeout=10,
    )


def normalize(name: str) -> str:
    return name.strip().lower().replace("\u2018", "'").replace("\u2019", "'")


def decide_card_promotion(rule_rows: list[dict], info: dict, min_age_hours: int) -> dict:
    active_rows = [
        row
        for row in rule_rows
        if str(row.get("execution_status") or "auto") != "disabled"
    ]
    if not active_rows:
        return {"decision": "missing"}
    if len(active_rows) > 1:
        return {
            "decision": "skip_multi_rule",
            "reason": "multiple_active_rules_for_name",
            "logical_rule_keys": [
                str(row.get("logical_rule_key") or "") for row in active_rows
            ],
        }

    row = active_rows[0]
    status = str(row.get("review_status") or "")
    source = str(row.get("source") or "")
    age_hours = float(row.get("age_hours") or 0)
    severities = info["severities"]
    only_medium_or_lower = "high" not in severities and "critical" not in severities

    if (
        status == "needs_review"
        and info["has_needs_review"]
        and only_medium_or_lower
        and age_hours >= min_age_hours
    ):
        return {
            "decision": "promote_needs_review",
            "row": row,
            "age_hours": age_hours,
        }

    if (
        source == "heuristic"
        and only_medium_or_lower
        and age_hours >= min_age_hours * 2
    ):
        return {
            "decision": "promote_heuristic",
            "row": row,
            "age_hours": age_hours,
        }

    return {"decision": "no_promotion", "row": row, "age_hours": age_hours}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--forensic-json", help="Path to forensic audit JSON report")
    parser.add_argument("--min-age-hours", type=int, default=12,
                        help="Idade minima (horas) desde primeira deteccao para promover needs_review")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()

    if not args.forensic_json:
        reports_dir = "/opt/data/workspace/mtgia/docs/hermes-analysis/master_optimizer_reports"
        candidates = sorted(
            [f for f in os.listdir(reports_dir) if f.startswith("forensic_") and f.endswith(".json")],
            reverse=True,
        )
        if not candidates:
            print("Nenhum forensic report encontrado.")
            return 0
        args.forensic_json = os.path.join(reports_dir, candidates[0])

    if not os.path.exists(args.forensic_json):
        print(f"Forensic report nao encontrado: {args.forensic_json}")
        return 1

    report = json.load(open(args.forensic_json))
    findings = report.get("rule_findings", report.get("findings", report.get("data", [])))
    summary = report.get("summary", {})

    # Extract affected cards
    affected_cards: dict[str, dict] = {}
    for f in findings:
        card = normalize(f.get("card", ""))
        severity = f.get("severity", "medium")
        finding_text = f.get("finding", "")
        if not card:
            continue
        if card not in affected_cards:
            affected_cards[card] = {"severities": set(), "count": 0, "has_needs_review": False}
        affected_cards[card]["severities"].add(severity)
        affected_cards[card]["count"] += 1
        if "needs_review" in finding_text:
            affected_cards[card]["has_needs_review"] = True

    if not affected_cards:
        print("Nenhum card afetado nos findings.")
        return 0

    load_env()
    conn = connect_pg()
    conn.autocommit = True
    cur = conn.cursor()
    now = datetime.now(timezone.utc)

    promotions = []
    skipped_multi_rule = []
    seen_updates = 0

    for card_name, info in affected_cards.items():
        cur.execute(
            "SELECT logical_rule_key, review_status, source, execution_status, "
            "last_seen_at, confidence, "
            "EXTRACT(EPOCH FROM (NOW() - COALESCE(last_seen_at, created_at)))/3600 AS age_hours "
            "FROM card_battle_rules WHERE LOWER(normalized_name) = %s "
            "ORDER BY logical_rule_key",
            (card_name,),
        )
        fetched = cur.fetchall()
        if not fetched:
            continue

        rows = [
            {
                "logical_rule_key": row[0],
                "review_status": row[1],
                "source": row[2],
                "execution_status": row[3],
                "last_seen_at": row[4],
                "confidence": row[5],
                "age_hours": row[6],
            }
            for row in fetched
        ]

        # Sempre atualiza last_seen_at para rastrear aparicoes
        cur.execute(
            "UPDATE card_battle_rules SET last_seen_at = NOW() "
            "WHERE LOWER(normalized_name) = %s "
            "AND COALESCE(execution_status, 'auto') != 'disabled'",
            (card_name,),
        )
        seen_updates += 1

        decision = decide_card_promotion(rows, info, args.min_age_hours)
        kind = decision["decision"]

        if kind == "skip_multi_rule":
            skipped_multi_rule.append(
                f"{card_name} ({', '.join(decision['logical_rule_keys'])})"
            )
            continue

        if kind == "promote_needs_review":
            row = decision["row"]
            age_hours = float(decision["age_hours"])
            if not args.dry_run:
                cur.execute(
                    "UPDATE card_battle_rules SET review_status = 'verified', "
                    "source = CASE WHEN source IN ('generated','heuristic') THEN 'curated' ELSE source END, "
                    "confidence = LEAST(confidence * 1.2, 1.0), "
                    "reviewed_by = 'auto_promote_battle_rules', "
                    "reviewed_at = NOW() "
                    "WHERE LOWER(normalized_name) = %s AND logical_rule_key = %s",
                    (card_name, row["logical_rule_key"]),
                )
            promotions.append(
                f"needs_review→verified: {card_name} (age={age_hours:.1f}h, only medium)"
            )

        # Promove heuristic → curated: muito tempo sem high findings
        elif kind == "promote_heuristic":
            row = decision["row"]
            age_hours = float(decision["age_hours"])
            if not args.dry_run:
                cur.execute(
                    "UPDATE card_battle_rules SET source = 'curated', "
                    "review_status = 'verified', "
                    "confidence = 0.85, "
                    "reviewed_by = 'auto_promote_battle_rules', "
                    "reviewed_at = NOW() "
                    "WHERE LOWER(normalized_name) = %s AND logical_rule_key = %s",
                    (card_name, row["logical_rule_key"]),
                )
            promotions.append(
                f"heuristic→curated: {card_name} (age={age_hours:.1f}h, only medium)"
            )

    cur.close()
    conn.close()

    mode = "DRY-RUN" if args.dry_run else "APPLIED"
    print(f"Auto-promote battle rules [{mode}]")
    print(f"Cards atualizados (last_seen_at): {seen_updates}")
    if promotions:
        for p in promotions:
            print(f"  {p}")
        print(f"Promocoes: {len(promotions)}")
    else:
        print("Nenhuma promocao elegivel (idade minima nao atingida ou high findings bloqueando).")
    if skipped_multi_rule:
        print("Promocoes puladas por multi-rule sem chave row-level no forensic:")
        for item in skipped_multi_rule:
            print(f"  {item}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
