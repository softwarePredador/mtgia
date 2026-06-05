#!/usr/bin/env python3
"""Deterministic Flutter UI/UX static audit for ManaLoom.

The Hermes cron uses this as the low-cost UI radar. It intentionally performs a
static scan only: it does not claim simulator screenshots or visual proof.
"""

from __future__ import annotations

import dataclasses
import os
import re
import subprocess
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

MAX_FINDINGS_PER_RULE = int(os.environ.get("UI_STATIC_MAX_FINDINGS_PER_RULE", "80"))


def discover_repo() -> Path:
    explicit = os.environ.get("MTGIA_REPO")
    if explicit:
        return Path(explicit)
    candidates = [Path.cwd(), Path(__file__).resolve()]
    for candidate in candidates:
        for parent in [candidate, *candidate.parents]:
            if (parent / ".git").exists() and (parent / "app/lib").exists():
                return parent
    return Path("/opt/data/workspace/mtgia")


MEMORY_REPO = Path(os.environ.get("MTGIA_MEMORY_REPO", str(discover_repo())))
_default_scan_repo = Path("/opt/data/workspace/mtgia-sync")
SCAN_REPO = Path(
    os.environ.get(
        "MTGIA_SCAN_REPO",
        str(_default_scan_repo if _default_scan_repo.exists() else MEMORY_REPO),
    )
)
SCOPES = [
    Path(p)
    for p in os.environ.get(
        "UI_STATIC_SCOPES",
        f"{SCAN_REPO / 'app/lib/features'}:{SCAN_REPO / 'app/lib/core'}",
    ).split(":")
    if p
]
REPORT = Path(
    os.environ.get(
        "UI_STATIC_REPORT_FILE",
        str(MEMORY_REPO / "docs/hermes-analysis/FLUTTER_UI_AUDIT.md"),
    )
)


@dataclasses.dataclass(frozen=True)
class Finding:
    priority: str
    rule: str
    path: str
    line: int
    evidence: str
    impact: str
    suggestion: str


def run(cmd: list[str], cwd: Path = SCAN_REPO, timeout: int = 20) -> str:
    try:
        out = subprocess.run(
            cmd,
            cwd=cwd,
            text=True,
            capture_output=True,
            timeout=timeout,
        )
        return (out.stdout or out.stderr or "").strip()
    except Exception as exc:
        return f"unavailable: {exc}"


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(SCAN_REPO))
    except ValueError:
        return str(path)


def dart_files() -> list[Path]:
    files: list[Path] = []
    for scope in SCOPES:
        if not scope.exists():
            continue
        files.extend(
            p
            for p in scope.rglob("*.dart")
            if not p.name.endswith(".g.dart") and "/test/" not in str(p)
        )
    return sorted(files)


def strip_for_signal(line: str) -> str:
    return line.strip().replace("\t", " ")[:220]


def is_comment_only(line: str) -> bool:
    s = line.strip()
    return s.startswith("//") or s.startswith("*") or s.startswith("/*")


def block(lines: list[str], start: int, max_lines: int = 28) -> str:
    return "\n".join(lines[start : min(len(lines), start + max_lines)])


def call_block(lines: list[str], start: int, max_lines: int = 220) -> str:
    depth = 0
    started = False
    collected: list[str] = []
    for line in lines[start : min(len(lines), start + max_lines)]:
        collected.append(line)
        depth += line.count("(")
        depth -= line.count(")")
        if "(" in line:
            started = True
        if started and depth <= 0:
            break
    return "\n".join(collected)


def has_visible_text_label(text: str) -> bool:
    return bool(
        re.search(r"\b(?:Text|SelectableText|RichText)\s*\(", text),
    )


def has_explicit_min_touch_target(text: str) -> bool:
    min_dimension = re.search(
        r"\b(width|height)\s*:\s*(?:4[8-9]|[5-9]\d|\d{3,})(?:\.0)?\b",
        text,
    )
    min_constraint = re.search(
        r"\b(minWidth|minHeight)\s*:\s*(?:4[8-9]|[5-9]\d|\d{3,})(?:\.0)?\b",
        text,
    )
    material_min = "minimumSize:" in text and re.search(
        r"Size\s*\(\s*(?:4[8-9]|[5-9]\d|\d{3,})(?:\.0)?\s*,\s*"
        r"(?:4[8-9]|[5-9]\d|\d{3,})(?:\.0)?\s*\)",
        text,
    )
    return bool(min_dimension or min_constraint or material_min)


def is_theme_foundation(path: Path) -> bool:
    rpath = rel(path).lower()
    return "/theme/" in rpath or rpath.endswith("app_theme.dart")


def add(findings: list[Finding], counters: Counter[str], finding: Finding) -> None:
    counters[finding.rule] += 1
    if counters[finding.rule] <= MAX_FINDINGS_PER_RULE:
        findings.append(finding)


