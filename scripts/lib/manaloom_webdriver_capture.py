"""Harness WebDriver para as capturas que exigem navegador de verdade.

Alguns pacotes de evidência não podem ser capturados por `flutter drive`, porque
o que eles provam é justamente o caminho que o evento sintético do Flutter pula:
histórico do navegador, hover e teclado físico sobre platform view. A arte da
carta na web é um `<img>` de plataforma
(`app/lib/core/widgets/cached_card_image.dart`), e é ali que a web costuma
falhar.

Este módulo existe para que esse trabalho pare de ser conduzido à mão. Cada
regra abaixo é cicatriz de uma corrida de 2026-09-24 que produziu evidência
FALSA — as quatro primeiras só foram pegas porque alguém abriu a imagem, nunca
pelo código:

1. **Viewport conferida, nunca presumida.** A janela apareceu com 942x770
   quando o contrato pedia 1440x900, e as capturas teriam ido embora fora do
   contrato sem ninguém notar. `abrir` confere e aborta.

2. **Foco reafirmado a cada leitura.** `battle_coach_screen.dart` faz
   `_appActive = state == resumed`, e o app para de atualizar quando a janela
   perde o foco. Janela visível mas sem foco já conta como inativa: o tabuleiro
   congela e o prazo do prompt expira no servidor.

3. **Rótulo é folha pequena.** Filtrar `children.length <= 1` sozinho deixa
   passar o contêiner da tela inteira, cujo `textContent` contém tudo. Isso
   gerou três capturas mentirosas. O teto de área separa rótulo de contêiner.

4. **Clique não exige `role="button"`.** A mesma linha vem com `role=""` numa
   largura e `role="button"` noutra.

5. **JS em string raw.** `\\n` dentro de regex virou quebra de linha real duas
   vezes, e o erro aparecia como "não achei o elemento".

6. **Falha de JS é registrada, nunca engolida.** `except: return False`
   transformou erro de sintaxe em "não achei o botão" e matou duas corridas.

Os binários saem do MESMO pin dos gates em bash
(`scripts/lib/manaloom_chromedriver.sh`): `resolver_binarios` fonteia aquela
biblioteca, resolve o ChromeDriver pinado (ou o override
`MANALOOM_CHROMEDRIVER_BIN`) e falha fechado se o major dele não for o do
Chrome que vai dirigir. O Chrome é `CHROME_EXECUTABLE`, com o mesmo padrão dos
roteiros de visual QA. Nenhum binário vem do PATH.
"""

from __future__ import annotations

import atexit
import base64
import json
import os
import signal
import subprocess
import time
import urllib.error
import urllib.request

_RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_BIBLIOTECA_DO_PIN = os.path.join(_RAIZ, "scripts", "lib", "manaloom_chromedriver.sh")
CHROME_PADRAO = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

ENABLE = r"""
const ph = document.querySelector('flt-semantics-placeholder');
if (ph) { ph.click(); return 'clicado'; }
return document.querySelector('flt-semantics-host') ? 'ativo' : 'ausente';
"""

# Rótulos: folha (no máximo um filho) E área pequena. Ver regra 3.
LER = r"""
const todos = [...document.querySelectorAll('flt-semantics')].map(e => ({
  e,
  t: (e.textContent || '').trim(),
  role: e.getAttribute('role') || '',
  k: e.children.length,
  r: e.getBoundingClientRect(),
}));
const folha = o => o.k <= 1 && o.r.width * o.r.height < 200000;
return {
  url: location.href,
  rotulos: todos.filter(folha).map(o => o.t.replace(/\n/g, ' ').slice(0, 80))
                .filter(t => t),
  botoes: todos.filter(o => o.role === 'button' && folha(o))
               .map(o => ({
                 t: o.t.replace(/\n/g, ' ').trim().slice(0, 60),
                 x: Math.round(o.r.x), y: Math.round(o.r.y),
                 w: Math.round(o.r.width), h: Math.round(o.r.height),
               })),
};
"""

# Clique por texto: menor área vence, e o contêiner de tela inteira nunca ganha.
CLICAR = r"""
const alvo = arguments[0];
const candidatos = [...document.querySelectorAll('flt-semantics')]
  .map(e => ({e, r: e.getBoundingClientRect(),
              t: (e.textContent || '').replace(/\n/g, ' ').trim()}))
  .filter(o => o.e.children.length <= 1)
  .filter(o => o.r.width * o.r.height < 200000)
  .filter(o => o.t.includes(alvo));
if (!candidatos.length) return {ok: false};
candidatos.sort((a, b) => a.r.width * a.r.height - b.r.width * b.r.height);
const alvoEl = candidatos[0];
alvoEl.e.click();
return {ok: true, t: alvoEl.t.slice(0, 60),
        x: Math.round(alvoEl.r.x + alvoEl.r.width / 2),
        y: Math.round(alvoEl.r.y + alvoEl.r.height / 2)};
"""

