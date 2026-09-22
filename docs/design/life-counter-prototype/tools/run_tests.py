"""Functional checks for the BrewTact table prototype, driven through real touch input
(CDP Input.dispatchTouchEvent -> the page receives touch + pointer events, single and multi-finger).
Every check asserts on the page's own state, and key states are saved as screenshots."""
import glob, json, os, pathlib, sys, time, traceback
from playwright.sync_api import sync_playwright

ROOT = pathlib.Path(__file__).resolve().parent.parent
# always test the current source, never a stale wrap
__import__('subprocess').run([sys.executable, str(ROOT / 'tools' / 'wrap.py')], check=True, capture_output=True)
URL = 'file://' + str(ROOT / 'serve' / 'index.html')
SHOTS = ROOT / 'proofs' / 'auto'
EXE = glob.glob(str(pathlib.Path.home() / 'Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell'))[0]
LAND = {'width': 874, 'height': 402}     # iPhone 17 lying sideways
PORT = {'width': 402, 'height': 874}
INSETS_LAND = (62, 0, 62, 21)
INSETS_PORT = (0, 62, 0, 34)

results = []

class T:
    def __init__(self, page, cdp):
        self.page, self.cdp = page, cdp
    # ── state ──
    def st(self): return self.page.evaluate('__mesa.state()')
    def view(self): return self.page.evaluate('__mesa.view()')
    def hist(self): return self.page.evaluate('__mesa.hist()')
    def p(self, pid): return next(x for x in self.st()['players'] if x['id'] == pid)
    def out(self, pid): return self.page.evaluate('id => __mesa.out(id)', pid)
    # ── geometry ──
    def box(self, sel):
        b = self.page.locator(sel).first.bounding_box()
        assert b, 'no box for ' + sel
        return b
    def centre(self, sel):
        b = self.box(sel); return b['x'] + b['width'] / 2, b['y'] + b['height'] / 2
    def half(self, pid, sign):
        return self.centre('.panel[data-id=%s] .half.%s' % (pid, 'plus' if sign > 0 else 'minus'))
    # ── touch ──
    def _touch(self, kind, pts):
        self.cdp.send('Input.dispatchTouchEvent', {'type': kind, 'touchPoints': [{'x': x, 'y': y, 'id': i} for (i, x, y) in pts]})
    def tap(self, x, y, fid=1, ms=40):
        self._touch('touchStart', [(fid, x, y)]); time.sleep(ms / 1000); self._touch('touchEnd', [])
    def hold(self, x, y, ms):
        self._touch('touchStart', [(1, x, y)]); time.sleep(ms / 1000); self._touch('touchEnd', [])
    def swipe(self, x1, y1, x2, y2, steps=6):
        self._touch('touchStart', [(1, x1, y1)])
        for i in range(1, steps + 1):
            self._touch('touchMove', [(1, x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps)]); time.sleep(.012)
        self._touch('touchEnd', [])
    def swipe_panel(self, pid, direction):
        """direction is from the player's own point of view on a landscape table: 'right' or 'left'."""
        x, y = self.centre('.panel[data-id=%s]' % pid)
        top = self.page.evaluate('id => !!document.querySelector(`.panel[data-id=${id}]`).closest(".row-top")', pid)
        d = 90 if direction == 'right' else -90
        if top: d = -d
        self.swipe(x - d / 2, y, x + d / 2, y)
    def click(self, sel):
        try: self.page.locator(sel).first.click(timeout=4000)
        except Exception as e: raise AssertionError('[%s] click failed on %s: %s' % (self.page.title(), sel, str(e).splitlines()[0]))
    def shot(self, name): self.page.screenshot(path=str(SHOTS / (name + '.png')))
    def fresh(self, players=4, insets=INSETS_LAND):
        self.page.evaluate('localStorage.clear()'); self.page.reload()
        self.page.wait_for_function('window.__mesa && __mesa.state().players.length > 0')
        self.page.evaluate('([l,t,r,b]) => __setInsets(l,t,r,b)', list(insets))
        if players != 4:
            self.open_mesa(); self.choose('count', players); self.click('[data-act=close]')
    def choose(self, act, val):
        """Pick players / starting life in the Mesa sheet. A game in progress asks for a second tap."""
        sel = '[data-act=%s][data-v="%d"]' % (act, val)
        self.click(sel)
        key = (lambda s: len(s['players'])) if act == 'count' else (lambda s: s['startLife'])
        if key(self.st()) != val: self.click(sel)
        assert key(self.st()) == val
    def open_hub(self):
        if not self.view()['hubOpen']: self.click('#btnHub')
    def set_page(self, pid, page):
        """Turn a panel to one of its faces without a gesture, the way the sheet offers it."""
        self.click('.panel[data-id=%s] .more' % pid)
        assert self.view()['sheet'] == 'player'
        self.click('[data-act=page][data-p=%s]' % page)
        assert self.view()['sheet'] is None
        got = 'cmd' if self.view()['cmdFor'] == pid else (self.view()['page'].get(pid) or 'life')
        assert got == page, got

    def close_hub(self):
        if self.view()['hubOpen']: self.click('#btnHub')
        assert not self.view()['hubOpen']

    def open_turns(self):
        self.open_hub(); self.click('#tileTurns')
        assert self.view()['sheet'] == 'turns'

    def open_rules(self):
        self.open_hub(); self.click('#tileRules')
        assert self.view()['sheet'] == 'rules'

    def open_mesa(self):
        """Mesa = o seletor visual de jogadores e vida inicial, aberto pela peça Mesa do menu."""
        self.open_hub(); self.click('#tileMesa')
        assert self.view()['sheet'] == 'mesa'


def check(name):
    def deco(fn):
        def run(t):
            try:
                fn(t); results.append((name, True, '')); print('PASS', name)
            except Exception as e:
                tb = traceback.format_exc().strip().splitlines()
                where = next((l.strip() for l in reversed(tb) if 'run_tests.py' in l), '')
                results.append((name, False, '%s | %s' % (str(e).splitlines()[0] if str(e) else type(e).__name__, where)))
                print('FAIL', name, '->', results[-1][2])
                if os.environ.get('MESA_TB'): print(traceback.format_exc())
                try: t.shot('FAIL-' + name.split(' ')[0])
                except Exception: pass
        run.__name__ = fn.__name__; CHECKS.append(run); return run
    return deco
CHECKS = []

# ─────────────────────────── table & taps ───────────────────────────
@check('01 mesa inicial: 4 painéis, assentos em sentido horário, fileira de cima invertida')
def _(t):
    t.fresh()
    assert t.page.locator('.panel').count() == 4
    ids = t.page.evaluate('[...document.querySelectorAll(".row-bottom .panel")].map(e=>e.dataset.id).join()+"|"+[...document.querySelectorAll(".row-top .panel")].map(e=>e.dataset.id).join()')
    assert ids == 'p1,p2|p4,p3', ids
    px, _y = t.half('p3', +1); mx, _y2 = t.half('p3', -1)
    assert px < mx, 'top row: the player\'s + must be on the screen left'
    px, _y = t.half('p1', +1); mx, _y2 = t.half('p1', -1)
    assert px > mx
    t.page.wait_for_timeout(2600); t.shot('01-mesa-4-jogadores')

@check('02 toque +1 e −1 (fileira de baixo e de cima)')
def _(t):
    t.fresh(); a = t.p('p1')['life']; c = t.p('p3')['life']
    t.tap(*t.half('p1', +1)); t.tap(*t.half('p1', +1)); t.tap(*t.half('p1', -1))
    t.tap(*t.half('p3', +1))
    assert t.p('p1')['life'] == a + 1, t.p('p1')['life']
    assert t.p('p3')['life'] == c + 1

@check('03 segurar repete de 10 em 10 e não soma 1 ao soltar')
def _(t):
    t.fresh(); a = t.p('p2')['life']
    t.hold(*t.half('p2', +1), ms=1050)       # 480 ms -> +10, 900 ms -> +10
    assert t.p('p2')['life'] == a + 20, t.p('p2')['life']
    t.hold(*t.half('p2', -1), ms=300)        # shorter than the hold threshold = a plain tap
    assert t.p('p2')['life'] == a + 19

@check('04 toques rápidos: contam todos, não dão zoom, e desfazer volta o bloco de uma vez')
def _(t):
    t.fresh(); a = t.p('p1')['life']; x, y = t.half('p1', +1)
    for _i in range(8): t.tap(x, y, ms=25); time.sleep(.03)
    assert t.p('p1')['life'] == a + 8, t.p('p1')['life']
    assert t.page.evaluate('visualViewport.scale') == 1
    assert 'on' in t.page.locator('.panel[data-id=p1] .delta').get_attribute('class')
    assert t.page.locator('.panel[data-id=p1] .delta').inner_text() == '+8'
    t.shot('04-delta-acumulado')
    t.open_hub(); t.click('#btnUndo')
    assert t.p('p1')['life'] == a, 'undo should drop the whole burst'

@check('05 MULTITOQUE: dois jogadores tocam ao mesmo tempo e os dois contam')
def _(t):
    t.fresh(); a = t.p('p1')['life']; b = t.p('p2')['life']
    x1, y1 = t.half('p1', +1); x2, y2 = t.half('p2', -1)
    t._touch('touchStart', [(1, x1, y1)]); t._touch('touchStart', [(1, x1, y1), (2, x2, y2)])
    time.sleep(.05); t._touch('touchEnd', [(2, x2, y2)]); time.sleep(.02); t._touch('touchEnd', [])   # CDP: touchEnd lifts the fingers it lists
    assert t.p('p1')['life'] == a + 1 and t.p('p2')['life'] == b - 1, (t.p('p1')['life'], t.p('p2')['life'])

@check('06 MULTITOQUE: um jogador segura enquanto outro toca três vezes')
def _(t):
    t.fresh(); a = t.p('p1')['life']; c = t.p('p3')['life']
    x1, y1 = t.half('p1', -1); x3, y3 = t.half('p3', +1)
    t._touch('touchStart', [(1, x1, y1)])
    for _i in range(3):
        time.sleep(.12); t._touch('touchStart', [(1, x1, y1), (2, x3, y3)]); time.sleep(.04); t._touch('touchEnd', [(2, x3, y3)])
    time.sleep(.45); t._touch('touchEnd', [])
    assert t.p('p3')['life'] == c + 3, t.p('p3')['life']
    assert t.p('p1')['life'] <= a - 10, 'the held finger must keep repeating: %s' % t.p('p1')['life']

# ─────────────────────────── commander damage ───────────────────────────
@check('07 arrastar para a direita abre dano de comandante; os outros painéis viram entrada; Concluir sai')
def _(t):
    t.fresh(); life = t.p('p1')['life']
    t.swipe_panel('p1', 'right')
    assert t.view()['cmdFor'] == 'p1'
    assert t.page.locator('.panel.is-source').count() == 3 and t.page.locator('.panel.is-receiver').count() == 1
    for _i in range(3): t.tap(*t.half('p2', +1)); time.sleep(.03)
    t.tap(*t.half('p3', +1))                       # far-side seat
    t.hold(*t.half('p4', +1), ms=600)               # hold = +5
    p1 = t.p('p1')
    assert p1['cmd'] == {'p2': 3, 'p3': 1, 'p4': 5}, p1['cmd']
    assert p1['life'] == life - 9, p1['life']
    assert t.page.locator('.panel[data-id=p2] .life').inner_text() == '3'
    t.shot('07-dano-de-comandante')
    t.tap(*t.half('p2', -1))
    assert t.p('p1')['cmd']['p2'] == 2 and t.p('p1')['life'] == life - 8
    t.click('.panel[data-id=p1] [data-done]')
    assert t.view()['cmdFor'] is None
    assert t.page.locator('.panel[data-id=p1] .life').inner_text() == str(life - 8)

@check('08 painel que está servindo de entrada ignora arrasto; Esc sai do modo')
def _(t):
    t.fresh(); t.swipe_panel('p1', 'right'); t.swipe_panel('p2', 'left'); t.swipe_panel('p2', 'right')
    assert t.view()['cmdFor'] == 'p1' and t.view()['page'].get('p2', 'life') == 'life'
    t.page.keyboard.press('Escape'); assert t.view()['cmdFor'] is None

@check('09 assento do outro lado: o arrasto é lido do ponto de vista de quem senta lá')
def _(t):
    t.fresh(); x, y = t.centre('.panel[data-id=p3]')
    t.swipe(x + 45, y, x - 45, y)      # screen-left == that player's right -> commander damage
    assert t.view()['cmdFor'] == 'p3', t.view()
    t.swipe(x - 45, y, x + 45, y); assert t.view()['cmdFor'] is None
    t.swipe(x - 45, y, x + 45, y); assert t.view()['page']['p3'] == 'counters'

@check('10 21 de dano do mesmo comandante elimina; 20+20 de dois comandantes não elimina por dano')
def _(t):
    t.fresh(); t.open_rules(); t.click('[data-act=cmdlife]'); t.click('[data-act=close]')
    assert t.st()['cmdHurtsLife'] is False
    t.swipe_panel('p1', 'right'); life = t.p('p1')['life']
    t.hold(*t.half('p2', +1), ms=2250)               # +5 x5 = 25? measured below
    got = t.p('p1')['cmd']['p2']; assert got >= 20, got
    while t.p('p1')['cmd']['p2'] > 20: t.tap(*t.half('p2', -1))
    t.hold(*t.half('p3', +1), ms=2250)
    while t.p('p1')['cmd']['p3'] > 20: t.tap(*t.half('p3', -1))
    assert t.p('p1')['life'] == life, 'rule is off: life must not move'
    assert t.out('p1') == '', t.out('p1')
    t.tap(*t.half('p2', +1))
    assert t.out('p1') == 'Dano de comandante letal'
    t.click('.panel[data-id=p1] [data-done]'); t.shot('10-eliminado-por-dano-de-comandante')

# ─────────────────────────── counters ───────────────────────────
@check('11 arrastar para a esquerda abre contadores; veneno 10 elimina; taxa vai de 2 em 2; − desabilita em zero')
def _(t):
    t.fresh(); t.swipe_panel('p4', 'left')
    assert t.view()['page']['p4'] == 'counters'
    base = '.panel[data-id=p4] '
    assert t.page.locator(base + '.cadd').is_visible(), 'the counters page offers the catalogue'
    assert t.page.locator(base + '.pm[data-c=energy][data-d="-1"]').is_disabled()
    for _i in range(10): t.click(base + '.pm[data-c=poison][data-d="1"]')
    assert t.p('p4')['c']['poison'] == 10 and t.out('p4') == 'Veneno letal'
    t.click(base + '.pm[data-c=tax][data-d="2"]'); t.click(base + '.pm[data-c=tax][data-d="2"]'); t.click(base + '.pm[data-c=tax][data-d="-2"]')
    assert t.p('p4')['c']['tax'] == 2
    t.click(base + '.pm[data-c=xp][data-d="1"]'); t.click(base + '.pm[data-c=energy][data-d="1"]')
    t.shot('11-contadores'); t.swipe_panel('p4', 'right')
    assert t.view()['page']['p4'] == 'life'

