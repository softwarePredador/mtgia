import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:provider/provider.dart';

import '../../core/branding/product_identity.dart';
import '../../core/config/release_capabilities.dart';
import '../../core/config/visual_fixture.dart';
import '../../core/services/activation_funnel_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/scryfall_image_helper.dart';
import '../../core/widgets/card_artwork.dart';
import '../../core/widgets/mana_symbols.dart';
import '../../core/widgets/manaloom_glyph.dart';
import 'life_counter_route.dart';
import 'life_counter/life_counter_session.dart';
import 'life_counter/life_counter_session_store.dart';
import 'services/onboarding_state_store.dart';
import '../decks/models/deck.dart';
import '../decks/providers/deck_provider.dart';

class HomeScreen extends StatefulWidget {
  final bool? lifeCounterAvailable;
  final String userId;
  final OnboardingStateRepository? onboardingStateRepository;
  final VoidCallback? onOnboardingSettled;

  const HomeScreen({
    super.key,
    this.lifeCounterAvailable,
    this.userId = '',
    this.onboardingStateRepository,
    this.onOnboardingSettled,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _requestedDeckBootstrap = false;
  bool _introStarted = false;
  late final AnimationController _introController;
  late final OnboardingStateRepository _onboardingStateRepository;
  OnboardingState? _onboardingState;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _onboardingStateRepository =
        widget.onboardingStateRepository ?? OnboardingStateStore();
    if (widget.userId.trim().isNotEmpty) {
      unawaited(_loadOnboardingState());
    }
  }

  Future<void> _loadOnboardingState() async {
    try {
      final state = await _onboardingStateRepository.load(widget.userId);
      if (!mounted) return;
      setState(() => _onboardingState = state);
    } catch (_) {
      // A Home continua funcional sem personalização quando o storage local
      // está indisponível. O onboarding preserva o aviso e o retry próprios.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_introStarted) {
      _introStarted = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _introController.value = 1;
      } else {
        _introController.forward();
      }
    }
    final capabilities = context.watch<ReleaseCapabilitiesProvider>();
    if (!capabilities.isAllowed(ReleaseCapability.decksPrivate)) {
      _requestedDeckBootstrap = false;
      return;
    }
    if (_requestedDeckBootstrap) return;

    _requestedDeckBootstrap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final capabilities = context.read<ReleaseCapabilitiesProvider>();
      if (!capabilities.isAllowed(ReleaseCapability.decksPrivate)) return;
      final provider = context.read<DeckProvider>();
      if (provider.decks.isEmpty && !provider.isLoading) {
        provider.fetchDecks();
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _openPlayEntry(List<Deck> decks) async {
    var capabilities = context.read<ReleaseCapabilitiesProvider>();
    if (!_lifeCounterAllowed(capabilities)) return;
    var decksAllowed = capabilities.isAllowed(ReleaseCapability.decksPrivate);
    var learningWritesAllowed = capabilities.isAllowed(
      ReleaseCapability.learningWrites,
    );
    final store = LifeCounterSessionStore();
    final storedSession = await store.load();
    if (!mounted) return;
    capabilities = context.read<ReleaseCapabilitiesProvider>();
    if (!_lifeCounterAllowed(capabilities)) return;
    decksAllowed = capabilities.isAllowed(ReleaseCapability.decksPrivate);
    learningWritesAllowed = capabilities.isAllowed(
      ReleaseCapability.learningWrites,
    );
    final activeSession =
        storedSession?.playSessionId?.trim().isNotEmpty == true
        ? storedSession
        : null;
    final selection = await showModalBottomSheet<_PlayEntrySelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) => _PlayEntrySheet(
        decks: decksAllowed ? decks : const <Deck>[],
        activeSession: activeSession,
        decksAllowed: decksAllowed,
        learningWritesAllowed: learningWritesAllowed,
      ),
    );
    if (!mounted || selection == null) return;
    capabilities = context.read<ReleaseCapabilitiesProvider>();

    switch (selection.action) {
      case _PlayEntryAction.resume:
        final session = activeSession;
        if (session != null) await _openStoredLifeCounterSession(session);
      case _PlayEntryAction.end:
        final session = activeSession;
        if (session != null) await _endStoredLifeCounterSession(session, store);
      case _PlayEntryAction.quick:
        if (!_lifeCounterAllowed(capabilities)) return;
        final startedAt = DateTime.now().millisecondsSinceEpoch;
        await store.clear();
        await store.save(
          LifeCounterSession.initial(
            playSessionId: 'play-$startedAt',
            startedAtEpochMs: startedAt,
          ),
        );
        if (mounted) await _openLifeCounterAndPauseOnReturn();
      case _PlayEntryAction.newDeck:
        if (!_lifeCounterAllowed(capabilities) ||
            !capabilities.isAllowed(ReleaseCapability.decksPrivate)) {
          return;
        }
        final deck = selection.deck;
        if (deck != null) await _startDeckLifeCounter(deck, store);
      case _PlayEntryAction.manageDecks:
        if (capabilities.isAllowed(ReleaseCapability.decksPrivate)) {
          context.go('/decks');
        }
    }
  }

