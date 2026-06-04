#!/usr/bin/env python3
"""Pipeline de auditoria UI/UX screen por screen.

Cada execucao:
1. Indexa todos os arquivos de tela/widget do app
2. Pega os proximos N que ainda nao foram auditados no ciclo atual
3. Gera um prompt focado nesses arquivos
4. Executa hermes LLM com o prompt
5. Apenda findings ao relatorio
6. Se ciclo completo, gera sumario e reinicia

Estado salvo em: docs/hermes-analysis/.ui_audit_state.json
Relatorio em:  docs/hermes-analysis/FLUTTER_UI_AUDIT.md
"""

import json, os, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

APP_DIR = os.environ.get(
    "MTGIA_APP_DIR",
    "/opt/data/workspace/mtgia-sync/app/lib",
)
REPORT_FILE = "/opt/data/workspace/mtgia/docs/hermes-analysis/FLUTTER_UI_AUDIT.md"
STATE_FILE = "/opt/data/workspace/mtgia/docs/hermes-analysis/.ui_audit_state.json"
HERMES_BIN = "/opt/hermes/.venv/bin/hermes"
BATCH_SIZE = int(os.environ.get("UI_AUDIT_BATCH", "2"))

CHECKLIST = """## Checklist por Tela

Para cada arquivo, verifique:

### A. Strings e Copy
- Textos placeholder genericos ("Lorem ipsum", "TODO", "Teste")
- Frases que parecem geradas por IA (muito longas, impessoais, genericas)
- Falta de tratamento de plural/singular
- Labels truncadas em telas pequenas

### B. Design System
- Cores hardcoded (Color(0xFF...) em vez de AppTheme.xxx)
- Padding/margin diferentes entre telas similares
- Tamanhos de fonte fora do design system
- Overflow de texto (TextOverflow nao configurado)

### C. Estados
- Falta de estado de loading
- Falta de estado de erro
- Falta de estado empty (sem dados)
- Falta de estado desabilitado em botoes

### D. Icones e Semantica
- Icones sem contexto ou significado claro
- Falta de tooltip/semanticLabel em botoes so com icone
- Touch targets < 48x48

### E. Mock/Dados Hardcoded
- JSON fixo que deveria vir do backend
- Imagens placeholder com path local
- Flag isMock sempre true

### F. Acessibilidade
- Falta de Semantics widget em elementos interativos
- Contraste de cores potencialmente baixo
- Textos sem contraste suficiente com o fundo

### SAIDA por Arquivo
Para cada arquivo, liste findings individuais neste formato:
- [P0/P1/P2] arquivo:linha — descricao — sugestao de correcao
Onde: P0=bloqueia release, P1=importante corrigir, P2=cosmetico/melhoria
"""


def find_screen_files():
    """Encontra todos os arquivos de screen/widget no app."""
    files = []
    for root, _, filenames in os.walk(APP_DIR):
        for f in filenames:
            if f.endswith(".dart"):
                path = os.path.join(root, f)
                # Foca em screens e widgets principais, ignora testes e providers
                rel = path.replace(APP_DIR + "/", "")
                if "screen" in rel.lower() or "widget" in rel.lower() or "page" in rel.lower():
                    files.append(path)
                elif "view" in rel.lower():
                    files.append(path)
    return sorted(files)


def load_state():
    if os.path.exists(STATE_FILE):
        try:
            return json.load(open(STATE_FILE))
        except Exception:
            pass
    return {"audited": {}, "cycle": 1, "last_run": None}


def save_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    json.dump(state, open(STATE_FILE, "w"), indent=2)


