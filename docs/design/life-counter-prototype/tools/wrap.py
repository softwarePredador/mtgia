"""Wrap the artifact body in a minimal document (the publish step does the same) -> serve/index.html"""
import pathlib, re, subprocess, sys
root = pathlib.Path(__file__).resolve().parent.parent
body = (root / 'mesa-brewtact.html').read_text(encoding='utf-8')
# guard: every @container/@media override must come after the base rule of each selector it touches
css = re.search(r'<style>(.*?)</style>', body, re.S).group(1)
marker = css.index('Overrides. Keep every')
base, over = css[:marker], css[marker:]
bad = []
for sel in set(re.findall(r'^\s{4}(\.[\w.\- >:\[\]="]+?)\s*\{', over, re.M)):
    first = sel.split(',')[0].strip()
    if re.search(r'^\s{2}' + re.escape(first) + r'\s*\{', over.split('@', 1)[0], re.M):
        continue
    if not re.search(r'^\s{2}' + re.escape(first) + r'[\s,{]', base, re.M):
        bad.append(first)
if bad: print('WARN overrides without an earlier base rule:', sorted(bad))
js = re.search(r'<script>(.*)</script>', body, re.S).group(1)
(root / '_check.js').write_text(js, encoding='utf-8')
r = subprocess.run(['node', '--check', str(root / '_check.js')], capture_output=True, text=True)
(root / '_check.js').unlink()
if r.returncode: print(r.stderr); sys.exit(1)
doc = ('<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">'
       '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
       '<style>body{margin:0}[hidden]{display:none!important}</style></head><body>' + body + '</body></html>')
(root / 'serve').mkdir(exist_ok=True)
(root / 'serve' / 'index.html').write_text(doc, encoding='utf-8')
print('wrapped', len(doc), 'bytes; js syntax ok')
