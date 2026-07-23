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
  OnboardingDisposition _disposition = OnboardingDisposition.pending;
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
        _disposition = state.disposition;
        _persistenceError = null;
        _loading = false;
      });
      unawaited(
        _eventTracker.trackOnce(
          _eventKey('started'),
          'core_flow_started',
          format: _selectedFormat,
          source: 'onboarding',
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

  void _selectFormat(String? value) {
    if (value == null || value == _selectedFormat) return;
    setState(() => _selectedFormat = value);
    _selectionWrites = _selectionWrites.then((_) async {
      try {
        await _stateRepository.saveProgress(
          widget.userId,
          selectedFormat: value,
        );
        if (!mounted || _selectedFormat != value) return;
        setState(() => _persistenceError = null);
        unawaited(
          _eventTracker.trackOnce(
            _eventKey('format:$value'),
            'format_selected',
            format: value,
            source: 'onboarding',
          ),
        );
      } catch (_) {
        if (!mounted || _selectedFormat != value) return;
        setState(() {
          _persistenceError =
              'Não foi possível salvar o formato. '
              'Tente novamente antes de sair desta tela.';
        });
      }
    });
  }

  Future<void> _chooseBase({required bool generate}) async {
    if (_working) return;
    setState(() {
      _working = true;
      _persistenceError = null;
    });
    try {
      await _selectionWrites;
      await _stateRepository.saveProgress(
        widget.userId,
        selectedFormat: _selectedFormat,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _persistenceError =
            'Não foi possível salvar seu progresso. '
            'A navegação foi pausada para evitar perder sua escolha.';
      });
      return;
    }

    final eventName = generate ? 'base_choice_generate' : 'base_choice_import';
    unawaited(
      _eventTracker.trackOnce(
        _eventKey(eventName),
        eventName,
        format: _selectedFormat,
        source: 'onboarding',
      ),
    );
    if (!mounted) return;
    context.go(
      generate
          ? '/decks/generate?format=$_selectedFormat&from=onboarding'
          : '/decks/import?format=$_selectedFormat&from=onboarding',
    );
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
        metadata: {'disposition': disposition.name},
      ),
    );
    if (!mounted) return;
    if (skipped) {
      context.go('/home');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Guia concluído. Abra um deck e use “Otimizar Deck” quando quiser.',
        ),
      ),
    );
    context.go('/decks');
  }

  String _eventKey(String suffix) =>
      'onboarding:v${OnboardingStateStore.currentVersion}:${widget.userId}:$suffix';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: const Text(
          'Criar e otimizar deck',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.backgroundAbyss,
        actions: const [ShellAppBarActions()],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('onboarding-scroll-view'),
          padding: const EdgeInsets.all(AppTheme.space16),
          children: [
            Text(
              _disposition == OnboardingDisposition.pending
                  ? 'Vamos preparar seu primeiro deck'
                  : 'Monte outro deck com o guia',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppTheme.space6),
            Text(
              'Seu formato e progresso ficam salvos por usuário neste '
              'dispositivo, inclusive sem conexão.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            if (_loading) ...[
              const SizedBox(height: AppTheme.space16),
              Semantics(
                liveRegion: true,
                label: 'Carregando progresso do onboarding',
                child: const LinearProgressIndicator(
                  key: Key('onboarding-loading-progress'),
                ),
              ),
            ],
            if (_persistenceError != null) ...[
              const SizedBox(height: AppTheme.space16),
              _PersistenceNotice(
                message: _persistenceError!,
                retry: _loading ? null : _loadState,
              ),
            ],
            const SizedBox(height: AppTheme.space16),
            _StepCard(
              step: '1',
              title: 'Escolha o formato',
              description: 'Defina o formato principal antes de criar a base.',
              child: DropdownButtonFormField<String>(
                key: const Key('onboarding-format-dropdown'),
                initialValue: _selectedFormat,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Formato'),
                items: _formats
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
                onChanged: _loading || _working ? null : _selectFormat,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            _StepCard(
              step: '2',
              title: 'Monte a base inicial',
              description:
                  'Você pode gerar com IA ou importar uma lista existente.',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth = constraints.maxWidth >= 360
                      ? (constraints.maxWidth - AppTheme.space8) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: AppTheme.space8,
                    runSpacing: AppTheme.space8,
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton.icon(
                          key: const Key('onboarding-generate-action'),
                          onPressed: _loading || _working
                              ? null
                              : () => _chooseBase(generate: true),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Gerar com IA'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppTheme.touchTargetMin,
                            ),
                            backgroundColor: AppTheme.brass500,
                            foregroundColor: AppTheme.backgroundAbyss,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton.icon(
                          key: const Key('onboarding-import-action'),
                          onPressed: _loading || _working
                              ? null
                              : () => _chooseBase(generate: false),
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Importar lista'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppTheme.touchTargetMin,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            _StepCard(
              step: '3',
              title: 'Aplique otimização guiada',
              description:
                  'Depois de criar seu deck, abra os detalhes e use “Otimizar Deck”.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Resultado esperado: comparação Antes vs Depois e sugestões '
                    'com nível de confiança.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space10),
                  ElevatedButton(
                    key: const Key('onboarding-complete-action'),
                    onPressed: _loading || _working
                        ? null
                        : () => _settle(OnboardingDisposition.completed),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppTheme.touchTargetMin,
                      ),
                    ),
                    child: Text(_working ? 'Salvando…' : 'Ir para meus decks'),
                  ),
                ],
              ),
            ),
            if (_disposition == OnboardingDisposition.pending) ...[
              const SizedBox(height: AppTheme.space12),
              TextButton(
                key: const Key('onboarding-skip-action'),
                onPressed: _loading || _working
                    ? null
                    : () => _settle(OnboardingDisposition.skipped),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppTheme.touchTargetMin),
                ),
                child: const Text('Pular por enquanto'),
              ),
            ],
          ],
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

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.child,
  });

  final String step;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      padding: const EdgeInsets.all(AppTheme.space14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.brass500,
                child: Text(
                  step,
                  style: const TextStyle(
                    color: AppTheme.backgroundAbyss,
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontSm,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          child,
        ],
      ),
    );
  }
}
