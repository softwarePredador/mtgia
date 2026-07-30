# ManaLoom — fechamento local de continuidade e E2E

**Data:** 2026-07-29
**Branch:** `codex/free-beta-release-candidate-2026-07-17`
**Digest visual corrente:** `91f4d5af5d61a1e7b9c244f6656ab2d3cf95e9ff23072f202ad040e343c60b34`
**Decisão:** `PASS_LOCAL_PRE_HOMOLOGATION / RELEASE_NO_GO`

## Resultado

As correções de coleção, criação de deck Commander, otimização, Battle,
resiliência do provedor e cobertura candidata de Lorehold estão implementadas
e validadas localmente. O build Flutter Web foi recompilado com Battle
interativo habilitado, e o produto permanece disponível em
`http://127.0.0.1:8088/app/`.

O estado ainda não recebe aprovação de release porque faltam provas que só
podem ser produzidas contra uma API autenticada com escrita explicitamente
autorizada, sidecars publicados na mesma SHA e a recaptura integral da matriz
P0 Web+Android.

## Alterações exercitadas

- coleção: preço finito, erro dentro do editor, preservação dos dados em falha
  e remoção do preço quando a carta deixa de estar à venda;
- deck: erro dentro do modal, foco/teclado, criação otimista consistente,
  seletor de comandante e filtro de elegibilidade por formato;
- otimização: correção do caso `9 → 36` terrenos, piso Commander `≥ 33`,
  aplicação parcial, recálculo e desfazer;
- UI: Legal, Home e estado vazio de decks responsivos;
- Battle/IA: erros públicos sanitizados, 401/403 não repetíveis, 429 com
  orientação de espera limitada, carga e contratos de replay;
- XMage candidato: patch Lorehold reprodutível, sem alterar o pin oficial.

## Provas concluídas

### Gate agregado

`./scripts/quality_gate.sh full` passou com Node 24:

- backend determinístico completo;
- análise Flutter sem findings;
- 1.378 testes Flutter aprovados e 1 skip declarado;
- Web público: lint, tipos, build de produção e smoke HTTP;
- auditoria npm: 0 vulnerabilidades;
- harnesses de performance: 17 testes Python e contratos Battle/IA aprovados.

### E2E local

`./scripts/quality_gate.sh e2e` passou no perfil
`deterministic-read-only`. Foram aprovados:

- Patrol local;
- Web público;
- Deckbuilder e contratos de UI;
- retenção, comercial e trocas;
- logs e observabilidade;
- rotas de IA, Deckbuilder e Battle;
- fundação de dados, classificadores de ramp e prompt eval;
- gate canônico Battle;
- retenção de relatórios.

O resumo integral ficou em
`/tmp/manaloom_e2e_suite_reports/manaloom_e2e_suite_20260729T183606Z/summary.md`.
Os passos mutantes/live foram corretamente marcados como opcionais e não
executados.

### Android físico

No Samsung SM-A135M, Android 14, foram aprovados três níveis de evidência para
as jornadas controladas de coleção, deck Commander e otimização:

- `PASS_AUTOMATED`;
- `PASS_RUNTIME`;
- `PASS_VISUAL_REVIEWED`.

São 12 checkpoints 1080×2408, todos abertos e inspecionados. A relação de
hashes e a análise visual estão em
`docs/qa/MANALOOM_CORE_PRODUCT_RUNTIME_UI_EVIDENCE_2026-07-29.md`.

Essa prova usa providers controlados. Ela comprova a UI real no aparelho, mas
não é apresentada como persistência real em API/PostgreSQL.

### Flutter Web real

O app autenticado foi recompilado em modo release com:

- `API_BASE_URL=http://127.0.0.1:8088/api`;
- `ENABLE_INTERACTIVE_BATTLE=true`;
- base `/app/`;
- recursos locais, sem CDN.

Login, cadastro, Termos e Política foram abertos no build real. O agrupamento
do consentimento permanece dentro do formulário, sem a quebra visual
reportada, e o console do navegador ficou sem erros ou avisos.

A porta 8088 serve o artefato estático e não possui backend ativo:
`/api/health` retorna 404. Portanto, esta prova não atribui crédito de API ao
servidor estático. O runner `integration_test` do Flutter não oferece execução
em dispositivo Web; a validação Web foi feita no build release real e a mesma
jornada de integração passou no host e no Android físico.

### PostgreSQL descartável e performance

O gate de schema criou e removeu seu próprio PostgreSQL exclusivamente
loopback:

- 79 tabelas;
- 6 views;
- 98 foreign keys;
- 56 migrations;
- 24 jobs concorrentes;
- criação p95: 195 ms;
- listagem p95: 35 ms;
- PostgreSQL p95: 35 ms;
- batch p95: 8 ms;
- cancelamento p95: 52 ms;
- agregado: 202 ms;
- 0 jobs ativos após limpeza.

Nenhuma conexão externa ou escrita live foi realizada.

### Battle e Lorehold

O gate canônico Battle passou 46/46 verificações. O verificador Lorehold
reconstruiu o candidato a partir do pin oficial
`2c43ec8cdb5cd475d47e6b555a4077151f476a3b`:

- 34/34 módulos compilados;
- 6/6 testes focados;
- patch SHA-256
  `ef492f2d3993a2918ceb88db715373be4ae1bcead74dfbb01c161eaaee6b1812`;
- nenhum avanço de pin ou escrita PostgreSQL.

O candidato local continua não implantável até o patch ser publicado em um
fork governado e a SHA publicada passar pelo contrato de transição.

## Pendências reais de release

1. Executar cadastro, coleção, deck, otimização e Battle contra backend
   autenticado e PostgreSQL com os dois tokens textuais canônicos de aprovação
   exigidos pelo contrato do repositório.
2. Publicar os sidecars e provar API, migrations, preflight e sessão interativa
   na mesma SHA.
3. Recapturar toda a matriz P0 Web mobile/desktop/wide e Android. O
   `quality_gate.sh ui-proof` falha corretamente porque o agregado
   `docs/qa/ui-live/latest.json` ainda pertence ao digest anterior.
4. Fazer as verificações humanas separadas de teclado Web real e TalkBack.
5. Repetir carga, telemetria, alertas e smoke pós-deploy no ambiente alvo.

Esses itens são limites de ambiente e autorização, não falhas escondidas dos
testes locais concluídos.
