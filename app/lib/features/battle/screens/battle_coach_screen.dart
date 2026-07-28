import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/visual_fixture.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../../core/widgets/manaloom_theme_motif.dart';
import '../models/battle_test_setup.dart';
import '../models/interactive_battle_session.dart';
import '../services/battle_replay_service.dart';
import '../services/interactive_battle_service.dart';
import 'battle_replays_screen.dart';

String battleCoachRouteLocation(String deckId) =>
    '/decks/${Uri.encodeComponent(deckId)}/battle-coach';

String battleCoachSessionRouteLocation(String deckId, String sessionId) =>
    '${battleCoachRouteLocation(deckId)}/${Uri.encodeComponent(sessionId)}';

class BattleCoachScreen extends StatefulWidget {
  const BattleCoachScreen({
    super.key,
    required this.deckId,
    this.sessionId,
    this.gateway,
    this.opponentGateway,
    this.pollInterval = const Duration(milliseconds: 1200),
  });

  final String deckId;
  final String? sessionId;
  final InteractiveBattleGateway? gateway;
  final BattleReplayGateway? opponentGateway;
  final Duration pollInterval;

  @override
  State<BattleCoachScreen> createState() => _BattleCoachScreenState();
}

class _BattleCoachScreenState extends State<BattleCoachScreen>
    with WidgetsBindingObserver {
  late final InteractiveBattleGateway _gateway;
  late final BattleReplayGateway _opponentGateway;
  Timer? _pollTimer;
  Timer? _clockTimer;
  InteractiveBattleSession? _session;
  bool _loading = false;
  bool _starting = false;
  bool _submitting = false;
  bool _fetching = false;
  bool _appActive = true;
  String? _error;
  int? _integerValue;
  final TextEditingController _multiAmountController = TextEditingController();
  String? _configuredPromptId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gateway = widget.gateway ?? InteractiveBattleService();
    _opponentGateway = widget.opponentGateway ?? BattleReplayService();
    final sessionId = widget.sessionId?.trim();
    if (sessionId != null && sessionId.isNotEmpty) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _session?.isWaitingForAction == true) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      unawaited(_refresh());
    } else {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _multiAmountController.dispose();
    super.dispose();
  }

  Future<void> _chooseOpponent() async {
    if (_starting) return;
    final setup = await showBattleOpponentPicker(
      context: context,
      gateway: _opponentGateway,
      currentDeckId: widget.deckId,
    );
    if (setup == null || !mounted) return;
    await _start(setup);
  }

  Future<void> _start(BattleTestSetup setup) async {
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final session = await _gateway.create(
        deckId: widget.deckId,
        opponentDeckId: setup.opponentDeckId,
      );
      if (!mounted) return;
      _acceptSession(session);
      setState(() => _starting = false);
      final location = battleCoachSessionRouteLocation(
        widget.deckId,
        session.id,
      );
      if (GoRouterState.of(context).uri.path != location) {
        context.replace(location);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = _friendlyError(error);
      });
    }
  }

  Future<void> _refresh() async {
    final sessionId = _session?.id ?? widget.sessionId?.trim();
    if (!_appActive ||
        sessionId == null ||
        sessionId.isEmpty ||
        _fetching ||
        _submitting) {
      return;
    }
    _pollTimer?.cancel();
    _fetching = true;
    try {
      final session = await _gateway.get(sessionId);
      if (!mounted) return;
      _acceptSession(session);
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(error);
      });
    } finally {
      _fetching = false;
      if (mounted) _schedulePoll();
    }
  }

  void _acceptSession(InteractiveBattleSession session) {
    _session = session;
    final prompt = session.prompt;
    if (prompt?.id != _configuredPromptId) {
      _configuredPromptId = prompt?.id;
      _integerValue = prompt?.minimum;
      _multiAmountController.clear();
    }
    _schedulePoll();
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    if (!_appActive || _session?.isTerminal == true) return;
    _pollTimer = Timer(widget.pollInterval, () => unawaited(_refresh()));
  }

  Future<void> _respond(InteractiveBattleResponse response) async {
    final session = _session;
    final prompt = session?.prompt;
    if (session == null || prompt == null || _submitting) return;
    _pollTimer?.cancel();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await _gateway.respond(
        sessionId: session.id,
        prompt: prompt,
        response: response,
      );
      if (!mounted) return;
      _acceptSession(updated);
      setState(() => _submitting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _friendlyError(error);
      });
      unawaited(_refresh());
    }
  }

  Future<void> _submitMultiAmount(InteractiveBattlePrompt prompt) async {
    final values = _multiAmountController.text
        .split(RegExp(r'[,;\s]+'))
        .where((value) => value.trim().isNotEmpty)
        .map((value) => int.tryParse(value.trim()))
        .toList(growable: false);
    if (values.length != prompt.multiAmountCount ||
        values.any((value) => value == null)) {
      setState(() {
        _error =
            'Informe ${prompt.multiAmountCount} valores inteiros, separados por espaço.';
      });
      return;
    }
    await _respond(InteractiveBattleResponse.multiAmount(values.cast<int>()));
  }

  Future<void> _confirmConcede() async {
    final session = _session;
    if (session == null || session.isTerminal || _submitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conceder esta partida?'),
        content: const Text(
          'A sessão será encerrada e o replay parcial continuará disponível '
          'para análise quando o motor conseguir salvá-lo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar jogando'),
          ),
          FilledButton(
            key: const Key('battle-coach-confirm-concede-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Conceder'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _pollTimer?.cancel();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await _gateway.concede(session.id);
      if (!mounted) return;
      _acceptSession(updated);
      setState(() => _submitting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _friendlyError(error);
      });
      _schedulePoll();
    }
  }

  void _openReplay() {
    final replayId = _session?.replayId;
    final query = replayId == null || replayId.isEmpty
        ? ''
        : '?replay=${Uri.encodeQueryComponent(replayId)}';
    context.go('${battleReplaysRouteLocation(widget.deckId)}$query');
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      key: const Key('battle-coach-screen'),
      appBar: AppBar(
        title: const Text('Battle Coach'),
        actions: [
          IconButton(
            key: const Key('battle-coach-history-button'),
            tooltip: 'Abrir replays',
            onPressed: _openReplay,
            icon: const ManaLoomGlyph(ManaLoomGlyphKind.battleReplay, size: 22),
          ),
          if (session != null && !session.isTerminal)
            IconButton(
              key: const Key('battle-coach-refresh-button'),
              tooltip: 'Reconectar à mesa',
              onPressed: _fetching || _submitting ? null : _refresh,
              icon: const Icon(Icons.sync_rounded),
            ),
          if (session != null && !session.isTerminal)
            IconButton(
              key: const Key('battle-coach-concede-button'),
              tooltip: 'Conceder partida',
              onPressed: _submitting ? null : _confirmConcede,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _session == null) {
      return const AppStatePanel.loading(
        key: Key('battle-coach-loading-state'),
        title: 'Reconectando à mesa',
        message: 'Restaurando o estado privado da sua partida.',
        accent: AppTheme.frost400,
      );
    }
    if (_session == null) {
      return _BattleCoachWelcome(
        starting: _starting,
        error: _error,
        onChooseOpponent: _chooseOpponent,
      );
    }

    final session = _session!;
    return Column(
      children: [
        _BattleCoachStatusBar(session: session, busy: _submitting || _fetching),
        if (_error != null)
          _BattleCoachErrorBanner(message: _error!, onRetry: _refresh),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final expanded = constraints.maxWidth >= 1040;
              final board = _BattleCoachBoard(session: session);
              final decisions = _BattleCoachDecisionPanel(
                session: session,
                busy: _submitting,
                integerValue: _integerValue,
                multiAmountController: _multiAmountController,
                onOption: (option) =>
                    _respond(InteractiveBattleResponse.option(option.id)),
                onIntegerChanged: (value) {
                  setState(() => _integerValue = value);
                },
                onIntegerSubmit: () {
                  final value = _integerValue;
                  if (value != null) {
                    unawaited(
                      _respond(InteractiveBattleResponse.integer(value)),
                    );
                  }
                },
                onMultiSubmit: () {
                  final prompt = session.prompt;
                  if (prompt != null) unawaited(_submitMultiAmount(prompt));
                },
                onDelegate: () =>
                    _respond(const InteractiveBattleResponse.delegate()),
                onOpenReplay: _openReplay,
              );
              if (!expanded) {
                return SingleChildScrollView(
                  key: const Key('battle-coach-compact-scroll'),
                  padding: const EdgeInsets.all(AppTheme.pageGutterCompact),
                  child: Column(
                    children: [
                      board,
                      const SizedBox(height: AppTheme.space12),
                      decisions,
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(AppTheme.pageGutter),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: SingleChildScrollView(child: board)),
                    const SizedBox(width: AppTheme.paneGap),
                    SizedBox(
                      width: AppTheme.inspectorWidth,
                      child: SingleChildScrollView(child: decisions),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BattleCoachWelcome extends StatelessWidget {
  const _BattleCoachWelcome({
    required this.starting,
    required this.error,
    required this.onChooseOpponent,
  });

  final bool starting;
  final String? error;
  final VoidCallback onChooseOpponent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Container(
          key: const Key('battle-coach-welcome-state'),
          constraints: const BoxConstraints(maxWidth: 760),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppTheme.brass400.withValues(alpha: 0.35),
            ),
          ),
          child: ManaLoomThemeMotif(
            variant: ManaLoomMotifVariant.battlefield,
            intensity: 0.86,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MÃO · PILHA · CAMPO · PRIORIDADE',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.brass400,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Container(
                    width: 68,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.brass400.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: const ManaLoomGlyph(
                      ManaLoomGlyphKind.battleReplay,
                      size: 38,
                      color: AppTheme.brass400,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space18),
                  Text(
                    'Jogue as decisões que importam',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'O XMage conduz regras e ações automáticas. Quando houver uma '
                    'decisão real — mulligan, alvo, combate, mana ou prioridade — '
                    'a mesa para e entrega a escolha a você.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space18),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppTheme.space8,
                    runSpacing: AppTheme.space8,
                    children: [
                      _CoachTrustChip(
                        icon: Icons.rule_rounded,
                        label: 'Regras pelo XMage',
                      ),
                      _CoachTrustChip(
                        icon: Icons.visibility_off_outlined,
                        label: 'Mão adversária privada',
                      ),
                      _CoachTrustChip(
                        icon: Icons.history_rounded,
                        label: 'Replay e decisões salvos',
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      error!,
                      key: const Key('battle-coach-start-error'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.space24),
                  FilledButton.icon(
                    key: const Key('battle-coach-choose-opponent-button'),
                    onPressed: starting ? null : onChooseOpponent,
                    icon: starting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const ManaLoomGlyph(
                            ManaLoomGlyphKind.commander,
                            size: 20,
                          ),
                    label: Text(
                      starting ? 'Preparando a mesa…' : 'Escolher adversário',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachTrustChip extends StatelessWidget {
  const _CoachTrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.space10,
      vertical: AppTheme.space7,
    ),
    decoration: BoxDecoration(
      color: AppTheme.backgroundAbyss.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      border: Border.all(color: AppTheme.outlineMuted),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.frost400),
        const SizedBox(width: AppTheme.space6),
        Text(label),
      ],
    ),
  );
}

class _BattleCoachStatusBar extends StatelessWidget {
  const _BattleCoachStatusBar({required this.session, required this.busy});

  final InteractiveBattleSession session;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final state = session.privateState;
    final phaseLabel = state.phase?.isNotEmpty == true
        ? _humanize(state.phase!)
        : null;
    final stepLabel = state.step?.isNotEmpty == true
        ? _humanize(state.step!)
        : null;
    final phaseParts = <String>[
      if (state.turn > 0) 'Turno ${state.turn}',
      if (phaseLabel != null) phaseLabel,
      if (stepLabel != null &&
          stepLabel != phaseLabel &&
          !(stepLabel == 'Principal' &&
              phaseLabel?.startsWith('Principal ') == true))
        stepLabel,
    ];
    final waiting = session.isWaitingForAction;
    final accent = waiting
        ? AppTheme.brass400
        : session.isTerminal
        ? AppTheme.success
        : AppTheme.frost400;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('battle-coach-status-bar'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pageGutter,
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate,
          border: Border(
            bottom: BorderSide(color: accent.withValues(alpha: 0.35)),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    waiting
                        ? Icons.touch_app_rounded
                        : session.isTerminal
                        ? Icons.check_circle_outline_rounded
                        : Icons.auto_mode_rounded,
                    size: 18,
                    color: accent,
                  ),
                const SizedBox(width: AppTheme.space8),
                Text(
                  session.status.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              phaseParts.isEmpty
                  ? 'Aguardando estado do jogo'
                  : phaseParts.join(' · '),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleCoachErrorBanner extends StatelessWidget {
  const _BattleCoachErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.errorContainer,
    child: InkWell(
      key: const Key('battle-coach-error-banner'),
      onTap: onRetry,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pageGutter,
          vertical: AppTheme.space8,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sync_problem_rounded,
              color: AppTheme.onErrorContainer,
            ),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                '$message Toque para reconectar.',
                style: const TextStyle(color: AppTheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BattleCoachBoard extends StatelessWidget {
  const _BattleCoachBoard({required this.session});

  final InteractiveBattleSession session;

  @override
  Widget build(BuildContext context) {
    final state = session.privateState;
    final priorityPlayer = session.isTerminal ? null : state.priorityPlayer;
    final own =
        state.ownPlayerState ??
        (state.players.isNotEmpty ? state.players.first : null);
    InteractiveBattlePlayer? opponent;
    for (final player in state.players) {
      if (own == null || player.name != own.name) {
        opponent = player;
        break;
      }
    }
    return Container(
      key: const Key('battle-coach-board'),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlayerZone(
            player: opponent,
            isOwn: false,
            hasPriority:
                priorityPlayer != null && opponent?.name == priorityPlayer,
          ),
          _SharedBattleZone(state: state),
          _PlayerZone(
            player: own,
            isOwn: true,
            hasPriority: priorityPlayer != null && own?.name == priorityPlayer,
          ),
          _OwnHand(cards: state.ownHand),
        ],
      ),
    );
  }
}

class _PlayerZone extends StatelessWidget {
  const _PlayerZone({
    required this.player,
    required this.isOwn,
    required this.hasPriority,
  });

  final InteractiveBattlePlayer? player;
  final bool isOwn;
  final bool hasPriority;

  @override
  Widget build(BuildContext context) {
    final value = player;
    final identity = Row(
      children: [
        ManaLoomGlyph(
          isOwn ? ManaLoomGlyphKind.commander : ManaLoomGlyphKind.battleReplay,
          size: 19,
          color: hasPriority ? AppTheme.brass400 : AppTheme.textSecondary,
        ),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: Text(
            value == null
                ? (isOwn ? 'Seu campo' : 'Campo adversário')
                : '${isOwn ? 'Você' : 'Adversário'} · ${value.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
    final stats = Wrap(
      spacing: AppTheme.space6,
      runSpacing: AppTheme.space5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasPriority)
          const _BoardBadge(
            icon: Icons.bolt_rounded,
            label: 'Prioridade',
            accent: AppTheme.brass400,
          ),
        _BoardBadge(
          icon: Icons.favorite_rounded,
          label: '${value?.life ?? '—'}',
          accent: AppTheme.error,
        ),
        _BoardBadge(
          icon: Icons.style_rounded,
          label: '${value?.handCount ?? 0}',
          accent: AppTheme.frost400,
        ),
        _BoardBadge(
          icon: Icons.layers_outlined,
          label: '${value?.libraryCount ?? 0}',
          accent: AppTheme.textSecondary,
        ),
      ],
    );
    return AnimatedContainer(
      duration: _motionDuration(context),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: hasPriority
            ? AppTheme.brass400.withValues(alpha: 0.055)
            : AppTheme.transparent,
        border: Border(
          left: BorderSide(
            color: hasPriority ? AppTheme.brass400 : AppTheme.transparent,
            width: AppTheme.strokeAccent,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    identity,
                    const SizedBox(height: AppTheme.space7),
                    stats,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: AppTheme.space8),
                  stats,
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.space10),
          _ZoneCards(
            key: ValueKey('battlefield-${value?.name ?? isOwn}'),
            cards: value?.battlefield ?? const <InteractiveBattleCard>[],
            emptyLabel: 'Nenhuma permanente no campo',
            compact: true,
          ),
          if (value != null &&
              (value.command.isNotEmpty || value.graveyard.isNotEmpty)) ...[
            const SizedBox(height: AppTheme.space8),
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space5,
              children: [
                if (value.command.isNotEmpty)
                  _ZoneCount(
                    icon: ManaLoomGlyphKind.commander,
                    label: 'Comando',
                    count: value.command.length,
                  ),
                if (value.graveyard.isNotEmpty)
                  _ZoneCount(
                    materialIcon: Icons.auto_awesome_motion_outlined,
                    label: 'Cemitério',
                    count: value.graveyard.length,
                  ),
                if (value.exile.isNotEmpty)
                  _ZoneCount(
                    materialIcon: Icons.blur_on_rounded,
                    label: 'Exílio',
                    count: value.exile.length,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SharedBattleZone extends StatelessWidget {
  const _SharedBattleZone({required this.state});

  final InteractiveBattlePrivateState state;

  @override
  Widget build(BuildContext context) {
    final hasCombat = state.combat.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      color: AppTheme.backgroundAbyss.withValues(alpha: 0.56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.layers_rounded,
                color: AppTheme.frost400,
                size: 18,
              ),
              const SizedBox(width: AppTheme.space7),
              Text(
                state.stack.isEmpty ? 'Pilha vazia' : 'Pilha',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hasCombat) ...[
                const Spacer(),
                const Icon(
                  Icons.sports_martial_arts_outlined,
                  color: AppTheme.brass400,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.space5),
                Text(
                  'Combate',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.brass400,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          if (state.stack.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space8),
            _ZoneCards(cards: state.stack, emptyLabel: '', compact: true),
          ],
          if (hasCombat) ...[
            const SizedBox(height: AppTheme.space8),
            for (final group in state.combat)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space6),
                child: Text(
                  '${group.attackers.map((card) => card.name).join(', ')}'
                  ' → ${group.defenderName ?? 'defensor'}'
                  '${group.blockers.isEmpty ? '' : ' · bloqueado por ${group.blockers.map((card) => card.name).join(', ')}'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _OwnHand extends StatelessWidget {
  const _OwnHand({required this.cards});

  final List<InteractiveBattleCard> cards;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('battle-coach-own-hand'),
    padding: const EdgeInsets.all(AppTheme.space12),
    decoration: BoxDecoration(
      color: AppTheme.surfaceElevated.withValues(alpha: 0.8),
      border: const Border(top: BorderSide(color: AppTheme.outlineMuted)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const ManaLoomGlyph(
              ManaLoomGlyphKind.deck,
              size: 18,
              color: AppTheme.brass400,
            ),
            const SizedBox(width: AppTheme.space7),
            Text(
              'Sua mão · ${cards.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space10),
        _ZoneCards(
          cards: cards,
          emptyLabel: 'Sua mão está vazia',
          compact: false,
        ),
      ],
    ),
  );
}

class _ZoneCards extends StatelessWidget {
  const _ZoneCards({
    super.key,
    required this.cards,
    required this.emptyLabel,
    required this.compact,
  });

  final List<InteractiveBattleCard> cards;
  final String emptyLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Container(
        height: compact ? 48 : 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.backgroundAbyss.withValues(alpha: 0.36),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: AppTheme.outlineMuted.withValues(alpha: 0.65),
          ),
        ),
        child: Text(
          emptyLabel,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textHint),
        ),
      );
    }
    final width = compact ? 68.0 : 96.0;
    final height = compact ? 95.0 : 134.0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final card in cards) ...[
            _BattleCard(card: card, width: width, height: height),
            const SizedBox(width: AppTheme.space8),
          ],
        ],
      ),
    );
  }
}

class _BattleCard extends StatelessWidget {
  const _BattleCard({
    required this.card,
    required this.width,
    required this.height,
  });

  final InteractiveBattleCard card;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cardBody = Stack(
      fit: StackFit.expand,
      children: [
        AnimatedRotation(
          turns: card.tapped ? 0.25 : 0,
          duration: _motionDuration(context),
          child: CachedCardImage(
            imageUrl: card.effectiveImageUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            errorPlaceholder: _CardFallback(name: card.name),
          ),
        ),
        if (card.damage > 0 || card.counters.isNotEmpty)
          Positioned(
            right: AppTheme.space3,
            bottom: AppTheme.space3,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space5,
                vertical: AppTheme.space2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.overlayBlack65,
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: Text(
                [
                  if (card.damage > 0) '${card.damage} dano',
                  ...card.counters.map(
                    (counter) => '${counter.count} ${counter.name}',
                  ),
                ].join(' · '),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontMicro,
                ),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      image: true,
      label: '${card.name}${card.tapped ? ', virada' : ''}',
      child: SizedBox(width: width, height: height, child: cardBody),
    );
  }
}

class _CardFallback extends StatelessWidget {
  const _CardFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppTheme.space6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppTheme.backgroundAbyss,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      border: Border.all(color: AppTheme.outlineMuted),
    ),
    child: Text(
      name,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
    ),
  );
}

class _BoardBadge extends StatelessWidget {
  const _BoardBadge({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.space6,
      vertical: AppTheme.space3,
    ),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: AppTheme.space3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ZoneCount extends StatelessWidget {
  const _ZoneCount({
    this.icon,
    this.materialIcon,
    required this.label,
    required this.count,
  }) : assert(icon != null || materialIcon != null);

  final ManaLoomGlyphKind? icon;
  final IconData? materialIcon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null)
        ManaLoomGlyph(icon!, size: 15, color: AppTheme.textHint)
      else
        Icon(materialIcon, size: 15, color: AppTheme.textHint),
      const SizedBox(width: AppTheme.space4),
      Text(
        '$label $count',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppTheme.textHint),
      ),
    ],
  );
}

class _BattleCoachDecisionPanel extends StatelessWidget {
  const _BattleCoachDecisionPanel({
    required this.session,
    required this.busy,
    required this.integerValue,
    required this.multiAmountController,
    required this.onOption,
    required this.onIntegerChanged,
    required this.onIntegerSubmit,
    required this.onMultiSubmit,
    required this.onDelegate,
    required this.onOpenReplay,
  });

  final InteractiveBattleSession session;
  final bool busy;
  final int? integerValue;
  final TextEditingController multiAmountController;
  final ValueChanged<InteractiveBattlePromptOption> onOption;
  final ValueChanged<int> onIntegerChanged;
  final VoidCallback onIntegerSubmit;
  final VoidCallback onMultiSubmit;
  final VoidCallback onDelegate;
  final VoidCallback onOpenReplay;

  @override
  Widget build(BuildContext context) {
    if (session.isTerminal) {
      return _BattleCoachTerminalPanel(
        session: session,
        onOpenReplay: onOpenReplay,
      );
    }
    final prompt = session.prompt;
    if (prompt == null) {
      return const _BattleCoachAutoplayPanel();
    }
    final remaining = prompt.deadlineAt.difference(DateTime.now().toUtc());
    final seconds = manaloomVisualFixtureMode
        ? 60
        : remaining.isNegative
        ? 0
        : remaining.inSeconds;
    return AnimatedSwitcher(
      duration: _motionDuration(context),
      child: Container(
        key: ValueKey(prompt.id),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: AppTheme.brass400,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    prompt.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _DecisionClock(seconds: seconds),
              ],
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              prompt.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.space14),
            if (busy)
              const LinearProgressIndicator(
                key: Key('battle-coach-action-progress'),
                minHeight: AppTheme.space3,
              )
            else if (prompt.inputMode == 'options')
              for (final option in prompt.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space8),
                  child: _PromptOptionTile(
                    option: option,
                    onPressed: () => onOption(option),
                  ),
                )
            else if (prompt.inputMode == 'integer')
              _IntegerDecision(
                prompt: prompt,
                value: integerValue ?? prompt.minimum ?? 0,
                onChanged: onIntegerChanged,
                onSubmit: onIntegerSubmit,
              )
            else if (prompt.inputMode == 'multi_amount')
              _MultiAmountDecision(
                prompt: prompt,
                controller: multiAmountController,
                onSubmit: onMultiSubmit,
              ),
            const SizedBox(height: AppTheme.space6),
            OutlinedButton.icon(
              key: const Key('battle-coach-delegate-button'),
              onPressed: busy ? null : onDelegate,
              icon: const Icon(Icons.auto_mode_rounded),
              label: const Text('Delegar esta decisão ao motor'),
            ),
            const SizedBox(height: AppTheme.space6),
            Text(
              'Delegar vale somente para este prompt. A próxima decisão '
              'interativa voltará para você.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textHint,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionClock extends StatelessWidget {
  const _DecisionClock({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 15;
    final color = urgent ? AppTheme.warning : AppTheme.frost400;
    return Semantics(
      label: '$seconds segundos para decidir',
      child: Container(
        key: const Key('battle-coach-decision-clock'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space7,
          vertical: AppTheme.space4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, color: color, size: 15),
            const SizedBox(width: AppTheme.space4),
            Text(
              '${seconds}s',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptOptionTile extends StatelessWidget {
  const _PromptOptionTile({required this.option, required this.onPressed});

  final InteractiveBattlePromptOption option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final card = option.card;
    return Material(
      color: AppTheme.backgroundAbyss.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('battle-coach-option-${option.id}'),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space8),
          child: Row(
            children: [
              if (card != null) ...[
                CachedCardImage(
                  imageUrl: card.effectiveImageUrl,
                  width: 45,
                  height: 63,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  errorPlaceholder: _CardFallback(name: card.name),
                ),
                const SizedBox(width: AppTheme.space10),
              ] else ...[
                Icon(
                  _optionIcon(option.role),
                  color: AppTheme.brass400,
                  size: 21,
                ),
                const SizedBox(width: AppTheme.space10),
              ],
              Expanded(
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntegerDecision extends StatelessWidget {
  const _IntegerDecision({
    required this.prompt,
    required this.value,
    required this.onChanged,
    required this.onSubmit,
  });

  final InteractiveBattlePrompt prompt;
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final minimum = prompt.minimum ?? 0;
    final maximum = prompt.maximum ?? minimum;
    final divisions = maximum > minimum ? maximum - minimum : null;
    return Column(
      children: [
        Text(
          '$value',
          key: const Key('battle-coach-integer-value'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.brass400,
            fontWeight: FontWeight.w800,
          ),
        ),
        Slider(
          key: const Key('battle-coach-integer-slider'),
          value: value.clamp(minimum, maximum).toDouble(),
          min: minimum.toDouble(),
          max: maximum.toDouble(),
          divisions: divisions,
          label: '$value',
          semanticFormatterCallback: (next) =>
              'Quantidade ${next.round()} de $minimum a $maximum',
          onChanged: maximum == minimum
              ? null
              : (next) => onChanged(next.round()),
        ),
        FilledButton(
          key: const Key('battle-coach-integer-submit-button'),
          onPressed: onSubmit,
          child: const Text('Confirmar quantidade'),
        ),
      ],
    );
  }
}

class _MultiAmountDecision extends StatelessWidget {
  const _MultiAmountDecision({
    required this.prompt,
    required this.controller,
    required this.onSubmit,
  });

  final InteractiveBattlePrompt prompt;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const Key('battle-coach-multi-amount-field'),
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: '${prompt.multiAmountCount} quantidades',
          hintText: 'Ex.: 1 0 2',
          helperText: 'Separe cada valor por espaço.',
        ),
        onSubmitted: (_) => onSubmit(),
      ),
      const SizedBox(height: AppTheme.space10),
      FilledButton(
        key: const Key('battle-coach-multi-submit-button'),
        onPressed: onSubmit,
        child: const Text('Confirmar distribuição'),
      ),
    ],
  );
}

class _BattleCoachAutoplayPanel extends StatelessWidget {
  const _BattleCoachAutoplayPanel();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('battle-coach-autoplay-panel'),
    padding: const EdgeInsets.all(AppTheme.space18),
    decoration: BoxDecoration(
      color: AppTheme.surfaceSlate,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.outlineMuted),
    ),
    child: Column(
      children: [
        const ManaLoomGlyph(
          ManaLoomGlyphKind.shuffle,
          size: 34,
          color: AppTheme.frost400,
        ),
        const SizedBox(height: AppTheme.space12),
        Text(
          'O motor está jogando',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          'A mesa atualiza automaticamente e para quando uma decisão sua for necessária.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppTheme.space14),
        const LinearProgressIndicator(minHeight: AppTheme.space3),
      ],
    ),
  );
}

class _BattleCoachTerminalPanel extends StatelessWidget {
  const _BattleCoachTerminalPanel({
    required this.session,
    required this.onOpenReplay,
  });

  final InteractiveBattleSession session;
  final VoidCallback onOpenReplay;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('battle-coach-terminal-panel'),
    padding: const EdgeInsets.all(AppTheme.space18),
    decoration: BoxDecoration(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.success.withValues(alpha: 0.48)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppTheme.success,
          size: 38,
        ),
        const SizedBox(height: AppTheme.space12),
        Text(
          session.status.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          session.replayId == null
              ? 'A sessão terminou. O estado final permanece disponível nesta tela.'
              : 'O replay e a trilha de decisões estão prontos para revisão.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.35,
          ),
        ),
        if (session.errorCode != null) ...[
          const SizedBox(height: AppTheme.space8),
          Text(
            'Código técnico: ${session.errorCode}',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.textHint),
          ),
        ],
        const SizedBox(height: AppTheme.space16),
        FilledButton.icon(
          key: const Key('battle-coach-open-replay-button'),
          onPressed: onOpenReplay,
          icon: const ManaLoomGlyph(ManaLoomGlyphKind.battleReplay, size: 19),
          label: Text(
            session.replayId == null ? 'Abrir histórico' : 'Analisar replay',
          ),
        ),
      ],
    ),
  );
}

IconData _optionIcon(String role) => switch (role) {
  'keep' => Icons.front_hand_outlined,
  'mulligan' => Icons.shuffle_rounded,
  'target' => Icons.my_location_rounded,
  'done' => Icons.check_circle_outline_rounded,
  'cancel' => Icons.close_rounded,
  'delegate' => Icons.auto_mode_rounded,
  _ => Icons.bolt_rounded,
};

Duration _motionDuration(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations == true
    ? Duration.zero
    : const Duration(milliseconds: 220);

String _friendlyError(Object error) {
  if (error is InteractiveBattleGatewayException) return error.message;
  if (error is BattleReplayException) return error.message;
  return 'Não foi possível atualizar esta mesa.';
}

String _humanize(String value) {
  final normalized = value
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();
  final translated = switch (normalized) {
    'beginning' => 'Início',
    'untap' => 'Desvirar',
    'upkeep' => 'Manutenção',
    'draw' => 'Compra',
    'precombat main' => 'Principal pré-combate',
    'main' => 'Principal',
    'combat' => 'Combate',
    'begin combat' => 'Início do combate',
    'declare attackers' => 'Declarar atacantes',
    'declare blockers' => 'Declarar bloqueadores',
    'combat damage' => 'Dano de combate',
    'end combat' => 'Fim do combate',
    'postcombat main' => 'Principal pós-combate',
    'end' => 'Final',
    'end step' => 'Etapa final',
    'cleanup' => 'Limpeza',
    _ => null,
  };
  if (translated != null) return translated;
  if (normalized.isEmpty) return value;
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
