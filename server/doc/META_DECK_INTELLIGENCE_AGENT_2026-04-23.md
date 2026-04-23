# Meta Deck Intelligence Agent

Data: 2026-04-23

Objetivo:

- auditar a ingestao de `meta_decks`
- verificar se a busca de decks meta continua funcionando
- medir cobertura real por formato e identidade de cor
- interpretar a intencao estrategica das listas puxadas
- traduzir esse aprendizado para `optimize` e `generate` quando fizer sentido

## Papel do agente

Esse agente atua como:

- auditor de pipeline
- analista de cobertura
- leitor estrategico de decks competitivos

Ele nao deve assumir que a rotina funciona so porque existe codigo.

Ele precisa provar:

1. se a fonte responde
2. se o parser ainda bate com o HTML real
3. se o banco esta fresco
4. se a cobertura de cores/combinacoes e suficiente
5. se o aprendizado extraido realmente ajuda o produto

## Arquivos obrigatorios de leitura

- `.github/instructions/guia.instructions.md`
- `ROADMAP.md`
- `docs/CONTEXTO_PRODUTO_ATUAL.md`
- `server/bin/fetch_meta.dart`
- `server/bin/populate_meta_v2.py`
- `server/bin/extract_meta_insights.dart`
- `server/bin/meta_profile_report.dart`
- `server/bin/meta_report.dart`
- `server/doc/DECK_ENGINE_CONSISTENCY_FLOW.md`
- `server/doc/RELATORIO_COMMANDER_ONLY_OPTIMIZATION_VALIDATION_2026-04-21.md`
- `server/test/fixtures/optimization_resolution_corpus.json`

## Tarefas obrigatorias

1. mapear o pipeline atual:
   - fonte externa
   - script de ingestao
   - tabela de destino
   - scripts de consumo
2. validar a rotina de busca de forma nao destrutiva sempre que possivel
3. medir frescor da base atual
4. medir cobertura por:
   - formato
   - identidade de cor
   - casos especiais `partner/background` quando aplicavel
5. detectar falhas estruturais:
   - `archetype` vazio
   - `placement` mal parseado
   - parser acoplado a markup antigo
   - formatos sem renovacao recente
6. analisar um conjunto representativo de decks e responder:
   - o que o jogador quis construir
   - qual a malicia competitiva da lista
   - o que disso vira sinal util para `optimize` e `generate`
7. separar claramente:
   - problema de ingestao
   - problema de cobertura
   - problema de interpretacao estrategica

## Entrega minima

Criar ou atualizar:

- `server/doc/RELATORIO_META_DECK_INTELLIGENCE_2026-04-23.md`

Com:

- pipeline atual
- comandos rodados
- validacao da busca
- cobertura real
- gaps
- leitura estrategica
- proximas acoes pequenas

## Regras

- nao assumir cobertura total sem provar
- nao inventar fonte externa fora do codigo
- nao tratar corpus de resolucao como substituto automatico de `meta_decks`
- se houver duvida, marcar como `nao comprovado`

## Prompt operacional para Copilot CLI

Use este arquivo como base e execute a task com:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia && copilot --effort high -i "$(cat server/doc/META_DECK_INTELLIGENCE_AGENT_2026-04-23.md)"
```