# Teclas especiais do W3C WebDriver (ponto de código da área privada).
TECLAS = {
    "tab": "",
    "enter": "",
    "escape": "",
    "space": " ",
    "shift": "",
    "backspace": "",
}


class ErroDeCaptura(RuntimeError):
    """Falha que deve interromper a captura em vez de virar evidência torta."""


def resolver_binarios(chrome: str | None = None) -> tuple[str, str]:
    """Devolve `(chrome, chromedriver)` pelo pin compartilhado com os gates.

    Fonteia `scripts/lib/manaloom_chromedriver.sh` num bash próprio e chama as
    mesmas funções que os roteiros de visual QA chamam: o driver é o pin em
    cache (ou `MANALOOM_CHROMEDRIVER_BIN`) e o major dele tem de ser o do
    Chrome. Um pin divergente aborta aqui, antes de abrir qualquer navegador.
    """
    chrome = chrome or os.environ.get("CHROME_EXECUTABLE") or CHROME_PADRAO
    if not os.access(chrome, os.X_OK):
        raise ErroDeCaptura(
            f"BLOCKED: Chrome nao executa: {chrome} (defina CHROME_EXECUTABLE)"
        )
    script = (
        'set -euo pipefail; source "$1"; resolve_manaloom_chromedriver; '
        'assert_manaloom_chromedriver_matches_chrome "$2"; '
        'printf "%s\\n" "$MANALOOM_CHROMEDRIVER_BIN_RESOLVED"'
    )
    resultado = subprocess.run(
        ["/bin/bash", "-c", script, "resolver", _BIBLIOTECA_DO_PIN, chrome],
        capture_output=True, text=True, timeout=60,
    )
    if resultado.returncode != 0:
        raise ErroDeCaptura(
            "o pin do ChromeDriver recusou a corrida: "
            + (resultado.stderr.strip() or f"rc={resultado.returncode}")
        )
    return chrome, resultado.stdout.strip()


