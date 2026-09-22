#!/usr/bin/env python3
"""Classify the immutable staged snapshot against ManaLoom UI sources."""

from __future__ import annotations

import os
from pathlib import PurePosixPath
import re
import stat
import subprocess
import sys
from typing import Iterable


DIGEST_PATH = "scripts/manaloom_ui_source_digest.sh"
DIGEST_PATH_BYTES = DIGEST_PATH.encode("utf-8")
CLASSIFIER_PATH = "scripts/manaloom_staged_ui_scope.py"
AFFECTS_UI = "AFFECTS_UI"
NOT_APPLICABLE = "N/A_UI_SOURCE_UNCHANGED_STAGED_SCOPE"
BOOTSTRAP = "BOOTSTRAP_STAGED_UI_SCOPE_CONTROL_PLANE"
UNBORN_HEAD = "UNBORN"
ALLOWED_BLOB_MODES = {b"100644", b"100755"}
SAFE_ROOT = re.compile(r'  "([^"\\$`]+)"')
# Bash ignora linha que é só comentário dentro do array; entrada com comentário
# no fim continua sendo não literal e falha fechado.
COMMENT_LINE = re.compile(r"[ \t]*#[^\n]*")
OID = re.compile(r"[0-9a-f]{40}|[0-9a-f]{64}")

BOOTSTRAP_SOURCE_PATHS = frozenset(
    {
        ".githooks/pre-commit",
        "AGENTS.md",
        "docs/MANALOOM_E2E_RELEASE_CONTRACT.md",
        "scripts/manaloom_local_ci.sh",
        CLASSIFIER_PATH,
        "server/test/local_ci_contract_test.dart",
        "server/test/local_ci_staged_scope_dispatcher_test.py",
        "server/test/staged_ui_scope_classifier_test.py",
    }
)
BOOTSTRAP_GENERATED_PATHS = frozenset(
    {
        "project_logic_manifest.json",
        "docs/generated/CURRENT_SYSTEM.md",
        "docs/generated/TASK_REGISTRY.json",
        "docs/generated/openapi.generated.json",
    }
)
BOOTSTRAP_PATHS = BOOTSTRAP_SOURCE_PATHS | BOOTSTRAP_GENERATED_PATHS
WORKTREE_INDEX_BINDING_PATHS = BOOTSTRAP_SOURCE_PATHS


class ScopeClassificationError(RuntimeError):
    pass


