# ManaLoom UX-PACK-05 — implementação e evidência local

Data: 2026-08-06
Estado: `COMPLETE_LOCAL · FOCAL_WEB_VISUAL_PASS · GLOBAL_UI_EVIDENCE_STALE`
Autorização: continuação explícita do usuário — “pode seguir para os proximos
passos”, “continue” e “okay continue”.

## Resultado

O pacote fechou localmente a jornada social que antes terminava em informação:

```text
deck/wishlist com faltante
  → match de cópia pública verificável
  → Marketplace com impressão, estado, preço e freshness
  → proposta recuperável por URL
  → revisão explícita do que quero e ofereço
  → aceitar, contrapropor ou recusar
  → histórico, conversa e conclusão
```

Marketplace e Cotações agora têm nomes e destinos distintos. Empty states de
matches, ofertas, trades, mensagens e busca de jogadores indicam uma próxima
ação real. Comentários de deck podem ser ancorados no deck todo, categoria ou
carta, sem inventar um novo modelo de dados.

## Arquitetura de informação e rotas

- Marketplace canônico: `/collection?tab=1`;
- alias de Marketplace: `/marketplace`;
- Cotações canônicas: `/community?tab=3`;
- aliases de Cotações: `/quotes` e o legado `/market`;
- matches: `/collection/matches?deck=<id>`;
- proposta recuperável:
  `/trades/create/:receiverId?item=&type=&source=&deck=&counter=`.

O objeto `extra` continua sendo um fast path, mas receiver, item, tipo, origem,
deck e proposta anterior são reconstruídos da URL. A busca pública de usuários
também restaura `q` e executa a consulta após reload.

## Faltante, oferta e confiança

- o match compara a falta por identidade jogável
  `COALESCE(oracle_id, id)`, mas leva à proposta o `binder_item_id` exato;
- o card mostra arte, set/collector, acabamento, idioma, condição, quantidade,
  preço, jogador, localização pública e atualização;
- o backend reconfirma visibilidade do fichário, bloqueios, política de
  interação e disponibilidade antes de criar a proposta;
- uma oferta removida ou sem cópia livre vira estado recuperável, sem selecionar
  silenciosamente outra impressão;
- o fichário público nunca expõe notas ou localização privada.

## Proposta, contraproposta e histórico

- a revisão final compara itens, quantidades, condição, idioma e valores antes
  do envio;
- troca pura exige itens dos dois lados; mudar o tipo limpa campos incompatíveis;
- contraproposta aparece somente para `trade` pura, pendente e recebida;
- o servidor bloqueia a original e, na mesma transação, a recusa, revalida as
  cópias e cria a nova proposta, snapshots, histórico e mensagem;
- qualquer falha faz rollback integral; compra/misto não ganham um fluxo de
  contraproposta financeira implícito;
- estados pendente, recusado, erro recuperável e concluído mantêm identidades,
  cartas, valores, segurança e timeline legíveis.

Não houve migration. O ManaLoom registra a combinação e a conversa, mas não
recebe, guarda nem protege pagamento ou entrega.

## Comunidade e estados vazios

Comentários novos podem carregar um rótulo sanitizado em
`[Contexto: …]`, serializado no `body` existente. O app separa o rótulo na
leitura e mantém compatibilidade com comentários legados. A tela pública mostra
arte e impressão quando existe identidade exata, análise incremental,
correspondência de faltantes e CTA para ofertas compatíveis.

Os vazios foram transformados em decisões contextuais:

- matches → explorar Marketplace;
- Marketplace → abrir wishlist;
- trades → encontrar matches;
- mensagens → buscar jogadores;
- busca sem resultado → limpar/revisar busca.

## Tese visual aplicada

A lente do `frontend-skill` definiu uma “mesa social confiável”: carta e pessoa
dominam a leitura; Obsidian contém, Frost informa, azul sinaliza identidade e
Brass fica reservado a próxima ação. O resultado evita o padrão genérico de
inbox/dashboard e usa arte de carta onde ela ajuda reconhecimento, não como
decoração indiscriminada.

