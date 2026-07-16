#!/usr/bin/env python3
"""Read-only cleanup classification for PostgreSQL Commander deck fixtures.

The audit never deletes rows or creates PostgreSQL objects. It separates
ephemeral test residue from retained corpus/scorecard/reference fixtures and
keeps product decks in a review-only lane. A cleanup package may consume the
explicit high-confidence id list, but only after its own fresh precheck.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import textwrap
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from global_commander_deck_contract_audit import (
    TEST_EMAIL_RE,
    classify_deck,
    validate_commander_shape,
    _fetch_pg_rows,
)


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[3]
REPORT_DIR = REPO_ROOT / "docs/hermes-analysis/master_optimizer_reports"

PUBLIC_REFERENCE_COLUMNS = (
    ("activation_funnel_events", "deck_id", "set_null"),
    ("ai_logs", "deck_id", "set_null"),
    ("ai_optimize_cache", "deck_id", "set_null"),
    ("ai_optimize_fallback_telemetry", "deck_id", "set_null"),
    ("ai_optimize_jobs", "deck_id", "cascade"),
    ("battle_simulations", "deck_a_id", "set_null"),
    ("battle_simulations", "deck_b_id", "set_null"),
    ("battle_simulations", "winner_deck_id", "set_null"),
    ("card_deck_profiles", "deck_id", "set_null"),
    ("deck_comments", "deck_id", "cascade"),
    ("deck_learning_events", "deck_id", "unconstrained"),
    ("deck_matchups", "deck_id", "cascade"),
    ("deck_matchups", "opponent_deck_id", "cascade"),
    ("deck_optimization_events", "deck_id", "unconstrained"),
    ("deck_weakness_reports", "deck_id", "cascade"),
    ("ml_prompt_feedback", "deck_id", "unconstrained"),
    ("post_game_notes", "deck_id", "cascade"),
    ("shared_deck_reports", "deck_id", "set_null"),
)

EPHEMERAL_SOURCE_CLASSES = {
    "incremental_test_residue",
    "e2e_debate_residue",
    "generation_flow_residue",
    "optimization_test_residue",
    "device_qa_residue",
    "generic_qa_runtime_residue",
    "generic_test_residue",
}

RETAINED_SOURCE_CLASSES = {
    "commander_reference_fixture",
    "corpus_seed_fixture",
    "lorehold_reference_fixture",
    "semantic_scorecard_fixture",
}

HEX_RUN_RE = r"[0-9a-f]{8,16}"


def ephemeral_provenance(
    *,
    source: str,
    email: str,
    username: str,
    name: str,
) -> tuple[bool, str | None]:
    """Require coherent owner/name evidence, not only a broad test regex."""

    normalized_email = email.strip().lower()
    normalized_username = username.strip().lower()
    normalized_name = name.strip()

    if source == "incremental_test_residue":
        accepted = (
            normalized_email == "test_deck_incremental@example.com"
            and normalized_username == "test_deck_incremental_user"
            and normalized_name == "Deck incremental"
        )
        return accepted, (
            "server/test/decks_incremental_add_test.dart creates a fresh deck per case"
            if accepted
            else None
        )

    if source == "e2e_debate_residue":
        owner_match = re.fullmatch(r"e2e_debate_[0-9]+", normalized_username)
        accepted = bool(
            owner_match
            and normalized_email == f"{normalized_username}@test.local"
            and re.fullmatch(r"Debate Test #[0-9]+ - .+", normalized_name)
        )
        return accepted, (
            "timestamped e2e debate batch; no current tracked consumer or exact UUID reference"
            if accepted
            else None
        )

    if source == "generation_flow_residue":
        owner_match = re.fullmatch(r"gen_[ab]_[0-9]+", normalized_username)
        accepted_names = (
            r"Test Deck [AB] [0-9]+",
            r"Imported Deck [0-9]+",
            r"Private Deck [0-9]+",
            r"Cópia de Test Deck B [0-9]+",
        )
        accepted = bool(
            owner_match
            and normalized_email == f"{normalized_username}@test.com"
            and any(re.fullmatch(pattern, normalized_name) for pattern in accepted_names)
        )
        return accepted, (
            "server/test/e2e_general_tests.py creates timestamped users and decks"
            if accepted
            else None
        )

    if source == "optimization_test_residue":
        accepted = bool(
            normalized_username == "test_optimize"
            and TEST_EMAIL_RE.search(normalized_email)
            and re.fullmatch(r"Test AI - .+", normalized_name)
        )
        return accepted, (
            "dedicated optimize test owner and generated Test AI deck naming"
            if accepted
            else None
        )

    if source == "device_qa_residue":
        patterns = (
            (
                rf"iphone15_({HEX_RUN_RE})",
                r"iPhone15 Runtime Talrand \1",
                "app/integration_test/deck_runtime_m2006_test.dart",
            ),
            (
                rf"iphone15_async_({HEX_RUN_RE})",
                r"iPhone15 Async Talrand \1",
                "app/integration_test/deck_generate_async_runtime_test.dart",
            ),
            (
                rf"iphone15_commander_edition_({HEX_RUN_RE})",
                r"QA Commander Edition \1",
                "app/integration_test/commander_edition_runtime_test.dart",
            ),
            (
                rf"sm_a135m_lorehold_({HEX_RUN_RE})",
                r"SM A135M Lorehold Edition \1",
                "app/integration_test/lorehold_commander_edition_android_runtime_test.dart",
            ),
            (
                rf"m2006_({HEX_RUN_RE})",
                r"M2006 Runtime Talrand \1",
                "legacy device runtime harness with timestamped owner/deck pair",
            ),
        )
        for owner_pattern, name_template, witness in patterns:
            match = re.fullmatch(owner_pattern, normalized_username)
            if not match:
                continue
            expected_name = name_template.replace(r"\1", match.group(1))
            accepted = (
                normalized_email == f"{normalized_username}@example.com"
                and normalized_name == expected_name
            )
            return accepted, witness if accepted else None
        return False, None

    if source == "generic_qa_runtime_residue":
        functional_match = re.fullmatch(
            rf"functional_tags_runtime_({HEX_RUN_RE})", normalized_username
        )
        if (
            functional_match
            and normalized_email == f"{normalized_username}@example.com"
            and normalized_name == "Runtime Functional Tags"
        ):
            return True, "app/integration_test/deck_functional_tags_runtime_test.dart"

        feather_match = re.fullmatch(
            rf"runtime_feather_app_({HEX_RUN_RE})", normalized_username
        )
        if (
            feather_match
            and normalized_email == f"{normalized_username}@example.com"
            and re.fullmatch(rf"QA Feather feather {HEX_RUN_RE}", normalized_name)
        ):
            return True, "app/integration_test/commander_reference_feather_app_runtime_test.dart"

    return False, None


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def masked_owner(email: str, user_id: str) -> str:
    normalized = email.strip().lower()
    if not normalized:
        return f"user:{user_id}" if user_id else "system"
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:12]
    domain = normalized.rsplit("@", 1)[-1] if "@" in normalized else "no-domain"
    return f"email_sha256:{digest}@{domain}"


def source_class(*, email: str, username: str, name: str) -> str:
    text = " ".join((email, username, name)).lower()
    if "corpus.builder" in text or name.lower().startswith("corpus seed -"):
        return "corpus_seed_fixture"
    if name.lower().startswith(("qa cmdref ", "qa lot", "qa strixhaven ")):
        return "commander_reference_fixture"
    if name.lower().startswith(("runtime lorehold learned", "qa lorehold reference")):
        return "lorehold_reference_fixture"
    if "semantic v2 scorecard" in text or "semantic_v2_scorecard" in text:
        return "semantic_scorecard_fixture"
    if "test_deck_incremental" in text or name.lower().startswith("deck incremental"):
        return "incremental_test_residue"
    if "e2e_debate" in text or name.lower().startswith("debate test"):
        return "e2e_debate_residue"
    if "gen_a_" in text or "gen_b_" in text or name.lower().startswith("ai generated"):
        return "generation_flow_residue"
    if "test_optimize" in text or name.lower().startswith("optimize flow"):
        return "optimization_test_residue"
    if any(token in text for token in ("iphone15", "sm_a135m", "m2006_")):
        return "device_qa_residue"
    if any(token in text for token in ("qa", "runtime", "fixture", "smoke", "probe_")):
        return "generic_qa_runtime_residue"
    return "generic_test_residue"


def load_deck_metadata() -> dict[str, dict[str, Any]]:
    from db_helper import connect

    sql = """
    SELECT
      d.id::text AS deck_id,
      d.user_id::text AS user_id,
      COALESCE(u.email, '') AS email,
      COALESCE(u.username, '') AS username,
      d.name,
      d.description,
      d.is_public,
      d.created_at,
      d.deleted_at,
      (SELECT COUNT(*)::int FROM deck_cards dc WHERE dc.deck_id = d.id)
        AS deck_card_rows,
      (SELECT COALESCE(SUM(dc.quantity), 0)::int
       FROM deck_cards dc WHERE dc.deck_id = d.id) AS deck_quantity,
      MD5(ROW_TO_JSON(d)::text) AS deck_row_md5,
      (SELECT MD5(COALESCE(STRING_AGG(
         CONCAT_WS(E'\\x1f', dc.id::text, dc.deck_id::text,
           COALESCE(dc.card_id::text, '<NULL>'),
           COALESCE(dc.quantity::text, '<NULL>'),
           COALESCE(dc.is_commander::text, '<NULL>'),
           COALESCE(dc.condition, '<NULL>')),
         E'\\x1e' ORDER BY dc.id), ''))
       FROM deck_cards dc WHERE dc.deck_id = d.id) AS deck_cards_md5
    FROM decks d
    LEFT JOIN users u ON u.id = d.user_id
    WHERE d.deleted_at IS NULL
      AND LOWER(d.format) = 'commander'
    ORDER BY d.created_at, d.id
    """
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute("SET LOCAL TIME ZONE 'UTC'")
            cur.execute(sql)
            columns = [item[0] for item in cur.description]
            return {
                str(row[0]): dict(zip(columns, row))
                for row in cur.fetchall()
            }


def load_public_references() -> dict[str, dict[str, int]]:
    from db_helper import connect

    selects = []
    for table, column, policy in PUBLIC_REFERENCE_COLUMNS:
        selects.append(
            f"SELECT {column}::text AS deck_id, "
            f"'{table}.{column}'::text AS source, "
            f"'{policy}'::text AS policy, COUNT(*)::int AS row_count "
            f"FROM {table} WHERE {column} IS NOT NULL GROUP BY {column}"
        )
    sql = " UNION ALL ".join(selects)
    result: dict[str, dict[str, int]] = defaultdict(dict)
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            for deck_id, source, policy, row_count in cur.fetchall():
                result[str(deck_id)][f"{policy}:{source}"] = int(row_count)
    return result


def load_deploy_audit_references() -> dict[str, dict[str, int]]:
    from db_helper import connect

    result: dict[str, dict[str, int]] = defaultdict(dict)
    with connect() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT table_name
                FROM information_schema.columns
                WHERE table_schema = 'manaloom_deploy_audit'
                  AND column_name = 'deck_id'
                  AND data_type = 'uuid'
                ORDER BY table_name
                """
            )
            tables = [str(row[0]) for row in cur.fetchall()]
            if not tables:
                return result
            selects = [
                f'SELECT deck_id::text, \'{table}\'::text, COUNT(*)::int '
                f'FROM manaloom_deploy_audit."{table}" '
                f'WHERE deck_id IS NOT NULL GROUP BY deck_id'
                for table in tables
            ]
            cur.execute(" UNION ALL ".join(selects))
            for deck_id, table, row_count in cur.fetchall():
                result[str(deck_id)][table] = int(row_count)
    return result


