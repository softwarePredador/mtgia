# Commander Learning Execution Tracker - 2026-06-03

## Objetivo
Concentrar em um unico lugar as atividades restantes de App, Backend e Hermes para o fluxo de decks aprendidos, marcando o que ja foi concluido, o que eu consigo executar e o que depende do usuario/ambiente externo.

## Status Atual
- Backend publico esta validado com `/ai/commander-learning`.
- PG tem `commander_learned_decks` com Lorehold `learned_deck:82` ativo.
- App tem atalho condicional `Usar deck aprendido do comandante` na tela de gerar deck, exibido apenas para comandantes com deck aprendido ativo.
- Hermes ainda precisa de export/sync automatizado recorrente.

## Atividades Que Eu Consigo Executar

| Status | Area | Atividade | Criterio de conclusao |
|---|---|---|---|
| Concluido | Backend | Criar `GET /ai/commander-learning` sem `commander` para listar comandantes com deck aprendido ativo | Endpoint retorna lista com `commander`, `deck_name`, `source_ref`, `last_synced_at`, `legal_status` |
| Concluido | Backend | Melhorar contrato de `/ai/commander-learning` | Payload inclui `win_conditions`, `role_summary`, `source_confidence`, `last_synced_at` |
| Concluido | Backend | Documentar API dedicada | Doc `COMMANDER_LEARNING_API_2026-06-03.md` criado com request, response, campos, exemplo e `available=false` |
| Pendente | Backend | Reduzir duplicacao entre `commander-reference` e `commander-learning` | Helpers comuns extraidos sem alterar contrato publico |
| Pendente | Backend | Ampliar testes do endpoint dedicado | Teste cobre contrato/listagem/prioridade de deck ativo |
| Concluido | App | Melhorar UX do botao de deck aprendido | Botao explica origem, score e legalidade antes do clique |
| Concluido | App | Mostrar origem/score/legalidade no preview | Preview exibe `Hermes`, `learned_deck:82`, score, legalidade e confianca |
| Concluido | App | Usar listagem para mostrar botao apenas quando houver deck aprendido | Tela consulta disponibilidade e evita botao inutil para comandantes sem deck ativo |
| Concluido | App | Adicionar teste widget do clique no botao | Mock confirma clique e preview com origem/score/legalidade |
| Pendente | App | Adicionar teste widget do save do deck aprendido completo | Mock confirma save payload com commander + 99 main |
| Pendente | Hermes | Criar script exportador JSON a partir do SQLite Hermes | Script gera payload aceito por `bin/commander_learned_deck.dart` |
| Pendente | Hermes | Criar wrapper de sync Hermes -> PG | Wrapper exporta, faz dry-run, aplica e registra resumo |
| Pendente | Hermes | Preparar cron/manual job documentado | Comando recorrente documentado com logs e rollback simples |

## Atividades Que Dependem Do Usuario Ou Ambiente Externo

| Status | Area | Atividade | Por que depende de voce |
|---|---|---|---|
| Pendente | App | Teste visual real em device/simulador | Precisa confirmar UX visual/interacao em ambiente real; posso tentar localmente se voce autorizar tempo e possiveis bloqueios de simulator |
| Pendente | Operacao | Deploy manual via EasyPanel se deploy automatico falhar | Nao tenho SSH valido no host publico/EasyPanel; consigo validar `/health` quando o deploy ocorrer |
| Concluido | Produto | Decidir se o botao deve aparecer sempre ou so apos detectar disponibilidade | Implementado como condicional: mostrar so quando houver deck ativo |
| Pendente | Produto | Decidir se cron Hermes deve aplicar automaticamente ou exigir revisao manual | Afeta operacao recorrente e risco de promover deck errado; recomendacao tecnica: dry-run + apply manual no inicio |

## Ordem Recomendada
1. App: adicionar teste widget do save do deck aprendido completo.
2. Backend: reduzir duplicacao entre `commander-reference` e `commander-learning`.
3. Hermes: criar export JSON e wrapper sync.
4. Hermes: documentar job recorrente com dry-run + revisao manual inicial.
5. Usuario: testar visualmente em device/simulador.
6. Usuario: decidir politica final de cron Hermes automatico vs revisado.

## Como Marcar Concluido
Atualizar a coluna `Status` para `Concluido` e adicionar uma nota curta com commit, comando de validacao ou evidencia publica.

Exemplo:
```text
Concluido - commit abc123 - `flutter test ...` passou - endpoint publico validado HTTP 200
```

## Evidencias Ja Existentes
- Commit `4cf90e57`: backend expõe deck aprendido via `commander-reference`.
- Commit `9daff606`: app tem atalho inicial para deck aprendido.
- Commit `06bb644e`: rotina idempotente `commander_learned_deck.dart` criada.
- Commit `a763f15b`: endpoint dedicado `/ai/commander-learning` criado.
- Endpoint dedicado validado publicamente com Lorehold: 100 cartas, 99 main, legalidade valida, 0 Mox premium.
- Verificacao local desta rodada: `dart analyze` focado backend/app sem issues; `dart test test/commander_learned_deck_support_test.dart` passou; `flutter test test/features/decks/providers/deck_provider_test.dart test/features/decks/screens/deck_flow_entry_screens_test.dart` passou.