def audit_file(path: Path, findings: list[Finding], counters: Counter[str]) -> None:
    try:
        lines = path.read_text(errors="ignore").splitlines()
    except Exception as exc:
        add(
            findings,
            counters,
            Finding(
                "P1",
                "file_read_error",
                rel(path),
                1,
                str(exc),
                "Arquivo nao pode ser auditado pela cron.",
                "Verificar permissao ou encoding do arquivo.",
            ),
        )
        return

    text = "\n".join(lines)
    rpath = rel(path)
    theme_file = is_theme_foundation(path)

    for idx, line in enumerate(lines, start=1):
        if is_comment_only(line):
            continue
        signal = strip_for_signal(line)

        if not theme_file and re.search(r"\bColor\s*\(\s*0x[0-9a-fA-F]{8}\s*\)", line):
            add(
                findings,
                counters,
                Finding(
                    "P2",
                    "hardcoded_color",
                    rpath,
                    idx,
                    signal,
                    "Cores diretas dificultam consistencia visual, tema e contraste.",
                    "Trocar por token/AppTheme ou justificar excecao local.",
                ),
            )

        if not theme_file and re.search(r"\bColors\.[A-Za-z_]+", line) and "AppTheme" not in line:
            if not re.search(r"\bColors\.(transparent|white|black)\b", line):
                add(
                    findings,
                    counters,
                    Finding(
                        "P2",
                        "material_color_direct",
                        rpath,
                        idx,
                        signal,
                        "Uso direto de Colors pode furar o design system.",
                        "Preferir AppTheme/tokens semanticos para cor de UI.",
                    ),
                )

        if re.search(
            r"(['\"])(?:lorem|ipsum|todo|placeholder|dummy|fake|em breve)\b",
            line,
            re.I,
        ):
            add(
                findings,
                counters,
                Finding(
                    "P1",
                    "placeholder_or_mock_copy",
                    rpath,
                    idx,
                    signal,
                    "Copy placeholder ou mock pode vazar para producao.",
                    "Substituir por copy final ou condicionar a ambiente de desenvolvimento.",
                ),
            )

        if re.search(r"\b(mockData|fakeData|dummyData|sampleData|hardcoded)\b", line):
            add(
                findings,
                counters,
                Finding(
                    "P1",
                    "mock_or_hardcoded_data",
                    rpath,
                    idx,
                    signal,
                    "Dados mock/hardcoded no fluxo de UI podem divergir do backend real.",
                    "Trocar por provider/API real ou isolar em fixture de teste/dev.",
                ),
            )

        if "Image.network" in line:
            b = block(lines, idx - 1, 32)
            missing_state = (
                "loadingBuilder" not in b
                and "frameBuilder" not in b
                and "errorBuilder" not in b
            )
            if missing_state:
                add(
                    findings,
                    counters,
                    Finding(
                        "P1",
                        "image_network_missing_state",
                        rpath,
                        idx,
                        signal,
                        "Imagem remota sem loading/erro pode quebrar em rede lenta.",
                        "Adicionar fallback visual e errorBuilder/loadingBuilder ou componente centralizado.",
                    ),
                )

        if re.search(r"\bIconButton\s*\(", line):
            b = block(lines, idx - 1, 28)
            if "tooltip:" not in b:
                add(
                    findings,
                    counters,
                    Finding(
                        "P1",
                        "icon_button_missing_tooltip",
                        rpath,
                        idx,
                        signal,
                        "Botao apenas com icone sem tooltip reduz compreensao e acessibilidade.",
                        "Adicionar tooltip claro; quando necessario, semanticLabel no Icon.",
                    ),
                )

        if re.search(r"\b(GestureDetector|InkWell)\s*\(", line):
            interactive_block = call_block(lines, idx - 1)
            nearby = "\n".join(
                lines[max(0, idx - 16) : min(len(lines), idx + 24)]
            )
            semantic_context = f"{nearby}\n{interactive_block}"
            has_semantics = (
                "Semantics(" in semantic_context
                or "Tooltip(" in semantic_context
                or "semanticLabel" in semantic_context
                or "tooltip:" in semantic_context
                or has_visible_text_label(interactive_block)
            )
            if not has_semantics:
                add(
                    findings,
                    counters,
                    Finding(
                        "P2",
                        "interactive_without_semantics_hint",
                        rpath,
                        idx,
                        signal,
                        "Elemento interativo custom pode ficar pouco claro para leitor de tela.",
                        "Adicionar Semantics/Tooltip quando a acao nao estiver descrita por texto visivel.",
                    ),
                )
            small = re.search(
                r"\b(width|height)\s*:\s*(?:[0-3]?\d|4[0-7])(?:\.0)?\b",
                interactive_block,
            )
            touch_context = "\n".join(
                lines[max(0, idx - 24) : min(len(lines), idx + 48)]
            )
            if (
                small
                and not has_explicit_min_touch_target(touch_context)
                and not has_visible_text_label(interactive_block)
                and "Semantics(" not in touch_context
                and "Tooltip(" not in touch_context
            ):
                add(
                    findings,
                    counters,
                    Finding(
                        "P2",
                        "possible_small_touch_target",
                        rpath,
                        idx,
                        signal,
                        "Heuristica encontrou dimensao menor que 48 dentro de bloco tocavel.",
                        "Validar visualmente; elevar para P1 apenas se o alvo real ficar abaixo de 48x48.",
                    ),
                )

    if "Image.network" in text and "CachedNetworkImage" not in text:
        first = next((i + 1 for i, l in enumerate(lines) if "Image.network" in l), 1)
        add(
            findings,
            counters,
            Finding(
                "P2",
                "network_image_no_cache_abstraction",
                rpath,
                first,
                strip_for_signal(lines[first - 1]),
                "Imagens remotas repetidas podem prejudicar scroll/performance.",
                "Avaliar componente centralizado com cache, placeholder e error state.",
            ),
        )


