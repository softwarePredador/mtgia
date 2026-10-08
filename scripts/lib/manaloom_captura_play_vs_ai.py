"""Captura `play-vs-ai-web-real`: partida real contra o motor XMage local.

O contrato do pacote exige build Web real a 1440x900 e uma partida contra o
motor pinado — não uma tela montada com dados falsos. O harness
`scripts/manaloom_play_vs_ai_e2e.sh` com `MANALOOM_PLAY_VS_AI_BROWSER_QA=1`
sobe PostgreSQL descartável, os dois sidecars XMage, a API e o build Web,
semeia os decks e então segura por uma hora esperando as nove capturas e a
atestação. Este roteiro é a parte do navegador; os decks, o comandante e o
adversário são os que o harness semeia, e chegam aqui por argumento.

Procedência (D-80): este roteiro não nomeia agente nem navegador. Ele imprime
o navegador REAL da sessão WebDriver (nome, versão e modo headless), para quem
conduz a corrida declarar em `MANALOOM_PLAY_VS_AI_BROWSER_NAME` o que de fato
usou. A atestação e a revisão visual continuam fora daqui: o roteiro não as
escreve.

Uso (o Chrome é `CHROME_EXECUTABLE`; o ChromeDriver vem do pin de
`scripts/lib/manaloom_chromedriver.sh`):

    python3 scripts/lib/manaloom_captura_play_vs_ai.py \\
      <porta-webdriver> <destino> <web-url> <deck-id> <deck-adversario> \\
      <comandante> <email> <senha> <saida-sessao> <api-url> <saida-console>

Por que não `flutter drive`: os checkpoints 06 e 09 provam recarregar a página e
voltar pelo histórico do navegador. Evento sintético de widget não passa por ali.

As nove provas, e o que cada uma ASSERTA antes de virar arquivo:

1. `01-opponent-picker`         diálogo aberto com o deck adversário na lista
2. `02-private-hand-mulligan`   prompt de mão inicial com a própria mão visível
3. `03-land-played`             o aviso de campo vazio sai do MEU campo
4. `04-commander-cast`          comandante na metade de baixo da mesa
5. `05-combat-damage`           um total de vida abaixo do inicial
6. `06-reconnected-session`     a MESMA mesa de volta depois de recarregar
7. `07-terminal-replay-rematch` painel terminal com replay e revanche
8. `08-replay`                  replay aberto
9. `09-rematch-picker`          seletor aberto de novo, para a revanche

A regra que manda aqui é a cicatriz do harness: quatro capturas falsas saíram
num único dia porque o código conferia que o passo aconteceu, não o que estava
na tela. Cada checkpoint confere a tela e aborta a corrida em vez de gravar um
PNG que não prova nada.

CICATRIZES DESTA SESSÃO (2026-09-28), todas medidas:

* A partida roda numa passagem só. Fechar o navegador entre checkpoints deixa a
  sessão expirar — cada decisão tem 60 segundos — e a mesa vira
  "Sessão abandonada".
* A rolagem é roda de mouse real e acontece sobre a coluna DO ALVO. `scrollTop`
  não move CanvasKit, e rolar num x fixo só servia ao painel de decisão: na tela
  de boas-vindas, cujo cartão é centrado, aquela roda não rolava nada.
* A linha da opção e a miniatura dentro dela têm o mesmo texto. Escolher pela
  menor área pega a miniatura, que abre a prévia em vez de jogar a carta.
* O primeiro prompt da mesa não é o mulligan: é "Escolha um alvo" (quem começa).
* Leitura de vida e de campo vazio casa de forma ESTRITA. Casar por substring
  pegava uma folha grande que começa com "Turno 1" e continha "pontos de vida",
  e o primeiro número extraído era o 1 do turno.
* "Jogar novamente" só navega (`_playAgain` faz `context.go`); não abre o
  seletor. E a rota sem sessão reexibe a mesa encerrada até o servidor expirá-la.
"""

from __future__ import annotations

import os
import re
import sys
import time

CHECKPOINTS = (
    "01-opponent-picker",
    "02-private-hand-mulligan",
    "03-land-played",
    "04-commander-cast",
    "05-combat-damage",
    "06-reconnected-session",
    "07-terminal-replay-rematch",
    "08-replay",
    "09-rematch-picker",
)

TITULO_SELETOR = "Escolha o adversário controlado pela IA"

# Leitura de semântica: só folhas. Um contêiner de tela inteira traz no
# `textContent` tudo que existe, e foi assim que nasceram três capturas
# mentirosas — uma delas rotulada `03-land-played` numa tela que dizia
# "Nenhuma permanente no campo".
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
    """Menor folha cujo texto ou rótulo contém um dos trechos."""
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


def clicar(nav, *trechos: str, altura_max: int = 140) -> bool:
    """Clica rolando antes, com a roda sobre a coluna do próprio alvo."""
    for _ in range(9):
        o = achar(nav, *trechos, altura_max=altura_max)
        if o is None:
            return False
        if 60 <= o["y"] <= 840:
            nav.clicar_ponto(o["x"], o["y"])
            return True
        x = min(max(o["x"], 40), nav.largura - 40)
        nav.rolar(x, 450, 240 if o["y"] > 840 else -240)
        time.sleep(0.6)
    return False


def _totais_de_vida(nav) -> list[int]:
    """Os dois totais de vida, de cima para baixo: adversário, depois você.

    Casamento ESTRITO: a folha tem de ser só o número e o rótulo.
    """
    achados = nav.js(
        r"""
        return [...document.querySelectorAll('flt-semantics')]
          .filter(e => e.children.length <= 1)
          .map(e => {
            const r = e.getBoundingClientRect();
            return {t: (e.textContent || '').trim(), y: Math.round(r.y)};
          })
          .filter(o => /^-?\d+\s+pontos?\s+de\s+vida$/.test(o.t))
          .sort((a, b) => a.y - b.y)
          .map(o => o.t);
        """
    ) or []
    valores = []
    for texto in achados:
        m = re.match(r"^(-?\d+)", texto)
        if m:
            valores.append(int(m.group(1)))
    return valores


