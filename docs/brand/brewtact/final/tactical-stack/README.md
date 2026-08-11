# BrewTact — Tactical Stack

Status: direção escolhida para produção em 2026-08-11.

## Ideia da marca

O símbolo combina duas faixas inspiradas nas bordas de cartas. A faixa Brass
forma o espaço de montagem; a faixa Frost atravessa a composição e termina em
um corte tático. O vazio central preserva a leitura de pilha/deck sem copiar
versos de carta, símbolos de mana, marcas de coleção ou identidade da Wizards.

O desenho possui cinco polígonos sólidos, sem efeitos raster, e continua
legível em 16 px. As facetas escuras pertencem à construção da fita e não devem
ser substituídas por sombras ou gradientes livres.

## Paleta canônica

| Token | Hex | Uso |
| --- | --- | --- |
| Abyss | `#0B0D12` | fundo de marca, ícone e splash |
| Slate | `#151821` | campo visual secundário |
| Elevated Slate | `#1D222C` | profundidade discreta |
| Brass | `#C58B2A` | faixa principal |
| Brass Highlight | `#E0A93B` | face iluminada e `Tact` |
| Brass Shadow | `#8E641B` | dobra interna |
| Frost | `#6FA8DC` | faixa tática de apoio |
| Deep Frost | `#3E5F8A` | dobra Frost |
| Ivory | `#F3EFE3` | `Brew` e versão clara |
| Mist | `#B8C0CC` | apoio textual |
| Muted Outline | `#293041` | linhas ambientais |

Não introduzir roxo, verde, coral, branco puro ou dourados fora desta tabela em
ativos institucionais.

## Lockups e tipografia

- `brewtact-tactical-stack-mark.svg`: símbolo principal.
- `brewtact-wordmark.svg`: wordmark convertido em contornos vetoriais;
  `Brew` em Ivory e `Tact` em Brass Highlight.
- `brewtact-lockup-horizontal.svg`: padrão para cabeçalhos e site.
- `brewtact-lockup-stacked.svg`: abertura, campanhas e materiais quadrados.
- arquivos `mono`: uma tinta para gravação, themed icon e fundos sem controle.

O wordmark deriva da Fraunces já distribuída pelo produto, mas os masters não
dependem da fonte instalada porque cada glifo foi convertido em path. Textos de
interface continuam usando os tokens tipográficos do app; não usar o wordmark
como substituto de títulos ou botões.

## Espaço e redução

- Área de proteção mínima: metade da altura aparente da faixa Frost ao redor do
  mark.
- Mark colorido: mínimo recomendado de 16 px; em 16 px não adicionar contorno.
- Lockup horizontal: mínimo recomendado de 128 px de largura.
- Abaixo de 128 px usar somente o mark.
- Não rotacionar, inclinar, aplicar glow, trocar a ordem das fitas ou esticar.

## Splash e imagens de apoio

O splash nativo usa somente Abyss + mark centralizado. Nome e tagline não são
gravados na imagem, permitindo localização e atualização no runtime. Os fundos
Flutter portrait/wide usam formas de cartas e uma rota de decisão em baixa
ênfase; o conteúdo e o CTA permanecem a camada dominante.

`home_hero` e `home_hero_banner` não contêm texto. A margem esquerda do banner
é intencionalmente limpa para título e CTA responsivos.

## Exportação reproduzível

Pré-requisitos locais: Python 3, ImageMagick (`magick`) e HarfBuzz (`hb-view`).

```bash
python3 scripts/generate_brewtact_brand_assets.py
```

O comando recria masters, previews, assets Flutter/site, launchers
Android/iOS, LaunchImage, favicon e ícones PWA. O inventário com SHA-256 fica em
`asset-manifest.json`.

## Limite de propriedade intelectual

A marca é original e adjacente ao universo de card games. Não incorporar
Planeswalker, símbolos de mana, pentágono de cores, verso oficial de carta,
set marks, logos ou trade dress de Magic/Wizards.
