# ADR 0010 — Transição da marca pública ManaLoom para BrewTact

- Status: accepted
- Date: 2026-08-11
- Scope: identidade pública, assets, textos, metadados, e-mails, relatórios,
  launchers e splashes do app e do site

## Context

O domínio `manaloom.com` não pertence ao projeto e a expressão ManaLoom já é
usada comercialmente por terceiros. O produto ainda não possui publicação
definitiva nas lojas, portanto esta é a janela de menor risco para estabelecer
uma marca global controlável.

A identidade antiga também estava fragmentada entre um `M` rasterizado, um
glyph de tear, ícones de launcher e artes com cinco cartas. Não existia master
vetorial nem pipeline único de exportação. Parte da arte se aproximava
desnecessariamente da linguagem visual proprietária de Magic.

Após triagem linguística, comercial e visual, foi escolhido o nome
**BrewTact** e a direção **Tactical Stack**. `brew` representa a criação e o
refino de listas no vocabulário de card games; `tact` representa decisões e
tática. A marca visual usa duas bordas de carta interligadas, um recorte de
decisão e a paleta Obsidian + Brass + Frost já vigente.

## Decision

1. A marca exibida ao usuário passa a ser **BrewTact**.
2. A frase de produto em português é **Monte melhor. Jogue melhor.** e, em
   inglês, **Build smarter. Play better.**
3. A identidade pública usa um master vetorial Tactical Stack e exports
   derivados. Rasters gerados durante exploração não são fontes de produção.
4. Splash nativo contém somente fundo Obsidian e o símbolo central. Nome e
   texto localizável pertencem ao Flutter/Web, não ficam gravados na imagem.
5. App icon, favicon e notification glyph usam apenas o símbolo, com variantes
   próprias para máscara, monocromático e tamanho pequeno.
6. A paleta pública continua baseada nos tokens canônicos de `AppTheme`:
   Obsidian `#0B0D12`, Slate `#151821`, Brass `#C58B2A`/`#E0A93B`, Frost
   `#6FA8DC` e Ivory `#F3EFE3`.
7. Strings públicas, e-mails, relatórios, SEO, legal, launcher e título da
   janela usam BrewTact. Referências históricas em ADRs/evidências continuam
   intactas quando descrevem o estado anterior.
8. Identificadores internos permanecem legados nesta transição: package Dart,
   classes, variáveis `MANALOOM_*`, storage keys `manaloom.*`, bridges JS,
   valores de protocolo, package/bundle IDs, Firebase e nomes de serviço.
9. O código não faz substituição global. Cada string é classificada como
   pública ou interna antes da alteração.
10. Nenhum fallback pode apontar para `manaloom.com`. Até a aquisição e
    configuração de domínio BrewTact, links públicos usam a URL de deploy
    configurada ou o host público EasyPanel aprovado.

## Consequences

- Usuários veem uma única marca em app, site, e-mails, relatórios e sistema
  operacional.
- Sessões, preferências, drafts, autenticação, push e contratos de Battle não
  perdem compatibilidade.
- Nomes internos ainda contêm ManaLoom; isso é dívida intencional, não drift da
  marca pública.
- Qualquer mudança em `app/assets`, shell Web ou resources Android invalida a
  prova visual corrente. A entrega exige nova matriz Web e Android conforme o
  contrato de prova viva.
- Um domínio definitivo e remetente de e-mail BrewTact continuam dependentes
  de aquisição/verificação externa; o código não presume que isso ocorreu.

## Rejected alternatives

- Manter ManaLoom em domínio alternativo: não resolve tráfego, busca nem uso
  comercial anterior.
- Renomear todos os identificadores internos: eleva risco de perda de estado e
  quebra de compatibilidade sem benefício visível.
- Usar o PNG exploratório como logo final: não garante geometria, cor, máscara
  ou legibilidade determinística.
- Reproduzir símbolos oficiais de Magic: cria risco de propriedade intelectual
  e enfraquece uma identidade própria.

## Validation

- teste de contrato para ausência de ManaLoom em superfícies user-facing;
- inspeção de master SVG e exports em 16, 32, 192, 512 e 1024 px;
- launcher Android legacy/adaptive/monochrome, AppIcon iOS e PWA maskable;
- cold start nativo, splash Flutter e boot Web;
- build Web e Android reais;
- recaptura e revisão visual integral exigida pelo contrato vigente;
- `manaloom_project_logic.sh --write/--check` e gates locais aplicáveis.

## Review triggers

Revisar quando o projeto adquirir um domínio BrewTact, publicar nas lojas,
alterar package/bundle IDs, migrar Firebase, abandonar aliases internos ou
formalizar uma nova arquitetura de localização.
