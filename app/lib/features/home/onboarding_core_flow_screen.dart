import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';

import '../../core/services/activation_funnel_service.dart';
import '../../core/theme/app_theme.dart';
import 'services/onboarding_state_store.dart';

class OnboardingCoreFlowScreen extends StatefulWidget {
  const OnboardingCoreFlowScreen({
    super.key,
    required this.userId,
    this.stateRepository,
    this.eventTracker,
    this.initialStorageWarning = false,
    this.onSettled,
  });

  final String userId;
  final OnboardingStateRepository? stateRepository;
  final ActivationEventTracker? eventTracker;
  final bool initialStorageWarning;
  final VoidCallback? onSettled;

  @override
  State<OnboardingCoreFlowScreen> createState() =>
      _OnboardingCoreFlowScreenState();
}

class _OnboardingCoreFlowScreenState extends State<OnboardingCoreFlowScreen> {
  static const _formats = <String>[
    'commander',
    'standard',
    'modern',
    'pioneer',
    'legacy',
    'vintage',
    'pauper',
  ];

  late final OnboardingStateRepository _stateRepository;
  late final ActivationEventTracker _eventTracker;
  Future<void> _selectionWrites = Future<void>.value();
  String _selectedFormat = 'commander';
  OnboardingGoal? _selectedGoal;
  OnboardingExperience? _experience;
  OnboardingBuildMode _buildMode = OnboardingBuildMode.guided;
  OnboardingDisposition _disposition = OnboardingDisposition.pending;
  bool _resumedProgress = false;
  bool _loading = true;
  bool _working = false;
  String? _persistenceError;

  @override
  void initState() {
    super.initState();
    _stateRepository = widget.stateRepository ?? OnboardingStateStore();
    _eventTracker = widget.eventTracker ?? ActivationFunnelService.instance;
    if (widget.initialStorageWarning) {
      _persistenceError =
          'Não foi possível confirmar seu progresso salvo. '
          'Tente novamente antes de continuar.';
    }
    unawaited(_loadState());
  }

