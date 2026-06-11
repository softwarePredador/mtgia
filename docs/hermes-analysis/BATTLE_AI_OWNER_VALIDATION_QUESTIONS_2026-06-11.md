# Battle/AI/Hermes - Validacao Do Owner Antes Das Proximas Fases

> Data: 2026-06-11
> Status: documento de perguntas, furos e logistica para resposta do owner.
> Escopo: battle simulator, geracao/otimizacao de decks, semantic sync,
> Hermes, learned decks e Lorehold.
>
> Este arquivo nao autoriza mudanca de comportamento por si so. Ele existe para
> separar o que ja esta aprovado do que ainda precisa de validacao antes de
> virar codigo, schema, cron apply ou regra de produto.

## 1. Contexto resumido

As analises externas recebidas nesta rodada convergem no mesmo ponto:

- `deck_cards.quantity` deve continuar sendo a unica fonte de cardinalidade.
- `card_function_tags` deve ser a camada canonica de multi-funcao para
  deckbuilding.
- `card_battle_rules` deve continuar sendo semantica executavel/revisavel para
  simulacao, replay e auditoria, nao fonte direta de quantidade ou papel
  principal de deck.
- Hermes SQLite e read model/cache operacional; PostgreSQL/backend continuam
  sendo a fonte de verdade do produto.
- A solucao correta para cartas com multiplas funcoes/regras e agregacao por
  `card_id`, preservando arrays, e nunca escolher uma regra com `LIMIT 1`.

Documentos tecnicos relacionados:

- `docs/hermes-analysis/BATTLE_AI_DECK_LOGIC_DEEP_DIVE_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_IMPLEMENTATION_PLAN_2026-06-11.md`
- `docs/hermes-analysis/BATTLE_SEMANTIC_SYNC_SLICE1_REPORT_2026-06-11.md`
- `docs/hermes-analysis/IMPLEMENTATION_GAPS.md`

## 2. Defaults ja aprovados

Usar estes defaults ate decisao contraria explicita:

| Tema | Default aprovado |
|---|---|
| Release | estabilidade primeiro |
| Mox premium | sem ban global; excecao Lorehold learned deck permanece local |
| Learned decks | single commander ate existir corpus partner/background |
| Singleton Commander | duplicata por identidade bloqueia save/import |
| Metadados Hermes | ocultos para usuario normal; visiveis so em QA/dev |
| Autoridade | Hermes propoe; backend/PostgreSQL possuem a verdade |
| `needs_review` | nao executa comportamento duro |
| `card_battle_rules` -> tags | permitido so quando confiavel e rastreavel |
| Primeiro slice | limitado a agregacao + snapshot Hermes + testes |

## 3. O que ja pode ser implementado sem nova decisao

Estas tarefas seguem os defaults acima e podem continuar:

1. Classificar scripts Hermes que ainda consultam `functional_tag` diretamente
   como `active`, `manual`, `legacy` ou `archive`.
2. Migrar apenas scripts ativos para `functional_tags_json` com fallback para
   `functional_tag`.
3. Fazer backup do SQLite real do Hermes antes de qualquer apply.
4. Rodar apply controlado do snapshot agregado no Hermes runtime real somente
   depois dos consumidores criticos estarem compatíveis.
5. Rodar report-only depois do apply e comparar:
   - soma de `deck_cards.quantity`;
   - total Commander 100;
   - 1 commander + 99 main para Lorehold atual;
   - `deck_hash` estrutural;
   - `semantics_hash`;
   - ausencia de fanout.
6. Manter `card_battle_rules` como array preservado em contexto de deck, sem
   promover para papel de deckbuilding automaticamente.
7. Documentar todo achado Hermes como proposta com evidencia, nao como tarefa
   generica.

## 4. Furos reais que ainda precisam ser fechados

