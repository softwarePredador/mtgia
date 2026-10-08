"""Captura `card-details-navigation-web` com histórico real de navegador.

O contrato deste pacote exige "real pointer activation and browser history
navigation". `flutter drive` não serve: ele toca widgets e navega pelo router,
sem passar pelo histórico do navegador — que é justamente o que o pacote prova.

Fluxo, medido em 2026-09-24 contra a fixture autenticada:

1. deck → aba "Cartas" → clique na linha da carta abre a prévia
   (`01_deck_card_preview_modal`);
2. "Ver Detalhes" leva à rota de detalhes, e a prévia precisa sumir
   (`02_full_details_without_modal`);
3. **voltar pelo navegador** devolve ao deck, e a prévia NÃO pode ressurgir
   (`03_back_to_deck_without_modal`).

O passo 3 é o ponto. Um modal restaurado pelo histórico é um defeito clássico de
web, e só aparece com `history.back` de verdade.

As posições de clique são medidas na própria tela quando a árvore de semântica
não publica o elemento — o CanvasKit desenha a linha da carta sem expô-la. Isso
é aceitável aqui porque o contrato pede ponteiro real numa posição real; o que
não seria aceitável é presumir a posição sem conferir o que há nela. Por isso
o ponto de reserva da aba "Cartas" só é usado depois de o rótulo do menor nó
de semântica naquele ponto ser exatamente "Cartas" (igualdade depois de
normalizar espaços, não "contém"); se não for, a corrida aborta.

Uso (o Chrome é `CHROME_EXECUTABLE`; o ChromeDriver vem do pin de
`scripts/lib/manaloom_chromedriver.sh` e vive só durante a corrida):

    python3 scripts/lib/manaloom_captura_card_details_navigation.py \\
      <porta-webdriver> <destino> <app-url> <deck-id> <email> <senha> \\
      <saida-console>
"""

from __future__ import annotations

import os
import sys
import time

# Geometria conhecida da aba "Cartas" na tela de deck a 1280x720, conferida
# por captura. So vale depois de conferido o texto no ponto.
_RESERVA_ABA_CARTAS = (608, 79)

CHECKPOINTS = (
    "01_deck_card_preview_modal",
    "02_full_details_without_modal",
    "03_back_to_deck_without_modal",
)


def _entrar(nav, app: str, email: str, senha: str) -> None:
    nav.ir(f"{app}/", espera=10)
    campos = nav.js(
        "return [...document.querySelectorAll('input')].map(e => {"
        "  const b = e.getBoundingClientRect();"
        "  return {al: e.getAttribute('aria-label'),"
        "          x: Math.round(b.x + b.width / 2),"
        "          y: Math.round(b.y + b.height / 2)};"
        "});"
    )
    if not campos:
        return  # já autenticado
    for c in campos:
        nav.clicar_ponto(c["x"], c["y"])
        time.sleep(0.4)
        alvo = email if (c["al"] or "").lower().startswith("e") else senha
        nav.digitar(alvo)
    nav.clicar_texto("Entrar")
    time.sleep(9)


def _normalizar_espacos(texto: str) -> str:
    return " ".join(texto.split())


def rotulo_e_aba_cartas(aria_label: str, texto: str) -> bool:
    """O menor nó no ponto de reserva é a aba "Cartas", e só ela.

    Igualdade EXATA depois de normalizar espaços, não "contém": "Cartas" dentro
    de "Cartas do deck", "Sem cartas" ou de um contêiner que junta a barra de
    abas inteira não prova que o ponto é a aba. O nó pode publicar o rótulo em
    `aria-label`, no texto, ou nos dois; todo rótulo publicado precisa ser
    exatamente "Cartas", e pelo menos um precisa existir.
    """
    publicados = {
        normalizado
        for normalizado in (
            _normalizar_espacos(aria_label),
            _normalizar_espacos(texto),
        )
        if normalizado
    }
    return publicados == {"Cartas"}


def _centro_da_aba_cartas(nav) -> tuple[int, int]:
    """Mede a aba em vez de fixar coordenada."""
    from manaloom_webdriver_capture import ErroDeCaptura

    achado = nav.js(
        r"""
        const alvo = [...document.querySelectorAll('flt-semantics')]
          .map(e => ({e, r: e.getBoundingClientRect(),
                      t: (e.textContent || '').trim()}))
          .filter(o => o.e.children.length <= 1)
          .filter(o => o.t === 'Cartas' && o.r.height > 10 && o.r.height < 80);
        if (!alvo.length) return null;
        const r = alvo[0].r;
        return [Math.round(r.x + r.width / 2), Math.round(r.y + r.height / 2)];
        """
    )
    if achado:
        return tuple(achado)
    # A barra de abas nem sempre publica semântica como folha. O ponto de
    # reserva só vale se o rótulo do MENOR nó de semântica que cobre aquele
    # ponto for exatamente "Cartas" (`rotulo_e_aba_cartas`): clicar numa
    # coordenada sem conferir o que há nela seria presumir a posição, e a
    # captura provaria a aba errada sem ninguém notar.
    x, y = _RESERVA_ABA_CARTAS
    no = nav.js(
        r"""
        const x = arguments[0], y = arguments[1];
        const cobrem = [...document.querySelectorAll('flt-semantics')]
          .map(e => ({e, r: e.getBoundingClientRect()}))
          .filter(o => o.r.left <= x && x <= o.r.right
                       && o.r.top <= y && y <= o.r.bottom
                       && o.r.width * o.r.height > 0);
        if (!cobrem.length) return null;
        cobrem.sort((a, b) => a.r.width * a.r.height - b.r.width * b.r.height);
        const e = cobrem[0].e;
        return {al: e.getAttribute('aria-label') || '',
                t: e.textContent || ''};
        """,
        x,
        y,
    )
    if not isinstance(no, dict):
        no = {}
    rotulo = (no.get("al") or "", no.get("t") or "")
    if not rotulo_e_aba_cartas(*rotulo):
        raise ErroDeCaptura(
            "a aba 'Cartas' nao publicou semantica, e o ponto de reserva "
            f"({x},{y}) mostra {' / '.join(r for r in rotulo if r)[:80]!r} "
            "em vez de exatamente 'Cartas'; clicar ali seria presumir a "
            "posicao"
        )
    return (x, y)