@check('12 monarca é exclusivo')
def _(t):
    t.fresh(); assert t.p('p2')['monarch'] is True
    t.click('.panel[data-id=p1] .more'); t.click('[data-act=monarch]')
    assert [x['id'] for x in t.st()['players'] if x['monarch']] == ['p1']
    t.click('[data-act=monarch]')
    assert [x['id'] for x in t.st()['players'] if x['monarch']] == []
    t.click('[data-act=close]')

@check('13 sem arrastar: a folha troca de face, cada face tem a volta e os pontinhos dizem onde você está')
def _(t):
    t.fresh()
    dots = lambda: t.page.evaluate('''[...document.querySelectorAll('.panel[data-id=p2] .dots i')].map(d => d.classList.contains('on'))''')
    assert dots() == [False, True, False], dots()
    t.set_page('p2', 'cmd'); assert t.view()['cmdFor'] == 'p2' and dots() == [True, False, False]
    t.click('.panel[data-id=p2] [data-done]')                      # amber "Voltar" on the damage face
    assert t.view()['cmdFor'] is None and dots() == [False, True, False]
    t.set_page('p2', 'counters'); assert t.view()['page']['p2'] == 'counters' and dots() == [False, False, True]
    t.click('.panel[data-id=p2] .cback')                           # "Vida" inside the counters list
    assert t.view()['page']['p2'] == 'life' and dots() == [False, True, False]
    t.shot('13-faces-sem-arrastar')

# ─────────────────────────── elimination, winner, sheets ───────────────────────────
@check('14 folha do jogador: nome, cor, vida ±5, conceder; texto malicioso não vira HTML')
def _(t):
    t.fresh(); t.click('.panel[data-id=p1] .more')
    assert t.view()['sheet'] == 'player'
    t.page.fill('#pName', '<img src=x onerror=window.__xss=1>')
    assert t.page.locator('.panel[data-id=p1] .name b').inner_text().startswith('<img')
    assert t.page.locator('.panel img').count() == 0 and t.page.evaluate('window.__xss') is None
    t.page.fill('#pName', 'Rafael'); t.click('[data-act=color][data-c=indigo]')
    life = t.p('p1')['life']; t.click('[data-act=step][data-d="5"]'); t.click('[data-act=step][data-d="-1"]')
    assert t.p('p1')['life'] == life + 4 and t.p('p1')['color'] == 'indigo' and t.p('p1')['name'] == 'Rafael'
    t.shot('14-folha-do-jogador')
    t.click('[data-act=concede]'); assert t.out('p1') == 'Concedeu'
    t.click('[data-act=close]'); assert t.view()['sheet'] is None
    assert 'is-out' in t.page.locator('.panel[data-id=p1]').get_attribute('class')

@check('15 vida zero elimina; sobrando um, aparece o vencedor e o resumo; ganhar vida revive')
def _(t):
    t.fresh()
    for pid in ('p1', 'p2', 'p3'):
        t.click('.panel[data-id=%s] .more' % pid)
        while t.p(pid)['life'] > 0: t.click('[data-act=step][data-d="-5"]')
        t.click('[data-act=close]')
    assert t.out('p1') == 'Sem vida' and t.page.evaluate('__mesa.winner()') == 'p4'
    assert t.page.locator('#winner').is_visible() and 'Duda venceu' in t.page.locator('#winnerText').inner_text()
    t.shot('15-vencedor')
    t.click('#winner [data-open=summary]'); assert t.view()['sheet'] == 'summary'
    first = t.page.locator('.rs .rs-p').first.inner_text(); assert 'Duda' in first and 'VENCEU' in first.upper(), first
    t.shot('15-resumo'); t.click('[data-act=savepost]'); assert t.view()['sheet'] is None
    t.click('.panel[data-id=p1] .revive'); t.click('[data-act=revive]')
    assert t.out('p1') == '' and t.page.evaluate('__mesa.winner()') is None and not t.page.locator('#winner').is_visible()

@check('16 dados e moeda')
def _(t):
    t.fresh(); t.open_hub(); t.click('[data-open=dice]')
    for sides, ok in (('6', set(map(str, range(1, 7)))), ('20', set(map(str, range(1, 21)))), ('2', {'Cara', 'Coroa'})):
        for _i in range(6):
            t.click('[data-act=roll][data-sides="%s"]' % sides)
            assert t.st()['rolls'][0]['value'] in ok, t.st()['rolls'][0]
    assert len(t.st()['rolls']) == 12 and t.page.locator('.log li').count() == 8
    t.shot('16-dados'); t.page.keyboard.press('Escape'); assert t.view()['sheet'] is None

@check('17 sorteio de quem começa só escolhe quem está na partida')
def _(t):
    t.fresh(); t.click('.panel[data-id=p2] .more'); t.click('[data-act=concede]'); t.click('[data-act=close]')
    for _i in range(3):
        t.open_hub(); t.click('#btnStarter'); t.page.wait_for_function('document.querySelectorAll(".is-pick").length===0 && true', timeout=6000)
        t.page.wait_for_timeout(1700)
        s = t.st()['starter']; assert s in ('p1', 'p3', 'p4'), s
    t.shot('17-quem-comeca')

@check('18 menu da mesa: fechado por padrão, abre no hub sobre a mesa viva, o hub vira a saída, e cada peça mostra o estado')
def _(t):
    t.fresh(); assert t.view()['hubOpen'] is False and not t.page.locator('#btnUndo').is_visible()
    t.click('#btnHub'); assert t.view()['hubOpen'] and t.page.locator('#btnUndo').is_visible()
    assert t.page.locator('#btnHub .xmark').is_visible(), 'o hub vira o ✕, no mesmo ponto'
    # nada rola, nada sai da tela, toda peça tem alvo de dedo
    m = t.page.evaluate("""() => { const W = innerWidth, H = innerHeight;
      const bs = [...document.querySelectorAll('#menu button')].filter(b => b.offsetParent).map(b => b.getBoundingClientRect());
      return { n: bs.length, fora: bs.filter(r => r.left < -1 || r.top < -1 || r.right > W + 1 || r.bottom > H + 1).length,
               pequeno: bs.filter(r => r.width < 44 || r.height < 44).length,
               rola: document.querySelector('#menu').scrollHeight - document.querySelector('#menu').clientHeight }; }""")
    assert m['n'] >= 12 and m['fora'] == 0 and m['pequeno'] == 0 and m['rola'] <= 1, m
    # todo rótulo, estado e ícone mora DENTRO da própria peça e é legível (régua do menu)
    soltos = t.page.evaluate("""() => [...document.querySelectorAll('#menu .t')].flatMap(tile => { const tr = tile.getBoundingClientRect();
      return [...tile.querySelectorAll('.lb, .state, .ic, .num, .quem')].filter(e => e.offsetParent && e.textContent.trim() !== '' || e.tagName === 'svg')
        .filter(e => { const r = e.getBoundingClientRect(), o = parseFloat(getComputedStyle(e).opacity);
          if (!r.width || getComputedStyle(e).display === 'none') return false;
          return r.left < tr.left - 1 || r.right > tr.right + 1 || r.top < tr.top - 1 || r.bottom > tr.bottom + 1 || o < .55; })
        .map(e => (tile.id || tile.className) + ' › ' + (e.className.baseVal || e.className)); })""")
    assert soltos == [], 'fora da peça ou apagado: %s' % soltos
    cortados = t.page.evaluate("""() => [...document.querySelectorAll('#menu .lb, #menu .quem, #menu .state')]
      .filter(e => e.offsetParent && e.scrollWidth > e.clientWidth + 1).map(e => e.textContent.trim())""")
    assert cortados == [], 'texto cortado com reticências no menu: %s' % cortados
    # o estado mora dentro da peça
    assert t.page.locator('#tileCrown .state').inner_text() == 'Bia' and 'lit' in t.page.locator('#tileCrown').get_attribute('class')
    assert 'livre' in t.page.locator('#tileInit').get_attribute('class')
    assert t.page.locator('#menuCount').inner_text() == '4' and t.page.locator('#menuLife').inner_text() == '40'
    t.click('#btnTurn'); assert t.page.locator('#heroNum').inner_text() == '1'
    t.click('#btnDayNight'); assert 'is-day' in t.page.locator('#btnDayNight').get_attribute('class')
    t.shot('18-menu-de-pecas')
    t.click('#btnHub'); assert t.view()['hubOpen'] is False, 'o ✕ fecha'
    t.click('#btnHub'); t.page.mouse.click(8, 200); assert t.view()['hubOpen'] is False, 'tocar fora das peças fecha'
    t.open_mesa(); assert t.view()['sheet'] == 'mesa'; t.shot('18-mesa-visual'); t.click('[data-act=close]')
    t.open_rules(); t.shot('18-regras'); t.click('[data-act=menuback]'); assert t.view()['hubOpen'], 'a volta leva ao menu'
    t.close_hub()

# ─────────────────────────── players, new game, undo, storage ───────────────────────────
@check('19 de 2 a 6 jogadores: distribuição das fileiras, vida inicial, nomes mantidos, desfazer volta a partida anterior')
def _(t):
    t.fresh(); before = t.st()
    expect = {1: (1, 0), 2: (1, 1), 3: (2, 1), 5: (3, 2), 6: (3, 3), 7: (4, 3), 10: (5, 5), 4: (2, 2)}
    t.open_mesa()
    for n in (2, 3, 5, 6, 7, 10, 1, 4):
        t.choose('count', n)
        assert (t.page.locator('.row-bottom .panel').count(), t.page.locator('.row-top .panel').count()) == expect.get(n, (0, 0)), n
        assert all(p['life'] == 40 and p['cmd'] == {} for p in t.st()['players'])
    t.choose('start', 20); assert all(p['life'] == 20 for p in t.st()['players'])
    assert [p['name'] for p in t.st()['players']] == [p['name'] for p in before['players']]
    t.click('[data-act=close]')
    for _i in range(40):
        t.open_hub()
        if t.page.locator('#btnUndo').is_disabled(): break
        t.click('#btnUndo')
    now = t.st(); assert [p['life'] for p in now['players']] == [p['life'] for p in before['players']], [p['life'] for p in now['players']]
    assert now['players'][1]['cmd'] == before['players'][1]['cmd']

@check('20 nova partida pede confirmação em dois toques')
def _(t):
    t.fresh(); t.open_hub(); t.click('[data-act=newgame]')
    assert t.p('p1')['life'] == 34 and 'is-armed' in t.page.locator('[data-act=newgame]').get_attribute('class')
    assert 'DE NOVO' in t.page.locator('[data-act=newgame]').inner_text().upper()
    t.click('[data-act=newgame]'); assert t.view()['hubOpen'] is False and all(p['life'] == 40 for p in t.st()['players'])
    assert t.st()['starter'] is None

@check('21 estado sobrevive a recarregar; registro estragado não quebra a página')
def _(t):
    t.fresh(); t.tap(*t.half('p1', +1)); want = t.p('p1')['life']
    t.page.reload(); t.page.wait_for_function('window.__mesa'); assert t.p('p1')['life'] == want
    for bad in ('{"v":3,"players":"x"}', 'not json', '{"v":3,"players":[{},{}],"startLife":"abc"}', '{"v":3,"players":[1,2,3,4,5,6,7]}',
                '{"v":3,"startLife":40,"winnerId":"p9","turn":"p9","players":[{"winMsg":"<b>y</b>","loseMsg":{"a":1}},{"winMsg":123},{}]}',
                '{"v":3,"startLife":40,"players":[{"name":"<b>x</b>","life":"9e99","cmd":{"p2":"zz","p9":5},"color":"nope"},{"monarch":true},{"monarch":true}]}'):
        t.page.evaluate('v => localStorage.setItem("brewtact.mesa.prototipo.v3", v)', bad); t.page.reload()
        t.page.wait_for_function('window.__mesa && __mesa.state().players.length >= 2')
        assert t.page.locator('.panel').count() == len(t.st()['players'])
    assert t.page.evaluate('__mesa.winner()') is None                     # vencedor de um assento que não existe é descartado
    s = t.st(); assert s['players'][0]['life'] == 9999 and s['players'][0]['cmd'] == {} and s['players'][0]['color'] == 'brasa'
    assert [x['monarch'] for x in s['players']] == [False, True, False]
    assert t.page.locator('.panel[data-id=p1] .name b').inner_text() == '<b>x</b>'

# ─────────────────────────── keyboard & accessibility ───────────────────────────
@check('22 teclado: Enter nos lados do painel, Esc fecha a folha, Tab fica preso na folha, mesa inerte atrás')
def _(t):
    t.fresh(); a = t.p('p1')['life']
    t.page.locator('.panel[data-id=p1] .half.plus').focus(); t.page.keyboard.press('Enter'); t.page.keyboard.press('Enter')
    assert t.p('p1')['life'] == a + 2
    t.page.locator('.panel[data-id=p1] .more').focus(); t.page.keyboard.press('Enter'); assert t.view()['sheet'] == 'player'
    assert t.page.evaluate('document.getElementById("table").hasAttribute("inert")')
    for _i in range(30):
        t.page.keyboard.press('Tab')
        assert t.page.evaluate('document.getElementById("sheet").contains(document.activeElement)'), 'focus left the sheet'
    t.page.keyboard.press('Escape'); assert t.view()['sheet'] is None
    assert t.page.evaluate('document.activeElement && document.activeElement.classList.contains("more")')
    assert not t.page.evaluate('document.getElementById("table").hasAttribute("inert")')

@check('23 rótulos para leitor de tela e alvos de toque de pelo menos 40 px')
def _(t):
    t.fresh()
    assert 'Rafa, 34 de vida' in t.page.locator('.panel[data-id=p1] .half.plus').get_attribute('aria-label')
    unnamed = t.page.evaluate('[...document.querySelectorAll("button")].filter(b => b.offsetParent && !(b.getAttribute("aria-label")||b.textContent.trim())).length')
    assert unnamed == 0, unnamed
    t.set_page('p1', 'counters'); t.click('#btnHub')
    small = t.page.evaluate('''[...document.querySelectorAll("button")].filter(b => b.offsetParent).map(b => { const r = b.getBoundingClientRect(); return [b.className || b.id, Math.round(r.width), Math.round(r.height)]; }).filter(x => x[1] < 40 || x[2] < 40)''')
    assert small == [], small

# ─────────────────────────── findings from the code review ───────────────────────────
@check('28 botões pequenos respondem ao toque mesmo com o dedo de outra pessoa apoiado na mesa')
def _(t):
    t.fresh(); t.set_page('p2', 'counters'); x1, y1 = t.half('p1', +1)
    t._touch('touchStart', [(1, x1, y1)]); time.sleep(.05)
    bx, by = t.centre('.panel[data-id=p2] .cadd')
    t._touch('touchStart', [(1, x1, y1), (2, bx, by)]); time.sleep(.04); t._touch('touchEnd', [(2, bx, by)]); time.sleep(.05)
    assert t.view()['sheet'] == 'counters', t.view()
    t.click('[data-act=close]')
    px, py = t.centre('.panel[data-id=p2] .pm[data-c=poison][data-d="1"]')
    for _i in range(2):
        t._touch('touchStart', [(1, x1, y1), (2, px, py)]); time.sleep(.04); t._touch('touchEnd', [(2, px, py)]); time.sleep(.05)
    t._touch('touchEnd', []); assert t.p('p2')['c']['poison'] == 2, t.p('p2')['c']
    hx, hy = t.centre('#btnHub'); t.tap(hx, hy); assert t.view()['hubOpen']        # and plain single-finger taps on buttons fire once
    assert t.view()['sheet'] is None, 'the hub must have fired once, not twice'
    n = t.view()['undo']; ux, uy = t.centre('#btnUndo'); t.tap(ux, uy); assert t.view()['undo'] == n - 1, 'a single touch tap on Undo = exactly one undo'

