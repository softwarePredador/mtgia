#!/usr/bin/env python3
"""Semantic Layer v2 optimize shadow scorecard.

Runs public/backend optimize probes against sanitized versioned commander corpora
and writes aggregate-only summaries. It never saves auth tokens, QA e-mails,
deck ids, raw payloads, card names, or decklists.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

DEFAULT_BASE_URL = "https://evolution-cartinhas.8ktevp.easypanel.host"
DEFAULT_PASSWORD = "Qa123456!"
DEFAULT_CORPORA = [
    ("brago_king_eternal", "test/artifacts/commander_reference_sprint3_lot_c_2026-05-14/brago_king_eternal/corpus.json", "blink_etb_value"),
    ("krenko_mob_boss", "test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/krenko_mob_boss/corpus.json", "goblin_typal_tokens_aggro"),
    ("edgar_markov", "test/artifacts/commander_reference_deck_corpus_edgar_2026-05-13/edgar_edhrec_average_corpus.json", "mardu_vampire_tokens_aristocrats"),
    ("teysa_karlov", "test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/teysa_karlov/corpus.json", "orzhov_aristocrats_tokens"),
    ("niv_mizzet_parun", "test/artifacts/commander_reference_sprint3_lot_a_2026-05-13/niv_mizzet_parun/corpus.json", "izzet_spellslinger"),
    ("prosper_tome_bound", "test/artifacts/commander_reference_deck_corpus_prosper_2026-05-13/prosper_edhrec_average_corpus.json", "rakdos_exile_treasure"),
    ("aesi_tyrant_of_gyre_strait", "test/artifacts/commander_reference_deck_corpus_aesi_2026-05-13/aesi_edhrec_average_corpus.json", "simic_lands_ramp_draw"),
    ("winota_joiner_of_forces", "test/artifacts/commander_reference_sprint2_2026-05-13/winota_joiner_of_forces/corpus.json", "boros_winota_nonhuman_attack"),
    ("urza_lord_high_artificer", "test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/urza_lord_high_artificer/corpus.json", "mono_blue_artifact_combo_control"),
    ("sythis_harvest_s_hand", "test/artifacts/commander_reference_sprint3_lot_b_2026-05-14/sythis_harvest_s_hand/corpus.json", "selesnya_enchantress_value"),
]


def log_progress(event: str, **fields: Any) -> None:
    print("SEMANTIC_SCORECARD_PROGRESS " + json.dumps({"event": event, **fields}, sort_keys=True), file=sys.stderr, flush=True)


def request(base_url: str, method: str, path: str, payload: Any | None = None, token: str | None = None, timeout: int = 90, retries: int = 3) -> tuple[int, Any, dict[str, str]]:
    data = None if payload is None else json.dumps(payload).encode()
    headers = {"Accept": "application/json"}
    if payload is not None:
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = "Bearer " + token
    ctx = ssl._create_unverified_context()
    for attempt in range(retries + 1):
        req = urllib.request.Request(base_url + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
                body = resp.read().decode() or "{}"
                try:
                    parsed = json.loads(body)
                except Exception:
                    parsed = {"raw": body[:160]}
                return resp.status, parsed, dict(resp.headers)
        except urllib.error.HTTPError as exc:
            body = exc.read().decode() or "{}"
            try:
                parsed = json.loads(body)
            except Exception:
                parsed = {"raw": body[:160]}
            if exc.code == 429 and attempt < retries:
                retry_after = exc.headers.get("Retry-After")
                time.sleep(int(retry_after) if retry_after and retry_after.isdigit() else 5 + attempt * 2)
                continue
            return exc.code, parsed, dict(exc.headers)
    return 599, {"error": "request_exhausted"}, {}


def poll(base_url: str, path: str, token: str, timeout_s: int = 240) -> dict[str, Any]:
    started = time.time()
    last = None
    while time.time() - started < timeout_s:
        status, data, _ = request(base_url, "GET", path, token=token, timeout=60, retries=1)
        last = (status, data)
        if status != 200:
            return {"terminal": "http_error", "payload": data, "elapsed_ms": int((time.time() - started) * 1000)}
        job_status = str(data.get("status") or "").lower()
        if job_status == "completed":
            return {"terminal": "completed", "payload": data.get("result") or data, "elapsed_ms": int((time.time() - started) * 1000)}
        if job_status == "failed":
            return {"terminal": "failed", "payload": data, "elapsed_ms": int((time.time() - started) * 1000)}
        interval = data.get("poll_interval_ms") or 1500
        try:
            interval = max(500, min(int(interval), 5000))
        except Exception:
            interval = 1500
        time.sleep(interval / 1000)
    return {"terminal": "timeout", "payload": last[1] if last else None, "elapsed_ms": int((time.time() - started) * 1000)}


def auth(base_url: str) -> str:
    username = "semantic_v2_scorecard_" + format(int(time.time() * 1000), "x")
    status, data, _ = request(base_url, "POST", "/auth/register", {
        "username": username,
        "email": username + "@example.com",
        "password": DEFAULT_PASSWORD,
    }, timeout=60)
    if status not in (200, 201):
        raise RuntimeError(("auth", status, data))
    return data["token"]


def resolve_card(base_url: str, token: str, name: str, cache: dict[str, str | None]) -> str | None:
    if name in cache:
        return cache[name]
    query = urllib.parse.urlencode({"name": name, "limit": "1"})
    status, data, _ = request(base_url, "GET", "/cards?" + query, token=token, timeout=45, retries=2)
    rows = data.get("data") or []
    cache[name] = rows[0].get("id") if status == 200 and rows else None
    return cache[name]


def load_corpus(server_root: pathlib.Path, rel_path: str) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    data = json.loads((server_root / rel_path).read_text())
    deck = (data.get("decks") or [])[0]
    return deck, deck.get("cards") or []


def create_temp_deck(base_url: str, token: str, cards: list[dict[str, Any]], cache: dict[str, str | None]) -> tuple[str | None, dict[str, Any]]:
    payload_cards = []
    unresolved = 0
    commander_qty = 0
    main_qty = 0
    for card in cards:
        name = str(card.get("name") or "")
        card_id = resolve_card(base_url, token, name, cache)
        qty = int(card.get("quantity") or 1)
        board = str(card.get("board") or "main").lower()
        if not card_id:
            unresolved += 1
            continue
        is_commander = board == "commander"
        commander_qty += qty if is_commander else 0
        main_qty += qty if not is_commander else 0
        payload_cards.append({"card_id": card_id, "quantity": qty, "is_commander": is_commander})
    meta = {"unresolved_count": unresolved, "commander_qty": commander_qty, "main_qty": main_qty, "entry_count": len(payload_cards)}
    if unresolved or commander_qty != 1 or main_qty != 99:
        return None, meta | {"create_status": "skipped"}
    status, data, _ = request(base_url, "POST", "/decks", {
        "name": "Semantic v2 scorecard fixture",
        "format": "commander",
        "description": "Sanitized temporary optimize scorecard fixture",
        "cards": payload_cards,
    }, token=token, timeout=90)
    deck_id = str(data.get("id") or (data.get("deck") or {}).get("id") or "")
    return (deck_id if status in (200, 201) and deck_id else None), meta | {"create_status": status}


def validate_deck(base_url: str, token: str, deck_id: str) -> dict[str, Any]:
    status, data, _ = request(base_url, "POST", f"/decks/{deck_id}/validate", token=token, timeout=60, retries=1)
    body = data.get("validation") if isinstance(data.get("validation"), dict) else data
    return {
        "validate_status": status,
        "validation_ok": bool(body.get("is_valid") or body.get("valid") or body.get("ok")),
        "off_identity": body.get("off_identity_count") or 0,
    }


def semantic_shadow_decision(semantic: dict[str, Any]) -> dict[str, Any]:
    role_delta = semantic.get("role_delta") if isinstance(semantic.get("role_delta"), dict) else {}
    pair_count = int(semantic.get("pair_count") or 0)
    signaled = int(semantic.get("pairs_with_any_semantic_signal") or 0)
    coverage_ratio = (signaled / pair_count) if pair_count else 0
    critical_losses: dict[str, int] = {}
    review_losses: dict[str, int] = {}

    for role, value in role_delta.items():
        if role not in {"draw", "removal", "ramp", "wipe", "protection"}:
            continue
        if not isinstance(value, int) or value >= 0:
            continue

        if role == "protection":
            review_losses[role] = value
            continue

        critical_losses[role] = value

    return {
        "would_block_partial": bool(critical_losses),
        "critical_losses": critical_losses,
        "review_losses": review_losses,
        "coverage_ratio": coverage_ratio,
        "protection_rule": "protection_loss_is_review_only",
    }


def optimize(base_url: str, token: str, deck_id: str, archetype: str, intensity: str) -> dict[str, Any]:
    payload = {"deck_id": deck_id, "archetype": archetype, "bracket": 2, "keep_theme": True, "intensity": intensity, "async": True}
    started = time.time()
    status, data, _ = request(base_url, "POST", "/ai/optimize", payload, token=token, timeout=90, retries=2)
    accepted_ms = int((time.time() - started) * 1000)
    result = data
    terminal = "sync" if status == 200 else "http_" + str(status)
    elapsed_ms = accepted_ms
    if status == 202 and data.get("poll_url"):
        polled = poll(base_url, data["poll_url"], token)
        terminal = polled["terminal"]
        result = polled.get("payload") or {}
        elapsed_ms = polled["elapsed_ms"]
    quality_error = result.get("quality_error") if isinstance(result.get("quality_error"), dict) else {}
    diagnostics = result.get("optimize_diagnostics") if isinstance(result.get("optimize_diagnostics"), dict) else {}
    if not diagnostics and isinstance(quality_error.get("optimize_diagnostics"), dict):
        diagnostics = quality_error.get("optimize_diagnostics") or {}
    semantic = diagnostics.get("semantic_layer_v2") if isinstance(diagnostics.get("semantic_layer_v2"), dict) else {}
    shadow = semantic_shadow_decision(semantic) if semantic else {
        "would_block_partial": False,
        "critical_losses": {},
        "review_losses": {},
        "coverage_ratio": 0,
        "protection_rule": "not_evaluated",
    }
    suggestion_count = max(
        len(result.get("additions") or []) if isinstance(result.get("additions"), list) else 0,
        len(result.get("removals") or []) if isinstance(result.get("removals"), list) else 0,
        len(result.get("swaps") or []) if isinstance(result.get("swaps"), list) else 0,
    )
    current_gate_approved = terminal == "completed" and suggestion_count > 0 and not bool(result.get("quality_error"))
    semantic_v2_actual_blocked = (
        quality_error.get("code") == "OPTIMIZE_SEMANTIC_V2_REJECTED"
        or semantic.get("blocked_by_semantic_v2") is True
    )
    return {
        "intensity": intensity,
        "submit_status": status,
        "accepted_async": status == 202,
        "accepted_ms": accepted_ms,
        "terminal": terminal,
        "elapsed_ms": elapsed_ms,
        "mode": result.get("mode"),
        "outcome_code": result.get("outcome_code") or result.get("quality_error_code"),
        "quality_error": bool(result.get("quality_error")) or terminal == "failed",
        "suggestion_count": suggestion_count,
        "semantic_v2_actual_blocked": semantic_v2_actual_blocked,
        "semantic_v2_enforcement_mode": semantic.get("enforcement_mode"),
        "current_gate_approved": current_gate_approved,
        "has_semantic_signal": bool(semantic),
        "semantic_pair_count": semantic.get("pair_count"),
        "semantic_pairs_with_signal": semantic.get("pairs_with_any_semantic_signal"),
        "semantic_removed_role_count": semantic.get("removed_semantic_role_count"),
        "semantic_added_role_count": semantic.get("added_semantic_role_count"),
        "semantic_enforcement": semantic.get("enforcement"),
        "semantic_shadow_would_block_partial": shadow["would_block_partial"],
        "semantic_shadow_critical_loss_roles": sorted(shadow["critical_losses"].keys()),
        "semantic_shadow_review_loss_roles": sorted(shadow["review_losses"].keys()),
        "semantic_shadow_coverage_ratio": round(float(shadow["coverage_ratio"]), 4),
        "semantic_shadow_protection_rule": shadow["protection_rule"],
    }


def run(args: argparse.Namespace) -> dict[str, Any]:
    started_at = time.time()
    deadline = started_at + args.global_timeout_s if args.global_timeout_s > 0 else None
    base_url = args.base_url.rstrip("/")
    log_progress("health_check", base_url=base_url)
    status, health, _ = request(base_url, "GET", "/health", timeout=30)
    if status != 200:
        raise RuntimeError(("health", status, health))
    if args.expected_sha and health.get("git_sha") != args.expected_sha:
        raise RuntimeError(("unexpected_sha", health.get("git_sha"), args.expected_sha))
    log_progress("auth_start", backend_git_sha=health.get("git_sha"))
    token = auth(base_url)
    cache: dict[str, str | None] = {}
    server_root = pathlib.Path(args.server_root).resolve()
    corpora = DEFAULT_CORPORA[: args.limit]
    summary: dict[str, Any] = {
        "status": "PASS_WITH_RISKS",
        "date": time.strftime("%Y-%m-%d"),
        "scope": "semantic_layer_v2_optimize_shadow_scorecard",
        "backend_url": base_url,
        "backend_git_sha": health.get("git_sha"),
        "cases": [],
        "run": {
            "limit": args.limit,
            "global_timeout_s": args.global_timeout_s,
            "timed_out": False,
        },
        "redactions": {
            "auth_token": "not_saved",
            "qa_email": "not_saved",
            "deck_ids": "redacted",
            "decklists": "not_saved",
            "card_names": "not_saved",
            "raw_payloads": "not_saved",
        },
    }
    for index, (slug, rel_path, archetype) in enumerate(corpora, start=1):
        if deadline is not None and time.time() >= deadline:
            log_progress("global_timeout_before_case", case_index=index, cases_total=len(corpora))
            summary["run"]["timed_out"] = True
            break
        log_progress("case_start", case_index=index, cases_total=len(corpora), commander_slug=slug)
        deck_meta, cards = load_corpus(server_root, rel_path)
        case: dict[str, Any] = {
            "commander_slug": slug,
            "source": "versioned_commander_reference_corpus",
            "theme": deck_meta.get("theme") or archetype,
            "card_entry_count": len(cards),
            "quantity_total": sum(int(card.get("quantity") or 1) for card in cards),
            "optimize": [],
        }
        log_progress("create_temp_deck_start", commander_slug=slug, card_entry_count=len(cards))
        deck_id, create_meta = create_temp_deck(base_url, token, cards, cache)
        case.update(create_meta)
        log_progress(
            "create_temp_deck_done",
            commander_slug=slug,
            create_status=create_meta.get("create_status"),
            unresolved_count=create_meta.get("unresolved_count"),
            commander_qty=create_meta.get("commander_qty"),
            main_qty=create_meta.get("main_qty"),
        )
        if deck_id:
            try:
                case.update(validate_deck(base_url, token, deck_id))
                log_progress(
                    "validate_deck_done",
                    commander_slug=slug,
                    validation_ok=case.get("validation_ok"),
                    off_identity=case.get("off_identity"),
                )
                if case.get("validation_ok"):
                    for intensity in ("focused", "aggressive"):
                        if deadline is not None and time.time() >= deadline:
                            log_progress("global_timeout_before_job", commander_slug=slug, intensity=intensity)
                            summary["run"]["timed_out"] = True
                            break
                        log_progress("optimize_start", commander_slug=slug, intensity=intensity)
                        case["optimize"].append(optimize(base_url, token, deck_id, archetype, intensity))
                        log_progress(
                            "optimize_done",
                            commander_slug=slug,
                            intensity=intensity,
                            terminal=case["optimize"][-1].get("terminal"),
                            current_gate_approved=case["optimize"][-1].get("current_gate_approved"),
                            semantic_shadow_would_block_partial=case["optimize"][-1].get("semantic_shadow_would_block_partial"),
                        )
            finally:
                request(base_url, "DELETE", "/decks/" + deck_id, token=token, timeout=45, retries=0)
                log_progress("delete_temp_deck_done", commander_slug=slug)
        summary["cases"].append(case)
    jobs = [job for case in summary["cases"] for job in case.get("optimize", [])]
    completed = [job for job in jobs if job.get("terminal") == "completed"]
    approved = [job for job in jobs if job.get("current_gate_approved")]
    semantic = [job for job in jobs if job.get("has_semantic_signal")]
    semantic_would_block = [job for job in approved if job.get("semantic_shadow_would_block_partial")]
    semantic_review = [job for job in approved if job.get("semantic_shadow_review_loss_roles")]
    semantic_actual_blocked = [job for job in jobs if job.get("semantic_v2_actual_blocked")]
    quality_fail = [job for job in jobs if job.get("terminal") == "failed" or job.get("quality_error")]
    eligible_cases = [
        case for case in summary["cases"]
        if case.get("create_status") != "skipped"
        and case.get("validation_ok")
        and int(case.get("unresolved_count") or 0) == 0
        and int(case.get("off_identity") or 0) == 0
        and int(case.get("commander_qty") or 0) == 1
        and int(case.get("main_qty") or 0) == 99
    ]
    blocked = bool(semantic_would_block) or len(eligible_cases) < len(summary["cases"])
    summary["scorecard"] = {
        "cases_attempted": len(summary["cases"]),
        "eligible_cases": len(eligible_cases),
        "skipped_or_invalid_cases": len(summary["cases"]) - len(eligible_cases),
        "jobs_attempted": len(jobs),
        "completed_jobs": len(completed),
        "current_gate_approved_jobs": len(approved),
        "quality_failed_jobs": len(quality_fail),
        "semantic_signal_jobs": len(semantic),
        "semantic_shadow_would_block_approved_jobs": len(semantic_would_block),
        "semantic_shadow_review_approved_jobs": len(semantic_review),
        "semantic_v2_actual_blocked_jobs": len(semantic_actual_blocked),
        "false_positive_candidates": len(semantic_would_block),
        "review_candidates": len(semantic_review),
        "false_negative_candidates": 0,
        "decision": "keep_shadow_mode" if blocked else "eligible_for_limited_flagged_enforcement_review",
        "reason": "Keep shadow mode while reviewing semantic losses or invalid corpus coverage." if blocked else "No semantic shadow blockers among currently approved jobs in this sample; review-only losses still require broader corpus before enforcement.",
    }
    summary["run"]["elapsed_ms"] = int((time.time() - started_at) * 1000)
    if summary["run"]["timed_out"]:
        summary["scorecard"]["decision"] = "inconclusive_timeout"
        summary["scorecard"]["reason"] = "Global timeout reached before all requested corpora/jobs completed; use the partial sanitized summary only as operational evidence."
        summary["status"] = "BLOCKED"
    else:
        summary["status"] = "BLOCKED" if blocked else "PASS_WITH_RISKS"
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", default=os.environ.get("SEMANTIC_SCORECARD_BASE_URL", DEFAULT_BASE_URL))
    parser.add_argument("--expected-sha", default=os.environ.get("SEMANTIC_SCORECARD_EXPECTED_SHA"))
    parser.add_argument("--server-root", default=str(pathlib.Path(__file__).resolve().parents[1]))
    parser.add_argument("--limit", type=int, default=int(os.environ.get("SEMANTIC_SCORECARD_LIMIT", "6")))
    parser.add_argument("--global-timeout-s", type=int, default=int(os.environ.get("SEMANTIC_SCORECARD_GLOBAL_TIMEOUT_S", "900")))
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    summary = run(args)
    out = pathlib.Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(summary, indent=2, sort_keys=True, ensure_ascii=False) + "\n")
    print("SEMANTIC_V2_OPTIMIZE_SHADOW_SCORECARD " + json.dumps({"output": str(out), "scorecard": summary["scorecard"]}, sort_keys=True, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
