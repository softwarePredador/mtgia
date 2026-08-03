import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/launch_features.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../models/battle_job.dart';
import '../models/battle_live_cursor.dart';
import '../services/battle_job_gateway.dart';

String battleLiveRouteLocation(String deckId, String jobId) =>
    '/decks/${Uri.encodeComponent(deckId)}/battle-live/'
    '${Uri.encodeComponent(jobId)}';

String battleReplayDetailRouteLocation(String deckId, String replayId) =>
    '/decks/${Uri.encodeComponent(deckId)}/battle-replays'
    '?replay=${Uri.encodeQueryComponent(replayId)}';

class BattleLiveSpectatorScreen extends StatefulWidget {
  const BattleLiveSpectatorScreen({
    super.key,
    required this.deckId,
    required this.jobId,
    this.gateway,
    this.featureEnabled = LaunchFeatures.battleLiveSpectatorEnabled,
    this.pollInterval = const Duration(seconds: 2),
    this.onOpenReplay,
  });

  final String deckId;
  final String jobId;
  final BattleJobGateway? gateway;
  final bool featureEnabled;
  final Duration pollInterval;
  final ValueChanged<String>? onOpenReplay;

  @override
  State<BattleLiveSpectatorScreen> createState() =>
      _BattleLiveSpectatorScreenState();
}