def _meu_campo_vazio(nav) -> bool:
    """Se o campo DE BAIXO (o seu) ainda avisa que não tem permanente."""
    alturas = nav.js(
        r"""
        return [...document.querySelectorAll('flt-semantics')]
          .filter(e => e.children.length <= 1)
          .map(e => {
            const r = e.getBoundingClientRect();
            return {t: (e.textContent || '').trim(), y: Math.round(r.y)};
          })
          .filter(o => o.t === 'Nenhuma permanente no campo')
          .sort((a, b) => a.y - b.y)
          .map(o => o.y);
        """
    ) or []
    # Dois avisos = os dois campos vazios. Um só, abaixo da metade, = o seu.
    return len(alturas) == 2 or any(y > 250 for y in alturas)


def _faixa_do_meu_campo(nav) -> tuple[int, int] | None:
    """Os limites verticais do MEU campo, lidos dos cabeçalhos da própria tela.

    O campo do jogador fica entre o cabeçalho "Você · <deck>" e o cabeçalho
    "Sua mão". Delimitar por número fixo nao serve: a pilha entra e sai, e a
    mesa desloca tudo.
    """
    marcos = nav.js(
        r"""
        return [...document.querySelectorAll('flt-semantics')]
          .filter(e => e.children.length <= 1)
          .map(e => {
            const r = e.getBoundingClientRect();
            return {t: (e.textContent || '').trim(), y: Math.round(r.y)};
          })
          .filter(o => /^Você\s·/.test(o.t) || /^Sua mão/.test(o.t))
          .sort((a, b) => a.y - b.y)
          .map(o => [o.t.slice(0, 12), o.y]);
        """
    ) or []
    topo = next((y for t, y in marcos if t.startswith("Você")), None)
    base = next((y for t, y in marcos if t.startswith("Sua mão")), None)
    if topo is None:
        return None
    return (topo, base if base is not None else 10_000)


def _carta_no_meu_campo(nav, nome: str) -> bool:
    """Uma carta com esse nome esta no MEU campo, como permanente.

    DUAS CICATRIZES de 2026-09-28, as duas achadas abrindo a captura:

    1. Eu procurava o nome em qualquer folha da metade de baixo. O cabecalho do
       meu lado diz "Você · QA Web Isamaru ..." -- o NOME DO DECK contem o nome
       do comandante. A assercao passava com o comandante ainda na zona de
       comando.
    2. Depois eu exigi forma de carta, e passou a casar com a carta NA PILHA:
       o Isamaru aparecia sendo lancado, o painel pedia "Produza mana", e o
       `04-commander-cast` saiu mostrando um Plains no campo.

    Agora a faixa vem dos cabecalhos reais: entre "Você ·" e "Sua mão". A pilha
    fica ACIMA do cabecalho "Você ·" e nao entra.
    """
    faixa = _faixa_do_meu_campo(nav)
    if faixa is None:
        return False
    topo, base = faixa
    achados = nav.js(
        r"""
        const nome = arguments[0].toLowerCase();
        const topo = arguments[1], base = arguments[2];
        return [...document.querySelectorAll('flt-semantics')]
          .filter(e => e.children.length <= 1)
          .map(e => {
            const r = e.getBoundingClientRect();
            return {t: (e.textContent || '').trim(),
                    al: e.getAttribute('aria-label') || '',
                    x: Math.round(r.x), y: Math.round(r.y),
                    w: Math.round(r.width), h: Math.round(r.height)};
          })
          .filter(o => (o.t + ' ' + o.al).toLowerCase().includes(nome)
                       && o.x < 1050 && o.y > topo && o.y < base
                       && o.w >= 30 && o.w <= 220
                       && o.h >= 60 && o.h <= 220)
          .map(o => o.t || o.al);
        """,
        nome, topo, base,
    ) or []
    return len(achados) > 0


def _arte_carregada_no_meu_campo(nav) -> bool:
    """A arte da carta NO MEU CAMPO terminou de carregar.

    A arte na web e um `<img>` de plataforma. Sem esta espera a captura sai com
    o verso de fallback -- medido no `03-land-played`, que mostrou um tile
    escuro enquanto o rotulo ja dizia Plains.

    CICATRIZ de 2026-09-29: a versao antiga perguntava se ALGUMA `<img>` da
    pagina tinha carregado. Com sete cartas na mao carregadas, ela respondia
    sim mesmo com o campo ainda no verso -- e foi exatamente assim que uma
    captura saiu com o placeholder no campo enquanto o log dizia "com arte
    carregada". Agora a pergunta e feita DENTRO da faixa do meu campo.
    """
    faixa = _faixa_do_meu_campo(nav)
    if faixa is None:
        return False
    topo, base = faixa
    return bool(
        nav.js(
            r"""
            const topo = arguments[0], base = arguments[1];
            return [...document.querySelectorAll('img')].some(i => {
              if (!i.complete || !i.naturalWidth) return false;
              const r = i.getBoundingClientRect();
              if (r.width < 20 || r.height < 20) return false;
              const meio = r.y + r.height / 2;
              return meio >= topo && meio <= base;
            });
            """,
            topo,
            base,
        )
    )


def _linha_de_opcao(nav, nome: str) -> dict | None:
    """A LINHA da opção, nunca a miniatura dentro dela.

    As duas contêm o mesmo texto ("Ver prévia de Plains"); a linha tem largura
    de painel, a miniatura tem ~45px. Clicar na miniatura abre a prévia em vez
    de jogar a carta.
    """
    achados = nav.js(
        r"""
        const nome = arguments[0].toLowerCase();
        return [...document.querySelectorAll('flt-semantics')]
          .filter(e => e.children.length <= 1)
          .map(e => {
            const r = e.getBoundingClientRect();
            return {t: (e.textContent || '').trim(),
                    x: Math.round(r.x + r.width / 2),
                    y: Math.round(r.y + r.height / 2),
                    w: Math.round(r.width), h: Math.round(r.height)};
          })
          .filter(o => o.t.toLowerCase().includes(nome) && o.w >= 200
                       && o.h >= 30 && o.h <= 140)
          .sort((a, b) => a.y - b.y);
        """,
        nome,
    ) or []
    return achados[0] if achados else None


