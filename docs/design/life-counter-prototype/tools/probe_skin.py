"""Feasibility probe for the card-appearance spec: injects a candidate .skin layer into the
live prototype (no file edits) and re-runs the invariants that tests 41 / 24 / 25 enforce."""
import glob, pathlib, sys, subprocess, json
from playwright.sync_api import sync_playwright
ROOT = pathlib.Path('/private/tmp/claude-501/-Users-desenvolvimentomobile-Documents-rafa-mtg-mtgia/d32b60eb-412a-40fd-87e7-6a688b3766e6/scratchpad')
subprocess.run([sys.executable, str(ROOT/'tools'/'wrap.py')], check=True, capture_output=True)
URL = 'file://' + str(ROOT/'serve'/'index.html')
EXE = glob.glob(str(pathlib.Path.home()/'Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell'))[0]
LAND = {'width': 874, 'height': 402}; PORT = {'width': 402, 'height': 874}
INS_L = (62,0,62,21); INS_P = (0,62,0,34)

# candidate CSS + DOM injection, exactly as the spec proposes it
INJECT = r"""
(veil) => {
  var css = document.createElement('style');
  css.textContent = [
    '.skin { position: absolute; inset: 0; pointer-events: none; background-repeat: no-repeat;',
    '  background-position: 50% var(--artY, 50%); background-size: cover; background-image: var(--art, none); }',
    '.skin::after { content: ""; position: absolute; inset: 0;',
    '  background: radial-gradient(70% 58% at 50% 50%, rgba(11,13,18,calc(var(--veil,.3) + .16)), transparent 78%),',
    '  linear-gradient(rgba(11,13,18,var(--veil,.3)), rgba(11,13,18,var(--veil,.3))); }',
    '.panel.is-out .skin { filter: grayscale(1) brightness(.5); }',
    '.panel.is-art .life { text-shadow: 0 1px 2px rgba(0,0,0,.55), 0 0 20px rgba(0,0,0,.5); }',
    '.panel.is-art .who { text-shadow: 0 1px 3px rgba(0,0,0,.75); }'
  ].join('\n');
  document.head.appendChild(css);
  var art = 'repeating-linear-gradient(115deg, #fff 0 14px, #ffe9b0 14px 28px, #cfe6ff 28px 42px)';
  document.querySelectorAll('.panel').forEach(function (p) {
    var in_ = p.querySelector('.panel-in'), d = document.createElement('div');
    d.className = 'skin'; d.setAttribute('aria-hidden', 'true');
    in_.insertBefore(d, in_.firstChild);
    p.classList.add('is-art');
    p.style.setProperty('--art', art);          // worst case: a near-white texture
    p.style.setProperty('--veil', String(veil));
  });
  return document.querySelectorAll('.skin').length;
}
"""
CENTRE_JS = """() => [...document.querySelectorAll('.panel')].map(pn => {
  const c = pn.getBoundingClientRect(), n = pn.querySelector('.life').getBoundingClientRect();
  return { id: pn.dataset.id, dx: n.x + n.width/2 - (c.x + c.width/2), dy: n.y + n.height/2 - (c.y + c.height/2),
           font: parseFloat(getComputedStyle(pn.querySelector('.life')).fontSize), w: pn.offsetWidth, h: pn.offsetHeight };
})"""
LAYOUT_JS = (ROOT/'tools'/'run_tests.py').read_text(encoding='utf-8').split("LAYOUT_JS = r'''")[1].split("'''")[0]

def measure_luma(page):
    """Average + p95 sRGB luma actually painted over the numeral's box, from a real screenshot."""
    return page.evaluate("""() => {
      const pn = document.querySelector('.panel'), r = pn.querySelector('.life').getBoundingClientRect();
      return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
    }""")

def main():
    bad, notes = [], []
    with sync_playwright() as pw:
        b = pw.chromium.launch(executable_path=EXE)
        ctx = b.new_context(viewport=LAND, has_touch=True, is_mobile=True, device_scale_factor=2)
        page = ctx.new_page(); errs = []
        page.on('pageerror', lambda e: errs.append(str(e)))
        page.goto(URL); page.wait_for_function('window.__mesa')
        for vp, ins, tag in ((LAND, INS_L, 'paisagem'), (PORT, INS_P, 'retrato')):
            page.set_viewport_size(vp)
            for n in (2, 3, 4, 5, 6):
                page.evaluate('localStorage.clear()'); page.reload()
                page.wait_for_function('window.__mesa && __mesa.state().players.length > 0')
                page.evaluate('([l,t,r,bb]) => __setInsets(l,t,r,bb)', list(ins))
                if n != 4:
                    page.click('#btnHub'); page.click('#btnHub')
                    page.click('[data-act=count][data-v="%d"]' % n)
                    if len(page.evaluate('__mesa.state().players')) != n:
                        page.click('[data-act=count][data-v="%d"]' % n)
                    page.click('[data-act=close]')
                before = page.evaluate(CENTRE_JS)
                cnt = page.evaluate(INJECT, 0.46)
                assert cnt == n, (cnt, n)
                after = page.evaluate(CENTRE_JS)
                for r0, r1 in zip(before, after):
                    if abs(r1['dx']) > 1 or abs(r1['dy']) > 1:
                        bad.append('%s %dj %s: numeral fora do centro com arte (x %+.1f y %+.1f)' % (tag, n, r1['id'], r1['dx'], r1['dy']))
                    if round(r0['font']) != round(r1['font']):
                        bad.append('%s %dj %s: a arte mudou o tamanho do numeral %s -> %s' % (tag, n, r1['id'], r0['font'], r1['font']))
                probs = page.evaluate(LAYOUT_JS)
                bad += ['%s %dj layout: %s' % (tag, n, x) for x in probs]
                if n == 4 and tag == 'paisagem':
                    # z-order: the tap halves and the dark pills must still be on top of the art
                    hit = page.evaluate("""() => { const h = document.querySelector('.panel .half.plus').getBoundingClientRect();
                      const el = document.elementFromPoint(h.x + h.width/2, h.y + h.height/2); return el ? el.className : null; }""")
                    if 'half' not in (hit or ''): bad.append('a arte ficou por cima da metade de toque: %s' % hit)
                    notes.append('elementFromPoint no centro da metade = ' + str(hit))
                    # the eliminated card keeps the art (panel background override does not reach .skin)
                    page.evaluate("""() => { const s = __mesa.state(); }""")
                    page.click('.panel[data-id=p1] .more'); page.click('[data-act=concede]'); page.click('[data-act=close]')
                    st = page.evaluate("""() => { const sk = document.querySelector('.panel[data-id=p1] .skin');
                      const c = getComputedStyle(sk); return { img: c.backgroundImage.slice(0,40), filt: c.filter,
                        outClass: document.querySelector('.panel[data-id=p1]').className }; }""")
                    notes.append('eliminado: ' + json.dumps(st, ensure_ascii=False))
                    if st['img'] == 'none': bad.append('o card eliminado perdeu a arte')
                    page.screenshot(path=str(ROOT/'probe-arte-eliminado.png'))
                    page.click('.panel[data-id=p1] .revive'); page.click('[data-act=revive]')
                    page.screenshot(path=str(ROOT/'probe-arte-4j.png'))
        page.set_viewport_size(LAND)
        b.close()
    print(json.dumps({'problemas': bad, 'notas': notes, 'erros_js': errs}, ensure_ascii=False, indent=1))

main()
