#!/usr/bin/env python3
"""
ManaLoom Code Structure Auditor
Analisa a estrutura do projeto e identifica:
- Imports orfaos
- Arquivos muito grandes (gargalos)
- Logica potencialmente duplicada (funcoes publicas com mesmo nome entre arquivos)
- Referencias a tabelas PostgreSQL
- Observacoes informativas

NOTA: Este script faz analise TEXTUAL (regex/grep), nao compila nem constroi grafo
de chamadas. Achados de "nao usado" exigem validacao manual com grep antes de
serem reportados como problemas. Falsos positivos sao esperados.
"""
import os
import re
from datetime import datetime
from pathlib import Path

BASE = Path(os.environ.get("MTGIA_REPO_ROOT", Path.cwd())).resolve()
SERVER_LIB = BASE / "server" / "lib"
SERVER_ROUTES = BASE / "server" / "routes"
APP_LIB = BASE / "app" / "lib"
OUTPUT = BASE / "docs" / "hermes-analysis" / "STRUCTURE_AUDIT.md"
GENERATED_SECTION_MARKER = "## Historico gerado pelo auditor estrutural anterior"
MANUAL_SUFFIX_MARKER = "## Rodada focada:"

# ── Common function names that are expected to appear in multiple files ──
# These are standard patterns (toString, add, etc.) or common utilities.
COMMON_FUNC_NAMES = {
    'tostring', 'add', 'set', 'function', 'print', 'd', 'i', 'w', 'e',
    'tojson', 'fromjson', 'toint', 'tojson_safe', 'run', 'start', 'stop',
    'init', 'dispose', 'clear', 'reset', 'update', 'remove', 'contains',
    'isempty', 'isnotempty', 'length', 'hashcode', 'operatorequality',
    'notifylisteners', 'build', 'create', 'delete', 'get', 'put', 'post',
    'execute', 'fetch', 'load', 'save', 'read', 'write', 'close', 'open',
    'validate', 'parse', 'format', 'normalize', 'sanitize', 'resolve',
    'generateid', 'generatepromptcontext', 'generatetoken', 'calculatetcmc',
    'getmaintype', 'cleanupcache', 'readinessstatuscode', 'matches',
}

# ── Helper functions ──

def find_dart_files(path):
    return sorted([f for f in path.rglob("*.dart") if f.is_file()])

def read_file(path):
    try:
        return path.read_text(encoding='utf-8')
    except:
        return ""

def extract_classes(content):
    return re.findall(r'class\s+(\w+)', content)

def extract_functions(content):
    return re.findall(r'(?:Future|Stream|String|bool|int|void|Map|List|dynamic|[A-Z]\w+)\s+(\w+)\s*\(', content)

def extract_imports(content):
    return re.findall(r"import\s+['\"]([^'\"]+)['\"]", content)

def extract_table_references(content):
    tables = set()
    for m in re.finditer(r'FROM\s+(\w+)', content):
        tables.add(m.group(1))
    for m in re.finditer(r'JOIN\s+(\w+)', content):
        tables.add(m.group(1))
    for m in re.finditer(r'CREATE TABLE.*?(\w+)\s*\(', content):
        tables.add(m.group(1))
    return tables

def resolve_dart_import(source_path, import_uri):
    if import_uri.startswith("dart:") or import_uri.startswith("package:"):
        return None
    if import_uri.startswith("."):
        return (source_path.parent / import_uri).resolve()
    return None

def is_function_used_in_same_file(func_name, content):
    """Check if a function is called within the same file (outside its definition)."""
    # Remove the function definition line and check remaining content
    pattern = re.compile(rf'(?:Future|Stream|String|bool|int|void|Map|List|dynamic|[A-Z]\w+)\s+{re.escape(func_name)}\s*\(')
    matches = list(pattern.finditer(content))
    # If only one match, it's just the definition. If >1, there's at least one call.
    return len(matches) > 1 or (len(matches) == 1 and func_name.startswith('_') == False)

def merge_generated_report_with_manual_history(generated_report):
    if not OUTPUT.exists():
        return generated_report
    existing = read_file(OUTPUT)
    if GENERATED_SECTION_MARKER not in existing:
        return generated_report
    prefix = existing.split(GENERATED_SECTION_MARKER, 1)[0].rstrip()
    suffix = ""
    if MANUAL_SUFFIX_MARKER in existing:
        idx = existing.find(MANUAL_SUFFIX_MARKER)
        suffix = existing[idx:].strip()
    generated_lines = generated_report.splitlines()
    generated_body = "\n".join(generated_lines[3:]).strip()
    merged = f"{prefix}\n\n{GENERATED_SECTION_MARKER}\n\n{generated_body}"
    if suffix:
        merged = f"{merged}\n\n{suffix}"
    return merged

