#!/usr/bin/env python3
"""
ManaLoom Code Structure Auditor
Analisa toda a estrutura do projeto e identifica:
- Classes/functions fora do lugar
- Lógica duplicada ou não usada
- Imports órfãos
- Tabelas PostgreSQL sem uso
- Inconsistências entre arquivos
"""
import os
import re
import json
import subprocess
from datetime import datetime
from pathlib import Path

BASE = Path(os.environ.get("MTGIA_REPO_ROOT", Path.cwd())).resolve()
SERVER_LIB = BASE / "server" / "lib"
SERVER_ROUTES = BASE / "server" / "routes"
APP_LIB = BASE / "app" / "lib"
OUTPUT = BASE / "docs" / "hermes-analysis" / "STRUCTURE_AUDIT.md"
GENERATED_SECTION_MARKER = "## Historico gerado pelo auditor estrutural anterior"
MANUAL_SUFFIX_MARKER = "## Rodada focada: Semantica de cartas no runtime"

# ============================================================
# 1. MAPEAR TODOS OS ARQUIVOS DART
# ============================================================

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
    return re.findall(r'(?:Future|Stream|String|bool|int|void|Map|List|dynamic)\s+(\w+)\s*\(', content)

def extract_imports(content):
    return re.findall(r"import\s+['\"]([^'\"]+)['\"]", content)

def extract_tablenames(content):
    return re.findall(r'FROM\s+(\w+)|JOIN\s+(\w+)', content)

def extract_table_references(content):
    tables = set()
    # SQL queries
    for m in re.finditer(r'FROM\s+(\w+)', content):
        tables.add(m.group(1))
    for m in re.finditer(r'JOIN\s+(\w+)', content):
        tables.add(m.group(1))
    # Table creation
    for m in re.finditer(r'CREATE TABLE.*?(\w+)\s*\(', content):
        tables.add(m.group(1))
    return tables

def resolve_dart_import(source_path, import_uri):
    """Resolve only repo-local Dart imports.

    Relative imports are resolved from the importing file directory, matching
    Dart analyzer behavior. Package imports are resolved for local package names
    only; third-party packages are intentionally ignored by this structural
    audit.
    """
    if import_uri.startswith("dart:"):
        return None

    if import_uri.startswith("package:"):
        package_path = import_uri[len("package:"):]
        package_name, _, relative = package_path.partition("/")
        if not relative:
            return None
        if package_name == "server":
            return SERVER_LIB / relative
        if package_name == "manaloom":
            return APP_LIB / relative
        # Historical alias kept for older Hermes docs/runs.
        if package_name == "ai":
            return SERVER_LIB / relative
        return None

    if import_uri.startswith("."):
        return (source_path.parent / import_uri).resolve()

    return None

def merge_generated_report_with_manual_history(generated_report):
    """Keep focused manual audit rounds while refreshing generated evidence.

    STRUCTURE_AUDIT.md is both a living manual audit log and the output target
    for this script. Only the generated section should be replaced by reruns.
    """
    if not OUTPUT.exists():
        return generated_report

    existing = read_file(OUTPUT)
    if GENERATED_SECTION_MARKER not in existing:
        return generated_report

    prefix = existing.split(GENERATED_SECTION_MARKER, 1)[0].rstrip()
    suffix = ""
    if MANUAL_SUFFIX_MARKER in existing:
        suffix = existing.split(MANUAL_SUFFIX_MARKER, 1)[1].strip()

    generated_lines = generated_report.splitlines()
    generated_body = "\n".join(generated_lines[3:]).strip()
    merged = f"{prefix}\n\n{GENERATED_SECTION_MARKER}\n\n{generated_body}"
    if suffix:
        merged = f"{merged}\n\n{MANUAL_SUFFIX_MARKER}\n{suffix}"
    return merged

# ============================================================
# 2. ANALISAR ESTRUTURA
# ============================================================

