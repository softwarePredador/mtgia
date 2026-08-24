# Receipt de execução — `BT-DOC-001`

Status: `PASS_LOCAL · COMMITTED · NOT_PUSHED`

Este receipt prova somente o fechamento local de `BT-DOC-001`. Ele não
autoriza push, PR, merge, deploy, migration live, escrita em PostgreSQL live,
capability ON, promoção de deck/regra ou atualização de pin externo.

## Identidade

- Branch: `codex/free-beta-release-candidate-2026-07-17`
- SHA inicial:
  `b09ac6dbb6b88f2ea235404431049609da3215ff`
- SHA final da implementação:
  `c6e2725af0995e01dcf675f20e3a8b608b84d555`
- Upstream observado:
  `b2d3fc04f823f1c58434349a0cf0b48d74919862`
- Relação na implementação: `ahead_by=4`, `behind_by=0`, `NOT_PUSHED`
- Project logic digest da implementação:
  `be3bf02dba40befead607ba4f34a55595e1322ef9dc1a7bccc6396b1ccac9cee`
- Project logic digest de fechamento:
  `c1ddf67874b4861c9736cd64c5519887a3e59106e9658f12276a6905d9387a96`
- Registry source SHA-256 de fechamento:
  `5109f0e0e5585c2c6ce3655514d2f8a5f38331105f6a6471ee9069e520d25864`
- Generator: `manaloom_project_logic 1.4.0`
- Início UTC: `2026-08-24T16:38:30Z`
- Fim UTC: `2026-08-24T19:43:25Z`
- Autorização usada: documentação/tooling local e commits atômicos locais;
  nenhum push, deploy ou alvo live

## Resultado

- `README.md` e `docs/README.md` viraram roteadores curtos para decisão,
  backlog, fila, sistema gerado, contratos, receipts e histórico.
- `.github/AGENT_POLICY.md` passou a ser a policy única herdada pelos 11 perfis
  de agente e pelas duas instruções globais; não há autorização implícita de
  commit, push, deploy, DML, capability, pin, regra ou deck.
- Os entrypoints humanos e todos os Markdown `.github` entraram no lineage.
- Contratos atuais de coleção, deltas externos, aliases e XMage/Forge foram
  incluídos entre os inputs canônicos aplicáveis.
- Planos, trackers, ADR duplicado, roadmap e manual históricos receberam
  lifecycle inequívoco e `NO_MUTATION_AUTHORITY` no próprio cabeçalho.
- O gerador falha fechado se um histórico explícito estiver ausente ou perder
  os marcadores de segurança; o negativo usa um tracker com migration, escrita
  live e deploy sem banner.
- O contrato E2E deixou de incorporar uma “rodada corrente” envelhecível e o
  contrato UI classificou reels derivados sem conceder crédito E2E.
- MP4s derivados permanecem locais e ignorados em
  `docs/qa/ui-live/videos/`; nenhum binário foi commitado.

## Evidência

| Camada | Resultado |
| --- | --- |
| Project logic | `PASS`; 9 artefatos sincronizados, digest `be3bf02d…` na implementação |
| Testes do gerador | `PASS`; 23/23, incluindo negativo histórico fail-closed |
| Semantic analysis | `PASS`; 684/684 fontes resolvidas, zero arquivo com diagnóstico de erro |
| Documentação Dart | `PASS`; app, server e tools sem warnings/erros |
| Hook `quick` | `PASS`; executado normalmente no commit `c6e2725af` |
| Retenção | `PASS`; 17/17 testes |
| Segredos | `PASS`; zero credencial live literal e gitleaks 8.30.1 |
| Estrutura | `PASS`; `diff --check`, JSON parse e links dos READMEs |
| UI aggregate preexistente | `PASS`; 456 screenshots no digest `d517adb65b…`; nenhuma nova aprovação UI reivindicada |
| Auditoria independente | `GO`; o `NO-GO` inicial dos dois planos Battle foi corrigido e revalidado |

## Aceite canônico

| Cláusula | Evidência |
| --- | --- |
| Deck/IA possui mapa canônico | índice corrente, contratos canonizados e PostgreSQL/backend preservado como verdade |
| Plano/manual/Hermes antigo tem lifecycle inequívoco | overrides gerados, banners locais e históricos excluídos dos inputs ativos |
| Comando mutante histórico não parece operacional | `NO_MUTATION_AUTHORITY` obrigatório e teste negativo fail-closed |

## Limites e rollback

- Não houve mudança funcional, migration, PostgreSQL/Hermes/SQLite, runtime,
  capability, deck, regra, pin, push, PR ou deploy.
- Proteção remota de branch/PR continua ausente e exige autorização/execução
  própria; `BT-DOC-001` corrige o padrão local, não a configuração do GitHub.
- Receipt machine-readable forte e rastreabilidade completa continuam em
  `BT-GATE-002` e `BT-GATE-005`.
- Rollback: reverter `c6e2725af`, regenerar os nove artefatos e repetir os
  gates. Não existe estado live para restaurar.

## Veredito

`PASS` local para `BT-DOC-001`, gate-eligible para fechamento documental.
Produção e release não foram avaliadas nem alteradas. A fila avança para
`BT-DOC-004`.
