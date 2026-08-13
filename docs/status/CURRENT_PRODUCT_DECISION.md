# BrewTact — decisão corrente de produto

- Lifecycle: `CURRENT_PRODUCT_DECISION`
- Data da decisão: `2026-08-13`
- Estado de release: `NO_GO_PUBLIC_RELEASE`
- Candidato pretendido: `CONTROLLED_FREE_BETA`
- Público inicial: coorte pequena e controlada
- Plataformas do candidato: Web e Android
- Fora do candidato inicial: iOS e VoiceOver (`DEFERRED_BY_SCOPE`)

Este é o resumo curto que prevalece para escopo, oferta e abertura de produto.
O backlog mestre detalha execução e dependências; código, manifesto gerado e
receipts continuam sendo necessários para provar implementação e release.

## Identidade e destinos

- Marca pública: **BrewTact**.
- Origem pública canônica: `https://brewtact.com`, conforme ADR 0011. A
  configuração do domínio não prova que esta revisão all-OFF foi implantada.
- Host público técnico de deploy, smoke e rollback:
  `https://evolution-manaloom-web-public.2ta7qx.easypanel.host`; ele não é a
  identidade pública do produto.
- App Web: rota reservada `/app` na origem canônica, mas permanece inacessível
  enquanto a matriz server-authoritative desta revisão estiver totalmente
  `OFF` e sem receipt P0.
- A Web pública e os relatórios compartilhados não exibem CTA nem link para
  `/app` nesse estado; mostram apenas `Acesso ainda não liberado` sem ação.
- API aprovada pelo contrato de release:
  `https://evolution-cartinhas.2ta7qx.easypanel.host`.
- Nenhum desses destinos prova que a revisão corrente foi implantada. A prova
  live exige SHA, digest, health/readiness e receipt frescos.

## Oferta única da beta

Existe uma única oferta pública nesta fase: **Beta gratuita**.

- sem preço, plano Pro, assinatura, checkout, renovação, anúncio ou paywall;
- sem promessa de preço futuro ou de entitlement permanente;
- o teto operacional atual é de até `120` ações de IA elegíveis por mês UTC,
  apenas nas capabilities de IA que estiverem abertas pelo servidor;
- esse teto protege custo e capacidade, não transforma uma capability fechada
  em disponível e não autoriza Generate, Rebuild, Battle ou aprendizado;
- o backend é a autoridade do saldo autenticado. A landing não anuncia um
  segundo limite nem oferece upgrade.

Reabrir monetização exige decisão nova, parecer jurídico aplicável, custos
observados, entitlement server-side, checkout/webhook idempotentes e E2E de
pagamento. Código futuro compilável não é oferta.

## Matriz corrente de escopo

`implementation_status`, `release_capability` e `live_verified_as_of` são eixos
independentes. `OFF` significa inacessível também por API direta, antes de
consultar PostgreSQL ou chamar um provedor.

| Área | `implementation_status` | `release_capability` | `live_verified_as_of` |
| --- | --- | --- | --- |
| Cadastro de nova conta | Implementado e guardado | `OFF`; a coorte é admitida somente por decisão/receipt próprios | `null` |
| Login, recuperação, verificação, exportação e exclusão de conta existente | Plano de controle de acesso e privacidade | Disponível; não autoriza nenhuma capability de produto | `null` |
| Catálogo read-only, cartas, coleção/fichário privado e deck manual | Implementado, com P0 de release ainda abertos | `OFF_UNTIL_P0_RECEIPT` | `null` |
| Analyze/Optimize consultivo, sempre revisável | Experimental guardado, com P0 de IA ainda abertos | `OFF_UNTIL_P0_RECEIPT` | `null` |
| Generate/Rebuild | Experimental guardado | `OFF`; futura allowlist exige decisão e receipt próprios | `null` |
| Life Counter local | Implementado; isolamento/saída confiável ainda precisam fechar | `OFF_UNTIL_P0_RECEIPT` | `null` |
| Battle batch, Live e Coach | Implementação/laboratório existente | `OFF` até o programa Battle horizontal | `null` |
| Scanner/OCR | Implementação/provas históricas existentes | `OFF` | `null` |
| Galeria, perfis públicos, busca social, comments, follows, DMs e push social | Implementação parcial existente | `OFF` | `null` |
| Binder público, marketplace e trades | Implementação parcial existente | `OFF` | `null` |
| Checkout, assinatura, anúncios e paywall | Backend de billing contém bloqueio fail-closed | `OFF` | `null` |
| Aprendizado, leitura de learned decks e promoção | Contenção local existente; programa definitivo incompleto | `OFF` | `null` |

## Regras de abertura

1. Flag ausente, inválida, divergente ou sem receipt mantém a capability `OFF`.
2. UI escondida não vale como contenção; app e Web apresentam apenas o que a
   API autoritativa permite.
   Enquanto toda a matriz estiver `OFF`, nenhuma superfície pública aponta para
   `/app`.
3. Nenhuma IA aplica, publica, aprende ou promove sozinha.
4. Preview e commit precisam representar a mesma entrada e revisão.
5. Legalidade/estrutura não significam desempenho comprovado.
6. Migration, deploy, escrita live e promoção exigem autorização própria.
7. Um gate local verde não altera `live_verified_as_of`.

## Próxima decisão permitida

O trabalho atual é a Onda 0: tornar esta decisão executável, fechar oferta e
capabilities server-side, reconciliar lifecycle documental e endurecer os
gates. Somente receipts da mesma revisão podem mover uma linha de
`OFF_UNTIL_P0_RECEIPT` para `ON`.

Detalhamento e ordem:
`docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md`.
