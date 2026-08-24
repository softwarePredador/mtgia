# ManaLoom — contrato de origem, tratamento, cache e direitos de arte de cartas

- Status: `accepted_for_free_beta`
- Data: 2026-08-05
- Escopo: imagens, símbolos e metadados visuais de cartas no app ManaLoom
- Dono de implementação: produto + engenharia
- Dono do gate comercial: produto + revisão jurídica externa

Este documento é um contrato de produto e engenharia, não um parecer jurídico.
Ele valida a implementação da beta gratuita contra as políticas oficiais
consultadas em 2026-08-05 e bloqueia qualquer uso pago ou materialmente diferente
até nova revisão.

## Decisão

1. A impressão persistida no PostgreSQL é a fonte de identidade visual. O app
   mostra primeiro a URL da impressão e só usa busca por nome como referência
   visual explicitamente rotulada.
2. Imagem completa de carta usa `BoxFit.contain`. Nenhuma superfície pode
   cortar, cobrir, desfocar, distorcer, recolorir ou aplicar marca d'água à
   imagem de carta.
3. `art_crop` não tem caller de produto autorizado. Um uso futuro só pode ser
   aceito quando a mesma interface mostrar a carta completa ou o nome do artista
   e o copyright, sem transformação da imagem.
4. O ManaLoom não hospeda proxy nem republica um catálogo de imagens. O backend
   persiste identificadores, metadados e URLs; o cliente solicita a imagem
   diretamente da origem HTTPS.
5. Dados e imagens Scryfall não podem ficar atrás de paywall. A beta controlada
   desta revisão permanece gratuita. Assinatura, checkout ou outra monetização
   com arte ou dados de cartas fica bloqueada até revisão jurídica externa e
   autorização explícita de produto.
6. O app declara que é conteúdo de fã não oficial, que não é aprovado ou
   endossado pela Wizards e que Scryfall não aprova nem endossa o ManaLoom.

## Fonte e proveniência

- PostgreSQL/backend continua sendo a verdade do catálogo consumido pelo app.
- URLs Scryfall persistidas devem apontar para `https://cards.scryfall.io` ou
  para os endpoints documentados de imagem em `https://api.scryfall.com`.
- Uma URL HTTPS de outra origem só pode ser exibida quando veio de contrato
  backend revisado; normalização de transporte no widget não concede
  proveniência nem licença.
- O app não consulta Scryfall para substituir silenciosamente uma impressão.
  `/cards/named` é somente fallback de referência e recebe estado visual
  `reference`.
- Carta dupla face preserva as faces e a impressão conhecidas; não usa um crop
  Oracle para fingir identidade física.

## Tratamento visual e conteúdo

A tese visual do UX-PACK-01 é:

- arte completa e exata é a âncora dominante de reconhecimento;
- nome, set, collector e qualidade conhecida vêm em seguida;
- Frost identifica metadados verificáveis e Brass fica restrito a seleção,
  valor ou ação;
- condição, idioma e acabamento físico só aparecem quando Binder/Trades
  possuem essa verdade;
- ausência, loading, baixa resolução, referência, offline explícito e erro não
  são colapsados em um placeholder silencioso.

A ordem de conteúdo é imagem → nome → impressão → fato físico disponível →
ação. O fluxo exige escolha explícita quando duas impressões do mesmo Oracle ID
podem mudar a decisão.

## Cache e rede

- `AppImageCachePolicy` limita o cache vivo a 96 entradas e 32 MiB e limita o
  decode a 1400 px; thumbnails usam buckets menores.
- `CachedNetworkImage` mantém cache local do cliente e respeita a URL/cache da
  origem. Esse cache não é um serviço de distribuição e não é promovido a
  armazenamento de produto.
- URLs CDN já persistidas são preferidas para evitar buscas redundantes.
- Requisições de imagem via `api.scryfall.com` são iniciadas em série com
  intervalo mínimo de 125 ms, equivalente a no máximo 8 inícios por segundo, e
  possuem somente duas tentativas adicionais, após 500 ms e 1500 ms.
