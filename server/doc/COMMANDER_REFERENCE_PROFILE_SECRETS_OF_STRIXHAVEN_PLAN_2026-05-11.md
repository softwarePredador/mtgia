# Commander Reference Profile: Secrets of Strixhaven — 2026-05-11

## Objetivo

Expandir o pipeline de Commander Reference Profile v1 para todos os comandantes novos de `Secrets of Strixhaven` (`SOS`) e `Secrets of Strixhaven Commander` (`SOC`), usando o fluxo genérico já criado em `server/bin/commander_reference_profile.dart`.

## Escopo inicial

Fonte inicial: Scryfall API, query `(set:sos OR set:soc) is:commander not:reprint`.

Resultado: 36 comandantes novos.

Artifact semente:

- `server/test/artifacts/commander_reference_profile_secrets_of_strixhaven_2026-05-11/secrets_of_strixhaven_new_commanders_seed.json`

## Distribuição por identidade de cor

| Identidade | Quantidade | Comandantes |
| --- | ---: | --- |
| Colorless | 2 | The Dawning Archaic; Page, Loose Leaf |
| B | 2 | Arnyn, Deathbloom Botanist; Moseo, Vein's New Dean |
| BG | 5 | Dina, Essence Brewer; Gorma, the Gullet; Blech, Loafing Pest; Lluwen, Exchange Student // Pest Friend; Witherbloom, the Balancer |
| BW | 5 | Killian, Decisive Mentor; Scriv, the Obligator; Abigale, Poet Laureate // Heroic Stanza; Nita, Forum Conciliator; Silverquill, the Disputant |
| G | 2 | Nev, the Practical Dean; Emil, Vastlands Roamer |
| GU | 5 | Primo, the Unbounded; Zimone, Infinite Analyst; Berta, Wise Extrapolator; Quandrix, the Proof; Tam, Observant Sequencer // Deep Sight |
| R | 1 | Mica, Reader of Ruins |
| RU | 5 | Muddle, the Ever-Changing; Rootha, Mastering the Moment; Prismari, the Inspiration; Sanar, Unfinished Genius // Wild Idea; Zaffai and the Tempests |
| RW | 5 | Excava, the Risen Past; Quintorius, History Chaser; Aziza, Mage Tower Captain; Kirol, History Buff // Pack a Punch; Lorehold, the Historian |
| U | 2 | Jadzi, Steward of Fate // Oracle's Gift; Orysa, Tide Choreographer |
| W | 2 | Augusta, Order Returned; Ennis, Debate Moderator |

## Ordem recomendada

1. Lote 1: ciclos centrais das escolas e comandantes com maior chance de uso: Elder Dragons `Lorehold`, `Prismari`, `Quandrix`, `Silverquill`, `Witherbloom`, mais os face commanders `Dina`, `Killian`, `Rootha`, `Zimone`, `Quintorius`.
2. Lote 2: cinco cores de dois cards cada e comandantes monocoloridos com plano claro.
3. Lote 3: comandantes colorless e casos ambíguos que exigem decisão de produto.
4. Lote 4: reprints `is:commander` de `SOC`, somente se forem relevantes para geração do usuário.

## Critério de perfil aceito

Cada profile JSON precisa conter:

- `commander`: nome exato.
- `color_identity`: identidade Commander.
- `confidence`: `medium` ou `high`.
- `source_count`: quantidade de fontes ou evidências usadas.
- `themes`: arquétipos jogáveis.
- `role_targets`: metas de lands/ramp/draw/removal/protection/wincons/pacotes específicos.
- `expected_packages`: listas curadas por pacote funcional.
- `avoid_patterns`: padrões que a IA deve evitar.

## Critério de stats aceito

O runner deve resolver as cartas de `expected_packages` e persistir `commander_reference_card_stats` com:

- cartas resolvidas sem off-color;
- unresolved documentado;
- packages nomeados;
- confidence coerente;
- sem depender de scraping runtime;
- sem alterar legalidade, color identity ou deck validation.

## Comandos base

Dry-run de um profile:

```bash
cd server && dart run bin/commander_reference_profile.dart --profile-json=/absolute/path/profile.json --dry-run
```

Apply de um profile validado:

```bash
cd server && dart run bin/commander_reference_profile.dart --profile-json=/absolute/path/profile.json --apply
```

