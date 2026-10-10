#!/usr/bin/env python3
"""Servidor de assets dos `*_visual_qa.sh` nao pode ficar orfao (D-89, B11).

Defeito: os cinco roteiros subiam o servidor assim

    ( cd "$ROOT_DIR"; python3 ... ) &
    ASSET_SERVER_PID="$!"

e o `$!` e o PID do SUBSHELL, nao o do Python. O `cleanup` matava o subshell e
o Python seguia servindo a raiz do repositorio em loopback (PPID 1) ate alguem
mata-lo a mao. Conserto: `exec python3 ...` dentro do subshell, para o `$!`
apontar para o proprio Python.

Duas garantias:

- estatica: todo servidor de assets iniciado em segundo plano dentro de
  `( ... ) &` usa `exec`; tirar o `exec` derruba o teste (mutacao abaixo);
- comportamental: o padrao `( cd ..; exec python3 server ) &` seguido de
  `kill $!` fecha a porta.
"""

from __future__ import annotations

import re
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SERVER = REPO_ROOT / "scripts" / "lib" / "manaloom_fixture_asset_server.py"
ASSET_SERVER = "manaloom_fixture_asset_server.py"
SCRIPTS = sorted(
    p
    for p in REPO_ROOT.glob("scripts/manaloom_*_visual_qa.sh")
    if ASSET_SERVER in p.read_text(encoding="utf-8")
)


def violacoes(texto: str) -> list[str]:
    """Blocos `( ... ) &` que sobem o servidor de assets sem `exec`."""
    achadas = []
    for bloco in re.finditer(r"^\(\n(.*?)^\) &", texto, re.S | re.M):
        corpo = bloco.group(1)
        if ASSET_SERVER not in corpo:
            continue
        if not re.search(r"^\s*exec\s+python3\s+\S*" + ASSET_SERVER, corpo, re.M):
            achadas.append(corpo.strip())
    return achadas


def _porta_livre() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def _escutando(porta: int) -> bool:
    with socket.socket() as s:
        s.settimeout(0.5)
        return s.connect_ex(("127.0.0.1", porta)) == 0


class AssetServerExecContract(unittest.TestCase):
    def test_ha_os_cinco_roteiros(self):
        self.assertEqual(
            len(SCRIPTS), 5, [p.name for p in SCRIPTS]
        )

    def test_todo_servidor_em_segundo_plano_usa_exec(self):
        for script in SCRIPTS:
            texto = script.read_text(encoding="utf-8")
            self.assertFalse(violacoes(texto), script.name)

    def test_mutacao_sem_exec_e_pega(self):
        for script in SCRIPTS:
            texto = script.read_text(encoding="utf-8")
            mutado = re.sub(r"^(\s*)exec python3", r"\1python3", texto, flags=re.M)
            self.assertTrue(mutado != texto, script.name)
            self.assertTrue(violacoes(mutado), script.name)

    def test_kill_do_pid_do_subshell_fecha_a_porta(self):
        porta = _porta_livre()
        with tempfile.TemporaryDirectory() as raiz:
            roteiro = f"""
set -euo pipefail
(
  cd {raiz!r}
  exec python3 {str(SERVER)!r} {porta} --bind 127.0.0.1 >/dev/null 2>&1
) &
pid="$!"
for _ in $(seq 1 50); do
  python3 -c "import socket,sys; s=socket.socket(); sys.exit(s.connect_ex(('127.0.0.1', {porta})))" && break
  sleep 0.1
done
echo "$pid"
kill "$pid"
wait "$pid" 2>/dev/null || true
"""
            saida = subprocess.run(
                ["bash", "-c", roteiro], capture_output=True, text=True, timeout=30
            )
            self.assertEqual(saida.returncode, 0, saida.stderr)
            for _ in range(30):
                if not _escutando(porta):
                    break
                time.sleep(0.1)
            self.assertFalse(_escutando(porta), "a porta continuou escutando (orfao)")


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0], "-v"])
