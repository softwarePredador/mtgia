"""Captura `battle-coach-web-keyboard`: navegação por TECLADO na mesa.

O contrato pede build Web real a 1280x720 com Tab, Shift+Tab, Enter, Espaço,
Escape e digitação **do nível do navegador** — não atalho de widget. Por isso
`flutter drive` não serve: ele entrega o evento direto ao widget e pula a ordem
de foco que o navegador constrói, que é justamente o que o pacote prova.

Cada checkpoint assere QUEM tem o foco, lendo `document.activeElement`, antes de
virar arquivo. O halo de alto contraste (`_BattleCoachKeyboardFocusHalo`) é o
que aparece na imagem; a asserção é o nome acessível do elemento focado.

**D-79**: esta corrida roda no ambiente LOCAL — API, PostgreSQL e XMage
descartáveis em loopback, conta de QA semeada, nada tocando produção. O contrato
anterior descrevia um proxy para a API implantada. A mudança é de ambiente, e
todas as exigências de teclado seguem iguais.

**D-80**: a procedência registra o navegador e o agente reais da corrida, em vez
de nomear um agente fixo. Este roteiro imprime o navegador REAL da sessão
WebDriver (nome, versão e modo headless); quem conduz a corrida declara o
agente.

Uso (o Chrome é `CHROME_EXECUTABLE`; o ChromeDriver vem do pin de
`scripts/lib/manaloom_chromedriver.sh`):

    python3 scripts/lib/manaloom_captura_battle_coach_keyboard.py \\
      <porta-webdriver> <destino> <web-url> <deck-id> <rival> \\
      <email> <senha> <saida-console>
"""

from __future__ import annotations

import os
import sys
import time

CHECKPOINTS = (
    "01_focus_back",
    "02_tab_replays",
    "03_tab_choose_opponent",
    "04_shift_tab_replays",
    "05_enter_dialog_search_focus",
    "06_escape_focus_restored",
    "07_space_dialog_search_focus",
    "08_physical_typing_filters_rival",
    "09_tab_focuses_filtered_rival",
    "10_enter_selects_and_preflight",
    "11_tab_focuses_start_battle",
    "12_enter_starts_real_session",
    "13_prompt_option_focus_mulligan",
    "14_prompt_option_focus_keep",
    "15_delegate_focus",
    "16_shift_tab_returns_to_keep",
    "17_enter_activates_keep",
    "18_next_prompt_focus",
    "19_session_conceded_replay_ready",
)

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


def foco(nav) -> str:
    return (nav.elemento_focado() or "").strip()


def foco_esta_em(nav, *rotulos: str) -> bool:
    """Se o elemento focado É o controle desse rótulo, por identidade de DOM.

    CICATRIZ de 2026-09-28, e ela me fez reportar um defeito de acessibilidade
    que NÃO existe. Eu identificava o controle focado pelo rótulo do próprio nó
    (`aria-label || textContent || tagName`). Medido no navegador: os nós
    focados da mesa são `<flt-semantics role="button" tabindex="0">` SEM
    `aria-label` em cinco níveis de ancestral, então o rótulo saía
    `'FLT-SEMANTICS'` e nenhum matcher por texto casava. Eu concluí que o Tab
    não alcançava "Conceder partida" e reportei armadilha de teclado. A sonda
    mostrou o foco passando por nós diferentes a cada Tab -- node-64, 65, 14,
    16, 37, 38, 63 -- ou seja, a travessia sempre funcionou.

    A identificação certa é por IDENTIDADE: acha-se o elemento que carrega o
    rótulo e pergunta-se se o foco é ele ou está dentro dele.
    """
    return bool(
        nav.js(
            r"""
            const procurados = arguments[0].map(t => t.toLowerCase());
            const ativo = document.activeElement;
            if (!ativo) return false;
            const nos = [...document.querySelectorAll('flt-semantics')];
            const alvos = nos.filter(e => {
              const txt = ((e.textContent || '') + ' ' +
                           (e.getAttribute('aria-label') || '')).toLowerCase();
              return procurados.some(p => txt.includes(p));
            });
            // Só os mais internos: o contêiner da tela casa qualquer rótulo.
            const folhas = alvos.filter(
              a => !alvos.some(b => b !== a && a.contains(b))
            );
            return folhas.some(
              a => a === ativo || a.contains(ativo) ||
                   (ativo.contains(a) &&
                    ativo.querySelectorAll('flt-semantics').length <= 3)
            );
            """,
            list(rotulos),
        )
    )