def _git(
    root: str | None,
    arguments: Iterable[str],
    *,
    allowed_exit_codes: set[int] | None = None,
) -> subprocess.CompletedProcess[bytes]:
    command = ["git"]
    if root is not None:
        command.extend(["-C", root])
    command.extend(arguments)
    result = subprocess.run(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    allowed = allowed_exit_codes or {0}
    if result.returncode not in allowed:
        diagnostic = result.stderr.decode("utf-8", errors="replace").strip()
        raise ScopeClassificationError(
            f"git command failed ({result.returncode}): {diagnostic}"
        )
    return result


def _repository_root() -> str:
    result = _git(None, ["rev-parse", "--show-toplevel"])
    raw_root = result.stdout.rstrip(b"\n")
    if not raw_root or b"\n" in raw_root or b"\x00" in raw_root:
        raise ScopeClassificationError("invalid Git worktree root")
    root = os.path.realpath(os.fsdecode(raw_root))
    if not os.path.isabs(root) or not os.path.isdir(root):
        raise ScopeClassificationError("Git worktree root is not an absolute directory")
    return root


def _oid(payload: bytes, label: str) -> str:
    try:
        value = payload.decode("ascii", errors="strict").strip()
    except UnicodeDecodeError as error:
        raise ScopeClassificationError(f"{label} is not ASCII") from error
    if OID.fullmatch(value) is None:
        raise ScopeClassificationError(f"{label} is not a canonical object ID")
    return value


def _head_oid(root: str) -> str:
    result = _git(
        root,
        ["rev-parse", "--verify", "--quiet", "HEAD^{commit}"],
        allowed_exit_codes={0, 1},
    )
    if result.returncode == 0:
        return _oid(result.stdout, "HEAD")
    if result.stdout or result.stderr:
        raise ScopeClassificationError("could not establish HEAD identity")
    return UNBORN_HEAD


def _index_tree_oid(root: str) -> str:
    return _oid(_git(root, ["write-tree"]).stdout, "index tree")


def _split_nul_records(payload: bytes, label: str) -> list[bytes]:
    if not payload:
        return []
    if not payload.endswith(b"\x00"):
        raise ScopeClassificationError(f"{label} is not NUL terminated")
    records = payload[:-1].split(b"\x00")
    if any(not record for record in records):
        raise ScopeClassificationError(f"{label} contains an empty record")
    return records


def _head_blob(root: str, head_oid: str, path_text: str) -> bytes | None:
    if head_oid == UNBORN_HEAD:
        return None
    path_bytes = os.fsencode(path_text)
    listing = _git(root, ["ls-tree", "-z", head_oid, "--", path_text]).stdout
    records = _split_nul_records(listing, f"HEAD listing for {path_text}")
    if not records:
        return None
    if len(records) != 1 or b"\t" not in records[0]:
        raise ScopeClassificationError(f"HEAD listing for {path_text} is ambiguous")
    metadata, path = records[0].split(b"\t", 1)
    fields = metadata.split(b" ")
    if len(fields) != 3 or path != path_bytes:
        raise ScopeClassificationError(f"HEAD entry for {path_text} is malformed")
    mode, object_type, object_id = fields
    if mode not in ALLOWED_BLOB_MODES or object_type != b"blob":
        raise ScopeClassificationError(f"HEAD entry for {path_text} is not a regular blob")
    return _git(root, ["cat-file", "blob", object_id.decode("ascii")]).stdout


def _index_entry(root: str, path_text: str) -> tuple[bytes, str] | None:
    path_bytes = os.fsencode(path_text)
    listing = _git(root, ["ls-files", "--stage", "-z", "--", path_text]).stdout
    records = _split_nul_records(listing, f"index listing for {path_text}")
    if not records:
        return None
    if len(records) != 1 or b"\t" not in records[0]:
        raise ScopeClassificationError(f"index listing for {path_text} is ambiguous")
    metadata, path = records[0].split(b"\t", 1)
    fields = metadata.split(b" ")
    if len(fields) != 3 or path != path_bytes:
        raise ScopeClassificationError(f"index entry for {path_text} is malformed")
    mode, object_id, stage_number = fields
    if mode not in ALLOWED_BLOB_MODES or stage_number != b"0":
        raise ScopeClassificationError(
            f"index entry for {path_text} is not a stage-0 regular blob"
        )
    return mode, _oid(object_id, f"index object for {path_text}")


def _index_blob(root: str, path_text: str) -> bytes | None:
    entry = _index_entry(root, path_text)
    if entry is None:
        return None
    return _git(root, ["cat-file", "blob", entry[1]]).stdout


def _verify_worktree_index_binding(root: str) -> None:
    unmerged = _git(root, ["ls-files", "--unmerged", "-z", "--"]).stdout
    if unmerged:
        raise ScopeClassificationError("the index contains unmerged entries")

    tracked_delta = _git(
        root,
        ["diff", "--no-ext-diff", "--name-only", "-z", "--"],
    ).stdout
    if tracked_delta:
        raise ScopeClassificationError("tracked worktree bytes differ from the index")

    untracked = _git(
        root,
        ["ls-files", "--others", "--exclude-standard", "-z", "--"],
    ).stdout
    if untracked:
        raise ScopeClassificationError("worktree contains untracked non-ignored paths")

    for path_text in sorted(WORKTREE_INDEX_BINDING_PATHS):
        entry = _index_entry(root, path_text)
        if entry is None:
            raise ScopeClassificationError(
                f"required control-plane path is absent from the index: {path_text}"
            )
        full_path = os.path.join(root, *path_text.split("/"))
        try:
            metadata = os.lstat(full_path)
        except FileNotFoundError as error:
            raise ScopeClassificationError(
                f"required control-plane path is absent from the worktree: {path_text}"
            ) from error
        if not stat.S_ISREG(metadata.st_mode):
            raise ScopeClassificationError(
                f"required control-plane worktree path is not regular: {path_text}"
            )
        with open(full_path, "rb") as source:
            worktree_blob = source.read()
        index_blob = _git(root, ["cat-file", "blob", entry[1]]).stdout
        if worktree_blob != index_blob:
            raise ScopeClassificationError(
                f"control-plane worktree blob differs from index: {path_text}"
            )


def _parse_source_roots(blob: bytes, label: str) -> set[bytes]:
    if b"\x00" in blob or b"\r" in blob:
        raise ScopeClassificationError(f"{label} contains unsafe control bytes")
    try:
        text = blob.decode("utf-8", errors="strict")
    except UnicodeDecodeError as error:
        raise ScopeClassificationError(f"{label} is not valid UTF-8") from error

    lines = text.split("\n")
    assignment_lines = [
        index
        for index, line in enumerate(lines)
        if re.match(r"^[ \t]*SOURCE_ROOTS", line)
    ]
    exact_starts = [
        index for index, line in enumerate(lines) if line == "SOURCE_ROOTS=("
    ]
    if len(assignment_lines) != 1 or assignment_lines != exact_starts:
        raise ScopeClassificationError(
            f"{label} must contain exactly one literal SOURCE_ROOTS array"
        )

    start = exact_starts[0]
    try:
        end = lines.index(")", start + 1)
    except ValueError as error:
        raise ScopeClassificationError(f"{label} SOURCE_ROOTS array is not closed") from error
    if end == start + 1:
        raise ScopeClassificationError(f"{label} SOURCE_ROOTS array is empty")

    roots: set[bytes] = set()
    for line in lines[start + 1 : end]:
        if COMMENT_LINE.fullmatch(line):
            continue
        match = SAFE_ROOT.fullmatch(line)
        if match is None:
            raise ScopeClassificationError(
                f"{label} SOURCE_ROOTS contains a non-literal entry"
            )
        root = match.group(1)
        if any(ord(character) < 32 for character in root):
            raise ScopeClassificationError(f"{label} SOURCE_ROOTS contains controls")
        if any(
            token in root
            for token in (
                "*",
                "?",
                "[",
                "]",
                "{",
                "}",
                ";",
                "|",
                "&",
                "<",
                ">",
                "(",
                ")",
            )
        ):
            raise ScopeClassificationError(f"{label} SOURCE_ROOTS contains shell syntax")
        path = PurePosixPath(root)
        if (
            not root
            or root.startswith("/")
            or root.endswith("/")
            or "//" in root
            or path.as_posix() != root
            or any(part in {"", ".", ".."} for part in path.parts)
        ):
            raise ScopeClassificationError(f"{label} SOURCE_ROOTS path is unsafe")
        encoded = root.encode("utf-8")
        if encoded in roots:
            raise ScopeClassificationError(f"{label} SOURCE_ROOTS contains duplicates")
        roots.add(encoded)

    if not roots:
        raise ScopeClassificationError(f"{label} SOURCE_ROOTS array is empty")

    trailing_assignment = any(
        re.match(r"^[ \t]*SOURCE_ROOTS", line) for line in lines[end + 1 :]
    )
    if trailing_assignment:
        raise ScopeClassificationError(f"{label} SOURCE_ROOTS array is ambiguous")
    return roots


def _staged_paths(root: str) -> list[bytes]:
    payload = _git(
        root,
        ["diff", "--cached", "--no-renames", "--name-only", "-z", "--"],
    ).stdout
    paths = _split_nul_records(payload, "staged path list")
    for path in paths:
        if path.startswith(b"/") or any(
            component in {b"", b".", b".."} for component in path.split(b"/")
        ):
            raise ScopeClassificationError("Git returned an unsafe staged path")
    return paths


def _matches(path: bytes, root: bytes) -> bool:
    return path == root or path.startswith(root + b"/")


def paths_affect_ui(
    paths: Iterable[bytes], old_roots: set[bytes], new_roots: set[bytes]
) -> bool:
    source_roots = old_roots | new_roots
    return any(
        path == DIGEST_PATH_BYTES
        or any(_matches(path, source_root) for source_root in source_roots)
        for path in paths
    )


def classify() -> tuple[str, str, str]:
    root = _repository_root()
    _verify_worktree_index_binding(root)
    initial_head_oid = _head_oid(root)
    initial_index_tree_oid = _index_tree_oid(root)

    old_blob = _head_blob(root, initial_head_oid, DIGEST_PATH)
    new_blob = _index_blob(root, DIGEST_PATH)
    if old_blob is None and new_blob is None:
        raise ScopeClassificationError("UI digest script is absent from HEAD and index")

    old_roots = _parse_source_roots(old_blob, "HEAD digest") if old_blob else set()
    new_roots = _parse_source_roots(new_blob, "index digest") if new_blob else set()
    if not old_roots and not new_roots:
        raise ScopeClassificationError("UI source root union is empty")

    paths = _staged_paths(root)
    path_texts = {os.fsdecode(path) for path in paths}
    classifier_in_head = (
        _head_blob(root, initial_head_oid, CLASSIFIER_PATH) is not None
    )

    if not classifier_in_head:
        missing = BOOTSTRAP_PATHS - path_texts
        extra = path_texts - BOOTSTRAP_PATHS
        if missing or extra:
            detail = []
            if missing:
                detail.append("missing=" + ",".join(sorted(missing)))
            if extra:
                detail.append("extra=" + ",".join(sorted(extra)))
            raise ScopeClassificationError(
                "first bootstrap index is not the exact control-plane allowlist: "
                + "; ".join(detail)
            )
        status_value = BOOTSTRAP
    elif path_texts & BOOTSTRAP_SOURCE_PATHS:
        status_value = AFFECTS_UI
    elif paths_affect_ui(paths, old_roots, new_roots):
        status_value = AFFECTS_UI
    else:
        status_value = NOT_APPLICABLE

    _verify_worktree_index_binding(root)
    final_head_oid = _head_oid(root)
    final_index_tree_oid = _index_tree_oid(root)
    if (
        final_head_oid != initial_head_oid
        or final_index_tree_oid != initial_index_tree_oid
    ):
        raise ScopeClassificationError(
            "HEAD or index tree changed during staged UI scope classification"
        )
    return status_value, initial_head_oid, initial_index_tree_oid


def main() -> int:
    try:
        status_value, head_oid, index_tree_oid = classify()
    except ScopeClassificationError as error:
        print(f"staged UI scope classification failed: {error}", file=sys.stderr)
        return 2
    if status_value not in {AFFECTS_UI, NOT_APPLICABLE, BOOTSTRAP}:
        print("staged UI scope classifier produced an invalid status", file=sys.stderr)
        return 2
    print(f"{status_value}\t{head_oid}\t{index_tree_oid}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