def _jogar_carta(nav, nome: str) -> bool:
    for _ in range(9):
        linha = _linha_de_opcao(nav, nome)
        if linha is None:
            return False
        if 60 <= linha["y"] <= 840:
            nav.clicar_ponto(linha["x"], linha["y"])
            return True
        x = min(max(linha["x"], 40), nav.largura - 40)
        nav.rolar(x, 450, 240 if linha["y"] > 840 else -240)
        time.sleep(0.6)
    return False


def capturar_limpo(nav, caminho: str) -> None:
    """Tira o ponteiro da frente antes de fotografar.

    CICATRIZ de 2026-09-29: o `02-private-hand-mulligan` saiu com a previa
    flutuante de um Plains ocupando um quarto da tela, porque o ponteiro tinha
    ficado parado sobre uma carta da mao depois do ultimo clique. A previa e um
    recurso do produto e funciona -- mas ela nao e o estado que o checkpoint
    promete, e quem revisa nao tem como saber disso olhando o PNG.
    """
    nav.passar_mouse(6, 6, parar_ms=900)
    nav.capturar(caminho)


def _terminal(nav) -> bool:
    return achar(nav, "Jogar novamente", altura_max=60) is not None


# Nome do comandante desta corrida. O contrato do E2E exige um evento
# `attacker_declared` com ele no replay, e o automatico da mesa decide sozinho
# -- medido em 2026-09-29, passava o combate inteiro sem atacar e a validacao
# `validate_browser_qa_real_session` derrubava a corrida em silencio, porque o
# harness usa `jq -e` sem mensagem. Por isso o ataque vira escolha explicita.
_COMANDANTE_DA_CORRIDA = ""


# Rotulos que NAO sao declaracao de ataque, ainda que tragam o nome da carta.
# O cabecalho de fase ja diz "Declarar atacantes" enquanto o painel oferece a
# prioridade normal; sem este filtro o roteiro lancaria o comandante achando
# que estava atacando com ele.
#
# CICATRIZ de 2026-09-29: "prévia" estava nesta lista e derrubava justamente a
# linha certa. Medido com a tela na mao: no prompt "Decisão de combate" a
# opcao do comandante se chama "Ver prévia de Isamaru, Hound of Konda" -- esse
# E o rotulo acessivel da LINHA, nao de um botao de prévia separado.
_NAO_E_ATAQUE = ("cast ", "lançar", "lancar", "{t}")


def _tentar_declarar_atacante(nav, nome: str) -> bool:
    """Ataca com <nome> quando a mesa estiver pedindo atacantes.

    Retorna True so quando realmente clicou numa opcao de ataque com esse nome.
    Qualquer outra situacao devolve False para o chamador seguir no automatico.
    """
    if not nome:
        return False
    # O prompt de combate se anuncia pelo titulo "Decisão de combate"
    # (`InteractiveBattleRegistry.java:2418`); a mensagem dele nao fala em
    # atacante nenhum, e foi por isso que a primeira versao desta funcao nunca
    # disparou. O cabecalho de fase diz a ETAPA -- exigir "declarar atacantes"
    # junto garante que estou atacando, e nao bloqueando no turno do rival.
    texto = texto_da_tela(nav).lower()
    if "decis" not in texto or "combate" not in texto:
        return False
    if "declarar atacantes" not in texto:
        return False
    linha = _linha_de_opcao(nav, nome)
    if linha is None or not (60 <= linha["y"] <= 840):
        return False
    rotulo = (linha.get("t") or "").lower()
    if any(trecho in rotulo for trecho in _NAO_E_ATAQUE):
        return False
    nav.clicar_ponto(linha["x"], linha["y"])
    time.sleep(1.5)
    # A mesa pode pedir uma confirmacao depois da selecao; se nao pedir, estes
    # rotulos simplesmente nao existem e o clique devolve False sem efeito.
    clicar(nav, "Confirmar", "Declarar", "Continuar", "Pronto")
    print(f"ataque declarado com {nome}")
    return True


_DEBUG_COMBATE = os.environ.get("MANALOOM_DEBUG_COMBATE") == "1"
_JA_LOGADO: set[str] = set()


def _espiar_combate(nav) -> None:
    """Imprime uma vez cada tela que cheire a combate. So com a env ligada."""
    if not _DEBUG_COMBATE:
        return
    texto = texto_da_tela(nav)
    baixo = texto.lower()
    if "combate" not in baixo and "atacante" not in baixo:
        return
    curto = " | ".join(
        linha.strip() for linha in texto.splitlines() if linha.strip()
    )[:900]
    if curto in _JA_LOGADO:
        return
    _JA_LOGADO.add(curto)
    print(f"[COMBATE] {curto}")


def _avancar_uma_acao(nav) -> None:
    """Uma ação no automático. O botão vale só para a ação corrente."""
    _espiar_combate(nav)
    if _tentar_declarar_atacante(nav, _COMANDANTE_DA_CORRIDA):
        return
    if not clicar(nav, "Deixar esta ação no automático", "Passar prioridade"):
        time.sleep(1.2)


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
        return  # sessão já autenticada
    for c in campos:
        nav.clicar_ponto(c["x"], c["y"])
        time.sleep(0.4)
        nav.digitar(email if (c["al"] or "").lower().startswith("e") else senha)
    nav.clicar_texto("Entrar")
    time.sleep(10)


