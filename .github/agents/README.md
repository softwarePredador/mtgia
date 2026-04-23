# GitHub Agents

Este diretório concentra agentes operacionais reutilizáveis do repositório.

## Agentes ativos

- `MetaDeckIntelligenceAnalyst.md`
  - audita ingestão de `meta_decks`
  - mede cobertura real por formato e identidade de cor
  - interpreta o valor estratégico dos decks meta para `optimize` e `generate`

## Regra

Sempre que um agente aqui depender de documentação operacional fora de `.github/`,
ele deve apontar explicitamente para os arquivos fonte de verdade do projeto.
