#!/usr/bin/env python3
"""Premium visual QA report generator for ManaLoom Flutter screens.

This is a deterministic companion to screenshot review. It does not claim a
visual pass by itself. It maps visual drift signals to product surfaces and
prints the iPhone Simulator capture commands that must be reviewed for a real
layout verdict.
"""

from __future__ import annotations

import argparse
import dataclasses
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


MAX_SIGNALS_PER_RULE = int(os.environ.get("PREMIUM_VISUAL_MAX_SIGNALS_PER_RULE", "60"))
DEFAULT_CONFIG = "server/config/premium_visual_qa_surfaces.json"
DEFAULT_OUTPUT = "docs/qa/manaloom_premium_visual_audit_latest.md"
CONFIG_ERROR_EXIT_CODE = 2
AUDITABLE_TEXT_SUFFIXES = frozenset({".css", ".dart", ".html", ".js"})


@dataclasses.dataclass(frozen=True)
class Signal:
    rule: str
    severity: str
    path: str
    line: int
    evidence: str
    impact: str
    suggestion: str


@dataclasses.dataclass(frozen=True)
class ConfiguredFileIssue:
    surface_id: str
    path: str
    reason: str
    blocking: bool


def discover_repo() -> Path:
    explicit = os.environ.get("MTGIA_REPO")
    if explicit:
        return Path(explicit).resolve()
    candidate = Path(__file__).resolve()
    for parent in [Path.cwd().resolve(), candidate, *candidate.parents]:
        if (parent / ".git").exists() and (parent / "app/lib").exists():
            return parent
    return Path.cwd().resolve()


REPO = discover_repo()


def run(cmd: list[str], cwd: Path = REPO, timeout: int = 30) -> str:
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            text=True,
            capture_output=True,
            timeout=timeout,
        )
        return (result.stdout or result.stderr or "").strip()
    except Exception as exc:
        return f"unavailable: {exc}"


def load_json(path: Path) -> dict:
    with path.open() as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"Config must be a JSON object: {path}")
    return data


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def is_comment_only(line: str) -> bool:
    stripped = line.strip()
    return stripped.startswith("//") or stripped.startswith("/*") or stripped.startswith("*")


def snippet(line: str) -> str:
    return line.strip().replace("\t", " ")[:220]


def is_design_foundation(path: Path) -> bool:
    rpath = rel(path).lower()
    return "/theme/" in rpath or rpath.endswith("app_theme.dart")


def is_life_counter_path(path: Path) -> bool:
    rpath = rel(path).lower()
    return "/life_counter" in rpath or "/lotus" in rpath


def is_test_or_generated(path: Path) -> bool:
    rpath = rel(path)
    return "/test/" in rpath or rpath.endswith(".g.dart")


def block(lines: list[str], start_index: int, size: int = 18) -> str:
    return "\n".join(lines[start_index : min(len(lines), start_index + size)])


def add_signal(
    signals: list[Signal],
    counters: Counter[str],
    signal: Signal,
) -> None:
    counters[signal.rule] += 1
    if counters[signal.rule] <= MAX_SIGNALS_PER_RULE:
        signals.append(signal)


