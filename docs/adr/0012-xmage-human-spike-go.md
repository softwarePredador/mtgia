# ADR 0012 — GO limitado do spike XMage humano contra IA

- Estado: aceito
- Data original da decisão: 2026-07-27
- Renumeração documental: 2026-08-12
- Programa: `BL7`
- Decisão: `GO` limitado para engenharia
- Substitui: ADR 0003

## Contexto

O registro original desta decisão foi criado por engano com o identificador
`0004`, já ocupado pelo ADR de Battle Live. Esta renumeração não amplia a
decisão nem altera sua evidência: elimina apenas a ambiguidade de referência.
O arquivo histórico `0004-xmage-human-spike-go.md` conserva o relato completo
da rodada e não é mais uma fonte canônica.

## Decisão

As provas do spike XMage humano contra IA autorizam a engenharia local do
runtime interativo, mantendo todas as restrições originais:

1. Coach e sessões interativas continuam desabilitados por padrão;
2. nenhuma rota do probe vira superfície pública;
3. resposta obsoleta, inválida ou rejeitada encerra a sessão fail-closed;
4. timeout concede e termina a sessão — não existe decisão implícita pela IA;
5. informação privada nunca é reutilizada em replay, log ou stream público;
6. o GO não autoriza migration live, deploy, rollout, aprendizado ou promoção
   de deck/regra.

Battle continua sendo evidência de execução. Não prova legalidade, qualidade
estratégica nem superioridade de uma troca e não pode promover learned deck.

## Evidência preservada

O detalhe das partidas, callbacks, métricas e reprodução permanece no registro
histórico `0004-xmage-human-spike-go.md`. A interpretação corrente deve também
seguir:

- `docs/hermes-analysis/EXTERNAL_BATTLE_EXECUTION_CONTRACT.md`;
- `docs/hermes-analysis/GLOBAL_BATTLE_RULES_AND_LEARNING_CLOSURE_2026-07-15.md`;
- `docs/hermes-analysis/COMMANDER_DECKBUILDING_CONTRACT_2026-06-29.md`;
- `docs/BREWTACT_DECKBUILDER_AI_CURRENT_FLOW_2026-08-12.md`.

## Critério de revisão

Uma decisão posterior deve criar novo ADR. Receipts de runtime, matriz de
Battle ou gates de release não modificam silenciosamente este ADR e jamais
autorizam promoção autônoma de aprendizado.
