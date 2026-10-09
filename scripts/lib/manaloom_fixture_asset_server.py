"""Servidor de assets das fixtures visuais, com CORS.

Motivo de existir: as fixtures serviam as imagens de carta com
`python3 -m http.server`, que nao manda `Access-Control-Allow-Origin`. A pagina
do app e servida numa porta e as imagens em outra, entao no Flutter Web a
busca e cross-origin.

Isso so machuca o caminho NAO-Scryfall. Para arte da Scryfall o app usa
`_ScryfallWebCardImage` com `WebHtmlElementStrategy.prefer`
(`app/lib/core/widgets/cached_card_image.dart:285-288, 805`), e um `<img>`
exibe cross-origin sem CORS. As imagens das fixtures nao sao Scryfall: caem no
`CachedNetworkImage`, que no CanvasKit busca por fetch e precisa do cabecalho.

Medido em 2026-09-24: `curl -I` na fixture nao trazia
`Access-Control-Allow-Origin`, e as capturas do `ux-pack-02` saiam com o
marcador de imagem quebrada no lugar da arte.

So loopback: isto serve arquivo local para prova visual, nunca para rede.
`--bind` aceita apenas `127.0.0.1` (padrao), `::1` ou `localhost`; qualquer
outro endereco, inclusive `0.0.0.0`, e recusado antes de abrir o socket.
Listagem de diretorio fica desligada: um diretorio sem `index.html` responde
404 em vez de expor os nomes dos arquivos da raiz servida.

Uso: `python3 scripts/lib/manaloom_fixture_asset_server.py <porta>
[--bind 127.0.0.1] [--directory <raiz>]`; sem `--directory`, serve o
diretorio corrente.
"""

from __future__ import annotations

import argparse
import functools
import http.server
import os
import socket

# Lista fechada, por texto. Nao e `ipaddress.is_loopback`: aquilo aceitaria
# qualquer 127.x e enderecos mapeados, e o contrato aqui e o mais estreito.
BINDS_LOOPBACK = ("127.0.0.1", "::1", "localhost")


class _ServidorComCors(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def list_directory(self, path):
        # A classe base chama isto para diretorio sem `index.html` e devolve a
        # listagem em HTML. A fixture so precisa servir arquivo por caminho
        # conhecido; a listagem e desligada e o diretorio vira 404.
        self.send_error(404, "Listagem de diretorio desligada")
        return None

    def log_message(self, formato, *args):
        # O log padrao escreve uma linha em stderr por requisicao e polui o
        # log da captura. Silencia de fato: nao repassa para a classe base.
        # `log_error` tambem passa por aqui; uma falha de arquivo continua
        # aparecendo para o app como 404 e para a captura como arte ausente.
        return


def validar_bind(bind: str) -> str:
    """Devolve o bind se for loopback; senao levanta `ValueError` claro."""
    if bind not in BINDS_LOOPBACK:
        raise ValueError(
            f"--bind {bind!r} recusado: o servidor de assets da fixture so "
            f"escuta em loopback ({', '.join(BINDS_LOOPBACK)})"
        )
    return bind


def criar_servidor(
    bind: str, porta: int, diretorio: str
) -> http.server.ThreadingHTTPServer:
    """Abre o servidor ja ligado ao socket, sem comecar a atender."""
    validar_bind(bind)

    class _Servidor(http.server.ThreadingHTTPServer):
        # `::1` exige socket IPv6; o padrao da classe e IPv4.
        address_family = socket.AF_INET6 if bind == "::1" else socket.AF_INET

    handler = functools.partial(_ServidorComCors, directory=diretorio)
    return _Servidor((bind, porta), handler)


def main(argv: list[str] | None = None) -> None:
    p = argparse.ArgumentParser()
    p.add_argument("porta", type=int)
    p.add_argument("--bind", default="127.0.0.1")
    # Sem `--directory` serve o diretorio corrente, como `python3 -m
    # http.server`: um roteiro de fixture que ja fez `cd` para a raiz do
    # repositorio serve `app/assets/branding/...` por caminho relativo.
    # Exigir o argumento derrubou as fixtures visuais da arvore antiga com
    # "Local visual asset server stopped unexpectedly", medido em 2026-09-29.
    # Quem quer outra raiz passa o diretorio explicito.
    p.add_argument("--directory", default=os.getcwd())
    args = p.parse_args(argv)
    try:
        validar_bind(args.bind)
    except ValueError as erro:
        # `p.error` sai com codigo 2 e a mensagem, sem traceback.
        p.error(str(erro))

    with criar_servidor(args.bind, args.porta, args.directory) as s:
        s.serve_forever()


if __name__ == "__main__":
    main()