def audit_dart_file(path: Path, signals: list[Signal], counters: Counter[str]) -> None:
    if path.suffix.lower() not in AUDITABLE_TEXT_SUFFIXES or is_test_or_generated(path):
        return
    try:
        lines = path.read_text(errors="ignore").splitlines()
    except Exception as exc:
        add_signal(
            signals,
            counters,
            Signal(
                "file_read_error",
                "P1",
                rel(path),
                1,
                str(exc),
                "Arquivo visual nao pode ser auditado.",
                "Corrigir permissao/encoding antes de confiar no gate.",
            ),
        )
        return

    theme_file = is_design_foundation(path)
    life_counter_file = is_life_counter_path(path)
    rpath = rel(path)

    for index, line in enumerate(lines, start=1):
        if is_comment_only(line):
            continue
        stripped = line.strip()
        current = snippet(line)

        if not theme_file and re.search(r"\bColor\s*\(\s*0x[0-9a-fA-F]{8}\s*\)", line):
            add_signal(
                signals,
                counters,
                Signal(
                    "hardcoded_color_literal",
                    "P2" if life_counter_file else "P1",
                    rpath,
                    index,
                    current,
                    "Cor literal precisa ser revisada contra a paleta tabletop propria do Life Counter."
                    if life_counter_file
                    else "Cor literal pode furar Obsidian/Brass/Frost e gerar divergencia entre telas.",
                    "Centralizar a cor em token/paleta do Life Counter ou documentar excecao com prova visual."
                    if life_counter_file
                    else "Trocar por AppTheme ou documentar excecao local com prova visual.",
                ),
            )

        if not theme_file and re.search(r"\bColors\.[A-Za-z_]+", line):
            add_signal(
                signals,
                counters,
                Signal(
                    "material_color_direct",
                    "P2" if life_counter_file else "P1",
                    rpath,
                    index,
                    current,
                    "Uso direto de Colors.* no Life Counter precisa ser validado contra contraste e separacao dos jogadores."
                    if life_counter_file
                    else "Uso direto de Colors.* costuma trazer branco/preto/cinza Material fora do sistema visual.",
                    "Preferir paleta centralizada do Life Counter quando a cor fizer parte da mesa."
                    if life_counter_file
                    else "Usar AppTheme.textPrimary/textSecondary/backgroundAbyss/surfaceSlate/brass/frost.",
                ),
            )

        if not theme_file and "TextStyle(" in line:
            nearby = block(lines, index - 1, 12)
            if "AppTheme." not in nearby and "Theme.of(context).textTheme" not in nearby:
                add_signal(
                    signals,
                    counters,
                    Signal(
                        "text_style_without_theme_token",
                        "P2",
                        rpath,
                        index,
                        current,
                        "TextStyle isolado facilita drift de tipografia, peso e cor.",
                        "Preferir Theme.of(context).textTheme + copyWith usando AppTheme quando necessario.",
                    ),
                )

        if not theme_file and re.search(r"\bfontSize\s*:\s*[0-9]+(?:\.[0-9]+)?", line):
            if "AppTheme.font" not in line:
                add_signal(
                    signals,
                    counters,
                    Signal(
                        "font_size_literal",
                        "P2",
                        rpath,
                        index,
                        current,
                        "Tamanho de fonte literal pode quebrar escala tipografica entre telas.",
                        "Trocar por AppTheme.fontMicro/fontXs/fontSm/fontMd/fontLg/fontXl/fontXxl/fontDisplay.",
                    ),
                )

        if not theme_file and re.search(r"\bBorderRadius\.(circular|only|all)\s*\(", line):
            nearby = block(lines, max(0, index - 4), 10)
            if "AppTheme.radius" not in nearby:
                add_signal(
                    signals,
                    counters,
                    Signal(
                        "radius_literal",
                        "P2",
                        rpath,
                        index,
                        current,
                        "Raio literal pode deixar cards/modais fora da familia visual de Meus Decks.",
                        "Usar AppTheme.radiusXs/radiusSm/radiusMd/radiusLg/radiusXl.",
                    ),
                )

        if not theme_file and "Border.all(" in line:
            nearby = block(lines, index - 1, 10)
            if "AppTheme." not in nearby:
                add_signal(
                    signals,
                    counters,
                    Signal(
                        "border_without_theme_token",
                        "P2",
                        rpath,
                        index,
                        current,
                        "Borda sem token tende a variar cor/peso entre cards, filtros e modais.",
                        "Usar AppTheme.outlineMuted/brass/frost com opacidade consistente.",
                    ),
                )

        if not theme_file and "styleFrom(" in line:
            nearby = block(lines, index - 1, 16)
            has_direct_color = re.search(r"\b(Color\s*\(|Colors\.)", nearby) is not None
            if has_direct_color:
                add_signal(
                    signals,
                    counters,
                    Signal(
                        "button_style_direct_color",
                        "P2" if life_counter_file else "P1",
                        rpath,
                        index,
                        current,
                        "Botao do Life Counter com cor direta precisa de revisao de contraste e consistencia tabletop."
                        if life_counter_file
                        else "Botao com cor direta pode divergir de CTA brass/secundario slate/frost.",
                        "Centralizar em paleta do Life Counter ou justificar com screenshot."
                        if life_counter_file
                        else "Mover para tokens AppTheme e conferir contraste do texto do botao.",
                    ),
                )

        if "SizedBox(" not in line and re.search(r"\b(width|height)\s*:\s*(?:[0-3]?\d|4[0-7])(?:\.0)?\b", line):
            nearby = block(lines, max(0, index - 8), 20)
            if any(token in nearby for token in ("GestureDetector(", "InkWell(", "IconButton(", "ButtonStyleButton")):
                add_signal(
                    signals,
                    counters,
                    Signal(
                        "possible_small_touch_or_visual_target",
                        "P2",
                        rpath,
                        index,
                        current,
                        "Alvo ou elemento visual menor que 48 pode ficar dificil de tocar ou parecer desalinhado.",
                        "Validar screenshot/touch target; elevar para bug se o alvo real ficar abaixo de 48x48.",
                    ),
                )

        if "Container(" in line and index < len(lines):
            nearby = block(lines, index - 1, 22)
            if "BoxDecoration(" in nearby and "AppTheme." not in nearby:
                add_signal(
                    signals,
                    counters,
                    Signal(
                        "container_decoration_without_theme_token",
                        "P2",
                        rpath,
                        index,
                        current,
                        "Container decorado sem token e uma fonte comum de background/borda/sombra destoante.",
                        "Migrar decoracao para componente/tokens ou revisar em screenshot.",
                    ),
                )


