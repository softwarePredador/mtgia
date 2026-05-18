# Functional Card Tags Mass Audit - 2026-05-18

## Veredito

**PASS_WITH_RISKS** para auditoria em massa local no commit-base
`0f05c7f087925ae32fdd254ebf663a2f6e1f2e89`.

O runner aplicou `functional_card_tags_v1_2026_05_18` em todas as cartas locais
com `type_line` e `oracle_text`, sem salvar `oracle_text`, ids de cartas, dados de
conexao, secrets, tokens, e-mails QA ou decklists.

## Artefato sanitizado

- Caminho: `server/test/artifacts/functional_card_tags_mass_audit_2026-05-18/summary.json`
- Tamanho: ~215 KB.
- Conteudo permitido: contagens agregadas, nomes publicos de cartas em exemplos
  limitados, `type_line`, `mana_cost`, `cmc`, `confidence`, `evidence` em allow-list
  e reason codes de suspeita.
- Conteudo proibido e ausente: texto completo de `oracle_text`, ids de cartas,
  detalhes de conexao DB, secrets, JWT, DSN, API keys, e-mails QA e decklists.

## Cobertura final

| Metrica | Valor |
|---|---:|
| Linhas de cartas processadas | 33.435 |
| Nomes distintos | 33.196 |
| Linhas com ao menos uma tag | 22.272 |
| Nomes distintos com tag | 22.055 |
| Linhas sem tag | 11.163 |
| Cobertura por linha | 66,613% |
| Tempo do runner | 14.079 ms |

## Contagens principais por tag

| Tag | Linhas | Nomes distintos |
|---|---:|---:|
| `graveyard_synergy` | 4.781 | 4.781 |
| `removal` | 4.583 | 4.499 |
| `draw` | 4.516 | 4.513 |
| `token_maker` | 3.959 | 3.957 |
| `big_spell` | 3.847 | 3.839 |
| `ramp` | 3.247 | 3.127 |
| `protection` | 2.379 | 2.349 |
| `recursion` | 1.960 | 1.960 |
| `lifegain` | 1.825 | 1.825 |
| `artifact_synergy` | 1.412 | 1.412 |

## Cartas sem tag por tipo

| Tipo agregado | Linhas |
|---|---:|
| `creature` | 7.130 |
| `enchantment` | 1.365 |
| `instant` | 987 |
| `sorcery` | 734 |
| `artifact` | 733 |
| `other` | 197 |
| `planeswalker` | 9 |
| `battle` | 8 |

## Bugs claros corrigidos

1. `Nature's Lore`/buscas de tipo basico estavam entrando como `tutor`; agora
   `Forest/Plains/Island/Swamp/Mountain card`, `basic land` e `land card` ficam
   fora de tutor generico e seguem como ramp quando aplicavel.
2. Textos de hate como "opponents can't gain life" estavam entrando como
   `lifegain`; agora negacoes diretas de ganho de vida nao viram lifegain.
3. `ward`, "can't be the target", prevencao global de dano e regeneracao
   estavam ausentes de `protection`; agora entram como protecao.
4. `board_wipe` disparava em textos de atribuicao de dano de combate ou efeitos
   que afetam apenas criaturas do controlador; o helper de wipe agora evita esses
   casos e exige sinais de sweeper mais fortes para dano em cada criatura.
5. `candidate_quality_data_support.dart` foi alinhado para nao reintroduzir
   buscas de terreno como `tutor` por meio do bloco legado.

## Suspeitas remanescentes

Esses numeros sao diagnostics heurísticos, nao falhas finais:

| Categoria | Reason code | Linhas |
|---|---|---:|
| Possivel FP | `counterspell_low_confidence_protection_signal` | 463 |
| Possivel FP | `graveyard_card_return_counted_as_removal` | 61 |
| Possivel FP | `blink_like_exile_return_counted_as_removal` | 57 |
| Possivel FP | `temporary_mana_or_ritual_counted_as_ramp` | 40 |
| Possivel FN | `draw_text_not_tagged_draw` | 450 |
| Possivel FN | `fight_edict_or_damage_interaction_not_tagged` | 343 |
| Possivel FN | `broad_mana_or_land_acceleration_not_tagged_ramp` | 311 |
| Possivel FN | `broad_each_or_all_creature_sweeper_not_tagged` | 266 |

## Contrato/API

Nao houve mudanca de formato de resposta app-facing. O contrato existente de
`functional_tags.{schema_version,counts,samples,coverage}` permanece aditivo e
compatível. O valor de `schema_version` foi preservado porque esta rodada corrigiu
bugs dentro da mesma implantacao v1 do dia, sem alterar o shape do payload.

## Comandos executados

```bash
cd server && dart format bin/audit_functional_card_tags_mass.dart
cd server && dart analyze bin/audit_functional_card_tags_mass.dart
cd server && dart run bin/audit_functional_card_tags_mass.dart
cd server && dart format lib/ai/functional_card_tags.dart lib/ai/optimization_functional_roles.dart lib/ai/candidate_quality_data_support.dart test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart
cd server && dart analyze lib/ai/functional_card_tags.dart lib/ai/optimization_functional_roles.dart lib/ai/candidate_quality_data_support.dart test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart
cd server && dart test test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart -r expanded
cd server && dart run bin/audit_functional_card_tags_mass.dart
cd server && dart analyze lib/ai routes/ai bin test
cd server && dart test test/functional_card_tags_test.dart test/candidate_quality_data_support_test.dart -r expanded
git --no-pager diff --check -- <changed-files>
python3 <simple-secret-scan-for-changed-files>
```

## Pass/fail

- Runner estatico: PASS.
- Auditoria em massa no banco real configurado: PASS.
- Testes focados de tags e candidate quality: PASS.
- `dart analyze lib/ai routes/ai bin test`: PASS.
- `git diff --check`: PASS.
- Scan simples de secrets em arquivos alterados e artefato: PASS.
- Sanitizacao do artefato: PASS_WITH_RISKS pelos riscos heurísticos listados,
  nao por vazamento detectado.

## Riscos e limites

- Os reason codes de FP/FN sao detectores amplos para triagem; precisam de revisao
  humana antes de virar mudanca automatica.
- `counterspell_can_protect_plan` continua como sinal de baixa confianca; ele nao
  entra nos counts principais de `FunctionalDeckSummary` quando abaixo do threshold
  padrao, mas aparece no audit completo por carta.
- DFC/split/adventure/modal podem combinar faces em uma linha local de
  `oracle_text`; o artefato marca essa limitacao e nao persiste o texto.
- O runner e somente leitura, mas usa o banco configurado localmente; nao grava
  tabelas nem altera `cards`/`card_function_tags`.

## Menores proximos fixes

1. Revisar separadamente removal em blink/recursion antes de alterar o detector,
   porque ha efeitos legitimos de exile/return e bounce.
2. Separar `ritual` de `ramp` nos counts de Deck Analysis se produto decidir que
   ramp deve significar somente aceleracao permanente.
3. Criar fixtures adicionais para fight/edict, investigate/connive e sweepers
   condicionais antes de ampliar recall.
