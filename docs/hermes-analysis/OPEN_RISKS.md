# Hermes Analysis: Open Risks

> Lista inicial de riscos que o agente residente deve acompanhar. Este arquivo nao substitui os documentos canonicos; ele resume a leitura operacional atual.

## P0: Ambiente de validacao do agente

O servidor Hermes consegue ler o repositorio e analisar o projeto, mas o container atual nao possui Dart ou Flutter instalados.

Impacto:

- o agente consegue auditar codigo e docs;
- o agente nao consegue confirmar `dart test`, `flutter analyze` ou `flutter test` neste ambiente sem toolchain adicional;
- recomendacoes de codigo devem ser marcadas como nao validadas quando nao houver execucao local.

## P1: Fonte de verdade e deriva documental

O repositorio possui muitos relatorios historicos e arquivos arquivados. A chance de ler prioridade antiga como atual e alta.

Fontes que devem prevalecer:

- `docs/CONTEXTO_PRODUTO_ATUAL.md`
- `docs/README.md`
- `server/manual-de-instrucao.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`

## P1: Core de decks ainda concentra risco

O fluxo central segue sendo `criar/importar -> analisar -> otimizar -> aplicar -> validar`.

Riscos:

- regressao no provider de decks;
- regressao nos widgets de `DeckDetails`;
- contrato app/backend quebrado em rotas de IA ou decks;
- resultados de otimizacao sem aplicacao/validacao final confiavel.

## P1: Observabilidade mobile e request tracing

Pendencias documentadas indicam necessidade de validar ingestao real do Sentry mobile e correlacao de `x-request-id` ponta a ponta.

## P2: Scanner/OCR e dependencias nativas

Scanner/camera/OCR seguem fora do escopo principal da rodada atual, mas as dependencias nativas aumentam superficie de falha.

## P2: IA e dados externos

O backend depende de dados de MTG e rotas de IA com regras complexas. O agente deve acompanhar testes de corpus, Commander Reference, resolucao de carta, identidade de cor, otimizacao, rebuild e validacao.
