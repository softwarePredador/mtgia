# Hermes Analysis: Product Direction

> Leitura operacional do objetivo do ManaLoom para orientar o agente residente.

## Produto

ManaLoom e uma plataforma Commander-first para Magic: The Gathering. A promessa central e ajudar o usuario a criar, importar, analisar, otimizar, aplicar mudancas e validar decks com confiabilidade real.

## Fluxo carro-chefe

```text
criar/importar -> analisar -> otimizar -> aplicar -> validar
```

Esse fluxo deve prevalecer sobre frentes adjacentes enquanto o produto estiver em endurecimento do core.

## Intencao de produto

O app quer ser mais que um deck builder cosmetico. A direcao indicada pela documentacao e construir confianca operacional:

- importar listas sem quebrar;
- entender comandante, identidade de cor e regras de Commander;
- analisar plano, curva, sinergia e buracos do deck;
- sugerir upgrades seguros;
- aplicar mudancas com preview e controle;
- validar o resultado final;
- reduzir ruido visual e deixar o fluxo principal claro.

## Prioridade atual

Enquanto `docs/CONTEXTO_PRODUTO_ATUAL.md` nao mudar, a prioridade e blindar o core de decks.

Ordem de atencao:

1. confiabilidade do fluxo de decks;
2. contratos app/backend;
3. observabilidade e request tracing;
4. cobertura de testes do core;
5. carga/thresholds basicos;
6. frentes secundarias.

## Frentes secundarias

Social, binder, trade, scanner/OCR, community e cosmetica sem impacto no fluxo principal nao devem disputar prioridade com o core.

## Perguntas que o agente deve responder sempre

- isso melhora o fluxo carro-chefe?
- isso reduz risco ou aumenta escopo?
- isso respeita a fonte de verdade atual?
- isso precisa atualizar contrato ou documentacao?
- existe teste/documento que protege esse comportamento?
- qual e o proximo passo mais util para release?
