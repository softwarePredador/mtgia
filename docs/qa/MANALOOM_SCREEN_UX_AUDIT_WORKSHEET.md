# Worksheet — auditoria de superfície ManaLoom

Copiar esta ficha por rota, aba ou ocorrência não-route. Uma ficha compartilhada só é permitida quando comportamento, composição, estados e job forem realmente equivalentes.

## A. Identificação

| Campo | Valor |
|---|---|
| ID da auditoria | `UX-SURFACE-...` |
| Data/hora |  |
| Auditor/revisor |  |
| Onda/domínio |  |
| Rota/entrada/trigger |  |
| Widget/arquivo:linha |  |
| Escopo | active / deferred / redirect / compatibility / conditional |
| Persona primária |  |
| Job do usuário |  |
| Source of truth |  |
| Mutation possível | nenhuma / descrever |
| SHA/digest de UI |  |

## B. Evidência usada

Marcar apenas o que ocorreu nesta rodada.

- [ ] `CODE_SEEN`
- [ ] `AUTOMATED_PASS`
- [ ] `RUNTIME_SEEN` — plataforma: ______
- [ ] `VISUAL_OPENED` — artefatos: ______
- [ ] `USER_EVIDENCE` — fonte: ______
- [ ] `INFERENCE`
- [ ] `GAP_CONFIRMED`
- [ ] `PROPOSAL_ONLY`
- [ ] `NOT_APPLICABLE` — justificativa: ______

Evidência histórica consultada, sem crédito atual:

>

## C. Fluxo e modelo mental

| Pergunta | Resposta/evidência |
|---|---|
| De onde o usuário chega? |  |
| Que contexto deveria chegar? |  |
| O que chega de fato? |  |
| Qual é a ação primária? |  |
| Qual é o sucesso observável? |  |
| Qual é a saída/continuação? |  |
| Back/deep link/reload preservam intenção? |  |
| O que pode ser perdido? |  |
| O usuário precisa sair do ManaLoom? |  |

Wireflow observado:

```text
entrada → estado → decisão → ação → sucesso/erro → próxima superfície
```

## D. Estados

| Estado | Aplicável? | Exercitado? | Evidência | Compreensível? | Recuperação | Finding |
|---|---|---|---|---|---|---|
| initial |  |  |  |  |  |  |
| loading/progress |  |  |  |  |  |  |
| partial/stale/loading_more |  |  |  |  |  |  |
| empty |  |  |  |  |  |  |
| error/retry |  |  |  |  |  |  |
| offline |  |  |  |  |  |  |
| saving/optimistic |  |  |  |  |  |  |
| disabled |  |  |  |  |  |  |
| conflict/permission/session |  |  |  |  |  |  |
| success |  |  |  |  |  |  |
| image_fallback |  |  |  |  |  |  |
| reduced_motion |  |  |  |  |  |  |

## E. Teste de cinco segundos

Sem interagir, responder:

1. Onde estou? ______
2. O que está acontecendo? ______
3. Qual é a ação principal? ______
4. Qual carta/deck/partida/pessoa está em contexto? ______
5. Como continuo ou me recupero? ______

Resultado: `PASS` / `PARTIAL` / `FAIL`

Evidência e motivo:

>

## F. Hierarquia, identidade e desejabilidade

| Verificação | Resultado/evidência |
|---|---|
| Um job claro por região |  |
| Um CTA primário por região |  |
| Obsidian/Frost/Brass cumprem papéis sem ruído |  |
| Tipografia cria hierarquia e mantém leitura |  |
| Cards representam unidades reais, não decoração repetitiva |  |
| Layout evita aparência de dashboard/template genérico |  |
| Empty/error/loading têm linguagem visual distinta |  |
| A superfície desperta exploração/retorno |  |
| Densidade atende iniciante e usuário frequente |  |

## G. Imagens de carta e contexto visual

Objeto principal: carta / comandante / deck / set / partida / pessoa / nenhum

| Pergunta | Resposta/evidência |
|---|---|
| Imagem ajudaria reconhecimento, decisão ou confirmação? |  |
| Está presente no runtime? |  |
| É a carta/impressão correta? |  |
| Crop/aspect ratio preserva o necessário? |  |
| Loading/fallback/offline são honestos? |  |
| Há modo compacto/lista quando necessário? |  |
| A arte é contextual ou decorativa? |  |
| Fonte/cache/atribuição estão adequados? |  |

Rótulo:

- [ ] `IMAGE_REQUIRED_MISSING`
- [ ] `IMAGE_PRESENT_USEFUL`
- [ ] `IMAGE_PRESENT_DECORATIVE`
- [ ] `IMAGE_PRESENT_HARMFUL_DENSITY`
- [ ] `COMPACT_MODE_NEEDED`
- [ ] `IMAGE_NOT_APPLICABLE`
- [ ] `RUNTIME_NOT_VERIFIED`

## H. Modais, sheets, menus e transientes

Registrar uma linha por ocorrência disparável.

