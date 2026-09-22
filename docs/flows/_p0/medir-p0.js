export const meta = {
  name: 'medir-p0-core-brewtact',
  description: 'Mede, contra o código real, quanto falta de cada P0 CORE que bloqueia a beta do BrewTact, com verificação adversarial das estimativas otimistas',
  phases: [
    { title: 'Medir', detail: 'um agente por grupo: decompõe o aceite em asserções e confere cada uma no código' },
    { title: 'Contestar', detail: 'cético ataca as asserções dadas como prontas' },
    { title: 'Consolidar', detail: 'caminho crítico, ordem e o que realmente falta' },
  ],
}

const ROOT = '/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia'
const OUT = '/private/tmp/claude-501/-Users-desenvolvimentomobile-Documents-rafa-mtg-mtgia/206df247-c871-4d22-a00a-7b04debb95d5/scratchpad/p0'

const RULES = `
REGRAS DURAS
- Repo em ${ROOT}. SOMENTE LEITURA no repo: não edite, não crie, não apague nada dentro dele; não rode git add/commit/checkout.
- NÃO rode flutter, dart test, builds, emulador nem servidores: outras sessões usam a máquina e o digest de UI está congelado. Use Read, Grep, Glob, e comandos de leitura baratos (git log, git grep, wc, sed -n, python3 para ler JSON).
- Escreva APENAS em ${OUT} (fora do repo). Português do Brasil.
- Toda afirmação sobre o código leva arquivo:linha. "Parece implementado" não vale: ou você aponta onde está, ou declara NAO_ENCONTRADO.

O QUE VOCÊ ESTÁ MEDINDO
O BrewTact tem 49 tarefas P0 CORE abertas que bloqueiam a beta controlada. O dono quer saber QUANTO FALTA de verdade — não uma estimativa de tempo, mas o que existe e o que não existe.
Fonte do aceite: docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md (tabelas por épico; cada linha tem ID, prioridade, estado, descrição, dependências e critério de aceite). O registry gerado é docs/generated/TASK_REGISTRY.json (campos: id, priority, status, delivery, depends_on, acceptance, section, source_line — use source_line para achar a linha no backlog). Quase nenhuma tarefa tem ficha própria em docs/execution/tasks/.
Contexto de estado: docs/status/CURRENT_PRODUCT_DECISION.md (matriz de escopo, capabilities todas OFF), docs/MAPA_OPERACIONAL_DO_PROJETO.md, docs/MANALOOM_E2E_RELEASE_CONTRACT.md (critério de conclusão).
ATENÇÃO ao eixo triplo que este projeto separa de propósito: IMPLEMENTADO (o código existe) ≠ PROVADO (há teste/receipt que exercita) ≠ ABERTO (a capability deixa alcançar). Uma tarefa pode estar 100% implementada e 0% provada. Meça os três.

MÉTODO POR TAREFA
1. Leia o critério de aceite no backlog (use source_line) e DECOMPONHA em asserções verificáveis — cada frase do aceite costuma esconder 2 a 5 asserções independentes.
2. Para CADA asserção, procure no código e classifique:
   - PRONTO_E_PROVADO: existe (arquivo:linha) e há teste que o exercita (arquivo do teste:linha). Diga o que o teste realmente afirma — abra o teste, não confie no nome.
   - PRONTO_SEM_PROVA: existe no código, nenhum teste exercita.
   - PARCIAL: existe algo, mas não satisfaz o aceite. Diga o que falta.
   - NAO_ENCONTRADO: nada no código atende.
3. Estime o trabalho restante em unidades CONCRETAS, nunca em dias: quantos arquivos precisam ser tocados, quantos testes escritos, se exige migração de banco, se exige decisão humana (de produto, jurídica ou de custo), se exige serviço externo, se exige prova viva (captura/receipt).
4. Diga se a dependência DECLARADA no registry é real: às vezes a tarefa já pode andar; às vezes depende de algo não declarado que você descobriu lendo o código.
5. Aponte sobreposição: duas tarefas que o mesmo trabalho resolve, ou tarefa que já foi resolvida de fato por outro commit e ninguém atualizou o estado.
`

const ASSERCAO = { type: 'object', properties: {
  asercao: { type: 'string' },
  estado: { type: 'string', enum: ['PRONTO_E_PROVADO', 'PRONTO_SEM_PROVA', 'PARCIAL', 'NAO_ENCONTRADO'] },
  ondeEsta: { type: 'string', description: 'arquivo:linha, ou vazio se NAO_ENCONTRADO' },
  teste: { type: 'string', description: 'arquivo:linha do teste e o que ele afirma de verdade; vazio se não há' },
  oQueFalta: { type: 'string' } },
  required: ['asercao', 'estado', 'oQueFalta'] }