def abrir_seletor(nav, web: str, deck: str, paciencia: float = 420.0) -> None:
    """Abre o seletor de adversário a partir de qualquer estado da tela.

    Três estados, cada um cicatriz:

    * mesa ATIVA aparece como "Reconectar à mesa" e impede partida nova; sem
      partida nova não existe prompt de mulligan e o checkpoint 02 fica
      inalcançável. Concede antes.
    * mesa ENCERRADA mostra o painel terminal, e a rota sem sessão reexibe essa
      mesa até o servidor expirá-la. "Jogar novamente" só navega. O que resolve
      é insistir renavegando até o estado limpo.
    * estado limpo mostra "Escolher adversário".
    """
    from manaloom_webdriver_capture import ErroDeCaptura

    nav.ir(f"{web}#/decks/{deck}/play-vs-ai", espera=12)

    # Mesa ativa: a tela de boas-vindas mostra "Retomar mesa ativa" ou
    # "Reconectar à mesa" no lugar de "Escolher adversário", e "Conceder
    # partida" so aparece na barra DEPOIS de a mesa estar carregada. Cicatriz de
    # 2026-09-28: o laco so conhecia "Escolher adversário" e "Jogar novamente",
    # nao achava nada e renavegava ate estourar os 240 s com a tela cheia.
    if achar(nav, "Retomar mesa ativa", "Reconectar à mesa",
             altura_max=60) is not None:
        clicar(nav, "Retomar mesa ativa", "Reconectar à mesa", altura_max=60)
        time.sleep(8)

    if achar(nav, "Conceder partida", altura_max=200) is not None:
        clicar(nav, "Conceder partida", altura_max=200)
        time.sleep(2)
        clicar(nav, "Conceder", altura_max=200)
        time.sleep(10)
        nav.ir(f"{web}#/decks/{deck}/play-vs-ai", espera=10)

    limite = time.time() + paciencia
    while time.time() < limite:
        if achar(nav, TITULO_SELETOR) is not None:
            return
        # Esperar o DIALOGO, nunca dormir as cegas. Cicatriz de 2026-09-28:
        # com `sleep` fixo, um dialogo lento fazia o laco clicar de novo -- e o
        # segundo clique cai na barreira e FECHA o que acabou de abrir. O laco
        # oscilava ate estourar os 240 s com o botao visivel na tela.
        if clicar(nav, "Escolher adversário", altura_max=60):
            if esperar(nav, TITULO_SELETOR, segundos=20) is not None:
                return
            continue
        if clicar(nav, "Jogar novamente", altura_max=60):
            if esperar(nav, TITULO_SELETOR, segundos=20) is not None:
                return
            time.sleep(3)
            continue
        if clicar(nav, "Retomar mesa ativa", "Reconectar à mesa",
                  altura_max=60):
            time.sleep(8)
            if clicar(nav, "Conceder partida", altura_max=200):
                time.sleep(2)
                clicar(nav, "Conceder", altura_max=200)
                time.sleep(10)
            continue
        nav.ir(f"{web}#/decks/{deck}/play-vs-ai", espera=10)
        time.sleep(5)
    raise ErroDeCaptura(
        f"o seletor nunca abriu em {paciencia:.0f}s. Folhas pequenas:\n  "
        + "\n  ".join(
            f"{(o['t'] or o['al'])[:48]!r}@({o['x']},{o['y']})"
            for o in folhas(nav)
            if o["h"] <= 120
        )
    )


def _conferir_seletor(nav, adversario: str) -> None:
    from manaloom_webdriver_capture import ErroDeCaptura

    if adversario.lower() not in texto_da_tela(nav).lower():
        raise ErroDeCaptura(
            f"o seletor abriu sem o deck '{adversario}' na lista; sem ele a "
            "captura nao prova o que o checkpoint pede"
        )


def iniciar_partida(nav, adversario: str) -> None:
    from manaloom_webdriver_capture import ErroDeCaptura

    linha = achar(nav, adversario, altura_max=90)
    if linha is None:
        raise ErroDeCaptura(f"linha do deck '{adversario}' nao encontrada")
    nav.clicar_ponto(linha["x"], linha["y"])
    time.sleep(2)
    if not clicar(nav, "Jogar contra IA", altura_max=60):
        raise ErroDeCaptura("botao 'Jogar contra IA' nao encontrado no seletor")


def esperar_mesa(nav, segundos: float = 200.0) -> str:
    """Espera a rota da sessão e devolve o id lido da URL."""
    from manaloom_webdriver_capture import ErroDeCaptura

    limite = time.time() + segundos
    while time.time() < limite:
        url = nav.url()
        if "/play-vs-ai/" in url:
            return url.rsplit("/play-vs-ai/", 1)[1].split("?")[0].strip()
        time.sleep(1.0)
    raise ErroDeCaptura(
        f"a mesa nao abriu: a URL nunca virou /play-vs-ai/<sessao>. URL {nav.url()}"
    )


def cp01(nav, destino: str, adversario: str, registrar) -> None:
    _conferir_seletor(nav, adversario)
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[0]}.png")
    registrar(f"{CHECKPOINTS[0]}: seletor com '{adversario}' na lista")


def cp02(nav, destino: str, registrar) -> int:
    """Mão inicial privada. Devolve a vida do começo da partida.

    Antes do mulligan o motor pode pedir outra decisão — medido: "Escolha um
    alvo", para quem começa. O laço responde o que vier, conferindo o mulligan
    PRIMEIRO em cada volta para nunca delegar a decisão que o checkpoint mostra.
    """
    from manaloom_webdriver_capture import ErroDeCaptura

    limite = time.time() + 150
    while time.time() < limite:
        if achar(nav, "Mão inicial", altura_max=60) is not None:
            break
        _avancar_uma_acao(nav)
        time.sleep(2)
    if esperar(nav, "Mão inicial", segundos=90) is None:
        raise ErroDeCaptura(
            "o prompt de mao inicial nao apareceu; sem ele o checkpoint de "
            f"mulligan nao existe. Tela:\n{texto_da_tela(nav)[:900]}"
        )
    tela = texto_da_tela(nav)
    if "Manter esta mão" not in tela:
        raise ErroDeCaptura("o prompt de mao inicial nao ofereceu manter a mao")
    if "Sua mão" not in tela:
        raise ErroDeCaptura(
            "a propria mao nao esta visivel; a captura nao provaria a mao "
            "privada, que e o ponto do checkpoint"
        )
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[1]}.png")
    registrar(f"{CHECKPOINTS[1]}: mao inicial de 7 com opcao de manter")

    vidas = _totais_de_vida(nav)
    if not vidas:
        raise ErroDeCaptura("nao consegui ler a vida no comeco da partida")
    if not clicar(nav, "Manter esta mão"):
        raise ErroDeCaptura("nao consegui clicar em 'Manter esta mão'")
    time.sleep(6)
    return vidas[0]