def configured_file_inventory(
    config: dict,
    include_life_counter: bool,
) -> tuple[list[Path], list[ConfiguredFileIssue]]:
    paths: list[Path] = []
    issues: list[ConfiguredFileIssue] = []
    for surface in config.get("surfaces", []):
        if surface.get("id") == "life_counter" and not include_life_counter:
            continue
        surface_id = str(surface.get("id", "unknown"))
        blocking = bool(surface.get("strict_file_inventory", False))
        for raw in surface.get("files", []):
            if not isinstance(raw, str) or not raw.strip():
                issues.append(
                    ConfiguredFileIssue(
                        surface_id=surface_id,
                        path=repr(raw),
                        reason="invalid_path",
                        blocking=blocking,
                    )
                )
                continue
            path = REPO / raw
            if path.is_file():
                paths.append(path)
                continue
            issues.append(
                ConfiguredFileIssue(
                    surface_id=surface_id,
                    path=raw,
                    reason="missing" if not path.exists() else "not_a_file",
                    blocking=blocking,
                )
            )
    return (
        sorted(set(paths)),
        sorted(
            set(issues),
            key=lambda issue: (
                not issue.blocking,
                issue.surface_id,
                issue.path,
                issue.reason,
            ),
        ),
    )


def configured_files(config: dict, include_life_counter: bool) -> list[Path]:
    """Return existing selected files for callers that only need the scan set."""

    files, _ = configured_file_inventory(config, include_life_counter)
    return files


def surface_for_file(config: dict, path: str) -> str:
    for surface in config.get("surfaces", []):
        if path in surface.get("files", []):
            return surface.get("id", "unknown")
    return "unmapped"


def render_command_block(commands: dict) -> list[str]:
    lines: list[str] = []
    for label, command in commands.items():
        lines.extend([f"### {label}", "", "```bash", command, "```", ""])
    return lines


def signals_by_surface(config: dict, signals: Iterable[Signal]) -> dict[str, list[Signal]]:
    grouped: dict[str, list[Signal]] = defaultdict(list)
    for signal in signals:
        grouped[surface_for_file(config, signal.path)].append(signal)
    return grouped