const TAREFA = { type: 'object', properties: {
  id: { type: 'string' },
  statusDeclarado: { type: 'string' },
  statusMedido: { type: 'string', enum: ['ja-atendida', 'quase-la', 'metade', 'mal-comecada', 'nao-comecada'] },
  assercoes: { type: 'array', items: ASSERCAO },
  arquivosATocar: { type: 'integer' },
  testesAEscrever: { type: 'integer' },
  exigeMigracao: { type: 'boolean' },
  exigeDecisaoHumana: { type: 'string', description: 'qual decisão, ou vazio' },
  exigeServicoExterno: { type: 'string' },
  exigeProvaViva: { type: 'boolean' },
  dependenciaDeclaradaEhReal: { type: 'string' },
  sobreposicaoComOutraTarefa: { type: 'string' },
  resumo: { type: 'string', description: 'uma frase: o que realmente falta' } },
  required: ['id', 'statusMedido', 'assercoes', 'arquivosATocar', 'testesAEscrever', 'exigeMigracao', 'exigeProvaViva', 'resumo'] }

const MEDIDA_SCHEMA = { type: 'object', properties: {
  grupo: { type: 'string' },
  docPath: { type: 'string' },
  tarefas: { type: 'array', items: TAREFA },
  achadosTransversais: { type: 'array', items: { type: 'string' }, description: 'coisas que valem para o grupo todo' },
  resumo: { type: 'string' } },
  required: ['grupo', 'docPath', 'tarefas', 'resumo'] }

const VERIFY_SCHEMA = { type: 'object', properties: {
  grupo: { type: 'string' },
  assercoesReexaminadas: { type: 'integer' },
  rebaixadas: { type: 'array', items: { type: 'object', properties: {
    tarefa: { type: 'string' }, asercao: { type: 'string' },
    de: { type: 'string' }, para: { type: 'string' }, porque: { type: 'string' } },
    required: ['tarefa', 'asercao', 'de', 'para', 'porque'] } },
  promovidas: { type: 'array', items: { type: 'object', properties: {
    tarefa: { type: 'string' }, asercao: { type: 'string' }, porque: { type: 'string' } },
    required: ['tarefa', 'asercao', 'porque'] } },
  statusMedidoRevisado: { type: 'array', items: { type: 'object', properties: {
    tarefa: { type: 'string' }, de: { type: 'string' }, para: { type: 'string' } },
    required: ['tarefa', 'de', 'para'] } },
  otimismo: { type: 'string', enum: ['otimista-demais', 'justo', 'pessimista-demais'] },
  resumo: { type: 'string' } },
  required: ['grupo', 'assercoesReexaminadas', 'rebaixadas', 'promovidas', 'otimismo', 'resumo'] }