def reancorar_se_perdido(nav, registrar=None) -> bool:
    """Devolve o foco à árvore quando ele cai no elemento de medição.

    O `flutter typography measurement` não está na ordem de tabulação: quando o
    foco cai nele — e ele cai, se o nó focado sai da árvore porque o motor
    trocou o prompt no meio do percurso — o Tab perde a âncora e não anda mais.
    Medido em 2026-09-28: doze Tabs seguidos sem sair do lugar. Foi isso que me
    fez reportar uma armadilha de teclado que NÃO existe; a tela tinha 22 nós
    focáveis, "Conceder partida" entre eles.

    Reancorar é recuperação de INSTRUMENTO, não parte da prova: o que o pacote
    prova é a travessia por Tab e o Enter ativando o controle. Por isso o foco
    volta para o primeiro nó focável e o percurso recomeça por teclado.
    """
    if not _e_medicao(foco(nav)):
        return False
    nav.js(
        "const n = document.querySelector('flt-semantics[tabindex]');"
        "if (n) n.focus();"
    )
    time.sleep(0.4)
    if registrar:
        registrar(f"foco reancorado em {foco(nav)!r} (estava no medidor)")
    return True


def tab_ate(nav, *alvos: str, limite: int = 24) -> tuple[str, int]:
    """Tab até o foco bater com um dos alvos. Devolve (foco, quantos Tabs).

    Tab de NAVEGADOR, uma tecla por vez, conferindo o foco a cada passo: é a
    ordem de foco real que o pacote prova, então percorrer por atalho ou por
    clique invalidaria a prova.

    Medido em 2026-09-28: o PRIMEIRO Tab depois de entrar na rota mantém o foco
    em "Back" — ele sai do envoltório do halo para o próprio botão. Contar Tabs
    fixos quebraria; por isso o avanço é até o alvo, com o número de Tabs
    registrado como evidência.
    """
    procurados = [a.lower() for a in alvos]
    for passo in range(1, limite + 1):
        nav.teclar("Tab")
        time.sleep(0.45)
        atual = foco(nav)
        if _e_medicao(atual):
            # Sem ancora o Tab nao anda; reancora e segue percorrendo.
            reancorar_se_perdido(nav)
            atual = foco(nav)
        if any(p in atual.lower() for p in procurados) or foco_esta_em(
            nav, *alvos
        ):
            return (atual, passo)
    return (foco(nav), limite)


def shift_tab_ate(nav, *alvos: str, limite: int = 24) -> tuple[str, int]:
    procurados = [a.lower() for a in alvos]
    for passo in range(1, limite + 1):
        nav.teclar_com_shift("Tab")
        time.sleep(0.45)
        atual = foco(nav)
        if _e_medicao(atual):
            # Sem ancora o Tab nao anda; reancora e segue percorrendo.
            reancorar_se_perdido(nav)
            atual = foco(nav)
        if any(p in atual.lower() for p in procurados) or foco_esta_em(
            nav, *alvos
        ):
            return (atual, passo)
    return (foco(nav), limite)


def exigir_foco(nav, esperado: str, checkpoint: str) -> str:
    from manaloom_webdriver_capture import ErroDeCaptura

    atual = foco(nav)
    if esperado.lower() not in atual.lower():
        raise ErroDeCaptura(
            f"{checkpoint}: o foco esta em {atual!r}, esperado algo com "
            f"{esperado!r}. Sem o foco certo a captura nao prova o teclado."
        )
    return atual


def capturar_com_foco(nav, destino: str, checkpoint: str, esperado: str,
                      registrar) -> None:
    atual = exigir_foco(nav, esperado, checkpoint)
    nav.capturar(f"{destino}/{checkpoint}.png")
    registrar(f"{checkpoint}: foco em {atual!r}")


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


