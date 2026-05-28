# Plano de Correcao — Audit de Estrutura

> Data: 2026-05-28 00:01 UTC
> Escopo: documentar problemas estruturais detectados em `STRUCTURE_AUDIT.md` sem alterar codigo de produto.

## Resumo executivo

O auditor gerou muito ruído por inferir imports relativos a partir do root do repositório, então os **178 "imports quebrados" não podem ser tratados como defeitos reais** sem revalidação por `dart analyze` ou por resolução relativa ao diretório do arquivo Dart. Ainda assim, o relatório revelou três frentes prioritárias de organização:

1. **P0 — Ferramenta de auditoria com falso-positivo em massa**: o próprio relatório produz evidência estrutural pouco confiável e pode induzir correções erradas.
2. **P1 — Concentradores de complexidade muito grandes**: `server/lib/ai/optimize_runtime_support.dart` (4197 linhas) e `server/routes/ai/optimize/index.dart` (3495 linhas) seguem como gargalos de manutenção.
3. **P1 — Duplicação de helpers e lógica espalhada**: múltiplas funções com mesmo nome e mesma intenção aparecem em módulos de IA, meta e rotas HTTP, aumentando risco de drift.
4. **P1 — Entry point local quebrado**: `server/bin/local_test_server.dart` depende de `../.dart_frog/server.dart`, inexistente no checkout atual, e faz `dart analyze` do backend falhar.

## Achados priorizados

### P0 — Corrigir o `structure_auditor.py` antes de usar a contagem de imports quebrados como verdade
- **Evidência**:
  - `STRUCTURE_AUDIT.md` lista imports como "não encontrado" para arquivos que existem, por exemplo:
    - `server/routes/ai/_middleware.dart` → `../../lib/auth_middleware.dart`
    - `server/routes/auth/login.dart` → `../../lib/auth_service.dart`
  - Verificação direta no filesystem confirmou que os alvos existem em `server/lib/`.
- **Impacto**: priorização errada, documentação enganosa e risco de criar refactors desnecessários.
- **Causa provável**: o auditor resolve caminhos relativos de import contra o diretório errado (provavelmente o root do repo, não o diretório do arquivo origem).
- **Ação recomendada**:
  1. ajustar a resolução de imports relativos no script;
  2. separar "imports potencialmente quebrados pelo parser" de "imports inválidos confirmados por analyzer";
  3. deduplicar ocorrências repetidas no relatório.
- **Validação**:
  - rerodar `python3 docs/hermes-analysis/scripts/structure_auditor.py`;
  - conferir redução drástica dos falsos positivos;
  - confrontar com `dart analyze` do backend.

### P1 — Quebrar os módulos centrais do otimizador em unidades menores
- **Evidência**:
  - `server/lib/ai/optimize_runtime_support.dart`: 4197 linhas
  - `server/routes/ai/optimize/index.dart`: 3495 linhas
  - `STRUCTURE_AUDIT.md` também aponta duplicações diretas entre esses dois arquivos (`matchesFunctionalNeed`, `scoreOptimizeReplacementCandidate`, `shouldRetryOptimizeWithAiFallback`, `computeOptimizeStructuralRecoverySwapTarget`, `isOptimizeStructuralRecoveryScenario`, `resolveOptimizeArchetype`).
- **Impacto**: alta dificuldade de revisão, regressões sutis, duplicação de regras de negócio e risco de drift entre helper compartilhado e rota.
- **Ação recomendada**:
  1. definir fronteiras explícitas para seleção de candidatos, archetype resolution, structural recovery e fallback AI;
  2. mover regras duplicadas para `server/lib/ai/*_support.dart` com cobertura focada;
  3. deixar a rota `ai/optimize` como orquestração fina.
- **Validação**:
  - `dart analyze` verde;
  - testes de optimize e quality gate verdes;
  - diff estrutural mostrando redução de linhas na rota principal.

### P1 — Consolidar helpers duplicados que indicam drift funcional
- **Evidência**:
  - `_looksLikeComboPiece`, `_looksLikeEnabler`, `_looksLikeEngine`, `_looksLikePayoff`, `_looksLikeWincon` existem tanto em `server/lib/ai/functional_card_tags.dart` quanto em `server/lib/ai/optimization_functional_roles.dart`.
  - `_isBasicLandName` aparece em quatro locais diferentes.
  - `_requestId` e `_logInvalidPayload` repetem-se em várias rotas de trades/conversations.
  - `calculateCmc` e `getMainType` duplicados em duas rotas de decks/community.
- **Impacto**: mudança semântica em um ponto não propaga automaticamente para os demais; risco de respostas inconsistentes por endpoint/fluxo.
- **Ação recomendada**:
  1. agrupar duplicações por domínio (IA semântica, utilitários HTTP, utilitários de deck);
  2. extrair helpers compartilhados apenas quando a semântica for realmente idêntica;
  3. manter wrappers locais somente se o contexto justificar nomes iguais com comportamento diferente.
- **Validação**:
  - grep/listagem de duplicados reduzida;
  - testes existentes seguem verdes;
  - revisão de imports mostra dependência convergindo para helpers compartilhados.

### P1 — Restaurar a analisabilidade do backend local
- **Evidência**:
  - `dart analyze` em `server/` falhou com:
    - `bin/local_test_server.dart:3:8 - Target of URI doesn't exist: '../.dart_frog/server.dart'`
- **Impacto**: bloqueia validação estrutural automatizada e reduz confiança em checks rápidos do backend.
- **Ação recomendada**:
  1. decidir se `bin/local_test_server.dart` exige geração prévia obrigatória de `.dart_frog/server.dart`;
  2. documentar ou automatizar esse passo no fluxo local;
  3. se o arquivo não for mais usado, substituir por entry point resiliente ou removê-lo.
- **Validação**:
  - gerar artefatos necessários ou corrigir o entry point;
  - rerodar `dart analyze` até ficar verde.

## Sequência sugerida

1. **Primeiro**: corrigir o auditor estrutural (P0), porque ele afeta a confiabilidade do restante do relatório.
2. **Segundo**: destravar `dart analyze` do backend via `local_test_server.dart`.
3. **Terceiro**: atacar duplicações de maior risco no domínio de optimize/IA.
4. **Quarto**: modularizar os arquivos gigantes do otimizador com testes de regressão.

## Itens explicitamente não confirmados como bug real nesta rodada

- Os **178 imports quebrados** do relatório **não** foram validados como defeitos reais de código; a amostragem conferida aponta falso-positivo do auditor.
- A seção de "funções com nomes duplicados" mistura duplicação relevante com nomes esperados (`toString`, `print`, `add`), então precisa de triagem antes de virar tarefa de engenharia.

## Critério de saída para uma próxima rodada

Considerar a frente de estrutura saneada quando:

- o auditor não reportar imports existentes como ausentes;
- `dart analyze` do backend estiver verde no fluxo local documentado;
- a duplicação explícita entre `server/routes/ai/optimize/index.dart` e `server/lib/ai/optimize_runtime_support.dart` cair significativamente;
- os maiores arquivos do domínio de optimize reduzirem tamanho e responsabilidade.
