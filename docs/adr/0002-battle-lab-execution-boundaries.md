# ADR 0002 — Limites de execução do Battle Lab, Live Spectator e Coach

- Estado: aceito
- Data: 2026-07-26
- Responsáveis: ManaLoom engineering
- Programa: `BL0–BL10`

## Contexto

O Battle atual executa uma simulação fechada por meio de
`external_battle_request_v2`, persiste o replay concluído e permite leitura
posterior. Esse contrato não representa uma sessão restaurável nem oferece um
canal seguro para ações humanas durante a partida.

Battle Lab, acompanhamento ao vivo e Coach Mode têm estados, riscos e
necessidades operacionais diferentes. Acrescentar jobs, eventos incrementais ou
comandos humanos diretamente ao envelope atual criaria compatibilidade
ambígua, poderia misturar resultados concluídos com tentativas censuradas e
aumentaria o risco de expor zonas ocultas.

## Decisão

As três superfícies permanecem contratos independentes:

1. **Battle Lab** mantém `external_battle_request_v2` como requisição fechada.
   Toda execução cria uma tentativa persistida e termina com exatamente um
   outcome versionado. Um replay continua sendo evidência imutável e não é um
   checkpoint restaurável.
2. **Live Spectator** será construído sobre `battle_job_v1` e um stream público
   sanitizado e cursorado. O transporte inicial é polling/long polling. Pausar
   o playback no cliente não pausa o engine.
3. **Coach Mode** usa `interactive_battle_session_v1`, com visão privada do
   participante separada do replay público, prompts versionados e opções
   opacas produzidas pelo engine. Ele não reutiliza o stream público como canal
   de comando.

`client_editor_network_and_adventure` continua não adotado como capacidade
global. O BL7 pode executar somente um spike XMage isolado, sem rota pública,
para decidir se callbacks humanos limitados são seguros e operáveis. BL8 só
começa após um GO explícito desse spike.

## Invariantes

- PostgreSQL/backend é a verdade do produto; Hermes/SQLite é
  cache/laboratório/auditoria.
- XMage continua sendo o executor primário. Forge permanece fallback apenas
  para gap estruturado de cobertura e isolado por processo/API.
- Timeout, cobertura incompleta, falha de engine, cancelamento, censura e falha
  de persistência são outcomes distintos; nenhum vira empate ou conclusão.
- Ausência de evento continua significando desconhecido, nunca prova de não
  uso.
- Replay, tentativa, job e sessão carregam owner, revisão/hash dos decks,
  identidade do engine, schema e política de timeout.
- O hash imutável de `battle_job_request_v1` não é reutilizado como se fosse o
  hash enviado a cada engine. Cada dispatch tem schema/hash próprios. XMage e
  Forge exigem eco validado pelo sidecar para aceitar sucesso ou gap estruturado
  de cobertura. Falha operacional sem resposta aceita fica honestamente como
  `server_dispatch_recorded`; o runtime nativo usa a mesma fonte porque ainda
  não ecoa esse contrato.
- `auto` só avança XMage → Forge → native após gap estruturado de cobertura.
  Timeout, 5xx, contrato/identidade inválida e falha de correlação terminam a
  tentativa e nunca acionam fallback operacional.
- Cancelamento é cooperativo nos limites que os sidecars suportam: antes do
  dispatch, entre fallbacks, após a resposta e antes de persistir. Não se alega
  abortar uma chamada HTTP já enviada enquanto não existir RPC de cancelamento.
- Eventos públicos têm ator/lado e `subject_deck_key`; ação exclusiva do
  oponente não valida o deck analisado.
- Mão, biblioteca, escolhas privadas e opções derivadas de zonas ocultas não
  entram em replay, log, métrica ou stream público.
- IDs de prompt/opção são opacos. Ações carregam `state_version`, são
  idempotentes e rejeitam estado obsoleto.
- “Deixar a IA decidir” só é disponibilizado quando o sidecar provar takeover
  seguro; até lá, timeout termina/concede a sessão conforme política explícita.
- Nenhuma dessas evidências promove automaticamente carta, regra, swap ou deck.

## Retenção, export e exclusão

- Tentativas, replays, anotações, jobs terminais e registros Live públicos não
  possuem TTL automático nesta versão. Eles são mantidos como evidência do
  usuário até a exclusão da conta ou uma futura política versionada.
- A exportação de dados da conta inclui essas cinco famílias. Dados internos de
  lease, request payload/fingerprint e correlação secreta não entram no
  payload exportado.
- A exclusão da conta remove anotações, jobs/Live, tentativas e replays
  owner-scoped na ordem compatível com FKs; soft-deleted decks não ampliam
  acesso.
- Somente o registro transitório do sidecar Live expira por limite operacional;
  isso não apaga a verdade já persistida no PostgreSQL.
- Introduzir TTL temporal ou compactação de replay exige migration/ADR,
  preservação de exportabilidade e prova de que não rompe learning/auditoria.

## Consequências

- Há mais schemas e estados para manter, porém cada consumidor pode falhar
  fechado e evoluir sem quebrar a simulação existente.
- O primeiro valor entregável continua sendo Battle Lab. Live Spectator e
  Coach podem permanecer desabilitados independentemente.
- Forge pode participar do replay concluído, mas Live começa XMage-only enquanto
  não houver emissão incremental confiável e sanitizada no sidecar Forge.
- Replays antigos permanecem legíveis como `legacy`; não recebem proveniência
  ou certeza retroativas.

## Rollout e rollback

- Novos contratos entram atrás de capacidade/feature flags com default
  desabilitado até os respectivos gates.
- DDL é aplicado somente por migrations e passa em cluster PostgreSQL
  descartável antes de qualquer autorização live.
- Desabilitar Live ou Coach não remove tentativas/replays existentes.
- Rollback de schema com dados requer plano manual, backup e restore validados;
  não se apagam evidências para simular compatibilidade.

## Provas obrigatórias

- `docs/MANALOOM_BATTLE_LAB_DELIVERY_PLAN.md`
- `docs/hermes-analysis/EXTERNAL_BATTLE_EXECUTION_CONTRACT.md`
- `docs/hermes-analysis/EXTERNAL_ENGINE_CAPABILITY_CONTRACT.json`
- `./scripts/quality_gate.sh battle`
- `./scripts/quality_gate.sh engine-capabilities`
- migration PostgreSQL descartável e testes negativos de hidden zones
