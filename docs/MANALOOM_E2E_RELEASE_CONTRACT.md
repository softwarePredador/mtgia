# Contrato E2E e de conclusão do ManaLoom

Este é o contrato operacional vigente para validar, concluir e preparar uma
entrega do repositório. Relatórios datados registram evidência de uma rodada;
eles não substituem este contrato.

## Regras invariantes

- PostgreSQL é a fonte de verdade de produto. Hermes/SQLite e relatórios são
  cache, laboratório ou evidência; nunca promovem verdade revisada por conta
  própria.
- Nenhum gate local determinístico escreve em PostgreSQL, chama IA externa ou
  cria dados em uma API viva.
- Uma escrita live exige a confirmação textual
  `MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL`.
- Uma escrita via API viva exige o token live; SQL direto, migração ou cleanup
  direto em PostgreSQL exige também
  `MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL`.
- Flags booleanas como `MANALOOM_RUN_*` selecionam uma camada, mas não são
  autorização de escrita.
- DDL de produto pertence somente a migrations. Caminhos de request, serviços e
  testes read-only não podem criar ou alterar schema implicitamente.
- Suites legacy de HTTP só podem usar alvo local/staging explícito. O hostname
  conhecido de produção é bloqueado nelas.
- Um `SKIP` precisa declarar pré-requisito e comando de ativação. Ele não pode
  ser apresentado como `PASS`.

## Perfis canônicos

| Perfil | Escopo | Rede/escrita | Entrada | Resultado esperado |
| --- | --- | --- | --- | --- |
| `deterministic-read-only` | app, server, deckbuilder, battle, contratos, PG/Hermes read-only | sem mutação de produto | `./scripts/quality_gate.sh e2e` | `PARTIAL` quando as camadas opcionais forem declaradamente puladas; zero falhas/bloqueios |
| `isolated-mutating` | corpus Commander completo em ambiente aprovado | cria e remove usuários/decks de validação | `MANALOOM_RUN_MUTATING_RESOLUTION_E2E=1` + token PostgreSQL | `PASS` somente com cleanup e resumo do corpus |
| `live-smoke` | Flutter runtime, API viva e smoke comercial | pode criar/apagar dados e chamar serviços externos | flags `MANALOOM_RUN_*_E2E=1` + tokens live/PG aplicáveis | `PASS` somente no alvo explicitamente aprovado |
| `release-target` | build instalável, device/simulador, saúde e SHA implantado | depende do alvo de release | checklist desta página | conclusão de release, não apenas conclusão local |

O resumo da suíte é gravado por padrão em
`/tmp/manaloom_e2e_suite_reports/<run>/summary.md` e `summary.json`. Os status
válidos são:

- `PASS`: todas as etapas solicitadas executaram e passaram;
- `PARTIAL`: não houve falha, mas camadas opcionais não solicitadas foram
  registradas como `SKIP`;
- `BLOCKED`: uma camada foi solicitada sem autorização ou pré-requisito;
- `FAIL`: pelo menos uma etapa executada falhou.

## Matriz mínima de gates

| Área | Comando canônico | Mutação de produto |
| --- | --- | --- |
| Server + app completos | `./scripts/quality_gate.sh full` | não; tags live são excluídas |
| Contrato do harness p50/p95 | `./scripts/quality_gate.sh performance` (também incluído em `full`) | não; valida código/orçamentos sem abrir browser, device ou fixture |
| Dependências | `./scripts/quality_gate.sh deps` | não |
| Regras ManaLoom | `./scripts/quality_gate.sh custom-lint` | não |
| UI/goldens/acessibilidade | `./scripts/quality_gate.sh ui-audit` | não |
| Jornadas Patrol locais | `./scripts/quality_gate.sh patrol-smoke` | não |
| Battle nativo/Forge/XMage | `./scripts/quality_gate.sh battle` | não |
| Ponte app/IA | `./scripts/quality_gate.sh ai-bridge` | não |
| Ramp, optimizer, fundação de dados e regras | etapa `Ramp classifiers and data-foundation safety contracts` de `./scripts/quality_gate.sh e2e` | não; somente testes locais, preflight e injeção simulada de falha |
| Contrato PG/Hermes/SQLite | `./scripts/quality_gate.sh pg-contract` | leitura de PG; relatórios em `/tmp` |
| IA/deckbuilder profundo | `./scripts/quality_gate.sh deep-ai` | leitura de PG; não aplica migração |
| Retenção de relatórios | `./scripts/quality_gate.sh report-retention` | não |
| Produto integrado local | `./scripts/quality_gate.sh e2e` | não por padrão |

O gate de battle deve ser reprodutível sem o `~/.m2` da máquina. O bootstrap
`services/xmage-sidecar/bin/bootstrap_pinned_xmage_maven.sh` instala os módulos
XMage ausentes do Maven Central a partir do SHA de `XMAGE_COMMIT`; o CI executa
esse bootstrap antes do gate.