def render(findings: list[Finding], counters: Counter[str], files_count: int) -> str:
    now = datetime.now(timezone.utc).isoformat()
    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=SCAN_REPO)
    sha = run(["git", "rev-parse", "--short", "HEAD"], cwd=SCAN_REPO)
    status = run(["git", "status", "--short", "--branch"], cwd=SCAN_REPO)
    memory_status = run(
        ["git", "status", "--short", "--branch"],
        cwd=MEMORY_REPO,
    )
    by_prio = Counter(f.priority for f in findings)
    lines: list[str] = [
        "# Flutter UI/UX Audit",
        "",
        "## Metadata",
        "",
        f"- Gerado em UTC: `{now}`",
        f"- Branch: `{branch}`",
        f"- SHA: `{sha}`",
        f"- Scan repo: `{SCAN_REPO}`",
        f"- Memory/report repo: `{MEMORY_REPO}`",
        "- Escopo: `app/lib/features/**/*.dart`, `app/lib/core/**/*.dart`",
        f"- Arquivos Dart analisados: `{files_count}`",
        "- Metodo: varredura estatica deterministica por padroes de UI/UX",
        "- Limite por regra: " + f"`{MAX_FINDINGS_PER_RULE}`",
        "",
        "## Sumario",
        "",
        f"`findings={len(findings)} P0={by_prio['P0']} P1={by_prio['P1']} P2={by_prio['P2']}`",
        "",
        "### Contagem por regra",
        "",
    ]
    if counters:
        for rule, count in counters.most_common():
            capped = "" if count <= MAX_FINDINGS_PER_RULE else f" (mostrando {MAX_FINDINGS_PER_RULE})"
            lines.append(f"- `{rule}`: {count}{capped}")
    else:
        lines.append("- Nenhum padrao problematico encontrado pela varredura estatica.")

    lines.extend(["", "## Findings", ""])
    if not findings:
        lines.append("Nenhum finding objetivo encontrado pela varredura estatica.")
    for priority in ["P0", "P1", "P2"]:
        group = [f for f in findings if f.priority == priority]
        if not group:
            continue
        lines.extend([f"### {priority}", ""])
        for index, finding in enumerate(group, start=1):
            lines.extend(
                [
                    f"#### {priority}-{index:03d} {finding.rule}",
                    "",
                    f"- Evidencia: `{finding.path}:{finding.line}`",
                    f"- Trecho: `{finding.evidence}`",
                    f"- Impacto: {finding.impact}",
                    f"- Sugestao: {finding.suggestion}",
                    "",
                ]
            )

    lines.extend(
        [
            "## Incertezas / medir depois",
            "",
            "- Contraste real depende de renderizacao e tema ativo; validar com screenshot ou teste visual.",
            "- Overflow/truncamento depende de device, escala de fonte e dados reais.",
            "- Estados empty/error/loading contextuais exigem revisar providers/API por fluxo.",
            "",
            "## Git status no momento da auditoria",
            "",
            "```text",
            status,
            "```",
            "",
            "## Git status da memoria Hermes",
            "",
            "```text",
            memory_status,
            "```",
            "",
            f"UI_AUDIT_RESULT: findings={len(findings)} P0={by_prio['P0']} P1={by_prio['P1']} P2={by_prio['P2']}",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    files = dart_files()
    findings: list[Finding] = []
    counters: Counter[str] = Counter()
    for path in files:
        audit_file(path, findings, counters)
    findings.sort(
        key=lambda f: (
            {"P0": 0, "P1": 1, "P2": 2}.get(f.priority, 9),
            f.rule,
            f.path,
            f.line,
        )
    )
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    report = render(findings, counters, len(files))
    REPORT.write_text(report)
    marker = report.strip().splitlines()[-1]
    print(marker)
    print(f"Report: {REPORT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
