#!/usr/bin/env python3
"""Tira retratos do protótipo em estados nomeados, para olhar antes de qualquer teste.
Uso: python3 tools/look.py menu|mesa|regras [saida.png]"""
import glob, pathlib, sys
from playwright.sync_api import sync_playwright
ROOT = pathlib.Path(__file__).resolve().parent.parent
EXE = glob.glob(str(pathlib.Path.home() / 'Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell'))[0]
estado = sys.argv[1]; out = sys.argv[2] if len(sys.argv) > 2 else str(ROOT / 'design' / ('look-' + estado + '.png'))
with sync_playwright() as pw:
    b = pw.chromium.launch(executable_path=EXE)
    pg = b.new_page(viewport={'width': 874, 'height': 402}, device_scale_factor=2, has_touch=True)
    erros = []; pg.on('pageerror', lambda e: erros.append(str(e).splitlines()[0]))
    pg.goto('file://' + str(ROOT / 'serve' / 'index.html'))
    pg.wait_for_function('window.__mesa && __mesa.state().players.length > 0')
    pg.evaluate('([l,t,r,bb]) => __setInsets(l,t,r,bb)', [62, 0, 62, 21])
    if estado.startswith('menu'):
        if estado == 'menu-vivo':                       # com coisas valendo: turno, noite, plano, coroa
            pg.click('#btnHub'); pg.click('#btnTurn'); pg.click('#btnTurn'); pg.click('#btnDayNight'); pg.click('#btnDayNight')
        else: pg.click('#btnHub')
    elif estado == 'mesa': pg.click('#btnHub'); pg.click('#tileMesa')
    elif estado.startswith('arranjo'):
        pg.click('#btnHub'); pg.click('#tileMesa')
        alvo = estado.split('-')[1] if '-' in estado else '5'
        pg.click('[data-act=count][data-v="%s"]' % alvo)
        if pg.evaluate("() => __mesa.state().players.length") != int(alvo):
            pg.click('[data-act=count][data-v="%s"]' % alvo)
    elif estado == 'regras': pg.click('#btnHub'); pg.click('#tileRules')
    elif estado == 'dados':
        pg.click('#btnHub'); pg.click('#menu [data-open=dice]')
        for n in ('6', '8', '20'): pg.click('[data-act=roll][data-sides="%s"]' % n)
    elif estado == 'dados-inicio':
        pg.click('#btnHub'); pg.click('#menu [data-open=dice]'); pg.click('[data-act=roll][data-sides="20"]'); pg.click('[data-act=highroll]')
    elif estado == 'turnos':
        pg.click('#btnHub'); pg.click('#btnTurn'); pg.click('#btnTurn'); pg.click('#tileTurns'); pg.wait_for_timeout(1200)
    elif estado == 'plano':
        pg.click('#btnHub'); pg.click('#btnPlane'); pg.click('[data-act=pcmode]')
        pg.click('[data-act=planarroll]'); pg.fill('#pPlane', 'Academia Ruína'); pg.click('[data-act=chaos][data-d="1"]')
    elif estado == 'plano-arqui':
        pg.click('#btnHub'); pg.click('#btnPlane'); pg.click('[data-act=aemode]'); pg.click('[data-act=setarch][data-p=p2]')
        pg.click('[data-act=scheme][data-d="1"]'); pg.click('[data-act=scheme][data-d="1"]')
    elif estado in ('partidas', 'partida', 'resumo'):
        # três partidas guardadas: uma com vencedor, uma empatada e uma longa
        pg.evaluate("""() => {
          const agora = Date.now(), cor = ['brasa','mare','musgo','ambar','indigo','cobre'];
          const jog = (n, i, l, o, f) => ({ n: n, c: cor[i], l: l, m: i === 1 ? 14 : 0, v: i === 2 ? 3 : 0, o: o || '', f: f || '', ms: 400000 });
          const g = [
            { s: agora - 3600e3, e: agora - 1800e3, n: 40, k: 'fim', wi: 0, wm: 0, d: 0, t: 1802000,
              p: [jog('Rafa', 0, 27, '', 'Atraxa fez o serviço'), jog('Bia', 1, 0, 'dano de comandante'), jog('Léo', 2, 0, 'veneno'), jog('Duda', 3, 12, '')] },
            { s: agora - 26 * 3600e3, e: agora - 25 * 3600e3, n: 40, k: 'nova', wi: -1, wm: 0, d: 1, t: 2740000,
              p: [jog('Rafa', 0, 0, 'vida zerada'), jog('Nina', 4, 0, 'vida zerada'), jog('Téo', 5, 0, 'vida zerada')] },
            { s: agora - 52 * 3600e3, e: agora - 50 * 3600e3, n: 30, k: 'fim', wi: 1, wm: 1, d: 0, t: 5430000,
              p: [jog('Caio', 2, 4, ''), jog('Duda', 3, 18, '', 'Talrand não deixou barato'), jog('Mel', 5, 0, 'concedeu')] }
          ];
          localStorage.setItem('brewtact.mesa.hist.v1', JSON.stringify({ hv: 1, g: g }));
        }""")
        pg.click('#btnHub'); pg.click('#tileHistory')
        if estado == 'partida': pg.click('.hx-g.hero .hx-open')
        if estado == 'resumo':
            pg.click('[data-act=close]'); pg.click('#btnHub'); pg.click('#menu [data-open=summary]')
    elif estado in ('peca', 'peca-livre'):
        if estado == 'peca':
            pg.click('.panel[data-id=p1] .more'); pg.click('[data-act=monarch]'); pg.click('[data-act=close]')
        pg.click('#btnHub'); pg.click('#tileCrown')
        if estado == 'peca-livre': pg.click('.tk-p.livre')
    elif estado == 'teclado':
        pg.click('.panel[data-id=p2] .setlife')
        for n in ('2', '7'): pg.click('[data-act=digit][data-n="%s"]' % n)
    elif estado == 'teclado-limpo': pg.click('.panel[data-id=p2] .setlife')
    elif estado == 'vida-inicial':
        pg.click('#btnHub'); pg.click('#tileMesa'); pg.click('[data-act=startother]')
        for n in ('5', '0'): pg.click('[data-act=sdigit][data-n="%s"]' % n)
    elif estado == 'jogador': pg.click('.panel[data-id=p2] .more')
    elif estado == 'jogador-fim':
        pg.click('.panel[data-id=p2] .more'); pg.evaluate("document.querySelector('.sheet-body').scrollTop = 9999")
    pg.wait_for_timeout(700)
    pg.screenshot(path=out)
    b.close()
print('ok', out, '| erros de JS:', erros or 'nenhum')