Validação backend:

```bash
cd server && dart analyze lib/ai routes/ai bin test && dart test test/commander_reference_profile_support_test.dart test/commander_reference_card_stats_support_test.dart test/commander_reference_profile_generate_live_test.dart test/ai_generate_performance_support_test.dart -r expanded
```

## Comando para agente de curadoria

```bash
copilot --agent "Commander Meta Web Research Analyst" --allow-all -p "Objetivo: criar Commander Reference Profiles v1 para os comandantes novos de Secrets of Strixhaven. Repo: /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia. Branch alvo: master. Leia server/doc/COMMANDER_REFERENCE_PROFILE_SECRETS_OF_STRIXHAVEN_PLAN_2026-05-11.md e o artifact server/test/artifacts/commander_reference_profile_secrets_of_strixhaven_2026-05-11/secrets_of_strixhaven_new_commanders_seed.json. Nao alterar codigo. Nao expor secrets, tokens, JWT, SENTRY_DSN, DATABASE_URL ou payload sensivel. Pesquisar fontes publicas confiaveis e de baixo volume para cada comandante, sem scraping agressivo e sem depender de API nao-oficial em runtime. Criar JSONs de profile em docs/qa/commander_reference_profiles_secrets_of_strixhaven_2026-05-11/ com commander, color_identity, confidence, source_count, themes, role_targets, expected_packages e avoid_patterns. Priorizar Lote 1: Lorehold, the Historian; Prismari, the Inspiration; Quandrix, the Proof; Silverquill, the Disputant; Witherbloom, the Balancer; Dina, Essence Brewer; Killian, Decisive Mentor; Rootha, Mastering the Moment; Zimone, Infinite Analyst; Quintorius, History Chaser. Gerar relatorio docs/qa/commander_reference_profiles_secrets_of_strixhaven_2026-05-11/README.md com fontes, riscos, unresolved e recomendacao PASS/PASS WITH RISKS/BLOCKED. Se houver profiles suficientes, nao aplicar no banco; deixar para o agente de implementacao. Worktree limpo ou commit de docs apenas se o conteudo estiver pronto."
```

## Comando para agente de aplicação/validação

```bash
copilot --agent "Commander Optimize Flow Auditor" --allow-all -p "Objetivo: aplicar e validar Commander Reference Profiles v1 de Secrets of Strixhaven ja curados. Repo: /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia. Branch alvo: master. Leia server/doc/COMMANDER_REFERENCE_PROFILE_SECRETS_OF_STRIXHAVEN_PLAN_2026-05-11.md, docs/qa/commander_reference_profiles_secrets_of_strixhaven_2026-05-11/ e server/doc/API_CONTRACTS_AND_DATA_MAP.md. Nao expor secrets, tokens, JWT, SENTRY_DSN, DATABASE_URL ou payload sensivel. Para cada profile JSON aprovado, rodar server/bin/commander_reference_profile.dart --dry-run, revisar resolved/unresolved/off-color, depois --apply somente se seguro. Rodar dart analyze lib/ai routes/ai bin test, dart test completo ou focado, e probes sanitizados de /ai/generate com commander_name para pelo menos 3 comandantes do lote. Atualizar server/doc/RELATORIO_COMMANDER_REFERENCE_PROFILE_SECRETS_OF_STRIXHAVEN_2026-05-11.md, server/doc/API_CONTRACTS_AND_DATA_MAP.md se houver drift, app/doc/APP_AUDIT_2026-04-29.md e server/manual-de-instrucao.md. Se encontrar bug claro, corrigir com teste. Commitar e subir em master com trailer Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>. Resultado final PASS/PASS WITH RISKS/BLOCKED e worktree limpo."
```

## Riscos

- Perfis fracos pioram a geração mais do que ajudam; usar `confidence=medium/high` apenas quando houver evidência suficiente.
- Comandantes novos podem ter pouca amostra pública; nesses casos, usar oracle text, precon decklist e pacotes determinísticos, marcando `source_count` e `confidence` corretamente.
- Não usar EDHREC/Archidekt como dependência runtime; referências devem virar dados locais auditáveis.
- Reprints de `SOC` não entram no primeiro lote para evitar diluir a etapa com comandantes já conhecidos.