const GRUPOS = [
  { key: 'auth-conta', nome: 'Autenticação, conta e aceite legal',
    ids: ['BT-AUTH-001', 'BT-AUTH-002', 'BT-AUTH-003', 'BT-AUTH-004', 'BT-AUTH-006', 'BT-LEGAL-ACCEPT-001'],
    onde: 'server/routes/auth/*, server/lib/auth_service.dart, rate_limit_middleware.dart, verified_email_middleware.dart, app/lib/features/auth, app/lib/core/security; migrações em server/bin/migrate.dart e server/database_setup.sql' },
  { key: 'privacidade-telemetria', nome: 'Privacidade, exportação/exclusão, KPI e observabilidade',
    ids: ['BT-PRIV-001', 'BT-PRIV-002', 'BT-KPI-001', 'BT-OBS-001'],
    onde: 'server/lib (serviços de export/delete de conta), server/routes/users, app/lib/core/services/activation_funnel_service.dart, app/lib/core/observability, server/lib/observability.dart, server/bin/manaloom_ops_daemon.py' },
  { key: 'deck-core', nome: 'Núcleo do deck: concorrência, revisão, preview/commit, exclusão e isolamento de sessão',
    ids: ['DCK-P0-00', 'DCK-P0-01', 'DCK-P0-02', 'DCK-P0-03', 'DCK-P0-04', 'DCK-P0-06', 'DCK-P0-07', 'DCK-P1-04'],
    onde: 'server/routes/decks/**, server/lib (serviços de deck, validação, revisão), app/lib/features/decks/providers/deck_provider*.dart, app/lib/core/api' },
  { key: 'ux-telas', nome: 'UX das telas de deck: imagem de carta, densidade, troca pareada, acessibilidade e prova visual',
    ids: ['BT-UX-IMG-001', 'BT-UX-FIX-001', 'BT-UX-SWAP-001', 'BT-UX-A11Y-001', 'BT-UX-PROOF-001'],
    onde: 'app/lib/core/widgets/card_artwork.dart e cached_card_image.dart, app/lib/features/decks/widgets, app/test/ui/**, app/tool/ui_runtime_evidence.dart, docs/qa/ui-live/current. IMPORTANTE: existe uma auditoria visual recente em docs/design/visual-audit-2026-09-21/README.md e uma spec de kit em docs/design/ui-kit-spec.md — leia as duas e diga o que delas já resolve parte destes aceites' },
  { key: 'catalogo-arte', nome: 'Catálogo read-only, contenção de upstream e arte de carta',
    ids: ['BT-CAT-01', 'BT-CAT-02', 'BT-CAT-03', 'BT-ART-01'],
    onde: 'server/routes/cards/**, server/routes/sets, server/routes/rules, server/lib/endpoint_cache.dart, server/lib/scryfall*, app/lib/features/cards, app/lib/core/widgets/card_artwork.dart' },
  { key: 'banco', nome: 'Banco: inventário de schema, migração segura e contenção de DDL',
    ids: ['BT-DB-001', 'BT-DB-002', 'BT-DB-003', 'BT-DB-004'],
    onde: 'server/bin/migrate.dart, server/bin/update_schema.dart, server/database_setup.sql, server/lib (acesso a Pool), scripts que rodam DDL, server/test/*schema*' },
  { key: 'contencao-escopo', nome: 'Contenção de escopo: manifesto de capabilities, oferta, rotas órfãs, social/trade/scanner fechados',
    ids: ['BT-SCP-001', 'BT-OFFER-001', 'BT-AI-029', 'SCOPE-P0-SOC-00', 'SCOPE-P0-TRD-00', 'BT-SCN-00'],
    onde: 'server/lib/release_capability_policy.dart, server/config/release_capabilities.json, server/routes/_middleware.dart, app/lib/core/config/release_capabilities.dart, app/lib/main.dart (guard de rota), web-public/, server/routes/ai/{recommendations,weakness-analysis,simulate-matchup,simulate}' },
  { key: 'infra-release', nome: 'Capacidade, disaster recovery e identidade de release',
    ids: ['BT-CAP-001', 'BT-CAP-002', 'BT-DR-001', 'BT-REL-001', 'BT-REL-002', 'BT-REL-003'],
    onde: 'scripts/manaloom_deploy*, scripts de release e rollback, server/routes/health/**, server/routes/ready, server/lib (release identity), app/lib/core/config (digest embutido), server/bin/manaloom_ops_daemon.py' },
  { key: 'gates-qa-web', nome: 'Gates de qualidade, QA de aceite, decisão de rollout e web pública',
    ids: ['BT-GATE-001', 'BT-GATE-002', 'BT-GATE-003', 'BT-QA-001', 'BT-DEC-001', 'BT-WEB-001'],
    onde: 'scripts/quality_gate.sh, scripts/manaloom_local_ci.sh, scripts/manaloom_project_logic.sh, .githooks, scripts/manaloom_public_web_surface_contract_test.sh, web-public/, docs/qa/execution/**' },
]

const ONLY = (args && args.only) || null
const SEL = ONLY ? GRUPOS.filter(g => ONLY.includes(g.key)) : GRUPOS
const FINAL = !!(args && args.final)

const JA_ESCRITO = (args && args.jaEscrito) || []
const medirPrompt = g => `Você é um engenheiro sênior medindo, contra o código real, quanto falta de um grupo de tarefas P0 CORE do BrewTact.
${RULES}
GRUPO: ${g.nome}
TAREFAS: ${g.ids.join(', ')}
ONDE OLHAR: ${g.onde}
${JA_ESCRITO.includes(g.key) ? `
ATENÇÃO — TRABALHO ANTERIOR EXISTE: uma execução anterior deste mesmo grupo foi interrompida DEPOIS de escrever ${OUT}/${g.key}.md, mas ANTES de devolver o resultado estruturado. Leia esse arquivo primeiro. Se ele cobre todas as ${g.ids.length} tarefas com asserções e estados, NÃO refaça a medição: confira por amostragem 3 asserções PRONTO_E_PROVADO abrindo os testes citados, complete o que estiver faltando, atualize o HEAD no cabeçalho, e devolva o estruturado a partir do que está escrito. Só refaça do zero uma tarefa cujo trecho estiver incompleto ou sem arquivo:linha.` : ''}

Para CADA uma das ${g.ids.length} tarefas, siga o método. Comece lendo a linha dela no backlog (docs/generated/TASK_REGISTRY.json dá o source_line; o texto completo está em docs/BREWTACT_MASTER_EXECUTION_BACKLOG_2026-08-12.md).
Seja cético com o estado declarado: TODO pode estar quase pronto, e IMPLEMENTED_LOCAL_PENDING_FULL_GATE pode ter buracos. Meça o código, não o rótulo.
Escreva o detalhamento em ${OUT}/${g.key}.md — uma seção por tarefa, com a tabela de asserções (asserção | estado | onde está | teste | o que falta) e o parágrafo "o que realmente falta". No topo, uma tabela-resumo do grupo.
Depois devolva o resultado estruturado.`

