#!/usr/bin/env python3
"""Incremental Flutter UI/UX audit pipeline for Hermes.

This is the LLM-backed companion to the deterministic static UI auditor. Each
run sends a small batch of screen/widget files to Hermes, appends Hermes'
response to the memory report, and advances state only when the response ends
with a valid UI_AUDIT_BATCH_RESULT marker.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


def _discover_repo() -> Path:
    candidates = [Path.cwd(), Path(__file__).resolve()]
    for candidate in candidates:
        for parent in [candidate, *candidate.parents]:
            if (parent / ".git").exists() and (parent / "app/lib").exists():
                return parent
    return Path("/opt/data/workspace/mtgia")


REPO_DIR = Path(os.environ.get("MTGIA_REPO", str(_discover_repo())))
SYNC_REPO_DIR = Path(
    os.environ.get("MTGIA_SYNC_REPO", "/opt/data/workspace/mtgia-sync")
)
APP_DIR = Path(os.environ.get("MTGIA_APP_DIR", str(SYNC_REPO_DIR / "app/lib")))
REPORT_FILE = Path(
    os.environ.get(
        "UI_AUDIT_REPORT_FILE",
        str(REPO_DIR / "docs/hermes-analysis/FLUTTER_UI_AUDIT.md"),
    )
)
STATE_FILE = Path(
    os.environ.get(
        "UI_AUDIT_STATE_FILE",
        str(REPO_DIR / "docs/hermes-analysis/.ui_audit_state.json"),
    )
)
HERMES_BIN = Path(os.environ.get("HERMES_BIN", "/opt/hermes/.venv/bin/hermes"))
BATCH_SIZE = int(os.environ.get("UI_AUDIT_BATCH", "2"))
MAX_FILE_CHARS = int(os.environ.get("UI_AUDIT_MAX_FILE_CHARS", "5000"))
HERMES_TIMEOUT_SECONDS = int(os.environ.get("UI_AUDIT_TIMEOUT_SECONDS", "600"))
RESULT_RE = re.compile(
    r"UI_AUDIT_BATCH_RESULT:\s*audited=(?P<audited>\d+)\s+"
    r"findings=(?P<findings>\d+)\s+P0=(?P<p0>\d+)\s+"
    r"P1=(?P<p1>\d+)\s+P2=(?P<p2>\d+)"
)

CHECKLIST = """## Checklist por tela

Verifique somente os arquivos recebidos neste batch:

### A. Strings e copy
- Placeholder generico, TODO, lorem ipsum, teste ou copy improvisada.
- Texto muito longo, impessoal ou gerado por IA.
- Plural/singular incorreto.
- Texto sem overflow/truncamento seguro.

### B. Design system
- Cor hardcoded fora de tokens/AppTheme.
- Padding/margin inconsistente entre telas similares.
- Fonte/tamanho divergente do padrao premium ManaLoom.
- Card, borda, sombra ou background fora do padrao Meus Decks/Home.

### C. Estados
- Loading, erro, vazio ou disabled ausente.
- Falha visual com rede lenta ou imagem remota quebrada.

### D. Icones e semantica
- IconButton sem tooltip.
- Botao so com icone sem semanticLabel quando o significado nao e obvio.
- Touch target possivelmente menor que 48x48.

### E. Dados mock/hardcoded
- Fixture, lista fixa ou path local que pode vazar para producao.
- Diferenciar compatibilidade com contrato backend de mock indevido.

### F. Acessibilidade
- Contraste suspeito.
- Elemento interativo custom sem Semantics/Tooltip.

Saida obrigatoria por finding:
- [P0/P1/P2] arquivo:linha - descricao - sugestao

P0 bloqueia release, P1 deve entrar no backlog imediato, P2 e melhoria/cosmetico.
"""


def run(cmd: list[str], cwd: Path, timeout: int = 30) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
        capture_output=True,
        timeout=timeout,
    )


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(APP_DIR))
    except ValueError:
        return str(path)


def find_screen_files() -> list[Path]:
    files: list[Path] = []
    if not APP_DIR.exists():
        return files
    for path in APP_DIR.rglob("*.dart"):
        relative = rel(path)
        lower = relative.lower()
        if path.name.endswith(".g.dart"):
            continue
        if any(token in lower for token in ("screen", "widget", "page", "view")):
            files.append(path)
    return sorted(files)


def load_state() -> dict:
    if STATE_FILE.exists():
        try:
            state = json.loads(STATE_FILE.read_text())
            if isinstance(state, dict):
                return {
                    "audited": state.get("audited", {}),
                    "cycle": state.get("cycle", 1),
                    "last_run": state.get("last_run"),
                }
        except Exception:
            pass
    return {"audited": {}, "cycle": 1, "last_run": None}


def save_state(state: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n")


def append_report(text: str) -> None:
    REPORT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with REPORT_FILE.open("a") as report:
        report.write(text.rstrip())
        report.write("\n")


def sync_master_workspace() -> None:
    if not (SYNC_REPO_DIR / ".git").exists():
        return
    result = run(
        ["git", "pull", "--ff-only", "origin", "master"],
        cwd=SYNC_REPO_DIR,
        timeout=45,
    )
    if result.returncode == 0:
        print(f"Sync workspace updated: {SYNC_REPO_DIR}")
    else:
        print((result.stderr or result.stdout or "").strip())


def render_cycle_summary(state: dict, total_files: int) -> None:
    audited = state.get("audited", {})
    p0 = sum(int(v.get("p0", 0)) for v in audited.values())
    p1 = sum(int(v.get("p1", 0)) for v in audited.values())
    p2 = sum(int(v.get("p2", 0)) for v in audited.values())
    now = datetime.now(timezone.utc).isoformat()
    append_report(
        f"""