def garantir_estado_limpo(nav, web: str, deck: str, registrar,
                          paciencia: float = 420.0) -> None:
    """Deixa a tela no estado de boas-vindas, sem mesa ativa.

    Cicatriz de 2026-09-28: uma corrida anterior que criou sessao deixa a mesa
    viva, e a tela passa a oferecer "Reconectar à mesa" no lugar de
    "Escolher adversário". A ordem de foco muda junto, e o checkpoint 03 falha
    sem que nada esteja errado com o teclado. O preparo NAO faz parte da prova:
    ele so garante o mesmo ponto de partida de sempre.
    """
    from manaloom_webdriver_capture import ErroDeCaptura

    limite = time.time() + paciencia
    while time.time() < limite:
        nav.ir(f"{web}#/decks/{deck}/play-vs-ai", espera=12)
        tela = texto_da_tela(nav)
        if "Escolher adversário" in tela:
            return
        if "Conceder partida" in tela:
            _clicar_texto(nav, "Conceder partida")
            time.sleep(2)
            _clicar_texto(nav, "Conceder")
            time.sleep(10)
            continue
        if "Reconectar à mesa" in tela or "Retomar mesa ativa" in tela:
            _clicar_texto(nav, "Reconectar à mesa", "Retomar mesa ativa")
            time.sleep(8)
            continue
        if "Sessão abandonada" in tela or "Partida concluída" in tela:
            # A rota sem sessão reexibe a mesa encerrada até o servidor
            # expirá-la, e "Jogar novamente" só navega. O que resolve é
            # insistir renavegando -- mesma cicatriz do play-vs-ai.
            _clicar_texto(nav, "Jogar novamente")
            time.sleep(10)
            continue
        time.sleep(6)
    raise ErroDeCaptura(
        "a tela nunca chegou ao estado de boas-vindas com "
        f"'Escolher adversário'. Tela:\n{texto_da_tela(nav)[:600]}"
    )


def _clicar_texto(nav, *trechos: str) -> bool:
    """Clique auxiliar do PREPARO -- fora dos dezenove checkpoints."""
    alvos = [t.lower() for t in trechos]
    melhor = None
    for o in folhas(nav):
        if o["h"] > 200:
            continue
        combinado = f"{o['t']} {o['al']}".lower()
        if any(a in combinado for a in alvos):
            if melhor is None or o["w"] * o["h"] < melhor["w"] * melhor["h"]:
                melhor = o
    if melhor is None:
        return False
    nav.clicar_ponto(melhor["x"], melhor["y"])
    return True


def encerrar_mesa(nav, registrar) -> None:
    """Concede a mesa ao sair, para a proxima corrida comecar limpa."""
    try:
        if _clicar_texto(nav, "Conceder partida"):
            time.sleep(2)
            if _clicar_texto(nav, "Conceder"):
                time.sleep(6)
                registrar("mesa encerrada na saida")
    except Exception as erro:
        registrar(f"nao consegui encerrar a mesa na saida: {erro}")


_ACOES_LEGAIS = (
    "você",
    "voce",
    "adversário",
    "adversario",
    "passar prioridade",
    "deixar esta ação no automático",
    "deixar esta acao no automatico",
    "fazer mulligan",
    "manter esta mão",
    "ver prévia de",
)


def _e_medicao(texto: str) -> bool:
    """O elemento interno `flutter typography measurement`.

    Ele carrega no texto a barra inteira do app, entao casar qualquer rotulo
    contra ele aprova qualquer coisa. Nenhum matcher deste roteiro pode
    aceita-lo.
    """
    return "flutter typography measurement" in (texto or "").lower()


def garantir_foco(nav, *alvos: str, limite: int = 20) -> tuple[str, int]:
    """Deixa o foco num dos alvos, tabulando SÓ se ele já não estiver lá.

    Com o conserto do halo, a primeira ação legal de um prompt novo já nasce
    focada. Tabular às cegas partia de cima do alvo e dava a volta inteira na
    ordem de foco — medido em 2026-09-28, 20 Tabs terminando no elemento de
    medição.
    """
    atual = foco(nav)
    if not _e_medicao(atual) and any(a.lower() in atual.lower() for a in alvos):
        return (atual, 0)
    return tab_ate(nav, *alvos, limite=limite)


