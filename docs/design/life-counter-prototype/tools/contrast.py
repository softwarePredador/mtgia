#!/usr/bin/env python3
"""Contraste WCAG medido nos pixels: esconde o elemento, fotografa o fundo onde ele estava,
e compara com a tinta real (cor computada, já composta se tiver alfa)."""
import glob, pathlib, io
from playwright.sync_api import sync_playwright
from PIL import Image
ROOT = pathlib.Path(__file__).resolve().parent.parent
EXE = glob.glob(str(pathlib.Path.home() / 'Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell'))[0]

def lum(c):
    f = lambda v: (v / 255) / 12.92 if v / 255 <= .03928 else (((v / 255) + .055) / 1.055) ** 2.4
    return .2126 * f(c[0]) + .7152 * f(c[1]) + .0722 * f(c[2])
def ratio(a, b):
    la, lb = lum(a), lum(b); hi, lo = max(la, lb), min(la, lb); return (hi + .05) / (lo + .05)
def parse(t):
    p = [x.strip() for x in t.replace('rgba(', '').replace('rgb(', '').replace(')', '').split(',')]
    return tuple(int(float(x)) for x in p[:3]), (float(p[3]) if len(p) > 3 else 1.0)

MENU = [('coroa acesa · ícone', '#tileCrown .ic', 'icone'), ('coroa acesa · rótulo', '#tileCrown .lb', 'texto'),
        ('coroa acesa · estado', '#tileCrown .state', 'texto'), ('herói · rótulo', '.menu .hero .lb', 'texto'),
        ('herói · nome', '.menu .hero .quem', 'grande'), ('dia/noite aceso · estado', '#btnDayNight .state', 'texto')]
# partidas guardadas e resultado: texto claro sobre a cor cheia do jogador é o caso de risco
HX = [('ficha · data', '.hx-g.hero .meta em', 'texto'), ('ficha · fala de quem venceu', '.hx-g.hero .say', 'texto'),
      ('ficha · duração', '.hx-g.hero .dur', 'grande'), ('ficha sem dono · nome', '.hx-g.livre b', 'grande'),
      ('ficha sem dono · data', '.hx-g.livre .meta em', 'texto')]
RS = [('resultado · nome', '.rs-p.win .who b', 'texto'), ('resultado · nota', '.rs-p.win .who i', 'texto'),
      ('resultado · numeral', '.rs-p.win .num', 'grande'), ('resultado · selo venceu', '.rs-p .tags em.won', 'texto'),
      ('resultado · selo', '.rs-p:not(.win) .tags em', 'texto')]
PD = [('teclado · legenda', '.padout .cap', 'texto'), ('teclado · numeral', '.padout output', 'grande'),
      ('teclado · apoio', '.padout .sub', 'texto'), ('teclado · tecla', '.pad button', 'grande'),
      ('teclado · vida inicial', '.pd-v b', 'grande'), ('teclado · rótulo da peça', '.pd-v i', 'texto')]
TK = [('peça · nome do dono', '.tk-hero b', 'grande'), ('peça · linha do dono', '.tk-hero i', 'texto'),
      ('peça · nome no card', '.tk-p.on b', 'texto'), ('peça · estado no card', '.tk-p.on i', 'texto'),
      ('peça vazia · nome', '.tk-p.livre b', 'texto')]
PF = [('concedeu aceso · título', '.rt.bad.on b', 'texto'), ('concedeu aceso · estado', '.rt.bad.on .st', 'texto'),
      ('vida · legenda', '.pf-life .cap', 'texto'), ('vida · numeral', '.pf-row output', 'grande'),
      ('placa · fio', '.plaque input', 'fio'), ('coroa acesa (pf) · título', '.pf-states .rt.on b', 'texto')]

def medir(pg, alvos):
    pg.wait_for_timeout(400)      # a folha entra em 160ms; medir antes disso mede a mesa por baixo
    out = []
    for nome, sel, tipo in alvos:
        d = pg.evaluate("""(sel) => { const e = document.querySelector(sel); if (!e) return null;
          const cs = getComputedStyle(e), r = e.getBoundingClientRect();
          if (r.width < 2 || r.height < 2) return null;
          return { cor: tipoFio(cs), r: [r.x, r.y, r.width, r.height], h: parseFloat(cs.fontSize) || 0, peso: cs.fontWeight };
          function tipoFio(c) { return c.borderBottomWidth !== '0px' && c.borderBottomStyle !== 'none' ? c.borderBottomColor : c.color; } }""", sel)
        if not d: continue
        x, y, w, h = d['r']
        cx, cy = x + w / 2, y + h / 2
        if tipo == 'fio': cy = y + h - 1                      # o fio mora na base do campo
        # apagar só a tinta (e não o elemento) revela o fundo que o glifo realmente pisa —
        # inclusive o fundo da própria peça, como no selo de latão "Venceu"
        esconde = "(sel) => { document.querySelector(sel).style.visibility = 'hidden'; }" if tipo == 'fio' \
            else "(sel) => { const e = document.querySelector(sel); e.dataset.corAntes = e.style.color; e.style.color = 'transparent'; }"
        pg.evaluate(esconde, sel)
        cx = min(max(3, cx), 871); cy = min(max(3, cy), 399)      # o recorte tem de caber na tela
        buf = pg.screenshot(clip={'x': cx - 3, 'y': cy - 3, 'width': 6, 'height': 6})
        volta = "(sel) => { document.querySelector(sel).style.visibility = ''; }" if tipo == 'fio' \
            else "(sel) => { const e = document.querySelector(sel); e.style.color = e.dataset.corAntes || ''; delete e.dataset.corAntes; }"
        pg.evaluate(volta, sel)
        im = Image.open(io.BytesIO(buf)).convert('RGB')
        fundo = im.resize((1, 1)).getpixel((0, 0))            # média do pedacinho
        tinta, a = parse(d['cor'])
        if a < 1: tinta = tuple(round(tinta[i] * a + fundo[i] * (1 - a)) for i in range(3))
        grande = tipo == 'grande' or (d['h'] >= 24) or (d['h'] >= 18.66 and int(d['peso'] or 400) >= 700)
        minimo = 3.0 if tipo in ('icone', 'fio') or grande else 4.5
        out.append((nome, ratio(tinta, fundo), minimo, fundo, tinta))
    return out