# ── Main analysis ──

def analyze():
    report = []
    report.append(f"# ManaLoom Code Structure Audit")
    report.append(f"> Data: {datetime.now().strftime('%Y-%m-%d %H:%M')} UTC")
    report.append(f"> Metodo: analise textual (regex) — nao substitui dart analyze")
    report.append("")

    server_files = find_dart_files(SERVER_LIB)
    route_files = find_dart_files(SERVER_ROUTES)
    all_server = server_files + route_files

    report.append(f"## Arquivos Mapeados")
    report.append(f"- `server/lib/`: {len(server_files)} arquivos")
    report.append(f"- `server/routes/`: {len(route_files)} arquivos")
    report.append(f"- **Total**: {len(all_server)} arquivos")
    report.append("")

    # Build file map
    file_map = {}
    for f in all_server:
        content = read_file(f)
        rel = str(f.relative_to(BASE))
        file_map[rel] = {
            'path': f,
            'content': content,
            'classes': extract_classes(content),
            'functions': extract_functions(content),
            'imports': extract_imports(content),
            'tables': extract_table_references(content),
            'lines': len(content.split('\n')),
        }

    # ── 1. Classes por arquivo (inventario, nao auditoria) ──
    report.append("## Classes por Arquivo")
    all_classes = {}
    for rel, info in file_map.items():
        for cls in info['classes']:
            all_classes[cls] = rel
    for cls, rel in sorted(all_classes.items()):
        report.append(f"- `{cls}` → `{rel}`")
    report.append("")

    # ── 2. Imports quebrados (confirmados via arquivo) ──
    report.append("## Imports Potencialmente Quebrados")
    broken = []
    for rel, info in file_map.items():
        for imp in info['imports']:
            imp_path = resolve_dart_import(info['path'], imp)
            if imp_path is None:
                continue
            if not imp_path.exists():
                broken.append(f"- `{rel}` importa `{imp}` (arquivo nao encontrado)")
    if broken:
        for b in broken:
            report.append(b)
    else:
        report.append("- Nenhum import quebrado encontrado")
    report.append("")

    # ── 3. Funcoes publicas (inventario) ──
    report.append("## Funcoes Publicas (amostra por arquivo)")
    for rel in sorted(file_map.keys()):
        info = file_map[rel]
        publics = [f for f in info['functions'] if not f.startswith('_')][:5]
        if publics:
            report.append(f"- `{rel}` ({info['lines']} linhas): {', '.join(publics)}")
    report.append("")

    # ── 4. Tabelas PostgreSQL ──
    report.append("## Tabelas PostgreSQL Referenciadas no Codigo")
    all_tables = {}
    for rel, info in file_map.items():
        for t in info['tables']:
            if t not in all_tables:
                all_tables[t] = []
            all_tables[t].append(rel)
    for t, refs in sorted(all_tables.items()):
        report.append(f"- `{t}`: {len(refs)} referencias")
    report.append("")

    # ── 5. Problemas estruturais (alta confianca) ──
    report.append("## Problemas Estruturais Identificados")
    problems = []

    # 5a. Arquivos muito grandes (>500 linhas) — metrica confiavel
    large_files = [(rel, info['lines']) for rel, info in file_map.items() if info['lines'] > 500]
    if large_files:
        problems.append("- **Arquivos grandes (>500 linhas) — gargalos de manutencao:**")
        for rel, lines in sorted(large_files, key=lambda x: -x[1]):
            problems.append(f"  - `{rel}`: {lines} linhas")
        problems.append("")

    # 5b. Funcoes PUBLICAS com mesmo nome em arquivos DIFERENTES que compartilham imports
    # (possivel duplicacao real, nao apenas reuso legítimo)
    func_map = {}  # func_name -> [(file, content)]
    for rel, info in file_map.items():
        for func in info['functions']:
            if func.startswith('_'):  # Skip private functions
                continue
            if func.lower() in COMMON_FUNC_NAMES:  # Skip common names
                continue
            if func not in func_map:
                func_map[func] = []
            func_map[func].append((rel, info['content']))

    # Build import relationships: which files import each other
    import_pairs = set()
    for rel, info in file_map.items():
        for imp in info['imports']:
            imp_path = resolve_dart_import(info['path'], imp)
            if imp_path and imp_path.exists():
                imp_rel = str(imp_path.relative_to(BASE))
                import_pairs.add((rel, imp_rel))

    real_duplicates = []
    for func, locations in func_map.items():
        if len(locations) < 2:
            continue
        # Only flag if the function appears in at least 2 DIFFERENT files that
        # DO NOT import each other (if they import each other, it's likely
        # intentional re-export/delegation, not accidental duplication)
        files = [loc[0] for loc in locations]
        has_cross_import = False
        for i in range(len(files)):
            for j in range(len(files)):
                if i != j and ((files[i], files[j]) in import_pairs or (files[j], files[i]) in import_pairs):
                    has_cross_import = True
                    break
        if not has_cross_import:
            real_duplicates.append((func, files))

    if real_duplicates:
        problems.append("- **Funcoes publicas duplicadas (mesmo nome, arquivos sem import cruzado):**")
        for func, files in sorted(real_duplicates):
            problems.append(f"  - `{func}` em: {', '.join(files)}")
        problems.append("  ⚠️ Validar com grep antes de agir — pode ser falso positivo.")
        problems.append("")
    else:
        problems.append("- Nenhuma duplicacao suspeita de funcoes publicas detectada.")
        problems.append("")

    # 5c. Imports quebrados (ja listados acima)
    if broken:
        problems.append(f"- **{len(broken)} imports quebrados** (ver secao acima)")

    if not problems:
        problems.append("- Nenhum problema estrutural identificado")

    for p in problems:
        report.append(p)
    report.append("")

    # ── 6. Observacoes (informativas, nao problemas) ──
    report.append("## Observacoes Informativas")
    observations = []

    # 6a. Tabelas/propriedades apenas lidas (nao inseridas)
    read_only_refs = []
    for rel, info in file_map.items():
        content = info['content']
        for pattern in ['semantic_tags_v2', 'card_function_tags']:
            if pattern in content:
                if 'INSERT' not in content and 'UPDATE' not in content:
                    read_only_refs.append(f"  - `{rel}` referencia `{pattern}` (apenas leitura)")
    if read_only_refs:
        observations.append("- **Referencias read-only a tabelas semanticas:**")
        for obs in read_only_refs:
            observations.append(obs)
        observations.append("  (Esperado para analise/consulta — nao e problema)")
        observations.append("")

    # 6b. Limitacao do auditor
    observations.append("- **Limitacao do auditor textual:** este script NAO compila codigo nem")
    observations.append("  constroi grafo de chamadas. 'Nao usado' requer validacao manual com")
    observations.append("  grep no arquivo fonte + arquivos relacionados antes de agir.")
    observations.append("  Use `dart analyze` e `dart test` como fonte primaria de confiabilidade.")

    for obs in observations:
        report.append(obs)
    report.append("")

    # ── 7. Gaps Conhecidos (manual) ──
    report.append("## Gaps Conhecidos (manual)")
    report.append("- `card_function_tags` / `card_semantic_tags_v2`: fluxo core de analysis/optimize ja usa multi-tags; rotas experimentais de recommendations/weakness ainda precisam convergir antes de promocao app-facing")
    report.append("- `card_deck_profiles`: 670 perfis, mas `filterUnsafeOptimizeSwapsByCardData` nao consulta")
    report.append("- `semantic_layer_v2`: default `disabled`, modo `partial` existe e tem teste de contrato; habilitar apenas em ambiente controlado com scorecard")
    report.append("- `archetype_patterns`: 69 registros, nao validado contra codigo")
    report.append("")

    # Write report
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    final_report = merge_generated_report_with_manual_history('\n'.join(report))
    OUTPUT.write_text(final_report, encoding='utf-8')

    print(f"Relatorio gerado: {OUTPUT}")
    print(f"- Arquivos analisados: {len(all_server)}")
    print(f"- Classes encontradas: {len(all_classes)}")
    print(f"- Tabelas PostgreSQL: {len(all_tables)}")
    print(f"- Problemas identificados: {len(problems)}")
    print(f"- Imports quebrados: {len(broken)}")
    print(f"- AVISO: Auditor textual — validar achados com grep antes de publicar")

if __name__ == '__main__':
    analyze()
