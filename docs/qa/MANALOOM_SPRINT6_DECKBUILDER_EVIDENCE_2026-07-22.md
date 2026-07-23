# ManaLoom — evidência da Sprint 6 (Deckbuilder e IA)

Data: 2026-07-22
Branch: `codex/free-beta-release-candidate-2026-07-17`
HEAD base observado: `2813152121c4d41069f9ebbb3334eb4c6b8b1110`
Owner: `/root`

## Decisão

**Sprint 6: `PASS` com rejeição explícita de promoção Lorehold.**

O Deckbuilder agora tem contrato público sanitizado, restrições fortes de
coleção/orçamento, cortes por lane, anchors protegidos, aplicação parcial/total
recalculada e E2E com provedor real. Isso não significa que o deck `607` seja
“perfeito” ou que um sucessor definitivo tenha sido encontrado. O desenho
pareado histórico era incompatível com XMage/Forge; o candidato foi rejeitado,
o `607` continua baseline protegido e a UI o identifica como experimental e
bloqueado para aplicação automática.

## Resultado por task

| Task | Estado | Evidência principal |
|---|---|---|
| S6-01 | PASS | contrato `commander_deckbuilding_contract_v6_2026-07-22`, fluxo completo e resumo público v3 |
| S6-02 | PASS | proveniência pública separa Oracle, preço, corpus, uso aprendido e sugestão; metadados internos são removidos |
| S6-03 | PASS | 295/295 decks PostgreSQL classificados; owner intent preservada; reparos não são automáticos |
| S6-04 | PASS | mesma lane ou hipótese explícita; anchors não podem ser cortes silenciosos |
| S6-05 | PASS | coleção/orçamento hard, apply parcial/total, reanálise persistida e rollback com drift guard |
| S6-06 | PASS | modelo pareado retirado; amostras externas independentes balanceadas; nenhum candidato promovido |
| S6-07 | PASS | deck `607` protegido e apresentado como `experimental_blocked` |
| S6-08 | PASS | held-out global, dois modelos reais, latência, tokens e custo medidos |
| S6-09 | PASS | ciclo real completo em PostgreSQL descartável com catálogo de 34.653 cartas |

## S6-01, S6-02 e S6-04 — contrato de planejamento

O fluxo canônico cobre, nesta ordem:

1. legalidade e bracket;
2. intenção do comandante e arquétipo;
3. planos principal e alternativo de vitória;
4. mana e curva;
5. card flow e motores;
6. interação, proteção e resiliência;
7. packages do comandante;
8. combos, sinergias e finalizadores;
9. corpus de referência e uso aprendido;
10. staples por papel e impacto;
11. cortes por lane com proteção de anchors;
12. iteração por goldfish, Battle e replay.

Cada swap precisa ter carta de saída presente, carta de entrada catalogada,
identidade de cor e bracket válidos, lane preservada ou hipótese explícita,
anchor autorizado e ausência de rejeição Battle já registrada. Explicações
públicas incluem função, risco, curva, preço e bracket, mas não expõem campos
brutos do Hermes nem transformam fonte ausente em certeza.

## S6-03 — auditoria global no servidor novo

Comando executado pelo wrapper read-only, usando túnel efêmero e
`default_transaction_read_only=on`:

```bash
./server/bin/with_new_server_pg.sh --read-only python3 \
  docs/hermes-analysis/manaloom-knowledge/scripts/global_commander_deck_contract_audit.py \
  --out-prefix /tmp/manaloom_global_commander_s6_final
```

Resultado:

| Métrica | Valor |
|---|---:|
| decks PostgreSQL carregados/classificados | 295/295 |
| decks Hermes classificados | 17 |
| decks de usuário reais | 16 |
| estruturalmente prontos | 7 |
| exigem revisão do dono | 9 |
| mutações automáticas | 0 |

Os nove reparos pendentes são estado do conteúdo dos usuários, não falha de
classificação: faltam quantidade, comandante ou resolução de identidade em
alguns decks. O auditor preserva intenção, oferece reparo revisável e mantém
`promotion.allowed=false`. SHA-256 do JSON sanitizado:
`48571df0879bf18374d89069455f70004bf028347310874d35f8b98c4237b238`.
O túnel foi encerrado após a leitura.

## S6-05 — restrições, apply e rollback

O E2E provou que:

- `collection_only=true` rejeita carta não disponível;
- orçamento zero rejeita compra e informa `budget_exceeded`;
- disponibilidade vem do snapshot PostgreSQL, não do cache Hermes;
- preview não altera deck nem `validation_updated_at`;
- seleção parcial recalcula `post_analysis` apenas do estado realmente aplicado;
- aplicação integral identifica `selection_scope=full_preview`;
- mutação inválida é atômica e preserva o deck anterior;
- rollback restaura o snapshot, e drift posterior produz
  `optimization_rollback_conflict`.

## S6-06 e S6-07 — Lorehold