def tracked_uuid_references(deck_ids: Iterable[str]) -> dict[str, list[str]]:
    patterns = sorted(set(deck_ids))
    if not patterns:
        return {}
    completed = subprocess.run(
        [
            "git",
            "grep",
            "-n",
            "-F",
            "-f",
            "-",
            "--",
            ".",
            ":(exclude)docs/hermes-analysis/master_optimizer_reports/**",
            ":(exclude)server/test/artifacts/**",
        ],
        cwd=REPO_ROOT,
        input="\n".join(patterns),
        text=True,
        capture_output=True,
        check=False,
    )
    references: dict[str, list[str]] = defaultdict(list)
    for line in completed.stdout.splitlines():
        for deck_id in patterns:
            if deck_id in line:
                references[deck_id].append(line[:500])
    return references


def age_days(created_at: Any, now: datetime) -> int | None:
    if created_at is None:
        return None
    created = created_at
    if created.tzinfo is None:
        created = created.replace(tzinfo=timezone.utc)
    return max(0, (now - created).days)


def reference_total(refs: dict[str, int]) -> int:
    return sum(int(value) for value in refs.values())


def build_report(*, minimum_age_days: int = 30) -> dict[str, Any]:
    now = utc_now()
    contract_rows = _fetch_pg_rows()
    metadata = load_deck_metadata()
    public_refs = load_public_references()
    audit_refs = load_deploy_audit_references()
    repo_refs = tracked_uuid_references(row.deck_id for row in contract_rows)

    rows: list[dict[str, Any]] = []
    for contract_row in contract_rows:
        meta = metadata[contract_row.deck_id]
        scope = classify_deck(contract_row)
        shape_status, issues = validate_commander_shape(contract_row)
        source = source_class(
            email=contract_row.user_email,
            username=str(meta.get("username") or ""),
            name=contract_row.name,
        )
        provenance_ok, provenance_witness = ephemeral_provenance(
            source=source,
            email=contract_row.user_email,
            username=str(meta.get("username") or ""),
            name=contract_row.name,
        )
        days = age_days(meta.get("created_at"), now)
        deck_public_refs = public_refs.get(contract_row.deck_id, {})
        deck_audit_refs = audit_refs.get(contract_row.deck_id, {})
        deck_repo_refs = repo_refs.get(contract_row.deck_id, [])

        blockers: list[str] = []
        if scope != "test_or_fixture":
            blockers.append("not_test_or_fixture_scope")
        if source in RETAINED_SOURCE_CLASSES:
            blockers.append(f"retained_source_class:{source}")
        if source not in EPHEMERAL_SOURCE_CLASSES:
            blockers.append("source_not_ephemeral")
        if not provenance_ok:
            blockers.append("ephemeral_owner_name_provenance_not_proven")
        if not TEST_EMAIL_RE.search(contract_row.user_email or ""):
            blockers.append("owner_email_not_explicitly_test")
        if days is None or days < minimum_age_days:
            blockers.append("younger_than_minimum_age")
        if bool(meta.get("is_public")):
            blockers.append("public_deck")
        if reference_total(deck_public_refs) > 0:
            blockers.append("public_table_references_present")
        if reference_total(deck_audit_refs) > 0:
            blockers.append("deploy_audit_references_present")
        if deck_repo_refs:
            blockers.append("exact_uuid_referenced_in_tracked_repo")

        cleanup_class = (
            "high_confidence_ephemeral_unreferenced_candidate"
            if not blockers
            else "retain_or_manual_review"
        )
        if scope == "user_product":
            cleanup_class = "product_review_only_never_auto_delete"

        rows.append(
            {
                "deck_id": contract_row.deck_id,
                "owner_user_id": contract_row.user_id,
                "owner": masked_owner(contract_row.user_email, contract_row.user_id),
                "owner_email_md5": hashlib.md5(
                    contract_row.user_email.strip().lower().encode("utf-8")
                ).hexdigest(),
                "owner_username": str(meta.get("username") or ""),
                "name": contract_row.name,
                "source_class": source,
                "ephemeral_provenance_proven": provenance_ok,
                "ephemeral_provenance_witness": provenance_witness,
                "scope": scope,
                "cleanup_class": cleanup_class,
                "cleanup_blockers": blockers,
                "created_at": meta.get("created_at").isoformat()
                if meta.get("created_at")
                else None,
                "age_days": days,
                "is_public": bool(meta.get("is_public")),
                "deck_card_rows": int(meta.get("deck_card_rows") or 0),
                "deck_quantity": int(meta.get("deck_quantity") or 0),
                "deck_row_md5": str(meta.get("deck_row_md5") or ""),
                "deck_cards_md5": str(meta.get("deck_cards_md5") or ""),
                "shape_status": shape_status,
                "shape_issues": issues,
                "public_reference_counts": dict(sorted(deck_public_refs.items())),
                "public_reference_total": reference_total(deck_public_refs),
                "deploy_audit_reference_counts": dict(sorted(deck_audit_refs.items())),
                "deploy_audit_reference_total": reference_total(deck_audit_refs),
                "tracked_repo_uuid_reference_count": len(deck_repo_refs),
                "tracked_repo_uuid_reference_sample": deck_repo_refs[:5],
            }
        )

    scope_counts = Counter(row["scope"] for row in rows)
    cleanup_counts = Counter(row["cleanup_class"] for row in rows)
    source_counts = Counter(row["source_class"] for row in rows if row["scope"] == "test_or_fixture")
    blocker_counts = Counter(
        blocker
        for row in rows
        for blocker in row["cleanup_blockers"]
        if row["scope"] == "test_or_fixture"
    )
    safe_rows = [
        row
        for row in rows
        if row["cleanup_class"] == "high_confidence_ephemeral_unreferenced_candidate"
    ]
    product_incomplete = [
        row
        for row in rows
        if row["scope"] == "user_product" and row["shape_status"] != "structure_ready"
    ]
    owner_counts = Counter(row["owner_user_id"] for row in safe_rows)

    return {
        "status": "safe_subset_identified" if safe_rows else "no_safe_subset",
        "generated_at": now.isoformat(),
        "contract": {
            "postgresql_mutated": False,
            "delete_executed": False,
            "minimum_age_days": minimum_age_days,
            "classification_policy": (
                "explicit_test_owner_and_coherent_ephemeral_owner_name_provenance_"
                "and_age_and_zero_references"
            ),
            "product_policy": "never_auto_delete",
        },
        "summary": {
            "deck_count": len(rows),
            "scope_counts": dict(sorted(scope_counts.items())),
            "cleanup_class_counts": dict(sorted(cleanup_counts.items())),
            "test_fixture_source_counts": dict(sorted(source_counts.items())),
            "test_fixture_blocker_counts": dict(sorted(blocker_counts.items())),
            "safe_candidate_count": len(safe_rows),
            "safe_candidate_deck_card_row_count": sum(row["deck_card_rows"] for row in safe_rows),
            "safe_candidate_quantity": sum(row["deck_quantity"] for row in safe_rows),
            "safe_candidate_owner_counts": dict(sorted(owner_counts.items())),
            "incomplete_product_deck_count": len(product_incomplete),
        },
        "safe_candidate_ids": [row["deck_id"] for row in safe_rows],
        "safe_candidates": safe_rows,
        "retained_test_fixtures": [
            row
            for row in rows
            if row["scope"] == "test_or_fixture"
            and row["cleanup_class"] != "high_confidence_ephemeral_unreferenced_candidate"
        ],
        "incomplete_product_decks": product_incomplete,
        "all_decks": rows,
    }


