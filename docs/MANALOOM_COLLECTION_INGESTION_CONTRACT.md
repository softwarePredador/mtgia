# ManaLoom — contrato de ingestão e revisão da coleção

- Status: `accepted_phase_1_no_migration`
- Data: 2026-08-05
- Escopo: Fichário `Tenho`/`Quero`, importação por texto, sessão de scanner,
  correção de impressão, retry e resumo de disponibilidade
- Pacote: `UX-PACK-02`

## Decisão de produto

O pacote será entregue em fases. A fase 1 prioriza importação em lote por texto
e usa a mesma fila para uma sessão de scanner quando o feature flag já
homologado estiver ativo. Nenhuma migration é criada nesta fase. Localização
estruturada de cópia física permanece bloqueada até autorização separada para
schema, contrato de privacidade e concorrência.

O workspace persistente `/collection/import` é a superfície canônica. Ele não
aplica nada ao ler a fonte: primeiro cria candidatos, exige as decisões
pendentes, compara o lote com PostgreSQL e só então oferece uma confirmação de
apply.

## Formato da entrada

A importação aceita até 100 identidades físicas revisadas por lote. Linhas de
texto usam:

```text
4 Lightning Bolt
1 Sol Ring (CMM) 396
2 Rhystic Study [WOT] 25
```

- quantidade e nome são obrigatórios;
- `(SET) collector` e `[SET] collector` são hints opcionais;
- linhas idênticas são agrupadas e continuam identificadas como duplicatas;
- comentários iniciados por `#` são ignorados;
- linhas inválidas ficam visíveis e fora do apply;
- arquivo não é lido diretamente nesta fase; uma exportação textual pode ser
  colada sem mudar a semântica do lote.

## Identidade e revisão

1. `cards.id` é a impressão persistida; `oracle_id` continua sendo identidade
   jogável para disponibilidade.
2. Nome resolvido não autoriza escolher uma impressão. Quando há mais de uma,
   a fila permanece em `needsPrinting` até confirmação explícita de set e
   collector.
3. Um hint que seleciona exatamente uma impressão e um nome com somente uma
   impressão local podem avançar automaticamente porque não há alternativa
   concorrente.
4. Condição, `is_foil`, idioma e `list_type` completam a identidade física.
5. Duplicatas que terminam na mesma identidade física são agrupadas antes do
   preflight.
6. A edição de item existente pode trocar `card_id`; o backend valida a nova
   impressão e mantém os mesmos conflitos de identidade e compromisso ativo.
7. `cards.foil` continua sendo capacidade de catálogo; o acabamento escolhido
   no lote é `user_binder_items.is_foil`.

O ADR 0008 permanece normativo. Nenhuma linha de `deck_cards` passa a alegar
idioma, acabamento ou alocação de uma cópia específica.

## Draft, retomada e histórico

- fonte, candidatos, impressão escolhida e atributos físicos são salvos em
  `SharedPreferences` com chave por usuário;
- o rascunho é retomável sem rede, mas um plano servidor nunca é reutilizado
  após reabrir: baseline e target precisam ser recalculados;
- itens aplicados saem do rascunho; itens falhos permanecem para retry;
- os dez resultados mais recentes ficam em histórico local por usuário;
- SharedPreferences é continuidade local, não verdade do inventário. O estado
  confirmado continua vindo do backend/PostgreSQL.

## Preflight read-only

`POST /binder/import/preview` recebe identidades já escolhidas. Apesar do
método POST necessário ao payload estruturado, a rota não executa `INSERT`,
`UPDATE` nem `DELETE`.

Para cada item, ela devolve:

- ação `create` ou `update`;
- `baseline_quantity`, quantidade observada no Fichário;
- `target_quantity = baseline_quantity + quantity`;
- impressão e identidade física normalizadas;
- `owned`, `allocated`, `committed`, `free` e `missing` da identidade jogável;
- rejeição explícita caso a impressão não exista mais.

O resumo agregado usa `collection_availability_snapshot`. O cliente não
recalcula disponibilidade por conta própria.

## Apply idempotente e falha parcial

`POST /binder/import/apply` recebe o mesmo item com baseline e target. Cada
identidade roda em transação própria e é bloqueada com `FOR UPDATE`.

```text
current == target   → unchanged; replay já aplicado
current == baseline → create/update para target
qualquer outro      → binder_import_inventory_changed; revisar novamente
```

Criação usa a unicidade física existente e `ON CONFLICT ... DO NOTHING`. Uma
corrida é relida dentro da transação; ela só vira `unchanged` se a quantidade
observada já for exatamente o target. Assim, perda de resposta e retry do
mesmo plano não somam cópias novamente sem exigir tabela de idempotência.

O lote retorna resultado por item. Sucessos não são desfeitos por uma falha em
outro item; falhas ficam no draft e recebem novo preflight antes do retry. O
cliente nunca apresenta um erro de transporte como confirmação de escrita.

## Sessão de scanner

Quando `ENABLE_SCANNER_RELEASE=true`, o workspace pode abrir
`CardScannerScreen` em `continuousBinderSession`. Cada confirmação devolve uma
impressão concreta para a mesma fila, agrega scans repetidos e reinicia o
scanner sem persistir no Fichário. Fechar a câmera retorna à revisão; o apply
continua sendo o único ponto de escrita.

Com o flag desativado, nenhuma rota ou CTA de scanner é publicada. OCR/câmera,
permissão, dispositivo físico e ML Kit continuam sujeitos à homologação
Android específica.

## Localização estruturada — bloqueio explícito

`user_binder_items.notes` não será usado como localização fingida. Área,
caixa/fichário e posição opcional exigem:

1. decisão de cardinalidade e privacidade;
2. migration autorizada separadamente;
3. compatibilidade de Binder público, Marketplace, Trade snapshot e export;
4. concorrência para edição e remoção;
5. E2E isolado e runtime visual no digest resultante.

Até isso ocorrer, o UX-PACK-02 está implementado para ingestão/revisão, mas não
recebe estado global `COMPLETE` para organização/localização.

## Gates

- parser, agrupamento, draft, impressão, cancelamento, preflight, apply,
  partial failure, retry e scanner queue têm testes automatizados;
- endpoints novos não dependem de migration;
- toda mudança app-facing precisa dos três níveis do contrato de evidência UI;
- scanner físico, TalkBack humano, teclado Web real e localização persistente
  permanecem gates separados de release.