A etapa focada da suíte E2E executa explicitamente os classificadores de ramp
em Dart e Python, o piso estrutural do optimizer, os contratos de segurança da
fundação de qualidade de candidatos e da sincronização das Comprehensive Rules.
Testes de segurança do backfill `semantic_layer_v2` entram automaticamente
quando existem no repositório; a etapa nunca chama `--apply`.

## Camadas que exigem autorização

### Corpus Commander mutante

```bash
MANALOOM_RUN_MUTATING_RESOLUTION_E2E=1 \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
./scripts/quality_gate.sh e2e
```

### Smoke live completo

Defina também `MANALOOM_API_BASE_URL`/`TEST_API_BASE_URL` para o alvo aprovado.

```bash
MANALOOM_RUN_FLUTTER_RUNTIME_E2E=1 \
MANALOOM_RUN_SERVER_LIVE_E2E=1 \
MANALOOM_RUN_LIVE_PRODUCT_E2E=1 \
MANALOOM_CONFIRM_LIVE_MUTATIONS=I_HAVE_EXPLICIT_APPROVAL \
MANALOOM_CONFIRM_POSTGRES_WRITES=I_HAVE_EXPLICIT_APPROVAL \
./scripts/quality_gate.sh e2e
```

Não copie esses tokens para `.env`, CI ou documentação de comando automático.
Eles representam aprovação humana para uma execução específica.

## Critério de conclusão

### Conclusão local do projeto

Uma rodada pode ser declarada concluída localmente quando:

1. `git diff --check` e a sintaxe dos scripts alterados estão verdes;
2. `full`, `deps`, `custom-lint`, `ui-audit`, `patrol-smoke`, `battle`,
   `report-retention` e o perfil E2E determinístico estão sem falhas;
3. Android e iOS continuam enumeráveis/compiláveis nos alvos disponíveis;
4. artefatos removidos têm zero consumidor ativo e substituto canônico;
5. relatórios gerados ficam em `/tmp` ou diretório ignorado, salvo evidência
   revisada e manifestada;
6. toda camada não executada aparece como `SKIP`/pendência, nunca como sucesso.

### Conclusão de release

Além da conclusão local, exige:

1. build instalável no(s) alvo(s) de distribuição;
2. jornada crítica em device/simulador representativo;
3. smoke live no ambiente explicitamente aprovado, com cleanup validado;
4. pagamentos/webhooks/serviços externos aplicáveis ao release;
5. `/health`, `/ready` e SHA implantado compatíveis com a revisão entregue;
6. nenhuma migração pendente necessária ao código implantado.

Sem esses itens, o resultado correto é “localmente concluído, release
pendente”, e não “produção concluída”.

## Política de legado e artefatos

Um arquivo só pode ser removido automaticamente quando não tem consumidor
ativo, não é prova citada, possui substituto canônico quando necessário e os
gates relevantes permanecem verdes. Duplicatas de empacotamento exigidas por
runtimes distintos não são legado apenas por terem o mesmo hash.

Dados brutos em `docs/hermes-analysis/master_optimizer_reports/` são
classificados como `active_consumer`, `manifest_only` ou `ungoverned` pelo gate
de retenção. `ungoverned` falha o gate. `manifest_only` continua dívida de
arquivo explícita e não pode inflar a contagem de consumidores ativos.

## Evidência da rodada corrente

A revalidação mais recente do checkout local está em
`docs/qa/MANALOOM_E2E_CORE_DOCUMENTATION_AUDIT_2026-07-21.md`. O aggregate
determinístico daquela rodada terminou `FAIL` com 8 etapas aprovadas, 2 falhas
e 9 skips explícitos. O Battle passou isoladamente antes/depois, mas o analysis
server caiu dentro do aggregate; retenção permaneceu vermelha por 18 artefatos
locais e o host ficou sem espaço durante `full`/Flutter completo. Portanto, a
evidência de 2026-07-21 não declara conclusão local nem release.

O resultado e os resíduos da varredura anterior de 2026-07-15 ficam em
`docs/qa/MANALOOM_E2E_PROJECT_CLOSURE_2026-07-15.md`. Naquela execução, o perfil
determinístico ficou sem falhas e as 35 migrations estavam executadas, mas não
havia release implantada. O follow-up operacional do mesmo dia publicou a API,
o app Flutter autenticado em `/app` e o APK Android assinado no servidor novo;
o APK passou em aparelho físico e teve o download conferido por SHA-256. Isso
não altera retroativamente o resultado da suíte nem fecha iOS: a distribuição
nativa ainda exige uma equipe Apple Developer/App Store Connect da ManaLoom.