class _BattleLiveSpectatorScreenState extends State<BattleLiveSpectatorScreen>
    with WidgetsBindingObserver {
  late final BattleJobGateway _gateway;
  final FocusNode _keyboardFocusNode = FocusNode(
    debugLabel: 'battle-live-keyboard-focus',
  );
  final FocusNode _retryFocusNode = FocusNode(
    debugLabel: 'battle-live-retry-focus',
  );

  BattleJob? _job;
  BattleLiveSession _session = const BattleLiveSession.empty();
  Timer? _pollTimer;
  bool _initialLoading = true;
  bool _pollInFlight = false;
  bool _playbackPaused = false;
  bool _cancelConfirmationVisible = false;
  bool _cancelling = false;
  bool _appActive = true;
  bool _visualFeedUnavailable = false;
  int _visibleRecordCount = 0;
  String? _connectionError;

  bool get _isTerminal => _session.isTerminal || _job?.isTerminal == true;
  bool get _pollingComplete {
    final job = _job;
    if ((_session.hasMore || _session.replayPending) &&
        !_visualFeedUnavailable) {
      return false;
    }
    if (job?.isTerminal == true) return true;
    final status = _session.status;
    if (status == null || !status.isTerminal) return false;
    return status != BattleLiveStatus.completed || _session.replayId != null;
  }

  String? get _replayId => _session.replayId ?? _job?.replayId;
  int get _bufferedRecordCount {
    final buffered = _session.records.length - _visibleRecordCount;
    return buffered < 0 ? 0 : buffered;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gateway = widget.gateway ?? BattleJobGateway();
    if (widget.featureEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pollOnce());
    } else {
      _initialLoading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appActive = true;
      _schedulePoll(immediate: true);
    } else {
      _appActive = false;
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _keyboardFocusNode.dispose();
    _retryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pollOnce() async {
    if (!mounted ||
        !widget.featureEnabled ||
        _pollInFlight ||
        _pollingComplete) {
      return;
    }
    _pollTimer?.cancel();
    _pollInFlight = true;
    BattleJob? fetchedJob;

    try {
      final job = await _gateway.get(widget.jobId);
      fetchedJob = job;
      if (!mounted) return;
      setState(() {
        _job = job;
        _initialLoading = false;
      });

      BattleLiveSession nextSession = _session;
      final knownUnsupportedEngine =
          job.engine != null && job.engine != BattleExecutionEngine.xmage;
      var visualFeedUnavailable = knownUnsupportedEngine;
      if (!visualFeedUnavailable) {
        try {
          nextSession = await _gateway.pollLive(
            jobId: widget.jobId,
            session: _session,
          );
        } on BattleJobGatewayException catch (error) {
          if (error.statusCode == 409) {
            visualFeedUnavailable = !_isTransientEngineAssignment(job);
          } else if (job.isTerminal) {
            nextSession = _session;
          } else {
            rethrow;
          }
        }
      }
      if (!mounted) return;

      setState(() {
        _job = job;
        _session = nextSession;
        _visualFeedUnavailable = visualFeedUnavailable;
        if (!_playbackPaused) {
          _visibleRecordCount = nextSession.records.length;
        }
        _initialLoading = false;
        _connectionError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (fetchedJob != null) _job = fetchedJob;
        _initialLoading = false;
        _connectionError = _friendlyLiveError(error);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _connectionError != null) {
          _retryFocusNode.requestFocus();
        }
      });
    } finally {
      _pollInFlight = false;
      if (mounted && !_pollingComplete) {
        _schedulePoll(immediate: _session.hasMore);
      }
    }
  }

  void _schedulePoll({bool immediate = false}) {
    _pollTimer?.cancel();
    if (!mounted || !widget.featureEnabled || !_appActive || _pollingComplete) {
      return;
    }
    _pollTimer = Timer(
      immediate ? Duration.zero : widget.pollInterval,
      _pollOnce,
    );
  }

  void _retry() {
    setState(() => _connectionError = null);
    _schedulePoll(immediate: true);
  }

  void _togglePlayback() {
    if (_session.records.isEmpty || _isTerminal) return;
    setState(() {
      _playbackPaused = !_playbackPaused;
      if (!_playbackPaused) {
        _visibleRecordCount = _session.records.length;
      }
    });
  }

  void _jumpToLatest() {
    if (_session.records.isEmpty) return;
    setState(() {
      _playbackPaused = false;
      _visibleRecordCount = _session.records.length;
    });
  }

  Future<void> _cancel() async {
    if (_cancelling || _job?.canCancel != true) return;
    setState(() => _cancelling = true);
    try {
      final result = await _gateway.cancel(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = result.job;
        _cancelConfirmationVisible = false;
        _cancelling = false;
        _connectionError = null;
      });
      if (!_isTerminal) _schedulePoll(immediate: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _connectionError = _friendlyLiveError(error);
      });
    }
  }

  void _openReplay() {
    final replayId = _replayId;
    if (replayId == null) return;
    final callback = widget.onOpenReplay;
    if (callback != null) {
      callback(replayId);
      return;
    }
    context.go(battleReplayDetailRouteLocation(widget.deckId, replayId));
  }

  void _backToReplays() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/decks/${Uri.encodeComponent(widget.deckId)}/battle-replays');
  }

  void _prepareNewAttempt() {
    context.go('/decks/${Uri.encodeComponent(widget.deckId)}/battle-replays');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('battle-live-screen'),
      appBar: AppBar(
        title: const Text('Acompanhar ao vivo'),
        actions: [
          if (widget.featureEnabled && !_initialLoading)
            IconButton(
              key: const Key('battle-live-refresh-button'),
              tooltip: 'Reconectar ao Battle',
              onPressed: _pollInFlight ? null : _retry,
              icon: const Icon(Icons.sync_rounded),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: SizedBox.expand(
            child: Column(
              children: [
                const _BattleLiveReadOnlyNotice(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!widget.featureEnabled) {
      return AppStatePanel(
        key: const Key('battle-live-disabled-state'),
        iconWidget: const ManaLoomGlyph(
          ManaLoomGlyphKind.battleReplay,
          size: 28,
        ),
        title: 'Battle ao vivo ainda não habilitado',
        message:
            'Este ambiente mantém apenas o Battle síncrono homologado. '
            'Volte aos replays para executar e revisar testes disponíveis.',
        accent: AppTheme.brass400,
        actionLabel: 'Voltar aos replays',
        onAction: _backToReplays,
      );
    }

    if (_initialLoading) {
      return const AppStatePanel.loading(
        key: Key('battle-live-loading-state'),
        title: 'Conectando ao Battle',
        message: 'Retomando a partida e as atualizações já validadas.',
        accent: AppTheme.frost400,
      );
    }

    if (_job == null && _connectionError != null) {
      return AppStatePanel(
        key: const Key('battle-live-error-state'),
        icon: Icons.cloud_off_rounded,
        title: 'Battle temporariamente indisponível',
        message:
            'A partida não foi alterada. Reconecte para retomar do último ponto recebido.',
        accent: Theme.of(context).colorScheme.error,
        actionLabel: 'Reconectar',
        onAction: _retry,
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _togglePlayback,
        const SingleActivator(LogicalKeyboardKey.keyR): _retry,
        const SingleActivator(LogicalKeyboardKey.end): _jumpToLatest,
      },
      child: Focus(
        key: const Key('battle-live-keyboard-focus'),
        focusNode: _keyboardFocusNode,
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space14,
              AppTheme.space16,
              AppTheme.space32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight > AppTheme.space48
                    ? constraints.maxHeight - AppTheme.space48
                    : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeader(),
                  _buildConnectionNotice(),
                  if (_cancelConfirmationVisible) _buildCancelConfirmation(),
                  const SizedBox(height: AppTheme.space16),
                  if (_visualFeedUnavailable)
                    const _BattleVisualFeedUnavailablePanel()
                  else
                    _buildWorkspace(constraints.maxWidth),
                  if (_isTerminal) ...[
                    const SizedBox(height: AppTheme.space16),
                    _buildTerminalAction(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final job = _job!;
    final theme = Theme.of(context);
    final statusColor = _battleJobStatusColor(job.status);
    final progressIsTerminal = job.isTerminal;
    final stageLabel = _battleStageLabel(job.stage);
    final elapsedLabel = _battleElapsedLabel(job);
    return Container(
      key: const Key('battle-live-status-header'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        border: Border.all(
          color: statusColor.withValues(alpha: 0.42),
          width: AppTheme.strokeHairline,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const ManaLoomGlyph(
                ManaLoomGlyphKind.battleReplay,
                size: 24,
                color: AppTheme.brass400,
              ),
              Text(
                'Mesa em observação',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _LiveStatusBadge(
                label: _battleJobStatusLabel(job.status),
                color: statusColor,
              ),
              if (_playbackPaused)
                const _LiveStatusBadge(
                  label: 'Pausa local',
                  color: AppTheme.brass400,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Partida ${_shortId(job.jobId)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Semantics(
            label: 'Progresso do Battle',
            value: progressIsTerminal
                ? 'Execução encerrada: ${_battleJobStatusLabel(job.status)}'
                : 'Em andamento: $stageLabel',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXxs),
              child: LinearProgressIndicator(
                key: const Key('battle-live-progress'),
                value: progressIsTerminal ? 1 : null,
                minHeight: 6,
                backgroundColor: AppTheme.outlineMuted.withValues(alpha: 0.38),
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            spacing: AppTheme.space10,
            runSpacing: AppTheme.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                progressIsTerminal
                    ? '$stageLabel · Duração total: $elapsedLabel'
                    : '$stageLabel · Tempo decorrido: $elapsedLabel',
                key: const Key('battle-live-progress-detail'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              OutlinedButton.icon(
                key: const Key('battle-live-pause-button'),
                onPressed: _session.records.isEmpty || _isTerminal
                    ? null
                    : _togglePlayback,
                icon: Icon(
                  _playbackPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                ),
                label: Text(
                  _playbackPaused
                      ? 'Retomar acompanhamento'
                      : 'Pausar visualização',
                ),
              ),
              if (_bufferedRecordCount > 0)
                TextButton.icon(
                  key: const Key('battle-live-jump-latest-button'),
                  onPressed: _jumpToLatest,
                  icon: const Icon(Icons.vertical_align_bottom_rounded),
                  label: Text(
                    'Ver $_bufferedRecordCount '
                    '${_bufferedRecordCount == 1 ? 'novo registro' : 'novos registros'}',
                  ),
                ),
              if (job.canCancel && !_isTerminal)
                TextButton.icon(
                  key: const Key('battle-live-cancel-button'),
                  onPressed: _cancelling
                      ? null
                      : () => setState(() => _cancelConfirmationVisible = true),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Cancelar Battle'),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            'Atalhos: Espaço pausa localmente · End volta ao mais recente · '
            'R reconecta. Pausar não interrompe o motor.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textHint,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionNotice() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final message = _connectionError;
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 160),
      child: message == null
          ? const SizedBox.shrink(key: Key('battle-live-connected-state'))
          : Container(
              key: const Key('battle-live-reconnect-banner'),
              margin: const EdgeInsets.only(top: AppTheme.space12),
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.45),
                ),
              ),
              child: Wrap(
                spacing: AppTheme.space12,
                runSpacing: AppTheme.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(
                      '$message Os registros recebidos permanecem na tela.',
                    ),
                  ),
                  TextButton(
                    key: const Key('battle-live-inline-retry-button'),
                    focusNode: _retryFocusNode,
                    onPressed: _retry,
                    child: const Text('Reconectar'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCancelConfirmation() {
    return Container(
      key: const Key('battle-live-cancel-confirmation'),
      margin: const EdgeInsets.only(top: AppTheme.space12),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.brass500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.brass500.withValues(alpha: 0.42)),
      ),
      child: Wrap(
        spacing: AppTheme.space10,
        runSpacing: AppTheme.space8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Cancelar solicita o encerramento da partida; o replay pode não existir.',
          ),
          FilledButton(
            key: const Key('battle-live-confirm-cancel-button'),
            onPressed: _cancelling ? null : _cancel,
            child: Text(_cancelling ? 'Cancelando…' : 'Confirmar cancelamento'),
          ),
          TextButton(
            key: const Key('battle-live-keep-running-button'),
            onPressed: _cancelling
                ? null
                : () => setState(() => _cancelConfirmationVisible = false),
            child: const Text('Manter Battle'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(double width) {
    final visibleRecords = _session.records
        .take(_visibleRecordCount)
        .toList(growable: false);
    final latestSnapshot = _latestSnapshot(visibleRecords);
    final table = _BattleLiveTable(
      snapshot: latestSnapshot,
      receivedRecordCount: visibleRecords.length,
      paused: _playbackPaused,
    );
    final timeline = _BattleLiveTimeline(records: visibleRecords);

    if (width >= AppTheme.breakpointExpanded) {
      return Row(
        key: const Key('battle-live-wide-workspace'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: table),
          const SizedBox(width: AppTheme.space16),
          Expanded(flex: 5, child: timeline),
        ],
      );
    }
    return Column(
      key: const Key('battle-live-stacked-workspace'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        table,
        const SizedBox(height: AppTheme.space16),
        timeline,
      ],
    );
  }

  Widget _buildTerminalAction() {
    final replayId = _replayId;
    final replayPending =
        replayId == null && (_session.replayPending || _session.hasMore);
    final theme = Theme.of(context);
    return Container(
      key: const Key('battle-live-terminal-state'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.4)),
      ),
      child: Wrap(
        spacing: AppTheme.space16,
        runSpacing: AppTheme.space12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const ManaLoomGlyph(
            ManaLoomGlyphKind.battleReplay,
            size: 28,
            color: AppTheme.frost400,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  replayPending
                      ? 'Finalizando o replay'
                      : replayId == null
                      ? 'Battle encerrado sem replay disponível'
                      : 'Battle concluído e replay validado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  replayPending
                      ? 'A partida terminou; a referência persistida ainda '
                            'está sendo confirmada.'
                      : replayId == null
                      ? _terminalReasonCopy(
                          _session.terminalReason ?? _job?.terminalReason,
                          status: _job?.status,
                          errorCode: _job?.errorCode,
                        )
                      : 'Abra o registro persistido para revisar campo, '
                            'timeline e evidências do motor.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (replayId != null)
            FilledButton.icon(
              key: const Key('battle-live-open-replay-button'),
              onPressed: _openReplay,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Abrir replay final'),
            )
          else if (replayPending)
            const SizedBox.square(
              key: Key('battle-live-replay-pending'),
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              children: [
                FilledButton.icon(
                  key: const Key('battle-live-new-attempt-button'),
                  onPressed: _prepareNewAttempt,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Preparar nova tentativa'),
                ),
                TextButton(
                  key: const Key('battle-live-back-replays-button'),
                  onPressed: _backToReplays,
                  child: const Text('Voltar aos replays'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BattleLiveReadOnlyNotice extends StatelessWidget {
  const _BattleLiveReadOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Somente acompanhamento. Você não controla a partida.',
      child: Container(
        key: const Key('battle-live-read-only-notice'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          AppTheme.space10,
          AppTheme.space16,
          AppTheme.space0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.frost400.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.34)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: AppTheme.frost400),
            SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                'Somente acompanhamento — você não controla a partida',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleVisualFeedUnavailablePanel extends StatelessWidget {
  const _BattleVisualFeedUnavailablePanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('battle-live-visual-feed-unavailable'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            color: AppTheme.brass400,
            size: 28,
          ),
          const SizedBox(height: AppTheme.space10),
          Text(
            'Acompanhamento visual indisponível para esta partida',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            'A simulação continua normalmente. O progresso será atualizado '
            'aqui e o replay poderá ser aberto quando a partida terminar.',
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

class _BattleLiveTable extends StatelessWidget {
  const _BattleLiveTable({
    required this.snapshot,
    required this.receivedRecordCount,
    required this.paused,
  });

  final BattleLiveRecord? snapshot;
  final int receivedRecordCount;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = snapshot?.payload;
    final players = _publicMapList(payload?['players']);
    final stack = _publicMapList(payload?['stack']);
    final combat = _publicMapList(payload?['combat']);

    return Container(
      key: const Key('battle-live-table'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.62),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTheme.space10,
            runSpacing: AppTheme.space6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Estado observável',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (payload != null)
                Text(
                  _snapshotPosition(payload),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.frost400,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            paused
                ? 'Visualização pausada localmente. A partida continua recebendo atualizações.'
                : 'Somente zonas públicas e contagens validadas são exibidas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppTheme.space14),
          if (snapshot == null)
            _EmptyLiveRegion(
              message: receivedRecordCount == 0
                  ? 'Aguardando o primeiro estado público da partida.'
                  : 'Eventos recebidos; o primeiro snapshot público ainda não chegou.',
            )
          else ...[
            if (players.isEmpty)
              const _EmptyLiveRegion(
                message: 'Este snapshot não informou jogadores públicos.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal =
                      constraints.maxWidth >= AppTheme.breakpointMedium;
                  if (horizontal && players.length >= 2) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (
                          var index = 0;
                          index < players.length;
                          index++
                        ) ...[
                          if (index > 0)
                            const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: _BattleLivePlayer(player: players[index]),
                          ),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var index = 0; index < players.length; index++) ...[
                        if (index > 0) const SizedBox(height: AppTheme.space10),
                        _BattleLivePlayer(player: players[index]),
                      ],
                    ],
                  );
                },
              ),
            const SizedBox(height: AppTheme.space14),
            _PublicZoneSummary(
              title: 'Pilha',
              emptyLabel: 'Pilha vazia',
              items: stack.map(_publicObjectName).toList(growable: false),
            ),
            const SizedBox(height: AppTheme.space10),
            _PublicZoneSummary(
              title: 'Combate',
              emptyLabel: 'Sem combate declarado',
              items: combat.map(_combatSummary).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _BattleLivePlayer extends StatelessWidget {
  const _BattleLivePlayer({required this.player});

  final Map<String, dynamic> player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        _safeText(player['name']) ?? _safeText(player['deck_key']) ?? 'Jogador';
    return Container(
      key: Key('battle-live-player-${_safeKey(name)}'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              _PublicMetric(
                label: 'Vida',
                value: _safeNumber(player['life']),
                accent: AppTheme.brass400,
              ),
              _PublicMetric(
                label: 'Mão',
                value: _safeNumber(player['hand_size']),
              ),
              _PublicMetric(
                label: 'Grimório',
                value: _safeNumber(player['library_size']),
              ),
              _PublicMetric(
                label: 'Campo',
                value: _safeNumber(player['battlefield_count']),
              ),
              _PublicMetric(
                label: 'Cemitério',
                value: _safeNumber(player['graveyard_size']),
              ),
              _PublicMetric(
                label: 'Mana',
                value:
                    _safeNumber(player['mana_available']) ??
                    _safeNumber(player['mana']),
                accent: AppTheme.frost400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublicMetric extends StatelessWidget {
  const _PublicMetric({required this.label, this.value, this.accent});

  final String label;
  final String? value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: ${value ?? 'não informado'}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space10,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: (accent ?? AppTheme.frost400).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: ExcludeSemantics(
          child: Text(
            '$label ${value ?? '—'}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent ?? AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicZoneSummary extends StatelessWidget {
  const _PublicZoneSummary({
    required this.title,
    required this.emptyLabel,
    required this.items,
  });

  final String title;
  final String emptyLabel;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Text(
          items.isEmpty ? emptyLabel : items.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BattleLiveTimeline extends StatelessWidget {
  const _BattleLiveTimeline({required this.records});

  final List<BattleLiveRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = records.length <= 80
        ? records
        : records.sublist(records.length - 80);
    return Container(
      key: const Key('battle-live-timeline'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.62),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline pública',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            records.length > 80
                ? 'Exibindo os 80 registros públicos mais recentes.'
                : '${records.length} ${records.length == 1 ? 'registro recebido' : 'registros recebidos'}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          if (visible.isEmpty)
            const _EmptyLiveRegion(
              message: 'A timeline aparecerá quando o motor publicar eventos.',
            )
          else
            for (final record in visible)
              _BattleLiveTimelineRow(record: record),
        ],
      ),
    );
  }
}

class _BattleLiveTimelineRow extends StatelessWidget {
  const _BattleLiveTimelineRow({required this.record});

  final BattleLiveRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSnapshot = record.kind == BattleLiveRecordKind.snapshot;
    return Container(
      key: Key('battle-live-record-${record.recordId}'),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineMuted.withValues(alpha: 0.34),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isSnapshot ? AppTheme.frost400 : AppTheme.brass400)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '${record.sequence}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSnapshot ? AppTheme.frost400 : AppTheme.brass400,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSnapshot
                      ? _snapshotPosition(record.payload)
                      : _eventTitle(record.payload),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                Text(
                  isSnapshot
                      ? 'Estado público capturado'
                      : _eventDescription(record.payload),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (record.contentTruncated) ...[
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    'Conteúdo limitado pelo contrato público.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.brass400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLiveRegion extends StatelessWidget {
  const _EmptyLiveRegion({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

class _LiveStatusBadge extends StatelessWidget {
  const _LiveStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space8,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _friendlyLiveError(Object error) {
  if (error is BattleJobGatewayException) return error.message;
  return 'Não foi possível atualizar o Battle agora.';
}

Color _battleJobStatusColor(BattleJobStatus status) => switch (status) {
  BattleJobStatus.completed => AppTheme.frost400,
  BattleJobStatus.cancelled ||
  BattleJobStatus.censored ||
  BattleJobStatus.timeout ||
  BattleJobStatus.coverageError ||
  BattleJobStatus.engineError ||
  BattleJobStatus.persistenceError => AppTheme.error,
  BattleJobStatus.cancelPending => AppTheme.brass400,
  _ => AppTheme.frost400,
};

String _battleJobStatusLabel(BattleJobStatus status) => switch (status) {
  BattleJobStatus.queued => 'Na fila',
  BattleJobStatus.claimed => 'Preparando',
  BattleJobStatus.running => 'Em execução',
  BattleJobStatus.cancelPending => 'Cancelamento solicitado',
  BattleJobStatus.completed => 'Concluído',
  BattleJobStatus.censored => 'Censurado',
  BattleJobStatus.timeout => 'Tempo esgotado',
  BattleJobStatus.coverageError => 'Cobertura insuficiente',
  BattleJobStatus.engineError => 'Falha do motor',
  BattleJobStatus.cancelled => 'Cancelado',
  BattleJobStatus.persistenceError => 'Falha ao persistir',
};

String _battleStageLabel(String stage) => switch (stage) {
  'queued' => 'Aguardando início',
  'claimed' => 'Preparando a partida',
  'starting_engine' => 'Iniciando a simulação',
  'running' => 'Simulação em curso',
  'persisting_replay' => 'Salvando o replay',
  'cancel_pending' => 'Encerrando a partida',
  'completed' => 'Replay persistido',
  'censored' => 'Resultado censurado',
  'timeout' => 'Tempo esgotado',
  'coverage_error' => 'Cobertura insuficiente',
  'engine_error' => 'Falha do motor',
  'cancelled' => 'Execução cancelada',
  'persistence_error' => 'Falha ao persistir',
  _ => stage.replaceAll('_', ' '),
};

bool _isTransientEngineAssignment(BattleJob job) =>
    !job.isTerminal &&
    job.status == BattleJobStatus.running &&
    job.requestedEngine == BattleRequestedEngine.auto &&
    job.engine == null;

String _battleElapsedLabel(BattleJob job) {
  final startedAt = job.startedAt ?? job.createdAt;
  final endedAt = job.finishedAt ?? DateTime.now().toUtc();
  final rawElapsed = endedAt.difference(startedAt);
  final elapsed = rawElapsed.isNegative ? Duration.zero : rawElapsed;
  if (elapsed.inDays > 0) {
    return '${elapsed.inDays}d ${elapsed.inHours.remainder(24)}h';
  }
  if (elapsed.inHours > 0) {
    return '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}min';
  }
  if (elapsed.inMinutes > 0) {
    return '${elapsed.inMinutes}min ${elapsed.inSeconds.remainder(60)}s';
  }
  return '${elapsed.inSeconds}s';
}

String _terminalReasonCopy(
  String? reason, {
  BattleJobStatus? status,
  String? errorCode,
}) {
  final normalizedReason = reason?.trim().toLowerCase();
  final normalizedError = errorCode?.trim().toLowerCase();
  if (status == BattleJobStatus.timeout ||
      normalizedReason == 'timeout' ||
      normalizedReason == 'battle_job_timeout' ||
      normalizedError == 'battle_job_timeout' ||
      normalizedError == 'xmage_timeout') {
    return 'A simulação atingiu o limite de tempo antes de concluir. '
        'Prepare uma nova tentativa para executar novamente.';
  }
  if (normalizedReason == 'xmage_battle_operational_failure' ||
      normalizedError == 'xmage_battle_operational_failure' ||
      status == BattleJobStatus.engineError ||
      normalizedReason == 'engine_error') {
    return 'A simulação foi encerrada por uma falha temporária do motor. '
        'Nenhuma alteração foi feita no deck; tente novamente.';
  }
  return switch (normalizedReason) {
    'cancelled' => 'A execução foi cancelada antes da persistência do replay.',
    'coverage_error' =>
      'O motor não cobriu todas as regras necessárias para esta partida.',
    'persistence_error' =>
      'A execução terminou, mas o replay não foi persistido.',
    _ => 'A partida terminou sem uma referência pública de replay.',
  };
}

String _snapshotPosition(Map<String, dynamic> payload) {
  final turn = payload['turn'];
  final phase = _safeText(payload['phase']);
  final step = _safeText(payload['step']);
  return [
        if (turn is int) 'Turno $turn',
        if (phase != null) _titleCase(phase.replaceAll('_', ' ')),
        if (step != null) _titleCase(step.replaceAll('_', ' ')),
      ].join(' · ').trim().isEmpty
      ? 'Snapshot público'
      : [
          if (turn is int) 'Turno $turn',
          if (phase != null) _titleCase(phase.replaceAll('_', ' ')),
          if (step != null) _titleCase(step.replaceAll('_', ' ')),
        ].join(' · ');
}

String _eventTitle(Map<String, dynamic> event) {
  final type = _safeText(event['event_type']);
  return switch (type) {
    'ability_activated' => 'Habilidade ativada',
    'attacker_declared' => 'Atacante declarado',
    'battlefield_entry' => 'Entrada no campo',
    'blocker_declared' => 'Bloqueador declarado',
    'card_draw' => 'Compra registrada',
    'card_played' => 'Carta jogada',
    'combat_damage' => 'Dano de combate',
    'commander_cast' => 'Comandante conjurado',
    'counter_change' => 'Marcador alterado',
    'damage' => 'Dano',
    'game_started' => 'Partida iniciada',
    'land_played' => 'Terreno jogado',
    'life_change' => 'Total de vida alterado',
    'life_gain' => 'Ganho de vida',
    'life_loss' => 'Perda de vida',
    'phase_changed' => 'Mudança de fase',
    'resolve' => 'Objeto resolvido',
    'spell_cast' => 'Mágica conjurada',
    'stack_entry' => 'Entrada na pilha',
    'tap_change' => 'Estado de virar alterado',
    'turn_started' => 'Turno iniciado',
    'zone_transition' => 'Mudança de zona',
    _ => 'Evento público',
  };
}

String _eventDescription(Map<String, dynamic> event) {
  final message = _safeText(event['message']);
  if (message != null) return message;
  final actor = _safeText(event['actor']);
  final card = _safeText(event['card_name']);
  final turn = event['turn'];
  final lifeAfter = event['life_after'];
  final damage = event['damage'];
  final amount = event['amount'];
  final parts = <String>[
    if (turn is int) 'Turno $turn',
    if (actor != null) actor,
    if (card != null) card,
    if (damage is int) '$damage de dano',
    if (amount is int) 'valor $amount',
    if (lifeAfter is int) 'vida após: $lifeAfter',
  ];
  return parts.isEmpty
      ? 'Sem detalhes públicos adicionais.'
      : parts.join(' · ');
}

BattleLiveRecord? _latestSnapshot(List<BattleLiveRecord> records) {
  for (var index = records.length - 1; index >= 0; index -= 1) {
    if (records[index].kind == BattleLiveRecordKind.snapshot) {
      return records[index];
    }
  }
  return null;
}

List<Map<String, dynamic>> _publicMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (entry) => entry.map((key, nested) => MapEntry(key.toString(), nested)),
      )
      .toList(growable: false);
}

String _publicObjectName(Map<String, dynamic> object) =>
    _safeText(object['name']) ??
    _safeText(object['card_name']) ??
    'Objeto público';

String _combatSummary(Map<String, dynamic> combat) {
  final defender =
      _safeText(combat['defender_name']) ??
      _safeText(combat['defender_side']) ??
      'defensor';
  final attackers = _publicMapList(combat['attackers']).length;
  final blockers = _publicMapList(combat['blockers']).length;
  return '$attackers atacante(s) contra $defender · $blockers bloqueador(es)';
}

String? _safeText(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? _safeNumber(Object? value) => value is int ? '$value' : null;

String _shortId(String value) =>
    value.length <= 12 ? value : '${value.substring(0, 8)}…';

String _safeKey(String value) =>
    value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');

String _titleCase(String value) => value
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