def main():
    print("=== Flutter UI Audit Pipeline ===")

    # Pull latest sync workspace
    sync_dir = os.path.dirname(os.path.dirname(APP_DIR))
    if os.path.isdir(os.path.join(sync_dir, ".git")):
        subprocess.run(
            ["git", "-C", sync_dir, "pull", "--ff-only", "origin", "master"],
            capture_output=True, timeout=30,
        )
        print(f"Sync workspace atualizado: {sync_dir}")

    all_files = find_screen_files()
    state = load_state()

    # Filtra nao auditados no ciclo atual
    pending = [f for f in all_files if f not in state["audited"]]
    if not pending:
        # Ciclo completo: gera sumario e reseta
        print("CICLO COMPLETO — gerando sumario e reiniciando")
        total = len(all_files)
        findings_p0 = sum(1 for v in state["audited"].values() if v.get("p0", 0) > 0)
        findings_p1 = sum(1 for v in state["audited"].values() if v.get("p1", 0) > 0)
        findings_p2 = sum(1 for v in state["audited"].values() if v.get("p2", 0) > 0)

        with open(REPORT_FILE, "a") as f:
            f.write(f"\n---\n## Resumo Ciclo {state['cycle']}\n\n")
            f.write(f"Total de telas: {total}\n")
            f.write(f"Findings P0: {findings_p0}\n")
            f.write(f"Findings P1: {findings_p1}\n")
            f.write(f"Findings P2: {findings_p2}\n")
            f.write(f"Concluido em: {datetime.now(timezone.utc).isoformat()}\n")
            f.write(f"\nProximo ciclo: {state['cycle'] + 1}\n")
            f.write("\n---\n\n")

        state = {"audited": {}, "cycle": state["cycle"] + 1, "last_run": None}
        save_state(state)
        return 0

    batch = pending[:BATCH_SIZE]
    print(f"Arquivos pendentes: {len(pending)}, auditando batch de {len(batch)}")
    for b in batch:
        rel = b.replace(APP_DIR + "/", "")
        print(f"  {rel}")

    # Constroi texto com os arquivos (truncados se muito grandes)
    file_contents = []
    for path in batch:
        rel = path.replace(APP_DIR + "/", "")
        try:
            content = open(path).read()
            if len(content) > 4000:
                content = content[:3000] + "\n... (truncado, +" + str(len(content) - 3000) + " bytes)"
            file_contents.append(f"### Arquivo: {rel}\n```dart\n{content}\n```\n")
        except Exception as e:
            file_contents.append(f"### Arquivo: {rel}\nERRO LEITURA: {e}\n")

    prompt = f"""## Flutter UI/UX Audit — Ciclo {state['cycle']} — Batch {len(batch)} arquivos

Workdir: /opt/data/workspace/mtgia
NAO editar produto, codigo ou master.
NAO commitar.

{CHECKLIST}

### ARQUIVOS PARA AUDITAR NESTE CICLO

{''.join(file_contents)}

### INSTRUCOES
1. Analise CADA arquivo individualmente contra o checklist acima.
2. Liste findings no formato: [P0/P1/P2] arquivo:linha — descricao — sugestao
3. Apenda seus findings ao final de {REPORT_FILE} com header "## Ciclo {state['cycle']} — {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')}"
4. Se nao houver findings, registre "Nenhum finding — OK".

Sempre termine com: UI_AUDIT_BATCH_RESULT: audited={len(batch)} findings=N P0=X P1=Y P2=Z
"""

    # Executa hermes
    print("Executando Hermes LLM...")
    result = subprocess.run(
        [HERMES_BIN, "--accept-hooks", "-z", prompt],
        capture_output=True, text=True, timeout=600,
        cwd="/opt/data/workspace/mtgia",
        env={**os.environ, "OPENCODE_GO_API_KEY": os.environ.get("OPENCODE_GO_API_KEY", "")},
    )

    output = result.stdout + result.stderr
    print(output[-500:] if len(output) > 500 else output)

    # Atualiza estado
    now = datetime.now(timezone.utc).isoformat()
    for path in batch:
        rel = path.replace(APP_DIR + "/", "")
        p0 = output.count("[P0]") if path == batch[0] else 0  # estimativa simples
        state["audited"][path] = {
            "file": rel,
            "audited_at": now,
            "p0": 1 if "[P0] " + rel in output else 0,
            "p1": 1 if "[P1] " + rel in output else 0,
            "p2": 1 if "[P2] " + rel in output else 0,
        }
    state["last_run"] = now
    save_state(state)

    print(f"\nEstado atualizado: {len(state['audited'])}/{len(all_files)} auditados no ciclo {state['cycle']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