def cp03(nav, destino: str, registrar, vigia=None) -> None:
    from manaloom_webdriver_capture import ErroDeCaptura

    limite = time.time() + 180
    while time.time() < limite and not _carta_no_meu_campo(nav, "Plains"):
        if _jogar_carta(nav, "Plains"):
            time.sleep(4)
            continue
        if _terminal(nav):
            raise ErroDeCaptura("a mesa terminou antes de eu jogar um terreno")
        if vigia:
            vigia()
        _avancar_uma_acao(nav)
        time.sleep(1.5)
    if _meu_campo_vazio(nav) or not _carta_no_meu_campo(nav, "Plains"):
        raise ErroDeCaptura(
            "nenhum Plains identificavel no meu campo; 03-land-played seria "
            "falso. Campo vazio="
            f"{_meu_campo_vazio(nav)}"
        )
    # O portao de taxa do Scryfall enfileira as artes; 20s nao bastavam com a
    # mao inteira carregando antes do campo.
    espera_arte = time.time() + 60
    while time.time() < espera_arte and not _arte_carregada_no_meu_campo(nav):
        time.sleep(1.0)
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[2]}.png")
    registrar(f"{CHECKPOINTS[2]}: Plains no meu campo, com arte carregada")


def _comandante_lancado(nav, comandante: str) -> bool:
    """Comandante no campo E sem oferta de lanca-lo.

    As duas condicoes juntas, porque cada uma sozinha ja mentiu: a carta no
    campo pode ser confundida com o nome do deck, e a oferta pode sumir por
    falta de mana em vez de por ter sido lancada.
    """
    if not _carta_no_meu_campo(nav, comandante):
        return False
    return f"cast {comandante}".lower() not in texto_da_tela(nav).lower()


def cp04(nav, destino: str, comandante: str, registrar, vigia=None) -> None:
    from manaloom_webdriver_capture import ErroDeCaptura

    # Lancar o comandante custa {W} e abre um prompt proprio: "Produza mana",
    # com "Opção legal 1" e "Escolha segura do motor". Medido em 2026-09-28: o
    # laco que so delegava nao fechava o lancamento em 240 s, porque delegar
    # naquele prompt nao e o mesmo que escolher a fonte de mana.
    limite = time.time() + 420
    while time.time() < limite and not _comandante_lancado(nav, comandante):
        if _terminal(nav):
            raise ErroDeCaptura(
                "a mesa terminou antes de o comandante entrar no campo"
            )
        tela = texto_da_tela(nav)
        if "Produza mana" in tela:
            if clicar(nav, "Opção legal 1", "Escolha segura do motor"):
                time.sleep(3)
                continue
        if f"cast {comandante}".lower() in tela.lower():
            if _jogar_carta(nav, comandante):
                time.sleep(4)
                continue
        if vigia:
            vigia()
        _avancar_uma_acao(nav)
        time.sleep(1.5)
    if not _comandante_lancado(nav, comandante):
        raise ErroDeCaptura(
            f"o comandante '{comandante}' nao chegou ao campo, ou o painel "
            "ainda oferece lanca-lo"
        )
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[3]}.png")
    registrar(f"{CHECKPOINTS[3]}: comandante no campo")


def _fase_e_estado(nav) -> tuple[str, bool]:
    """Le so o cabecalho de fase e se a partida acabou. Uma varredura curta."""
    dados = nav.js(
        r"""
        const folhas = [...document.querySelectorAll('flt-semantics')]
          .filter(e => e.children.length <= 1)
          .map(e => (e.textContent || '').trim());
        // O cabecalho NAO comeca com "Turno": ele e
        // "Sua prioridade ... Turno 1 · Principal pré-combate". Ancorar no
        // inicio nunca casava, e eu cheguei a concluir que a UI nao expunha a
        // fase -- conclusao errada, medida por sonda em 2026-09-28.
        const fase = folhas.find(t => /Turno\s+\d+/.test(t)) || '';
        const fim = folhas.some(t => t === 'Partida concluída');
        return [fase, fim];
        """
    ) or ["", False]
    return (dados[0] or "", bool(dados[1]))


def _chave_de_concessao() -> str:
    """Chave de idempotencia no formato do app: `battle-concede:<uuid>`."""
    import uuid

    return f"battle-concede:{uuid.uuid4()}"


def limpar_mesas_pela_api(api: str, token: str, deck: str, registrar) -> int:
    """Concede, pela API, qualquer mesa ainda viva deste deck.

    CICATRIZ de 2026-09-28: cada corrida que falhava no meio deixava a sessao
    viva, e a seguinte gastava minutos -- as vezes o limite inteiro -- so para
    voltar ao estado de boas-vindas, porque a rota sem sessao reexibe a mesa
    encerrada ate o servidor expira-la. Limpar pela API e PREPARO, nao prova: o
    que o pacote prova comeca no seletor de adversario.
    """
    import json
    import urllib.request

    def chamar(caminho: str, metodo: str = "GET", corpo: dict | None = None):
        cabecalhos = {"Authorization": f"Bearer {token}"}
        dados = None
        if corpo is not None:
            dados = json.dumps(corpo).encode()
            cabecalhos["Content-Type"] = "application/json"
        pedido = urllib.request.Request(
            f"{api}{caminho}",
            data=dados,
            headers=cabecalhos,
            method=metodo,
        )
        with urllib.request.urlopen(pedido, timeout=60) as resposta:
            return json.loads(resposta.read().decode() or "{}")

    try:
        lista = chamar(f"/ai/battle/sessions?deck_id={deck}&limit=20")
    except Exception as erro:
        registrar(f"nao consegui listar mesas pela API: {erro}")
        return 0
    sessoes = lista.get("sessions") or lista.get("items") or (
        lista if isinstance(lista, list) else []
    )
    encerradas = 0
    for sessao in sessoes:
        if not isinstance(sessao, dict) or sessao.get("terminal"):
            continue
        ident = sessao.get("session_id") or sessao.get("id")
        if not ident:
            continue
        try:
            # A rota de concessao exige chave de idempotencia, no mesmo formato
            # que o app usa (`interactive_battle_service.dart`); sem ela vem
            # 422 e a mesa continua viva.
            chamar(
                f"/ai/battle/sessions/{ident}/concede",
                "POST",
                {"idempotency_key": _chave_de_concessao()},
            )
            encerradas += 1
        except Exception as erro:
            registrar(f"nao consegui conceder {ident}: {erro}")
    if encerradas:
        registrar(f"mesas encerradas pela API antes de comecar: {encerradas}")
    return encerradas