def render_report(
    config: dict,
    signals: list[Signal],
    counters: Counter[str],
    files_count: int,
    include_life_counter: bool,
    include_git_status: bool,
    configured_file_issues: list[ConfiguredFileIssue] | None = None,
    inventory_files_count: int | None = None,
) -> str:
    configured_file_issues = configured_file_issues or []
    if inventory_files_count is None:
        inventory_files_count = files_count
    blocking_file_issues = [
        issue for issue in configured_file_issues if issue.blocking
    ]
    now = datetime.now(timezone.utc).isoformat()
    branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    sha = run(["git", "rev-parse", "--short", "HEAD"])
    by_severity = Counter(signal.severity for signal in signals)
    grouped = signals_by_surface(config, signals)

    lines: list[str] = [
        "# ManaLoom Premium Visual QA Gate",
        "",
        "## Veredito automatico",
        "",
        "`NOT_A_VISUAL_PASS`.",
        "",
        "Este relatorio valida sinais objetivos de drift visual, mas nao substitui prova viva no iPhone Simulator. Proporcao de cards, poluicao visual, seam de imagem, legibilidade real e fidelidade ao mockup exigem revisar screenshots.",
        "",
        "## Metadata",
        "",
        f"- Gerado em UTC: `{now}`",
        f"- Branch: `{branch}`",
        f"- SHA: `{sha}`",
        f"- Config: `{rel(REPO / DEFAULT_CONFIG)}`",
        f"- Arquivos inventariados: `{inventory_files_count}`",
        f"- Arquivos textuais auditados: `{files_count}`",
        f"- Caminhos configurados invalidos: `{len(configured_file_issues)}`",
        f"- Erros bloqueantes de inventario: `{len(blocking_file_issues)}`",
        f"- Life Counter incluido: `{include_life_counter}`",
        "",
        "## Fontes de verdade",
        "",
    ]
    for doc in config.get("baseline_documents", []):
        lines.append(f"- `{doc}`")
    lines.extend(["", "## Regras premium aplicadas", ""])
    for rule in config.get("baseline_rules", []):
        lines.append(f"- {rule}")

    if configured_file_issues:
        lines.extend(
            [
                "",
                "## Integridade dos caminhos configurados",
                "",
                "`CONFIG_INVALID` para surfaces com inventario estrito; "
                "`CONFIG_WARNING` para surfaces legadas ainda nao bloqueantes.",
                "",
                "Caminhos ausentes ou que nao sejam arquivos nao entram silenciosamente "
                "na contagem auditada.",
                "",
            ]
        )
        for issue in configured_file_issues:
            status = "CONFIG_INVALID" if issue.blocking else "CONFIG_WARNING"
            lines.append(
                f"- `{status}` surface=`{issue.surface_id}` "
                f"reason=`{issue.reason}` path=`{issue.path}`"
            )

    lines.extend(
        [
            "",
            "## Sumario de sinais",
            "",
            f"`signals={len(signals)} P1={by_severity['P1']} P2={by_severity['P2']}`",
            "",
            "### Por regra",
            "",
        ]
    )
    if counters:
        for rule, count in counters.most_common():
            capped = "" if count <= MAX_SIGNALS_PER_RULE else f" (mostrando {MAX_SIGNALS_PER_RULE})"
            lines.append(f"- `{rule}`: {count}{capped}")
    else:
        lines.append("- Nenhum sinal objetivo de drift visual encontrado nas surfaces configuradas.")

    lines.extend(["", "## Matriz por tela", ""])
    lines.append("| Surface | Capturas obrigatorias | Sinais | Foco de revisao |")
    lines.append("| --- | --- | ---: | --- |")
    for surface in config.get("surfaces", []):
        if surface.get("id") == "life_counter" and not include_life_counter:
            continue
        sid = surface.get("id", "unknown")
        captures = ", ".join(f"`{item}`" for item in surface.get("captures", [])) or "-"
        focus = "; ".join(surface.get("focus", []))
        lines.append(f"| {surface.get('label', sid)} | {captures} | {len(grouped.get(sid, []))} | {focus} |")

    if grouped.get("unmapped"):
        lines.extend(["", "## Arquivos nao mapeados", ""])
        for signal in grouped["unmapped"][:40]:
            lines.append(f"- `{signal.path}:{signal.line}` `{signal.rule}`")

    lines.extend(
        [
            "",
            "## Comandos de prova viva obrigatoria",
            "",
            "Substitua `<IPHONE_SIMULATOR_UDID>` pelo device atual de `flutter devices`. Para app-facing visual change, a captura deve passar e os screenshots devem ser revisados contra o checklist abaixo.",
            "",
        ]
    )
    lines.extend(render_command_block(config.get("capture_commands", {})))

    lines.extend(
        [
            "## Checklist de screenshot",
            "",
            "- Proporcao: cards, hero, modais e listas ocupam area adequada sem sobras artificiais.",
            "- Background: nao ha seam, transparencia indevida, bloco claro solto ou Material default.",
            "- Cor: textos/botoes/tabs/chips seguem Obsidian/Brass/Frost; sem branco/preto/cinza Material indevido.",
            "- Tipografia: headers usam display com intencao; formularios/listas usam UI font e escala AppTheme.",
            "- Borda/raio: cards, inputs, sheets e modais usam a familia de Meus Decks.",
            "- Hierarquia: CTA principal e claramente brass; secundarias ficam discretas.",
            "- Densidade: tela nao fica poluida, nem vazia quando ha conteudo.",
            "- Acessibilidade visual: contraste, tamanho de toque e truncamento sao legiveis no iPhone.",
            "",
            "## Sinais detalhados",
            "",
        ]
    )
    if not signals:
        lines.append("Nenhum sinal objetivo encontrado.")
    for severity in ["P1", "P2"]:
        group = [signal for signal in signals if signal.severity == severity]
        if not group:
            continue
        lines.extend([f"### {severity}", ""])
        for idx, signal in enumerate(group, start=1):
            lines.extend(
                [
                    f"#### {severity}-{idx:03d} {signal.rule}",
                    "",
                    f"- Surface: `{surface_for_file(config, signal.path)}`",
                    f"- Evidencia: `{signal.path}:{signal.line}`",
                    f"- Trecho: `{signal.evidence}`",
                    f"- Impacto: {signal.impact}",
                    f"- Sugestao: {signal.suggestion}",
                    "",
                ]
            )

    if include_git_status:
        status = run(["git", "status", "--short", "--branch"])
        lines.extend(["## Git status", "", "```text", status, "```", ""])

    config_valid = "false" if blocking_file_issues else "true"
    lines.extend(
        [
            f"VISUAL_PREMIUM_QA_CONFIG_RESULT: issues={len(configured_file_issues)} blocking={len(blocking_file_issues)} valid={config_valid}",
            "",
            f"VISUAL_PREMIUM_QA_RESULT: signals={len(signals)} P1={by_severity['P1']} P2={by_severity['P2']} visual_pass=false",
            "",
        ]
    )
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default=DEFAULT_CONFIG)
    parser.add_argument("--output", default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--include-life-counter",
        action="store_true",
        help="Include Life Counter/Lotus surfaces in the premium signal scan.",
    )
    parser.add_argument(
        "--include-git-status",
        action="store_true",
        help="Append current git status to the report for ad-hoc local diagnostics.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config_path = (REPO / args.config).resolve()
    output_path = (REPO / args.output).resolve()
    config = load_json(config_path)

    files, configured_file_issues = configured_file_inventory(
        config,
        include_life_counter=args.include_life_counter,
    )
    auditable_files = [
        path for path in files if path.suffix.lower() in AUDITABLE_TEXT_SUFFIXES
    ]
    signals: list[Signal] = []
    counters: Counter[str] = Counter()
    for path in auditable_files:
        audit_dart_file(path, signals, counters)

    signals.sort(
        key=lambda s: (
            {"P1": 0, "P2": 1}.get(s.severity, 9),
            surface_for_file(config, s.path),
            s.rule,
            s.path,
            s.line,
        )
    )

    report = render_report(
        config,
        signals,
        counters,
        len(auditable_files),
        include_life_counter=args.include_life_counter,
        include_git_status=args.include_git_status,
        configured_file_issues=configured_file_issues,
        inventory_files_count=len(files),
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(report)
    marker = report.strip().splitlines()[-1]
    if configured_file_issues:
        blocking_count = sum(issue.blocking for issue in configured_file_issues)
        config_valid = "false" if blocking_count else "true"
        print(
            "VISUAL_PREMIUM_QA_CONFIG_RESULT: "
            f"issues={len(configured_file_issues)} "
            f"blocking={blocking_count} valid={config_valid}",
            file=sys.stderr,
        )
        for issue in configured_file_issues:
            status = "ERROR" if issue.blocking else "WARNING"
            print(
                f"{status}: surface={issue.surface_id} "
                f"reason={issue.reason} path={issue.path}",
                file=sys.stderr,
            )
    print(marker)
    print(f"Report: {output_path}")
    if any(issue.blocking for issue in configured_file_issues):
        return CONFIG_ERROR_EXIT_CODE
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
