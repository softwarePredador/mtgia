#!/usr/bin/env python3
"""Lint: checagem de shell que não barra sob `set -e`.

No bash anterior ao 4.1 (o `/bin/bash` do macOS, onde a coordenação roda deploy,
promoção, ops e backup, é o 3.2), um `[[ ... ]]` ou um `(( ... ))` solto que falha não
encerra o script com `set -e`. Um `!` solto não encerra em versão nenhuma. Uma checagem
assim nunca barra: a execução segue como se tivesse passado.

O lint lê o código local do script, fora de heredoc, de comentário e de texto entre
aspas (que em geral vira comando remoto, rodado pelo bash do host). Ele acusa o comando
que começa com `[[`, `((` com comparação ou `!`, quando:
- está no nível do comando (começo da linha, depois de `;`, `then`, `do`, `else` ou `{`);
- não tem `||`, `&&` ou `|` depois;
- não faz parte de uma condição ou de uma continuação (`if`, `while`, `until`, `elif`,
  linha que termina em `&&`, `||`, `|` ou `\\`).
O último comando antes do `}` que fecha uma função vale como o retorno dela e não é
acusado: quem chama a função solta sai com `set -e` em qualquer versão. O `}` de um
grupo `{ ...; }` comum não conta: ali a checagem solta segue sem barrar.

As raízes do digest de UI (`SOURCE_ROOTS` de `scripts/manaloom_ui_source_digest.sh`) só
mudam com a prova de UI da coordenação; o conserto delas vai em rascunho. Com
`--pending`, o que já se sabe delas fica numa lista fechada que só encolhe: checagem
solta nova numa raiz falha, e a entrada que não existe mais também (tire da lista junto
com o conserto).

Uso: manaloom_errexit_lint.py ARQUIVO... (sai com 1 se acusar algo)
     manaloom_errexit_lint.py --scan RAIZ [--pending LISTA.json] [--json]
     (os .sh de scripts/ e server/bin/ com set -e e as bibliotecas de scripts/lib/)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

ERREXIT = re.compile(r"^\s*set\s+(-[a-zA-Z]*e[a-zA-Z]*\b|-o\s+errexit\b)", re.MULTILINE)
HEREDOC = re.compile(r"<<(-?)\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\2")
STATEMENT_KEYWORDS = ("then", "do", "else", "{")
CONDITION_KEYWORDS = ("if", "elif", "while", "until", "!")
CONTINUATION = ("&&", "||", "|", "\\", "(", "if", "elif", "while", "until", "then", "do")
COMPARISON = re.compile(r"(<=|>=|==|!=|<|>)")


def code_lines(text: str) -> list[tuple[int, str, bool]]:
    """Cada linha com só o código local do nível do script; o resto vira espaço.

    Texto entre aspas, `$( ... )` (que roda num subshell), comentários e heredocs saem.
    Cada item é (número da linha, texto, começou no código do script). Uma linha que
    começa dentro de aspas continua a anterior.
    """
    lines = text.split("\n")
    result: list[tuple[int, str, bool]] = []
    stack: list[str] = ["code"]
    depth: list[int] = [0]
    heredocs: list[tuple[str, bool]] = []
    for index, line in enumerate(lines):
        number = index + 1
        if heredocs:
            delimiter, strip_tabs = heredocs[0]
            candidate = line.lstrip("\t") if strip_tabs else line
            if candidate == delimiter:
                heredocs.pop(0)
            continue
        started = stack == ["code"]
        out: list[str] = []
        position = 0
        while position < len(line):
            char = line[position]
            context = stack[-1]
            top = stack == ["code"]
            if context in ("code", "subst"):
                if char == "\\" and position + 1 < len(line):
                    out.append("  ")
                    position += 2
                    continue
                if char == "'":
                    stack.append("single")
                elif char == '"':
                    stack.append("double")
                elif line.startswith("$'", position):
                    stack.append("ansi")
                    out.append("  ")
                    position += 2
                    continue
                elif line.startswith("$((", position):
                    out.append(" " * 3)
                    stack.append("subst")
                    depth.append(1)
                    position += 3
                    continue
                elif line.startswith("$(", position):
                    stack.append("subst")
                    depth.append(0)
                    out.append("  ")
                    position += 2
                    continue
                elif char == "#" and (position == 0 or line[position - 1] in " \t;&|("):
                    break
                elif context == "subst" and char == "(":
                    depth[-1] += 1
                elif context == "subst" and char == ")":
                    if depth[-1] == 0:
                        stack.pop()
                        depth.pop()
                        out.append(" ")
                        position += 1
                        continue
                    depth[-1] -= 1
                elif top and line.startswith("<<", position) and not line.startswith("<<<", position):
                    match = HEREDOC.match(line, position)
                    if match:
                        heredocs.append((match.group(3), match.group(1) == "-"))
                        out.append(" " * (match.end() - position))
                        position = match.end()
                        continue
                out.append(char if top else " ")
                if char in "'\"" and top:
                    out[-1] = " "
            elif context == "single":
                if char == "'":
                    stack.pop()
                out.append(" ")
            elif context == "ansi":
                if char == "\\" and position + 1 < len(line):
                    out.append("  ")
                    position += 2
                    continue
                if char == "'":
                    stack.pop()
                out.append(" ")
            else:  # double
                if char == "\\" and position + 1 < len(line):
                    out.append("  ")
                    position += 2
                    continue
                if char == '"':
                    stack.pop()
                elif line.startswith("$(", position):
                    stack.append("subst")
                    depth.append(0)
                    out.append("  ")
                    position += 2
                    continue
                out.append(" ")
            position += 1
        result.append((number, "".join(out).rstrip(), started))
    return result


def _matching(text: str, start: int, opener: str, closer: str) -> int | None:
    """Posição logo depois do fechamento de `[[`/`((` que começa em [start]."""
    depth = 0
    position = start
    while position < len(text):
        if text.startswith(opener, position):
            depth += 1
            position += len(opener)
            continue
        if text.startswith(closer, position):
            depth -= 1
            position += len(closer)
            if depth == 0:
                return position
            continue
        position += 1
    return None


def logical_lines(lines: list[tuple[int, str, bool]]) -> list[tuple[int, str]]:
    """Junta o que é um comando só: `\\` no fim, texto entre aspas em várias linhas e
    `[[ ... ]]` aberto em uma linha e fechado em outra."""
    joined: list[tuple[int, str]] = []
    for number, text, started in lines:
        if joined and (not started or joined[-1][1].rstrip().endswith("\\")
                       or joined[-1][1].count("[[") > joined[-1][1].count("]]")):
            first, previous = joined[-1]
            previous = previous.rstrip()
            if previous.endswith("\\"):
                previous = previous[:-1]
            joined[-1] = (first, previous + " " + text)
            continue
        joined.append((number, text))
    return joined


def _statement_starts(text: str) -> list[int]:
    """Posições onde começa um comando: início, depois de `;`, `then`, `do`, `else`, `{`."""
    starts = []
    stripped = text.lstrip()
    if stripped:
        starts.append(len(text) - len(stripped))
    for match in re.finditer(r"(;|\bthen\b|\bdo\b|\belse\b|\{)\s*", text):
        if match.group(1) == ";" and text[match.start():match.start() + 2] == ";;":
            continue
        end = match.end()
        if end < len(text):
            starts.append(end)
    return sorted(set(starts))


FUNCTION_OPEN = re.compile(
    r"^\s*(?:function\s+[A-Za-z_][\w:.-]*\s*(?:\(\s*\))?|[A-Za-z_][\w:.-]*\s*\(\s*\))\s*"
    r"(?P<brace>\{)(?:\s|$)")
# `{` e `}` de comando: com espaço, `;`, `&`, `|` ou parêntese antes e espaço ou fim
# depois (`${var}` e `{a,b}` ficam de fora).
BRACE = re.compile(r"(?:^|(?<=[\s;&|()]))([{}])(?=[\s;&|<>)]|$)")


def _function_closers(lines: list[tuple[int, str]]) -> set[int]:
    """Índices das linhas lógicas que começam com o `}` que fecha uma função."""
    stack: list[bool] = []
    closers: set[int] = set()
    for index, (_, line) in enumerate(lines):
        function_open = FUNCTION_OPEN.match(line)
        function_brace = function_open.start("brace") if function_open else -1
        for match in BRACE.finditer(line):
            if match.group(1) == "{":
                stack.append(match.start() == function_brace)
            elif stack:
                closes_function = stack.pop()
                if closes_function and not line[:match.start()].strip():
                    closers.add(index)
    return closers


def findings(text: str) -> list[tuple[int, str]]:
    original = text.split("\n")
    lines = logical_lines(code_lines(text))
    closers = _function_closers(lines)
    problems: list[tuple[int, str]] = []
    previous = ""
    for position, (number, line) in enumerate(lines):
        stripped = line.strip()
        # A linha anterior deixou o comando aberto: termina em `&&`, `||`, `|`, `\\`...
        # ou é uma condição (`if`, `while`...) que ainda não chegou ao `then`/`do`.
        continuation = previous.endswith(CONTINUATION) or bool(re.match(
            r"^(if|elif|while|until)\b", previous)) and not re.search(
            r"\b(then|do)\b", previous)
        next_index = next((index for index in range(position + 1, len(lines))
                           if lines[index][1].strip()), None)
        closes_function = next_index is not None and next_index in closers
        for start in _statement_starts(line):
            if start == 0 or not line[:start].strip():
                if continuation:
                    continue
            before = line[:start].rstrip()
            if before.endswith(("&&", "||", "|")) or re.search(
                    r"(^|\s)(if|elif|while|until|!)\s*$", before):
                continue
            rest = line[start:]
            if rest.startswith("[["):
                end = _matching(line, start, "[[", "]]")
                kind = "[["
            elif rest.startswith("((") and not line[max(0, start - 1)] == "$":
                end = _matching(line, start, "((", "))")
                kind = "(("
                if end is not None and not COMPARISON.search(line[start:end]):
                    continue  # aritmética de efeito (incremento), não checagem
            elif re.match(r"!\s", rest):
                end = len(line)
                semicolon = line.find(";", start)
                if semicolon != -1:
                    end = semicolon
                kind = "!"
            else:
                continue
            if end is None:
                problems.append((number, f"{kind} sem fechamento: "
                                 f"{original[number - 1].strip()[:80]}"))
                continue
            after = line[end:].lstrip()
            if kind != "!" and after.startswith(("&&", "||", "|")):
                continue
            if kind == "!" and re.search(r"(&&|\|\|)", line[start:end]):
                continue
            # O último comando antes do `}` de uma função é o retorno dela.
            if (not after or after.startswith(";")) and closes_function:
                continue
            problems.append((number, original[number - 1].strip()[:100]))
        previous = stripped
    return problems


def _ui_digest_roots(root: Path) -> set[str]:
    source = (root / "scripts" / "manaloom_ui_source_digest.sh").read_text(encoding="utf-8")
    block = source[source.index("SOURCE_ROOTS=("):]
    block = block[:block.index("\n)")]
    return set(re.findall(r'"([^"]+)"', block))


def scan_targets(root: Path) -> tuple[list[Path], list[Path]]:
    """Os scripts com set -e e as bibliotecas; e as raízes do digest de UI, à parte."""
    roots = _ui_digest_roots(root)
    targets, digest = [], []
    candidates = sorted((root / "scripts").rglob("*.sh")) + sorted(
        (root / "server" / "bin").glob("*.sh"))
    for path in candidates:
        relative = path.relative_to(root).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")
        library = relative.startswith("scripts/lib/")
        if not (library or ERREXIT.search(text)):
            continue
        (digest if relative in roots else targets).append(path)
    return targets, digest


def load_pending(path: Path) -> Counter:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != "manaloom_errexit_lint_pending_v1":
        raise ValueError(f"{path}: schema_version inesperado")
    return Counter((item["file"], item["statement"]) for item in data["pending"])


def pending_drift(root: Path, digest: list[Path],
                  pending: Counter) -> tuple[list[tuple[str, str]], list[tuple[str, str]]]:
    """(checagens soltas novas nas raízes do digest, entradas da lista que já sumiram)."""
    found: Counter = Counter()
    for path in digest:
        relative = path.relative_to(root).as_posix()
        for _, statement in findings(path.read_text(encoding="utf-8", errors="replace")):
            found[(relative, statement)] += 1
    return sorted((found - pending).elements()), sorted((pending - found).elements())


def _label(path: Path, base: Path) -> str:
    try:
        return path.resolve().relative_to(base.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--scan", type=Path)
    parser.add_argument("--pending", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    if args.pending and not args.scan:
        parser.error("--pending só vale com --scan")
    digest: list[Path] = []
    if args.scan:
        root = args.scan.resolve()
        paths, digest = scan_targets(root)
        base = root
    else:
        paths, base = args.paths, Path.cwd()
    report: dict[str, list] = {}
    for path in paths:
        found = findings(path.read_text(encoding="utf-8", errors="replace"))
        if found:
            report[_label(path, base)] = found
    pending: dict[str, list] = {}
    for path in digest:
        found = findings(path.read_text(encoding="utf-8", errors="replace"))
        if found:
            pending[_label(path, base)] = found
    new: list[tuple[str, str]] = []
    stale: list[tuple[str, str]] = []
    if args.pending:
        new, stale = pending_drift(base, digest, load_pending(args.pending))
    if args.json:
        print(json.dumps({"findings": report, "ui_digest_pending": pending,
                          "ui_digest_new": new, "pending_stale": stale,
                          "scanned": len(paths) + len(digest)},
                         ensure_ascii=False, indent=2))
    else:
        for label, found in report.items():
            for number, statement in found:
                print(f"{label}:{number}: checagem solta, não barra sob set -e: {statement}")
        if args.pending:
            for label, statement in new:
                print(f"{label}: checagem solta nova numa raiz do digest de UI: {statement}")
            for label, statement in stale:
                print(f"{args.pending}: entrada que já não existe em {label}, "
                      f"tire da lista: {statement}")
        else:
            for label, found in pending.items():
                for number, statement in found:
                    print(f"{label}:{number}: (raiz do digest de UI, em rascunho) {statement}")
    return 1 if report or new or stale else 0


if __name__ == "__main__":
    sys.exit(main())