const verifyPrompt = (m, g) => `Você é um revisor cético. Outro engenheiro mediu quanto falta das tarefas P0 CORE do grupo "${g.nome}" (${g.ids.join(', ')}) do BrewTact. Estimativa otimista aqui custa caro: o dono vai planejar em cima disso.
${RULES}
DOCUMENTO DELE: ${m.docPath} (você PODE editar este arquivo — e só ele — para corrigir)
MEDIÇÃO (JSON): ${JSON.stringify(m)}

ATAQUE, nesta ordem:
1. TODA asserção marcada PRONTO_E_PROVADO: abra o teste citado e confirme que ele exercita mesmo a asserção. Teste que só verifica string, ou que afirma menos do que a asserção diz, NÃO prova — rebaixe para PRONTO_SEM_PROVA e diga o que o teste realmente cobre.
2. TODA asserção PRONTO_SEM_PROVA: abra o arquivo:linha e confirme que o código faz o que ele diz. Procure a guarda que falta, o caminho de erro não tratado, o caso que escapa. Se não satisfaz o aceite inteiro, rebaixe para PARCIAL.
3. Toda tarefa cujo statusMedido é 'ja-atendida' ou 'quase-la': tente derrubar. É o tipo de conclusão que faz um plano inteiro derrapar.
4. Seja justo nos dois sentidos: se ele foi duro demais e algo está de fato pronto, promova e diga por quê.
5. Reveja arquivosATocar e testesAEscrever: números baixos demais para o que o aceite exige?
Corrija o documento no lugar e acrescente ao final uma seção "Verificação adversarial" com o que caiu, o que subiu e o veredito de otimismo.
Devolva o estruturado.`

phase('Medir')
log(`medindo: ${SEL.map(g => g.key).join(', ')}`)
const res = await pipeline(
  SEL,
  g => agent(medirPrompt(g), { label: 'medir:' + g.key, phase: 'Medir', schema: MEDIDA_SCHEMA }),
  (m, g) => m
    ? agent(verifyPrompt(m, g), { label: 'contestar:' + g.key, phase: 'Contestar', schema: VERIFY_SCHEMA }).then(v => ({ key: g.key, nome: g.nome, ids: g.ids, medida: m, verify: v }))
    : null
)
const ok = res.filter(Boolean)
const falhas = SEL.filter(g => !ok.find(r => r.key === g.key)).map(g => g.key)
log(`${ok.length}/${SEL.length} grupos medidos` + (falhas.length ? ` — FALHARAM: ${falhas.join(', ')}` : ''))

const quadro = ok.flatMap(r => r.medida.tarefas.map(t => {
  const rev = r.verify && r.verify.statusMedidoRevisado.find(x => x.tarefa === t.id)
  return { id: t.id, grupo: r.key, status: rev ? rev.para : t.statusMedido,
    arquivos: t.arquivosATocar, testes: t.testesAEscrever, migracao: t.exigeMigracao,
    decisaoHumana: t.exigeDecisaoHumana || '', provaViva: t.exigeProvaViva,
    naoEncontrado: t.assercoes.filter(a => a.estado === 'NAO_ENCONTRADO').length,
    parcial: t.assercoes.filter(a => a.estado === 'PARCIAL').length,
    semProva: t.assercoes.filter(a => a.estado === 'PRONTO_SEM_PROVA').length,
    provado: t.assercoes.filter(a => a.estado === 'PRONTO_E_PROVADO').length }
}))

if (!FINAL) return { lote: SEL.map(g => g.key), quadro, falhas, otimismo: ok.map(r => ({ grupo: r.key, veredito: r.verify && r.verify.otimismo })) }