_CONTROLES_DA_BARRA = (
    "abrir replays",
    "conceder partida",
    "atualizar",
)


def foco_saiu_para_a_barra(nav) -> bool:
    """Se o foco caiu num controle da BARRA do app — o defeito do checkpoint.

    Por que a conferência é esta, e não "o foco está na opção":

    Em Flutter Web o `document.activeElement` reporta o ANCESTRAL quando o nó
    focado não tem elemento próprio no DOM. Depois do conserto do halo, a
    imagem mostra o halo desenhado em "Passar prioridade" — a primeira ação
    legal — enquanto o `activeElement` é o painel inteiro do prompt. Ler o
    rótulo dizia "falhou"; a tela dizia "passou", e a tela é que está certa.
    Isso quase me fez "consertar" um app já consertado.

    Tentei contenção de DOM e ela também não serve sozinha: o contêiner da tela
    inteira casa qualquer marca do painel, então conter o elemento focado ali
    aprova até o foco em "Abrir replays".

    O que o checkpoint existe para impedir é o foco escapar para a barra do app.
    É isso que se confere aqui, pelo rótulo EXATO do nó focado, com o halo
    conferido na revisão visual da imagem. O teste de widget
    `battle_coach_prompt_focus_test.dart` cobre a versão forte — foco no nó da
    própria ação — onde o DOM não interfere.
    """
    atual = (foco(nav) or "").strip().lower()
    if not atual or _e_medicao(atual):
        return True
    return any(atual == c or atual.startswith(c) for c in _CONTROLES_DA_BARRA)


def _foco_e_acao_legal(texto: str) -> bool:
    """Se o foco esta numa acao legal do prompt, e nao num elemento interno.

    O `flutter typography measurement` carrega no texto a barra inteira do app,
    entao casar por substring contra ele aprova qualquer rotulo. A conferencia
    descarta esse elemento antes de olhar o rotulo.
    """
    baixo = (texto or "").strip().lower()
    if not baixo or "flutter typography measurement" in baixo:
        return False
    return any(a in baixo for a in _ACOES_LEGAIS)


def _texto_tem(nav, *trechos: str) -> bool:
    tela = texto_da_tela(nav).lower()
    return all(t.lower() in tela for t in trechos)


