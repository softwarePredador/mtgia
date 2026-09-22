#!/usr/bin/env python3
"""Mede uma captura do aparelho: onde está o numeral dentro de cada card, e se algo encosta na borda.

Uso: python3 tools/shot_check.py proofs/ios/<nome>.png
Trabalha sobre a imagem já girada (mesa legível). Segmenta os cards pelos vãos escuros entre eles,
acha a maior mancha clara de cada card (o numeral) e compara o centro dela com o centro do card.
"""
import sys, pathlib
from collections import deque
from PIL import Image

IVORY = lambda px: px[0] > 195 and px[1] > 185 and px[2] > 160          # marfim do numeral
DARK  = lambda px: px[0] < 45 and px[1] < 45 and px[2] < 50             # vão entre os cards

def faixas(escuro, limite):
    """Índices onde a linha/coluna é majoritariamente escura viram fronteira entre cards."""
    corte, blocos, ini = [i for i, v in enumerate(escuro) if v >= limite], [], None
    for i in range(len(escuro)):
        if i in set(corte):
            if ini is not None: blocos.append((ini, i)); ini = None
        elif ini is None: ini = i
    if ini is not None: blocos.append((ini, len(escuro)))
    return [b for b in blocos if b[1] - b[0] > len(escuro) * .12]

def numeral(im, x0, y0, x1, y1):
    """Caixa do numeral: os dígitos são manchas separadas, então junta as da mesma linha de texto."""
    px = im.load()
    visto, comps = set(), []
    passo = 2                                                           # amostragem: rápido e suficiente
    for y in range(y0 + 4, y1 - 4, passo):
        for x in range(x0 + 4, x1 - 4, passo):
            if (x, y) in visto or not IVORY(px[x, y]): continue
            fila, comp = deque([(x, y)]), []
            visto.add((x, y))
            while fila:
                cx, cy = fila.popleft(); comp.append((cx, cy))
                for dx, dy in ((passo, 0), (-passo, 0), (0, passo), (0, -passo)):
                    nx, ny = cx + dx, cy + dy
                    if x0 < nx < x1 and y0 < ny < y1 and (nx, ny) not in visto and IVORY(px[nx, ny]):
                        visto.add((nx, ny)); fila.append((nx, ny))
            bb = (min(p[0] for p in comp), min(p[1] for p in comp), max(p[0] for p in comp), max(p[1] for p in comp))
            comps.append((len(comp), bb))
    if not comps: return None
    comps.sort(reverse=True)
    _, (ax0, ay0, ax1, ay1) = comps[0]
    alto = ay1 - ay0
    caixa = [ax0, ay0, ax1, ay1]
    for area, (bx0, by0, bx1, by1) in comps[1:]:
        if area < comps[0][0] * .2: continue                            # letrinha de nome/chip fica de fora
        if abs((by1 - by0) - alto) > alto * .3: continue                # outra altura = outro texto
        if min(by1, caixa[3]) - max(by0, caixa[1]) < alto * .5: continue # linha de texto diferente
        if min(abs(bx0 - caixa[2]), abs(caixa[0] - bx1)) > alto * .9: continue  # longe demais para ser o vizinho
        caixa = [min(caixa[0], bx0), min(caixa[1], by0), max(caixa[2], bx1), max(caixa[3], by1)]
    return caixa

def main(caminho):
    im = Image.open(caminho).convert('RGB')
    W, H = im.size
    px = im.load()
    lin_escura = [sum(1 for x in range(0, W, 6) if DARK(px[x, y])) for y in range(H)]
    lins = faixas(lin_escura, len(range(0, W, 6)) * .92)
    # as fileiras podem ter contagens diferentes (arranjo 3+1), então cada uma tem a sua própria grade
    colunas = []
    for y0, y1 in lins:
        amostra = range(y0 + 2, y1 - 2, 6) or range(y0, y1)
        col = [sum(1 for y in amostra if DARK(px[x, y])) for x in range(W)]
        colunas.append(faixas(col, len(list(amostra)) * .92))
    print(f'{pathlib.Path(caminho).name}: {W}x{H} · {len(lins)} fileira(s) de '
          f'{"+".join(str(len(c)) for c in colunas)} card(s)')
    problemas = []
    for li, (y0, y1) in enumerate(lins):
        for ci, (x0, x1) in enumerate(colunas[li]):
            caixa = numeral(im, x0, y0, x1, y1)
            cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
            if not caixa:
                print(f'  card [{li}][{ci}] {x1-x0}x{y1-y0}: sem numeral visível (face de marcadores/eliminado?)')
                continue
            bx0, by0, bx1, by1 = caixa
            dx, dy = (bx0 + bx1) / 2 - cx, (by0 + by1) / 2 - cy
            folga = min(bx0 - x0, x1 - bx1, by0 - y0, y1 - by1)
            alt = (by1 - by0) / (y1 - y0) * 100
            print(f'  card [{li}][{ci}] {x1-x0}x{y1-y0}: numeral desvia {dx:+.0f},{dy:+.0f} px do centro · '
                  f'altura {alt:.0f}% do card · folga até a borda {folga:.0f} px')
            if abs(dx) > max(6, (x1 - x0) * .02): problemas.append(f'card [{li}][{ci}] fora do centro em x ({dx:+.0f})')
            if abs(dy) > max(6, (y1 - y0) * .03): problemas.append(f'card [{li}][{ci}] fora do centro em y ({dy:+.0f})')
            if folga < 4: problemas.append(f'card [{li}][{ci}] numeral encostando na borda ({folga:.0f} px)')
    print('PROBLEMAS:', '; '.join(problemas) if problemas else 'nenhum')
    return 1 if problemas else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