def estado_pela_api(api: str, token: str, sessao: str) -> dict:
    """Estado da partida lido do BACKEND, não da árvore de semântica.

    O PostgreSQL e a API são a verdade; a árvore do Flutter é uma projeção
    dela, e ler rótulo de lá foi a fonte de quatro diagnósticos errados meus
    neste checkpoint. Aqui vêm vida dos dois lados, status e turno, já
    desambiguados pelo servidor.
    """
    import json
    import urllib.request

    pedido = urllib.request.Request(
        f"{api}/ai/battle/sessions/{sessao}",
        headers={"Authorization": f"Bearer {token}"},
    )
    with urllib.request.urlopen(pedido, timeout=30) as resposta:
        corpo = json.loads(resposta.read().decode())
    # O estado do jogo vem em `private_state`, nao no topo -- e o proprio app
    # le assim (`interactive_battle_session.dart:334`). Medido em 2026-09-28:
    # no topo ha status, terminal, prompt e metadados do motor, e nada de vida.
    estado_privado = corpo.get("private_state") or {}
    jogadores = estado_privado.get("players") or corpo.get("players") or []
    return {
        # `terminal` e o proprio contrato dizendo se acabou
        # (`interactive_battle_contract.dart`), melhor do que eu enumerar
        # status e errar um nome -- `waiting_for_action` ja me pegou.
        "terminal": bool(corpo.get("terminal")),
        "status": corpo.get("status"),
        "turno": estado_privado.get("turn") or corpo.get("turn"),
        "fase": (
            f"{estado_privado.get('phase') or corpo.get('phase') or ''} "
            f"{estado_privado.get('step') or corpo.get('step') or ''}"
        ).strip(),
        "vidas": [p.get("life") for p in jogadores],
        "nomes": [p.get("name") for p in jogadores],
        "chaves": sorted(estado_privado.keys()) or sorted(corpo.keys()),
        "chaves_jogador": sorted(jogadores[0].keys()) if jogadores else [],
    }


def vigiar_dano(contexto: dict, nav, destino: str, registrar) -> None:
    """Captura o 05 no primeiro dano, com a TELA como gatilho.

    Por que a tela e nao a API, depois de eu ter tentado os dois:

    A tela atualiza a vida PROGRESSIVAMENTE enquanto o combate resolve -- foi
    de la que saiu o instante bom, 40 para 39. O estado da sessao no backend ja
    entrega o valor ASSENTADO: medido em 2026-09-28, em quatro corridas e dois
    seeds diferentes, a API so mostrava 40 e depois -23, com `terminal` ja
    verdadeiro. Como gatilho a API perde o instante; como guarda de fim de
    partida ela e melhor que a tela, porque `terminal` vem do proprio contrato.

    Entao cada um faz o que faz bem: a TELA diz quando capturar, a API diz se
    ainda da tempo.
    """
    if contexto.get("capturado"):
        return
    vidas = _totais_de_vida(nav)
    if not vidas or not any(v < contexto["inicial"] for v in vidas):
        return
    estado = None
    if contexto.get("api"):
        try:
            estado = estado_pela_api(
                contexto["api"], contexto["token"], contexto["sessao"]
            )
        except Exception:
            estado = None
    if estado is not None and estado["terminal"]:
        return  # ja acabou: capturar agora seria o painel terminal, que e o 07
    # A vida ja caiu e o instante esta garantido; da para gastar alguns
    # segundos esperando a arte do meu campo voltar. Sem isso a captura sai com
    # as minhas cartas no verso enquanto as do rival e as da mao aparecem --
    # medido em 2026-09-29, e e so a fila do portao de taxa do Scryfall
    # recomecando quando a mesa se redesenha.
    espera = time.time() + 8
    while time.time() < espera and not _arte_carregada_no_meu_campo(nav):
        time.sleep(0.8)
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[4]}.png")
    # A mesa anda durante a espera pela arte. O registro tem de dizer a vida
    # que ESTA na imagem, nao a que disparou o gatilho -- senao o recibo
    # descreve uma captura que nao existe.
    vidas = _totais_de_vida(nav) or vidas
    contexto["capturado"] = True
    registrar(
        f"{CHECKPOINTS[4]}: dano de combate com a partida em curso "
        f"(tela: vidas={vidas} inicio={contexto['inicial']}"
        + (f"; API: status={estado['status']} turno={estado['turno']}"
           if estado else "")
        + ")"
    )


def cp05(nav, destino: str, inicial: int, registrar, api: str = "",
         token: str = "", sessao: str = "") -> None:
    """Rede do 05: segue jogando e vigiando, se o fluxo natural nao pegou."""
    from manaloom_webdriver_capture import ErroDeCaptura

    contexto = {
        "api": api, "token": token, "sessao": sessao,
        "inicial": inicial, "capturado": False,
    }
    limite = time.time() + 420
    while time.time() < limite and not contexto["capturado"]:
        vigiar_dano(contexto, nav, destino, registrar)
        if contexto["capturado"]:
            return
        if _terminal(nav):
            raise ErroDeCaptura(
                "a mesa terminou sem nenhum instante de dano com a partida em "
                "curso. Se o primeiro dano do confronto semeado for o letal, "
                "ele encerra a mesa no mesmo golpe e o 05 nao tem o que mostrar."
            )
        _avancar_uma_acao(nav)
        time.sleep(0.3)
    if not contexto["capturado"]:
        raise ErroDeCaptura("nenhum dano de combate no tempo previsto")


