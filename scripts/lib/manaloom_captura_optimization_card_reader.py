"""Captura `optimization-card-reader-web`: o leitor de carta da otimização.

O contrato pede build Web real a 1280x720 com hover de mouse, clique e Escape
FÍSICO. `flutter drive` não serve: a arte da carta na web é um `<img>` de
plataforma (`app/lib/core/widgets/cached_card_image.dart`), e é justamente esse
caminho que o pacote existe para provar — evento sintético de widget passa por
cima dele.

Os dois checkpoints:

1. `01_hover_card`   hover real sobre a linha da sugestão abre a prévia da carta
2. `02_full_reader`  o botão "Ver carta X" abre o leitor, com Escape fechando

O que torna este pacote possível é a D-82: sem provedor de IA, a rota
`/ai/optimize` passou a servir as trocas determinísticas (só PostgreSQL) em vez
da prévia não acionável. Antes disso não havia sugestão na tela, logo não havia
botão `optimize-suggestion-add-0-preview-button` e o leitor nunca abria.

O deck vem de `scripts/lib/manaloom_seed_deck_otimizavel.sql`, que semeia 100
cartas com ids fixos mais um pool de 12 candidatos FORA do deck — sem material
de adição a shortlist sai vazia e a rota volta ao mock.

SÓ RODA CONTRA A API DO E2E ISOLADO (`MANALOOM_E2E_ISOLATED_RUNTIME=1`, com o
token de validação da corrida e `ENVIRONMENT` development ou test). Fora dele
não há o que capturar, e não é defeito deste roteiro:

* a política de capabilities da beta deixa `ai_analyze_optimize_advisory`
  desligada, e só o runtime isolado aceita a política temporária que a liga
  (`server/lib/release_capability_policy.dart`); sem ela a folha de
  otimização não abre;
* o seed aponta a arte para o servidor de assets loopback da fixture, e só no
  runtime isolado o servidor mantém URL de `127.0.0.1` em vez de derivar uma
  URL do CDN público (`docs/MANALOOM_CARD_ART_SOURCE_CACHE_AND_RIGHTS_CONTRACT.md`);
  fora dele a captura mostraria o placeholder no lugar da arte.

Os binários chegam por argumento. Passe os do pin: `resolver_binarios`, em
`manaloom_webdriver_capture.py`, devolve o Chrome de `CHROME_EXECUTABLE` e o
ChromeDriver de `scripts/lib/manaloom_chromedriver.sh`.

Uso:

    python3 scripts/lib/manaloom_captura_optimization_card_reader.py \\
      <porta-webdriver> <destino> <web-url> <deck-id> <email> <senha> \\
      <chrome> <chromedriver> <saida-console>
"""

from __future__ import annotations

import sys
import time

CHECKPOINTS = ("01_hover_card", "02_full_reader")

_FOLHAS = r"""
    return [...document.querySelectorAll('flt-semantics')]
      .filter(e => e.children.length <= 1)
      .map(e => {
        const r = e.getBoundingClientRect();
        return {t: (e.textContent || '').trim(),
                al: e.getAttribute('aria-label') || '',
                x: Math.round(r.x + r.width / 2),
                y: Math.round(r.y + r.height / 2),
                w: Math.round(r.width), h: Math.round(r.height)};
      })
      .filter(o => (o.t || o.al) && o.w > 0 && o.h > 0);
"""


def folhas(nav) -> list[dict]:
    return nav.js(_FOLHAS) or []


def texto_da_tela(nav) -> str:
    return "\n".join(f"{o['t']} {o['al']}".strip() for o in folhas(nav))


def achar(nav, *trechos: str, altura_max: int = 400) -> dict | None:
    alvos = [t.lower() for t in trechos]
    melhor = None
    for o in folhas(nav):
        if o["h"] > altura_max:
            continue
        combinado = f"{o['t']} {o['al']}".lower()
        if any(t in combinado for t in alvos):
            if melhor is None or o["w"] * o["h"] < melhor["w"] * melhor["h"]:
                melhor = o
    return melhor


def esperar(nav, *trechos: str, segundos: float = 30.0, altura_max: int = 400):
    limite = time.time() + segundos
    while time.time() < limite:
        o = achar(nav, *trechos, altura_max=altura_max)
        if o is not None:
            return o
        time.sleep(0.6)
    return None