Durante a inspeção, a primeira captura mobile revelou o defeito apontado pelo
usuário: metadados e CTA ficavam espremidos porque o card consultava a largura
global do browser, não sua largura local. `_TradeMatchCard` passou a decidir o
layout com `LayoutBuilder`; em 390 px, detalhes ocupam a largura disponível e
preço/CTA ficam abaixo em botão largo. Um teste de regressão simula
`MediaQuery` de 1440 px com card local de 390 px e exige CTA maior que 300 px.
As três matrizes foram recapturadas somente após essa correção.

## Evidência automatizada e runtime

O harness usa Chrome real, build Web release, gateway controlado e artes locais
same-origin. Dezesseis checkpoints são exigidos por perfil:

1. matches preenchidos;
2. Marketplace preenchido;
3. Marketplace vazio;
4. proposta reidratada da URL;
5. modal de revisão;
6. oferta indisponível;
7. proposta pendente com ações;
8. rascunho de contraproposta;
9. proposta recusada;
10. erro recuperável;
11. proposta concluída;
12. inbox de trades vazio;
13. mensagens vazias;
14. busca sem jogadores;
15. comentário comunitário contextual;
16. matches vazios.

Comando focal:

```bash
./scripts/manaloom_social_trade_visual_qa.sh
```

Resultado no digest
`70322d0704bc63fffe5520d1874873c100c3d82ddb85e8f9cf53ccd288083adf`:

- `web_social_trade_mobile_390x844`: `16/16 PASS_RUNTIME`;
- `web_social_trade_desktop_1440x900`: `16/16 PASS_RUNTIME`;
- `web_social_trade_wide_1920x1080`: `16/16 PASS_RUNTIME`;
- `48/48 PASS_VISUAL_REVIEWED`, após abrir cada PNG individualmente;
- consoles dos três perfis: zero entrada proibida.

Manifests:

```text
mobile   80bd5201583ba9e9024b893b178f9cee75a289a5c93d8208228aa69dde332154
desktop  c4c120c7d0f7b5125c18ce4aec41ebebc8a6671cc1628cd06b935946bb9eb021
wide     28bfbb6e5cc6343dd179fa876a1c43d7cf3dc0dd3e341f8dcaee2fcae1402748
```

Digest ordenado das 48 imagens:

```text
abb17bf764f37ba51cac438cfc20f9907156324ec89de71ddc08eebcf8853e0e
```

## Verificações focais

- Flutter social/trade/collection/Binder: `116/116 PASS`;
- contratos focais do servidor: `21/21 PASS`;
- regressão de largura local do match: `PASS`;
- política e inventário de superfícies: `7/7 PASS`;
- analyzers completos do app e servidor: `PASS · no issues found`;
- Chrome release 390×844, 1440×900 e 1920×1080:
  `48/48 PASS_RUNTIME`;
- revisão manual de cada PNG: `48/48 PASS_VISUAL_REVIEWED`.

`./scripts/quality_gate.sh ui-proof` foi executado no digest corrente e
recusou corretamente o aggregate: o review e seus 14 manifests ainda estão no
digest anterior, e os três perfis `web_social_trade_*` ainda não pertencem a
`latest.json`. Nenhum hash antigo foi promovido nem recebeu crédito novo.

## Limites e trabalho remanescente

- `docs/qa/ui-live/latest.json` ainda referencia o digest global anterior; o
  gate agregado deve continuar fail-closed até uma reancoragem integral no
  digest corrente. A prova focal acima não recebe crédito global;
- a reancoragem integral não foi iniciada: a inspeção ADB encontrou somente
  `emulator-5554`, mas a política corrente exige
  `android_physical_sm_a135m` e proíbe declarar emulador como físico. O host
  também tinha apenas 5,6 GiB livres, abaixo da margem segura para toda a
  fixture/build/matriz;
- Android físico, TalkBack humano, teclado Web real e smoke de hardware/release
  continuam verificações separadas;
- localização privada, pagamento, entrega e mediação de disputa permanecem fora
  do produto;
- contraproposta automática está deliberadamente limitada a troca pura;
- o pacote não autoriza migration, release, deploy ou escrita live.

## Segurança de entrega

Não houve commit, push, deploy, migration, limpeza de checkout, escrita em
PostgreSQL live nem alteração de Hermes/SQLite. O checkout sujo preexistente foi
preservado.