def cp06(nav, destino: str, web: str, deck: str, sessao: str, registrar) -> None:
    """Recarrega a PÁGINA e exige a mesma mesa de volta.

    É o checkpoint que `flutter drive` não alcança: sem recarregar o documento
    não há prova de que a sessão sobrevive ao navegador.
    """
    from manaloom_webdriver_capture import ErroDeCaptura

    # Avanca UMA acao antes de recarregar. Cicatriz de 2026-09-29: a
    # reconexao acontece logo depois do checkpoint 05 e o modo de fixture fixa
    # o relogio do prompt em 60s, entao a tela ficava identica e as duas
    # capturas saiam byte a byte iguais -- 8 sha distintos onde o harness exige
    # 9. Com uma acao a mais, a mesa retomada mostra estado POSTERIOR, o que
    # prova melhor a reconexao do que uma tela igual provaria.
    _avancar_uma_acao(nav)
    time.sleep(2)
    antes = _totais_de_vida(nav)
    nav.ir(f"{web}#/decks/{deck}/play-vs-ai/{sessao}", espera=14)
    if esperar(nav, "pontos de vida", segundos=90) is None:
        raise ErroDeCaptura("depois de recarregar, a mesa nao voltou")
    if sessao not in nav.url():
        raise ErroDeCaptura(f"a URL perdeu a sessao: {nav.url()}")
    depois = _totais_de_vida(nav)
    if antes and depois and min(depois) > min(antes):
        raise ErroDeCaptura(
            f"a mesa voltou com vidas {depois}, acima de {antes}: isso seria "
            "uma mesa nova, nao a mesma retomada"
        )
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[5]}.png")
    registrar(f"{CHECKPOINTS[5]}: mesa {sessao} retomada apos recarregar")


def cp07(nav, destino: str, registrar, api: str = "", token: str = "",
         sessao: str = "") -> None:
    """Estado terminal com replay e revanche.

    A mesa e levada ao fim jogando no automatico. Se nao terminar sozinha no
    tempo do checkpoint, a partida e CONCEDIDA explicitamente -- e isso fica
    registrado no recibo da corrida, nunca implicito.

    Conceder e o proprio fluxo do produto, e o painel terminal que ele produz
    e o mesmo que o checkpoint pede. Quanto a partida demora a acabar sozinha
    depende do confronto que o harness semeia, nao deste roteiro.
    """
    from manaloom_webdriver_capture import ErroDeCaptura

    limite = time.time() + 240
    while time.time() < limite and not _terminal(nav):
        _avancar_uma_acao(nav)
        time.sleep(1.0)

    concedida = False
    if not _terminal(nav):
        registrar("a mesa nao terminou sozinha; concedendo explicitamente")
        # A concessao vai pela API -- o MESMO endpoint que o app chama
        # (`interactive_battle_service.dart`: /ai/battle/sessions/<id>/concede).
        # O botao da barra nao esta confiavelmente na arvore de semantica
        # depois do fluxo de captura, e o que este checkpoint prova e o PAINEL
        # TERMINAL, nao o gesto de conceder. A pagina e recarregada em seguida,
        # e o painel capturado e o que o produto renderiza.
        import json
        import urllib.request

        if not (api and token and sessao):
            raise ErroDeCaptura(
                "sem API para conceder e a mesa nao terminou sozinha"
            )
        # A rota exige chave de idempotencia no corpo, no mesmo formato que o
        # app usa (`interactive_battle_service.dart`): sem ela vem 422.
        pedido = urllib.request.Request(
            f"{api}/ai/battle/sessions/{sessao}/concede",
            data=json.dumps({"idempotency_key": _chave_de_concessao()}).encode(),
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(pedido, timeout=60) as resposta:
                json.loads(resposta.read().decode() or "{}")
        except Exception as erro:
            raise ErroDeCaptura(f"a concessao pela API falhou: {erro}") from erro
        nav.ir(nav.url(), espera=10)
        espera = time.time() + 90
        while time.time() < espera and not _terminal(nav):
            time.sleep(1.0)
        concedida = True

    if not _terminal(nav):
        raise ErroDeCaptura("a mesa nao chegou ao estado terminal")
    if "replay" not in texto_da_tela(nav).lower():
        raise ErroDeCaptura("o painel terminal nao ofereceu replay")
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[6]}.png")
    registrar(
        f"{CHECKPOINTS[6]}: painel terminal com replay e revanche"
        + (" (sessao CONCEDIDA explicitamente)" if concedida
           else " (fim natural da partida)")
    )


def cp08(nav, destino: str, registrar) -> None:
    """Abre o replay. "Abrir replays", na barra de título, é a rede."""
    from manaloom_webdriver_capture import ErroDeCaptura

    for rotulo in ("Analisar replay", "Ver replay", "Abrir replays"):
        if clicar(nav, rotulo, altura_max=140):
            registrar(f"replay aberto por '{rotulo}'")
            break
    else:
        raise ErroDeCaptura(
            f"nenhuma entrada de replay respondeu. Tela:\n{texto_da_tela(nav)[:900]}"
        )
    time.sleep(9)
    if esperar(nav, "Battle Lab", "replay", segundos=60, altura_max=600) is None:
        raise ErroDeCaptura("o replay nao abriu depois do clique")
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[7]}.png")
    registrar(f"{CHECKPOINTS[7]}: replay aberto")


