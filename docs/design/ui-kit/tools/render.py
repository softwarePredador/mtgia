#!/usr/bin/env python3
"""Renderiza um mock HTML em PNG (Playwright, Chromium headless, @2x).

Uso:
  python3 docs/design/ui-kit/tools/render.py <arquivo.html> <saida.png> [--w 390] [--h 844] [--hash '#estado'] [--full]

Perfis usuais: mobile 390x844 · tablet 834x1194 · desktop 1440x900 · wide 1920x1080 · iPhone deitado 874x402.
--hash vira location.hash, para o mesmo HTML mostrar mais de um estado.
--full captura a página inteira (use só quando a tela rola de propósito).
Sai com código 1 se houver erro de JS ou se Fraunces/Inter não carregarem: um mock com fonte errada não vale como prova.
"""
import argparse, glob, pathlib, sys
from playwright.sync_api import sync_playwright

ap = argparse.ArgumentParser()
ap.add_argument('html'); ap.add_argument('out')
ap.add_argument('--w', type=int, default=390); ap.add_argument('--h', type=int, default=844)
ap.add_argument('--hash', default=''); ap.add_argument('--full', action='store_true')
a = ap.parse_args()
exe = glob.glob(str(pathlib.Path.home() / 'Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell'))
html, out = pathlib.Path(a.html).resolve(), pathlib.Path(a.out).resolve()
out.parent.mkdir(parents=True, exist_ok=True)
with sync_playwright() as pw:
    b = pw.chromium.launch(executable_path=exe[0] if exe else None, args=['--allow-file-access-from-files'])
    pg = b.new_page(viewport={'width': a.w, 'height': a.h}, device_scale_factor=2)
    erros = []
    pg.on('pageerror', lambda e: erros.append(str(e).splitlines()[0]))
    pg.goto('file://' + str(html) + a.hash)
    pg.wait_for_timeout(700)
    fontes = pg.evaluate("""async () => { await document.fonts.ready;
      return {fraunces: document.fonts.check('700 40px Fraunces'), inter: document.fonts.check('800 12px Inter'),
              rola: document.documentElement.scrollHeight > window.innerHeight + 1,
              estouroX: document.documentElement.scrollWidth > window.innerWidth + 1}; }""")
    pg.screenshot(path=str(out), full_page=a.full)
    b.close()
print('ok', out, '| viewport', f'{a.w}x{a.h}', '| erros de JS:', erros or 'nenhum', '|', fontes)
if fontes['estouroX']: print('AVISO: a página estoura na horizontal')
if fontes['rola'] and not a.full: print('AVISO: a página rola; o PNG mostra só a primeira dobra (use --full se a rolagem for intencional)')
sys.exit(1 if erros or not (fontes['fraunces'] and fontes['inter']) else 0)
