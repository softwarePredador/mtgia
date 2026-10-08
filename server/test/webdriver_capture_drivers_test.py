#!/usr/bin/env python3
"""Roteiros de captura WebDriver de `scripts/lib` (BT-UIEV-001).

Nenhum teste aqui abre navegador nem ChromeDriver; as partes conferidas sao as
que decidem antes disso ou no lugar disso:

- `manaloom_captura_card_details_navigation.py`: o ponto de reserva da aba
  "Cartas" so vale com o rotulo EXATO "Cartas" (igualdade depois de
  normalizar espacos), nunca "contem";
- `manaloom_captura_optimization_card_reader.py`: argv errado sai com
  mensagem e codigo 2, sem traceback;
- `manaloom_captura_play_vs_ai.py`: a limpeza de mesas aceita a listagem como
  objeto ou lista crua, sem `AttributeError` de `list.get`.
"""

from __future__ import annotations

import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[2]
LIB = REPO_ROOT / "scripts" / "lib"
CARD_DETAILS = LIB / "manaloom_captura_card_details_navigation.py"
CARD_READER = LIB / "manaloom_captura_optimization_card_reader.py"
PLAY_VS_AI = LIB / "manaloom_captura_play_vs_ai.py"

# Os roteiros importam `manaloom_webdriver_capture` de dentro das funcoes,
# como irmao em `scripts/lib`.
if str(LIB) not in sys.path:
    sys.path.insert(0, str(LIB))