def write_markdown(payload: dict[str, Any], path: Path) -> None:
    summary = payload["summary"]
    lines = [
        "# Global Commander Fixture Cleanup Audit",
        "",
        f"- Status: `{payload['status']}`",
        f"- PostgreSQL mutated: `{str(payload['contract']['postgresql_mutated']).lower()}`",
        f"- Delete executed: `{str(payload['contract']['delete_executed']).lower()}`",
        f"- Active PostgreSQL Commander decks: `{summary['deck_count']}`",
        f"- Test/fixture decks: `{summary['scope_counts'].get('test_or_fixture', 0)}`",
        f"- High-confidence ephemeral unreferenced candidates: `{summary['safe_candidate_count']}`",
        f"- Incomplete product decks (review only): `{summary['incomplete_product_deck_count']}`",
        "",
        "## Test Fixture Source Classes",
        "",
        "| Source class | Count |",
        "| --- | ---: |",
    ]
    for key, value in summary["test_fixture_source_counts"].items():
        lines.append(f"| `{key}` | {value} |")

    lines.extend(
        [
            "",
            "## High-confidence Cleanup Candidates",
            "",
            "| Deck | Owner | Source | Age days | Card rows | Quantity |",
            "| --- | --- | --- | ---: | ---: | ---: |",
        ]
    )
    for row in payload["safe_candidates"]:
        lines.append(
            "| `{name}` (`{deck_id}`) | `{owner}` | `{source}` | {age} | {cards} | {quantity} |".format(
                name=str(row["name"]).replace("|", "/"),
                deck_id=row["deck_id"],
                owner=row["owner"],
                source=row["source_class"],
                age=row["age_days"],
                cards=row["deck_card_rows"],
                quantity=row["deck_quantity"],
            )
        )

    lines.extend(
        [
            "",
            "## Incomplete Product Decks (Never Auto-delete)",
            "",
            "| Deck | Owner user id | Age days | Quantity | Issues | References |",
            "| --- | --- | ---: | ---: | --- | ---: |",
        ]
    )
    for row in payload["incomplete_product_decks"]:
        lines.append(
            "| `{name}` (`{deck_id}`) | `{owner}` | {age} | {quantity} | `{issues}` | {refs} |".format(
                name=str(row["name"]).replace("|", "/"),
                deck_id=row["deck_id"],
                owner=row["owner_user_id"],
                age=row["age_days"],
                quantity=row["deck_quantity"],
                issues=",".join(row["shape_issues"]),
                refs=row["public_reference_total"] + row["deploy_audit_reference_total"],
            )
        )

    lines.extend(
        [
            "",
            "## Guardrails",
            "",
            "- Corpus seeds, Commander-reference fixtures, Lorehold-reference fixtures, and semantic scorecards are retained.",
            "- Product decks are review-only regardless of name, age, quantity, or apparent probe shape.",
            "- Any public-table, deploy-audit, or tracked exact-UUID reference blocks automatic cleanup.",
            "- A broad QA/test regex is insufficient: owner and deck name must match a known timestamped harness contract.",
            "- The safe id list is evidence for a fresh SQL precheck, not deletion authorization.",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def manifest_values(payload: dict[str, Any]) -> str:
    generated_at = payload["generated_at"]
    values = []
    for row in sorted(payload["safe_candidates"], key=lambda item: item["deck_id"]):
        values.append(
            "(" + ", ".join(
                (
                    f"{sql_literal(row['deck_id'])}::uuid",
                    f"{sql_literal(row['owner_user_id'])}::uuid",
                    sql_literal(row["owner_email_md5"]),
                    sql_literal(row["owner_username"]),
                    sql_literal(row["name"]),
                    f"{sql_literal(row['created_at'])}::timestamptz",
                    str(row["deck_card_rows"]),
                    str(row["deck_quantity"]),
                    sql_literal(row["deck_row_md5"]),
                    sql_literal(row["deck_cards_md5"]),
                    sql_literal(row["source_class"]),
                    sql_literal(row["ephemeral_provenance_witness"]),
                    f"{sql_literal(generated_at)}::timestamptz",
                )
            ) + ")"
        )
    return ",\n  ".join(values)


def manifest_ddl(table_name: str, *, temporary: bool) -> str:
    create = "CREATE TEMP TABLE" if temporary else "CREATE TABLE"
    suffix = " ON COMMIT DROP" if temporary else ""
    return textwrap.dedent(
        f"""
        {create} {table_name} (
          deck_id uuid PRIMARY KEY,
          owner_user_id uuid NOT NULL,
          owner_email_md5 text NOT NULL,
          owner_username text NOT NULL,
          expected_name text NOT NULL,
          expected_created_at timestamptz NOT NULL,
          expected_deck_card_rows integer NOT NULL,
          expected_quantity bigint NOT NULL,
          expected_deck_row_md5 text NOT NULL,
          expected_deck_cards_md5 text NOT NULL,
          source_class text NOT NULL,
          provenance_witness text NOT NULL,
          audit_generated_at timestamptz NOT NULL
        ){suffix};
        """
    ).strip()


def public_reference_union(manifest_table: str) -> str:
    selects = []
    for table, column, policy in PUBLIC_REFERENCE_COLUMNS:
        selects.append(
            f"SELECT {sql_literal(policy + ':' + table + '.' + column)} AS source "
            f"FROM public.{table} r JOIN {manifest_table} m ON m.deck_id = r.{column} "
        )
    return "\n          UNION ALL\n          ".join(selects)


def expected_public_reference_values() -> str:
    return ",\n              ".join(
        f"({sql_literal(table)}, {sql_literal(column)})"
        for table, column, _policy in PUBLIC_REFERENCE_COLUMNS
    )


def guard_do_sql(
    *,
    manifest_table: str,
    expected_count: int,
    package_stem: str,
    product_ids: list[str],
) -> str:
    product_array = ", ".join(f"{sql_literal(item)}::uuid" for item in product_ids)
    reference_union = public_reference_union(manifest_table)
    expected_refs = expected_public_reference_values()
    return textwrap.dedent(
        f"""
        DO $fixture_guard$
        DECLARE
          ref_table text;
          has_deploy_reference boolean;
        BEGIN
          IF (SELECT COUNT(*) FROM {manifest_table}) <> {expected_count} THEN
            RAISE EXCEPTION 'target manifest count drifted; expected {expected_count}';
          END IF;

          IF EXISTS (
            SELECT 1 FROM {manifest_table}
            WHERE deck_id = ANY(ARRAY[{product_array}])
          ) THEN
            RAISE EXCEPTION 'product deck leaked into cleanup target manifest';
          END IF;

          IF (SELECT COUNT(*) FROM public.decks d JOIN {manifest_table} m ON m.deck_id = d.id)
             <> {expected_count} THEN
            RAISE EXCEPTION 'one or more exact target decks are missing';
          END IF;

          IF EXISTS (
            SELECT 1
            FROM {manifest_table} m
            JOIN public.decks d ON d.id = m.deck_id
            LEFT JOIN public.users u ON u.id = d.user_id
            WHERE d.user_id IS DISTINCT FROM m.owner_user_id
               OR MD5(LOWER(BTRIM(COALESCE(u.email, '')))) IS DISTINCT FROM m.owner_email_md5
               OR COALESCE(u.username, '') IS DISTINCT FROM m.owner_username
               OR d.name IS DISTINCT FROM m.expected_name
               OR d.created_at IS DISTINCT FROM m.expected_created_at
               OR d.deleted_at IS NOT NULL
               OR LOWER(d.format) <> 'commander'
               OR COALESCE(d.is_public, false)
               OR MD5(ROW_TO_JSON(d)::text) IS DISTINCT FROM m.expected_deck_row_md5
               OR (SELECT COUNT(*) FROM public.deck_cards dc WHERE dc.deck_id = d.id)
                  <> m.expected_deck_card_rows
               OR (SELECT COALESCE(SUM(dc.quantity), 0) FROM public.deck_cards dc WHERE dc.deck_id = d.id)
                  <> m.expected_quantity
               OR (SELECT MD5(COALESCE(STRING_AGG(
                    CONCAT_WS(E'\\x1f', dc.id::text, dc.deck_id::text,
                      COALESCE(dc.card_id::text, '<NULL>'),
                      COALESCE(dc.quantity::text, '<NULL>'),
                      COALESCE(dc.is_commander::text, '<NULL>'),
                      COALESCE(dc.condition, '<NULL>')),
                    E'\\x1e' ORDER BY dc.id), ''))
                   FROM public.deck_cards dc WHERE dc.deck_id = d.id)
                  IS DISTINCT FROM m.expected_deck_cards_md5
          ) THEN
            RAISE EXCEPTION 'target owner/name/content identity drifted since audit';
          END IF;

          IF EXISTS (
            SELECT 1 FROM (
              {reference_union}
            ) public_refs
          ) THEN
            RAISE EXCEPTION 'target acquired a public-table reference after audit';
          END IF;

          IF EXISTS (
            SELECT table_name, column_name
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name <> 'deck_cards'
              AND (
                column_name = 'deck_id'
                OR column_name IN ('deck_a_id', 'deck_b_id', 'winner_deck_id')
                OR column_name ILIKE '%deck%id%'
              )
            EXCEPT
            SELECT * FROM (VALUES
              {expected_refs}
            ) expected(table_name, column_name)
          ) THEN
            RAISE EXCEPTION 'new public deck-reference column exists; audit/package must be regenerated';
          END IF;

          FOR ref_table IN
            SELECT table_name
            FROM information_schema.columns
            WHERE table_schema = 'manaloom_deploy_audit'
              AND column_name = 'deck_id'
              AND data_type = 'uuid'
              AND table_name NOT LIKE {sql_literal(package_stem + '_%')}
            ORDER BY table_name
          LOOP
            EXECUTE format(
              'SELECT EXISTS (SELECT 1 FROM manaloom_deploy_audit.%I r '
              'JOIN {manifest_table} m ON m.deck_id = r.deck_id)',
              ref_table
            ) INTO has_deploy_reference;
            IF has_deploy_reference THEN
              RAISE EXCEPTION 'target referenced by manaloom_deploy_audit.%', ref_table;
            END IF;
          END LOOP;
        END
        $fixture_guard$;
        """
    ).strip()


def precheck_guard_do_sql(payload: dict[str, Any], package_stem: str) -> str:
    safe_rows = payload["safe_candidates"]
    expected_count = len(safe_rows)
    target_array = ", ".join(
        f"{sql_literal(row['deck_id'])}::uuid" for row in safe_rows
    )
    product_array = ", ".join(
        f"{sql_literal(row['deck_id'])}::uuid"
        for row in payload["incomplete_product_decks"]
    )
    values_sql = manifest_values(payload)
    expected_refs = expected_public_reference_values()
    reference_union = "\n          UNION ALL\n          ".join(
        f"SELECT {sql_literal(policy + ':' + table + '.' + column)} AS source "
        f"FROM public.{table} r WHERE r.{column} = ANY(target_ids)"
        for table, column, policy in PUBLIC_REFERENCE_COLUMNS
    )
    manifest_columns = (
        "deck_id, owner_user_id, owner_email_md5, owner_username, expected_name, "
        "expected_created_at, expected_deck_card_rows, expected_quantity, "
        "expected_deck_row_md5, expected_deck_cards_md5, source_class, "
        "provenance_witness, audit_generated_at"
    )
    return textwrap.dedent(
        f"""
        DO $fixture_precheck$
        DECLARE
          target_ids uuid[] := ARRAY[{target_array}];
          product_ids uuid[] := ARRAY[{product_array}];
          ref_table text;
          has_deploy_reference boolean;
        BEGIN
          IF CARDINALITY(target_ids) <> {expected_count} THEN
            RAISE EXCEPTION 'target id count drifted; expected {expected_count}';
          END IF;
          IF target_ids && product_ids THEN
            RAISE EXCEPTION 'product deck leaked into cleanup target ids';
          END IF;
          IF (SELECT COUNT(*) FROM public.decks WHERE id = ANY(target_ids))
             <> {expected_count} THEN
            RAISE EXCEPTION 'one or more exact target decks are missing';
          END IF;

          IF EXISTS (
            WITH m({manifest_columns}) AS (VALUES
              {values_sql}
            )
            SELECT 1
            FROM m
            JOIN public.decks d ON d.id = m.deck_id
            LEFT JOIN public.users u ON u.id = d.user_id
            WHERE d.user_id IS DISTINCT FROM m.owner_user_id
               OR MD5(LOWER(BTRIM(COALESCE(u.email, '')))) IS DISTINCT FROM m.owner_email_md5
               OR COALESCE(u.username, '') IS DISTINCT FROM m.owner_username
               OR d.name IS DISTINCT FROM m.expected_name
               OR d.created_at IS DISTINCT FROM m.expected_created_at
               OR d.deleted_at IS NOT NULL
               OR LOWER(d.format) <> 'commander'
               OR COALESCE(d.is_public, false)
               OR MD5(ROW_TO_JSON(d)::text) IS DISTINCT FROM m.expected_deck_row_md5
               OR (SELECT COUNT(*) FROM public.deck_cards dc WHERE dc.deck_id = d.id)
                  <> m.expected_deck_card_rows
               OR (SELECT COALESCE(SUM(dc.quantity), 0) FROM public.deck_cards dc WHERE dc.deck_id = d.id)
                  <> m.expected_quantity
               OR (SELECT MD5(COALESCE(STRING_AGG(
                    CONCAT_WS(E'\\x1f', dc.id::text, dc.deck_id::text,
                      COALESCE(dc.card_id::text, '<NULL>'),
                      COALESCE(dc.quantity::text, '<NULL>'),
                      COALESCE(dc.is_commander::text, '<NULL>'),
                      COALESCE(dc.condition, '<NULL>')),
                    E'\\x1e' ORDER BY dc.id), ''))
                   FROM public.deck_cards dc WHERE dc.deck_id = d.id)
                  IS DISTINCT FROM m.expected_deck_cards_md5
          ) THEN
            RAISE EXCEPTION 'target owner/name/content identity drifted since audit';
          END IF;

          IF EXISTS (SELECT 1 FROM ({reference_union}) public_refs) THEN
            RAISE EXCEPTION 'target acquired a public-table reference after audit';
          END IF;

          IF EXISTS (
            SELECT table_name, column_name
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name <> 'deck_cards'
              AND (
                column_name = 'deck_id'
                OR column_name IN ('deck_a_id', 'deck_b_id', 'winner_deck_id')
                OR column_name ILIKE '%deck%id%'
              )
            EXCEPT
            SELECT * FROM (VALUES
              {expected_refs}
            ) expected(table_name, column_name)
          ) THEN
            RAISE EXCEPTION 'new public deck-reference column exists; audit/package must be regenerated';
          END IF;

          FOR ref_table IN
            SELECT table_name
            FROM information_schema.columns
            WHERE table_schema = 'manaloom_deploy_audit'
              AND column_name = 'deck_id'
              AND data_type = 'uuid'
              AND table_name NOT LIKE {sql_literal(package_stem + '_%')}
            ORDER BY table_name
          LOOP
            EXECUTE format(
              'SELECT EXISTS (SELECT 1 FROM manaloom_deploy_audit.%I r '
              'WHERE r.deck_id = ANY($1))',
              ref_table
            ) INTO has_deploy_reference USING target_ids;
            IF has_deploy_reference THEN
              RAISE EXCEPTION 'target referenced by manaloom_deploy_audit.%', ref_table;
            END IF;
          END LOOP;
        END
        $fixture_precheck$;
        """
    ).strip()


def write_sql_package(payload: dict[str, Any], prefix: Path) -> dict[str, str]:
    safe_rows = payload["safe_candidates"]
    if not safe_rows:
        return {}

    prefix.parent.mkdir(parents=True, exist_ok=True)
    package_stem = prefix.name
    audit_prefix = f"manaloom_deploy_audit.{package_stem}"
    manifest_table = f"{audit_prefix}_manifest"
    decks_backup = f"{audit_prefix}_decks_backup"
    cards_backup = f"{audit_prefix}_deck_cards_backup"
    expected_count = len(safe_rows)
    expected_card_rows = sum(int(row["deck_card_rows"]) for row in safe_rows)
    values_sql = manifest_values(payload)
    product_ids = [row["deck_id"] for row in payload["incomplete_product_decks"]]
    target_array = ", ".join(
        f"{sql_literal(row['deck_id'])}::uuid" for row in safe_rows
    )

    header = textwrap.dedent(
        f"""
        -- Generated read-only audit package: {payload['generated_at']}
        -- Targets: {expected_count} exact UUIDs; expected deck_cards rows: {expected_card_rows}.
        -- This file is preparation, not PostgreSQL write authorization.
        \\set ON_ERROR_STOP on
        """
    ).strip()

    precheck = "\n\n".join(
        (
            header,
            "BEGIN;\nSET TRANSACTION READ ONLY;\nSET LOCAL TIME ZONE 'UTC';",
            precheck_guard_do_sql(payload, package_stem),
            textwrap.dedent(
                f"""
                SELECT
                  COUNT(*) AS target_decks,
                  {expected_card_rows}::bigint AS target_deck_card_rows,
                  {sum(int(row['deck_quantity']) for row in safe_rows)}::bigint AS target_quantity,
                  MIN(created_at) AS oldest_target,
                  MAX(created_at) AS newest_target
                FROM public.decks
                WHERE id = ANY(ARRAY[{target_array}]);
                ROLLBACK;
                """
            ).strip(),
        )
    ) + "\n"

    apply_sql = "\n\n".join(
        (
            header,
            textwrap.dedent(
                """
                BEGIN;
                SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
                SET LOCAL TIME ZONE 'UTC';
                LOCK TABLE public.decks IN SHARE ROW EXCLUSIVE MODE;
                LOCK TABLE public.deck_cards IN SHARE ROW EXCLUSIVE MODE;
                """
            ).strip(),
            manifest_ddl(manifest_table, temporary=False),
            f"INSERT INTO {manifest_table} VALUES\n  {values_sql};",
            guard_do_sql(
                manifest_table=manifest_table,
                expected_count=expected_count,
                package_stem=package_stem,
                product_ids=product_ids,
            ),
            textwrap.dedent(
                f"""
                CREATE TABLE {decks_backup} AS
                SELECT d.*
                FROM public.decks d
                JOIN {manifest_table} m ON m.deck_id = d.id;

                CREATE TABLE {cards_backup} AS
                SELECT dc.*
                FROM public.deck_cards dc
                JOIN {manifest_table} m ON m.deck_id = dc.deck_id;

                DO $backup_guard$
                BEGIN
                  IF (SELECT COUNT(*) FROM {decks_backup}) <> {expected_count} THEN
                    RAISE EXCEPTION 'deck backup count mismatch';
                  END IF;
                  IF (SELECT COUNT(*) FROM {cards_backup}) <> {expected_card_rows} THEN
                    RAISE EXCEPTION 'deck_cards backup count mismatch';
                  END IF;
                  IF EXISTS (
                    SELECT 1
                    FROM {manifest_table} m
                    JOIN {decks_backup} b ON b.id = m.deck_id
                    WHERE MD5(ROW_TO_JSON(b)::text) IS DISTINCT FROM m.expected_deck_row_md5
                  ) THEN
                    RAISE EXCEPTION 'deck backup identity hash mismatch';
                  END IF;
                  IF EXISTS (
                    SELECT 1
                    FROM {manifest_table} m
                    WHERE (SELECT MD5(COALESCE(STRING_AGG(
                      CONCAT_WS(E'\\x1f', b.id::text, b.deck_id::text,
                        COALESCE(b.card_id::text, '<NULL>'),
                        COALESCE(b.quantity::text, '<NULL>'),
                        COALESCE(b.is_commander::text, '<NULL>'),
                        COALESCE(b.condition, '<NULL>')),
                      E'\\x1e' ORDER BY b.id), ''))
                      FROM {cards_backup} b WHERE b.deck_id = m.deck_id)
                      IS DISTINCT FROM m.expected_deck_cards_md5
                  ) THEN
                    RAISE EXCEPTION 'deck_cards backup identity hash mismatch';
                  END IF;
                END
                $backup_guard$;

                DO $delete_guard$
                DECLARE
                  deleted_count integer;
                BEGIN
                  DELETE FROM public.decks d
                  USING {manifest_table} m
                  WHERE d.id = m.deck_id;
                  GET DIAGNOSTICS deleted_count = ROW_COUNT;
                  IF deleted_count <> {expected_count} THEN
                    RAISE EXCEPTION 'delete count mismatch: expected {expected_count}, got %', deleted_count;
                  END IF;
                  IF EXISTS (SELECT 1 FROM public.decks d JOIN {manifest_table} m ON m.deck_id = d.id)
                     OR EXISTS (SELECT 1 FROM public.deck_cards dc JOIN {manifest_table} m ON m.deck_id = dc.deck_id) THEN
                    RAISE EXCEPTION 'target rows remain after exact delete';
                  END IF;
                END
                $delete_guard$;

                COMMIT;
                """
            ).strip(),
        )
    ) + "\n"

    postcheck = "\n\n".join(
        (
            header,
            "BEGIN;\nSET TRANSACTION READ ONLY;\nSET LOCAL TIME ZONE 'UTC';",
            textwrap.dedent(
                f"""
                DO $postcheck$
                BEGIN
                  IF TO_REGCLASS({sql_literal(manifest_table)}) IS NULL
                     OR TO_REGCLASS({sql_literal(decks_backup)}) IS NULL
                     OR TO_REGCLASS({sql_literal(cards_backup)}) IS NULL THEN
                    RAISE EXCEPTION 'cleanup audit/backup tables are missing';
                  END IF;
                  IF (SELECT COUNT(*) FROM {manifest_table}) <> {expected_count}
                     OR (SELECT COUNT(*) FROM {decks_backup}) <> {expected_count}
                     OR (SELECT COUNT(*) FROM {cards_backup}) <> {expected_card_rows} THEN
                    RAISE EXCEPTION 'manifest or backup count mismatch';
                  END IF;
                  IF EXISTS (SELECT 1 FROM public.decks d JOIN {manifest_table} m ON m.deck_id = d.id)
                     OR EXISTS (SELECT 1 FROM public.deck_cards dc JOIN {manifest_table} m ON m.deck_id = dc.deck_id) THEN
                    RAISE EXCEPTION 'one or more cleanup targets still exist';
                  END IF;
                  IF EXISTS (
                    SELECT 1
                    FROM {manifest_table} m
                    JOIN {decks_backup} b ON b.id = m.deck_id
                    WHERE MD5(ROW_TO_JSON(b)::text) IS DISTINCT FROM m.expected_deck_row_md5
                  ) THEN
                    RAISE EXCEPTION 'backup identity drift detected';
                  END IF;
                  IF EXISTS (
                    SELECT 1
                    FROM {manifest_table} m
                    WHERE (SELECT MD5(COALESCE(STRING_AGG(
                      CONCAT_WS(E'\\x1f', b.id::text, b.deck_id::text,
                        COALESCE(b.card_id::text, '<NULL>'),
                        COALESCE(b.quantity::text, '<NULL>'),
                        COALESCE(b.is_commander::text, '<NULL>'),
                        COALESCE(b.condition, '<NULL>')),
                      E'\\x1e' ORDER BY b.id), ''))
                      FROM {cards_backup} b WHERE b.deck_id = m.deck_id)
                      IS DISTINCT FROM m.expected_deck_cards_md5
                  ) THEN
                    RAISE EXCEPTION 'backup deck_cards identity drift detected';
                  END IF;
                END
                $postcheck$;

                SELECT
                  (SELECT COUNT(*) FROM {manifest_table}) AS manifest_decks,
                  (SELECT COUNT(*) FROM {decks_backup}) AS backed_up_decks,
                  (SELECT COUNT(*) FROM {cards_backup}) AS backed_up_deck_cards,
                  (SELECT COUNT(*) FROM public.decks d JOIN {manifest_table} m ON m.deck_id = d.id)
                    AS remaining_target_decks;
                COMMIT;
                """
            ).strip(),
        )
    ) + "\n"

    deck_columns = (
        "id, user_id, name, format, description, is_public, synergy_score, "
        "strengths, weaknesses, created_at, deleted_at, archetype, bracket, "
        "pricing_currency, pricing_total, pricing_missing_cards, pricing_updated_at"
    )
    card_columns = "id, deck_id, card_id, quantity, is_commander, condition"
    rollback = "\n\n".join(
        (
            header,
            textwrap.dedent(
                """
                BEGIN;
                SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
                SET LOCAL TIME ZONE 'UTC';
                LOCK TABLE public.decks IN SHARE ROW EXCLUSIVE MODE;
                LOCK TABLE public.deck_cards IN SHARE ROW EXCLUSIVE MODE;
                """
            ).strip(),
            textwrap.dedent(
                f"""
                DO $rollback_precheck$
                BEGIN
                  IF TO_REGCLASS({sql_literal(manifest_table)}) IS NULL
                     OR TO_REGCLASS({sql_literal(decks_backup)}) IS NULL
                     OR TO_REGCLASS({sql_literal(cards_backup)}) IS NULL THEN
                    RAISE EXCEPTION 'rollback backup tables are missing';
                  END IF;
                  IF (SELECT COUNT(*) FROM {manifest_table}) <> {expected_count}
                     OR (SELECT COUNT(*) FROM {decks_backup}) <> {expected_count}
                     OR (SELECT COUNT(*) FROM {cards_backup}) <> {expected_card_rows} THEN
                    RAISE EXCEPTION 'rollback backup counts do not match package manifest';
                  END IF;
                  IF EXISTS (SELECT 1 FROM public.decks d JOIN {manifest_table} m ON m.deck_id = d.id)
                     OR EXISTS (SELECT 1 FROM public.deck_cards dc JOIN {manifest_table} m ON m.deck_id = dc.deck_id) THEN
                    RAISE EXCEPTION 'target UUIDs already exist; refusing non-idempotent rollback';
                  END IF;
                  IF EXISTS (
                    SELECT 1 FROM {decks_backup} b
                    LEFT JOIN public.users u ON u.id = b.user_id
                    WHERE b.user_id IS NOT NULL AND u.id IS NULL
                  ) THEN
                    RAISE EXCEPTION 'one or more original owner users no longer exist';
                  END IF;
                  IF EXISTS (
                    SELECT 1 FROM {cards_backup} b
                    LEFT JOIN public.cards c ON c.id = b.card_id
                    WHERE b.card_id IS NOT NULL AND c.id IS NULL
                  ) THEN
                    RAISE EXCEPTION 'one or more original card rows no longer exist';
                  END IF;
                  IF EXISTS (
                    SELECT 1
                    FROM {manifest_table} m
                    WHERE (SELECT MD5(COALESCE(STRING_AGG(
                      CONCAT_WS(E'\\x1f', b.id::text, b.deck_id::text,
                        COALESCE(b.card_id::text, '<NULL>'),
                        COALESCE(b.quantity::text, '<NULL>'),
                        COALESCE(b.is_commander::text, '<NULL>'),
                        COALESCE(b.condition, '<NULL>')),
                      E'\\x1e' ORDER BY b.id), ''))
                      FROM {cards_backup} b WHERE b.deck_id = m.deck_id)
                      IS DISTINCT FROM m.expected_deck_cards_md5
                  ) THEN
                    RAISE EXCEPTION 'rollback deck_cards backup identity mismatch';
                  END IF;
                END
                $rollback_precheck$;

                INSERT INTO public.decks ({deck_columns})
                SELECT {deck_columns} FROM {decks_backup};

                INSERT INTO public.deck_cards ({card_columns})
                SELECT {card_columns} FROM {cards_backup};

                DO $rollback_postcheck$
                BEGIN
                  IF (SELECT COUNT(*) FROM public.decks d JOIN {manifest_table} m ON m.deck_id = d.id)
                     <> {expected_count} THEN
                    RAISE EXCEPTION 'rollback deck count mismatch';
                  END IF;
                  IF (SELECT COUNT(*) FROM public.deck_cards dc JOIN {manifest_table} m ON m.deck_id = dc.deck_id)
                     <> {expected_card_rows} THEN
                    RAISE EXCEPTION 'rollback deck_cards count mismatch';
                  END IF;
                  IF EXISTS (
                    SELECT 1
                    FROM {manifest_table} m
                    JOIN public.decks d ON d.id = m.deck_id
                    WHERE MD5(ROW_TO_JSON(d)::text) IS DISTINCT FROM m.expected_deck_row_md5
                  ) THEN
                    RAISE EXCEPTION 'rollback identity hash mismatch';
                  END IF;
                  IF EXISTS (
                    SELECT 1
                    FROM {manifest_table} m
                    WHERE (SELECT MD5(COALESCE(STRING_AGG(
                      CONCAT_WS(E'\\x1f', dc.id::text, dc.deck_id::text,
                        COALESCE(dc.card_id::text, '<NULL>'),
                        COALESCE(dc.quantity::text, '<NULL>'),
                        COALESCE(dc.is_commander::text, '<NULL>'),
                        COALESCE(dc.condition, '<NULL>')),
                      E'\\x1e' ORDER BY dc.id), ''))
                      FROM public.deck_cards dc WHERE dc.deck_id = m.deck_id)
                      IS DISTINCT FROM m.expected_deck_cards_md5
                  ) THEN
                    RAISE EXCEPTION 'rollback deck_cards identity hash mismatch';
                  END IF;
                END
                $rollback_postcheck$;

                COMMIT;
                """
            ).strip(),
        )
    ) + "\n"

    paths = {
        "precheck": str(prefix.with_name(prefix.name + "_precheck.sql")),
        "apply": str(prefix.with_name(prefix.name + "_apply.sql")),
        "postcheck": str(prefix.with_name(prefix.name + "_postcheck.sql")),
        "rollback": str(prefix.with_name(prefix.name + "_rollback.sql")),
    }
    Path(paths["precheck"]).write_text(precheck, encoding="utf-8")
    Path(paths["apply"]).write_text(apply_sql, encoding="utf-8")
    Path(paths["postcheck"]).write_text(postcheck, encoding="utf-8")
    Path(paths["rollback"]).write_text(rollback, encoding="utf-8")
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--minimum-age-days", type=int, default=30)
    parser.add_argument(
        "--out-prefix",
        type=Path,
        default=REPORT_DIR / "global_commander_fixture_cleanup_audit_current",
    )
    parser.add_argument(
        "--sql-package-prefix",
        type=Path,
        help="Write precheck/apply/postcheck/rollback SQL for the exact safe UUID set.",
    )
    args = parser.parse_args()
    payload = build_report(minimum_age_days=max(0, args.minimum_age_days))
    args.out_prefix.parent.mkdir(parents=True, exist_ok=True)
    json_path = args.out_prefix.with_suffix(".json")
    md_path = args.out_prefix.with_suffix(".md")
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=True), encoding="utf-8")
    write_markdown(payload, md_path)
    sql_paths = (
        write_sql_package(payload, args.sql_package_prefix)
        if args.sql_package_prefix is not None
        else {}
    )
    print(
        json.dumps(
            {
                "status": payload["status"],
                "json": str(json_path),
                "markdown": str(md_path),
                "sql_package": sql_paths,
                "summary": payload["summary"],
            },
            ensure_ascii=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