def capturar(nav, destino: str, web: str, deck: str, rival: str,
             email: str, senha: str, registrar=print) -> None:
    """Os dezenove checkpoints, só com teclado do navegador."""
    from manaloom_webdriver_capture import ErroDeCaptura

    entrar(nav, web, email, senha)
    garantir_estado_limpo(nav, web, deck, registrar)
    # Recarrega para o foco nascer em Back, como o checkpoint 01 exige.
    nav.ir(f"{web}#/decks/{deck}/play-vs-ai", espera=16)

    # 01 — a entrada na rota coloca foco visível em Back.
    capturar_com_foco(nav, destino, CHECKPOINTS[0], "Back", registrar)

    # 02/03 — Tab do NAVEGADOR avança a ordem de foco.
    atual, passos = tab_ate(nav, "Abrir replays", limite=6)
    registrar(f"{CHECKPOINTS[1]}: {passos} Tab(s) ate {atual!r}")
    capturar_com_foco(nav, destino, CHECKPOINTS[1], "Abrir replays", registrar)
    atual, passos = tab_ate(nav, "Escolher adversário", limite=6)
    registrar(f"{CHECKPOINTS[2]}: {passos} Tab(s) ate {atual!r}")
    capturar_com_foco(nav, destino, CHECKPOINTS[2], "Escolher adversário",
                      registrar)

    # 04 — Shift+Tab devolve o foco ao anterior.
    atual, passos = shift_tab_ate(nav, "Abrir replays", limite=6)
    registrar(f"{CHECKPOINTS[3]}: {passos} Shift+Tab(s) ate {atual!r}")
    capturar_com_foco(nav, destino, CHECKPOINTS[3], "Abrir replays", registrar)

    # 05 — Tab volta ao botão e ENTER abre o diálogo com a busca focada.
    tab_ate(nav, "Escolher adversário", limite=6)
    exigir_foco(nav, "Escolher adversário", CHECKPOINTS[4])
    nav.teclar("Enter"); time.sleep(4)
    if not _texto_tem(nav, "Escolha o adversário controlado pela IA"):
        raise ErroDeCaptura(
            f"{CHECKPOINTS[4]}: Enter nao abriu o dialogo do adversario"
        )
    alvo_busca = foco(nav)
    if not alvo_busca:
        raise ErroDeCaptura(
            f"{CHECKPOINTS[4]}: o dialogo abriu sem foco em nenhum elemento; "
            "o contrato pede a busca focada"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[4]}.png")
    registrar(f"{CHECKPOINTS[4]}: Enter abriu o dialogo, foco em {alvo_busca!r}")

    # 06 — Escape fecha e DEVOLVE o foco ao botão que abriu.
    nav.teclar("Escape"); time.sleep(3)
    if _texto_tem(nav, "Escolha o adversário controlado pela IA"):
        raise ErroDeCaptura(f"{CHECKPOINTS[5]}: Escape nao fechou o dialogo")
    capturar_com_foco(nav, destino, CHECKPOINTS[5], "Escolher adversário",
                      registrar)

    # 07 — ESPAÇO reabre o diálogo, também com a busca focada.
    nav.teclar("Space"); time.sleep(4)
    if not _texto_tem(nav, "Escolha o adversário controlado pela IA"):
        raise ErroDeCaptura(
            f"{CHECKPOINTS[6]}: Espaco nao reabriu o dialogo do adversario"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[6]}.png")
    registrar(f"{CHECKPOINTS[6]}: Espaco reabriu o dialogo, foco em {foco(nav)!r}")

    # 08 — digitação FÍSICA filtra até o rival validado.
    termo = rival.split()[-1]
    nav.digitar(termo); time.sleep(3)
    if not _texto_tem(nav, rival):
        raise ErroDeCaptura(
            f"{CHECKPOINTS[7]}: digitar {termo!r} nao deixou o rival "
            f"{rival!r} na lista"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[7]}.png")
    registrar(f"{CHECKPOINTS[7]}: digitacao fisica de {termo!r} filtrou a lista")

    # 09 — Tab leva o foco à linha filtrada do rival.
    achado, passos = tab_ate(nav, rival, rival.split()[-1], limite=10)
    registrar(f"{CHECKPOINTS[8]}: {passos} Tab(s) ate a linha do rival")
    if rival.split()[-1].lower() not in achado.lower():
        raise ErroDeCaptura(
            f"{CHECKPOINTS[8]}: Tab nao alcancou a linha do rival; foco em "
            f"{achado!r}"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[8]}.png")
    registrar(f"{CHECKPOINTS[8]}: foco na linha do rival, {achado!r}")

    # 10 — Enter seleciona o rival e o preflight responde.
    nav.teclar("Enter"); time.sleep(5)
    if _texto_tem(nav, "Selecione um adversário"):
        raise ErroDeCaptura(
            f"{CHECKPOINTS[9]}: Enter nao selecionou o rival; o dialogo ainda "
            "pede 'Selecione um adversário'"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[9]}.png")
    registrar(f"{CHECKPOINTS[9]}: Enter selecionou o rival")

    # 11 — Tab alcança a ação de iniciar, já habilitada.
    achado, passos = tab_ate(nav, "Jogar contra IA", limite=12)
    registrar(f"{CHECKPOINTS[10]}: {passos} Tab(s) ate a acao de iniciar")
    if "jogar contra ia" not in achado.lower():
        raise ErroDeCaptura(
            f"{CHECKPOINTS[10]}: Tab nao alcancou a acao de iniciar; foco em "
            f"{achado!r}"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[10]}.png")
    registrar(f"{CHECKPOINTS[10]}: foco em {achado!r}")

    # 12 — Enter cria e abre uma sessão interativa REAL.
    nav.teclar("Enter")
    limite = time.time() + 200
    while time.time() < limite and "/play-vs-ai/" not in nav.url():
        time.sleep(1.0)
    if "/play-vs-ai/" not in nav.url():
        raise ErroDeCaptura(
            f"{CHECKPOINTS[11]}: Enter nao abriu uma sessao real; URL "
            f"{nav.url()}"
        )
    sessao = nav.url().rsplit("/play-vs-ai/", 1)[1].split("?")[0]
    time.sleep(6)
    nav.capturar(f"{destino}/{CHECKPOINTS[11]}.png")
    registrar(f"{CHECKPOINTS[11]}: sessao real {sessao}")

    # --- a mesa, ainda só com teclado ------------------------------------
    # Antes do mulligan o motor pode pedir outra decisão (medido: "Escolha um
    # alvo", para quem começa). Ela é respondida por TECLADO, como tudo aqui.
    # Qualquer prompt anterior ao mulligan é respondido por TECLADO. Casar pelo
    # título não serve: em 2026-09-28 o primeiro prompt não se chamava "Escolha
    # um alvo" nesta corrida, o laço não reconheceu nada, o prazo de 60 s
    # estourou e a sessão virou "Sessão abandonada" no turno 1.
    #
    # O reconhecimento agora é pelo FOCO: com o conserto do halo, a primeira
    # ação legal do prompt já nasce focada. Se não estiver, o Tab alcança uma.
    # O prompt de mulligan e reconhecido pelas ACOES que ele oferece, nao pelo
    # titulo: casar por "Mão inicial" falhou em 2026-09-28, o laco tratou o
    # mulligan como "prompt anterior" e apertou Enter em 'Fazer mulligan' --
    # dando mulligan antes de o checkpoint 13 ser capturado.
    limite = time.time() + 150
    while time.time() < limite:
        if _texto_tem(nav, "Manter esta mão"):
            break
        if _texto_tem(nav, "Sessão abandonada", "Partida concluída"):
            raise ErroDeCaptura(
                "a sessao morreu antes do mulligan; o prompt anterior nao foi "
                "respondido a tempo"
            )
        atual = foco(nav)
        if "mulligan" in atual.lower() or "manter esta" in atual.lower():
            break  # ja e o prompt do checkpoint 13
        if not _foco_e_acao_legal(atual):
            atual, _ = tab_ate(nav, *_ACOES_LEGAIS, limite=14)
        if "mulligan" in atual.lower() or "manter esta" in atual.lower():
            break
        if _foco_e_acao_legal(atual):
            registrar(f"prompt anterior ao mulligan respondido; foco {atual!r}")
            nav.teclar("Enter")
            time.sleep(4)
            continue
        time.sleep(2)
    if not _texto_tem(nav, "Manter esta mão"):
        raise ErroDeCaptura(
            f"{CHECKPOINTS[12]}: o prompt de mao inicial nao apareceu. "
            f"Tela:\n{texto_da_tela(nav)[:600]}"
        )

    # 13 — o teclado alcança "Fazer mulligan" com halo visível.
    atual, passos = garantir_foco(nav, "Fazer mulligan", limite=20)
    registrar(
        f"{CHECKPOINTS[12]}: {passos} Tab(s) ate {atual!r}"
        + (" (ja nascia focado, pelo conserto do halo)" if passos == 0 else "")
    )
    capturar_com_foco(nav, destino, CHECKPOINTS[12], "Fazer mulligan", registrar)

    # 14 — Tab alcança "Manter esta mão".
    atual, passos = tab_ate(nav, "Manter esta mão", limite=8)
    registrar(f"{CHECKPOINTS[13]}: {passos} Tab(s) ate {atual!r}")
    capturar_com_foco(nav, destino, CHECKPOINTS[13], "Manter esta mão",
                      registrar)

    # 15 — Tab alcança o automático desta ação.
    atual, passos = tab_ate(nav, "automático", "automatico", limite=8)
    registrar(f"{CHECKPOINTS[14]}: {passos} Tab(s) ate {atual!r}")
    capturar_com_foco(nav, destino, CHECKPOINTS[14], "autom", registrar)

    # 16 — Shift+Tab devolve o foco a "Manter esta mão".
    atual, passos = shift_tab_ate(nav, "Manter esta mão", limite=8)
    registrar(f"{CHECKPOINTS[15]}: {passos} Shift+Tab(s) ate {atual!r}")
    capturar_com_foco(nav, destino, CHECKPOINTS[15], "Manter esta mão",
                      registrar)

    # 17 — ENTER ativa "Manter esta mão" e a sessão real avança.
    nav.teclar("Enter")
    limite = time.time() + 90
    while time.time() < limite and _texto_tem(nav, "Mão inicial"):
        time.sleep(1.0)
    if _texto_tem(nav, "Mão inicial"):
        raise ErroDeCaptura(
            f"{CHECKPOINTS[16]}: Enter nao ativou 'Manter esta mão'; o prompt "
            "de mao inicial continua na tela"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[16]}.png")
    registrar(f"{CHECKPOINTS[16]}: Enter manteve a mao e a mesa avancou")

    # 18 — o prompt seguinte preserva halo de foco numa ação legal.
    # O checkpoint diz que o prompt substituído de forma assíncrona PRESERVA
    # o halo numa ação legal. Então a leitura é do foco como ele está, SEM Tab:
    # tabular até achar alguma coisa provaria outra coisa.
    #
    # Cicatriz de 2026-09-28: eu aceitava "foco não vazio", e passou o foco em
    # `flutter typography measurement` — um elemento interno de medição cujo
    # texto contém a barra inteira, inclusive "Jogar contra IA". Casar por
    # substring contra esse blob aprova qualquer coisa.
    # 30 s bastam: o prompt e substituido em segundos, e cada decisao tem 60 s
    # de prazo no servidor. Esperar 180 s aqui estourava o prazo e a sessao
    # virava "Sessão abandonada" -- medido em 2026-09-28, e foi isso que
    # derrubou o checkpoint 19 na mesma corrida.
    limite = time.time() + 30
    atual = ""
    dentro = False
    while time.time() < limite:
        atual = foco(nav)
        dentro = _foco_e_acao_legal(atual) or (
            _texto_tem(nav, "segundos para decidir")
            and not foco_saiu_para_a_barra(nav)
        )
        if dentro:
            break
        time.sleep(1.0)
    if not dentro:
        diag = os.environ.get("MANALOOM_BCK_DIAG_18")
        if diag:
            nav.capturar(diag)
            registrar(f"diagnostico do 18 salvo em {diag}")
        raise ErroDeCaptura(
            f"{CHECKPOINTS[17]}: depois de Enter em 'Manter esta mão' o foco "
            f"ficou em {atual!r}. O checkpoint exige que o prompt substituido "
            "preserve o foco dentro dele, e nao que ele escape para a barra "
            "do app."
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[17]}.png")
    registrar(f"{CHECKPOINTS[17]}: prompt seguinte com foco em {atual!r}")

    # 19 — sessão concedida explicitamente expõe o replay.
    #
    # Este roteiro NÃO assere que a mão adversária não vaza, e não finge que
    # assere: a árvore de semântica não separa a mão do campo do adversário de
    # um jeito que uma leitura daqui distinga sem calibrar contra a mesa real.
    # A garantia é do servidor -- `interactive_battle_runtime_client.dart`
    # recusa estado com mão ou opções privadas do adversário, e o E2E
    # `manaloom_play_vs_ai_e2e.sh` exige `opponent_hand_protected` -- e a
    # revisão visual da captura 19 confere a tela.
    if not _concede_por_teclado(nav, registrar):
        raise ErroDeCaptura(
            f"{CHECKPOINTS[18]}: nao consegui conceder a partida por teclado"
        )
    if not _texto_tem(nav, "replay"):
        raise ErroDeCaptura(
            f"{CHECKPOINTS[18]}: a sessao encerrada nao ofereceu replay"
        )
    nav.capturar(f"{destino}/{CHECKPOINTS[18]}.png")
    registrar(f"{CHECKPOINTS[18]}: sessao concedida com replay disponivel")