- Em plataformas nativas, o cliente envia `User-Agent: ManaLoom/1.0` e
  `Accept: image/*`. No Web, mantém o User-Agent do navegador e usa elemento
  HTML para o CDN quando CORS impede fetch de bytes.
- Falha terminal cai para referência declarada ou para o card-back original do
  ManaLoom; nunca entra em retry ilimitado.

## Crédito e aviso ao usuário

A rota pública `/legal` contém o aviso de conteúdo de fã não oficial, a
titularidade da Wizards e a identificação do Scryfall como fornecedor de dados
e imagens. A versão de Termos foi elevada para `2026-08-05` junto com o backend.

Imagens completas preservam dentro do próprio card o nome do artista e os
avisos legais. Como `art_crop` não está autorizado, o produto não depende hoje
de crédito externo por crop. Scryfall, Wizards, seus logos e marcas não podem
ser usados para sugerir parceria ou endosso.

## Inventário e enforcement

- `CardArtwork` concentra geometria, semântica e os estados de imagem.
- `CachedCardImage` concentra HTTPS, cache, headers, rate gate, retry e
  fallback; seu fit padrão é `contain`.
- O Scanner existente também usa esses componentes. Não restam callers de
  carta com `Image.network` ou `CachedNetworkImage` fora da implementação
  central.
- Usos diretos remanescentes de providers de rede são exclusivamente avatares
  de pessoa e ficam em allowlist testada.
- O guard `card_image_source_policy_guard_test.dart` bloqueia novos callers
  diretos de rede e qualquer `art_crop` em `app/lib/features`.

## Fronteira de deck e cópia física

O [ADR 0008](adr/0008-decklist-and-binder-physical-copy-boundary.md) permanece
normativo: `deck_cards` guarda decklist e impressão do catálogo; condição,
idioma e acabamento pertencem a `user_binder_items` ou ao snapshot imutável de
Trade. `cards.foil` é capacidade da impressão, não acabamento possuído.

## Gates e revisão

Reabrir este contrato antes de:

- ativar plano pago, checkout, publicidade condicionante ou paywall;
- adicionar outra fonte de arte, proxy, download em massa ou armazenamento de
  binários;
- reintroduzir `art_crop`, background derivado, blur ou outro tratamento;
- mudar headers, frequência, retry, cache persistente ou hosts permitidos;
- usar logos, marcas, símbolos oficiais ou arte fora de uma experiência de
  Magic gratuita e claramente não oficial;
- alterar a fronteira entre decklist e cópia física.

TalkBack humano, teclado Web real e smoke de hardware/release continuam gates
separados do release e não são substituídos por este contrato.

## Fontes oficiais verificadas em 2026-08-05

- [Scryfall REST API — Overview & Rules](https://scryfall.com/docs/api): headers
  obrigatórios, uso de dados e imagens, acesso sem paywall, proibição de
  transformação e regra de crédito para `art_crop`.
- [Scryfall Card Imagery](https://scryfall.com/docs/api/images): formatos de
  imagem e estados `missing`, `placeholder`, `lowres` e `highres_scan`.
- [Scryfall API access FAQ](https://scryfall.com/docs/faqs/i-m-having-trouble-accessing-the-scryfall-api-or-i-m-blocked-17): limite abaixo
  de 10 requests por segundo, headers e preferência por bulk data em volume.
- [Política de Conteúdo de Fãs da Wizards](https://company.wizards.com/pt-BR/legal/fancontentpolicy): gratuidade, aviso de conteúdo não oficial,
  preservação de avisos legais e limites de marcas/IP.
- [Termos da Wizards](https://company.wizards.com/en/legal/terms): titularidade
  e uso somente quando expressamente permitido pelos Termos ou pela Política de
  Conteúdo de Fãs.