O entrypoint pareado histórico agora sempre falha fechado. Rótulos iguais de
seed não controlam o RNG de XMage ou Forge, portanto os 384 resultados antigos
são evidência descritiva, não pares estatísticos. O desenho substituto usa:

- amostras independentes por candidato/baseline e oponentes balanceados;
- mínimo de amostra não censurada por estrato;
- limite explícito de censura;
- Wilson e Newcombe para diferenças de proporções independentes;
- MOVER ponderado por oponente;
- teste condicional exato unilateral estratificado;
- hashes de registry/checkpoint e `automatic_promotion_allowed=false`.

O laboratório Python nativo pode repetir sua própria agenda, mas agora declara
`evidence_scope=diagnostic_native_only`,
`external_engine_seed_pairing_claim=false` e `promotion_allowed=false`.

Decisão atual: rejeitar a hipótese histórica, manter o deck `607` protegido e
só abrir nova comparação após uma hipótese same-lane distinta. Nenhum deck,
carta, regra ou PostgreSQL foi promovido por S6-06.

## S6-08 — qualidade, latência e custo

O corpus held-out tem seis casos, brackets 1–5, buckets colorless/mono/two/
three-plus e seis famílias de arquétipo, incluindo Lorehold com anchor
protegido. O gate determinístico passou:

```text
quality_gate.sh ai-eval: PASS
casos held-out: 6/6
score: 100 (mínimo 90)
suíte adicional: 111/111 testes
JSON SHA-256: 8c9e5b854eb00abb0d719507e3940eb3409a87b4f8a7bfbdde3230dae1db97f7
```

A execução real de `commander_ai_live_model_eval.dart --summary-only` produziu:

| Modelo | Casos | Score | p50 | p95 | Tokens | Custo estimado |
|---|---:|---:|---:|---:|---:|---:|
| `gpt-4o-mini` | 6/6 | 100 | 2.873 ms | 4.563 ms | 28.432 | US$ 0,004952 |
| `gpt-5.4-mini` | 6/6 | 100 | 2.651 ms | 5.041 ms | 29.091 | US$ 0,030106 |
| **global** | **12/12** | **100** | **2.873 ms** | **5.041 ms** | **57.523** | **US$ 0,035058** |

Não houve erro nem falha de qualidade. Os rótulos light/focused/aggressive/
rebuild representam categorias do corpus, não volume de produção projetado.

## S6-09 — ciclo real isolado

Comando:

```bash
env MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
    MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
    MANALOOM_ISOLATED_FULL_CARD_CATALOG=1 \
    MANALOOM_ISOLATED_SERVER_ENVIRONMENT=development \
    OPENAI_PROFILE=prod RUN_REAL_PROVIDER_LIFECYCLE=1 \
    ./scripts/manaloom_server_contract_e2e_isolated.sh \
      test/commander_ai_real_provider_lifecycle_live_test.dart \
      test/deck_optimization_apply_rollback_live_test.dart
```

Resultado do mesmo run:

```text
result=pass
tests=2/2
migration_count=50
latest_migration=050
card_catalog_count=34653
server_environment=development
openai_profile=prod
full_card_catalog_enabled=1
summary_sha256=a932e7717503026cdeda2c28305576fe1c091a865db0acd6945b05cf264cb144
```

O fluxo real percorreu `generate → validate → save → analyze → optimize →
rebuild preview → goldfish → Battle/replay`, sem mock e sem mutação causada por
preview. O segundo teste provou apply parcial/total e rollback. O catálogo
temporário importou 34.653 cartas e 330.207 legalidades.

Cleanup: servidor e cluster PostgreSQL descartável foram encerrados; dados de
teste desapareceram com o cluster; não restaram `pgdata`, socket, processo de
sync ou arquivo bruto `AtomicCards`. O diretório `/tmp` manteve somente logs e
resumos sanitizados pequenos.

## Falhas e aprendizado

Ausência/invalidade de chave, 401, 429, timeout, 5xx e resposta malformada são
cobertos por testes negativos. Toda resposta Optimize não 2xx recebe
`can_apply=false` e `learning_eligible=false`; mock e rebuild guiado também não
podem promover aprendizado. A ponte app/IA passou 22/22 checks, SHA-256
`8e4bb3d86c1f3b3655560e015eb4d46ed9c86ae59c7c5c66583b768c2e11bd65`.

## Testes focados

| Camada | Resultado |
|---|---:|
| estatística/global Lorehold Python | 16/16 PASS |
| contrato/Optimize/eval servidor | 78/78 PASS |
| modelos e UI Deckbuilder Flutter | 58/58 PASS |
| segurança de escopo nativo/independente/alinhamento | 25/25 PASS |
| alinhamento operacional | 53/53 PASS |

Risco residual: os nove decks reais incompletos precisam de decisão de seus
donos; e um novo Lorehold só pode superar o `607` depois de amostra externa
independente suficiente. Esses bloqueios são estados explícitos do produto,
não autorização para reconstrução ou promoção automática.
