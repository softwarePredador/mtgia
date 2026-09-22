#!/usr/bin/env python3
"""Mede, para cada arranjo de duas fileiras, se o numeral fica acima do piso
(40 px de corpo e 38% da altura do card) em paisagem e em retrato."""
import glob, pathlib, sys
from playwright.sync_api import sync_playwright
ROOT = pathlib.Path(__file__).resolve().parent.parent
EXE = glob.glob(str(pathlib.Path.home() / 'Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell'))[0]
LAND, PORT = {'width': 874, 'height': 402}, {'width': 402, 'height': 874}
IL, IP = (62, 0, 62, 21), (0, 59, 0, 34)
CENTRE = """() => [...document.querySelectorAll('.panel')].map(pn => {
  const c = pn.getBoundingClientRect(), e = pn.querySelector('.life');
  return { id: pn.dataset.id, font: parseFloat(getComputedStyle(e).fontSize), w: pn.offsetWidth, h: pn.offsetHeight,
           top: !!pn.closest('.row-top') };
})"""
with sync_playwright() as pw:
    b = pw.chromium.launch(executable_path=EXE)
    print('%-4s %-7s %-9s %6s %6s %6s %7s  %s' % ('j', 'arranjo', 'tela', 'card w', 'card h', 'corpo', 'altura', 'veredito'))
    for vp, ins, tag in ((LAND, IL, 'paisagem'), (PORT, IP, 'retrato')):
        pg = b.new_page(viewport=vp, device_scale_factor=2, has_touch=True)
        pg.goto('file://' + str(ROOT / 'serve' / 'index.html')); pg.wait_for_function('window.__mesa')
        for n in range(2, 11):
            for baixo in range(1, n):
                pg.evaluate("""([n, baixo, ins]) => {
                  localStorage.clear();
                  const s = { v: 3, startLife: 40, cmdHurtsLife: true, tapNumber: true, holdStep: 10, customDice: 100,
                              seatRow: baixo, startedAt: Date.now(),
                              players: Array.from({ length: n }, (_, i) => ({ name: 'J' + (i + 1), life: 40 })) };
                  localStorage.setItem('brewtact.mesa.prototipo.v3', JSON.stringify(s));
                }""", [n, baixo, list(ins)])
                pg.reload(); pg.wait_for_function('window.__mesa && __mesa.state().players.length > 0')
                pg.evaluate('([l,t,r,bb]) => __setInsets(l,t,r,bb)', list(ins))
                pg.wait_for_timeout(120)
                got = pg.evaluate("() => __mesa.state().seatRow")
                rows = pg.evaluate(CENTRE)
                if got != baixo:
                    print('%-4d %-7s %-9s  arranjo recusado pelo estado (veio %s)' % (n, '%d+%d' % (n - baixo, baixo), tag, got))
                    continue
                pior = min(rows, key=lambda r: .72 * r['font'] / r['h'])
                share = .72 * pior['font'] / pior['h']
                ok = pior['font'] >= 40 and share >= .38
                print('%-4d %-7s %-9s %6d %6d %6.0f %6.0f%%  %s' % (n, '%d+%d' % (n - baixo, baixo), tag,
                      pior['w'], pior['h'], pior['font'], 100 * share, 'ok' if ok else 'REPROVA'))
        pg.close()
    b.close()