---
## Resumo ciclo {state.get('cycle', 1)}

- Total de arquivos UI: `{total_files}`
- Findings P0: `{p0}`
- Findings P1: `{p1}`
- Findings P2: `{p2}`
- Concluido em UTC: `{now}`
- Proximo ciclo: `{int(state.get('cycle', 1)) + 1}`

---
"""
    )


def build_prompt(batch: list[Path], cycle: int) -> str:
    file_contents: list[str] = []
    for path in batch:
        relative = rel(path)
        try:
            content = path.read_text(errors="replace")
            if len(content) > MAX_FILE_CHARS:
                content = (
                    content[:MAX_FILE_CHARS]
                    + f"\n... (truncado, +{len(content) - MAX_FILE_CHARS} chars)"
                )
            file_contents.append(
                f"### Arquivo: {relative}\n```dart\n{content}\n```\n"
            )
        except Exception as exc:
            file_contents.append(f"### Arquivo: {relative}\nERRO LEITURA: {exc}\n")

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M")
    return f"""## Flutter UI/UX Audit - Ciclo {cycle} - {now} UTC

Workdir informativo: {REPO_DIR}
Nao edite arquivos.
Nao commite.
Retorne somente a auditoria solicitada.

{CHECKLIST}

### Arquivos para auditar neste batch

{''.join(file_contents)}

### Instrucoes finais
1. Analise cada arquivo individualmente.
2. Liste apenas findings com evidencia concreta no codigo recebido.
3. Se nao houver findings, escreva `Nenhum finding - OK`.
4. Nao invente telas, screenshots ou validacao em simulator.
5. Termine obrigatoriamente com:
UI_AUDIT_BATCH_RESULT: audited={len(batch)} findings=N P0=X P1=Y P2=Z
"""


def run_hermes(prompt: str) -> tuple[int, str]:
    if not HERMES_BIN.exists():
        return 127, f"Hermes binary not found: {HERMES_BIN}"
    result = subprocess.run(
        [str(HERMES_BIN), "--accept-hooks", "-z", prompt],
        cwd=REPO_DIR,
        text=True,
        capture_output=True,
        timeout=HERMES_TIMEOUT_SECONDS,
        env={
            **os.environ,
            "OPENCODE_GO_API_KEY": os.environ.get("OPENCODE_GO_API_KEY", ""),
        },
    )
    return result.returncode, (result.stdout or "") + (result.stderr or "")


def parse_result(output: str) -> dict[str, int] | None:
    matches = list(RESULT_RE.finditer(output))
    if not matches:
        return None
    match = matches[-1]
    return {key: int(value) for key, value in match.groupdict().items()}


def main() -> int:
    print("=== Flutter UI Audit Pipeline ===")
    sync_master_workspace()

    files = find_screen_files()
    state = load_state()
    audited: dict = state.setdefault("audited", {})
    pending = [path for path in files if rel(path) not in audited]

    if not pending:
        print("Cycle complete; writing summary and resetting state.")
        render_cycle_summary(state, len(files))
        save_state({"audited": {}, "cycle": int(state.get("cycle", 1)) + 1, "last_run": None})
        return 0

    batch = pending[:BATCH_SIZE]
    print(f"Pending files: {len(pending)}; auditing batch: {len(batch)}")
    for path in batch:
        print(f"  {rel(path)}")

    code, output = run_hermes(build_prompt(batch, int(state.get("cycle", 1))))
    print(output[-1000:] if len(output) > 1000 else output)
    parsed = parse_result(output)
    if code != 0 or parsed is None or parsed["audited"] != len(batch):
        append_report(
            f"""
---
## Falha UI audit ciclo {state.get('cycle', 1)} - {datetime.now(timezone.utc).isoformat()}

- Return code: `{code}`
- Batch esperado: `{len(batch)}`
- Resultado parseado: `{parsed}`

```text
{output[-4000:]}
```
"""
        )
        print("UI audit failed or missing result marker; state not advanced.")
        return 1

    header = (
        f"\n---\n## Ciclo {state.get('cycle', 1)} - "
        f"{datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')} UTC\n\n"
    )
    append_report(header + output)

    now = datetime.now(timezone.utc).isoformat()
    # Store aggregate counts on the first file and mark the rest as audited. This
    # avoids fragile per-file parsing while preserving cycle progress.
    for index, path in enumerate(batch):
        audited[rel(path)] = {
            "audited_at": now,
            "findings": parsed["findings"] if index == 0 else 0,
            "p0": parsed["p0"] if index == 0 else 0,
            "p1": parsed["p1"] if index == 0 else 0,
            "p2": parsed["p2"] if index == 0 else 0,
        }
    state["last_run"] = now
    save_state(state)
    print(
        f"State updated: {len(audited)}/{len(files)} files audited "
        f"in cycle {state.get('cycle', 1)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