def _load(path: Path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


card_details = _load(CARD_DETAILS)
play_vs_ai = _load(PLAY_VS_AI)
from manaloom_webdriver_capture import ErroDeCaptura  # noqa: E402


class _NavFalso:
    """Devolve, em ordem, o que cada `nav.js` responderia no navegador."""

    def __init__(self, *respostas) -> None:
        self.respostas = list(respostas)

    def js(self, _script, *_args):
        return self.respostas.pop(0)


class CartasTabLabelTest(unittest.TestCase):
    def test_exact_label_after_whitespace_normalization_passes(self) -> None:
        for aria_label, texto in (
            ("Cartas", ""),
            ("", "Cartas"),
            ("  Cartas\n", ""),
            ("", "\tCartas  "),
            ("Cartas", "Cartas"),
        ):
            with self.subTest(aria_label=aria_label, texto=texto):
                self.assertTrue(
                    card_details.rotulo_e_aba_cartas(aria_label, texto)
                )

    def test_label_that_only_contains_cartas_is_refused(self) -> None:
        for aria_label, texto in (
            ("Cartas do deck", ""),
            ("", "Sem cartas"),
            ("", "Visão geral Cartas Análise"),
            ("Cartas\nTab 2 of 3", ""),
            ("Cartas", "Cartas (12)"),
            ("cartas", ""),
            ("", ""),
        ):
            with self.subTest(aria_label=aria_label, texto=texto):
                self.assertFalse(
                    card_details.rotulo_e_aba_cartas(aria_label, texto)
                )

    def test_fallback_point_requires_the_exact_label(self) -> None:
        reserva = card_details._RESERVA_ABA_CARTAS
        # Primeira chamada: nenhuma folha "Cartas"; segunda: o menor no que
        # cobre o ponto de reserva.
        nav = _NavFalso(None, {"al": "", "t": " Cartas "})
        self.assertEqual(card_details._centro_da_aba_cartas(nav), reserva)

        for no in (
            {"al": "", "t": "Visão geral Cartas Análise"},
            {"al": "Cartas do deck", "t": ""},
            {"al": "", "t": ""},
            None,
        ):
            with self.subTest(no=no):
                with self.assertRaisesRegex(ErroDeCaptura, "exatamente 'Cartas'"):
                    card_details._centro_da_aba_cartas(_NavFalso(None, no))

    def test_semantic_leaf_found_first_wins(self) -> None:
        nav = _NavFalso([100, 200])
        self.assertEqual(card_details._centro_da_aba_cartas(nav), (100, 200))


class CardReaderArgvTest(unittest.TestCase):
    def _rodar(self, *args: str) -> subprocess.CompletedProcess:
        # Diretorio descartavel: se a validacao regredir e o roteiro seguir
        # adiante, o `<saida-console>` relativo cai aqui, nao no repositorio.
        with tempfile.TemporaryDirectory() as cwd:
            return subprocess.run(
                [sys.executable, str(CARD_READER), *args],
                capture_output=True,
                text=True,
                timeout=30,
                check=False,
                cwd=cwd,
            )

    def test_wrong_arity_is_a_usage_error_without_traceback(self) -> None:
        nove = ["9515", "destino", "http://127.0.0.1:1/app", "deck", "email",
                "senha", "chrome", "chromedriver", "console.txt"]
        for args in ([], nove[:8], nove + ["extra"]):
            with self.subTest(quantos=len(args)):
                resultado = self._rodar(*args)
                self.assertEqual(resultado.returncode, 2, resultado.stderr)
                self.assertIn("FALHA: esperados 9 argumentos", resultado.stderr)
                self.assertIn("Uso:", resultado.stderr)
                self.assertNotIn("Traceback", resultado.stderr)

    def test_bad_port_is_a_usage_error_without_traceback(self) -> None:
        resto = ["destino", "http://127.0.0.1:1/app", "deck", "email",
                 "senha", "chrome", "chromedriver", "console.txt"]
        for porta in ("abc", "0", "70000", ""):
            with self.subTest(porta=porta):
                resultado = self._rodar(porta, *resto)
                self.assertEqual(resultado.returncode, 2, resultado.stderr)
                self.assertIn("<porta-webdriver>", resultado.stderr)
                self.assertNotIn("Traceback", resultado.stderr)


class _RespostaFalsa(io.BytesIO):
    def __enter__(self):
        return self

    def __exit__(self, *exc) -> None:
        self.close()


class PlayVsAiSessionCleanupTest(unittest.TestCase):
    def test_sessions_from_object_or_raw_list(self) -> None:
        viva = {"session_id": "s1"}
        self.assertEqual(play_vs_ai._sessoes_da_lista([viva]), [viva])
        self.assertEqual(
            play_vs_ai._sessoes_da_lista({"sessions": [viva]}), [viva]
        )
        self.assertEqual(play_vs_ai._sessoes_da_lista({"items": [viva]}), [viva])
        for estranho in ({}, {"sessions": "x"}, "texto", 3, None):
            with self.subTest(estranho=estranho):
                self.assertEqual(play_vs_ai._sessoes_da_lista(estranho), [])

    def _limpar_com(self, listagem) -> tuple[int, list[str], list[str]]:
        pedidos: list[str] = []
        registros: list[str] = []

        def urlopen(pedido, timeout=None):
            pedidos.append(f"{pedido.get_method()} {pedido.full_url}")
            if pedido.get_method() == "GET":
                return _RespostaFalsa(json.dumps(listagem).encode())
            corpo = json.loads(pedido.data.decode())
            self.assertTrue(corpo["idempotency_key"].startswith("battle-concede:"))
            return _RespostaFalsa(b"{}")

        with mock.patch("urllib.request.urlopen", urlopen):
            encerradas = play_vs_ai.limpar_mesas_pela_api(
                "http://127.0.0.1:9/api", "token", "deck-1", registros.append
            )
        return encerradas, pedidos, registros

    def test_cleanup_concedes_live_tables_from_a_raw_list(self) -> None:
        encerradas, pedidos, _ = self._limpar_com(
            [{"session_id": "s1"}, {"id": "s2", "terminal": True}, "lixo"]
        )
        self.assertEqual(encerradas, 1)
        self.assertEqual(
            pedidos,
            [
                "GET http://127.0.0.1:9/api/ai/battle/sessions?deck_id=deck-1&limit=20",
                "POST http://127.0.0.1:9/api/ai/battle/sessions/s1/concede",
            ],
        )

    def test_cleanup_still_reads_the_route_object(self) -> None:
        encerradas, pedidos, _ = self._limpar_com({"sessions": [{"id": "s3"}]})
        self.assertEqual(encerradas, 1)
        self.assertTrue(pedidos[-1].endswith("/sessions/s3/concede"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