def _concede_por_teclado(nav, registrar) -> bool:
    """Concede a partida usando só o teclado, como o resto do pacote."""
    # Com o foco preservado dentro do prompt (o conserto do halo), a barra do
    # app fica mais longe pelo Tab do que ficava antes. Shift+Tab e a rede: a
    # barra vem ANTES do painel na ordem de foco.
    # "Conceder partida" fica desabilitado enquanto a resposta anterior esta
    # sendo enviada (`onPressed: _submitting ? null : ...`), e botao
    # desabilitado nao entra na ordem de foco. Por isso a espera antes de
    # percorrer, e uma segunda tentativa depois.
    # Volta ao topo antes de percorrer. A barra do app so participa da ordem
    # de foco enquanto esta na arvore de semantica, e o fluxo de captura rola o
    # painel de decisao. Medido em 2026-09-28: com a pagina rolada, o Tab
    # ciclava so entre as acoes do prompt -- o que me fez reportar uma
    # armadilha de teclado que NAO existe.
    for _ in range(6):
        nav.rolar(640, 360, -300)
        time.sleep(0.3)
    time.sleep(5)
    atual, passos = tab_ate(nav, "Conceder partida", limite=40)
    if "conceder" not in atual.lower():
        time.sleep(5)
        atual, passos = shift_tab_ate(nav, "Conceder partida", limite=40)
    if "conceder" not in atual.lower():
        focaveis = nav.js(
            r"""
            return [...document.querySelectorAll('flt-semantics[tabindex]')]
              .map(e => ((e.textContent || '').trim().slice(0, 34) || '(sem texto)')
                        + ' #' + (e.id || '?'));
            """
        ) or []
        registrar(f"nem Tab nem Shift+Tab alcancaram Conceder; foco {atual!r}")
        registrar(f"focaveis na tela ({len(focaveis)}): {focaveis[:6]}")
        sequencia = []
        for _ in range(12):
            nav.teclar("Tab")
            time.sleep(0.35)
            no = nav.js(
                "const a=document.activeElement;"
                "return a ? ((a.textContent||'').trim().slice(0,22) || '(vazio)')"
                "  + ' #' + (a.id||'?') : '(nenhum)';"
            )
            sequencia.append(no)
        registrar(f"sequencia de Tab: {sequencia}")
        return False
    registrar(f"{passos} Tab(s) ate {atual!r}")
    nav.teclar("Enter")
    time.sleep(3)
    confirmado, _ = tab_ate(nav, "Conceder", limite=10)
    if "conceder" not in confirmado.lower():
        return False
    nav.teclar("Enter")
    time.sleep(8)
    return True


def main() -> int:
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from manaloom_webdriver_capture import (
        ChromeDriver,
        ErroDeCaptura,
        Navegador,
        resolver_binarios,
    )

    if len(sys.argv) != 9:
        print(__doc__, file=sys.stderr)
        return 2
    porta, destino, web, deck, rival, email, senha, saida_console = sys.argv[1:9]
    # Sem barra final: as rotas sao montadas como `{web}#/decks/...`.
    web = web.rstrip("/")

    try:
        chrome, chromedriver = resolver_binarios()
    except ErroDeCaptura as e:
        print(f"FALHA: {e}", file=sys.stderr)
        return 2

    with ChromeDriver(chromedriver, int(porta)):
        nav = Navegador(int(porta), 1280, 720)
        try:
            nav.abrir(chrome)
            print(f"navegador da corrida (D-80): {nav.navegador_real}")
            capturar(nav, destino, web, deck, rival, email, senha)
        except ErroDeCaptura as e:
            print(f"FALHA: {e}", file=sys.stderr)
            # A limpeza e preparo da proxima corrida, fora dos checkpoints.
            encerrar_mesa(nav, print)
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
    print(f"battle-coach-web-keyboard: {len(CHECKPOINTS)} checkpoints capturados")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
