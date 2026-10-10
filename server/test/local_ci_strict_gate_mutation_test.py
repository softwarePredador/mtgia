#!/usr/bin/env python3
"""BT-GATE-001/002/003: mutação dos contratos do gate estrito.

Cada mutação tira uma propagação (skip -> PARTIAL, BLOCKED -> exit 2, receipt por
etapa, SHA por etapa, deck gate no full/release, reaproveitamento por SHA) de uma
cópia do repositório e exige que o teste de contrato correspondente fique
vermelho. Antes, a mesma seleção de testes tem de passar na cópia sem mutação:
sem isso, um teste quebrado por outro motivo contaria como "mutante morto".

Nenhum arquivo do repositório é alterado: tudo roda numa árvore temporária.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]

COPIED_FILES = (
    "scripts/manaloom_local_ci.sh",
    "scripts/quality_gate.sh",
    "scripts/manaloom_gate_run_receipt.py",
    "scripts/manaloom_gate_skip_inventory.py",
    "scripts/manaloom_deck_ai_learning_receipt_validator.py",
    "scripts/manaloom_deck_ai_learning_gate.sh",
    "scripts/manaloom_staged_ui_scope.py",
    "scripts/manaloom_ui_source_digest.sh",
    ".githooks/pre-commit",
    "server/config/gate_skip_allowlist.json",
    "server/config/deck_ai_learning_gate_policy.json",
    "server/test/gate_skip_inventory_test.py",
    "server/test/gate_run_receipt_test.py",
    "server/test/local_ci_strict_gate_test.py",
    "server/test/local_ci_staged_scope_dispatcher_test.py",
    "server/test/deck_ai_learning_gate_contract_test.py",
    "server/test/deck_ai_learning_receipt_validator_test.py",
    "server/test/deck_ai_learning_release_producer_loopback_test.py",
    "scripts/manaloom_deck_ai_learning_release_receipt.sh",
    "app/test/features/home/lotus_web_host_runtime_test_stub.dart",
)

STRICT = "server/test/local_ci_strict_gate_test.py"
SKIPS = "server/test/gate_skip_inventory_test.py"
RECEIPT = "server/test/gate_run_receipt_test.py"
DECK = "server/test/deck_ai_learning_gate_contract_test.py"
VALIDATOR_TEST = "server/test/deck_ai_learning_receipt_validator_test.py"
LOOPBACK = "server/test/deck_ai_learning_release_producer_loopback_test.py"


@dataclass(frozen=True)
class Mutation:
    name: str
    path: str
    old: str
    new: str
    test_file: str
    tests: tuple[str, ...]


MUTATIONS = (
    # --- local_ci.sh -------------------------------------------------------
    Mutation(
        "local_ci: skip numa etapa deixa de virar PARTIAL",
        "scripts/manaloom_local_ci.sh",
        "      3) step_rc=3 ;;\n",
        "      3) ;;\n",
        STRICT,
        ("LocalCiStrictGateTest.test_skip_marker_in_a_step_is_partial_exit_3_never_pass",
         "LocalCiStrictGateTest.test_uninventoried_test_skip_counter_is_partial"),
    ),
    Mutation(
        "local_ci: BLOCKED do scan de log vira sucesso",
        "scripts/manaloom_local_ci.sh",
        "      *) step_rc=2 ;;\n",
        "      *) ;;\n",
        STRICT,
        ("LocalCiStrictGateTest.test_blocked_marker_with_zero_exit_is_blocked_not_success",),
    ),
    Mutation(
        "local_ci: PARTIAL no fim sai com 0",
        "scripts/manaloom_local_ci.sh",
        "    exit 3\n  fi\n}",
        "    exit 0\n  fi\n}",
        STRICT,
        ("LocalCiStrictGateTest.test_skip_marker_in_a_step_is_partial_exit_3_never_pass",
         "LocalCiStrictGateTest.test_quick_manual_and_staged_both_reject_a_skip"),
    ),
    Mutation(
        "local_ci: receipt final nunca é gravado",
        "scripts/manaloom_local_ci.sh",
        '  finalize_receipt "$gate_status"\n',
        '  RECEIPT_FINAL_STATUS="$gate_status"\n',
        STRICT,
        ("LocalCiStrictGateTest.test_full_pass_writes_one_eligible_receipt_with_every_named_step",),
    ),
    Mutation(
        "local_ci: etapa não grava o estado-fonte nem o resultado no ledger",
        "scripts/manaloom_local_ci.sh",
        '      "$step_id" "$step_status" "$step_rc" "$log_file" "$source_file" >>"$STEPS_FILE"',
        '      "$step_id" "PASS" "0" "$log_file" "$source_file" >>"$STEPS_FILE"',
        STRICT,
        ("LocalCiStrictGateTest.test_step_exit_codes_map_to_blocked_partial_and_fail",
         "LocalCiStrictGateTest.test_skip_marker_in_a_step_is_partial_exit_3_never_pass"),
    ),
    Mutation(
        "local_ci: o full deixa de rodar o gate Deck/IA/Learning",
        "scripts/manaloom_local_ci.sh",
        "  run_named_step deck-ai-learning run_deck_ai_learning_gate\n",
        "",
        STRICT,
        ("LocalCiStrictGateTest.test_full_runs_the_deck_ai_learning_gate_once_in_local_profile",),
    ),
    Mutation(
        "local_ci: o release roda o perfil local em vez do read-only",
        "scripts/manaloom_local_ci.sh",
        '    profile="release-read-only"\n',
        '    profile="local"\n',
        STRICT,
        ("LocalCiStrictGateTest.test_release_runs_the_deck_gate_in_read_only_profile",),
    ),
    Mutation(
        "local_ci: o release deixa de exigir o receipt do PG de produção",
        "scripts/manaloom_local_ci.sh",
        "    require_release_pg_receipt\n    run_full\n",
        "    run_full\n",
        STRICT,
        ("LocalCiStrictGateTest.test_release_requires_the_production_pg_receipt_before_any_step",),
    ),
    Mutation(
        "local_ci: o deck gate não recebe o ledger de reaproveitamento",
        "scripts/manaloom_local_ci.sh",
        '  MANALOOM_GATE_REUSE_STEPS="$STEPS_FILE" \\\n',
        "  MANALOOM_GATE_REUSE_STEPS=/nonexistent \\\n",
        STRICT,
        ("LocalCiStrictGateTest.test_deck_gate_reuses_slices_the_local_ci_already_proved",),
    ),
    # --- quality_gate.sh ---------------------------------------------------
    Mutation(
        "quality_gate: o Flutter volta a aceitar 'All other tests passed!' sem inventário",
        "scripts/quality_gate.sh",
        '  check_skip_inventory flutter-full "$json_file" || inventory_rc=$?\n',
        "  :\n",
        SKIPS,
        ("QualityGateSkipWiringTest.test_flutter_all_other_tests_passed_is_no_longer_enough",),
    ),
    Mutation(
        "quality_gate: skip fora da allowlist retorna 0",
        "scripts/quality_gate.sh",
        "      return 3\n",
        "      return 0\n",
        SKIPS,
        ("QualityGateSkipWiringTest.test_flutter_all_other_tests_passed_is_no_longer_enough",
         "QualityGateSkipWiringTest.test_dart_test_wrapper_applies_the_same_rule"),
    ),
    Mutation(
        "quality_gate: inventário ilegível (BLOCKED) retorna 0",
        "scripts/quality_gate.sh",
        '(exit $inventory_rc)." >&2\n      return 2\n',
        '(exit $inventory_rc)." >&2\n      return 0\n',
        SKIPS,
        ("QualityGateSkipWiringTest.test_flutter_without_a_reporter_file_is_blocked",),
    ),
    Mutation(
        "quality_gate: o wrapper de teste não pede o reporter JSON",
        "scripts/quality_gate.sh",
        '  "$@" --file-reporter "json:$json_file" || test_rc=$?\n',
        '  "$@" || test_rc=$?\n',
        SKIPS,
        ("QualityGateSkipWiringTest.test_dart_test_wrapper_applies_the_same_rule",),
    ),
    Mutation(
        "quality_gate: um runner de teste novo escapa do inventário",
        "scripts/quality_gate.sh",
        "run_inventoried_test backend-quick \\\n      dart test",
        "dart test",
        SKIPS,
        ("QualityGateSkipWiringTest.test_every_test_runner_in_quality_gate_goes_through_the_inventory",),
    ),
    # --- manaloom_gate_skip_inventory.py ------------------------------------
    Mutation(
        "inventário: skip fora da allowlist deixa de ser PARTIAL",
        "scripts/manaloom_gate_skip_inventory.py",
        '"status": "PARTIAL" if unlisted else "PASS",',
        '"status": "PASS",',
        SKIPS,
        ("SkipInventoryTest.test_skip_outside_the_allowlist_is_partial_with_exit_3",),
    ),
    Mutation(
        "inventário: entrada vencida continua valendo",
        "scripts/manaloom_gate_skip_inventory.py",
        "        if review_by < today:\n            continue  # vencida: o skip volta a ser PARTIAL\n",
        "",
        SKIPS,
        ("SkipInventoryTest.test_expired_entry_no_longer_covers_the_skip",),
    ),
    Mutation(
        "inventário: relatório truncado deixa de ser BLOCKED",
        "scripts/manaloom_gate_skip_inventory.py",
        '    if not any(event.get("type") == "done" for event in events):\n        raise InventoryError("test report has no done event (truncated run)")\n',
        "",
        SKIPS,
        ("SkipInventoryTest.test_missing_empty_or_truncated_report_is_blocked_not_pass",),
    ),
    Mutation(
        "inventário: BLOCKED deixa de ter precedência sobre PARTIAL",
        "scripts/manaloom_gate_skip_inventory.py",
        'status = "BLOCKED" if blocked else "PARTIAL" if partial else "PASS"',
        'status = "PARTIAL" if partial else "BLOCKED" if blocked else "PASS"',
        SKIPS,
        ("SkipInventoryTest.test_blocked_marker_is_blocked_and_beats_partial",),
    ),
    Mutation(
        "inventário: o marcador SKIP deixa de ser reconhecido",
        "scripts/manaloom_gate_skip_inventory.py",
        "(SKIP|SKIPPED|PARTIAL)",
        "(NEVER_MATCHES)",
        SKIPS,
        ("SkipInventoryTest.test_skip_marker_in_a_log_is_partial",),
    ),
    Mutation(
        "inventário: allowlist sem dono passa",
        "scripts/manaloom_gate_skip_inventory.py",
        'REQUIRED_ENTRY_FIELDS = ("id", "kind", "reason", "owner", "added", "review_by")',
        'REQUIRED_ENTRY_FIELDS = ("id", "kind", "reason", "added", "review_by")',
        SKIPS,
        ("SkipInventoryTest.test_entry_without_reason_owner_or_deadline_is_rejected",),
    ),
    # --- manaloom_gate_run_receipt.py ---------------------------------------
    Mutation(
        "receipt: etapa em outro SHA/tree/digest não derruba o PASS",
        "scripts/manaloom_gate_run_receipt.py",
        "    if step_drift:\n",
        "    if False:\n",
        RECEIPT,
        ("GateRunReceiptTest.test_step_on_another_sha_turns_the_receipt_into_fail",),
    ),
    Mutation(
        "receipt: catálogo incompleto ainda diz PASS",
        "scripts/manaloom_gate_run_receipt.py",
        '        and gate == "local_ci"\n        and [check["id"]',
        '        and False\n        and [check["id"]',
        RECEIPT,
        ("GateRunReceiptTest.test_forged_single_check_is_rejected",),
    ),
    Mutation(
        "receipt: PASS com check não-PASS deixa de virar FAIL",
        "scripts/manaloom_gate_run_receipt.py",
        '    if final_status == "PASS" and any(check["status"] != "PASS" for check in checks):',
        '    if final_status == "PASS" and False:',
        RECEIPT,
        ("GateRunReceiptTest.test_partial_step_never_yields_pass_or_eligibility",
         "GateRunReceiptTest.test_pass_status_with_failed_check_is_fail"),
    ),
    Mutation(
        "receipt: o validador não confere o SHA de cada check",
        "scripts/manaloom_gate_run_receipt.py",
        "all(check_source.get(key) == start.get(key) for key in STEP_SOURCE_KEYS)",
        "True",
        RECEIPT,
        ("GateRunReceiptTest.test_check_rules_are_enforced",),
    ),
    Mutation(
        "receipt: reaproveita etapa que não passou",
        "scripts/manaloom_gate_run_receipt.py",
        'if step is None or step["status"] != "PASS" or step["exit_code"] != 0:',
        "if step is None:",
        RECEIPT,
        ("GateRunReceiptTest.test_reuse_requires_pass_on_the_same_sha_tree_and_digest",),
    ),
    Mutation(
        "receipt: reaproveita etapa de outro estado-fonte",
        "scripts/manaloom_gate_run_receipt.py",
        "if all(step_source[key] == current.get(key) for key in STEP_SOURCE_KEYS):",
        "if True:",
        RECEIPT,
        ("GateRunReceiptTest.test_reuse_is_refused_after_the_worktree_moves",),
    ),
    # --- gate Deck/IA/Learning: fatia única e migration do manifesto ---------
    Mutation(
        "deck gate: reaproveita sem prova do local_ci",
        "scripts/manaloom_deck_ai_learning_gate.sh",
        '--steps "$REUSE_STEPS_FILE" --check "$candidates" 2>/dev/null)" || return 1',
        '--steps "$REUSE_STEPS_FILE" --check "$candidates" 2>/dev/null)" || true',
        DECK,
        ("DeckAiLearningGateContractTest.test_reuse_requires_a_passing_local_ci_step_on_the_same_source",),
    ),
    Mutation(
        "deck gate: reaproveita a fatia de contenção isolada em rede",
        "scripts/manaloom_deck_ai_learning_gate.sh",
        '    audit.operational_surface_alignment) printf \'%s\\n\' "guardrail-audits" ;;\n',
        '    audit.operational_surface_alignment) printf \'%s\\n\' "guardrail-audits" ;;\n'
        '    dart.deck_ai_learning_containment_contracts) printf \'%s\\n\' "full-quality" ;;\n',
        DECK,
        ("DeckAiLearningGateContractTest.test_reuse_is_limited_to_slices_with_the_same_evidence",),
    ),
    Mutation(
        "validador: última migration volta a ser um número fixo",
        "scripts/manaloom_deck_ai_learning_receipt_validator.py",
        '    source["required_latest_migration"] = latest\n',
        '    source["required_latest_migration"] = "058"\n',
        VALIDATOR_TEST,
        ("DeckAiLearningReceiptValidatorTest.test_policy_range_follows_the_manifest_latest_migration",),
    ),
    Mutation(
        "validador: receipt recusado fica no disco",
        "scripts/manaloom_deck_ai_learning_receipt_validator.py",
        "        output_path.unlink(missing_ok=True)\n",
        "        pass\n",
        LOOPBACK,
        ("ReleaseProducerLoopbackTest.test_unapplied_manifest_migration_blocks_the_receipt",),
    ),
    Mutation(
        "produtor: o SQL de migrations pede acesso de escrita",
        "scripts/manaloom_deck_ai_learning_release_receipt.sh",
        '"$ROOT_DIR/server/bin/with_new_server_pg.sh" --read-only \\\n  psql -X -v ON_ERROR_STOP=1 -qAt -c "$MIGRATION_SQL"',
        '"$ROOT_DIR/server/bin/with_new_server_pg.sh" --write-approved \\\n  psql -X -v ON_ERROR_STOP=1 -qAt -c "$MIGRATION_SQL"',
        LOOPBACK,
        ("ReleaseProducerLoopbackTest.test_producer_emits_a_receipt_the_validator_accepts_up_to_the_manifest_migration",
         "ReleaseProducerLoopbackTest.test_producer_source_never_requests_write_access_or_ddl"),
    ),
)


def _prepare_tree(root: Path) -> None:
    for relative in COPIED_FILES:
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(REPO_ROOT / relative, target)
    # Manifesto mínimo: o real tem centenas de milhares de linhas e os testes só
    # precisam de database.latest_migration e do digest.
    (root / "project_logic_manifest.json").write_text(
        '{"source_digest_sha256": "' + "a" * 64 + '", "database": {"latest_migration": "076"}}\n',
        encoding="utf-8",
    )
    for directory in ("scripts/lib",):
        shutil.copytree(REPO_ROOT / directory, root / directory, dirs_exist_ok=True)


def _run_tests(root: Path, test_file: str, tests: tuple[str, ...]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(root / test_file), *tests],
        cwd=root,
        text=True,
        capture_output=True,
    )


class GateStrictnessMutationTest(unittest.TestCase):
    def test_each_mutation_is_killed_by_its_contract_test(self) -> None:
        survivors: list[str] = []
        for mutation in MUTATIONS:
            with self.subTest(mutation=mutation.name):
                with tempfile.TemporaryDirectory(prefix="manaloom-gate-mutation.") as raw:
                    root = Path(raw)
                    _prepare_tree(root)
                    baseline = _run_tests(root, mutation.test_file, mutation.tests)
                    self.assertEqual(
                        baseline.returncode,
                        0,
                        f"baseline sem mutação deve passar: {mutation.name}\n{baseline.stderr[-1500:]}",
                    )
                    target = root / mutation.path
                    text = target.read_text(encoding="utf-8")
                    self.assertEqual(
                        text.count(mutation.old),
                        1,
                        f"trecho da mutação deve existir uma vez: {mutation.name}",
                    )
                    target.write_text(text.replace(mutation.old, mutation.new), encoding="utf-8")
                    mutated = _run_tests(root, mutation.test_file, mutation.tests)
                    if mutated.returncode == 0:
                        survivors.append(mutation.name)
        self.assertEqual(survivors, [], "mutantes sobreviventes: " + "; ".join(survivors))


if __name__ == "__main__":
    unittest.main(verbosity=2)