  Future<void> _startDeckLifeCounter(
    Deck deck,
    LifeCounterSessionStore store,
  ) async {
    var capabilities = context.read<ReleaseCapabilitiesProvider>();
    if (!_lifeCounterAllowed(capabilities) ||
        !capabilities.isAllowed(ReleaseCapability.decksPrivate)) {
      return;
    }
    final provider = context.read<DeckProvider>();
    await provider.fetchDeckDetails(deck.id);
    if (!mounted) return;
    capabilities = context.read<ReleaseCapabilitiesProvider>();
    if (!_lifeCounterAllowed(capabilities) ||
        !capabilities.isAllowed(ReleaseCapability.decksPrivate)) {
      return;
    }
    final details = provider.selectedDeck;
    final snapshotHash = details?.deckSnapshotHash?.trim();
    final versionAt = details?.deckVersionAt;
    if (details?.id != deck.id ||
        snapshotHash == null ||
        !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(snapshotHash) ||
        versionAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível confirmar a revisão deste deck. Tente novamente ou escolha o modo rápido.',
          ),
        ),
      );
      return;
    }

    await store.clear();
    if (!mounted) return;
    await _openLifeCounterAndPauseOnReturn(
      deckId: details!.id,
      deckName: details.name,
      deckSnapshotHash: snapshotHash.toLowerCase(),
      deckVersionAtEpochMs: versionAt.millisecondsSinceEpoch,
    );
  }

  Future<void> _openStoredLifeCounterSession(LifeCounterSession session) async {
    final capabilities = context.read<ReleaseCapabilitiesProvider>();
    if (!_lifeCounterAllowed(capabilities)) return;
    final decksAllowed = capabilities.isAllowed(ReleaseCapability.decksPrivate);
    await _openLifeCounterAndPauseOnReturn(
      deckId: decksAllowed ? session.deckId : null,
      deckName: decksAllowed ? session.deckName : null,
      deckSnapshotHash: decksAllowed ? session.deckSnapshotHash : null,
      deckVersionAtEpochMs: decksAllowed ? session.deckVersionAtEpochMs : null,
    );
  }

  Future<void> _openLifeCounterAndPauseOnReturn({
    String? deckId,
    String? deckName,
    String? deckSnapshotHash,
    int? deckVersionAtEpochMs,
  }) async {
    final capabilities = context.read<ReleaseCapabilitiesProvider>();
    if (!_lifeCounterAllowed(capabilities)) return;
    final result = await openLifeCounterRoute<LifeCounterExitResult>(
      context,
      deckId: deckId,
      deckName: deckName,
      deckSnapshotHash: deckSnapshotHash,
      deckVersionAtEpochMs: deckVersionAtEpochMs,
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sessão pausada. Abra “Jogar agora” para retomar ou encerrar e registrar.',
        ),
      ),
    );
  }

  Future<void> _endStoredLifeCounterSession(
    LifeCounterSession session,
    LifeCounterSessionStore store,
  ) async {
    await store.clear();
    if (!mounted) return;
    final capabilities = context.read<ReleaseCapabilitiesProvider>();
    if (!capabilities.isAllowed(ReleaseCapability.decksPrivate)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Partida encerrada.')));
      return;
    }
    final deckId = session.deckId?.trim();
    if (deckId == null || deckId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partida rápida encerrada.')),
      );
      return;
    }
    final snapshotHash = session.deckSnapshotHash?.trim();
    final versionAt = session.deckVersionAtEpochMs;
    final hasCompleteVersion =
        snapshotHash != null &&
        RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(snapshotHash) &&
        versionAt != null;
    final uri = Uri(
      path: '/decks/$deckId/post-game',
      queryParameters: <String, String>{
        if (session.playSessionId?.trim().isNotEmpty == true)
          'playSessionId': session.playSessionId!.trim(),
        if (session.startedAtEpochMs != null)
          'startedAt': session.startedAtEpochMs.toString(),
        'endedAt': DateTime.now().millisecondsSinceEpoch.toString(),
        if (hasCompleteVersion) 'deckSnapshotHash': snapshotHash.toLowerCase(),
        if (hasCompleteVersion) 'deckVersionAt': versionAt.toString(),
      },
    );
    context.push(uri.toString());
  }

  bool _lifeCounterAllowed(ReleaseCapabilitiesProvider capabilities) {
    return (widget.lifeCounterAvailable ?? true) &&
        capabilities.isAllowed(ReleaseCapability.lifeCounterLocal);
  }

  Future<bool> _completePendingHomeIntent(OnboardingState state) async {
    final goal = state.selectedGoal;
    if (state.disposition != OnboardingDisposition.pending) return true;
    if (goal == null || widget.userId.trim().isEmpty) return false;
    try {
      await _onboardingStateRepository.settle(
        widget.userId,
        selectedFormat: state.selectedFormat,
        disposition: OnboardingDisposition.completed,
        selectedGoal: goal,
        experience: state.experience,
        buildMode: state.buildMode,
      );
      final settled = state.copyWith(
        disposition: OnboardingDisposition.completed,
        updatedAt: DateTime.now().toUtc(),
      );
      if (!mounted) return false;
      setState(() => _onboardingState = settled);
      widget.onOnboardingSettled?.call();
      unawaited(
        ActivationFunnelService.instance.trackOnce(
          'onboarding:v${OnboardingStateStore.currentVersion}:${widget.userId}:completed',
          'onboarding_completed',
          format: state.selectedFormat,
          source: 'home_intent',
          metadata: {
            'disposition': OnboardingDisposition.completed.name,
            'goal': goal.name,
            if (state.experience != null) 'experience': state.experience!.name,
          },
        ),
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar a conclusão do guia. Tente novamente antes de continuar.',
          ),
        ),
      );
      return false;
    }
  }

  Future<void> _runHomePrimaryAction(
    List<Deck> decks,
    bool lifeCounterAvailable,
  ) async {
    if (!mounted) return;
    final capabilities = context.read<ReleaseCapabilitiesProvider>();
    final decksAllowed = capabilities.isAllowed(ReleaseCapability.decksPrivate);
    final collectionAllowed = capabilities.isAllowed(
      ReleaseCapability.collectionPrivate,
    );
    final generateAllowed = capabilities.isAllowed(
      ReleaseCapability.aiGenerateRebuild,
    );
    final lifeAllowed =
        lifeCounterAvailable && _lifeCounterAllowed(capabilities);
    Future<void> runDefaultAction() async {
      if (lifeAllowed) {
        await _openPlayEntry(decksAllowed ? decks : const <Deck>[]);
      } else if (decksAllowed) {
        context.go('/decks');
      } else if (collectionAllowed) {
        context.go('/collection?tab=0');
      }
    }

    final state = _onboardingState;
    final goal = state?.selectedGoal;
    if (state == null || goal == null) {
      await runDefaultAction();
      return;
    }

    final visibleDecks = decksAllowed ? decks : const <Deck>[];
    final recentDeck = visibleDecks.isEmpty ? null : visibleDecks.first;
    final fromOnboarding = state.disposition == OnboardingDisposition.pending
        ? 'onboarding'
        : null;
    String route(String path, [Map<String, String?> parameters = const {}]) {
      return Uri(
        path: path,
        queryParameters: {
          ...parameters,
          if (fromOnboarding != null) 'from': fromOnboarding,
        }..removeWhere((_, value) => value == null || value.isEmpty),
      ).toString();
    }

    switch (goal) {
      case OnboardingGoal.buildDeck:
        if (!decksAllowed) {
          await runDefaultAction();
          return;
        }
        if (recentDeck != null && state.isSettled) {
          context.go('/decks/${recentDeck.id}');
          return;
        }
        if (state.buildMode == OnboardingBuildMode.manual || !generateAllowed) {
          context.go(
            route('/decks', {'create': '1', 'format': state.selectedFormat}),
          );
        } else {
          context.go(
            route('/decks/generate', {'format': state.selectedFormat}),
          );
        }
        return;
      case OnboardingGoal.importDeck:
        if (!decksAllowed) {
          await runDefaultAction();
          return;
        }
        if (recentDeck != null && state.isSettled) {
          context.go('/decks/${recentDeck.id}');
          return;
        }
        context.go(route('/decks/import', {'format': state.selectedFormat}));
        return;
      case OnboardingGoal.catalogCollection:
        if (!collectionAllowed) {
          await runDefaultAction();
          return;
        }
        if (state.isSettled) {
          context.go('/collection?tab=0');
          return;
        }
        context.go(route('/collection/import', const {'list_type': 'have'}));
        return;
      case OnboardingGoal.play:
        if (!lifeAllowed) {
          await runDefaultAction();
          return;
        }
        if (!await _completePendingHomeIntent(state) || !mounted) return;
        await _openPlayEntry(visibleDecks);
        return;
      case OnboardingGoal.improveDeck:
        if (!decksAllowed) {
          await runDefaultAction();
          return;
        }
        if (recentDeck == null) {
          context.go('/decks');
          return;
        }
        if (generateAllowed) {
          if (!await _completePendingHomeIntent(state) || !mounted) return;
          final refreshedCapabilities = context
              .read<ReleaseCapabilitiesProvider>();
          if (!refreshedCapabilities.isAllowed(
                ReleaseCapability.decksPrivate,
              ) ||
              !refreshedCapabilities.isAllowed(
                ReleaseCapability.aiGenerateRebuild,
              )) {
            return;
          }
          context.go('/decks/${recentDeck.id}?optimize=rebuild');
          return;
        }
        context.go('/decks/${recentDeck.id}');
        return;
    }
  }

  _HomeHeroContent _heroContent(
    List<Deck> decks, {
    required bool decksAllowed,
    required bool collectionAllowed,
    required bool generateAllowed,
    required bool analyzeOptimizeAllowed,
    required bool lifeCounterAllowed,
  }) {
    final state = _onboardingState;
    final goal = state?.selectedGoal;
    final recentDeck = decks.isEmpty ? null : decks.first;
    final fallback = _defaultHeroContent(
      decksAllowed: decksAllowed,
      collectionAllowed: collectionAllowed,
      lifeCounterAllowed: lifeCounterAllowed,
    );
    if (goal == null) return fallback;
    final completedDeck = state!.isSettled ? recentDeck : null;
    switch (goal) {
      case OnboardingGoal.buildDeck:
        if (!decksAllowed) return fallback;
        final guidedGenerationAllowed =
            state.buildMode == OnboardingBuildMode.guided && generateAllowed;
        return _HomeHeroContent(
          title: completedDeck == null
              ? 'Seu primeiro\ndeck começa aqui'
              : 'Continue\n${completedDeck.name}',
          subtitle: completedDeck == null
              ? guidedGenerationAllowed
                    ? 'Gere uma base e revise cada escolha.'
                    : 'Crie a estrutura e escolha seu comandante.'
              : 'Abra a lista e avance para o próximo ajuste.',
          actionLabel: completedDeck == null
              ? guidedGenerationAllowed
                    ? 'Continuar montagem'
                    : 'Criar deck'
              : 'Abrir deck',
        );
      case OnboardingGoal.importDeck:
        if (!decksAllowed) return fallback;
        return _HomeHeroContent(
          title: completedDeck == null
              ? 'Sua lista,\nsem surpresas'
              : 'Revise\n${completedDeck.name}',
          subtitle: completedDeck == null
              ? 'Confira cartas reconhecidas antes de criar.'
              : 'O deck importado está pronto para sua revisão.',
          actionLabel: completedDeck == null ? 'Revisar lista' : 'Abrir deck',
        );
      case OnboardingGoal.catalogCollection:
        if (!collectionAllowed) return fallback;
        return _HomeHeroContent(
          title: 'Sua coleção,\ncópia por cópia',
          subtitle: 'Organize impressão, condição e disponibilidade.',
          actionLabel: state.isSettled ? 'Abrir Fichário' : 'Importar cópias',
        );
      case OnboardingGoal.play:
        if (!lifeCounterAllowed) return fallback;
        return _HomeHeroContent(
          title: 'Sua mesa\nestá pronta',
          subtitle: decksAllowed
              ? 'Escolha um deck revisado ou jogue no modo rápido.'
              : 'Abra uma partida rápida sem vincular um deck.',
          actionLabel: 'Jogar agora',
        );
      case OnboardingGoal.improveDeck:
        if (!decksAllowed) return fallback;
        if (recentDeck == null) {
          return const _HomeHeroContent(
            title: 'Escolha um deck\npara evoluir',
            subtitle: 'Abra seus decks para escolher a próxima revisão.',
            actionLabel: 'Ver decks',
          );
        }
        if (generateAllowed) {
          return _HomeHeroContent(
            title: 'Próxima revisão:\n${recentDeck.name}',
            subtitle: 'Compare mudanças, fontes e impacto antes de aplicar.',
            actionLabel: 'Abrir Oficina',
          );
        }
        return _HomeHeroContent(
          title: 'Revise\n${recentDeck.name}',
          subtitle: analyzeOptimizeAllowed
              ? 'Abra o deck para consultar a análise disponível.'
              : 'Abra a lista para revisar suas escolhas.',
          actionLabel: 'Abrir deck',
        );
    }
  }

  _HomeHeroContent _defaultHeroContent({
    required bool decksAllowed,
    required bool collectionAllowed,
    required bool lifeCounterAllowed,
  }) {
    if (lifeCounterAllowed) {
      return const _HomeHeroContent(
        title: 'Olá,\nPlaneswalker',
        subtitle: 'Sua próxima jogada começa aqui.',
        actionLabel: 'Jogar agora',
      );
    }
    if (decksAllowed) {
      return const _HomeHeroContent(
        title: 'Seus decks,\nno seu ritmo',
        subtitle: 'Crie, importe ou revise uma lista privada.',
        actionLabel: 'Abrir decks',
      );
    }
    if (collectionAllowed) {
      return const _HomeHeroContent(
        title: 'Sua coleção,\norganizada',
        subtitle: 'Consulte seu fichário privado.',
        actionLabel: 'Abrir coleção',
      );
    }
    return const _HomeHeroContent(
      title: 'Beta em\npreparação',
      subtitle: 'Os recursos desta versão ainda não foram liberados.',
      actionLabel: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = context.watch<ReleaseCapabilitiesProvider>();
    final decksAllowed = capabilities.isAllowed(ReleaseCapability.decksPrivate);
    final collectionAllowed = capabilities.isAllowed(
      ReleaseCapability.collectionPrivate,
    );
    final generateAllowed = capabilities.isAllowed(
      ReleaseCapability.aiGenerateRebuild,
    );
    final analyzeOptimizeAllowed = capabilities.isAllowed(
      ReleaseCapability.aiAnalyzeOptimizeAdvisory,
    );
    final lifeCounterAllowed = _lifeCounterAllowed(capabilities);
    final tradesAllowed = capabilities.isAllowed(ReleaseCapability.trades);
    final communityAllowed = const {
      ReleaseCapability.galleryPublic,
      ReleaseCapability.follows,
      ReleaseCapability.userSearch,
      ReleaseCapability.marketplace,
    }.any(capabilities.isAllowed);
    if (!decksAllowed && !collectionAllowed && !lifeCounterAllowed) {
      return const Scaffold(
        backgroundColor: AppTheme.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: _BetaPreparationState(),
            ),
          ),
        ),
      );
    }
    final isDeckLoading = context.select<DeckProvider, bool>(
      (dp) => dp.isLoading,
    );
    final decks = context.select<DeckProvider, List<Deck>>(
      (dp) => dp.decks.toList(),
    );
    final deckError = context.select<DeckProvider, String?>(
      (dp) => dp.errorMessage,
    );
    final deckStatusCode = context.select<DeckProvider, int?>(
      (dp) => dp.listStatusCode,
    );
    final visibleDecks = decksAllowed ? decks : const <Deck>[];
    final recentDecks = visibleDecks.take(4).toList();
    final heroContent = _heroContent(
      visibleDecks,
      decksAllowed: decksAllowed,
      collectionAllowed: collectionAllowed,
      generateAllowed: generateAllowed,
      analyzeOptimizeAllowed: analyzeOptimizeAllowed,
      lifeCounterAllowed: lifeCounterAllowed,
    );

    return Scaffold(
      backgroundColor: AppTheme.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _introController,
            curve: Curves.easeOutCubic,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              26,
              AppTheme.space16,
              MediaQuery.of(context).padding.bottom + 96,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HomeHeader(),
                    const SizedBox(height: AppTheme.space12),
                    _HomeHero(
                      content: heroContent,
                      onAction: () => _runHomePrimaryAction(
                        visibleDecks,
                        lifeCounterAllowed,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    const _SectionHeader(label: 'Acesso rápido'),
                    const SizedBox(height: AppTheme.space10),
                    _QuickActions(
                      lifeCounterAvailable: lifeCounterAllowed,
                      decksAllowed: decksAllowed,
                      collectionAllowed: collectionAllowed,
                      generateAllowed: generateAllowed,
                      communityAllowed: communityAllowed,
                      tradesAllowed: tradesAllowed,
                      onPlay: () => _openPlayEntry(visibleDecks),
                    ),
                    if (decksAllowed) ...[
                      const SizedBox(height: AppTheme.space18),
                      _SectionHeader(
                        label: 'Decks recentes',
                        trailing: TextButton(
                          onPressed: () => context.go('/decks'),
                          child: const Text('Ver todos'),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space10),
                      if (deckStatusCode == 401)
                        const _DecksSessionExpiredState()
                      else if (recentDecks.isNotEmpty)
                        Column(
                          children: [
                            if (isDeckLoading) ...[
                              const _CachedDecksStatus(
                                isLoading: true,
                                message: 'Atualizando seus decks...',
                              ),
                              const SizedBox(height: AppTheme.space8),
                            ] else if (deckError != null) ...[
                              _CachedDecksStatus(
                                isLoading: false,
                                message: deckError,
                              ),
                              const SizedBox(height: AppTheme.space8),
                            ],
                            _RecentDecksRail(decks: recentDecks),
                          ],
                        )
                      else if (isDeckLoading)
                        const _DecksLoadingState()
                      else if (deckError != null)
                        _DecksErrorState(message: deckError)
                      else
                        const _EmptyDecksState(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BetaPreparationState extends StatelessWidget {
  const _BetaPreparationState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.construction_rounded,
            size: 44,
            color: AppTheme.brass400,
          ),
          const SizedBox(height: AppTheme.space14),
          Text(
            'Beta em preparação',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Os recursos desta versão ainda não foram liberados para uso.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlayEntryAction { resume, end, quick, newDeck, manageDecks }

class _PlayEntrySelection {
  const _PlayEntrySelection(this.action, {this.deck});

  final _PlayEntryAction action;
  final Deck? deck;
}

class _PlayEntrySheet extends StatelessWidget {
  const _PlayEntrySheet({
    required this.decks,
    required this.activeSession,
    required this.decksAllowed,
    required this.learningWritesAllowed,
  });

  final List<Deck> decks;
  final LifeCounterSession? activeSession;
  final bool decksAllowed;
  final bool learningWritesAllowed;

  void _select(BuildContext context, _PlayEntryAction action, {Deck? deck}) {
    Navigator.of(context).pop(_PlayEntrySelection(action, deck: deck));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeSession;
    final capabilities = context.watch<ReleaseCapabilitiesProvider>();
    final canUseDecks =
        decksAllowed && capabilities.isAllowed(ReleaseCapability.decksPrivate);
    final canWriteLearning =
        learningWritesAllowed &&
        capabilities.isAllowed(ReleaseCapability.learningWrites);
    final availableDecks = canUseDecks
        ? decks.take(8).toList(growable: false)
        : const <Deck>[];
    final activeHasVisibleDeck =
        canUseDecks && active?.deckId?.trim().isNotEmpty == true;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.space20,
          AppTheme.space14,
          AppTheme.space20,
          AppTheme.space20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Row(
              children: [
                const ManaLoomGlyph(
                  ManaLoomGlyphKind.lifeCounter,
                  color: AppTheme.brass400,
                  size: 28,
                ),
                const SizedBox(width: AppTheme.space10),
                Expanded(
                  child: Text(
                    'Qual partida você vai abrir?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space6),
            Text(
              canUseDecks && canWriteLearning
                  ? 'Vincule uma revisão para transformar a mesa em aprendizado, ou declare um modo rápido sem deck.'
                  : canUseDecks
                  ? 'Vincule um deck para registrar a partida, ou use o modo rápido sem deck.'
                  : 'Abra uma partida rápida sem vincular um deck.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            if (active != null) ...[
              const SizedBox(height: AppTheme.space16),
              Container(
                key: const Key('home-play-active-session'),
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space14),
                decoration: BoxDecoration(
                  color: AppTheme.brass400.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.brass400.withValues(alpha: 0.38),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SESSÃO PAUSADA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.brass400,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space5),
                    Text(
                      activeHasVisibleDeck &&
                              active.deckName?.trim().isNotEmpty == true
                          ? active.deckName!.trim()
                          : activeHasVisibleDeck
                          ? 'Deck vinculado'
                          : 'Modo rápido · sem deck',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space5),
                    Text(
                      activeHasVisibleDeck &&
                              active.deckSnapshotHash?.trim().isNotEmpty == true
                          ? 'Revisão ${active.deckSnapshotHash!.substring(0, math.min(8, active.deckSnapshotHash!.length))} preservada'
                          : 'Sessão local sem revisão vinculada.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Wrap(
                      spacing: AppTheme.space8,
                      runSpacing: AppTheme.space8,
                      children: [
                        FilledButton.icon(
                          key: const Key('home-play-resume-session'),
                          onPressed: () =>
                              _select(context, _PlayEntryAction.resume),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Retomar'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('home-play-end-session'),
                          onPressed: () =>
                              _select(context, _PlayEntryAction.end),
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(
                            activeHasVisibleDeck
                                ? 'Encerrar e registrar'
                                : 'Encerrar modo rápido',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (canUseDecks) ...[
              const SizedBox(height: AppTheme.space16),
              Text(
                'NOVA PARTIDA COM DECK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textHint,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              if (availableDecks.isEmpty)
                Container(
                  key: const Key('home-play-no-decks'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.space14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSlate,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    'Você ainda não tem um deck disponível. Pode jogar no modo rápido ou criar um deck primeiro.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    key: const Key('home-play-deck-list'),
                    shrinkWrap: true,
                    itemCount: availableDecks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.space8),
                    itemBuilder: (context, index) {
                      final deck = availableDecks[index];
                      return _PlayEntryDeckTile(
                        deck: deck,
                        onTap: () => _select(
                          context,
                          _PlayEntryAction.newDeck,
                          deck: deck,
                        ),
                      );
                    },
                  ),
                ),
            ],
            const SizedBox(height: AppTheme.space12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('home-play-quick-mode'),
                onPressed: () => _select(context, _PlayEntryAction.quick),
                icon: const Icon(Icons.bolt_outlined),
                label: const Text('Nova partida rápida · sem deck'),
              ),
            ),
            if (canUseDecks && availableDecks.isEmpty) ...[
              const SizedBox(height: AppTheme.space6),
              Center(
                child: TextButton(
                  key: const Key('home-play-manage-decks'),
                  onPressed: () =>
                      _select(context, _PlayEntryAction.manageDecks),
                  child: const Text('Criar ou importar deck'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayEntryDeckTile extends StatelessWidget {
  const _PlayEntryDeckTile({required this.deck, required this.onTap});

  final Deck deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = deck.commanderImageUrl?.trim();
    return Material(
      key: Key('home-play-deck-${deck.id}'),
      color: AppTheme.surfaceSlate,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space10),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 62,
                child: artwork == null || artwork.isEmpty
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXs,
                          ),
                        ),
                        child: const Center(
                          child: ManaLoomGlyph(
                            ManaLoomGlyphKind.deck,
                            color: AppTheme.textHint,
                            size: 22,
                          ),
                        ),
                      )
                    : CardArtwork(
                        variant: CardArtworkVariant.gallery,
                        imageUrl: artwork,
                        semanticLabel:
                            'Comandante de ${deck.name} para iniciar partida',
                        constrainAspectRatio: false,
                        showStatusBadge: false,
                      ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      '${_formatLabel(deck.format)} · revisão confirmada antes de abrir',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.brass400),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: AppTheme.space48,
      child: Row(
        children: [
          SizedBox(
            width: AppTheme.space48,
            child: IconButton(
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.account_circle_outlined),
              color: AppTheme.textSecondary,
              tooltip: 'Perfil',
            ),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ManaLoomGlyph(
                      ManaLoomGlyphKind.brand,
                      color: AppTheme.brass400,
                      size: 22,
                    ),
                    const SizedBox(width: AppTheme.space7),
                    Text(
                      ProductIdentity.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.brass400,
                        fontWeight: FontWeight.w900,
                        fontSize: AppTheme.fontXl + 4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            width: AppTheme.space112,
            child: Align(
              alignment: Alignment.centerRight,
              child: ShellAppBarActions(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeroContent {
  const _HomeHeroContent({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
}

class _HomeHero extends StatelessWidget {
  final _HomeHeroContent content;
  final VoidCallback? onAction;

  const _HomeHero({required this.content, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionLabel = content.actionLabel;
    final actionWidth = (actionLabel?.length ?? 0) > 12 ? 176.0 : 122.0;
    final wideArtwork = MediaQuery.sizeOf(context).width >= 840;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final heroHeight = textScale >= 1.5 ? 280.0 : 190.0;
    final artworkSize = wideArtwork ? 680.0 : 430.0;
    final artworkOverflow = (artworkSize - heroHeight) / 2;
    return RepaintBoundary(
      key: const Key('home-hero-frame'),
      child: Container(
        key: const Key('home-hero-surface'),
        height: heroHeight,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.backgroundAbyss,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppTheme.backgroundAbyss.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        // The frame is painted above the artwork. A border in [decoration]
        // sits behind the child and can disappear at clipped corners.
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: AppTheme.brass500.withValues(alpha: 0.5),
            width: AppTheme.strokeThin,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: wideArtwork ? -10 : -34,
              top: -artworkOverflow,
              bottom: -artworkOverflow,
              width: artworkSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/branding/home_hero.png',
                    key: const Key('home-hero-artwork'),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppTheme.backgroundAbyss,
                          AppTheme.transparent,
                        ],
                        stops: [0, 0.32],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.backgroundAbyss,
                      AppTheme.backgroundAbyss.withValues(alpha: 0.98),
                      AppTheme.backgroundAbyss.withValues(alpha: 0.7),
                      AppTheme.transparent,
                    ],
                    stops: const [0.0, 0.24, 0.5, 0.78],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 24,
              bottom: 20,
              width: 194,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: AppTheme.fontDisplay - 8,
                      height: 1.03,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space9),
                  Text(
                    content.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSm,
                      height: 1.32,
                    ),
                  ),
                  const Spacer(),
                  if (actionLabel != null && onAction != null)
                    SizedBox(
                      width: actionWidth,
                      height: AppTheme.touchTargetMin,
                      child: FilledButton(
                        key: const Key('home-primary-action'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brass400,
                          foregroundColor: AppTheme.backgroundAbyss,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space18,
                          ),
                          textStyle: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: AppTheme.fontSm,
                          ),
                        ),
                        onPressed: onAction,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(actionLabel),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            const Icon(Icons.arrow_forward_rounded, size: 17),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 2,
          height: AppTheme.iconSpinnerSm,
          decoration: BoxDecoration(
            color: AppTheme.brass500,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: AppTheme.fontXl,
              letterSpacing: 0,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final bool lifeCounterAvailable;
  final bool decksAllowed;
  final bool collectionAllowed;
  final bool generateAllowed;
  final bool communityAllowed;
  final bool tradesAllowed;
  final VoidCallback onPlay;

  const _QuickActions({
    required this.lifeCounterAvailable,
    required this.decksAllowed,
    required this.collectionAllowed,
    required this.generateAllowed,
    required this.communityAllowed,
    required this.tradesAllowed,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (lifeCounterAvailable)
        _QuickActionData(
          glyph: ManaLoomGlyphKind.lifeCounter,
          title: 'Jogar agora',
          accent: AppTheme.brass400,
          onTap: onPlay,
        )
      else if (communityAllowed)
        _QuickActionData(
          icon: Icons.groups_outlined,
          title: 'Comunidade',
          accent: AppTheme.brass400,
          onTap: () => context.go('/community'),
        ),
      if (decksAllowed)
        _QuickActionData(
          glyph: ManaLoomGlyphKind.deck,
          title: generateAllowed ? 'Construir deck' : 'Criar deck',
          accent: AppTheme.brass500,
          onTap: () =>
              context.go(generateAllowed ? '/onboarding/core-flow' : '/decks'),
        ),
      if (decksAllowed)
        _QuickActionData(
          glyph: ManaLoomGlyphKind.deck,
          title: 'Meus Decks',
          accent: AppTheme.textSecondary,
          onTap: () => context.go('/decks'),
        ),
      if (collectionAllowed)
        _QuickActionData(
          glyph: ManaLoomGlyphKind.collection,
          title: 'Coleção',
          accent: AppTheme.textSecondary,
          onTap: () => context.go('/collection'),
        ),
      if (collectionAllowed && tradesAllowed)
        _QuickActionData(
          glyph: ManaLoomGlyphKind.trade,
          title: 'Trocas',
          accent: AppTheme.brass500,
          onTap: () => context.go('/collection?tab=2'),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            key: const Key('home-quick-actions-list'),
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: AppTheme.space10),
                Expanded(child: _QuickActionCard(data: actions[index])),
              ],
            ],
          );
        }

        const gap = AppTheme.space10;
        const edgePadding = AppTheme.space4;
        final visibleItemCount = constraints.maxWidth >= 520 ? 3 : 2;
        final availableWidth =
            constraints.maxWidth -
            (edgePadding * 2) -
            (gap * (visibleItemCount - 1));
        final itemWidth = availableWidth / visibleItemCount;
        final itemStride = itemWidth + gap;

        return SizedBox(
          height: AppTheme.space72,
          child: ListView.separated(
            key: const Key('home-quick-actions-list'),
            padding: const EdgeInsets.symmetric(horizontal: edgePadding),
            scrollDirection: Axis.horizontal,
            physics: _QuickActionSnapPhysics(
              itemExtent: itemStride,
              parent: const BouncingScrollPhysics(),
            ),
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (context, index) => SizedBox(
              key: Key('home-quick-action-$index'),
              width: itemWidth,
              child: _QuickActionCard(data: actions[index]),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionSnapPhysics extends ScrollPhysics {
  const _QuickActionSnapPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  _QuickActionSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return _QuickActionSnapPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final parentSimulation = super.createBallisticSimulation(
      position,
      velocity,
    );
    final projectedPixels =
        parentSimulation?.x(double.infinity) ?? position.pixels;
    final targetPixels = (projectedPixels / itemExtent).round() * itemExtent;
    final boundedTarget = targetPixels
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    final tolerance = toleranceFor(position);
    if ((boundedTarget - position.pixels).abs() <= tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      boundedTarget,
      velocity,
      tolerance: tolerance,
    );
  }
}

class _QuickActionData {
  final ManaLoomGlyphKind? glyph;
  final IconData? icon;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionData({
    this.glyph,
    this.icon,
    required this.title,
    required this.accent,
    required this.onTap,
  }) : assert(
         (glyph == null) != (icon == null),
         'Provide exactly one of glyph or icon.',
       );
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        splashColor: data.accent.withValues(alpha: 0.08),
        highlightColor: data.accent.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.55),
              width: AppTheme.strokeHairline,
            ),
          ),
          child: Row(
            children: [
              if (data.glyph != null)
                ManaLoomGlyph(data.glyph!, color: data.accent, size: 21)
              else
                Icon(data.icon, color: data.accent, size: 21),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: AppTheme.fontSm,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDecksRail extends StatelessWidget {
  final List<Deck> decks;

  const _RecentDecksRail({required this.decks});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 144,
      child: ListView.separated(
        key: const Key('home-recent-decks-rail'),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space2,
          AppTheme.space4,
          AppTheme.space2,
          AppTheme.space12,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: decks.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppTheme.space12),
        itemBuilder: (context, index) => _RecentDeckCard(deck: decks[index]),
      ),
    );
  }
}

class _RecentDeckCard extends StatelessWidget {
  final Deck deck;

  const _RecentDeckCard({required this.deck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = _deckTarget(deck.format);
    final ratio = (deck.cardCount / target).clamp(0.0, 1.0);
    final frameColor = ratio >= 1 ? AppTheme.brass500 : AppTheme.outlineMuted;
    final age = _createdTime(deck.createdAt);
    final commanderName = deck.commanderName?.trim();

    return SizedBox(
      key: Key('home-recent-deck-${deck.id}'),
      width: 244,
      child: Material(
        color: AppTheme.surfaceSlate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(
            color: frameColor.withValues(alpha: 0.74),
            width: AppTheme.strokeThin,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/decks/${deck.id}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          splashColor: AppTheme.brass400.withValues(alpha: 0.08),
          highlightColor: AppTheme.brass400.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space8),
            child: Row(
              children: [
                ClipRRect(
                  key: Key('home-recent-deck-art-${deck.id}'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: SizedBox(
                    width: AppTheme.space72,
                    height: 102,
                    child: _DeckArtwork(deck: deck),
                  ),
                ),
                const SizedBox(width: AppTheme.space10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space0,
                      AppTheme.space3,
                      AppTheme.space3,
                      AppTheme.space2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: AppTheme.fontSm,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space3),
                        Text(
                          commanderName == null || commanderName.isEmpty
                              ? _formatLabel(deck.format)
                              : commanderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontXs,
                            height: 1.1,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatLabel(deck.format),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontXs,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _ManaPips(
                              identity: deck.colorIdentity,
                              identityKnown: deck.colorIdentityKnown,
                            ),
                            const SizedBox(width: AppTheme.space6),
                            Text(
                              '${deck.cardCount}/$target',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: AppTheme.fontXs,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value: ratio,
                            backgroundColor: AppTheme.outlineMuted,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ratio >= 1
                                  ? AppTheme.brass400
                                  : AppTheme.frost400,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space5),
                        Text(
                          age,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHint,
                            fontSize: AppTheme.fontMicro,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckArtwork extends StatelessWidget {
  final Deck deck;

  const _DeckArtwork({required this.deck});

  @override
  Widget build(BuildContext context) {
    final imageUrl = deck.commanderImageUrl?.trim();
    final commanderName = deck.commanderName?.trim();
    final fallbackImageUrl = ScryfallImageHelper.namedImageUrl(commanderName);
    if ((imageUrl != null && imageUrl.isNotEmpty) || fallbackImageUrl != null) {
      return CardArtwork(
        variant: CardArtworkVariant.recentDeck,
        imageUrl: imageUrl,
        fallbackImageUrl: fallbackImageUrl,
        semanticLabel: imageUrl == null || imageUrl.isEmpty
            ? 'Arte de referência do comandante ${commanderName ?? deck.name}'
            : 'Carta do comandante ${commanderName ?? deck.name}',
        constrainAspectRatio: false,
      );
    }
    return _DeckFallback(deck: deck);
  }
}

class _DeckFallback extends StatelessWidget {
  final Deck deck;

  const _DeckFallback({required this.deck});

  @override
  Widget build(BuildContext context) {
    final identity = deck.colorIdentity.toSet();
    final accent = AppTheme.identityColor(identity);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.34),
                AppTheme.surfaceElevated,
                AppTheme.backgroundAbyss,
              ],
            ),
          ),
        ),
        ManaLoomGlyph(
          ManaLoomGlyphKind.deck,
          color: AppTheme.textPrimary.withValues(alpha: 0.26),
          size: 34,
        ),
      ],
    );
  }
}

class _ManaPips extends StatelessWidget {
  final List<String> identity;
  final bool identityKnown;

  const _ManaPips({required this.identity, required this.identityKnown});

  @override
  Widget build(BuildContext context) {
    if (identity.isEmpty && !identityKnown) {
      return const Tooltip(
        message: 'Identidade de cor pendente',
        child: Icon(
          Icons.help_outline_rounded,
          size: 13,
          color: AppTheme.textHint,
        ),
      );
    }
    return ColorIdentityPips(
      colors: identity,
      symbolSize: 12,
      spacing: 2,
      decorated: false,
      colorlessWhenEmpty: identityKnown,
    );
  }
}

class _EmptyDecksState extends StatelessWidget {
  const _EmptyDecksState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-decks-empty-state'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space14,
        AppTheme.space14,
        AppTheme.space14,
        AppTheme.space14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.brass500.withValues(alpha: 0.34)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.brass400.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: AppTheme.brass400.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brass400.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const ManaLoomGlyph(
              ManaLoomGlyphKind.deck,
              color: AppTheme.brass400,
              size: 28,
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          Text(
            'Você ainda não tem decks',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: AppTheme.fontLg,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Crie seu primeiro deck e comece sua jornada em Magic.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/decks'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar novo deck'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecksErrorState extends StatelessWidget {
  const _DecksErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-decks-error-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.42)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.error, size: 28),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Não foi possível carregar seus decks',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.onErrorContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          OutlinedButton.icon(
            key: const Key('home-decks-retry'),
            onPressed: () => _retryDeckFetch(context),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _DecksSessionExpiredState extends StatelessWidget {
  const _DecksSessionExpiredState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-decks-session-expired-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.brass500.withValues(alpha: 0.52)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            color: AppTheme.brass400,
            size: 28,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Sua sessão expirou',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Entre novamente para recarregar seus decks com segurança.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          FilledButton.icon(
            key: const Key('home-decks-login-again'),
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_rounded),
            label: const Text('Entrar novamente'),
          ),
        ],
      ),
    );
  }
}

class _CachedDecksStatus extends StatelessWidget {
  const _CachedDecksStatus({required this.isLoading, required this.message});

  final bool isLoading;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key(
        isLoading
            ? 'home-decks-cache-refreshing-state'
            : 'home-decks-cached-read-only-state',
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: AppTheme.space18,
              height: AppTheme.space18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.cloud_off_rounded,
              size: AppTheme.space18,
              color: AppTheme.brass400,
            ),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Text(
              isLoading ? message : 'Mostrando decks salvos. $message',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          if (!isLoading)
            IconButton(
              key: const Key('home-decks-cache-retry'),
              onPressed: () => _retryDeckFetch(context),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Tentar novamente',
              color: AppTheme.brass400,
            ),
        ],
      ),
    );
  }
}

class _DecksLoadingState extends StatelessWidget {
  const _DecksLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-decks-loading-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: AppTheme.space24,
            height: AppTheme.space24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: AppTheme.space16),
          Expanded(
            child: Text(
              'Carregando seus decks...',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

void _retryDeckFetch(BuildContext context) {
  final capabilities = context.read<ReleaseCapabilitiesProvider>();
  if (!capabilities.isAllowed(ReleaseCapability.decksPrivate)) return;
  unawaited(context.read<DeckProvider>().fetchDecks());
}

int _deckTarget(String format) {
  final normalized = format.toLowerCase();
  if (normalized.contains('commander') || normalized.contains('brawl')) {
    return 100;
  }
  return 60;
}

String _formatLabel(String format) {
  final normalized = format.toLowerCase();
  if (normalized.contains('commander')) return 'Commander';
  if (normalized.contains('standard') || normalized.contains('padr')) {
    return 'Padrão';
  }
  if (normalized.isEmpty) return 'Deck';
  return format[0].toUpperCase() + format.substring(1);
}

String _createdTime(DateTime date) {
  if (manaloomVisualFixtureMode) return 'Criado agora';
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inMinutes < 1) return 'Criado agora';
  if (difference.inHours < 1) {
    return 'Criado há ${math.max(1, difference.inMinutes)}min';
  }
  if (difference.inDays < 1) return 'Criado há ${difference.inHours}h';
  return 'Criado há ${difference.inDays}d';
}