phase('Consolidar')
const consolidado = await agent(`Você vai responder, com número e evidência, à pergunta do dono do BrewTact: "quanto realmente falta para fechar o app?".
${RULES}
As medições por grupo estão em ${OUT}/*.md (use Glob; foram escritas em lotes). Os grupos previstos eram: ${GRUPOS.map(g => g.key).join(', ')}.
Quadro já calculado do último lote: ${JSON.stringify(quadro)}
Para os lotes anteriores, extraia os números lendo as tabelas-resumo no topo de cada .md.

O alvo NÃO é release público: é a beta controlada gratuita (docs/status/CURRENT_PRODUCT_DECISION.md — CONTROLLED_FREE_BETA, coorte pequena, Web e Android, iOS fora de escopo). O que bloqueia a beta core são as P0 CORE abertas: as 49 medidas por agente e mais 6 registradas no backlog em 2026-09-22 que NÃO foram medidas por agente — BT-CI-001 (feito, receipt pendente), BT-UIEV-001 (22/23 packs; bloqueia o gate amplo), BT-WEB-003 (bump do npm audit, autorizado; bloqueia o gate amplo), BT-DOC-006 (feito na árvore), BT-GATE-007 (gate passar a rodar app/integration_test/), BT-UX-KIT-001 (kit visual; próximo NOW, packet em docs/design/execution/BT-UX-KIT-001-proposto.md). Leia as linhas delas no backlog e situe-as no caminho crítico. Atenção: BT-SCP-001 (NOW) agora declara depender de BT-UIEV-001 e BT-WEB-003 — a dependência inversa que existia foi corrigida. As demais P0 (AI, BATTLE, SOCIAL, TRADE, SCANNER, LIFE, LEARNING, GENERATE, COMMERCIAL) bloqueiam apenas a própria capability e podem ficar OFF sem travar a beta — confirme essa leitura na tabela de prioridade do backlog (seção 5.1) e diga se ela se sustenta.

ESCREVA ${OUT}/README.md com:
1. A resposta direta em números: quantas asserções ao todo, quantas em cada estado, quantas tarefas em cada statusMedido.
2. Tabela por tarefa: id, status medido, asserções por estado, arquivos a tocar, testes a escrever, migração, decisão humana, prova viva.
3. O CAMINHO CRÍTICO real: o grafo de dependências efetivas (não o declarado — use o que os medidores descobriram), qual é a corrente mais longa, e o que pode andar em paralelo. Diga qual tarefa destrava mais coisas.
4. O que é decisão humana e não trabalho de código — lista separada, porque isso não se resolve programando.
5. Tarefas que já estão atendidas de fato e só precisam de receipt, e tarefas cujo estado declarado está errado.
6. Sobreposições: trabalho que uma tarefa resolve para outra.
7. O que NÃO foi medido e por quê.
8. Uma seção final "Se fosse para começar amanhã": a ordem das 5 primeiras tarefas, com a razão de cada uma.
NÃO invente prazo em dias ou semanas — o dono não pediu isso e você não tem base para estimar velocidade. Fale em trabalho concreto.
Devolva o estruturado.`,
  { label: 'consolidar:quanto-falta', phase: 'Consolidar', schema: { type: 'object', properties: {
    docPath: { type: 'string' },
    totalAssercoes: { type: 'integer' },
    porEstado: { type: 'object', properties: {
      provado: { type: 'integer' }, semProva: { type: 'integer' }, parcial: { type: 'integer' }, naoEncontrado: { type: 'integer' } },
      required: ['provado', 'semProva', 'parcial', 'naoEncontrado'] },
    tarefasPorStatus: { type: 'object', properties: {
      jaAtendida: { type: 'integer' }, quaseLa: { type: 'integer' }, metade: { type: 'integer' },
      malComecada: { type: 'integer' }, naoComecada: { type: 'integer' } },
      required: ['jaAtendida', 'quaseLa', 'metade', 'malComecada', 'naoComecada'] },
    correnteMaisLonga: { type: 'array', items: { type: 'string' } },
    tarefaQueDestravaMais: { type: 'string' },
    decisoesHumanas: { type: 'array', items: { type: 'string' } },
    soPrecisamReceipt: { type: 'array', items: { type: 'string' } },
    estadoDeclaradoErrado: { type: 'array', items: { type: 'string' } },
    primeirasCinco: { type: 'array', items: { type: 'object', properties: {
      id: { type: 'string' }, porque: { type: 'string' } }, required: ['id', 'porque'] } },
    resumo: { type: 'string' } },
    required: ['docPath', 'totalAssercoes', 'porEstado', 'tarefasPorStatus', 'correnteMaisLonga', 'tarefaQueDestravaMais', 'decisoesHumanas', 'primeirasCinco', 'resumo'] } })

return { quadro, falhas, consolidado }
