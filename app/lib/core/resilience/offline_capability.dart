enum OfflineCapability {
  offlineSupported('offline_supported'),
  cachedReadOnly('cached_read_only'),
  onlineRequired('online_required');

  const OfflineCapability(this.wireName);

  final String wireName;
}

enum OfflineInputPreservation { none, inMemory, durable }

enum OfflineProductFlow {
  authentication,
  cardCatalog,
  collection,
  binderMutation,
  marketplace,
  deckRead,
  deckGenerateImport,
  deckEdit,
  deckOptimize,
  battle,
  lifeCounter,
  postGameNotes,
  directMessages,
  trades,
  community,
  notifications,
  profileSettings,
  onboarding,
  genericOnlineAction,
}

class OfflineFlowContract {
  const OfflineFlowContract({
    required this.flow,
    required this.key,
    required this.capability,
    required this.mutable,
    required this.serverBacked,
    required this.queuesRemoteMutations,
    required this.reconcilesAutomatically,
    required this.inputPreservation,
    required this.cachePolicy,
    required this.queuePolicy,
    required this.retryPolicy,
    required this.conflictPolicy,
    required this.reconciliationPolicy,
    required this.implementation,
  });

  final OfflineProductFlow flow;
  final String key;
  final OfflineCapability capability;
  final bool mutable;
  final bool serverBacked;
  final bool queuesRemoteMutations;
  final bool reconcilesAutomatically;
  final OfflineInputPreservation inputPreservation;
  final String cachePolicy;
  final String queuePolicy;
  final String retryPolicy;
  final String conflictPolicy;
  final String reconciliationPolicy;
  final String implementation;

  String get disconnectedMessage {
    if (capability == OfflineCapability.cachedReadOnly) {
      return 'Sem conexão com o servidor. Os dados já carregados continuam '
          'disponíveis; reconecte para atualizar.';
    }
    if (capability == OfflineCapability.offlineSupported) {
      if (serverBacked) {
        return 'Sem conexão com o servidor. A alteração ficou salva neste '
            'aparelho e será sincronizada ao reconectar.';
      }
      return 'Este recurso continua disponível sem conexão.';
    }
    return switch (inputPreservation) {
      OfflineInputPreservation.durable =>
        'Sem conexão com o servidor. Seu rascunho continua salvo neste '
            'aparelho; reconecte e tente novamente.',
      OfflineInputPreservation.inMemory =>
        'Sem conexão com o servidor. Seus dados continuam nesta tela; '
            'reconecte e tente novamente.',
      OfflineInputPreservation.none =>
        'Sem conexão com o servidor. Reconecte e tente novamente.',
    };
  }
}