| Prioridade | Furo | Por que importa | Proximo passo seguro |
|---|---|---|---|
| P1 | Consumidores historicos podem depender de `functional_tag` unico | Um script antigo pode gerar relatorio errado ou proposta ruim mesmo sem alterar deck | Inventariar com `rg`, classificar e migrar so os ativos |
| P1 | Snapshot agregado ainda nao foi aplicado no SQLite Hermes real | A prova atual foi em SQLite temporario | Backup, apply controlado, report-only e rollback plan |
| P1 | Identidade semantica da carta ainda e ambigua | Split/MDFC/DFC/adventure/localized names podem exigir oracle/faces | Planejar migracao para `oracle_id`, `layout`, `card_faces_json` ou equivalente |
| P1 | Singleton Commander por impressao pode falhar | `deck_id/card_id` nao basta para regra singleton por identidade/nome | Criar validacao canonical-name/oracle identity antes de salvar/importar |
| P1 | `card_battle_rules` pode ter regras equivalentes duplicadas | Agregar por `card_id` preserva arrays, mas nao deduplica regra logica | Definir `logical_rule_key` antes de derivacao ou execucao mais forte |
| P1 | Derivacao de battle rules para tags ainda nao tem gate formal | Regra fraca ou `needs_review` nao pode virar tag canonica | Definir gate por `source`, `review_status`, `confidence` e stale cleanup |
| P2 | Replays nao carregam snapshot semantico completo | Forensic/debug fica dependente de nome/effect legado | Adicionar `card_id`, `semantic_hash`, `rule_version`, `variant_kind` em fase propria |
| P2 | ML feedback ainda nao dirige politica | Usar cedo pode consolidar falso positivo | Usar apenas apos scorecard comparativo |
| P2 | Partner/background learned deck nao tem contrato de UI/corpus | Dois commanders mudam contagem e identidade de cor | Manter como gap explicito ate corpus real |

## 5. Perguntas para voce validar antes das proximas fases

Responda apenas os itens que quiser destravar agora. Sem resposta, valem os
defaults da secao 2.

1. Podemos aplicar o snapshot agregado no Hermes runtime real depois de backup e
   report-only, ou quer manter tudo em dry-run local por mais uma rodada?
2. A migracao de identidade semantica (`oracle_id`, `layout`,
   `card_faces_json`) entra nos proximos 20 dias ou fica como planejamento
   documentado para depois do release interno?
3. A validacao singleton por identidade/nome em Commander deve bloquear
   imediatamente save/import ou primeiro virar warning tecnico?
4. Para usuario normal, o texto do deck aprendido deve esconder completamente
   `Hermes`, `learned_deck:id`, score e confidence?
5. A excecao sem Mox premium continua exclusiva do Lorehold learned deck 82?
6. O app deve mostrar explicacao "por que esta carta" usando
   `functional_tags_json`, ou isso fica so em QA/dev por enquanto?
7. `card_battle_rules` com `needs_review` pode aparecer em diagnostico
   interno, desde que nao execute comportamento duro?
8. Crons Hermes podem abrir PR/branch automaticamente no futuro, ou devem
   continuar apenas report-only ate revisao manual?
9. Quando Hermes sugerir swaps Lorehold, o backend pode salvar uma proposta
   revisavel, ou o usuario deve sempre aplicar manualmente?
10. Devemos priorizar o contrato PG `deck_card_semantics_v1` como view/function
    antes de novas regras modernas de battle?

## 6. Ideias que parecem boas, mas nao devem entrar sem prova

| Ideia | Risco | Gate minimo |
|---|---|---|
| Promover toda tag derivada de `card_battle_rules` | Mistura regra executavel com papel de deckbuilding | Gate por fonte/status/confianca + stale cleanup |
| Usar `semantic_tags_v2` como hard gate de optimize | Falso positivo/falso negativo em corpus pequeno | Scorecard por comandante e papel critico |
| Generalizar ban de Mox premium | Quebra decks high-power/bracket especifico | Politica de bracket/budget aprovada |
| Learned deck para partner sem UI nova | Contagem 98+2 e identidade de cor podem confundir usuario | Corpus partner + preview que mostra ambos commanders |
| Unificar simulador backend com Hermes | Risco de performance e contrato app-facing instavel | API nova, benchmark e rollback |
| Fazer judge engine completo | Escopo explode e atrasa release | Foco em casos Commander reais com replay/teste |

## 7. Ordem recomendada para Codex continuar

1. Inventariar consumidores restantes de `functional_tag` direto.
2. Criar relatorio de classificacao: ativo/manual/legado/arquivo.
3. Migrar consumidores ativos restantes para helper set-based.
4. Rodar testes Python, battle conformance e backend analyze.
5. Backup + apply controlado do snapshot Hermes real.
6. Rodar report-only Hermes e comparar hashes/totais.
7. So depois planejar `deck_card_semantics_v1` no PostgreSQL/backend.

## 8. Criterio para considerar esta fase pronta

Esta fase so fica pronta quando:

- nenhum consumidor ativo de deck enriquecido depende exclusivamente de
  `functional_tag`;
- snapshot Hermes real foi aplicado com backup e rollback possivel;
- report-only confirma que enriquecimento semantico nao muda cardinalidade;
- `IMPLEMENTATION_GAPS.md` separa claramente backlog de battle/regras de
  produto/UX;
- o owner validou ou manteve defaults para os itens da secao 5.