def _primeira_carta(nav) -> tuple[int, int] | None:
    """Localiza a primeira linha de carta pela imagem de arte que ela contém."""
    return nav.js(
        r"""
        const imgs = [...document.querySelectorAll('img')]
          .map(e => e.getBoundingClientRect())
          .filter(r => r.width > 40 && r.width < 120 && r.height > 60
                       && r.y > 300 && r.y < 700);
        if (!imgs.length) return null;
        imgs.sort((a, b) => a.y - b.y);
        const r = imgs[0];
        return [Math.round(r.x + r.width / 2 + 240), Math.round(r.y + r.height / 2)];
        """
    )


def capturar(nav, destino: str, app: str, deck: str, email: str, senha: str) -> None:
    from manaloom_webdriver_capture import ErroDeCaptura

    _entrar(nav, app, email, senha)
    nav.ir(f"{app}/#/decks/{deck}", espera=9)

    x, y = _centro_da_aba_cartas(nav)
    nav.clicar_ponto(x, y)
    time.sleep(4)

    carta = _primeira_carta(nav)
    if carta is None:
        raise ErroDeCaptura("nenhuma linha de carta encontrada na aba Cartas")
    nav.clicar_ponto(carta[0], carta[1])
    time.sleep(3)

    if not nav.js(
        "return [...document.querySelectorAll('flt-semantics')]"
        "  .some(e => (e.textContent || '').includes('Ver Detalhes'));"
    ):
        raise ErroDeCaptura("a prévia da carta não abriu")
    nav.capturar(f"{destino}/{CHECKPOINTS[0]}.png")

    url_deck = nav.url()
    r = nav.clicar_texto("Ver Detalhes")
    if not r.get("ok"):
        raise ErroDeCaptura("'Ver Detalhes' não foi encontrado na prévia")
    time.sleep(5)

    if nav.url() == url_deck:
        raise ErroDeCaptura(
            "'Ver Detalhes' não mudou a rota; sem rota nova não há histórico "
            "para voltar, e o pacote perde o que prova"
        )
    if nav.js(
        "return [...document.querySelectorAll('flt-semantics')]"
        "  .some(e => (e.textContent || '').includes('Ver Detalhes'));"
    ):
        raise ErroDeCaptura("a prévia continuou na tela de detalhes")
    nav.capturar(f"{destino}/{CHECKPOINTS[1]}.png")

    # O ponto do pacote: histórico REAL, não `context.pop()`.
    nav.voltar(espera=5)
    if nav.url() != url_deck:
        raise ErroDeCaptura(
            f"voltar levou a {nav.url()}, esperado {url_deck}"
        )
    if nav.js(
        "return [...document.querySelectorAll('flt-semantics')]"
        "  .some(e => (e.textContent || '').includes('Ver Detalhes'));"
    ):
        raise ErroDeCaptura(
            "a prévia ressurgiu ao voltar pelo navegador -- é exatamente o "
            "defeito que este pacote existe para flagrar"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[2]}.png")


def main() -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from manaloom_webdriver_capture import (
        ChromeDriver,
        ErroDeCaptura,
        Navegador,
        resolver_binarios,
    )

    if len(sys.argv) != 8:
        print(__doc__, file=sys.stderr)
        return 2
    porta, destino, app, deck, email, senha, saida_console = sys.argv[1:8]
    # Sem barra final: as rotas sao montadas como `{app}/#/decks/...`.
    app = app.rstrip("/")

    try:
        chrome, chromedriver = resolver_binarios()
    except ErroDeCaptura as e:
        print(f"FALHA: {e}", file=sys.stderr)
        return 2

    # O driver vive so durante a corrida: nada de ChromeDriver de pe entre
    # capturas, que e o que deixa um navegador sobreviver sem ninguem notar.
    with ChromeDriver(chromedriver, int(porta)):
        nav = Navegador(int(porta), 1280, 720)
        try:
            nav.abrir(chrome)
            print(f"navegador da corrida (D-80): {nav.navegador_real}")
            capturar(nav, destino, app, deck, email, senha)
        except ErroDeCaptura as e:
            print(f"FALHA: {e}", file=sys.stderr)
            return 1
        finally:
            # O console vira o log de runtime da evidencia: o indexador confere
            # excecao, overflow de RenderFlex e falha de CachedCardImage.
            try:
                total = nav.gravar_console(saida_console)
                print(f"console do navegador: {total} mensagens")
            except Exception as erro:
                print(f"nao consegui ler o console: {erro}", file=sys.stderr)
            nav.fechar()
    print(f"card-details-navigation-web: {len(CHECKPOINTS)} checkpoints capturados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
