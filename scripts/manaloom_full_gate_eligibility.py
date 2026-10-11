#!/usr/bin/env python3
"""G-10: quais tarefas IMPLEMENTED_LOCAL_PENDING_FULL_GATE ficam elegíveis a PASS
quando o gate `full` fica verde num SHA. Só lê: nunca edita o backlog, o
registry nem a fila, nunca grava no checkout e nunca fala com rede ou banco.

Lê tudo do próprio SHA, pelo Git (não do worktree):
- o registry (`docs/generated/TASK_REGISTRY.json`), ou `--registry-file`;
- as raízes do digest de UI (`scripts/manaloom_ui_source_digest.sh`).

Para cada tarefa pendente de full gate, confere:
- os commits citados no aceite (hex de 7 a 40) que existem no repositório
  precisam ser ancestrais do SHA; senão: `commit_citado_fora_do_sha`;
- os receipts citados (`docs/qa/execution/...`) precisam existir no SHA; senão:
  `receipt_ausente_no_sha`;
- cada dependência precisa estar em PASS ou ficar elegível nesta mesma
  rodada (ponto fixo); senão: `bloqueada_por_dependencia`;
- a prova de UI falha fechada. Os commits da tarefa vêm de três lugares: os
  citados no aceite, os citados dentro dos receipts citados (lidos do SHA) e
  os commits do SHA, sem merge, cuja mensagem cita o ID (inclusive em faixa,
  como `LC-P0-01..06` ou `BT-GATE-002/003`, e pela família no escopo do
  assunto, como `fix(LC-P0): ...`). Se algum caminho citado no aceite ou nos
  receipts, ou algum arquivo mudado por um desses commits, cai numa raiz do
  digest de UI, a tarefa é `elegivel_com_prova_ui`: o PASS exige também a
  prova de UI (PASS_VISUAL_REVIEWED) no mesmo SHA. Commit citado só como
  referência (a linha de base da produção, por exemplo) também conta: o erro
  fica do lado de pedir prova a mais;
- `elegivel` (sem prova de UI) exige rastro: pelo menos um commit da tarefa,
  ancestral do SHA e que não seja merge, que mude algo fora de `docs/` e do
  manifesto. Merge citado (o `master` em que o receipt foi conferido, por
  exemplo) conta para a UI, nunca como rastro. Sem rastro,
  a tarefa sai `elegivel_sem_rastro_de_ui`: ninguém sabe o que ela mudou, e
  ela só sobe com a prova de UI ou depois que o aceite citar os commits dela
  e a lista for refeita. A busca nunca prova que não há outro commit: o
  receipt lista os commits conferidos.
O aceite que declara pendência ("Segue aberto", "Falta:") é marcado para
revisão humana: a elegibilidade nunca decide sozinha que a pendência fechou.

Com `--receipt`, confere a estrutura do receipt forte do full
(`manaloom.gate_run_receipt.v1`, gate `local_ci` em `full`, `e2e` ou
`release`, PASS, `gate_eligible`, fonte estável e limpa, mesmo SHA). A prova
forte é `scripts/manaloom_gate_run_receipt.py validate` num checkout do SHA.
Sem `--receipt`, a lista é condicional ("se o full estiver verde neste SHA").

Uso:
  scripts/manaloom_full_gate_eligibility.py --sha SHA [--receipt receipt.json]
      [--registry-file TASK_REGISTRY.json] [--format md|json] [--repo DIR]

Saída: 0 com a lista; 2 entrada inválida (SHA, registry); 3 receipt inválido
(nenhuma tarefa sobe: a lista sai como bloqueada pelo receipt).
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

SCHEMA = "manaloom.full_gate_eligibility.v1"
PENDING = "IMPLEMENTED_LOCAL_PENDING_FULL_GATE"
REGISTRY_PATH = "docs/generated/TASK_REGISTRY.json"
UI_DIGEST_SCRIPT = "scripts/manaloom_ui_source_digest.sh"
RECEIPT_SCHEMA = "manaloom.gate_run_receipt.v1"
RECEIPT_MODES_COVERING_FULL = ("full", "e2e", "release")
HEX = re.compile(r"(?<![0-9A-Za-z])[0-9a-f]{7,40}(?![0-9A-Za-z])")
BACKTICKED = re.compile(r"`([^`\s]+)`")
REPO_TOP_DIRS = (
    ".githooks/", "app/", "docs/", "scripts/", "server/", "services/", "tools/",
    "web-public/",
)
OPEN_ITEMS = re.compile(r"Segue aberto|Falta:|Falta fazer|pendente de decis", re.I)
FULL_SHA = re.compile(r"^[0-9a-f]{40}$")
# Faixa ou lista de IDs numa mensagem: `LC-P0-01..06`, `BT-GATE-002/003`.
ID_SERIES = re.compile(
    r"(?<![0-9A-Za-z-])(?P<prefix>[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-)(?P<first>\d+)"
    r"(?P<rest>(?:(?:\.\.|/)(?:(?P=prefix))?\d+)+)(?![0-9A-Za-z])"
)
SERIES_STEP = re.compile(r"(\.\.|/)(?:[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-)?(\d+)")
MAX_SERIES = 99
# Escopo do assunto de um commit convencional: `fix(LC-P0, BT-UX-01): ...`.
SUBJECT_SCOPE = re.compile(r"^[A-Za-z]+\(([^)]*)\)!?:")
# Mudança que não conta como rastro de implementação: só documentação e o
# manifesto gerado (backlog, registry, receipts, fila).
NON_IMPLEMENTATION = ("docs/", "project_logic_manifest.json")


class InvalidInput(Exception):
    pass


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    result = subprocess.run(
        ["git", "-C", str(repo), *args], capture_output=True, text=True,
        encoding="utf-8", errors="replace",
    )
    if check and result.returncode != 0:
        raise InvalidInput(f"git {' '.join(args)}: {result.stderr.strip()}")
    return result


def resolve_sha(repo: Path, sha: str) -> str:
    result = git(repo, "rev-parse", "--verify", "--quiet", f"{sha}^{{commit}}",
                 check=False)
    resolved = result.stdout.strip()
    if result.returncode != 0 or not FULL_SHA.match(resolved):
        raise InvalidInput(f"SHA desconhecido: {sha}")
    return resolved


def show(repo: Path, sha: str, path: str) -> str | None:
    result = git(repo, "show", f"{sha}:{path}", check=False)
    return result.stdout if result.returncode == 0 else None


def exists_at(repo: Path, sha: str, path: str) -> bool:
    return git(repo, "cat-file", "-e", f"{sha}:{path}", check=False).returncode == 0


def ui_roots(repo: Path, sha: str) -> list[str]:
    """Raízes do digest de UI no SHA; sem o script, todo `app/` conta como UI."""
    text = show(repo, sha, UI_DIGEST_SCRIPT)
    if text is None:
        return ["app/"]
    block = re.search(r"SOURCE_ROOTS=\((.*?)\n\)", text, re.S)
    if block is None:
        return ["app/"]
    roots = re.findall(r'^\s*"([^"]+)"', block.group(1), re.M)
    return roots or ["app/"]


def under(path: str, roots: list[str]) -> bool:
    for root in roots:
        bare = root.rstrip("/")
        if path == bare or path.startswith(bare + "/"):
            return True
    return False


def cited_paths(text: str) -> list[str]:
    paths: list[str] = []
    for token in BACKTICKED.findall(text):
        token = token.split("#", 1)[0].rstrip(".,;:)")
        token = re.sub(r":\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*$", "", token)
        if token.startswith(REPO_TOP_DIRS) and "*" not in token and token not in paths:
            paths.append(token)
    return paths


def cited_commits(repo: Path, text: str) -> tuple[list[str], list[str]]:
    """Commits citados que existem no repositório, e os hex que não resolvem."""
    found: list[str] = []
    unknown: list[str] = []
    for token in dict.fromkeys(HEX.findall(text)):
        result = git(repo, "rev-parse", "--verify", "--quiet", f"{token}^{{commit}}",
                     check=False)
        if result.returncode == 0 and FULL_SHA.match(result.stdout.strip()):
            found.append(result.stdout.strip())
        else:
            unknown.append(token)
    return found, unknown


def is_ancestor(repo: Path, commit: str, sha: str) -> bool:
    return git(repo, "merge-base", "--is-ancestor", commit, sha,
               check=False).returncode == 0


def changed_files(repo: Path, commit: str,
                  cache: dict[str, list[str]] | None = None) -> list[str]:
    if cache is not None and commit in cache:
        return cache[commit]
    result = git(repo, "show", "--name-only", "--format=", "-m", commit, check=False)
    files = list(dict.fromkeys(
        line for line in result.stdout.splitlines() if line.strip()))
    if cache is not None:
        cache[commit] = files
    return files


def family(task_id: str) -> str | None:
    """`LC-P0-03` -> `LC-P0`; ID sem número final não tem família."""
    match = re.match(r"^(.+)-\d+$", task_id)
    return match.group(1) if match else None


def mentioned_ids(message: str, wanted: set[str], direct: re.Pattern[str],
                  families: dict[str, set[str]]) -> set[str]:
    """IDs de `wanted` citados numa mensagem de commit: direto, em faixa ou
    lista (`LC-P0-01..06`, `BT-GATE-002/003`) e pela família no escopo do
    assunto (`fix(LC-P0): ...`)."""
    found = set(direct.findall(message))
    for match in ID_SERIES.finditer(message):
        prefix, first = match.group("prefix"), match.group("first")
        width, current = len(first), int(first)
        numbers = {current}
        for separator, number in SERIES_STEP.findall(match.group("rest")):
            value = int(number)
            if separator == ".." and current < value <= current + MAX_SERIES:
                numbers.update(range(current, value + 1))
            else:
                numbers.add(value)
            current = value
        for number in numbers:
            candidate = f"{prefix}{number:0{width}d}"
            if candidate in wanted:
                found.add(candidate)
    subject = message.split("\n", 1)[0]
    scope = SUBJECT_SCOPE.match(subject)
    if scope is not None:
        for token in re.split(r"[\s,;/]+", scope.group(1)):
            found.update(families.get(token, ()))
    return found & wanted


def commits_by_task(repo: Path, sha: str, ids: set[str]) -> dict[str, list[str]]:
    """Commits do SHA (sem merge, do mais novo ao mais velho) cuja mensagem
    cita cada ID."""
    if not ids:
        return {}
    direct = re.compile(
        r"(?<![0-9A-Za-z-])("
        + "|".join(re.escape(task_id) for task_id in sorted(ids, key=len, reverse=True))
        + r")(?![0-9A-Za-z])"
    )
    families: dict[str, set[str]] = {}
    for task_id in ids:
        name = family(task_id)
        if name is not None:
            families.setdefault(name, set()).add(task_id)
    log = git(repo, "log", "--no-merges", "--format=%H%x00%B%x1e", sha).stdout
    found: dict[str, list[str]] = {}
    for record in log.split("\x1e"):
        commit, _, message = record.strip("\n").partition("\x00")
        if not FULL_SHA.match(commit):
            continue
        for task_id in mentioned_ids(message, ids, direct, families):
            found.setdefault(task_id, []).append(commit)
    return found


def is_implementation(files: list[str]) -> bool:
    return any(not path.startswith(NON_IMPLEMENTATION) for path in files)


def check_receipt(path: Path, sha: str) -> dict[str, Any]:
    problems: list[str] = []
    try:
        receipt = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return {"status": "invalido", "path": str(path),
                "problems": [f"não li o receipt: {error}"]}
    if not isinstance(receipt, dict):
        return {"status": "invalido", "path": str(path),
                "problems": ["o receipt não é um objeto"]}
    gate = receipt.get("gate") if isinstance(receipt.get("gate"), dict) else {}
    source = receipt.get("source") if isinstance(receipt.get("source"), dict) else {}
    start = source.get("start") if isinstance(source.get("start"), dict) else {}
    if receipt.get("schema") != RECEIPT_SCHEMA:
        problems.append(f"schema não é {RECEIPT_SCHEMA}")
    if gate.get("id") != "local_ci" or gate.get("mode") not in RECEIPT_MODES_COVERING_FULL:
        problems.append("gate não é local_ci em full, e2e ou release")
    if receipt.get("status") != "PASS":
        problems.append(f"status {receipt.get('status')!r}, não PASS")
    if receipt.get("gate_eligible") is not True:
        problems.append("gate_eligible não é true")
    if receipt.get("git_sha") != sha:
        problems.append(f"git_sha {str(receipt.get('git_sha'))[:12]} não é o SHA pedido")
    if source.get("stable") is not True:
        problems.append("fonte instável durante o gate")
    if start.get("git_dirty") is not False:
        problems.append("worktree sujo no início do gate")
    return {
        "status": "valido" if not problems else "invalido",
        "path": str(path),
        "mode": gate.get("mode"),
        "completed_at": receipt.get("completed_at"),
        "problems": problems,
    }


def evaluate(repo: Path, sha: str, registry: dict[str, Any],
             registry_source: str, registry_sha256: str,
             receipt: dict[str, Any] | None) -> dict[str, Any]:
    tasks = registry.get("tasks")
    if not isinstance(tasks, list):
        raise InvalidInput("registry sem a lista tasks")
    by_id: dict[str, dict[str, Any]] = {}
    for task in tasks:
        if not isinstance(task, dict) or not isinstance(task.get("id"), str):
            raise InvalidInput("registry com tarefa sem id")
        by_id[task["id"]] = task
    roots = ui_roots(repo, sha)
    pending_ids = {task["id"] for task in tasks if task.get("status") == PENDING}
    by_message = commits_by_task(repo, sha, pending_ids)
    files_cache: dict[str, list[str]] = {}
    ancestry: dict[str, bool] = {}
    merges: dict[str, bool] = {}

    def ancestor(commit: str) -> bool:
        if commit not in ancestry:
            ancestry[commit] = is_ancestor(repo, commit, sha)
        return ancestry[commit]

    def merge(commit: str) -> bool:
        if commit not in merges:
            parents = git(repo, "rev-list", "--parents", "-n", "1", commit).stdout
            merges[commit] = len(parents.split()) > 2
        return merges[commit]

    rows: dict[str, dict[str, Any]] = {}
    for task in tasks:
        if task.get("status") != PENDING:
            continue
        text = f"{task.get('delivery', '')} {task.get('acceptance', '')}"
        commits, unknown = cited_commits(repo, text)
        outside = [commit for commit in commits if not ancestor(commit)]
        paths = cited_paths(text)
        receipts = [path for path in paths
                    if path.startswith("docs/qa/execution/")
                    and path.endswith((".md", ".json"))]
        missing_receipts = [path for path in receipts if not exists_at(repo, sha, path)]
        missing_paths = [path for path in paths
                         if path not in receipts and not exists_at(repo, sha, path)]
        ui_paths = sorted(path for path in paths if under(path, roots))
        # O que os receipts citados (no SHA) dizem: caminhos e commits.
        receipt_paths: list[str] = []
        receipt_commits: list[str] = []
        for receipt_path in receipts:
            receipt_text = show(repo, sha, receipt_path)
            if receipt_text is None:
                continue
            for path in cited_paths(receipt_text):
                if path not in receipt_paths:
                    receipt_paths.append(path)
            for commit in cited_commits(repo, receipt_text)[0]:
                if commit not in commits and commit not in receipt_commits:
                    receipt_commits.append(commit)
        ui_paths_from_receipts = sorted(
            path for path in receipt_paths
            if under(path, roots) and path not in ui_paths
        )
        message_commits = [
            commit for commit in by_message.get(task["id"], [])
            if commit not in commits and commit not in receipt_commits
        ]
        task_commits = commits + receipt_commits + message_commits
        implementation_commits = [
            commit for commit in task_commits
            if ancestor(commit) and not merge(commit) and is_implementation(
                changed_files(repo, commit, files_cache))
        ]
        ui_commits: list[str] = []
        from_commits: set[str] = set()
        for commit in task_commits:
            touched = [path for path in changed_files(repo, commit, files_cache)
                       if under(path, roots)]
            if touched:
                ui_commits.append(commit)
                from_commits.update(touched)
        ui_paths_from_commits = sorted(
            path for path in from_commits
            if path not in ui_paths and path not in ui_paths_from_receipts
        )
        open_items = OPEN_ITEMS.search(text)
        rows[task["id"]] = {
            "id": task["id"],
            "priority": task.get("priority"),
            "depends_on": list(task.get("depends_on") or []),
            "cited_commits": commits,
            "unresolved_hex": unknown,
            "commits_outside_sha": outside,
            "receipts": receipts,
            "missing_receipts": missing_receipts,
            "missing_paths": missing_paths,
            "receipt_commits": receipt_commits,
            "receipt_commits_outside_sha": [
                commit for commit in receipt_commits if not ancestor(commit)
            ],
            "message_commits": message_commits,
            "implementation_commits": implementation_commits,
            "ui_commits": ui_commits,
            "ui_paths": ui_paths,
            "ui_paths_from_receipts": ui_paths_from_receipts,
            "ui_paths_from_commits": ui_paths_from_commits,
            "declares_open_items": open_items is not None,
            "open_items_excerpt": (
                text[open_items.start():open_items.start() + 240].strip()
                if open_items else None
            ),
        }

    evidence_ok = {
        task_id for task_id, row in rows.items()
        if not row["commits_outside_sha"] and not row["missing_receipts"]
    }
    eligible = set(evidence_ok)
    changed = True
    while changed:
        changed = False
        for task_id in sorted(eligible):
            for dep in rows[task_id]["depends_on"]:
                status = by_id.get(dep, {}).get("status")
                if status != "PASS" and dep not in eligible:
                    eligible.discard(task_id)
                    changed = True
                    break

    receipt_blocks = receipt is not None and receipt["status"] != "valido"
    for task_id, row in rows.items():
        row["open_dependencies"] = [
            {"id": dep, "status": by_id.get(dep, {}).get("status", "DESCONHECIDA")}
            for dep in row["depends_on"]
            if by_id.get(dep, {}).get("status") != "PASS" and dep not in eligible
        ]
        if row["commits_outside_sha"]:
            row["classification"] = "commit_citado_fora_do_sha"
        elif row["missing_receipts"]:
            row["classification"] = "receipt_ausente_no_sha"
        elif task_id not in eligible:
            row["classification"] = "bloqueada_por_dependencia"
        elif (row["ui_paths"] or row["ui_paths_from_receipts"]
              or row["ui_paths_from_commits"]):
            row["classification"] = "elegivel_com_prova_ui"
        elif not row["implementation_commits"]:
            row["classification"] = "elegivel_sem_rastro_de_ui"
        else:
            row["classification"] = "elegivel"
        if receipt_blocks and row["classification"].startswith("elegivel"):
            row["classification"] = "bloqueada_pelo_receipt"

    ordered = [rows[task["id"]] for task in tasks if task["id"] in rows]
    counts: dict[str, int] = {}
    for row in ordered:
        counts[row["classification"]] = counts.get(row["classification"], 0) + 1
    return {
        "schema": SCHEMA,
        "sha": sha,
        "registry": {"source": registry_source, "sha256": registry_sha256},
        "full_receipt": receipt or {"status": "nao_informado"},
        "conditional": receipt is None,
        "pending_status": PENDING,
        "ui_roots": roots,
        "summary": {"pending": len(ordered), **dict(sorted(counts.items()))},
        "tasks": ordered,
    }


def to_markdown(result: dict[str, Any]) -> str:
    receipt = result["full_receipt"]
    lines = [
        f"# Elegibilidade a PASS no SHA `{result['sha']}`",
        "",
        f"- Registry: `{result['registry']['source']}` "
        f"(sha256 `{result['registry']['sha256']}`)",
        f"- Receipt do full: {receipt['status']}"
        + (f" (`{receipt.get('path')}`, modo {receipt.get('mode')})"
           if receipt["status"] != "nao_informado" else
           "; lista condicional: vale só se o full estiver verde neste SHA"),
    ]
    for problem in receipt.get("problems", []):
        lines.append(f"  - {problem}")
    lines += [
        f"- Pendentes de full gate: {result['summary']['pending']}",
        "",
        "| Classe | Quantidade |",
        "| --- | ---: |",
    ]
    for key, value in result["summary"].items():
        if key != "pending":
            lines.append(f"| `{key}` | {value} |")
    lines += [
        "",
        "| Tarefa | Prioridade | Classe | Dependências abertas | Receipts "
        "| Commits da tarefa | Revisar |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in result["tasks"]:
        deps = ", ".join(f"`{d['id']}` ({d['status']})" for d in row["open_dependencies"])
        receipts = ", ".join(f"`{path}`" for path in row["receipts"]) or "nenhum citado"
        shown = row["implementation_commits"][:6]
        task_commits = ", ".join(f"`{commit[:9]}`" for commit in shown) or "nenhum"
        if len(row["implementation_commits"]) > len(shown):
            task_commits += f" e mais {len(row['implementation_commits']) - len(shown)}"
        review = []
        if row["declares_open_items"]:
            review.append("aceite declara pendência")
        if row["commits_outside_sha"]:
            review.append("commit fora do SHA: " + ", ".join(
                c[:9] for c in row["commits_outside_sha"]))
        if row["missing_receipts"]:
            review.append("receipt ausente")
        if row["missing_paths"]:
            review.append(f"{len(row['missing_paths'])} caminho(s) citado(s) fora do SHA")
        if row["receipt_commits_outside_sha"]:
            review.append("receipt cita commit fora do SHA: " + ", ".join(
                c[:9] for c in row["receipt_commits_outside_sha"]))
        if (row["ui_paths"] or row["ui_paths_from_receipts"]
                or row["ui_paths_from_commits"]):
            review.append(
                f"prova de UI ({len(row['ui_paths'])} caminho(s) citado(s), "
                f"{len(row['ui_paths_from_receipts'])} pelos receipts, "
                f"{len(row['ui_paths_from_commits'])} por commit da tarefa: "
                + ", ".join(c[:9] for c in row["ui_commits"][:6]) + ")"
            )
        elif not row["implementation_commits"]:
            review.append(
                "sem commit da tarefa no SHA: a prova de UI não pode ser "
                "dispensada sem citar os commits"
            )
        lines.append(
            f"| `{row['id']}` | {row['priority']} | `{row['classification']}` | "
            f"{deps or '—'} | {receipts} | {task_commits} | "
            f"{'; '.join(review) or '—'} |"
        )
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--sha", required=True)
    parser.add_argument("--receipt", type=Path)
    parser.add_argument("--registry-file", type=Path)
    parser.add_argument("--format", choices=("md", "json"), default="md")
    parser.add_argument("--repo", type=Path,
                        default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args(argv)
    try:
        repo = args.repo.resolve()
        sha = resolve_sha(repo, args.sha)
        if args.registry_file is not None:
            try:
                raw = args.registry_file.read_bytes()
            except OSError as error:
                raise InvalidInput(f"não li {args.registry_file}: {error}") from error
            source = str(args.registry_file)
        else:
            text = show(repo, sha, REGISTRY_PATH)
            if text is None:
                raise InvalidInput(f"{REGISTRY_PATH} não existe no SHA {sha[:12]}")
            raw = text.encode("utf-8")
            source = f"git:{sha}:{REGISTRY_PATH}"
        try:
            registry = json.loads(raw)
        except json.JSONDecodeError as error:
            raise InvalidInput(f"registry ilegível: {error}") from error
        if not isinstance(registry, dict):
            raise InvalidInput("registry não é um objeto")
        receipt = check_receipt(args.receipt, sha) if args.receipt else None
        result = evaluate(repo, sha, registry, source,
                          hashlib.sha256(raw).hexdigest(), receipt)
    except InvalidInput as error:
        print(json.dumps({"status": "invalid", "error": str(error)},
                         ensure_ascii=False))
        return 2
    if args.format == "json":
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        sys.stdout.write(to_markdown(result))
    return 3 if receipt is not None and receipt["status"] != "valido" else 0


if __name__ == "__main__":
    sys.exit(main())
