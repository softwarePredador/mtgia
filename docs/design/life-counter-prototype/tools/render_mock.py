#!/usr/bin/env python3
"""Renderiza um mock HTML no tamanho do iPhone deitado (874x402 @2x) e grava PNGs.
Uso: python3 tools/render_mock.py <arquivo.html> <saida.png> [#estado]
O terceiro argumento vira location.hash, para o mesmo HTML mostrar mais de um estado."""
import glob, pathlib, sys
from playwright.sync_api import sync_playwright
EXE = glob.glob(str(pathlib.Path.home() / 'Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell'))[0]
html, out = pathlib.Path(sys.argv[1]).resolve(), pathlib.Path(sys.argv[2]).resolve()
hash_ = sys.argv[3] if len(sys.argv) > 3 else ''
with sync_playwright() as pw:
    b = pw.chromium.launch(executable_path=EXE)
    pg = b.new_page(viewport={'width': 874, 'height': 402}, device_scale_factor=2)
    erros = []
    pg.on('pageerror', lambda e: erros.append(str(e).splitlines()[0]))
    pg.goto('file://' + str(html) + hash_)
    pg.wait_for_timeout(900)          # fontes e transições
    pg.screenshot(path=str(out))
    b.close()
print('ok', out, 'erros de JS:', erros or 'nenhum')