  Future<void> _loadState() async {
    if (widget.userId.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _persistenceError =
            'Sua sessão não identificou o usuário. Entre novamente para continuar.';
      });
      return;
    }

    if (mounted) setState(() => _loading = true);
    try {
      final state = await _stateRepository.load(widget.userId);
      if (!mounted) return;
      setState(() {
        _selectedFormat = state.selectedFormat;
        _selectedGoal = state.selectedGoal;
        _experience = state.experience;
        _buildMode = state.buildMode;
        _disposition = state.disposition;
        _resumedProgress =
            state.selectedGoal != null ||
            state.experience != null ||
            state.selectedFormat != 'commander' ||
            state.buildMode != OnboardingBuildMode.guided ||
            state.disposition != OnboardingDisposition.pending;
        _persistenceError = null;
        _loading = false;
      });
      unawaited(
        _eventTracker.trackOnce(
          _eventKey('started'),
          'core_flow_started',
          format: _selectedFormat,
          source: 'onboarding',
          metadata: {
            if (_selectedGoal != null) 'goal': _selectedGoal!.name,
            if (_experience != null) 'experience': _experience!.name,
          },
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _persistenceError =
            'Não foi possível ler o progresso neste dispositivo. '
            'Nada foi marcado como concluído.';
      });
    }
  }

  void _selectGoal(OnboardingGoal goal) {
    if (_selectedGoal == goal || _loading || _working) return;
    setState(() => _selectedGoal = goal);
    _queueProgressWrite(
      eventSuffix: 'goal:${goal.name}',
      eventName: 'onboarding_goal_selected',
    );
  }

  void _selectExperience(OnboardingExperience experience) {
    if (_experience == experience || _loading || _working) return;
    setState(() => _experience = experience);
    _queueProgressWrite(
      eventSuffix: 'experience:${experience.name}',
      eventName: 'onboarding_experience_selected',
    );
  }

  void _selectBuildMode(OnboardingBuildMode mode) {
    if (_buildMode == mode || _loading || _working) return;
    setState(() => _buildMode = mode);
    _queueProgressWrite(
      eventSuffix: 'build_mode:${mode.name}',
      eventName: 'onboarding_build_mode_selected',
    );
  }

  void _selectFormat(String? value) {
    if (value == null || value == _selectedFormat || _loading || _working) {
      return;
    }
    setState(() => _selectedFormat = value);
    _queueProgressWrite(
      eventSuffix: 'format:$value',
      eventName: 'format_selected',
    );
  }

  void _queueProgressWrite({
    required String eventSuffix,
    required String eventName,
  }) {
    final format = _selectedFormat;
    final goal = _selectedGoal;
    final experience = _experience;
    final buildMode = _buildMode;
    _selectionWrites = _selectionWrites.then((_) async {
      try {
        await _stateRepository.saveProgress(
          widget.userId,
          selectedFormat: format,
          selectedGoal: goal,
          experience: experience,
          buildMode: buildMode,
        );
        if (!mounted ||
            _selectedFormat != format ||
            _selectedGoal != goal ||
            _experience != experience ||
            _buildMode != buildMode) {
          return;
        }
        setState(() => _persistenceError = null);
        unawaited(
          _eventTracker.trackOnce(
            _eventKey(eventSuffix),
            eventName,
            format: format,
            source: 'onboarding',
            metadata: {
              if (goal != null) 'goal': goal.name,
              if (experience != null) 'experience': experience.name,
              'build_mode': buildMode.name,
            },
          ),
        );
      } catch (_) {
        if (!mounted ||
            _selectedFormat != format ||
            _selectedGoal != goal ||
            _experience != experience ||
            _buildMode != buildMode) {
          return;
        }
        setState(() {
          _persistenceError =
              'Não foi possível salvar esta escolha. '
              'Tente novamente antes de sair da tela.';
        });
      }
    });
  }

  Future<void> _startTask() async {
    final goal = _selectedGoal;
    final experience = _experience;
    if (goal == null || experience == null || _working) return;
    setState(() {
      _working = true;
      _persistenceError = null;
    });
    try {
      await _selectionWrites;
      await _stateRepository.saveProgress(
        widget.userId,
        selectedFormat: _selectedFormat,
        selectedGoal: goal,
        experience: experience,
        buildMode: _buildMode,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _persistenceError =
            'Não foi possível salvar seu plano. '
            'A navegação foi pausada para evitar perder a escolha.';
      });
      return;
    }

    unawaited(
      _eventTracker.trackOnce(
        _eventKey('task:${goal.name}:${_buildMode.name}'),
        'onboarding_task_started',
        format: _selectedFormat,
        source: 'onboarding',
        metadata: {
          'goal': goal.name,
          'experience': experience.name,
          'build_mode': _buildMode.name,
        },
      ),
    );
    if (!mounted) return;
    context.go(_taskRoute(goal));
  }

  String _taskRoute(OnboardingGoal goal) {
    final continuesOnboarding = _disposition == OnboardingDisposition.pending
        ? 'onboarding'
        : null;
    Uri route(String path, [Map<String, String?> parameters = const {}]) {
      return Uri(
        path: path,
        queryParameters: {
          ...parameters,
          if (continuesOnboarding != null) 'from': continuesOnboarding,
        }..removeWhere((_, value) => value == null || value.isEmpty),
      );
    }

    return switch (goal) {
      OnboardingGoal.catalogCollection => route('/collection/import', const {
        'list_type': 'have',
      }).toString(),
      OnboardingGoal.buildDeck when _buildMode == OnboardingBuildMode.manual =>
        route('/decks', {'create': '1', 'format': _selectedFormat}).toString(),
      OnboardingGoal.buildDeck => route('/decks/generate', {
        'format': _selectedFormat,
      }).toString(),
      OnboardingGoal.importDeck => route('/decks/import', {
        'format': _selectedFormat,
      }).toString(),
      OnboardingGoal.play || OnboardingGoal.improveDeck => '/home',
    };
  }

  Future<void> _settle(OnboardingDisposition disposition) async {
    if (_working) return;
    setState(() {
      _working = true;
      _persistenceError = null;
    });
    try {
      await _selectionWrites;
      await _stateRepository.settle(
        widget.userId,
        selectedFormat: _selectedFormat,
        disposition: disposition,
        selectedGoal: _selectedGoal,
        experience: _experience,
        buildMode: _buildMode,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _persistenceError =
            'Não foi possível confirmar essa escolha. '
            'O onboarding continua pendente e você pode tentar novamente.';
      });
      return;
    }

    _disposition = disposition;
    widget.onSettled?.call();
    final skipped = disposition == OnboardingDisposition.skipped;
    unawaited(
      _eventTracker.trackOnce(
        _eventKey(skipped ? 'skipped' : 'completed'),
        skipped ? 'onboarding_skipped' : 'onboarding_completed',
        format: _selectedFormat,
        source: 'onboarding',
        metadata: {
          'disposition': disposition.name,
          if (_selectedGoal != null) 'goal': _selectedGoal!.name,
          if (_experience != null) 'experience': _experience!.name,
        },
      ),
    );
    if (!mounted) return;
    context.go('/home');
  }

  String _eventKey(String suffix) =>
      'onboarding:v${OnboardingStateStore.currentVersion}:${widget.userId}:$suffix';

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final canStart =
        !_loading && !_working && _selectedGoal != null && _experience != null;
    return Scaffold(
      key: const Key('onboarding-intent-screen'),
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: const Text(
          'Seu primeiro passo',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.backgroundAbyss,
        surfaceTintColor: AppTheme.transparent,
        actions: const [ShellAppBarActions()],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final wide = viewport.maxWidth >= 900;
            return ListView(
              key: const Key('onboarding-scroll-view'),
              padding: EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space12,
                AppTheme.space16,
                MediaQuery.paddingOf(context).bottom + AppTheme.space24,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _OnboardingHero(
                          returning:
                              _selectedGoal != null ||
                              _experience != null ||
                              _disposition != OnboardingDisposition.pending,
                          resumed: _resumedProgress,
                          selectedGoal: _selectedGoal,
                        ),
                        if (_loading) ...[
                          const SizedBox(height: AppTheme.space12),
                          Semantics(
                            liveRegion: true,
                            label: 'Carregando progresso do onboarding',
                            child: const LinearProgressIndicator(
                              key: Key('onboarding-loading-progress'),
                            ),
                          ),
                        ],
                        if (_persistenceError != null) ...[
                          const SizedBox(height: AppTheme.space12),
                          _PersistenceNotice(
                            message: _persistenceError!,
                            retry: _loading ? null : _loadState,
                          ),
                        ],
                        const SizedBox(height: AppTheme.space16),
                        _JourneyProgress(
                          hasGoal: _selectedGoal != null,
                          hasContext: _experience != null,
                        ),
                        const SizedBox(height: AppTheme.space14),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 390,
                                child: _GoalRail(
                                  selectedGoal: _selectedGoal,
                                  enabled: !_loading && !_working,
                                  onSelected: _selectGoal,
                                ),
                              ),
                              const SizedBox(width: AppTheme.space18),
                              Expanded(
                                child: _JourneyComposer(
                                  selectedGoal: _selectedGoal,
                                  experience: _experience,
                                  selectedFormat: _selectedFormat,
                                  buildMode: _buildMode,
                                  enabled: !_loading && !_working,
                                  canStart: canStart,
                                  working: _working,
                                  disableAnimations: disableAnimations,
                                  onExperienceSelected: _selectExperience,
                                  onFormatSelected: _selectFormat,
                                  onBuildModeSelected: _selectBuildMode,
                                  onStart: _startTask,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _GoalRail(
                            selectedGoal: _selectedGoal,
                            enabled: !_loading && !_working,
                            onSelected: _selectGoal,
                          ),
                          const SizedBox(height: AppTheme.space14),
                          _JourneyComposer(
                            selectedGoal: _selectedGoal,
                            experience: _experience,
                            selectedFormat: _selectedFormat,
                            buildMode: _buildMode,
                            enabled: !_loading && !_working,
                            canStart: canStart,
                            working: _working,
                            disableAnimations: disableAnimations,
                            onExperienceSelected: _selectExperience,
                            onFormatSelected: _selectFormat,
                            onBuildModeSelected: _selectBuildMode,
                            onStart: _startTask,
                          ),
                        ],
                        if (_disposition == OnboardingDisposition.pending) ...[
                          const SizedBox(height: AppTheme.space10),
                          TextButton(
                            key: const Key('onboarding-skip-action'),
                            onPressed: _loading || _working
                                ? null
                                : () => _settle(OnboardingDisposition.skipped),
                            style: TextButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                AppTheme.touchTargetMin,
                              ),
                            ),
                            child: const Text(
                              'Pular por enquanto — seu objetivo continua salvo',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    required this.returning,
    required this.resumed,
    required this.selectedGoal,
  });

  final bool returning;
  final bool resumed;
  final OnboardingGoal? selectedGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      key: const Key('onboarding-intent-hero'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.42)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: compact ? -55 : -120,
            bottom: compact ? -55 : -120,
            right: compact ? -180 : -70,
            width: compact ? 470 : 760,
            child: Opacity(
              opacity: compact ? 0.48 : 0.62,
              child: Image.asset(
                'assets/branding/home_hero.png',
                key: const Key('onboarding-intent-artwork'),
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
              ),
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
                    AppTheme.backgroundAbyss.withValues(alpha: 0.97),
                    AppTheme.backgroundAbyss.withValues(alpha: 0.55),
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space20,
              AppTheme.space18,
              AppTheme.space20,
              AppTheme.space20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 150),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 300 : 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resumed
                            ? 'PLANO RETOMADO'
                            : returning
                            ? 'AJUSTE SUA ROTA'
                            : 'COMECE PELO SEU JOGO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.brass400,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        resumed
                            ? 'Continue de onde você parou.'
                            : returning
                            ? 'Qual é sua próxima jogada?'
                            : 'O que você quer fazer primeiro?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontFamily: AppTheme.displayFontFamily,
                          fontWeight: FontWeight.w900,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        selectedGoal == null
                            ? 'Escolha um objetivo. O ManaLoom prepara somente o caminho necessário.'
                            : _goalCopy(selectedGoal!).heroConfirmation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({required this.hasGoal, required this.hasContext});

  final bool hasGoal;
  final bool hasContext;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Progresso do onboarding: ${hasGoal ? 'objetivo escolhido' : 'objetivo pendente'}, ${hasContext ? 'contexto escolhido' : 'contexto pendente'}',
      child: Row(
        key: const Key('onboarding-journey-progress'),
        children: [
          _ProgressSegment(label: '1 · Objetivo', complete: hasGoal),
          const SizedBox(width: AppTheme.space8),
          _ProgressSegment(label: '2 · Contexto', complete: hasContext),
          const SizedBox(width: AppTheme.space8),
          _ProgressSegment(label: '3 · Ação', complete: hasGoal && hasContext),
        ],
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: complete ? AppTheme.textPrimary : AppTheme.textHint,
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3,
            decoration: BoxDecoration(
              color: complete ? AppTheme.brass400 : AppTheme.outlineMuted,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRail extends StatelessWidget {
  const _GoalRail({
    required this.selectedGoal,
    required this.enabled,
    required this.onSelected,
  });

  final OnboardingGoal? selectedGoal;
  final bool enabled;
  final ValueChanged<OnboardingGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('onboarding-goal-rail'),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space14,
              AppTheme.space16,
              AppTheme.space10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 · Escolha seu objetivo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                Text(
                  'Você pode mudar depois. Agora escolha o que precisa resolver.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          for (final goal in _goalOrder) ...[
            Divider(
              height: 1,
              color: AppTheme.outlineMuted.withValues(alpha: 0.7),
            ),
            _GoalRow(
              goal: goal,
              selected: selectedGoal == goal,
              enabled: enabled,
              onTap: () => onSelected(goal),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final OnboardingGoal goal;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = _goalCopy(goal);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${copy.title}. ${copy.description}',
      child: Material(
        color: selected
            ? AppTheme.brass400.withValues(alpha: 0.09)
            : AppTheme.transparent,
        child: InkWell(
          key: Key('onboarding-goal-${goal.name}'),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space14,
              vertical: AppTheme.space12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.brass400
                        : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: selected
                          ? AppTheme.brass400
                          : AppTheme.outlineMuted,
                    ),
                  ),
                  child: Icon(
                    copy.icon,
                    color: selected
                        ? AppTheme.backgroundAbyss
                        : AppTheme.textSecondary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space3),
                      Text(
                        copy.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? AppTheme.brass400 : AppTheme.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyComposer extends StatelessWidget {
  const _JourneyComposer({
    required this.selectedGoal,
    required this.experience,
    required this.selectedFormat,
    required this.buildMode,
    required this.enabled,
    required this.canStart,
    required this.working,
    required this.disableAnimations,
    required this.onExperienceSelected,
    required this.onFormatSelected,
    required this.onBuildModeSelected,
    required this.onStart,
  });

  final OnboardingGoal? selectedGoal;
  final OnboardingExperience? experience;
  final String selectedFormat;
  final OnboardingBuildMode buildMode;
  final bool enabled;
  final bool canStart;
  final bool working;
  final bool disableAnimations;
  final ValueChanged<OnboardingExperience> onExperienceSelected;
  final ValueChanged<String?> onFormatSelected;
  final ValueChanged<OnboardingBuildMode> onBuildModeSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);
    return Container(
      key: const Key('onboarding-context-panel'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2 · Conte sobre seu momento',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Isso muda a orientação, não as regras do formato.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            key: const Key('onboarding-experience-options'),
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              for (final option in OnboardingExperience.values)
                ChoiceChip(
                  key: Key('onboarding-experience-${option.name}'),
                  label: Text(_experienceLabel(option)),
                  selected: experience == option,
                  onSelected: enabled
                      ? (_) => onExperienceSelected(option)
                      : null,
                  showCheckmark: true,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space14),
          DropdownButtonFormField<String>(
            key: const Key('onboarding-format-dropdown'),
            initialValue: selectedFormat,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Formato principal',
              helperText:
                  'Usaremos isso para preparar decks, listas e sugestões.',
              helperMaxLines: 2,
            ),
            items: _OnboardingCoreFlowScreenState._formats
                .map(
                  (format) => DropdownMenuItem(
                    value: format,
                    child: Text(
                      format[0].toUpperCase() + format.substring(1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled ? onFormatSelected : null,
          ),
          const SizedBox(height: AppTheme.space16),
          Divider(color: AppTheme.outlineMuted.withValues(alpha: 0.75)),
          const SizedBox(height: AppTheme.space12),
          AnimatedSwitcher(
            duration: duration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
            child: selectedGoal == null
                ? const _NoGoalSelected(key: ValueKey('no-goal'))
                : _GoalTask(
                    key: ValueKey(selectedGoal),
                    goal: selectedGoal!,
                    buildMode: buildMode,
                    enabled: enabled,
                    canStart: canStart,
                    working: working,
                    onBuildModeSelected: onBuildModeSelected,
                    onStart: onStart,
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoGoalSelected extends StatelessWidget {
  const _NoGoalSelected({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const Icon(Icons.route_outlined, color: AppTheme.frost400, size: 28),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Text(
              'Escolha um objetivo para ver uma única próxima ação.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTask extends StatelessWidget {
  const _GoalTask({
    super.key,
    required this.goal,
    required this.buildMode,
    required this.enabled,
    required this.canStart,
    required this.working,
    required this.onBuildModeSelected,
    required this.onStart,
  });

  final OnboardingGoal goal;
  final OnboardingBuildMode buildMode;
  final bool enabled;
  final bool canStart;
  final bool working;
  final ValueChanged<OnboardingBuildMode> onBuildModeSelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = _goalCopy(goal);
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3 · ${copy.actionTitle}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTheme.space5),
          Text(
            copy.actionDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          if (goal == OnboardingGoal.buildDeck) ...[
            const SizedBox(height: AppTheme.space14),
            _BuildModeSelector(
              selected: buildMode,
              enabled: enabled,
              onSelected: onBuildModeSelected,
            ),
            const SizedBox(height: AppTheme.space10),
            Text(
              buildMode == OnboardingBuildMode.guided
                  ? 'A IA prepara uma base para você revisar. Nada é aplicado sem sua confirmação.'
                  : 'Você começa com nome, formato e comandante e adiciona cada carta no seu ritmo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.space16),
          SizedBox(
            width: double.infinity,
            child: KeyedSubtree(
              key: const Key('onboarding-primary-action'),
              child: FilledButton.icon(
                key: _legacyActionKey(goal, buildMode),
                onPressed: canStart ? onStart : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    AppTheme.touchTargetMin + 2,
                  ),
                  backgroundColor: AppTheme.brass400,
                  foregroundColor: AppTheme.backgroundAbyss,
                ),
                icon: working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.backgroundAbyss,
                        ),
                      )
                    : Icon(copy.actionIcon),
                label: Text(
                  working
                      ? 'Salvando seu plano…'
                      : _actionLabel(goal, buildMode),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (!canStart && !working) ...[
            const SizedBox(height: AppTheme.space8),
            const Text(
              'Escolha também seu momento de experiência para continuar.',
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: AppTheme.fontXs,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuildModeSelector extends StatelessWidget {
  const _BuildModeSelector({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final OnboardingBuildMode selected;
  final bool enabled;
  final ValueChanged<OnboardingBuildMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 520;
        final options = [
          _BuildModeTile(
            key: const Key('onboarding-build-guided'),
            title: 'Gerar uma base',
            subtitle: 'Mais rápido · revisão antes de salvar',
            icon: Icons.auto_awesome_rounded,
            selected: selected == OnboardingBuildMode.guided,
            enabled: enabled,
            onTap: () => onSelected(OnboardingBuildMode.guided),
          ),
          _BuildModeTile(
            key: const Key('onboarding-build-manual'),
            title: 'Criar do zero',
            subtitle: 'Controle carta por carta',
            icon: Icons.edit_note_rounded,
            selected: selected == OnboardingBuildMode.manual,
            enabled: enabled,
            onTap: () => onSelected(OnboardingBuildMode.manual),
          ),
        ];
        if (stack) {
          return Column(
            children: [
              options.first,
              const SizedBox(height: AppTheme.space8),
              options.last,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: options.first),
            const SizedBox(width: AppTheme.space8),
            Expanded(child: options.last),
          ],
        );
      },
    );
  }
}

class _BuildModeTile extends StatelessWidget {
  const _BuildModeTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppTheme.brass400.withValues(alpha: 0.1)
            : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selected ? AppTheme.brass400 : AppTheme.outlineMuted,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppTheme.brass400 : AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppTheme.brass400 : AppTheme.textHint,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersistenceNotice extends StatelessWidget {
  const _PersistenceNotice({required this.message, required this.retry});

  final String message;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: Container(
        key: const Key('onboarding-persistence-error'),
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: theme.colorScheme.error),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sync_problem,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: AppTheme.space10),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (retry != null)
              TextButton(
                key: const Key('onboarding-persistence-retry'),
                onPressed: retry,
                child: const Text('Tentar novamente'),
              ),
          ],
        ),
      ),
    );
  }
}

const _goalOrder = <OnboardingGoal>[
  OnboardingGoal.buildDeck,
  OnboardingGoal.importDeck,
  OnboardingGoal.catalogCollection,
  OnboardingGoal.play,
  OnboardingGoal.improveDeck,
];

({
  String title,
  String description,
  String heroConfirmation,
  String actionTitle,
  String actionDescription,
  IconData icon,
  IconData actionIcon,
})
_goalCopy(OnboardingGoal goal) {
  return switch (goal) {
    OnboardingGoal.buildDeck => (
      title: 'Montar um deck',
      description: 'Comece do zero ou gere uma base para revisar.',
      heroConfirmation: 'Vamos transformar uma ideia em uma lista jogável.',
      actionTitle: 'Escolha como começar',
      actionDescription:
          'Criar do zero dá controle total. Gerar uma base acelera o primeiro rascunho.',
      icon: Icons.style_outlined,
      actionIcon: Icons.auto_awesome_rounded,
    ),
    OnboardingGoal.importDeck => (
      title: 'Importar uma lista',
      description: 'Traga um deck de texto ou de outro site.',
      heroConfirmation: 'Sua lista será revisada antes de criar qualquer deck.',
      actionTitle: 'Prepare sua lista',
      actionDescription:
          'Cole a lista, confira cartas reconhecidas e resolva pendências antes de salvar.',
      icon: Icons.content_paste_go_outlined,
      actionIcon: Icons.fact_check_outlined,
    ),
    OnboardingGoal.catalogCollection => (
      title: 'Catalogar minha coleção',
      description: 'Registre cópias, impressão e estado físico.',
      heroConfirmation:
          'Vamos montar uma fila segura para revisar suas cópias.',
      actionTitle: 'Traga suas cartas',
      actionDescription:
          'Importe uma lista em lote e confirme impressão, idioma, acabamento e condição.',
      icon: Icons.inventory_2_outlined,
      actionIcon: Icons.playlist_add_check_circle_outlined,
    ),
    OnboardingGoal.play => (
      title: 'Jogar uma partida',
      description: 'Abra uma mesa com ou sem deck vinculado.',
      heroConfirmation:
          'A Home vai preparar uma única entrada para a sua mesa.',
      actionTitle: 'Prepare a mesa',
      actionDescription:
          'Na Home você escolhe um deck revisado ou declara um modo rápido sem deck.',
      icon: Icons.sports_esports_outlined,
      actionIcon: Icons.play_arrow_rounded,
    ),
    OnboardingGoal.improveDeck => (
      title: 'Melhorar um deck',
      description: 'Escolha uma lista e revise mudanças com contexto.',
      heroConfirmation:
          'Vamos partir de um deck real e manter você no controle.',
      actionTitle: 'Escolha o deck certo',
      actionDescription:
          'A Home prioriza seu deck recente e abre a Oficina com preview, fontes e undo.',
      icon: Icons.tune_rounded,
      actionIcon: Icons.trending_up_rounded,
    ),
  };
}

String _experienceLabel(OnboardingExperience experience) {
  return switch (experience) {
    OnboardingExperience.firstSteps => 'Começando agora',
    OnboardingExperience.returning => 'Voltando ao Magic',
    OnboardingExperience.experienced => 'Jogo com frequência',
  };
}

String _actionLabel(OnboardingGoal goal, OnboardingBuildMode buildMode) {
  return switch (goal) {
    OnboardingGoal.buildDeck when buildMode == OnboardingBuildMode.manual =>
      'Criar deck do zero',
    OnboardingGoal.buildDeck => 'Gerar uma base para revisar',
    OnboardingGoal.importDeck => 'Revisar minha lista',
    OnboardingGoal.catalogCollection => 'Importar minha coleção',
    OnboardingGoal.play => 'Continuar para a mesa',
    OnboardingGoal.improveDeck => 'Escolher deck para melhorar',
  };
}

Key _legacyActionKey(OnboardingGoal goal, OnboardingBuildMode buildMode) {
  if (goal == OnboardingGoal.buildDeck &&
      buildMode == OnboardingBuildMode.guided) {
    return const Key('onboarding-generate-action');
  }
  if (goal == OnboardingGoal.importDeck) {
    return const Key('onboarding-import-action');
  }
  return const Key('onboarding-complete-action');
}
