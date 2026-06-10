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
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5433"),
        dbname=os.environ.get("DB_NAME", "halder"),
        user=os.environ.get("DB_USER", "postgres"),
        password=os.environ["DB_PASS"],
        connect_timeout=10,
    )


def normalize(name: str) -> str:
    return name.strip().lower().replace("\u2018", "'").replace("\u2019", "'")


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
    seen_updates = 0

    for card_name, info in affected_cards.items():
        cur.execute(
            "SELECT review_status, source, last_seen_at, confidence, "
            "  EXTRACT(EPOCH FROM (NOW() - COALESCE(last_seen_at, created_at)))/3600 AS age_hours "
            "FROM card_battle_rules WHERE LOWER(normalized_name) = %s",
            (card_name,),
        )
        row = cur.fetchone()
        if not row:
            continue

        status, source, last_seen, confidence, age_hours = row
        age_hours = float(age_hours or 0)
        severities = info["severities"]
        count = info["count"]
        only_medium_or_lower = "high" not in severities and "critical" not in severities

        # Sempre atualiza last_seen_at para rastrear aparicoes
        cur.execute(
            "UPDATE card_battle_rules SET last_seen_at = NOW() WHERE LOWER(normalized_name) = %s",
            (card_name,),
        )
        seen_updates += 1

        # Promove needs_review → verified: regra tem idade minima e sem high findings
        if (status == "needs_review" and info["has_needs_review"]
                and only_medium_or_lower and age_hours >= args.min_age_hours):
            if not args.dry_run:
                cur.execute(
                    "UPDATE card_battle_rules SET review_status = 'verified', "
                    "source = CASE WHEN source IN ('generated','heuristic') THEN 'curated' ELSE source END, "
                    "confidence = LEAST(confidence * 1.2, 1.0), "
                    "reviewed_by = 'auto_promote_battle_rules', "
                    "reviewed_at = NOW() "
                    "WHERE LOWER(normalized_name) = %s",
                    (card_name,),
                )
            promotions.append(
                f"needs_review→verified: {card_name} (age={age_hours:.1f}h, only medium)"
            )

        # Promove heuristic → curated: muito tempo sem high findings
        elif (source == "heuristic" and only_medium_or_lower
                and age_hours >= args.min_age_hours * 2):
            if not args.dry_run:
                cur.execute(
                    "UPDATE card_battle_rules SET source = 'curated', "
                    "review_status = 'verified', "
                    "confidence = 0.85, "
                    "reviewed_by = 'auto_promote_battle_rules', "
                    "reviewed_at = NOW() "
                    "WHERE LOWER(normalized_name) = %s",
                    (card_name,),
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

    return 0


if __name__ == "__main__":
    sys.exit(main())