@check('29 desfazer volta só a partida: nome, cor e regra da mesa ficam como estão')
def _(t):
    t.fresh(); a = t.p('p1')['life']; t.tap(*t.half('p1', +1))
    t.click('.panel[data-id=p1] .more'); t.page.fill('#pName', 'Rafael'); t.click('[data-act=color][data-c=ameixa]'); t.click('[data-act=close]')
    t.open_rules(); t.click('[data-act=cmdlife]'); t.click('[data-act=close]')
    t.open_hub(); t.click('#btnUndo'); p = t.p('p1')
    assert (p['life'], p['name'], p['color'], t.st()['cmdHurtsLife']) == (a, 'Rafael', 'ameixa', False), p

@check('30 corrigir dano de comandante devolve exatamente a vida que foi tirada, mesmo se a regra mudou no meio')
def _(t):
    def rule(): t.open_rules(); t.click('[data-act=cmdlife]'); t.click('[data-act=close]')
    t.fresh(); a = t.p('p1')['life']; t.swipe_panel('p1', 'right')
    t.hold(*t.half('p2', +1), ms=600); assert t.p('p1')['life'] == a - 5 and t.p('p1')['cmd']['p2'] == 5
    t.click('.panel[data-id=p1] [data-done]'); rule(); t.swipe_panel('p1', 'right')          # rule off
    t.hold(*t.half('p2', -1), ms=600); assert t.p('p1')['cmd'] == {} and t.p('p1')['life'] == a, t.p('p1')
    t.hold(*t.half('p3', +1), ms=600); assert t.p('p1')['life'] == a                         # rule off: no life taken
    t.click('.panel[data-id=p1] [data-done]'); rule(); t.swipe_panel('p1', 'right')          # rule on again
    t.hold(*t.half('p3', -1), ms=600); assert t.p('p1')['life'] == a, 'nothing was taken, nothing comes back: %s' % t.p('p1')['life']

@check('31 todos fora = empate; quem sai perde a coroa e não pode recebê-la')
def _(t):
    t.fresh(); assert t.p('p2')['monarch']
    for pid in ('p1', 'p2', 'p3', 'p4'):
        t.click('.panel[data-id=%s] .more' % pid); t.click('[data-act=concede]'); t.click('[data-act=close]')
        if pid == 'p2': assert t.p('p2')['monarch'] is False
    assert t.page.evaluate('__mesa.winner()') is None and 'empate' in t.page.locator('#winnerText').inner_text().lower()
    t.click('.panel[data-id=p1] .more'); assert t.page.locator('[data-act=monarch]').is_visible(); t.click('[data-act=close]')
    t.shot('31-empate'); t.click('#winner [data-open=summary]'); assert t.page.locator('#sheetTitle').inner_text() == 'Empate'

@check('32 trocar jogadores ou vida inicial com partida em andamento pede um segundo toque; em partida nova, não')
def _(t):
    t.fresh(); t.open_mesa(); t.click('[data-act=count][data-v="6"]')
    armed = t.page.locator('[data-act=count][data-v="6"]')
    assert len(t.st()['players']) == 4 and 'is-armed' in (armed.get_attribute('class') or '')
    assert 'confirmar' in (armed.get_attribute('aria-label') or '')
    assert armed.inner_text().strip() == '6', 'o número não pode esticar e empurrar os vizinhos'
    t.shot('32-confirmar-troca'); t.click('[data-act=count][data-v="6"]'); assert len(t.st()['players']) == 6
    t.click('[data-act=count][data-v="3"]'); assert len(t.st()['players']) == 3, 'a game nobody touched needs no confirmation'
    t.click('[data-act=start][data-v="30"]'); assert t.st()['startLife'] == 30

@check('33 segurar para de repetir se a mesa muda de modo debaixo do dedo')
def _(t):
    t.fresh(); a = t.p('p2')['life']; x, y = t.half('p2', +1)
    t._touch('touchStart', [(1, x, y)]); time.sleep(.6)                       # one +10 has fired
    cx, cy = t.centre('.panel[data-id=p1]')
    for i, fx in enumerate([cx - 45, cx - 20, cx + 10, cx + 45]):             # a second finger drags p1 into damage mode
        t._touch('touchStart' if i == 0 else 'touchMove', [(1, x, y), (2, fx, cy)]); time.sleep(.02)
    t._touch('touchEnd', [(2, cx + 45, cy)])
    assert t.view()['cmdFor'] == 'p1', t.view(); time.sleep(1.0); t._touch('touchEnd', [])
    assert t.p('p2')['life'] == a + 10 and t.p('p1')['cmd'] == {}, (t.p('p2')['life'], t.p('p1')['cmd'])

# ─────────────────────────── wave: what the Lotus study asked for ───────────────────────────
@check('34 tocar no número abre o teclado e define o total exato')
def _(t):
    t.fresh()
    t.click('.panel[data-id=p1] .setlife'); assert t.view()['sheet'] == 'pad'
    t.click('[data-act=digit][data-n="2"]'); t.click('[data-act=digit][data-n="7"]')
    assert t.page.locator('.padout output').inner_text() == '27'
    t.click('[data-act=back]'); t.click('[data-act=digit][data-n="9"]')
    t.shot('34-teclado-de-vida')
    # on a phone lying sideways the sheet only has the screen's short side: the main action must be
    # reachable without scrolling, in both ways of holding the phone
    for vp, ins in ((LAND, INSETS_LAND), (PORT, INSETS_PORT)):
        t.page.set_viewport_size(vp)
        t.page.evaluate('([l,tp,r,b]) => __setInsets(l,tp,r,b)', list(ins))
        box = t.box('[data-act=padapply]'); rot = t.box('.rot')
        assert box['y'] >= rot['y'] - 1 and box['y'] + box['height'] <= rot['y'] + rot['height'] + 1, \
            'Aplicar fora da folha em %dx%d: %s dentro de %s' % (vp['width'], vp['height'], box, rot)
        over = t.page.evaluate('''() => { const b = document.querySelector('.padbody'); return b.scrollHeight - b.clientHeight; }''')
        assert over <= 1, 'teclado precisa de rolagem em %dx%d (sobram %dpx)' % (vp['width'], vp['height'], over)
    t.page.set_viewport_size(LAND); t.page.evaluate('([l,tp,r,b]) => __setInsets(l,tp,r,b)', list(INSETS_LAND))
    t.click('[data-act=padapply]')
    assert t.view()['sheet'] is None and t.p('p1')['life'] == 29, t.p('p1')['life']
    n = t.view()['undo']; t.open_hub(); t.click('#btnUndo')
    assert t.p('p1')['life'] == 34 and t.view()['undo'] == n - 1
    # and the setting turns the whole thing off
    t.open_rules(); t.click('[data-act=tapnumber]'); t.click('[data-act=close]')
    assert t.page.locator('.panel[data-id=p1] .setlife').is_disabled()

@check('35 catálogo de marcadores: escolher, aparecer no painel e sair ao zerar')
def _(t):
    t.fresh(); assert len(t.page.evaluate('__mesa.counters()')) == 21          # entrou Recompensa (onda 7)
    t.set_page('p2', 'counters')
    assert t.page.locator('.panel[data-id=p2] .crow[data-row]').count() == 4
    t.click('.panel[data-id=p2] .cadd'); assert t.view()['sheet'] == 'counters'
    assert t.page.locator('[data-act=toggle-counter][data-c=poison]').is_disabled(), 'os quatro fixos não saem'
    for cid in ('treasure', 'clue', 'manaR'): t.click('[data-act=toggle-counter][data-c=%s]' % cid)
    t.shot('35-catalogo-de-marcadores'); t.click('[data-act=close]')
    assert t.page.locator('.panel[data-id=p2] .crow[data-row]').count() == 7
    t.click('.panel[data-id=p2] .pm[data-c=treasure][data-d="1"]')
    t.click('.panel[data-id=p2] .pm[data-c=manaR][data-d="1"]')
    assert t.p('p2')['c']['treasure'] == 1 and t.p('p2')['c']['manaR'] == 1
    t.click('.panel[data-id=p2] .cback')            # the way home lives on the page itself
    assert (t.view()['page'].get('p2') or 'life') == 'life'
    assert t.page.locator('.panel[data-id=p2] .chip').count() >= 3
    t.shot('35-marcadores-no-painel')

@check('36 eliminado ocupa o painel e volta com um toque')
def _(t):
    t.fresh()
    t.click('.panel[data-id=p1] .setlife'); t.click('[data-act=digit][data-n="0"]'); t.click('[data-act=padapply]')
    assert t.out('p1') == 'Sem vida'
    el = '.panel[data-id=p1] '
    assert t.page.locator(el + '.outlabel').inner_text().upper() == 'ELIMINADO'
    assert float(t.page.evaluate('getComputedStyle(document.querySelector("%s.outlabel")).fontSize' % el).replace('px', '')) >= 20
    t.shot('36-eliminado')
    t.click(el + '.revive'); assert t.view()['sheet'] == 'revive'
    t.click('[data-act=revive]')
    assert t.out('p1') == '' and t.p('p1')['life'] == 1

@check('37 dados d4 a d20, moeda e high roll de quem começa')
def _(t):
    t.fresh(); t.open_hub(); t.click('[data-open=dice]')
    for n in (4, 6, 8, 10, 12, 20, 2):
        t.click('[data-act=roll][data-sides="%d"]' % n)
        v = t.st()['rolls'][0]
        assert v['kind'] == ('Moeda' if n == 2 else 'd%d' % n), v
        if n != 2: assert 1 <= int(v['value']) <= n, v
    t.click('[data-act=highroll]')
    hr = t.st()['highroll']
    assert len(hr) == 4 and sum(1 for r in hr if r.get('win')) == 1
    assert t.st()['starter'] == next(r['id'] for r in hr if r.get('win'))
    assert hr[0]['value'] >= hr[-1]['value']
    t.shot('37-dados-e-high-roll'); t.click('[data-act=close]')

@check('38 mesa com 1 jogador e com 10; vida inicial digitada')
def _(t):
    t.fresh(players=1)
    assert t.page.locator('.panel').count() == 1 and t.page.evaluate('document.getElementById("rowTop").hidden')
    assert t.page.evaluate('__mesa.winner()') is None, 'solo não tem vencedor'
    t.tap(*t.half('p1', -1)); assert t.p('p1')['life'] == 39
    t.shot('38-um-jogador')
    t.fresh(players=10); assert t.page.locator('.panel').count() == 10
    t.shot('38-dez-jogadores')
    t.open_mesa(); t.click('[data-act=startother]')
    assert t.view()['sheet'] == 'startpad'
    t.click('[data-act=sdigit][data-n="6"]'); t.click('[data-act=sdigit][data-n="0"]'); t.click('[data-act=sapply]')
    assert t.st()['startLife'] == 60 and all(p['life'] == 60 for p in t.st()['players'])
    t.click('[data-act=close]')

@check('39 passo do toque longo é configurável')
def _(t):
    t.fresh(); t.open_rules(); t.click('[data-act=hold][data-v="20"]'); t.click('[data-act=close]')
    a = t.p('p1')['life']; t.hold(*t.half('p1', -1), ms=600)
    assert t.p('p1')['life'] == a - 20, t.p('p1')['life']
    assert '20' in t.page.locator('.panel[data-id=p1] .half.minus').get_attribute('aria-label')

@check('40 o hub muda de marca quando a mesa está em modo dano')
def _(t):
    t.fresh(); assert 'mode' not in (t.page.locator('#hubwrap').get_attribute('class') or '')
    t.swipe_panel('p1', 'right')
    assert 'mode' in t.page.locator('#hubwrap').get_attribute('class')
    assert t.page.locator('#btnHub .swords').is_visible()
    t.click('.panel[data-id=p1] [data-done]')
    assert 'mode' not in t.page.locator('#hubwrap').get_attribute('class')

@check('41 o numeral fica no centro do card de cada jogador, não no centro da tela')
def _(t):
    bad = []
    for vp, ins, tag in ((LAND, INSETS_LAND, 'paisagem'), (PORT, INSETS_PORT, 'retrato')):
        t.page.set_viewport_size(vp)
        for n in (2, 3, 4, 5, 6):
            t.fresh(players=n, insets=ins)
            rows = t.page.evaluate(CENTRE_JS)
            for r in rows:
                if abs(r['dx']) > 1 or abs(r['dy']) > 1:
                    bad.append('%s %dj %s fora do centro: x %+.1f y %+.1f' % (tag, n, r['id'], r['dx'], r['dy']))
            sizes = {}
            for r in rows: sizes.setdefault((r['w'], r['h']), set()).add(round(r['font']))
            for box, fonts in sizes.items():
                if len(fonts) > 1:
                    bad.append('%s %dj: cards %dx%d com numerais de tamanhos diferentes %s' % (tag, n, box[0], box[1], sorted(fonts)))
                share = .72 * max(fonts) / box[1]
                if share < .38:
                    bad.append('%s %dj: numeral pequeno demais (%.0f%% da altura do card)' % (tag, n, 100 * share))
    t.page.set_viewport_size(LAND); t.fresh()
    assert not bad, '; '.join(bad[:8])

@check('42 arrastar devagar vira a página; não pode virar "segurar" e somar vida')
def _(t):
    t.fresh()
    life = t.p('p1')['life']
    x, y = t.centre('.panel[data-id=p1]')
    t._touch('touchStart', [(1, x - 60, y)])
    for i in range(1, 13):                                   # 12 moves × 70 ms = 840 ms, bem mais que o toque longo
        t._touch('touchMove', [(1, x - 60 + i * 10, y)]); time.sleep(.07)
    t._touch('touchEnd', [])
    assert t.view()['cmdFor'] == 'p1', t.view()
    assert t.p('p1')['life'] == life, 'o arrasto mexeu na vida: %s -> %s' % (life, t.p('p1')['life'])
    t.click('.panel[data-id=p1] [data-done]')
    # e o arrasto para o outro lado, também devagar, abre os marcadores
    t._touch('touchStart', [(1, x + 60, y)])
    for i in range(1, 13):
        t._touch('touchMove', [(1, x + 60 - i * 10, y)]); time.sleep(.07)
    t._touch('touchEnd', [])
    assert t.view()['page']['p1'] == 'counters', t.view()
    assert t.p('p1')['life'] == life
    t.shot('42-arrasto-lento')

CENTRE_JS = """() => [...document.querySelectorAll('.panel')].map(pn => {
  const c = pn.getBoundingClientRect(), n = pn.querySelector('.life').getBoundingClientRect();
  return { id: pn.dataset.id, dx: n.x + n.width / 2 - (c.x + c.width / 2), dy: n.y + n.height / 2 - (c.y + c.height / 2),
           font: parseFloat(getComputedStyle(pn.querySelector('.life')).fontSize),
           w: pn.offsetWidth, h: pn.offsetHeight };
})"""