class ChromeDriver:
    """ChromeDriver com vida atada à corrida.

    A regra é do dono e é simples: nada fica rodando entre corridas. Um
    ChromeDriver vivo entre capturas é o que permite que um Chrome sobreviva
    sem ninguém reparar -- e foi exatamente assim que um deles passou 17 horas
    e meia aberto na máquina dele.

    O driver nasce numa sessão de processo própria (`start_new_session`), e o
    encerramento mata o GRUPO inteiro: o Chrome que ele lança é filho dele e
    morre junto, mesmo que o `DELETE /session` não chegue. `TMPDIR=/tmp`
    mantém o diretório de perfil do navegador fora do TMPDIR herdado do
    chamador, que pode ser um diretório de sessão longo ou removido no meio.
    """

    def __init__(self, binario: str, porta: int) -> None:
        self.binario = binario
        self.porta = porta
        self.processo: subprocess.Popen | None = None

    def __enter__(self) -> "ChromeDriver":
        self.processo = subprocess.Popen(
            [self.binario, f"--port={self.porta}", "--allowed-ips=127.0.0.1"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            env=dict(os.environ, TMPDIR="/tmp"),
        )
        atexit.register(self.parar)
        for _ in range(40):
            try:
                urllib.request.urlopen(
                    f"http://127.0.0.1:{self.porta}/status", timeout=1
                )
                return self
            except Exception:
                time.sleep(0.25)
        self.parar()
        raise ErroDeCaptura(f"ChromeDriver nao subiu na porta {self.porta}")

    def __exit__(self, *_) -> None:
        self.parar()

    def parar(self) -> None:
        proc = self.processo
        self.processo = None
        if proc is None:
            return
        # O grupo existe enquanto houver membro vivo, mesmo com o driver já
        # morto: um Chrome órfão do grupo ainda é alcançado por aqui.
        grupo = proc.pid
        for sinal in (signal.SIGTERM, signal.SIGKILL):
            try:
                os.killpg(grupo, sinal)
            except ProcessLookupError:
                break
            limite = time.time() + 5
            while time.time() < limite:
                proc.poll()  # colhe o driver: zumbi nao conta como vivo
                if not _grupo_vivo(grupo):
                    break
                time.sleep(0.2)
            else:
                continue  # ainda ha membro vivo: sobe para SIGKILL
            break
        if proc.poll() is None:
            proc.kill()
            proc.wait(timeout=5)


def _grupo_vivo(grupo: int) -> bool:
    try:
        os.killpg(grupo, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


class Navegador:
    """Sessão WebDriver com viewport conferida, foco reafirmado e morte certa.

    "Morte certa" é literal e foi aprendida da pior forma: um Chrome deste
    harness ficou **17 horas e meia órfão com janela aberta** na máquina do
    dono, porque o `finally` do script não roda quando o processo é morto e o
    `DELETE /session` não chega quando o ChromeDriver já caiu.

    O encerramento tem três camadas, e nenhuma depende da anterior: `atexit`,
    handlers de SIGINT/SIGTERM/SIGHUP, e -- se o WebDriver não responder -- o
    PID do navegador morto direto. O PID vem da própria sessão
    (`goog:processID`, devolvido pelo ChromeDriver ao criar a sessão), nunca de
    um `pgrep` global: com outra corrida ou outra frente usando WebDriver na
    mesma máquina, o `pgrep` podia devolver o Chrome DELAS.
    """

    def __init__(
        self, porta: int, largura: int, altura: int, headless: bool = True
    ) -> None:
        self.base = f"http://127.0.0.1:{porta}"
        self.largura = largura
        self.altura = altura
        self.headless = headless
        self.sessao: str | None = None
        self.pid_navegador: int | None = None
        self.navegador_real = ""
        self._encerramento_registrado = False

    # -- transporte ----------------------------------------------------------

    def _chamar(self, metodo: str, caminho: str, corpo=None):
        dados = json.dumps(corpo).encode() if corpo is not None else None
        req = urllib.request.Request(
            self.base + caminho,
            data=dados,
            method=metodo,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            detalhe = e.read().decode("utf-8", "replace")[:400]
            raise ErroDeCaptura(
                f"WebDriver {metodo} {caminho} devolveu {e.code}: {detalhe}"
            ) from e
        except urllib.error.URLError as e:
            raise ErroDeCaptura(
                f"WebDriver {metodo} {caminho} inalcancavel: {e.reason}"
            ) from e

    def js(self, script: str, *args):
        """Executa JS. Regra 6: erro aparece, nunca vira 'não achei'."""
        return self._chamar(
            "POST",
            f"/session/{self.sessao}/execute/sync",
            {"script": script, "args": list(args)},
        )["value"]

    # -- ciclo de vida -------------------------------------------------------

    def abrir(self, chrome: str) -> None:
        headless = self.headless
        largura, altura = self.largura, self.altura
        caps = {
            "capabilities": {
                "alwaysMatch": {
                    "browserName": "chrome",
                    # Console do navegador: o indexador de evidencia confere o
                    # log contra excecoes, overflow de RenderFlex e falha de
                    # CachedCardImage. Sem pedir o log aqui, nao ha como
                    # afirmar `forbidden_entries: 0` com honestidade.
                    "goog:loggingPrefs": {"browser": "ALL"},
                    "goog:chromeOptions": {
                        "binary": chrome,
                        "args": [
                            # Headless por padrao, a pedido do dono: janela
                            # abrindo e roubando foco atrapalha quem esta
                            # usando a maquina. `--headless=new` e o proprio
                            # Chrome sem janela, mesmo motor, e as acoes do
                            # WebDriver continuam gerando eventos reais via
                            # CDP -- historico, teclado fisico e hover seguem
                            # valendo.
                            #
                            # Efeito colateral bom: sem janela nao ha disputa
                            # de foco do sistema, e o `document.hasFocus()`
                            # falso que travava o polling do play-vs-ai deixa
                            # de acontecer.
                            *(["--headless=new"] if headless else []),
                            f"--window-size={largura},{altura}",
                            "--hide-scrollbars",
                            "--no-sandbox",
                            "--disable-gpu",
                            "--force-device-scale-factor=1",
                        ],
                    },
                }
            }
        }
        resposta = self._chamar("POST", "/session", caps)["value"]
        self.sessao = resposta["sessionId"]
        capacidades = resposta.get("capabilities") or {}
        # D-80: a procedencia registra o navegador REAL da corrida, lido da
        # sessao, em vez de um nome fixo de agente ou de navegador.
        self.navegador_real = " ".join(
            parte
            for parte in (
                str(capacidades.get("browserName") or ""),
                str(capacidades.get("browserVersion") or ""),
                "headless" if headless else "",
            )
            if parte
        )
        pid = capacidades.get("goog:processID")
        self.pid_navegador = int(pid) if isinstance(pid, int) and pid > 0 else None
        self._registrar_encerramento()
        self._dimensionar()

    def _registrar_encerramento(self) -> None:
        """Tres camadas, nenhuma dependendo da anterior."""
        if self._encerramento_registrado:
            return
        self._encerramento_registrado = True
        atexit.register(self.fechar)
        for sinal in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            anterior = signal.getsignal(sinal)

            def ao_receber(_s, _f, _anterior=anterior):
                self.fechar()
                if callable(_anterior):
                    _anterior(_s, _f)
                else:
                    raise SystemExit(130)

            try:
                signal.signal(sinal, ao_receber)
            except ValueError:
                pass  # fora da thread principal: as outras camadas cobrem

    def _dimensionar(self) -> None:
        """Regra 1: a viewport é conferida, e a captura aborta se não bater.

        A altura da janela NAO e a da viewport, e isso vale tambem em headless:
        com `--window-size=1280,720` a viewport sai 1280x577, medido em
        2026-09-24. Quanto o navegador reserva varia por modo e versao, entao
        se PROCURA a altura de janela que produz a viewport pedida, em vez de
        calcular a partir de uma constante.
        """
        vw = vh = None
        for extra in (0, 143, 150, 160, 130, 120, 175, 100, 90, 80):
            self._chamar(
                "POST",
                f"/session/{self.sessao}/window/rect",
                {"width": self.largura, "height": self.altura + extra,
                 "x": 0, "y": 0},
            )
            time.sleep(0.4)
            vw, vh = self.js("return [innerWidth, innerHeight];")
            if (vw, vh) == (self.largura, self.altura):
                return
        raise ErroDeCaptura(
            f"viewport {vw}x{vh}, esperado {self.largura}x{self.altura}"
        )

    def focar(self) -> None:
        """Regra 2. `switchToWindow` é o que de fato devolve `hasFocus`."""
        handle = self._chamar("GET", f"/session/{self.sessao}/window")["value"]
        self._chamar("POST", f"/session/{self.sessao}/window", {"handle": handle})
        vw, vh = self.js("return [innerWidth, innerHeight];")
        if (vw, vh) != (self.largura, self.altura):
            self._dimensionar()

    def fechar(self) -> None:
        """Encerra a sessao e GARANTE que o navegador morre.

        O `DELETE` educado falha em silencio quando o ChromeDriver ja caiu --
        e foi assim que um Chrome ficou 17h30 aberto. Por isso o PID e morto
        depois, mesmo que o DELETE tenha parecido dar certo.
        """
        if self.sessao:
            try:
                self._chamar("DELETE", f"/session/{self.sessao}")
            except ErroDeCaptura:
                pass
            self.sessao = None
        pid = self.pid_navegador
        self.pid_navegador = None
        if not pid:
            return
        for sinal, espera in ((signal.SIGTERM, 2.0), (signal.SIGKILL, 0.5)):
            try:
                os.kill(pid, 0)
            except OSError:
                return  # ja morreu
            try:
                os.kill(pid, sinal)
            except OSError:
                return
            time.sleep(espera)

    # -- navegação e leitura -------------------------------------------------

    def ir(self, url: str, espera: float = 8.0) -> None:
        self._chamar("POST", f"/session/{self.sessao}/url", {"url": url})
        time.sleep(espera)
        self.ativar_semantica()

    def voltar(self, espera: float = 3.0) -> None:
        """Histórico REAL do navegador, que é o que certos contratos exigem."""
        self._chamar("POST", f"/session/{self.sessao}/back", {})
        time.sleep(espera)
        self.ativar_semantica()

    def avancar(self, espera: float = 3.0) -> None:
        self._chamar("POST", f"/session/{self.sessao}/forward", {})
        time.sleep(espera)
        self.ativar_semantica()

    def url(self) -> str:
        return self._chamar("GET", f"/session/{self.sessao}/url")["value"]

    def ativar_semantica(self) -> str:
        return self.js(ENABLE)

    def ler(self, tentativas: int = 3) -> dict:
        """Lê a árvore, reativando a semântica quando vier vazia."""
        for _ in range(tentativas):
            self.focar()
            estado = self.js(LER)
            if estado["rotulos"] or estado["botoes"]:
                return estado
            self.ativar_semantica()
            time.sleep(0.7)
        return {"url": self.url(), "rotulos": [], "botoes": []}

    # -- interação -----------------------------------------------------------

    def _acoes(self, acoes: list) -> None:
        self._chamar("POST", f"/session/{self.sessao}/actions", {"actions": acoes})

    def clicar_texto(self, texto: str) -> dict:
        """Regra 4: não exige `role="button"`."""
        return self.js(CLICAR, texto)

    def clicar_ponto(self, x: int, y: int) -> None:
        self._acoes([{
            "type": "pointer", "id": "mouse",
            "parameters": {"pointerType": "mouse"},
            "actions": [
                {"type": "pointerMove", "x": int(x), "y": int(y), "duration": 60},
                {"type": "pointerDown", "button": 0},
                {"type": "pause", "duration": 60},
                {"type": "pointerUp", "button": 0},
            ],
        }])

    def passar_mouse(self, x: int, y: int, parar_ms: int = 700) -> None:
        """Hover de verdade: o ponteiro move e FICA, que é o que dispara hover."""
        self._acoes([{
            "type": "pointer", "id": "mouse",
            "parameters": {"pointerType": "mouse"},
            "actions": [
                {"type": "pointerMove", "x": int(x), "y": int(y), "duration": 220},
                {"type": "pause", "duration": int(parar_ms)},
            ],
        }])

    def rolar(self, x: int, y: int, dy: int, dx: int = 0) -> None:
        """Roda do mouse de verdade.

        `element.scrollTop` nao move nada no CanvasKit: o Flutter Web desenha o
        conteudo e escuta evento de roda, nao rolagem de DOM. Medido em
        2026-09-24 tentando rolar a folha de otimizacao -- a tela ficou
        exatamente igual.
        """
        self._acoes([{
            "type": "wheel", "id": "roda",
            "actions": [{
                "type": "scroll", "x": int(x), "y": int(y),
                "deltaX": int(dx), "deltaY": int(dy), "duration": 200,
            }],
        }])

    def teclar(self, *teclas: str) -> None:
        """Tecla física no nível do navegador, não evento sintético do Flutter."""
        acoes = []
        for t in teclas:
            v = TECLAS.get(t.lower(), t)
            acoes.append({"type": "keyDown", "value": v})
            acoes.append({"type": "keyUp", "value": v})
        self._acoes([{"type": "key", "id": "teclado", "actions": acoes}])

    def teclar_com_shift(self, tecla: str) -> None:
        shift = TECLAS["shift"]
        v = TECLAS.get(tecla.lower(), tecla)
        self._acoes([{"type": "key", "id": "teclado", "actions": [
            {"type": "keyDown", "value": shift},
            {"type": "keyDown", "value": v},
            {"type": "keyUp", "value": v},
            {"type": "keyUp", "value": shift},
        ]}])

    def digitar(self, texto: str) -> None:
        acoes = []
        for ch in texto:
            acoes.append({"type": "keyDown", "value": ch})
            acoes.append({"type": "keyUp", "value": ch})
        self._acoes([{"type": "key", "id": "teclado", "actions": acoes}])

    def elemento_focado(self) -> str:
        return self.js(
            "const a = document.activeElement;"
            "if (!a) return '';"
            "return (a.getAttribute('aria-label') || a.textContent || a.tagName)"
            "  .trim().slice(0, 80);"
        )

    def console(self) -> list[dict]:
        """Mensagens do console do navegador desde a ultima leitura."""
        try:
            resposta = self._chamar(
                "POST", f"/session/{self.sessao}/log", {"type": "browser"}
            )
        except ErroDeCaptura:
            return []
        return resposta.get("value") or []

    def gravar_console(self, caminho: str) -> int:
        """Grava o console no log de runtime da evidencia e devolve a contagem.

        O indexador confere esse log contra excecao, overflow de RenderFlex e
        falha de CachedCardImage; sem a coleta nao da para afirmar
        `forbidden_entries: 0`.
        """
        linhas = self.console()
        os.makedirs(os.path.dirname(os.path.abspath(caminho)), exist_ok=True)
        with open(caminho, "w", encoding="utf-8") as fh:
            for m in linhas:
                fh.write(f"[{m.get('level')}] {m.get('message')}\n")
        return len(linhas)

    # -- captura -------------------------------------------------------------

    def capturar(self, caminho: str) -> int:
        """Grava o PNG e confere o tamanho contra o contrato."""
        self.focar()
        bruto = base64.b64decode(
            self._chamar("GET", f"/session/{self.sessao}/screenshot")["value"]
        )
        os.makedirs(os.path.dirname(caminho), exist_ok=True)
        with open(caminho, "wb") as f:
            f.write(bruto)
        # PNG: largura e altura ficam no cabeçalho IHDR, bytes 16..24.
        largura = int.from_bytes(bruto[16:20], "big")
        altura = int.from_bytes(bruto[20:24], "big")
        if (largura, altura) != (self.largura, self.altura):
            raise ErroDeCaptura(
                f"{os.path.basename(caminho)} saiu {largura}x{altura}, "
                f"o contrato pede {self.largura}x{self.altura}"
            )
        return len(bruto)