def cp09(nav, destino: str, web: str, deck: str, adversario: str,
         registrar) -> None:
    """Seletor da revanche, com o rival JÁ ESCOLHIDO.

    Volta pelo HISTÓRICO do navegador — o pacote prova a web, e voltar por rota
    nova não provaria nada.

    CICATRIZ de 2026-09-28: capturar o seletor recém-aberto produzia um PNG
    byte a byte idêntico ao `01-opponent-picker` (mesmo sha256, mesmo tamanho).
    O harness exige nove sha distintos, e a exigência está certa: uma captura
    igual à primeira não prova revanche nenhuma. O estado que distingue a
    revanche é o seletor com o adversário selecionado, pronto para recomeçar, e
    a prova disso é o aviso "Selecione um adversário" desaparecer.
    """
    from manaloom_webdriver_capture import ErroDeCaptura

    nav.voltar(espera=8)
    registrar(f"apos voltar pelo historico, url={nav.url()}")
    abrir_seletor(nav, web, deck, paciencia=420.0)
    _conferir_seletor(nav, adversario)

    linha = achar(nav, adversario, altura_max=90)
    if linha is None:
        raise ErroDeCaptura(
            f"o seletor da revanche nao ofereceu a linha de '{adversario}'"
        )
    nav.clicar_ponto(linha["x"], linha["y"])
    time.sleep(3)
    if "Selecione um adversário" in texto_da_tela(nav):
        raise ErroDeCaptura(
            "cliquei na linha do rival e o seletor continua pedindo "
            "'Selecione um adversário'; sem selecao a captura seria igual a 01"
        )
    capturar_limpo(nav, f"{destino}/{CHECKPOINTS[8]}.png")
    registrar(f"{CHECKPOINTS[8]}: seletor de revanche com o rival escolhido")


def capturar(nav, destino: str, web: str, deck: str, adversario: str,
             comandante: str, email: str, senha: str, api: str = "",
             token: str = "", registrar=print) -> str:
    global _COMANDANTE_DA_CORRIDA
    _COMANDANTE_DA_CORRIDA = comandante
    entrar(nav, web, email, senha)
    if api and token:
        limpar_mesas_pela_api(api, token, deck, registrar)
    abrir_seletor(nav, web, deck)
    cp01(nav, destino, adversario, registrar)
    iniciar_partida(nav, adversario)
    sessao = esperar_mesa(nav)
    registrar(f"mesa aberta, sessao {sessao}")
    vida_inicial = cp02(nav, destino, registrar)
    contexto = {
        "api": api, "token": token, "sessao": sessao,
        "inicial": vida_inicial, "capturado": False,
    }
    vigia = lambda: vigiar_dano(contexto, nav, destino, registrar)
    cp03(nav, destino, registrar, vigia)
    cp04(nav, destino, comandante, registrar, vigia)
    if not contexto["capturado"]:
        cp05(nav, destino, vida_inicial, registrar, api, token, sessao)
    cp06(nav, destino, web, deck, sessao, registrar)
    cp07(nav, destino, registrar, api, token, sessao)
    cp08(nav, destino, registrar)
    cp09(nav, destino, web, deck, adversario, registrar)
    return sessao


def _encerrar_mesa(nav) -> None:
    """Concede a mesa aberta antes de sair, doa no que der.

    Cicatriz de 2026-09-28: cada corrida que falhava no meio deixava a sessao
    viva. A corrida seguinte encontrava "Reconectar à mesa" ou
    "Sessão abandonada" e gastava minutos so para voltar ao estado limpo --
    quando nao estourava o proprio limite. Limpar na saida e mais barato do que
    brigar na entrada.
    """
    try:
        # `Conceder partida` e o tooltip de um IconButton (battle_coach_screen);
        # a folha nao cabe no limite de 60px que eu usava, e por isso a limpeza
        # na saida nunca rodava. O dialogo confirma com "Conceder".
        if clicar(nav, "Conceder partida", altura_max=200):
            time.sleep(2)
            if clicar(nav, "Conceder", altura_max=200):
                time.sleep(6)
                print("mesa encerrada na saida", file=sys.stderr)
    except Exception as erro:  # a limpeza nunca derruba o relato do erro real
        print(f"nao consegui encerrar a mesa na saida: {erro}", file=sys.stderr)


def _token_da_api(api: str, email: str, senha: str) -> str:
    """Token de leitura do estado da partida. Mesma conta de QA da fixture."""
    import json
    import urllib.request

    pedido = urllib.request.Request(
        f"{api}/auth/login",
        data=json.dumps({"email": email, "password": senha}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(pedido, timeout=60) as resposta:
        corpo = json.loads(resposta.read().decode())
    token = corpo.get("token") or corpo.get("access_token")
    if not token:
        raise RuntimeError("login na API nao devolveu token")
    return token


def main() -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from manaloom_webdriver_capture import (
        ChromeDriver,
        ErroDeCaptura,
        Navegador,
        resolver_binarios,
    )

    if len(sys.argv) != 12:
        print(__doc__, file=sys.stderr)
        return 2
    (porta, destino, web, deck, adversario, comandante, email, senha,
     saida_sessao, api, saida_console) = sys.argv[1:12]
    # Sem barra final: as rotas sao montadas como `{web}#/decks/...` e
    # `{api}/ai/...`, e uma barra a mais vira `//` na URL.
    web = web.rstrip("/")
    api = api.rstrip("/")

    try:
        chrome, chromedriver = resolver_binarios()
    except ErroDeCaptura as e:
        print(f"FALHA: {e}", file=sys.stderr)
        return 2

    token = _token_da_api(api, email, senha)

    sessao = None
    with ChromeDriver(chromedriver, int(porta)):
        nav = Navegador(int(porta), 1440, 900)
        try:
            nav.abrir(chrome)
            print(f"navegador da corrida (D-80): {nav.navegador_real}")
            sessao = capturar(
                nav, destino, web, deck, adversario, comandante, email, senha,
                api, token,
            )
        except ErroDeCaptura as e:
            print(f"FALHA: {e}", file=sys.stderr)
            _encerrar_mesa(nav)
            return 1
        finally:
            # O console vira o log de runtime da evidencia: o indexador confere
            # excecao, overflow de RenderFlex e falha de CachedCardImage. Sem
            # esta coleta nao daria para afirmar forbidden_entries igual a zero.
            try:
                total = nav.gravar_console(saida_console)
                print(f"console do navegador: {total} mensagens")
            except Exception as erro:
                print(f"nao consegui ler o console: {erro}", file=sys.stderr)
            nav.fechar()

    with open(saida_sessao, "w", encoding="utf-8") as fh:
        fh.write(sessao)
    print(f"play-vs-ai-web-real: {len(CHECKPOINTS)} checkpoints capturados")
    print(f"sessao={sessao}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