def analyze():
    report = []
    report.append(f"# ManaLoom Code Structure Audit")
    report.append(f"> Data: {datetime.now().strftime('%Y-%m-%d %H:%M')} UTC")
    report.append("")
    
    # 2.1 Mapear todos os arquivos Dart do backend
    server_files = find_dart_files(SERVER_LIB)
    route_files = find_dart_files(SERVER_ROUTES)
    all_server = server_files + route_files
    
    report.append(f"## Arquivos Mapeados")
    report.append(f"- `server/lib/`: {len(server_files)} arquivos")
    report.append(f"- `server/routes/`: {len(route_files)} arquivos")
    report.append(f"- **Total**: {len(all_server)} arquivos")
    report.append("")
    
    # 2.2 Extrair classes, funções e imports de cada arquivo
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
    
    # 2.3 Identificar classes e suas localizações
    report.append("## Classes por Arquivo")
    all_classes = {}
    for rel, info in file_map.items():
        for cls in info['classes']:
            all_classes[cls] = rel
    
    for cls, rel in sorted(all_classes.items()):
        report.append(f"- `{cls}` → `{rel}`")
    report.append("")
    
    # 2.4 Identificar imports que podem estar quebrados
    report.append("## Imports Potencialmente Quebrados")
    broken = []
    for rel, info in file_map.items():
        for imp in info['imports']:
            # Verificar se import local existe
            imp_path = resolve_dart_import(info['path'], imp)
            if imp_path is None:
                continue

            if not imp_path.exists():
                broken.append(f"- `{rel}` importa `{imp}` (não encontrado)")
    
    if broken:
        for b in broken:
            report.append(b)
    else:
        report.append("- Nenhum import quebrado encontrado")
    report.append("")
    
    # 2.5 Identificar funções públicas em cada arquivo
    report.append("## Funções Públicas (primeiros 5 por arquivo)")
    for rel in sorted(file_map.keys()):
        info = file_map[rel]
        publics = [f for f in info['functions'] if not f.startswith('_')][:5]
        if publics:
            report.append(f"- `{rel}` ({info['lines']} linhas): {', '.join(publics)}")
    report.append("")
    
    # 2.6 Mapear referências a tabelas PostgreSQL
    report.append("## Tabelas PostgreSQL Referenciadas no Código")
    all_tables = {}
    for rel, info in file_map.items():
        for t in info['tables']:
            if t not in all_tables:
                all_tables[t] = []
            all_tables[t].append(rel)
    
    for t, refs in sorted(all_tables.items()):
        report.append(f"- `{t}`: {len(refs)} referências")
    report.append("")
    
    # 2.7 Identificar problemas estruturais conhecidos
    report.append("## Problemas Estruturais Identificados")
    problems = []
    
    # Problema 1: semantic_tags_v2 nunca é populado
    for rel, info in file_map.items():
        if 'semantic_tags_v2' in info['content']:
            if 'INSERT' not in info['content'] and 'UPDATE' not in info['content']:
                problems.append(f"- `{rel}` referencia `semantic_tags_v2` mas não faz INSERT/UPDATE")
    
    # Problema 2: Classes com métodos que não são chamados em nenhum outro lugar
    defined_classes = set()
    used_classes = set()
    for rel, info in file_map.items():
        for cls in info['classes']:
            defined_classes.add(cls)
            # Verificar se a classe é mencionada em outros arquivos
            for other_rel, other_info in file_map.items():
                if other_rel != rel and cls in other_info['content']:
                    used_classes.add(cls)
    
    unused = defined_classes - used_classes
    if unused:
        for cls in sorted(unused):
            problems.append(f"- Classe `{cls}` é definida mas potencialmente não é usada em outros arquivos")
    
    # Problema 3: Arquivos muito grandes (>500 linhas)
    large_files = [(rel, info['lines']) for rel, info in file_map.items() if info['lines'] > 500]
    if large_files:
        problems.append("- Arquivos grandes (>500 linhas):")
        for rel, lines in sorted(large_files, key=lambda x: -x[1]):
            problems.append(f"  - `{rel}`: {lines} linhas")
    
    # Problema 4: Funções com nomes similares (possível duplicação)
    all_funcs = []
    for rel, info in file_map.items():
        for func in info['functions']:
            all_funcs.append((func, rel))
    
    func_names = [f[0] for f in all_funcs]
    duplicates = set([f for f in func_names if func_names.count(f) > 1])
    if duplicates:
        problems.append("- Funções com nomes duplicados:")
        for func in sorted(duplicates):
            locations = [rel for f, rel in all_funcs if f == func]
            problems.append(f"  - `{func}` em: {', '.join(locations)}")
    
    if problems:
        for p in problems:
            report.append(p)
    else:
        report.append("- Nenhum problema estrutural identificado")
    report.append("")
    
    # 2.8 Resumo de gaps conhecidos
    report.append("## Gaps Conhecidos (manual)")
    report.append("- `card_function_tags` / `card_semantic_tags_v2`: fluxo core de analysis/optimize ja usa multi-tags; rotas experimentais de recommendations/weakness ainda precisam convergir antes de promocao app-facing")
    report.append("- `card_deck_profiles`: 670 perfis, mas `filterUnsafeOptimizeSwapsByCardData` não consulta")
    report.append("- `semantic_layer_v2`: default `disabled`, modo `partial` existe e tem teste de contrato; habilitar apenas em ambiente controlado com scorecard")
    report.append("- `archetype_patterns`: 69 registros, não validado contra código")
    report.append("")
    
    # Escrever relatório
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    final_report = merge_generated_report_with_manual_history('\n'.join(report))
    OUTPUT.write_text(final_report, encoding='utf-8')
    
    print(f"Relatório gerado: {OUTPUT}")
    print(f"- Arquivos analisados: {len(all_server)}")
    print(f"- Classes encontradas: {len(all_classes)}")
    print(f"- Tabelas PostgreSQL: {len(all_tables)}")
    print(f"- Problemas identificados: {len(problems)}")
    print(f"- Imports quebrados: {len(broken)}")

if __name__ == '__main__':
    analyze()
