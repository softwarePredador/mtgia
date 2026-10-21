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

`--bind 127.0.0.1` continua obrigatorio: isto serve arquivo local para prova
visual, nunca para rede.
"""

import argparse
import functools
import http.server
import os


class _ServidorComCors(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, formato, *args):
        # O log padrao vai para stderr e polui o log da captura.
        super().log_message(formato, *args)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("porta", type=int)
    p.add_argument("--bind", default="127.0.0.1")
    # As sete fixtures visuais chamam este servidor SEM `--directory`, depois
    # de um `cd` para a raiz do repositorio -- elas servem
    # `app/assets/branding/...` por caminho relativo. Exigir o argumento
    # derrubava todas elas com "Local visual asset server stopped
    # unexpectedly", medido em 2026-09-29. O gate de evidencia passa o
    # diretorio explicito, e continua funcionando.
    p.add_argument("--directory", default=os.getcwd())
    args = p.parse_args()

    handler = functools.partial(_ServidorComCors, directory=args.directory)
    with http.server.ThreadingHTTPServer((args.bind, args.porta), handler) as s:
        s.serve_forever()


if __name__ == "__main__":
    main()