def clicar(nav, *trechos: str, altura_max: int = 200) -> bool:
    """Clica rolando antes, com a roda sobre a coluna do próprio alvo."""
    for _ in range(9):
        o = achar(nav, *trechos, altura_max=altura_max)
        if o is None:
            return False
        if 60 <= o["y"] <= nav.altura - 60:
            nav.clicar_ponto(o["x"], o["y"])
            return True
        x = min(max(o["x"], 40), nav.largura - 40)
        nav.rolar(x, nav.altura // 2, 240 if o["y"] > nav.altura else -240)
        time.sleep(0.6)
    return False


def entrar(nav, web: str, email: str, senha: str) -> None:
    nav.ir(f"{web}/", espera=12)
    campos = nav.js(
        "return [...document.querySelectorAll('input')].map(e => {"
        "  const b = e.getBoundingClientRect();"
        "  return {al: e.getAttribute('aria-label'),"
        "          x: Math.round(b.x + b.width / 2),"
        "          y: Math.round(b.y + b.height / 2)};"
        "});"
    )
    if not campos:
        return
    for c in campos:
        nav.clicar_ponto(c["x"], c["y"])
        time.sleep(0.4)
        nav.digitar(email if (c["al"] or "").lower().startswith("e") else senha)
    nav.clicar_texto("Entrar")
    time.sleep(10)


def _linhas_de_sugestao(nav) -> list[dict]:
    """As LINHAS de sugestão, cada uma contendo o botão "Ver carta".

    Medido em 2026-09-28: a folha e a linha inteira (506x107), com o rotulo do
    botao embutido no texto -- "Ver carta\nPresagio de Prova 23 • ALTA 90%...".
    Duas cicatrizes desta medicao:

    * eu filtrava por altura <= 80 e as linhas tem 107, entao nenhuma passava;
    * elas nascem abaixo da dobra (y ~1384 num viewport de 720), entao e
      preciso rolar de verdade antes de interagir.
    """
    return [
        o
        for o in folhas(nav)
        if "ver carta" in f"{o['t']} {o['al']}".lower()
        and 60 <= o["h"] <= 170
        and o["w"] >= 200
    ]


def _trazer_para_a_vista(nav, indice: int = 0) -> dict:
    """Rola ate a linha de sugestao ficar visivel e devolve a folha medida."""
    from manaloom_webdriver_capture import ErroDeCaptura

    for _ in range(14):
        linhas = _linhas_de_sugestao(nav)
        if not linhas:
            raise ErroDeCaptura("nenhuma linha de sugestao na tela")
        alvo = linhas[min(indice, len(linhas) - 1)]
        if 120 <= alvo["y"] <= nav.altura - 120:
            return alvo
        nav.rolar(640, nav.altura // 2,
                  300 if alvo["y"] > nav.altura else -300)
        time.sleep(0.8)
    raise ErroDeCaptura("nao consegui trazer a linha de sugestao para a vista")


def abrir_sugestoes(nav, web: str, deck: str, registrar) -> None:
    from manaloom_webdriver_capture import ErroDeCaptura

    nav.ir(f"{web}#/decks/{deck}", espera=14)
    if not clicar(nav, "Otimizar"):
        raise ErroDeCaptura(
            f"nao achei o botao 'Otimizar' no deck. Tela:\n{texto_da_tela(nav)[:700]}"
        )
    if esperar(nav, "Otimizar Deck", segundos=40) is None:
        raise ErroDeCaptura(
            f"a folha de otimizacao nao abriu. Tela:\n{texto_da_tela(nav)[:700]}"
        )
    tela = texto_da_tela(nav)
    if "Servidor indisponível" in tela or "Tentar Novamente" in tela:
        raise ErroDeCaptura(
            "a folha abriu em erro de servidor. Com a chave VAZIA o "
            "/ai/archetypes deve servir o mock; se este erro aparecer, a "
            f"corrida esta com chave configurada. Tela:\n{tela[:500]}"
        )
    registrar("folha de otimizacao aberta")

    if not clicar(nav, "Ver sugestões", altura_max=260):
        raise ErroDeCaptura(
            f"nao achei um plano para abrir. Tela:\n{texto_da_tela(nav)[:700]}"
        )
    if esperar(nav, "Ver carta", segundos=120, altura_max=170) is None:
        raise ErroDeCaptura(
            "nenhuma sugestao apareceu depois de escolher o plano. Sem "
            "sugestao nao existe leitor. Isso indica shortlist vazia ou "
            f"resposta mock. Tela:\n{texto_da_tela(nav)[:700]}"
        )
    registrar("sugestoes renderizadas")


def cp01_hover(nav, destino: str, registrar) -> dict:
    """Hover REAL sobre a linha da sugestão abre a prévia da carta."""
    from manaloom_webdriver_capture import ErroDeCaptura

    alvo = _trazer_para_a_vista(nav, 0)
    antes = nav.js(
        "return [...document.querySelectorAll('img')]"
        "  .filter(i => i.complete && i.naturalWidth > 0).length;"
    )
    # Passa o ponteiro na LINHA, à esquerda do botão: o MouseRegion que abre a
    # prévia envolve a linha inteira, e parar sobre o botão é outra coisa.
    esquerda = alvo["x"] - alvo["w"] // 2 + 90
    nav.passar_mouse(max(esquerda, 40), alvo["y"], parar_ms=1400)
    time.sleep(2)
    depois = nav.js(
        "return [...document.querySelectorAll('img')]"
        "  .filter(i => i.complete && i.naturalWidth > 0).length;"
    )
    if depois <= antes:
        raise ErroDeCaptura(
            f"o hover nao trouxe arte nova ({antes} -> {depois} imagens "
            "carregadas); sem isso a captura nao prova a previa por hover"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[0]}.png")
    registrar(f"{CHECKPOINTS[0]}: hover real, imagens {antes} -> {depois}")
    return alvo


def cp02_leitor(nav, destino: str, alvo: dict, registrar) -> None:
    """Botão abre o leitor; Escape FÍSICO fecha só o leitor."""
    from manaloom_webdriver_capture import ErroDeCaptura

    # O botao do leitor e um IconButton na ponta direita da linha; clicar no
    # centro acerta a linha (que alterna a selecao), nao o botao.
    alvo = _trazer_para_a_vista(nav, 0)
    direita = alvo["x"] + alvo["w"] // 2 - 28
    nav.clicar_ponto(min(direita, nav.largura - 20), alvo["y"])
    # A barreira do leitor e `Positioned.fill`: a folha dela ocupa a tela
    # inteira (1280x720). Procurar com limite de altura NUNCA a acha -- o erro
    # dizia "o leitor nao abriu" enquanto o proprio texto da tela comecava com
    # "Fechar leitura da carta". Aqui a conferencia e pelo TEXTO.
    limite = time.time() + 30
    while time.time() < limite:
        if "Fechar leitura da carta" in texto_da_tela(nav):
            break
        time.sleep(0.6)
    else:
        raise ErroDeCaptura(
            "o leitor de carta nao abriu depois do clique no botao. Tela:\n"
            f"{texto_da_tela(nav)[:700]}"
        )
    time.sleep(2)
    nav.capturar(f"{destino}/{CHECKPOINTS[1]}.png")
    registrar(f"{CHECKPOINTS[1]}: leitor aberto")

    nav.teclar("Escape")
    time.sleep(2)
    if "Fechar leitura da carta" in texto_da_tela(nav):
        raise ErroDeCaptura("Escape fisico nao fechou o leitor")
    if not _linhas_de_sugestao(nav):
        raise ErroDeCaptura(
            "depois do Escape as sugestoes sumiram; o contrato diz que ele "
            "fecha SO o leitor e preserva a decisao embaixo"
        )
    registrar("Escape fisico fechou o leitor e preservou as sugestoes")


_ARGUMENTOS = (
    "porta-webdriver", "destino", "web-url", "deck-id", "email", "senha",
    "chrome", "chromedriver", "saida-console",
)


def _ler_argumentos(argv: list[str]) -> tuple[int, list[str]] | None:
    """Confere o argv antes de tocar em navegador; `None` se nao servir.

    Antes, `sys.argv[1:10]` era desempacotado direto: argumento a menos
    (ou a mais) virava `ValueError` com traceback, e uma porta nao numerica,
    outro traceback no `int(porta)`. Agora a falha e de uso: mensagem curta,
    o modo de uso e codigo 2.
    """
    valores = argv[1:]
    if len(valores) != len(_ARGUMENTOS):
        print(
            f"FALHA: esperados {len(_ARGUMENTOS)} argumentos "
            f"({' '.join(f'<{a}>' for a in _ARGUMENTOS)}), recebidos "
            f"{len(valores)}.",
            file=sys.stderr,
        )
        print(__doc__, file=sys.stderr)
        return None
    try:
        porta = int(valores[0])
    except ValueError:
        porta = 0
    if not 0 < porta < 65536:
        print(
            f"FALHA: <porta-webdriver> precisa ser uma porta TCP (1-65535), "
            f"recebido {valores[0]!r}.",
            file=sys.stderr,
        )
        return None
    return porta, valores[1:]


def main() -> int:
    lidos = _ler_argumentos(sys.argv)
    if lidos is None:
        return 2
    porta, (destino, web, deck, email, senha, chrome, chromedriver,
            saida_console) = lidos

    sys.path.insert(0, __file__.rsplit("/", 1)[0])
    from manaloom_webdriver_capture import ChromeDriver, ErroDeCaptura, Navegador

    with ChromeDriver(chromedriver, porta):
        nav = Navegador(porta, 1280, 720)
        try:
            nav.abrir(chrome)
            entrar(nav, web, email, senha)
            abrir_sugestoes(nav, web, deck, print)
            alvo = cp01_hover(nav, destino, print)
            cp02_leitor(nav, destino, alvo, print)
        except ErroDeCaptura as e:
            print(f"FALHA: {e}", file=sys.stderr)
            return 1
        finally:
            # O console vira o log de runtime da evidencia: o indexador confere
            # excecoes, overflow de RenderFlex e falha de CachedCardImage. Sem
            # esta coleta nao daria para afirmar `forbidden_entries: 0`.
            try:
                linhas = nav.console()
                with open(saida_console, "w", encoding="utf-8") as fh:
                    for m in linhas:
                        fh.write(f"[{m.get('level')}] {m.get('message')}\n")
                print(f"console do navegador: {len(linhas)} mensagens")
            except Exception as erro:
                print(f"nao consegui ler o console: {erro}", file=sys.stderr)
            nav.fechar()
    print(f"optimization-card-reader-web: {len(CHECKPOINTS)} checkpoints capturados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