const offlineFlowContracts = <OfflineFlowContract>[
  OfflineFlowContract(
    flow: OfflineProductFlow.authentication,
    key: 'authentication',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy: 'Token seguro restaura somente uma sessão já validada.',
    queuePolicy: 'Login, cadastro e recuperação nunca entram em fila.',
    retryPolicy: 'Retry manual com formulário mantido na tela.',
    conflictPolicy: '401 encerra a sessão e limpa dados privados.',
    reconciliationPolicy: 'Nova autenticação consulta o backend canônico.',
    implementation: 'AuthProvider + AuthTokenStore',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.cardCatalog,
    key: 'card_catalog',
    capability: OfflineCapability.onlineRequired,
    mutable: false,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy: 'Arte já decodificada pode permanecer no cache de imagens.',
    queuePolicy: 'Busca e resolução de cartas não entram em fila.',
    retryPolicy: 'Retry manual preserva consulta e filtros.',
    conflictPolicy:
        'Resultado novo substitui somente a consulta correspondente.',
    reconciliationPolicy: 'Nova busca lê PostgreSQL via API.',
    implementation: 'CardProvider + SetsCatalogScreen + SetCardsScreen',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.collection,
    key: 'collection',
    capability: OfflineCapability.cachedReadOnly,
    mutable: false,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.none,
    cachePolicy:
        'Listas carregadas permanecem visíveis durante falha de página.',
    queuePolicy: 'Leitura não cria fila.',
    retryPolicy: 'Retry de página/refresh mantém o snapshot visível.',
    conflictPolicy: 'Resposta obsoleta não substitui geração mais nova.',
    reconciliationPolicy: 'Refresh explícito recompõe a lista do backend.',
    implementation: 'BinderProvider + BinderScreen',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.binderMutation,
    key: 'binder_mutation',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy: 'Snapshot carregado permanece visível.',
    queuePolicy: 'Alterações do fichário não entram em fila offline.',
    retryPolicy: 'Retry manual mantém os campos do diálogo.',
    conflictPolicy: '409/423 exige recarregar disponibilidade e ownership.',
    reconciliationPolicy: 'Sucesso ou conflito força nova leitura canônica.',
    implementation: 'BinderProvider mutation methods',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.marketplace,
    key: 'marketplace',
    capability: OfflineCapability.cachedReadOnly,
    mutable: false,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy:
        'Resultados já carregados permanecem durante falha de refresh.',
    queuePolicy: 'Busca de mercado não cria fila.',
    retryPolicy: 'Retry manual preserva filtros.',
    conflictPolicy: 'Preço e disponibilidade são revalidados antes da ação.',
    reconciliationPolicy: 'Refresh lê o backend canônico.',
    implementation: 'BinderProvider marketplace state',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.deckRead,
    key: 'deck_read',
    capability: OfflineCapability.cachedReadOnly,
    mutable: false,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.none,
    cachePolicy:
        'Deck já carregado permanece no provider durante erro transitório.',
    queuePolicy: 'Leitura de deck não cria fila.',
    retryPolicy: 'Retry manual preserva o snapshot atual.',
    conflictPolicy: 'Versão recebida só substitui o deck solicitado.',
    reconciliationPolicy: 'Refresh lê deck e versão do PostgreSQL.',
    implementation: 'DeckProvider fetch/details state',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.deckGenerateImport,
    key: 'deck_generate_import',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.durable,
    cachePolicy: 'Formulário, job ativo e chave idempotente ficam no aparelho.',
    queuePolicy:
        'O rascunho é local; geração/importação não é enviada offline.',
    retryPolicy: 'Retry reutiliza job/request key sem duplicar deck.',
    conflictPolicy: 'Resposta do job é vinculada ao owner e request key.',
    reconciliationPolicy:
        'Retomada consulta o job no backend antes de reenviar.',
    implementation: 'DeckEntryDraftStore + DeckGenerateScreen',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.deckEdit,
    key: 'deck_edit',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy:
        'Descrição pendente é persistida por usuário/deck; os demais '
        'editores permanecem abertos durante falha.',
    queuePolicy: 'Salvar deck não entra em fila offline.',
    retryPolicy: 'Retry manual mantém a edição atual.',
    conflictPolicy: 'Versão/ownership é validada pelo backend.',
    reconciliationPolicy: 'Após salvar, o provider recarrega o deck canônico.',
    implementation: 'DeckEntryDraftStore + DeckProvider mutation support',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.deckOptimize,
    key: 'deck_optimize',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy: 'Sugestão atual permanece visível até nova solicitação.',
    queuePolicy: 'Optimize/apply não entra em fila offline.',
    retryPolicy: 'Job usa timeout, cancelamento e chave idempotente.',
    conflictPolicy: 'Apply valida versão e registra histórico/rollback.',
    reconciliationPolicy: 'Status do job e deck aplicado vêm do backend.',
    implementation: 'DeckProvider AI support + optimization history',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.battle,
    key: 'battle',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy: 'Resultado já recebido permanece visível.',
    queuePolicy: 'Nova simulação não entra em fila offline.',
    retryPolicy: 'Retry explícito usa seed/request id governado.',
    conflictPolicy: 'Replay é imutável e autorizado por owner.',
    reconciliationPolicy: 'Simulação e replay persistidos vêm do backend.',
    implementation: 'Battle routes + battle_simulations',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.lifeCounter,
    key: 'life_counter',
    capability: OfflineCapability.offlineSupported,
    mutable: true,
    serverBacked: false,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.durable,
    cachePolicy: 'Sessão ativa é persistida localmente.',
    queuePolicy: 'Não há mutação remota para enfileirar.',
    retryPolicy: 'Reabertura restaura a sessão local.',
    conflictPolicy: 'Uma mesa local possui um único estado no aparelho.',
    reconciliationPolicy: 'Não se aplica; o fluxo é local por contrato.',
    implementation: 'LifeCounterSessionStore',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.postGameNotes,
    key: 'post_game_notes',
    capability: OfflineCapability.offlineSupported,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: true,
    reconcilesAutomatically: true,
    inputPreservation: OfflineInputPreservation.durable,
    cachePolicy: 'Notas e identidade do deck ficam persistidas localmente.',
    queuePolicy: 'Upserts e tombstones ficam em filas por deck.',
    retryPolicy: 'Load/reconexão descarrega operações pendentes em ordem.',
    conflictPolicy: 'ID imutável, tombstone e cursor evitam ressurreição.',
    reconciliationPolicy:
        'Merge por ID preserva pendências e aplica exclusões.',
    implementation: 'PostGameNoteStore',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.directMessages,
    key: 'direct_messages',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.durable,
    cachePolicy: 'Texto e client_request_id ficam salvos por conversa.',
    queuePolicy: 'Rascunho não é fila de envio.',
    retryPolicy: 'Retry manual reutiliza request id enquanto o texto não muda.',
    conflictPolicy: 'Unicidade por remetente/request id impede duplicação.',
    reconciliationPolicy: 'Sucesso limpa o rascunho e atualiza a conversa.',
    implementation: 'MessageDraftStore + MessageProvider',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.trades,
    key: 'trades',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy:
        'Lista/detalhe carregados permanecem durante falha transitória.',
    queuePolicy: 'Transição de trade nunca entra em fila offline.',
    retryPolicy: 'Retry manual preserva proposta/mensagem atual.',
    conflictPolicy: 'Máquina de estados e locks rejeitam versão indisponível.',
    reconciliationPolicy: 'Cada transição bem-sucedida recarrega o trade.',
    implementation: 'TradeProvider + TradeService',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.community,
    key: 'community',
    capability: OfflineCapability.cachedReadOnly,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy: 'Feed já carregado permanece visível.',
    queuePolicy: 'Follow, comentário, denúncia e bloqueio não entram em fila.',
    retryPolicy: 'Retry manual mantém texto enquanto a tela está aberta.',
    conflictPolicy: 'Backend reaplica bloqueios, visibilidade e moderação.',
    reconciliationPolicy: 'Refresh recompõe o feed autorizado.',
    implementation: 'CommunityProvider + SocialProvider',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.notifications,
    key: 'notifications',
    capability: OfflineCapability.cachedReadOnly,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.none,
    cachePolicy: 'Notificações já carregadas permanecem no provider.',
    queuePolicy: 'Leitura/ack não entra em fila offline.',
    retryPolicy: 'Polling retoma após sessão e lifecycle ativos.',
    conflictPolicy: 'IDs do backend tornam atualização idempotente.',
    reconciliationPolicy: 'Polling/refresh recompõe unread e itens.',
    implementation: 'NotificationProvider + RealtimeNotificationCoordinator',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.profileSettings,
    key: 'profile_settings',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy: 'Perfil autenticado atual permanece em memória.',
    queuePolicy: 'Privacidade e segurança não entram em fila offline.',
    retryPolicy: 'Retry manual mantém valores na tela.',
    conflictPolicy: 'Auth version e ownership são validados no servidor.',
    reconciliationPolicy: 'Sucesso substitui token/usuário de forma atômica.',
    implementation: 'AuthProvider profile/security mutations',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.onboarding,
    key: 'onboarding',
    capability: OfflineCapability.offlineSupported,
    mutable: true,
    serverBacked: false,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.durable,
    cachePolicy: 'Decisão por usuário é persistida localmente.',
    queuePolicy: 'Não há mutação remota obrigatória.',
    retryPolicy: 'Retomada reabre a etapa local correta.',
    conflictPolicy: 'Estado é isolado pela identidade autenticada.',
    reconciliationPolicy: 'Não se aplica; telemetria não é fonte de verdade.',
    implementation: 'OnboardingDecisionStore + AuthProvider',
  ),
  OfflineFlowContract(
    flow: OfflineProductFlow.genericOnlineAction,
    key: 'generic_online_action',
    capability: OfflineCapability.onlineRequired,
    mutable: true,
    serverBacked: true,
    queuesRemoteMutations: false,
    reconcilesAutomatically: false,
    inputPreservation: OfflineInputPreservation.inMemory,
    cachePolicy: 'Somente o estado corrente da tela é mantido.',
    queuePolicy: 'Nenhuma fila é presumida sem contrato específico.',
    retryPolicy: 'Retry manual após reconexão.',
    conflictPolicy: 'O backend decide a versão canônica.',
    reconciliationPolicy: 'Nova leitura após sucesso ou conflito.',
    implementation: 'FriendlyErrorMapper fallback',
  ),
];

final offlineFlowContractByFlow =
    Map<OfflineProductFlow, OfflineFlowContract>.unmodifiable(
      <OfflineProductFlow, OfflineFlowContract>{
        for (final contract in offlineFlowContracts) contract.flow: contract,
      },
    );

OfflineFlowContract offlineContractFor(OfflineProductFlow flow) {
  final contract = offlineFlowContractByFlow[flow];
  if (contract == null) {
    throw StateError('Missing offline contract for ${flow.name}.');
  }
  return contract;
}