with sync_playwright() as pw:
    b = pw.chromium.launch(executable_path=EXE)
    pg = b.new_page(viewport={'width': 874, 'height': 402}, device_scale_factor=2)
    pg.goto('file://' + str(ROOT / 'serve' / 'index.html'))
    pg.wait_for_function('window.__mesa && __mesa.state().players.length > 0')
    pg.evaluate('([l,t,r,bb]) => __setInsets(l,t,r,bb)', [62, 0, 62, 21])
    pg.click('#btnHub'); pg.click('#btnTurn'); pg.click('#btnDayNight')
    linhas = medir(pg, MENU)
    pg.click('#btnHub')
    pg.click('.panel[data-id=p2] .more'); pg.click('[data-act=concede]')
    pg.screenshot(path=str(ROOT / 'design' / 'look-jogador-concedeu.png'))
    linhas += medir(pg, PF)
    pg.click('[data-act=close]')
    SEED = """(vencedora) => { const agora = Date.now(), cor = [vencedora,'mare','musgo','ambar'];
      const jog = (n, i, l, o, f) => ({ n: n, c: cor[i], l: l, m: i === 1 ? 14 : 0, v: 0, o: o || '', f: f || '', ms: 4e5 });
      localStorage.setItem('brewtact.mesa.hist.v1', JSON.stringify({ hv: 1, g: [
        { s: agora - 36e5, e: agora, n: 40, k: 'fim', wi: 0, wm: 0, d: 0, t: 18e5,
          p: [jog('Rafa', 0, 27, '', 'Atraxa fez o serviço'), jog('Bia', 1, 0, 'dano de comandante'), jog('Léo', 2, 0, 'veneno')] },
        { s: agora - 72e5, e: agora, n: 40, k: 'nova', wi: -1, wm: 0, d: 1, t: 27e5,
          p: [jog('Rafa', 0, 0, 'vida zerada'), jog('Nina', 3, 0, 'vida zerada')] } ] })); }"""
    # duas passadas: a cor de card mais escura e a mais clara da paleta — o pior caso de cada lado
    for cor, sufixo in (('brasa', ''), ('oliva', ' (oliva)')):
        pg.evaluate(SEED, cor)
        pg.click('#btnHub'); pg.click('#tileHistory')
        linhas += [(n + sufixo, c, m, f, t) for n, c, m, f, t in medir(pg, HX)]
        pg.click('.hx-g.hero .hx-open')
        linhas += [(n + sufixo, c, m, f, t) for n, c, m, f, t in medir(pg, RS)]
        pg.click('[data-act=close]')
    # teclado e peça na cor mais clara da paleta, que é o pior caso para tinta marfim
    pg.click('.panel[data-id=p1] .more'); pg.click('[data-act=color][data-c=oliva]')
    pg.click('[data-act=monarch]'); pg.click('[data-act=close]')
    pg.click('.panel[data-id=p1] .setlife')
    pg.click('[data-act=digit][data-n="1"]'); pg.click('[data-act=digit][data-n="5"]')
    linhas += medir(pg, PD)
    pg.click('[data-act=close]')
    pg.click('#btnHub'); pg.click('#tileCrown')
    linhas += medir(pg, TK)
    pg.click('[data-act=close]')
    b.close()

print('%-30s %7s %6s  %s' % ('alvo', 'razão', 'mín', 'veredito'))
ruins = 0
for nome, cr, minimo, fundo, tinta in linhas:
    ok = cr >= minimo; ruins += 0 if ok else 1
    print('%-30s %7.2f %6.1f  %s   fundo %s tinta %s' % (nome, cr, minimo, 'ok' if ok else 'REPROVA', fundo, tinta))
print(('%d alvo(s) reprovando' % ruins) if ruins else 'tudo dentro do mínimo')