HUB_JS = """() => { const h = document.querySelector('#btnHub').getBoundingClientRect(), t = document.querySelector('#table').getBoundingClientRect();
  return { cx: h.x + h.width / 2, cy: h.y + h.height / 2, tx: t.x + t.width / 2, ty: t.y + t.height / 2 }; }"""
SMALL_JS = """() => [...document.querySelectorAll('button')].filter(b => b.offsetParent)
  .map(b => { const r = b.getBoundingClientRect(); return [b.className || b.id, Math.round(r.width), Math.round(r.height)]; })
  .filter(x => x[1] < 40 || x[2] < 40)"""
DOTS_JS = """() => [...document.querySelectorAll('.panel')].map(p => { const pr = p.getBoundingClientRect(), d = p.querySelector('.dots').getBoundingClientRect();
  return { id: p.dataset.id, folga: Math.round(Math.min(d.left - pr.left, pr.right - d.right, d.top - pr.top, pr.bottom - d.bottom)) }; })"""

@check('43 mesa cheia e trilho aberto: hub fixo na costura, nada abaixo de 40 px, pontinhos dentro do card')
def _(t):
    bad = []
    def hub_e_alvos(tag, n, trilho):
        h = t.page.evaluate(HUB_JS)
        # o hub marca a costura da mesa; as folgas --hl/--hr dos painéis são calculadas a partir dela
        if abs(h['cx'] - h['tx']) > 1 or abs(h['cy'] - h['ty']) > 1:
            bad.append('%s %dj trilho %s: hub fora da costura (%+.0f, %+.0f)' % (tag, n, trilho, h['cx'] - h['tx'], h['cy'] - h['ty']))
        small = t.page.evaluate(SMALL_JS)
        if small: bad.append('%s %dj trilho %s: botão menor que 40px %s' % (tag, n, trilho, small[:3]))
    for vp, ins, tag in ((LAND, INSETS_LAND, 'paisagem'), (PORT, INSETS_PORT, 'retrato')):
        t.page.set_viewport_size(vp)
        for n in (2, 5, 7, 10):
            t.fresh(players=n, insets=ins)
            hub_e_alvos(tag, n, 'fechado')
            meio = t.st()['players'][n // 2]['id']              # o painel que encosta no hub em fileira ímpar
            t.set_page(meio, 'counters')
            small = t.page.evaluate(SMALL_JS)
            if small: bad.append('%s %dj marcadores: botão menor que 40px %s' % (tag, n, small[:3]))
            t.click('.panel[data-id=%s] .cback' % meio)
            fora = [d for d in t.page.evaluate(DOTS_JS) if d['folga'] < 0]
            if fora: bad.append('%s %dj: pontinhos fora do card %s' % (tag, n, fora[:3]))
            t.open_hub()                                        # por último: o próximo fresh() recarrega e fecha o trilho
            hub_e_alvos(tag, n, 'aberto')
            if n == 10 and tag == 'paisagem': t.shot('43-dez-jogadores-trilho-aberto')
    t.page.set_viewport_size(LAND); t.fresh()
    assert not bad, '; '.join(bad[:8])

@check('44 faixa de vencedor: alvo de 40 px e sem cobrir o numeral de ninguém')
def _(t):
    t.fresh()
    for pid in ('p2', 'p3', 'p4'):
        t.click('.panel[data-id=%s] .setlife' % pid)
        t.click('[data-act=digit][data-n="0"]'); t.click('[data-act=padapply]')
    assert t.page.evaluate('__mesa.winner()') == 'p1', t.page.evaluate('__mesa.winner()')
    box = t.page.locator('#winner')
    assert box.is_visible()
    b = t.box('#winner button')
    assert b['width'] >= 40 and b['height'] >= 40, b
    choque = t.page.evaluate("""() => { const w = document.querySelector('#winner').getBoundingClientRect();
      return [...document.querySelectorAll('.panel')].filter(p => { const l = p.querySelector('.life');
        if (!l || l.offsetParent === null) return false; const r = l.getBoundingClientRect();
        return w.left < r.right - 1 && r.left < w.right - 1 && w.top < r.bottom - 1 && r.top < w.bottom - 1; }).map(p => p.dataset.id); }""")
    assert choque == [], 'a faixa de vencedor cobre o numeral de %s' % choque
    t.shot('44-faixa-de-vencedor')

@check('45 passar a vez anda pelos assentos, volta atrás e pula quem está fora')
def _(t):
    t.fresh()
    assert t.page.evaluate('__mesa.times()')['turn'] is None, 'mesa nova começa sem turno'
    t.open_hub(); t.click('#btnTurn')
    tm = t.page.evaluate('__mesa.times()')
    assert tm['turn'] == t.st()['starter'] and tm['turnNo'] == 1, tm      # começa em quem a mesa sorteou
    ordem = [p['id'] for p in t.st()['players']]
    inicio = ordem.index(tm['turn'])
    for k in (1, 2):
        t.click('#btnTurn')
        tm = t.page.evaluate('__mesa.times()')
        assert tm['turn'] == ordem[(inicio + k) % len(ordem)] and tm['turnNo'] == 1 + k, tm
    for _i in range(2): t.click('#btnTurn')                                # fecha a volta: rodada 2
    tm = t.page.evaluate('__mesa.times()')
    assert tm['turnNo'] == 5 and tm['round'] == 2, tm
    # quem concede deixa de receber a vez
    fora = ordem[(inicio + 1) % len(ordem)]
    t.close_hub()
    t.click('.panel[data-id=%s] .more' % fora); t.click('[data-act=concede]'); t.click('[data-act=close]')
    t.page.evaluate('id => { for (var i = 0; i < 20 && __mesa.times().turn !== id; i++) document.getElementById("btnTurn").click(); }', ordem[inicio])
    t.open_hub(); t.click('#btnTurn')
    assert t.page.evaluate('__mesa.times()')['turn'] != fora, 'a vez não pode parar em quem está fora'
    t.open_turns(); t.shot('45-folha-turnos'); t.click('[data-act=close]')

@check('46 o relógio corre só para quem está na vez, e pausar congela a mesa inteira')
def _(t):
    t.fresh(); t.open_hub(); t.click('#btnTurn')
    vez = t.page.evaluate('__mesa.times()')['turn']
    t.page.wait_for_timeout(1200)
    tm = t.page.evaluate('__mesa.times()')
    assert tm[vez] > 900, tm
    assert all(tm[p['id']] == 0 for p in t.st()['players'] if p['id'] != vez), tm
    assert tm['total'] >= tm[vez] - 50, tm
    t.open_turns(); t.click('[data-act=pause]')
    assert t.page.evaluate('__mesa.times()')['paused'] is True
    a = t.page.evaluate('__mesa.times()'); t.page.wait_for_timeout(900)
    b = t.page.evaluate('__mesa.times()')
    assert b[vez] - a[vez] < 120 and b['total'] - a['total'] < 120, (a, b)
    t.shot('46-pausado')
    t.click('[data-act=pause]'); t.page.wait_for_timeout(700)
    c = t.page.evaluate('__mesa.times()')
    assert c[vez] - b[vez] > 400, (b, c)
    t.click('[data-act=close]')

@check('47 a vez sobrevive a recarregar; desfazer devolve a vez sem rebobinar o relógio')
def _(t):
    t.fresh(); t.open_hub(); t.click('#btnTurn'); t.click('#btnTurn')
    antes = t.page.evaluate('__mesa.times()')
    t.page.reload(); t.page.wait_for_function('window.__mesa && __mesa.state().players.length > 0')
    t.page.evaluate('([l,tp,r,b]) => __setInsets(l,tp,r,b)', list(INSETS_LAND))
    depois = t.page.evaluate('__mesa.times()')
    assert depois['turn'] == antes['turn'] and depois['turnNo'] == antes['turnNo'], (antes, depois)
    assert depois[antes['turn']] >= antes[antes['turn']] - 50, 'o tempo de quem estava na vez não pode sumir'
    t.open_hub(); t.click('#btnTurn')
    tempo_antes_do_undo = t.page.evaluate('__mesa.times()')['total']
    vez_antes = t.page.evaluate('__mesa.times()')['turn']
    t.open_hub(); t.click('#btnUndo')
    tm = t.page.evaluate('__mesa.times()')
    assert tm['turn'] == depois['turn'] and tm['turn'] != vez_antes, tm      # a vez volta
    assert tm['total'] >= tempo_antes_do_undo - 50, 'desfazer não rebobina o relógio'

@check('48 quem sai passa a vez sozinho, e sortear quem começa abre o turno 1')
def _(t):
    t.fresh(); t.open_hub(); t.click('#btnTurn'); t.close_hub()
    vez = t.page.evaluate('__mesa.times()')['turn']
    t.click('.panel[data-id=%s] .setlife' % vez)
    t.click('[data-act=digit][data-n="0"]'); t.click('[data-act=padapply]')
    tm = t.page.evaluate('__mesa.times()')
    assert t.out(vez) == 'Sem vida' and tm['turn'] != vez, tm
    t.open_hub(); t.click('#btnStarter')
    t.page.wait_for_timeout(1900)
    tm = t.page.evaluate('__mesa.times()')
    assert tm['turn'] == t.st()['starter'] and tm['turnNo'] == 1, (tm, t.st()['starter'])
    t.shot('48-vez-do-sorteado')

@check('49 o anel da vez não ocupa espaço: régua limpa e numeral no lugar')
def _(t):
    bad = []
    for vp, ins, tag in ((LAND, INSETS_LAND, 'paisagem'), (PORT, INSETS_PORT, 'retrato')):
        t.page.set_viewport_size(vp)
        for n in (2, 4, 6):
            t.fresh(players=n, insets=ins)
            antes = t.page.evaluate(CENTRE_JS)
            t.open_hub(); t.click('#btnTurn')
            if t.view()['hubOpen']: t.click('#btnHub')
            assert t.page.evaluate("() => document.querySelectorAll('.panel.is-turn').length") == 1, 'o anel marca um card só'
            bad += ['%s %dj: %s' % (tag, n, x) for x in t.page.evaluate(LAYOUT_JS)]
            depois = t.page.evaluate(CENTRE_JS)
            for a, d in zip(antes, depois):
                if abs(a['dx'] - d['dx']) > 1 or abs(a['dy'] - d['dy']) > 1:
                    bad.append('%s %dj %s: o anel moveu o numeral' % (tag, n, d['id']))
            if n == 4 and tag == 'paisagem': t.shot('49-anel-da-vez')
    t.page.set_viewport_size(LAND); t.fresh()
    assert not bad, '; '.join(bad[:8])

LINHAS_JS = """(sel) => { const e = document.querySelector(sel); if (!e) return -1;
  const cs = getComputedStyle(e); const lh = parseFloat(cs.lineHeight) || parseFloat(cs.fontSize);
  return Math.round(e.clientHeight / lh); }"""     # valores de layout: em retrato o rect vem girado

@check('50 frase de derrota ocupa o lugar de "Eliminado", volta ao padrão e não estoura o card')
def _(t):
    t.fresh()
    t.click('.panel[data-id=p1] .more'); t.page.fill('#pLose', 'Morri feliz'); t.click('[data-act=close]')
    assert t.p('p1')['loseMsg'] == 'Morri feliz'
    t.click('.panel[data-id=p1] .setlife'); t.click('[data-act=digit][data-n="0"]'); t.click('[data-act=padapply]')
    assert t.page.locator('.panel[data-id=p1] .outlabel').inner_text().upper() == 'MORRI FELIZ'
    assert t.page.locator('.panel[data-id=p1] .outwhy').inner_text().upper() == 'SEM VIDA', 'o motivo não some'
    t.shot('50-frase-de-derrota')
    # a frase mais longa possível continua em duas linhas, em card de 4 e de 6
    for n in (4, 6):
        if n != 4:
            t.open_mesa(); t.choose('count', n); t.click('[data-act=close]')
            t.click('.panel[data-id=p1] .more'); t.page.fill('#pLose', 'x' * 28); t.click('[data-act=close]')
            t.click('.panel[data-id=p1] .setlife'); t.click('[data-act=digit][data-n="0"]'); t.click('[data-act=padapply]')
        else:
            t.click('.panel[data-id=p1] .more'); t.page.fill('#pLose', 'Chorei, mas valeu a pena'); t.click('[data-act=close]')
        linhas = t.page.evaluate(LINHAS_JS, '.panel[data-id=p1] .outlabel')
        assert 0 < linhas <= 2, '%dj: frase em %d linhas' % (n, linhas)
        assert t.page.evaluate(LAYOUT_JS) == [], '%dj: %s' % (n, t.page.evaluate(LAYOUT_JS)[:3])
    t.fresh()
    t.click('.panel[data-id=p1] .more'); t.page.fill('#pLose', ''); t.click('[data-act=close]')
    t.click('.panel[data-id=p1] .setlife'); t.click('[data-act=digit][data-n="0"]'); t.click('[data-act=padapply]')
    assert t.page.locator('.panel[data-id=p1] .outlabel').inner_text().upper() == 'ELIMINADO'

@check('51 frase de vitória aparece no resumo e no aviso da mesa')
def _(t):
    t.fresh()
    t.click('.panel[data-id=p1] .more'); t.page.fill('#pWin', 'Eu avisei'); t.click('[data-act=close]')
    for pid in ('p2', 'p3', 'p4'):
        t.click('.panel[data-id=%s] .more' % pid); t.click('[data-act=concede]'); t.click('[data-act=close]')
    assert t.page.evaluate('__mesa.winner()') == 'p1'
    assert 'Rafa venceu' in t.page.locator('#winnerText').inner_text()
    t.click('#winner [data-open=summary]')
    assert 'Eu avisei' in t.page.locator('#sheetTitle').inner_text()
    assert 'Eu avisei' in t.page.locator('.rs .rs-p').first.inner_text()
    t.shot('51-resumo-com-frase'); t.click('[data-act=close]')

@check('52 frases: limite, normalização e nada de HTML')
def _(t):
    t.fresh(); t.click('.panel[data-id=p1] .more')
    t.page.fill('#pLose', '<img src=x onerror=window.__xss2=1>')
    t.click('[data-act=concede]')
    assert t.page.locator('.panel img').count() == 0 and t.page.evaluate('window.__xss2') is None
    assert t.page.locator('.panel[data-id=p1] .outlabel').inner_text().startswith('<img')
    t.click('[data-act=close]')
    t.click('.panel[data-id=p1] .more')
    assert t.page.input_value('#pLose').startswith('<img'), 'o campo devolve o texto cru'
    # fill respeita maxlength, então o excesso entra por evento
    t.page.evaluate("""() => { const i = document.querySelector('#pWin');
      i.value = 'y'.repeat(80); i.dispatchEvent(new Event('input', { bubbles: true })); }""")
    assert len(t.p('p1')['winMsg']) == 28, len(t.p('p1')['winMsg'])
    t.page.evaluate("""() => { const i = document.querySelector('#pWin');
      i.value = '  a\t  b  '; i.dispatchEvent(new Event('input', { bubbles: true })); }""")
    assert t.p('p1')['winMsg'] == 'a b ', repr(t.p('p1')['winMsg'])
    t.click('[data-act=close]')

@check('53 a mesa pode nomear o vencedor, e a pílula não invade uma mesa viva')
def _(t):
    t.fresh()
    t.click('.panel[data-id=p3] .more'); t.click('[data-act=winner]'); t.click('[data-act=close]')
    assert t.page.evaluate('__mesa.winner()') == 'p3'
    assert t.page.locator('.panel[data-id=p3] .starts').inner_text().upper() == 'VENCEU'
    assert not t.page.locator('#winner').is_visible(), 'com quatro vivos a pílula cobriria o numeral de dois cards'
    assert t.page.evaluate(LAYOUT_JS) == [], t.page.evaluate(LAYOUT_JS)[:3]
    t.shot('53-vencedor-a-mao')
    t.open_hub(); t.click('#menu [data-open=summary]')
    assert 'Léo' in t.page.locator('#sheetTitle').inner_text()
    assert 'VENCEU' in t.page.locator('.rs .rs-p').first.inner_text().upper()
    t.click('[data-act=close]')
    t.click('.panel[data-id=p3] .more'); t.click('[data-act=winner]'); t.click('[data-act=close]')
    assert t.page.evaluate('__mesa.winner()') is None
    assert t.page.locator('.panel[data-id=p3] .starts').inner_text().upper() != 'VENCEU'

@check('54 desfazer não apaga a frase, e nova partida a mantém')
def _(t):
    t.fresh()
    t.tap(*t.half('p1', -1))                                        # a jogada vem ANTES da frase
    t.click('.panel[data-id=p1] .more')
    t.page.fill('#pLose', 'Morri feliz'); t.page.fill('#pWin', 'Eu avisei')
    t.click('[data-act=close]')
    vida = t.p('p1')['life']
    t.open_hub(); t.click('#btnUndo')
    assert t.p('p1')['life'] == vida + 1 and t.p('p1')['loseMsg'] == 'Morri feliz', t.p('p1')
    t.open_mesa(); t.choose('count', 6); t.click('[data-act=close]')
    assert t.p('p1')['winMsg'] == 'Eu avisei' and t.p('p1')['loseMsg'] == 'Morri feliz'

@check('55 folha aberta com o dedo não se fecha sozinha, em nenhum assento da mesa')
def _(t):
    # o clique tardio que o navegador manda depois do toque não pode cair no scrim e fechar o que abriu
    for n in (2, 4, 6):
        t.fresh(players=n)
        for p in t.st()['players']:
            t.tap(*t.centre('.panel[data-id=%s] .setlife' % p['id']))
            assert t.view()['sheet'] == 'pad', '%dj: %s não abriu o teclado' % (n, p['id'])
            assert p['name'] in t.page.locator('#sheetTitle').inner_text()
            t.click('[data-act=close]')
            t.tap(*t.centre('.panel[data-id=%s] .more' % p['id']))
            assert t.view()['sheet'] == 'player', '%dj: %s não abriu a folha do jogador' % (n, p['id'])
            t.click('[data-act=close]')
    t.fresh()

def encerra(t):
    """Três concedem, o resumo abre e a partida é guardada."""
    for pid in ('p2', 'p3', 'p4'):
        t.click('.panel[data-id=%s] .more' % pid); t.click('[data-act=concede]'); t.click('[data-act=close]')
    t.click('#winner [data-open=summary]'); assert t.view()['sheet'] == 'summary'
    t.click('[data-act=savepost]')

@check('56 partida encerrada vira recibo, sobrevive ao reload e não duplica')
def _(t):
    t.fresh(); t.page.evaluate('localStorage.removeItem("brewtact.mesa.hist.v1")')
    t.tap(*t.half('p1', +1))                                    # a mesa foi usada
    encerra(t)
    h = t.page.evaluate('__mesa.hist()')
    assert len(h) == 1 and h[0]['k'] == 'fim' and h[0]['p'][h[0]['wi']]['n'] == 'Rafa', h
    assert h[0]['t'] > 0 and h[0]['n'] == 40 and len(h[0]['p']) == 4, 'sem turnos, a duração é o tempo de mesa aberta'
    t.page.reload(); t.page.wait_for_function('window.__mesa')
    t.page.evaluate('([l,tp,r,b]) => __setInsets(l,tp,r,b)', list(INSETS_LAND))
    assert len(t.page.evaluate('__mesa.hist()')) == 1, 'o arquivo tem de sobreviver ao reload'
    # encerrar de novo e começar outra mesa continuam dando UM registro daquela partida
    t.open_hub(); t.click('#menu [data-open=summary]'); t.click('[data-act=savepost]')
    t.open_mesa(); t.choose('count', 6); t.click('[data-act=close]')
    h = t.page.evaluate('__mesa.hist()')
    assert len(h) == 1 and h[0]['k'] == 'fim', h                 # "encerrada" não vira "nova"
    t.shot('56-partida-guardada')

@check('57 lista de partidas: abre o resultado guardado e só apaga com dois toques')
def _(t):
    t.fresh(); t.page.evaluate('localStorage.removeItem("brewtact.mesa.hist.v1")')
    t.tap(*t.half('p1', +1)); encerra(t)
    t.open_hub(); t.click('#tileHistory')
    assert t.view()['sheet'] == 'history'
    assert t.page.locator('[data-act=hopen]').count() == 1
    s0 = t.page.evaluate('__mesa.hist()')[0]['s']
    t.click('[data-act=hopen]')
    assert t.view()['sheet'] == 'match'
    assert 'Rafa' in t.page.locator('#sheetTitle').inner_text()
    assert t.page.locator('.rs .rs-p').count() == 4
    t.shot('57-partida-no-arquivo')
    t.click('[data-act=hdel]')                                   # primeiro toque só arma
    assert len(t.page.evaluate('__mesa.hist()')) == 1
    t.click('[data-act=hdel][data-s="%s"]' % s0)
    assert t.page.evaluate('__mesa.hist()') == []
    assert t.view()['sheet'] == 'history'
    t.click('[data-act=menuback]'); t.close_hub()

@check('58 arquivo tem teto, e registro estragado não derruba a mesa')
def _(t):
    t.fresh()
    t.page.evaluate("""() => { const g = [];
      for (let i = 0; i < 60; i++) g.push({ s: 1700000000000 + i * 1000, e: 1700000000000 + i * 1000 + 60, n: 40, k: 'fim',
        wi: 0, wm: 0, d: 0, t: 60000, p: [{ n: 'A', c: 'brasa', l: 10, m: 0, v: 0, o: '', f: '', ms: 0 }, { n: 'B', c: 'mare', l: 0, m: 0, v: 0, o: 'Sem vida', f: '', ms: 0 }] });
      localStorage.setItem('brewtact.mesa.hist.v1', JSON.stringify({ hv: 1, g: g })); }""")
    t.page.reload(); t.page.wait_for_function('window.__mesa')
    assert len(t.page.evaluate('__mesa.hist()')) == 30, len(t.page.evaluate('__mesa.hist()'))
    for ruim in ('{"hv":1,"g":"x"}', 'nao json', '{"hv":2,"g":[]}',
                 '{"hv":1,"g":[{"s":0,"p":[]},{"s":1700000000000,"p":[{"n":123,"c":"nope","l":"x"}],"wi":9,"k":"zzz"}]}'):
        t.page.evaluate('v => localStorage.setItem("brewtact.mesa.hist.v1", v)', ruim)
        t.page.reload(); t.page.wait_for_function('window.__mesa && __mesa.state().players.length >= 2')
        h = t.page.evaluate('__mesa.hist()')
        assert isinstance(h, list), h
        assert t.page.locator('.panel').count() == len(t.st()['players'])
    h = t.page.evaluate('__mesa.hist()')
    assert len(h) == 1 and h[0]['p'][0]['n'] == 'Jogador' and h[0]['wi'] <= 0 and h[0]['k'] == 'nova', h
    t.page.evaluate('localStorage.removeItem("brewtact.mesa.hist.v1")')

@check('59 as folhas do arquivo cabem na mesa deitada e em pé')
def _(t):
    t.fresh(); t.page.evaluate('localStorage.removeItem("brewtact.mesa.hist.v1")')
    t.tap(*t.half('p1', +1)); encerra(t)
    bad = []
    for vp, ins, tag in ((LAND, INSETS_LAND, 'paisagem'), (PORT, INSETS_PORT, 'retrato')):
        t.page.set_viewport_size(vp)
        t.page.evaluate('([l,tp,r,b]) => __setInsets(l,tp,r,b)', list(ins))
        t.open_hub(); t.click('#tileHistory')
        for tela in ('history', 'match'):
            if tela == 'match': t.click('[data-act=hopen]')
            m = t.page.evaluate("""() => { const s = document.querySelector('.sheet'), b = s.querySelector('.sheet-body'), r = document.querySelector('.rot');
              const sr = s.getBoundingClientRect(), rr = r.getBoundingClientRect();
              return { fora: sr.left < rr.left - 1 || sr.right > rr.right + 1 || sr.bottom > rr.bottom + 1,
                       rolaX: b.scrollWidth - b.clientWidth, pequeno: [...s.querySelectorAll('button')].filter(x => x.offsetParent)
                         .map(x => x.getBoundingClientRect()).filter(x => x.width < 40 || x.height < 40).length }; }""")
            if m['fora']: bad.append('%s %s: folha fora da mesa' % (tag, tela))
            if m['rolaX'] > 1: bad.append('%s %s: rolagem horizontal de %dpx' % (tag, tela, m['rolaX']))
            if m['pequeno']: bad.append('%s %s: %d botão(ões) menor que 40px' % (tag, tela, m['pequeno']))
            if tela == 'match':
                vb, sb = t.box('[data-act=history]'), t.box('.sheet')
                if vb['y'] < sb['y'] - 1 or vb['y'] + vb['height'] > sb['y'] + sb['height'] + 1:
                    bad.append('%s partida guardada: a volta ficou fora da folha' % tag)
            if tag == 'paisagem': t.shot('59-folha-%s' % tela)
        t.click('[data-act=history]'); t.click('[data-act=menuback]'); t.close_hub()
    t.page.set_viewport_size(LAND); t.fresh()
    assert not bad, '; '.join(bad[:6])

def liga_parceiro(t, pid, kind=None):
    t.click('.panel[data-id=%s] .more' % pid)
    t.click('[data-act=partner]')
    if kind: t.click('[data-act=cmdkind][data-v=%s]' % kind)
    t.click('[data-act=close]')

def bate(t, sel, n):
    for _i in range(n): t.tap(*t.centre(sel))

LANE_A = '.panel[data-id=p2] .half.plus:not(.lane-b)'
LANE_B = '.panel[data-id=p2] .half.plus.lane-b'

@check('60 dois comandantes: 21 de um elimina, 20 de cada um não')
def _(t):
    t.fresh()
    t.open_rules(); t.click('[data-act=cmdlife]'); t.click('[data-act=close]')   # isola a regra do dano
    liga_parceiro(t, 'p2')
    assert t.page.evaluate('__mesa.duo("p2")') is True
    t.set_page('p1', 'cmd')
    assert t.page.locator('.panel[data-id=p2].is-duo').count() == 1, 'o card de entrada vira duas faixas'
    bate(t, LANE_A, 20); bate(t, LANE_B, 20)
    assert t.p('p1')['cmd']['p2'] == 20 and t.p('p1')['cmd2']['p2'] == 20, t.p('p1')
    assert t.out('p1') == '', '20 de cada comandante não mata'
    t.shot('60-duas-faixas')
    t.tap(*t.centre(LANE_B))
    assert t.p('p1')['cmd2']['p2'] == 21 and t.out('p1') == 'Dano de comandante letal', t.p('p1')

@check('61 cada faixa tira vida por conta própria, e corrigir devolve exatamente')
def _(t):
    t.fresh(); liga_parceiro(t, 'p2'); t.set_page('p1', 'cmd')
    vida = t.p('p1')['life']
    bate(t, LANE_A, 3); bate(t, LANE_B, 4)
    assert t.p('p1')['life'] == vida - 7, t.p('p1')['life']
    bate(t, '.panel[data-id=p2] .half.minus.lane-b', 4)
    assert t.p('p1')['life'] == vida - 3 and not t.p('p1')['cmd2'], t.p('p1')
    bate(t, '.panel[data-id=p2] .half.minus:not(.lane-b)', 3)
    assert t.p('p1')['life'] == vida and not t.p('p1')['cmd'], t.p('p1')

@check('62 tirar o segundo comandante devolve a vida que só ele tinha tirado')
def _(t):
    t.fresh(); liga_parceiro(t, 'p2'); t.set_page('p1', 'cmd')
    vida = t.p('p1')['life']
    bate(t, LANE_A, 2); bate(t, LANE_B, 5)
    assert t.p('p1')['life'] == vida - 7
    t.click('.panel[data-id=p1] [data-done]')                      # volta ao jogo
    t.click('.panel[data-id=p2] .more'); t.click('[data-act=partner]'); t.click('[data-act=close]')
    assert t.p('p1')['life'] == vida - 2, 'só o dano do parceiro volta'
    assert t.p('p1')['cmd']['p2'] == 2 and not t.p('p1')['cmd2']
    assert t.page.evaluate('__mesa.duo("p2")') is False
    # companheiro e fundo também não causam dano de comandante
    liga_parceiro(t, 'p2'); t.set_page('p1', 'cmd'); bate(t, LANE_B, 3)
    assert t.p('p1')['cmd2']['p2'] == 3
    t.click('.panel[data-id=p1] [data-done]')
    t.click('.panel[data-id=p2] .more'); t.click('[data-act=cmdkind][data-v=background]'); t.click('[data-act=close]')
    assert not t.p('p1')['cmd2'] and t.page.evaluate('__mesa.duo("p2")') is False
    t.shot('62-fundo-sem-faixa')

@check('63 com parceiro no modo dano, a régua continua limpa e o numeral legível')
def _(t):
    bad = []
    for vp, ins, tag in ((LAND, INSETS_LAND, 'paisagem'), (PORT, INSETS_PORT, 'retrato')):
        t.page.set_viewport_size(vp)
        for n in (2, 4, 6):
            t.fresh(players=n, insets=ins)
            liga_parceiro(t, 'p2')
            t.set_page('p1', 'cmd')
            bate(t, LANE_A, 2); bate(t, LANE_B, 13)               # valores de 1 e 2 dígitos nas duas faixas
            bad += ['%s %dj: %s' % (tag, n, x) for x in t.page.evaluate(LAYOUT_JS)]
            fontes = t.page.evaluate("""() => [...document.querySelectorAll('.panel[data-id=p2] .life')]
              .map(e => Math.round(parseFloat(getComputedStyle(e).fontSize)))""")
            if len(fontes) != 2: bad.append('%s %dj: %d faixas' % (tag, n, len(fontes)))
            if any(f < 40 for f in fontes): bad.append('%s %dj: numeral de faixa com %s px' % (tag, n, fontes))
            if tag == 'paisagem' and n == 4: t.shot('63-duas-faixas-4j')
            if tag == 'retrato' and n == 6: t.shot('63-duas-faixas-6j-retrato')
    t.page.set_viewport_size(LAND); t.fresh()
    assert not bad, '; '.join(bad[:8])

@check('64 o par de comandantes sobrevive ao reload e o dano órfão é descartado')
def _(t):
    t.fresh(); liga_parceiro(t, 'p2'); t.set_page('p1', 'cmd'); bate(t, LANE_B, 2)
    t.click('.panel[data-id=p1] [data-done]')
    t.page.reload(); t.page.wait_for_function('window.__mesa')
    t.page.evaluate('([l,tp,r,b]) => __setInsets(l,tp,r,b)', list(INSETS_LAND))
    assert t.page.evaluate('__mesa.duo("p2")') is True and t.p('p1')['cmd2']['p2'] == 2
    assert '+' in t.page.locator('.panel[data-id=p2] .cmdr').inner_text(), 'o card mostra os dois nomes'
    ruim = '{"v":3,"startLife":40,"players":[{"cmd2":{"p2":7}},{"cmd2":{"p1":5}},{},{}]}'
    t.page.evaluate('v => localStorage.setItem("brewtact.mesa.prototipo.v3", v)', ruim)
    t.page.reload(); t.page.wait_for_function('window.__mesa && __mesa.state().players.length >= 2')
    assert t.p('p1')['cmd2'] == {} and t.p('p2')['cmd2'] == {}, 'dano de um segundo comandante que não existe some'
    assert t.page.locator('.panel').count() == len(t.st()['players'])

def dar_peca(t, pid, act='monarch'):
    t.click('.panel[data-id=%s] .more' % pid); t.click('[data-act=%s]' % act); t.click('[data-act=close]')

def arrasta_peca(t, kind, de, para):
    x, y = t.centre('.panel[data-id=%s] .tok[data-tok=%s]' % (de, kind))
    tx, ty = t.centre('.panel[data-id=%s]' % para)
    t.swipe(x, y, tx, ty, steps=10)

@check('65 a coroa muda de dono arrastando de um card para outro, sem mexer na partida')
def _(t):
    t.fresh(); dar_peca(t, 'p1')
    assert t.page.evaluate('__mesa.tokens()')['crown'] == 'p1'
    vida, faces = t.p('p1')['life'], t.view()['page'].get('p1')
    t.shot('65-coroa-no-card')
    arrasta_peca(t, 'crown', 'p1', 'p3')
    tk = t.page.evaluate('__mesa.tokens()')
    assert tk['crown'] == 'p3' and tk['carry'] == 0, tk
    assert t.p('p1')['life'] == vida, 'arrastar a peça não pode somar vida'
    assert t.view()['cmdFor'] is None and t.view()['page'].get('p1') == faces, 'nem virar a face do card'
    assert t.page.locator('.panel.is-drop').count() == 0
    t.shot('65-coroa-passou')
    # a iniciativa é uma peça separada, e as duas convivem no mesmo card
    dar_peca(t, 'p3', 'initiative')
    tk = t.page.evaluate('__mesa.tokens()')
    assert tk['crown'] == 'p3' and tk['init'] == 'p3', tk
    assert t.page.locator('.panel[data-id=p3] .tok:not([hidden])').count() == 2

@check('66 a peça não vai para quem está fora, e quem sai a perde na hora')
def _(t):
    t.fresh(); dar_peca(t, 'p1')
    t.click('.panel[data-id=p2] .more'); t.click('[data-act=concede]'); t.click('[data-act=close]')
    arrasta_peca(t, 'crown', 'p1', 'p2')
    assert t.page.evaluate('__mesa.tokens()')['crown'] == 'p1', 'quem está fora não recebe a peça'
    arrasta_peca(t, 'crown', 'p1', 'p4')
    assert t.page.evaluate('__mesa.tokens()')['crown'] == 'p4'
    t.click('.panel[data-id=p4] .more'); t.click('[data-act=concede]'); t.click('[data-act=close]')
    assert t.page.evaluate('__mesa.tokens()')['crown'] is None, 'quem sai larga a peça'
    assert t.page.locator('.panel[data-id=p4] .tok[data-tok=crown]').is_visible() is False

@check('67 tocar na peça abre a escolha, e a folha Mesa mostra quem está com cada uma')
def _(t):
    t.fresh(); dar_peca(t, 'p1')
    x, y = t.centre('.panel[data-id=p1] .tok[data-tok=crown]')
    t.tap(x, y)
    assert t.view()['sheet'] == 'token', t.view()
    t.shot('67-folha-da-peca')
    t.click('[data-act=givetok][data-p=p2]')
    assert t.page.evaluate('__mesa.tokens()')['crown'] == 'p2'
    t.click('[data-act=givetok][data-p=""]')
    assert t.page.evaluate('__mesa.tokens()')['crown'] is None
    t.click('[data-act=close]')
    t.open_hub()
    assert 'SEM DONO' in t.page.locator('#tileCrown').inner_text().upper()
    t.click('#tileCrown'); t.click('[data-act=givetok][data-p=p3]')
    t.click('[data-act=close]')
    assert t.page.evaluate('__mesa.tokens()')['crown'] == 'p3'

@check('68 com as duas peças na mesa, a régua continua limpa em toda face e tamanho')
def _(t):
    bad = []
    for vp, ins, tag in ((LAND, INSETS_LAND, 'paisagem'), (PORT, INSETS_PORT, 'retrato')):
        t.page.set_viewport_size(vp)
        for n in (2, 4, 6):
            t.fresh(players=n, insets=ins)
            dar_peca(t, 'p1'); dar_peca(t, 'p2' if n > 1 else 'p1', 'initiative')
            bad += ['%s %dj mesa: %s' % (tag, n, x) for x in t.page.evaluate(LAYOUT_JS)]
            t.set_page('p1', 'counters')
            bad += ['%s %dj marcadores: %s' % (tag, n, x) for x in t.page.evaluate(LAYOUT_JS)]
            t.click('.panel[data-id=p1] .cback')
            t.set_page('p2', 'cmd')
            bad += ['%s %dj dano: %s' % (tag, n, x) for x in t.page.evaluate(LAYOUT_JS)]
            t.click('.panel[data-id=p2] [data-done]')
            t.click('.panel[data-id=p1] .setlife'); t.click('[data-act=digit][data-n="0"]'); t.click('[data-act=padapply]')
            bad += ['%s %dj eliminado: %s' % (tag, n, x) for x in t.page.evaluate(LAYOUT_JS)]
            if tag == 'paisagem' and n == 4: t.shot('68-pecas-na-mesa')
    t.page.set_viewport_size(LAND); t.fresh()
    assert not bad, '; '.join(bad[:8])

WASH_JS = """() => [...document.querySelectorAll('.panel')].map(p => getComputedStyle(p).getPropertyValue('--wash').trim())"""

@check('69 dia e noite: a mesa muda de luz, o hub muda de marca e só a virada conta')
def _(t):
    t.fresh()
    assert t.page.evaluate('__mesa.daynight()') == {'mode': 'none', 'flips': 0}
    assert t.page.locator('#btnHub .mark').is_visible()
    t.open_hub(); t.click('#btnDayNight')
    dn = t.page.evaluate('__mesa.daynight()')
    assert dn == {'mode': 'day', 'flips': 0}, dn                     # entrar no modo não é virada
    assert 'is-day' in t.page.locator('#btnDayNight').get_attribute('class'), 'a peça do menu mostra o céu'
    t.close_hub()
    assert t.page.locator('#btnHub .sun').is_visible() and not t.page.locator('#btnHub .mark').is_visible()
    lavagem = t.page.evaluate(WASH_JS)
    assert all(v and v != 'transparent' for v in lavagem), lavagem
    t.shot('69-dia')
    t.open_hub(); t.click('#btnDayNight'); t.close_hub()
    dn = t.page.evaluate('__mesa.daynight()')
    assert dn == {'mode': 'night', 'flips': 1}, dn
    assert t.page.locator('#btnHub .moon').is_visible()
    t.shot('69-noite')
    t.open_rules(); t.click('[data-act=daynight][data-v=none]'); t.click('[data-act=close]')
    assert t.page.evaluate('__mesa.daynight()') == {'mode': 'none', 'flips': 0}
    assert t.page.locator('#btnHub .mark').is_visible()
    assert all(v == 'transparent' for v in t.page.evaluate(WASH_JS))

@check('70 no dano de comandante o hub mostra as espadas, mas a luz da mesa continua')
def _(t):
    t.fresh(); t.open_hub(); t.click('#btnDayNight'); t.click('#btnDayNight'); t.close_hub()   # dia e depois noite
    assert t.page.evaluate('__mesa.daynight()')['mode'] == 'night'
    t.swipe_panel('p1', 'right')                                    # o arrasto também fecha o trilho
    assert t.view()['cmdFor'] == 'p1'
    assert t.page.locator('#btnHub .swords').is_visible()
    assert not t.page.locator('#btnHub .moon').is_visible(), 'dano de comandante ganha da marca de dia/noite'
    lavagem = t.page.evaluate(WASH_JS)
    assert all(v and v != 'transparent' for v in lavagem), 'a luz vale inclusive em quem recebe e em quem causa'
    t.shot('70-modo-dano-noite')
    t.click('.panel[data-id=p1] [data-done]')
    assert t.page.locator('#btnHub .moon').is_visible()
    # e um card eliminado também fica na luz da mesa
    t.click('.panel[data-id=p2] .setlife'); t.click('[data-act=digit][data-n="0"]'); t.click('[data-act=padapply]')
    assert t.page.evaluate(WASH_JS)[0] != 'transparent'

@check('71 a luz não move nem encolhe o numeral, e a régua segue limpa')
def _(t):
    bad = []
    for vp, ins, tag in ((LAND, INSETS_LAND, 'paisagem'), (PORT, INSETS_PORT, 'retrato')):
        t.page.set_viewport_size(vp)
        for n in (4, 6):
            t.fresh(players=n, insets=ins)
            antes = t.page.evaluate(CENTRE_JS)
            for modo in ('day', 'night'):
                t.open_rules(); t.click('[data-act=daynight][data-v=%s]' % modo); t.click('[data-act=close]')
                bad += ['%s %dj %s: %s' % (tag, n, modo, x) for x in t.page.evaluate(LAYOUT_JS)]
                for a, d in zip(antes, t.page.evaluate(CENTRE_JS)):
                    if abs(a['dx'] - d['dx']) > 1 or abs(a['dy'] - d['dy']) > 1 or abs(a['font'] - d['font']) > 1:
                        bad.append('%s %dj %s: numeral de %s mudou de lugar ou tamanho' % (tag, n, modo, d['id']))
            if tag == 'paisagem' and n == 4: t.shot('71-noite-4j')
    t.page.set_viewport_size(LAND); t.fresh()
    assert not bad, '; '.join(bad[:8])

def abre_plano(t):
    t.open_hub(); t.click('#btnPlane')
    assert t.view()['sheet'] == 'plane'

@check('72 dado planar: custo sobe no turno, zera na vez nova, e caos e planeswalk são contados')
def _(t):
    t.fresh(); abre_plano(t); t.click('[data-act=pcmode]')
    pl = t.page.evaluate('__mesa.plane()')
    assert pl['on'] is True and pl['rolls'] == 0, pl
    for i in range(1, 5):
        t.click('[data-act=planarroll]')
        pl = t.page.evaluate('__mesa.plane()')
        assert pl['rolls'] == i, pl
        assert '{%d}' % i in t.page.locator('.pl-hero i').inner_text(), t.page.locator('.pl-hero i').inner_text()
    assert pl['chaos'] + pl['walks'] <= 4 and pl['chaos'] <= 4, pl
    assert t.page.locator('.pl-hero b').inner_text() in ('Nada', 'Caos', 'Planeswalk')
    t.shot('72-dado-planar')
    t.click('[data-act=close]')
    t.open_hub(); t.click('#btnTurn')                                   # a vez passa: o custo volta a zero
    assert t.page.evaluate('__mesa.plane()')['rolls'] == 0
    abre_plano(t)
    assert 'GRAÇA' in t.page.locator('.pl-hero i').inner_text().upper()   # o rótulo é renderizado em caixa alta
    t.click('[data-act=close]')

@check('73 trocar de plano zera o caos e guarda o anterior, sem repetir')
def _(t):
    t.fresh(); abre_plano(t); t.click('[data-act=pcmode]')
    t.page.fill('#pPlane', 'Academia Ruína')
    t.click('[data-act=chaos][data-d="1"]'); t.click('[data-act=chaos][data-d="1"]')
    pl = t.page.evaluate('__mesa.plane()')
    assert pl['name'] == 'Academia Ruína' and pl['chaos'] == 2, pl
    t.page.fill('#pPlane', 'Naar Isle')
    pl = t.page.evaluate('__mesa.plane()')
    assert pl['name'] == 'Naar Isle' and pl['chaos'] == 0 and pl['recent'][0] == 'Academia Ruína', pl
    t.page.fill('#pPlane', 'Academia Ruína')
    t.page.fill('#pPlane', 'Naar Isle')
    assert t.page.evaluate('__mesa.plane()')['recent'].count('Academia Ruína') == 1, t.page.evaluate('__mesa.plane()')
    t.shot('73-plano-atual')
    t.click('[data-act=pcmode]')                                        # desligar limpa
    pl = t.page.evaluate('__mesa.plane()')
    assert pl['on'] is False and pl['name'] == '' and pl['chaos'] == 0, pl
    t.click('[data-act=close]')

@check('74 arqui-inimigo, recompensa no catálogo e a marca do plano no hub')
def _(t):
    t.fresh()
    assert len(t.page.evaluate('__mesa.counters()')) == 21
    abre_plano(t); t.click('[data-act=aemode]')
    t.click('[data-act=setarch][data-p=p2]')
    t.click('[data-act=scheme][data-d="1"]'); t.click('[data-act=scheme][data-d="1"]'); t.click('[data-act=scheme][data-d="1"]')
    pl = t.page.evaluate('__mesa.plane()')
    assert pl['arch'] is True and pl['archOf'] == 'p2' and pl['schemes'] == 3, pl
    t.shot('74-arqui-inimigo')
    t.click('[data-act=pcmode]'); t.click('[data-act=close]')           # liga planechase e volta à mesa
    assert t.page.locator('#btnHub .planar').is_visible() and not t.page.locator('#btnHub .mark').is_visible()
    t.open_rules(); t.click('[data-act=daynight][data-v=night]'); t.click('[data-act=close]')
    assert t.page.locator('#btnHub .planar').is_visible(), 'plano ganha de dia/noite na marca'
    assert not t.page.locator('#btnHub .moon').is_visible()
    t.swipe_panel('p1', 'right')
    assert t.page.locator('#btnHub .swords').is_visible(), 'dano de comandante ganha de tudo'
    t.click('.panel[data-id=p1] [data-done]')
    # e o hub continua do tamanho e no lugar, com o trilho aberto
    caixa = t.box('#btnHub')
    assert round(caixa['width']) == 48 and round(caixa['height']) == 48, caixa
    t.open_hub()
    h = t.page.evaluate(HUB_JS)
    assert abs(h['cx'] - h['tx']) <= 1 and abs(h['cy'] - h['ty']) <= 1, h      # o ✕ nasce no mesmo ponto
    assert t.page.evaluate(SMALL_JS) == []
    # o marcador de recompensa aparece no painel como qualquer outro
    t.close_hub()
    t.set_page('p2', 'counters'); t.click('.panel[data-id=p2] .cadd')
    t.click('[data-act=toggle-counter][data-c=bounty]'); t.click('[data-act=close]')
    t.click('.panel[data-id=p2] .pm[data-c=bounty][data-d="1"]')
    assert t.p('p2')['c']['bounty'] == 1, t.p('p2')['c']
    t.shot('74-recompensa')

@check('75 nenhuma cor do protótipo cai em nada: todo token usado está declarado')
def _(t):
    # variáveis escritas pelo JS por elemento (cor do card, arrasto, desvio do hub) não vivem no :root
    RUNTIME = {'--bg', '--ctop', '--dx', '--drag', '--dragf', '--c', '--c2', '--wash', '--corev', '--tokl', '--tokr'}
    fonte = (ROOT / 'mesa-brewtact.html').read_text()
    import re
    declaradas = set(re.findall(r'(--[a-z0-9-]+)\s*:', fonte))
    usadas = set(re.findall(r'var\((--[a-z0-9-]+)', fonte))
    orfas = sorted(usadas - declaradas - RUNTIME)
    assert orfas == [], 'token usado sem declaração: %s' % orfas
    # e, no navegador, toda cor da paleta (declarada no :root) resolve de verdade
    raiz = set(re.findall(r'(--[a-z0-9-]+)\s*:', fonte[fonte.index(':root'):fonte.index('html, body')]))
    t.fresh(); t.open_hub()
    vazios = t.page.evaluate("""(nomes) => { const cs = getComputedStyle(document.documentElement);
      return nomes.filter(n => !cs.getPropertyValue(n).trim()); }""", sorted(raiz))
    assert vazios == [], 'token da paleta sem valor no navegador: %s' % vazios
    assert '--frost-400' in raiz and '--frost-400' in usadas, 'o azul do aro noturno tem de existir e ser usado'
    t.close_hub()

@check('76 contraste medido nos pixels: texto e ícone sobre peça acesa passam no mínimo WCAG')
def _(t):
    import subprocess as sp
    r = sp.run([sys.executable, str(ROOT / 'tools' / 'contrast.py')], capture_output=True, text=True)
    assert r.returncode == 0, r.stderr[-400:]
    ruins = [l for l in r.stdout.splitlines() if 'REPROVA' in l]
    assert not ruins, 'contraste abaixo do mínimo:\n' + '\n'.join(ruins)

SEED_HIST = """() => {
  const agora = Date.now(), cor = ['brasa','mare','musgo','ambar','indigo','cobre'];
  const jog = (n, i, l, o, f) => ({ n: n, c: cor[i], l: l, m: i === 1 ? 14 : 0, v: i === 2 ? 3 : 0, o: o || '', f: f || '', ms: 400000 });
  const g = [
    { s: agora - 3600e3, e: agora - 1800e3, n: 40, k: 'fim', wi: 0, wm: 0, d: 0, t: 1802000,
      p: [jog('Rafa', 0, 27, '', 'Atraxa fez o serviço'), jog('Bia', 1, 0, 'dano de comandante'), jog('Léo', 2, 0, 'veneno'), jog('Duda', 3, 12, '')] },
    { s: agora - 26 * 3600e3, e: agora - 25 * 3600e3, n: 40, k: 'nova', wi: -1, wm: 0, d: 1, t: 2740000,
      p: [jog('Rafa', 0, 0, 'vida zerada'), jog('Nina', 4, 0, 'vida zerada'), jog('Téo', 5, 0, 'vida zerada')] },
    { s: agora - 52 * 3600e3, e: agora - 50 * 3600e3, n: 30, k: 'fim', wi: 1, wm: 1, d: 0, t: 5430000,
      p: [jog('Maria Aparecida', 2, 4, ''), jog('Duda', 3, 18, '', 'Talrand não deixou barato'), jog('Mel', 5, 0, 'concedeu')] }
  ];
  localStorage.setItem('brewtact.mesa.hist.v1', JSON.stringify({ hv: 1, g: g }));
}"""

# nada de texto cortado nem peça por cima de peça nas telas novas
CORTE_JS = r'''(sels) => {
  const mau = [], R = e => e.getBoundingClientRect();
  sels.forEach(sel => document.querySelectorAll(sel).forEach(e => {
    if (!e.offsetParent) return;
    const c = getComputedStyle(e), corta = c.overflow !== 'visible';
    if (e.scrollWidth > e.clientWidth + 1) mau.push(sel + ' cortado na largura: "' + e.textContent.trim().slice(0, 30) + '"');
    // só faz sentido falar em corte onde a caixa realmente esconde; com overflow visível a serifa só transborda
    if (corta && e.scrollHeight > e.clientHeight + 1) mau.push(sel + ' cortado na altura: "' + e.textContent.trim().slice(0, 30) + '"');
  }));
  document.querySelectorAll('.hx-g').forEach(g => {
    const x = R(g.querySelector('.hx-x'));
    ['.ttl', '.meta', '.dur', '.hx-seats'].forEach(sel => {
      const e = g.querySelector(sel); if (!e) return; const r = R(e);
      if (r.left < x.right - 1 && x.left < r.right - 1 && r.top < x.bottom - 1 && x.top < r.bottom - 1)
        mau.push('o ✕ cobre ' + sel + ' da ficha');
    });
    if (x.width < 40 || x.height < 40) mau.push('o ✕ da ficha é menor que 40px');
  });
  return mau;
}'''

@check('78 partidas guardadas: ficha na cor de quem venceu, empate sem dono, nada cortado')
def _(t):
    t.fresh(); t.page.evaluate(SEED_HIST)
    t.open_hub(); t.click('#tileHistory')
    assert t.view()['sheet'] == 'history'
    assert t.page.locator('table').count() == 0, 'a tela voltou a ser tabela'
    fichas = t.page.locator('.hx-g')
    assert fichas.count() == 3, 'esperava três fichas, vi %d' % fichas.count()
    heroi = t.page.locator('.hx-g.hero')
    assert heroi.count() == 1 and heroi.first.get_attribute('style').find('#A83A27') >= 0, \
        'a ficha grande tem de vir na cor de quem venceu'
    assert 'Atraxa fez o serviço' in heroi.first.inner_text(), 'a fala de quem venceu sumiu do herói'
    livre = t.page.locator('.hx-g.livre')
    assert livre.count() == 1 and 'EMPATE' in livre.first.inner_text().upper(), 'o empate tem de ficar sem dono'
    tracejado = t.page.evaluate("() => getComputedStyle(document.querySelector('.hx-g.livre')).outlineStyle")
    assert tracejado == 'dashed', 'sem dono é contorno tracejado, veio %s' % tracejado
    # a coroa de latão marca quem venceu dentro da mesa em miniatura
    assert t.page.locator('.hx-g.hero .hx-seats i.w').count() == 1
    assert t.page.locator('.hx-g.livre .hx-seats i.w').count() == 0
    t.shot('L-partidas')
    ruins = t.page.evaluate(CORTE_JS, ['.hx-g b', '.hx-g .say', '.hx-g .meta', '.hx-g .dur'])
    assert not ruins, '; '.join(ruins)

@check('79 abrir uma partida guardada mostra cada jogador como card, e apagar pede dois toques')
def _(t):
    t.fresh(); t.page.evaluate(SEED_HIST)
    t.open_hub(); t.click('#tileHistory'); t.click('.hx-g.hero .hx-open')
    assert t.view()['sheet'] == 'match'
    assert t.page.locator('table').count() == 0, 'o resultado voltou a ser tabela'
    linhas = t.page.locator('.rs .rs-p')
    assert linhas.count() == 4, linhas.count()
    primeiro = linhas.first
    assert 'RAFA' in primeiro.inner_text().upper() and 'VENCEU' in primeiro.inner_text().upper()
    assert 'win' in (primeiro.get_attribute('class') or ''), 'quem venceu não ganhou o aro de latão'
    assert '27' in primeiro.inner_text(), 'a vida de quem venceu sumiu'
    assert t.page.locator('.rs-p.out').count() == 2, 'quem saiu antes do fim tem de ficar apagado'
    t.shot('L-partida')
    ruins = t.page.evaluate(CORTE_JS, ['.rs-p .who b', '.rs-p .who i', '.rs-p .num', '.rs-p .tags em'])
    assert not ruins, '; '.join(ruins)
    # voltar e apagar: um toque arma, o outro apaga
    t.click('[data-act=history]')
    alvo = t.page.locator('.hx-g.hero .hx-x')
    s = alvo.get_attribute('data-s'); alvo.click()
    armado = t.page.locator('.hx-x.is-armed')
    assert armado.count() == 1 and len(t.hist()) == 3, 'o primeiro toque não pode apagar nada'
    cor = t.page.evaluate("() => getComputedStyle(document.querySelector('.hx-x.is-armed')).backgroundColor")
    assert cor.replace(' ', '') == 'rgb(110,27,42)', 'o ✕ armado tem de ficar vinho, veio %s' % cor
    t.page.locator('.hx-x.is-armed').click()
    assert len(t.hist()) == 2, 'o segundo toque tinha de apagar'
    assert t.page.locator('.hx-g').count() == 2
    ruins = t.page.evaluate(CORTE_JS, ['.hx-g b', '.hx-g .meta', '.hx-g .dur'])
    assert not ruins, '; '.join(ruins)
    t.click('[data-act=close]')

@check('77 a cor de estado ruim não é a cor de ninguém: longe de toda cor de jogador')
def _(t):
    import re
    def lab(h):
        h = h.lstrip('#'); r, g, b = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
        f = lambda c: c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4
        r, g, b = f(r), f(g), f(b)
        X = (r * .4124 + g * .3576 + b * .1805) / .95047; Y = r * .2126 + g * .7152 + b * .0722
        Z = (r * .0193 + g * .1192 + b * .9505) / 1.08883
        k = lambda v: v ** (1 / 3) if v > .008856 else 7.787 * v + 16 / 116
        fx, fy, fz = k(X), k(Y), k(Z)
        return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    dist = lambda a, b: sum((x - y) ** 2 for x, y in zip(lab(a), lab(b))) ** .5
    fonte = (ROOT / 'mesa-brewtact.html').read_text()
    ruim = re.search(r'--vinho:\s*(#[0-9A-Fa-f]{6})', fonte).group(1)
    paleta = re.findall(r"\{ id: '[a-z]+',\s+name: '[^']+',\s+hex: '(#[0-9A-Fa-f]{6})' \}", fonte)
    assert len(paleta) >= 10, 'não achei a paleta de jogadores: %s' % paleta
    perto = [(h, round(dist(ruim, h), 1)) for h in paleta if dist(ruim, h) < 25]
    assert not perto, 'a cor de "concedeu/encerrar" %s se confunde com cor de jogador: %s' % (ruim, perto)
    # e a peça acesa tem de usar o token, não um vermelho solto
    t.fresh(); regra = [l for l in fonte.splitlines() if l.strip().startswith('.rt.bad.on {')][0]
    assert 'var(--vinho)' in regra and not re.search(r'#[0-9A-Fa-f]{6}', regra), 'peça de estado ruim fora do token: %s' % regra.strip()[:120]
    # na tela: com o jogador em brasa, a peça acesa ainda tem de ser outra cor
    t.click('.panel[data-id=p2] .more'); t.click('[data-act=color][data-c=brasa]')
    t.click('[data-act=concede]'); t.page.wait_for_timeout(280)
    acesa = t.page.locator('.pf-states .rt.bad.on')
    assert acesa.count() == 1, 'a peça Concedeu não acendeu'
    t.shot('L-concedeu-vs-cor')
    pega = lambda sel: t.page.evaluate("(s) => { const e = document.querySelector(s); if (!e) return null;"
        " const m = getComputedStyle(e).backgroundImage.match(/rgba?\\([^)]+\\)/g) || [];"
        " return m.length ? m[Math.floor(m.length / 2)] : getComputedStyle(e).backgroundColor; }", sel)
    def rgb(v):
        n = [float(x) for x in re.findall(r'[\d.]+', v or '')][:3]
        return '#%02X%02X%02X' % tuple(int(round(c)) for c in n) if len(n) == 3 else None
    cp, cc = rgb(pega('.pf-states .rt.bad.on')), rgb(pega('.panel[data-id=p2]'))
    assert cp and cc, 'não consegui ler as duas cores (%s / %s)' % (cp, cc)
    d = dist(cp, cc)
    assert d >= 25, 'na tela a peça Concedeu (%s) lê como a cor do jogador (%s): dE=%.1f' % (cp, cc, d)
    t.click('[data-act=close]')

@check('80 teclado de vida: o número é o herói na cor do jogador, e o latão só acende com o que aplicar')
def _(t):
    t.fresh()
    cor = t.page.evaluate("() => getComputedStyle(document.querySelector('.panel[data-id=p2]')).getPropertyValue('--c').trim()")
    vida0 = [q['life'] for q in t.st()['players'] if q['id'] == 'p2'][0]
    t.click('.panel[data-id=p2] .setlife')
    assert t.view()['sheet'] == 'pad'
    assert t.page.locator('.padbody .btns').count() == 0, 'o rodapé de botões de texto voltou'
    assert t.page.locator('.padbody input').count() == 0, 'teclado de vida não tem campo de formulário'
    heroi = t.page.locator('.padout')
    assert (heroi.get_attribute('style') or '').find(cor) >= 0, 'o herói tem de vestir a cor de quem vai receber'
    assert t.page.locator('.pd-go.on').count() == 0, 'sem nada digitado o latão não pode estar aceso'
    assert t.page.locator('.pd-v b').inner_text() == str(t.st()['startLife'])
    t.click('[data-act=digit][data-n="1"]'); t.click('[data-act=digit][data-n="5"]')
    assert t.page.locator('.padout output').inner_text() == '15'
    assert t.page.locator('.pd-go.on').count() == 1, 'com valor digitado o latão acende'
    sub = t.page.locator('.padout .sub').inner_text().upper()
    assert ('ERA %d' % vida0) in sub and str(abs(15 - vida0)) in sub, \
        'a linha de apoio tem de dizer de quanto era e quanto muda: %r' % sub
    t.shot('L-teclado')
    ruins = t.page.evaluate(CORTE_JS, ['.padout .cap', '.padout .sub', '.pd-v b', '.pd-v i'])
    assert not ruins, '; '.join(ruins)
    baixas = t.page.evaluate("""() => [...document.querySelectorAll('.pad button, .pd-go, .pd-v')]
      .filter(e => e.getBoundingClientRect().height < 44).length""")
    assert baixas == 0, '%d peça(s) do teclado abaixo de 44px' % baixas
    t.click('[data-act=padapply]')
    assert [q['life'] for q in t.st()['players'] if q['id'] == 'p2'] == [15]
    # a vida inicial é da mesa, não de alguém: herói neutro
    t.open_mesa(); t.click('[data-act=startother]')
    assert t.view()['sheet'] == 'startpad'
    assert t.page.locator('.padout.neutro').count() == 1, 'o herói sem dono tem de ser vidro escuro'
    assert t.page.locator('.pd-go.wide').count() == 1
    t.click('[data-act=close]')

@check('81 quem fica com a peça: cada jogador é um card, e "ninguém" é a peça vazia da mesma grade')
def _(t):
    t.fresh()
    t.click('.panel[data-id=p4] .more'); t.click('[data-act=concede]'); t.click('[data-act=close]')
    t.open_hub(); t.click('#tileCrown')
    assert t.view()['sheet'] == 'token'
    assert t.page.locator('.sheet-body .btns').count() == 0, 'o rodapé "ninguém fica com ela" voltou'
    assert t.page.locator('.tk-p').count() == 5, 'quatro jogadores mais a peça vazia'
    assert t.page.locator('.tk-p.livre').count() == 1
    assert t.page.locator('.tk-p.out[disabled]').count() == 1, 'quem está fora não pode receber'
    # tirar de todo mundo: herói tracejado e a peça vazia passa a ser a escolhida
    t.click('.tk-p.livre')
    assert t.page.evaluate("() => getComputedStyle(document.querySelector('.tk-hero')).outlineStyle") == 'dashed'
    assert 'livre on' in (t.page.locator('.tk-p.livre').get_attribute('class') or '')
    assert t.page.locator('.tk-hero b').inner_text().upper() == 'SEM DONO'
    t.shot('L-peca-livre')
    t.click('.tk-p[data-p=p2]')
    assert t.page.evaluate('__mesa.tokens()')['crown'] == 'p2'
    dono = t.page.locator('.tk-p[data-p=p2]')
    assert 'on' in (dono.get_attribute('class') or '') and dono.locator('svg').count() == 1, 'a marca fica com quem tem a peça'
    assert t.page.locator('.tk-p[data-p=p1] svg').count() == 0, 'quem não tem a peça não mostra a marca'
    cor = t.page.evaluate("() => getComputedStyle(document.querySelector('.panel[data-id=p2]')).getPropertyValue('--c').trim()")
    assert (t.page.locator('.tk-hero').get_attribute('style') or '').find(cor) >= 0, 'o herói veste a cor de quem tem a peça'
    assert t.page.evaluate("() => getComputedStyle(document.querySelector('.tk-hero')).outlineStyle") != 'dashed'
    t.shot('L-peca')
    ruins = t.page.evaluate(CORTE_JS, ['.tk-hero b', '.tk-hero i', '.tk-p b', '.tk-p i'])
    assert not ruins, '; '.join(ruins)
    baixas = t.page.evaluate("() => [...document.querySelectorAll('.tk-p')].filter(e => e.getBoundingClientRect().height < 44).length")
    assert baixas == 0, '%d peça(s) abaixo de 44px' % baixas
    t.click('.tk-p.livre')
    assert t.page.evaluate('__mesa.tokens()')['crown'] is None
    assert t.page.locator('.tk-p[data-p=p2] svg').count() == 0
    t.click('[data-act=close]')

def piso(t):
    """(menor corpo, menor altura relativa) do numeral entre todos os cards da mesa."""
    rows = t.page.evaluate(CENTRE_JS)
    return (min(r['font'] for r in rows), min(.72 * r['font'] / r['h'] for r in rows), rows)

@check('82 arranjo dos assentos: só duas fileiras, só as divisões que mantêm o piso do numeral')
def _(t):
    t.fresh()
    # o catálogo é medido, não opinado: fileira de até três
    oferta = {n: t.page.evaluate('(n) => __mesa.arranjos(n)', n) for n in range(1, 11)}
    assert oferta[4] == [1, 2, 3], oferta[4]
    assert oferta[5] == [2, 3], oferta[5]
    assert oferta[3] == [1, 2], oferta[3]
    assert oferta[2] == [1] and oferta[1] == [1], (oferta[1], oferta[2])
    for n in (6, 7, 8, 9, 10):
        assert len(oferta[n]) == 1, 'mesa de %d não tem arranjo que cumpra o piso, então não se oferece escolha: %s' % (n, oferta[n])
    bad = []
    for vp, ins, tag in ((LAND, INSETS_LAND, 'paisagem'), (PORT, INSETS_PORT, 'retrato')):
        t.page.set_viewport_size(vp)
        for n in (3, 4, 5):
            for baixo in oferta[n]:
                t.fresh(players=n, insets=ins)
                t.open_mesa(); t.click('[data-act=arranjo][data-v="%d"]' % baixo); t.click('[data-act=close]')
                assert t.st()['seatRow'] == baixo, 'o arranjo %d+%d não pegou' % (n - baixo, baixo)
                cima = t.page.evaluate("() => document.querySelectorAll('.row-top .panel').length")
                assert cima == n - baixo, '%s %dj: pedi %d em cima, vieram %d' % (tag, n, n - baixo, cima)
                corpo, share, _ = piso(t)
                if corpo < 40 or share < .38:
                    bad.append('%s %dj %d+%d: numeral %.0fpx, %.0f%% da altura' % (tag, n, n - baixo, baixo, corpo, 100 * share))
                bad += ['%s %dj %d+%d: %s' % (tag, n, n - baixo, baixo, x) for x in t.page.evaluate(LAYOUT_JS)]
                for r in t.page.evaluate(CENTRE_JS):
                    if abs(r['dx']) > 1 or abs(r['dy']) > 1:
                        bad.append('%s %dj %d+%d: %s fora do centro do card' % (tag, n, n - baixo, baixo, r['id']))
    t.page.set_viewport_size(LAND)
    assert not bad, '; '.join(bad[:8])

@check('83 escolher arranjo é preferência, não lance: sobrevive ao reload e não mexe na partida')
def _(t):
    t.fresh(players=4)
    vidas = {q['id']: q['life'] for q in t.st()['players']}
    t.open_mesa(); t.click('[data-act=arranjo][data-v="3"]'); t.click('[data-act=close]')
    assert t.st()['seatRow'] == 3
    assert {q['id']: q['life'] for q in t.st()['players']} == vidas, 'mudar o arranjo mexeu na vida de alguém'
    assert t.view()['undo'] == 0, 'arranjo não é lance: não entra na pilha de desfazer'
    t.page.reload(); t.page.wait_for_function('window.__mesa && __mesa.state().players.length > 0')
    t.page.evaluate('([l,tp,r,b]) => __setInsets(l,tp,r,b)', list(INSETS_LAND))
    assert t.st()['seatRow'] == 3, 'o arranjo tem de sobreviver ao reload'
    assert t.page.evaluate("() => document.querySelectorAll('.row-top .panel').length") == 1
    t.shot('L-arranjo-3-1')
    # a miniatura do menu e a da peça Mesa contam a mesma história
    t.open_hub()
    linhas = t.page.evaluate("() => [...document.querySelectorAll('#menuSeats .ln')].map(l => l.children.length)")
    assert linhas == [1, 3], 'a miniatura do menu tem de mostrar o arranjo que está valendo: %s' % linhas
    t.close_hub()
    # trocar o número de jogadores descarta um arranjo que não existe mais
    t.open_mesa(); t.choose('count', 6); t.click('[data-act=close]')
    assert t.st()['seatRow'] in (None, 3), t.st()['seatRow']
    assert t.page.evaluate("() => document.querySelectorAll('.row-top .panel').length") == 3

# ─────────────────────────── layout in every table size ───────────────────────────
LAYOUT_JS = r'''() => {
  const bad = [], R = e => e.getBoundingClientRect(), vis = e => { if (e.offsetParent === null) return false; const c = getComputedStyle(e);
    return c.display !== 'none' && c.visibility !== 'hidden' && parseFloat(c.opacity) > .05; };
  const hit = (a, b) => a.left < b.right - 1 && b.left < a.right - 1 && a.top < b.bottom - 1 && b.top < a.bottom - 1;
  const hub = R(document.querySelector('#btnHub'));
  const W = innerWidth, H = innerHeight, s = getComputedStyle(document.documentElement);
  const px = v => parseFloat(s.getPropertyValue(v)) || 0, safe = { left: px('--sl'), top: px('--st'), right: W - px('--sr'), bottom: H - px('--sb') };
  document.querySelectorAll('.panel').forEach(p => {
    const id = p.dataset.id, pr = R(p);
    // an element clipped by a scrolling/hidden ancestor is only judged by the part you can actually see
    const clipOf = e => { let n = e.parentElement; while (n && n !== p) { if (getComputedStyle(n).overflow !== 'visible') return R(n); n = n.parentElement; } return null; };
    const clipTo = (r, c) => { if (!c) return r;
      const l = Math.max(r.left, c.left), tp = Math.max(r.top, c.top), rt = Math.min(r.right, c.right), bt = Math.min(r.bottom, c.bottom);
      return rt - l < 2 || bt - tp < 2 ? null : { left: l, top: tp, right: rt, bottom: bt, width: rt - l, height: bt - tp }; };
    const parts = ['.who .name b', '.who .cmdr', '.starts', '.more', '.dots', '.chip', '.life', '.modebar button', '.srcnote', '.counters .pm', '.cadd', '.cback', '.outlabel', '.lanenote', '.tok', '.delta.on']
      .flatMap(sel => [...p.querySelectorAll(sel)].filter(vis).map(e => [sel, clipTo(R(e), clipOf(e))]))
      .filter(x => x[1] && x[1].width > 0);
    for (const [sel, r] of parts) {
      if (r.left < pr.left - 1 || r.right > pr.right + 1 || r.top < pr.top - 1 || r.bottom > pr.bottom + 1) bad.push(id + ' ' + sel + ' leaves its panel');
      if (sel !== '.life' && (r.left < safe.left - 1 || r.right > safe.right + 1 || r.top < safe.top - 1 || r.bottom > safe.bottom + 1)) bad.push(id + ' ' + sel + ' is outside the safe area');
      if (sel !== '.life' && hit(r, hub)) bad.push(id + ' ' + sel + ' is under the hub');
    }
    for (let i = 0; i < parts.length; i++) for (let j = i + 1; j < parts.length; j++) {
      const [a, ra] = parts[i], [b, rb] = parts[j];
      if (a === b) continue;
      if (hit(ra, rb)) bad.push(id + ' ' + a + ' overlaps ' + b);
    }
    const life = p.querySelector('.life'); if (vis(life) && parseFloat(getComputedStyle(life).fontSize) < 40) bad.push(id + ' life numeral under 40px');
  });
  if (document.documentElement.scrollWidth > W || document.documentElement.scrollHeight > H) bad.push('page scrolls');
  return bad;
}'''

def layout_pass(t, tag):
    problems = []
    for n in (2, 3, 4, 5, 6):
        t.fresh(players=n, insets=INSETS_PORT if tag == 'retrato' else INSETS_LAND)
        t.page.evaluate('n => document.title = "mesa " + n + "j"', n)
        ids = [p['id'] for p in t.st()['players']]
        t.page.evaluate('''ids => { }''', ids)
        t.shot('L-%s-%dj-1-mesa' % (tag, n)); problems += ['%dj mesa: %s' % (n, x) for x in t.page.evaluate(LAYOUT_JS)]
        # busiest state: every chip on, one player out, then counters page, then commander mode
        t.set_page('p1', 'counters')
        for c, d in (('poison', '1'), ('tax', '2'), ('energy', '1'), ('xp', '1')): t.click('.panel[data-id=p1] .pm[data-c=%s][data-d="%s"]' % (c, d))
        t.shot('L-%s-%dj-2-contadores' % (tag, n)); problems += ['%dj contadores: %s' % (n, x) for x in t.page.evaluate(LAYOUT_JS)]
        t.click('.panel[data-id=p1] .cback')
        t.set_page('p2', 'cmd')
        t.tap(*t.half('p1', +1)); t.tap(*t.half('p1', +1))
        t.shot('L-%s-%dj-3-dano' % (tag, n)); problems += ['%dj dano: %s' % (n, x) for x in t.page.evaluate(LAYOUT_JS)]
        t.click('.panel[data-id=p2] [data-done]')
        t.page.wait_for_timeout(1800)
        t.shot('L-%s-%dj-4-cheio' % (tag, n)); problems += ['%dj cheio: %s' % (n, x) for x in t.page.evaluate(LAYOUT_JS)]
    assert not problems, '; '.join(problems[:12]) + (' …+%d' % (len(problems) - 12) if len(problems) > 12 else '')

@check('24 layout em paisagem, 2 a 6 jogadores: nada sai do painel, da área segura, nem se sobrepõe')
def _(t): layout_pass(t, 'paisagem')

@check('25 celular em pé: a mesa deita sozinha, toque e arrasto continuam certos; layout de 2 a 6')
def _(t):
    t.page.set_viewport_size(PORT)
    try:
        t.fresh(insets=INSETS_PORT); a = t.p('p1')['life']
        t.tap(*t.half('p1', +1)); assert t.p('p1')['life'] == a + 1
        x, y = t.centre('.panel[data-id=p1]'); top = False
        t.swipe(x, y - 45, x, y + 45)     # screen-down == table-right for the bottom row
        assert t.view()['cmdFor'] == 'p1', t.view()
        t.swipe(x, y + 45, x, y - 45); t.swipe(x, y + 45, x, y - 45); assert t.view()['page']['p1'] == 'counters'
        t.shot('25-retrato-contadores')
        layout_pass(t, 'retrato')
    finally:
        t.page.set_viewport_size(LAND)

@check('26 tela grande (tablet/desktop): cabeçalho visível, mesma mesa, layout de 2 a 6')
def _(t):
    t.page.set_viewport_size({'width': 1180, 'height': 820})
    try:
        t.fresh(insets=(0, 0, 0, 0)); assert t.page.locator('.top').is_visible()
        problems = []
        for n in (2, 4, 6):
            t.fresh(players=n, insets=(0, 0, 0, 0)); t.shot('L-desktop-%dj' % n); problems += ['%dj: %s' % (n, x) for x in t.page.evaluate(LAYOUT_JS)]
        assert not problems, '; '.join(problems[:10])
    finally:
        t.page.set_viewport_size(LAND)


def main():
    only = sys.argv[1:]
    with sync_playwright() as pw:
        browser = pw.chromium.launch(executable_path=EXE)
        ctx = browser.new_context(viewport=LAND, has_touch=True, is_mobile=True, device_scale_factor=2)
        page = ctx.new_page(); errors = []
        page.on('pageerror', lambda e: errors.append(str(e)))
        page.on('console', lambda m: errors.append(m.text) if m.type == 'error' and 'ERR_' not in m.text and 'Failed to load resource' not in m.text else None)
        page.goto(URL); page.wait_for_function('window.__mesa')
        t = T(page, ctx.new_cdp_session(page))
        for c in CHECKS:
            if only and not any(c.__name__ == o for o in only): pass
            c(t)
        results.append(('27 nenhum erro de JavaScript durante toda a suíte', not errors, '; '.join(errors[:5])))
        print('PASS' if not errors else 'FAIL', '27 nenhum erro de JavaScript', errors[:3])
        browser.close()
    ok = sum(1 for r in results if r[1])
    (ROOT / 'proofs' / 'auto' / 'resultado.json').write_text(json.dumps([{'check': n, 'pass': p, 'detail': d} for n, p, d in results], ensure_ascii=False, indent=1), encoding='utf-8')
    print('\n%d/%d passaram' % (ok, len(results)))
    sys.exit(0 if ok == len(results) else 1)

if __name__ == '__main__':
    main()