| ID/trigger | Tipo | Conteúdo/ação | Taxonomia | Perde contexto/draft? | Decisão | Finding |
|---|---|---|---|---|---|---|
|  |  |  | `SAFETY_CONFIRMATION` / `BOUNDED_PICKER` / `QUICK_EDIT` / `INLINE_EDUCATION` / `FLOW_CANDIDATE` / `DEAD_END_INFO` / `HIDDEN_PRIMARY_ACTION` / `TRANSIENT_MISUSE` / `SCOPE_OR_PAYWALL` |  | manter / inline / promover / remover |  |

Perguntas de promoção:

- [ ] Há várias etapas?
- [ ] Há comparação/diff?
- [ ] Há entrada longa, importação ou correção por item?
- [ ] Precisa ser retomado, compartilhado ou deep-linked?
- [ ] Precisa de imagem para decidir?
- [ ] A falha deve preservar trabalho?
- [ ] É uma ação central e frequente?
- [ ] O conteúdo rola ou esconde controles avançados?

## I. Funcionalidade, ação e confiança

| Verificação | Resultado/evidência |
|---|---|
| Todo controle visível executa ação real |  |
| Informação leva a decisão/ação útil |  |
| Cancelar não muta |  |
| Apply mostra diff e revalida |  |
| Retry é seguro/idempotente |  |
| Erro não parece vazio/sucesso |  |
| Regra/Oracle é separada de sugestão |  |
| IA mostra origem, motivo, confiança e limites |  |
| Preço mostra impressão, moeda, mercado e atualização |  |
| Posse distingue total/alocada/livre/faltante |  |
| Linguagem não promete feature, cobrança ou proteção ausente |  |

Estado funcional principal:

`EXISTS_AND_VISIBLE` / `EXISTS_BUT_HIDDEN` / `INFORMATION_ONLY` / `PARTIAL` / `MISSING` / `DEFERRED_BY_SCOPE` / `NOT_APPLICABLE` / `RUNTIME_UNKNOWN`

## J. Conteúdo

| Verificação | Resultado/evidência |
|---|---|
| PT-BR natural e termos de Magic contextualizados |  |
| Título explica o job, não o componente técnico |  |
| Copy informa consequência e próxima ação |  |
| Texto técnico/sanitização adequados |  |
| Proveniência e atualidade visíveis |  |
| Informações secundárias usam progressive disclosure |  |
| Modal informativo foi evitado quando inline é melhor |  |

## K. Acessibilidade e responsividade

| Perfil | Exercitado? | Overflow/crop | Teclado/foco | Semântica | Escala/contraste | Finding |
|---|---|---|---|---|---|---|
| Web 390 × 844 |  |  |  |  |  |  |
| Web 1440 × 900 |  |  |  |  |  |  |
| Web 1920 × 1080 |  |  |  |  |  |  |
| Android runtime |  |  | N/A/observação |  |  |  |

Verificações separadas de release:

- [ ] teclado Web real;
- [ ] foco visível e ordem coerente;
- [ ] alvos mínimos;
- [ ] TalkBack humano;
- [ ] texto ampliado;
- [ ] reduced motion;
- [ ] orientação/área segura quando aplicável.

## L. Pesquisa e concorrência

| Tipo | Fonte | Evidência | Relevância | Limite |
|---|---|---|---|---|
| `O` oficial |  |  |  | Não define automaticamente o roadmap |
| `U` usuário |  |  |  | Qualitativo/autoselecionado |
| `I` inferência |  |  |  | Precisa de validação |

## M. Scorecard

Usar `0–4`; `N/A` exige justificativa.

| Dimensão | Nota | Evidência/resumo |
|---|---:|---|
| Clareza |  |  |
| Continuidade |  |  |
| Valor |  |  |
| Ação |  |  |
| Identidade visual |  |  |
| Imagem significativa |  |  |
| Hierarquia/densidade |  |  |
| Confiança |  |  |
| Recuperação |  |  |
| Inclusão |  |  |
| Responsividade |  |  |
| Desejabilidade |  |  |

## N. Findings

| ID | Severidade | Evidência | Problema | Consequência para o usuário | Causa raiz | Confiança |
|---|---|---|---|---|---|---|
| `UX-...` | P0/P1/P2/P3 |  |  |  |  | baixa/média/alta |

## O. Proposta — ainda não implementada

| Campo | Conteúdo |
|---|---|
| Tese de conteúdo |  |
| Tese visual |  |
| Tese de interação |  |
| Wireflow proposto |  |
| Imagens/assets necessários |  |
| Estados afetados |  |
| Rotas/APIs/componentes afetados |  |
| Não objetivos |  |
| Riscos/dependências |  |
| Rollback |  |

## P. Critérios de fechamento futuro

### `PASS_AUTOMATED`

- [ ] teste focado;
- [ ] estados e semântica;
- [ ] regressão/contrato aplicável.

### `PASS_RUNTIME`

- [ ] Web real ou Android elegível;
- [ ] jornada exercitada;
- [ ] resultado e recuperação observados.

### `PASS_VISUAL_REVIEWED`

- [ ] todas as capturas foram abertas;
- [ ] acima e abaixo da dobra;
- [ ] mobile/desktop aplicáveis;
- [ ] loading/empty/error/modal/success aplicáveis;
- [ ] revisão registrada com digest correto.

Decisão da superfície: `NO_GAP_FOUND` / `GAP_CONFIRMED` / `BLOCKED` / `DEFERRED_BY_SCOPE`

Próxima ação: ______
