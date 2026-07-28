import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/launch_features.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../../core/widgets/mana_symbols.dart';
import '../../../core/widgets/manaloom_glyph.dart';
import '../../../core/widgets/manaloom_theme_motif.dart';
import '../models/battle_job.dart';
import '../models/battle_post_report.dart';
import '../models/battle_replay.dart';
import '../models/battle_replay_annotation.dart';
import '../models/battle_test_setup.dart';
import '../services/battle_job_gateway.dart';
import '../services/battle_job_series_runner.dart';
import '../services/battle_post_report_service.dart';
import '../services/battle_replay_service.dart';
import 'battle_live_spectator_screen.dart';

String battleReplaysRouteLocation(String deckId) =>
    '/decks/${Uri.encodeComponent(deckId)}/battle-replays';

Future<BattleTestSetup?> showBattleOpponentPicker({
  required BuildContext context,
  required BattleReplayGateway gateway,
  required String currentDeckId,
  bool allowSeries = false,
}) => showDialog<BattleTestSetup>(
  context: context,
  builder: (context) => _BattleOpponentPickerDialog(
    gateway: gateway,
    currentDeckId: currentDeckId,
    allowSeries: allowSeries,
  ),
);

enum _ReplayDetailView { timeline, decisions }

class BattleReplaysScreen extends StatefulWidget {
  const BattleReplaysScreen({
    super.key,
    required this.deckId,
    this.gateway,
    this.jobGateway,
    this.initialReplayId,
    this.battleLiveEnabled = LaunchFeatures.battleLiveSpectatorEnabled,
    this.interactiveBattleEnabled = LaunchFeatures.interactiveBattleEnabled,
  });

  final String deckId;
  final BattleReplayGateway? gateway;
  final BattleJobGateway? jobGateway;
  final String? initialReplayId;
  final bool battleLiveEnabled;
  final bool interactiveBattleEnabled;

  @override
  State<BattleReplaysScreen> createState() => _BattleReplaysScreenState();
}

class _BattleReplaysScreenState extends State<BattleReplaysScreen> {
  late final BattleReplayGateway _gateway;
  late final BattleJobGateway _jobGateway;

  bool _isLoading = true;
  bool _isRunning = false;
  bool _isStartingLive = false;
  bool _jobsLoading = false;
  bool _initialReplayConsumed = false;
  String? _error;
  String? _jobsError;
  List<BattleReplaySummary> _replays = const <BattleReplaySummary>[];
  List<BattleJob> _jobs = const <BattleJob>[];
  BattleReplayDetail? _selectedReplay;
  _ReplayDetailView _detailView = _ReplayDetailView.timeline;
  BattlePostReport? _comparisonBaseline;
  List<BattleReplayAnnotation> _annotations = const <BattleReplayAnnotation>[];
  bool _annotationsLoading = false;
  bool _annotationSaving = false;
  String? _annotationError;
  String? _annotationsReplayId;
  String _historyStatus = 'all';
  String _historyEngine = 'all';
  String _historyOpponent = 'all';
  String _historyRevision = 'all';
  String? _historyNextCursor;
  bool _historyHasMore = false;
  bool _historyLoadingMore = false;
  String? _pendingLiveRequestFingerprint;
  String? _pendingLiveIdempotencyKey;
  BattleJobSeriesProgress? _seriesProgress;
  BattleJobSeriesCancellation? _seriesCancellation;
  String? _seriesError;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? BattleReplayService();
    _jobGateway = widget.jobGateway ?? BattleJobGateway();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReplays());
    if (widget.battleLiveEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadJobs());
    }
  }

  Future<void> _loadReplays({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final page = await _gateway.listReplayPage(widget.deckId);
      final replays = page.items;
      if (!mounted) return;
      setState(() {
        _replays = replays;
        _historyNextCursor = page.nextCursor;
        _historyHasMore = page.hasMore;
        _historyLoadingMore = false;
        final engines = replays.map(_historyEngineValue).toSet();
        final opponents = replays.map(_historyOpponentValue).toSet();
        final revisions = replays.map(_historyRevisionValue).toSet();
        final statuses = replays.map((replay) => replay.status).toSet();
        if (!engines.contains(_historyEngine)) _historyEngine = 'all';
        if (!opponents.contains(_historyOpponent)) _historyOpponent = 'all';
        if (!revisions.contains(_historyRevision)) _historyRevision = 'all';
        if (!statuses.contains(_historyStatus)) _historyStatus = 'all';
        _isLoading = false;
        _error = null;
      });
      await _openInitialReplayIfNeeded();
    } catch (error) {
      if (!mounted) return;
      if (quiet) {
        setState(() {
          _isLoading = false;
          _historyLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Replay salvo, mas o historico nao foi atualizado. '
              'Tente atualizar novamente.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _isLoading = false;
        _historyLoadingMore = false;
        _error = _friendlyError(error);
      });
      await _openInitialReplayIfNeeded();
    }
  }

  Future<void> _openInitialReplayIfNeeded() async {
    final initialReplayId = widget.initialReplayId?.trim();
    if (_initialReplayConsumed ||
        initialReplayId == null ||
        initialReplayId.isEmpty) {
      return;
    }
    _initialReplayConsumed = true;
    await _openReplayId(initialReplayId);
  }

  Future<void> _loadMoreReplays() async {
    final cursor = _historyNextCursor;
    if (!_historyHasMore || cursor == null || _historyLoadingMore) return;
    setState(() {
      _historyLoadingMore = true;
      _error = null;
    });
    try {
      final page = await _gateway.listReplayPage(widget.deckId, cursor: cursor);
      if (!mounted) return;
      final merged = <String, BattleReplaySummary>{
        for (final replay in _replays) replay.id: replay,
        for (final replay in page.items) replay.id: replay,
      };
      setState(() {
        _replays = merged.values.toList(growable: false);
        _historyNextCursor = page.nextCursor;
        _historyHasMore = page.hasMore;
        _historyLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _historyLoadingMore = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  Future<void> _loadJobs({bool quiet = false}) async {
    if (!widget.battleLiveEnabled) return;
    if (!quiet) {
      setState(() {
        _jobsLoading = true;
        _jobsError = null;
      });
    }
    try {
      final jobs = await _jobGateway.list(limit: 8, deckId: widget.deckId);
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _jobsLoading = false;
        _jobsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _jobsLoading = false;
        _jobsError = _friendlyJobError(error);
      });
    }
  }

  Future<void> _refreshAll() async {
    final refreshes = <Future<void>>[_loadReplays()];
    if (widget.battleLiveEnabled) refreshes.add(_loadJobs());
    await Future.wait(refreshes);
  }

  Future<void> _openReplay(BattleReplaySummary summary) async {
    await _openReplayId(summary.id);
  }

  Future<void> _openReplayId(String replayId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _gateway.fetchReplay(
        deckId: widget.deckId,
        replayId: replayId,
      );
      if (!mounted) return;
      setState(() {
        _selectedReplay = detail;
        _detailView = _ReplayDetailView.timeline;
        _isLoading = false;
      });
      unawaited(_loadAnnotations(detail.summary.id));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _friendlyError(error);
      });
    }
  }

  Future<void> _runGoldfish() async {
    await _runSimulation(
      () => _gateway.runGoldfishSimulation(deckId: widget.deckId),
    );
  }

  Future<void> _runBattle() async {
    final setup = await _askBattleTestSetup();
    if (setup == null || setup.opponentDeckId.trim().isEmpty) return;
    await _runSimulation(
      () => _gateway.runBattleTest(deckId: widget.deckId, setup: setup),
    );
  }

  void _openBattleCoach() {
    context.push('/decks/${Uri.encodeComponent(widget.deckId)}/battle-coach');
  }

  Future<void> _runLiveBattle() async {
    final setup = await _askBattleTestSetup(allowSeries: true);
    if (setup == null || setup.opponentDeckId.trim().isEmpty) return;
    if (setup.seriesSize.isSeries) {
      await _runLiveSeries(setup);
      return;
    }
    final requestFingerprint = jsonEncode({
      'deck_id': widget.deckId,
      ...setup.toRequestJson(),
    });
    final idempotencyKey =
        _pendingLiveRequestFingerprint == requestFingerprint &&
            _pendingLiveIdempotencyKey != null
        ? _pendingLiveIdempotencyKey!
        : ApiClient.generateRequestId();
    _pendingLiveRequestFingerprint = requestFingerprint;
    _pendingLiveIdempotencyKey = idempotencyKey;
    setState(() {
      _isStartingLive = true;
      _jobsError = null;
    });
    try {
      final creation = await _jobGateway.create(
        BattleJobCreateRequest(
          deckId: widget.deckId,
          setup: setup,
          idempotencyKey: idempotencyKey,
        ),
      );
      if (!mounted) return;
      _pendingLiveRequestFingerprint = null;
      _pendingLiveIdempotencyKey = null;
      setState(() {
        _isStartingLive = false;
        _jobs = [
          creation.job,
          ..._jobs.where((job) => job.jobId != creation.job.jobId),
        ];
      });
      await context.push<void>(
        battleLiveRouteLocation(widget.deckId, creation.job.jobId),
      );
      if (mounted) unawaited(_loadJobs(quiet: true));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isStartingLive = false;
        _jobsError = _friendlyJobError(error);
      });
    }
  }

  Future<void> _runLiveSeries(BattleTestSetup setup) async {
    final cancellation = BattleJobSeriesCancellation();
    final runner = BattleJobSeriesRunner(gateway: _jobGateway);
    final seriesId = ApiClient.generateRequestId();
    setState(() {
      _isStartingLive = true;
      _seriesCancellation = cancellation;
      _seriesProgress = null;
      _seriesError = null;
      _jobsError = null;
    });

    void updateSeries(BattleJobSeriesProgress progress) {
      if (!mounted) return;
      final seriesJobs = progress.attempts.map((attempt) => attempt.job);
      final seriesJobIds = seriesJobs.map((job) => job.jobId).toSet();
      setState(() {
        _seriesProgress = progress;
        _jobs = [
          ...seriesJobs.toList().reversed,
          ..._jobs.where((job) => !seriesJobIds.contains(job.jobId)),
        ];
      });
    }

    try {
      final result = await runner.run(
        seriesId: seriesId,
        deckId: widget.deckId,
        setup: setup,
        cancellation: cancellation,
        onProgress: updateSeries,
      );
      if (!mounted) return;
      setState(() {
        _isStartingLive = false;
        _seriesProgress = result;
        _seriesCancellation = null;
      });
      final message = result.cancellationRequested
          ? 'Série interrompida. Jobs já criados continuam no histórico.'
          : 'Série encerrada: ${result.terminalCount}/${result.total} '
                'tentativas finalizadas. Confira cada status.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      unawaited(_loadJobs(quiet: true));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isStartingLive = false;
        _seriesCancellation = null;
        _seriesError = _friendlyJobError(error);
      });
    }
  }

  void _cancelLiveSeries() {
    final cancellation = _seriesCancellation;
    if (cancellation == null || cancellation.isCancellationRequested) return;
    cancellation.requestCancellation();
    setState(() {});
  }

  void _dismissLiveSeries() {
    if (_isStartingLive) return;
    setState(() {
      _seriesProgress = null;
      _seriesError = null;
    });
  }

  Future<void> _openLiveJob(BattleJob job) async {
    await context.push<void>(battleLiveRouteLocation(widget.deckId, job.jobId));
    if (mounted) unawaited(_loadJobs(quiet: true));
  }

  Future<void> _runSimulation(
    Future<BattleReplayDetail> Function() runner,
  ) async {
    setState(() {
      _isRunning = true;
      _error = null;
    });

    try {
      final detail = await runner();
      if (!mounted) return;
      setState(() {
        _selectedReplay = detail;
        _detailView = _ReplayDetailView.timeline;
        _isRunning = false;
      });
      unawaited(_loadAnnotations(detail.summary.id));
      await _loadReplays(quiet: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _error = _friendlyError(error);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<BattleTestSetup?> _askBattleTestSetup({bool allowSeries = false}) =>
      showBattleOpponentPicker(
        context: context,
        gateway: _gateway,
        currentDeckId: widget.deckId,
        allowSeries: allowSeries,
      );

  Future<void> _recordMulliganDecision(
    _OpeningHandExercise exercise,
    String choice,
  ) async {
    await _saveAnnotation(
      BattleReplayAnnotationDraft(
        kind: BattleReplayAnnotationKind.mulliganDecision,
        snapshotRef: 'snapshot:${exercise.snapshotPosition}',
        payload: {
          'choice': choice,
          'hand_size': exercise.handSize,
          'mulligan_number': exercise.mulliganNumber,
        },
      ),
      successMessage:
          'Escolha registrada antes da leitura detalhada. Ela não alterou o motor automático.',
    );
  }

  Future<void> _loadAnnotations(String replayId) async {
    setState(() {
      _annotationsReplayId = replayId;
      _annotations = const <BattleReplayAnnotation>[];
      _annotationsLoading = true;
      _annotationError = null;
    });
    try {
      final annotations = await _gateway.listReplayAnnotations(
        deckId: widget.deckId,
        replayId: replayId,
      );
      if (!mounted || _selectedReplay?.summary.id != replayId) return;
      setState(() {
        _annotations = annotations;
        _annotationsLoading = false;
        _annotationError = null;
      });
    } catch (error) {
      if (!mounted || _selectedReplay?.summary.id != replayId) return;
      setState(() {
        _annotationsLoading = false;
        _annotationError = _friendlyError(error);
      });
    }
  }

  Future<void> _saveAnnotation(
    BattleReplayAnnotationDraft draft, {
    String successMessage = 'Anotação salva no histórico deste replay.',
  }) async {
    final replayId = _selectedReplay?.summary.id;
    if (replayId == null || _annotationSaving) return;
    setState(() {
      _annotationSaving = true;
      _annotationError = null;
    });
    try {
      final annotation = await _gateway.createReplayAnnotation(
        deckId: widget.deckId,
        replayId: replayId,
        draft: draft,
      );
      if (!mounted || _selectedReplay?.summary.id != replayId) return;
      setState(() {
        _annotations = [
          annotation,
          ..._annotations.where((item) => item.id != annotation.id),
        ];
        _annotationSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted || _selectedReplay?.summary.id != replayId) return;
      setState(() {
        _annotationSaving = false;
        _annotationError = _friendlyError(error);
      });
    }
  }

  Future<void> _deleteAnnotation(BattleReplayAnnotation annotation) async {
    final replayId = _selectedReplay?.summary.id;
    if (replayId == null || _annotationSaving) return;
    setState(() {
      _annotationSaving = true;
      _annotationError = null;
    });
    try {
      final deleted = await _gateway.deleteReplayAnnotation(
        deckId: widget.deckId,
        replayId: replayId,
        annotationId: annotation.id,
      );
      if (!mounted || _selectedReplay?.summary.id != replayId) return;
      setState(() {
        if (deleted) {
          _annotations = _annotations
              .where((item) => item.id != annotation.id)
              .toList(growable: false);
        }
        _annotationSaving = false;
      });
    } catch (error) {
      if (!mounted || _selectedReplay?.summary.id != replayId) return;
      setState(() {
        _annotationSaving = false;
        _annotationError = _friendlyError(error);
      });
    }
  }

  Future<void> _addReplayNote() async {
    final result = await _showBattleNoteDialog(context);
    if (result == null) return;
    await _saveAnnotation(
      BattleReplayAnnotationDraft(
        kind: BattleReplayAnnotationKind.note,
        payload: {
          'text': result.text,
          if (result.title != null) 'title': result.title,
        },
      ),
    );
  }

  Future<void> _recordWouldDoDifferently(int eventIndex) async {
    final result = await _showBattleReflectionDialog(context);
    if (result == null) return;
    await _saveAnnotation(
      BattleReplayAnnotationDraft(
        kind: BattleReplayAnnotationKind.wouldDoDifferently,
        eventRef: 'event:$eventIndex',
        payload: {
          'stance': result.stance,
          if (result.reason != null) 'reason': result.reason,
        },
      ),
      successMessage:
          'Reflexão salva antes de avançar; o replay original não foi alterado.',
    );
  }

  Future<void> _reportReplayEvent(int eventIndex) async {
    final result = await _showBattleEventReportDialog(context);
    if (result == null) return;
    await _saveAnnotation(
      BattleReplayAnnotationDraft(
        kind: BattleReplayAnnotationKind.eventReport,
        eventRef: 'event:$eventIndex',
        payload: {
          'reason_code': result.reasonCode,
          if (result.details != null) 'details': result.details,
        },
      ),
      successMessage: 'Evento reportado sem alterar o replay.',
    );
  }

  String _friendlyError(Object error) {
    if (error is BattleReplayException) return error.message;
    return 'Nao foi possivel carregar as simulacoes.';
  }

  String _friendlyJobError(Object error) {
    if (error is BattleJobGatewayException) return error.message;
    return 'Não foi possível atualizar os Battles ao vivo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('battle-replays-screen'),
      appBar: AppBar(
        title: const Text('Battle e replays'),
        actions: [
          IconButton(
            key: const Key('battle-replays-refresh-button'),
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isRunning || _isStartingLive ? null : _refreshAll,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          key: const Key('battle-replays-workspace'),
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                _BattleReplayActions(
                  isRunning: _isRunning || _isStartingLive,
                  onRunGoldfish: _runGoldfish,
                  onRunBattle: _runBattle,
                  onRunLive: widget.battleLiveEnabled ? _runLiveBattle : null,
                  onOpenCoach: widget.interactiveBattleEnabled
                      ? _openBattleCoach
                      : null,
                  isStartingLive: _isStartingLive,
                ),
                if (_seriesProgress != null || _seriesError != null)
                  _BattleSeriesProgressPanel(
                    progress: _seriesProgress,
                    error: _seriesError,
                    running: _isStartingLive,
                    cancellationRequested:
                        _seriesCancellation?.isCancellationRequested ?? false,
                    onCancel: _cancelLiveSeries,
                    onDismiss: _dismissLiveSeries,
                  ),
                if (widget.battleLiveEnabled &&
                    _seriesProgress == null &&
                    _seriesError == null)
                  _BattleLiveJobStrip(
                    jobs: _jobs,
                    loading: _jobsLoading,
                    error: _jobsError,
                    onRetry: _loadJobs,
                    onOpen: _openLiveJob,
                  ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppStatePanel.loading(
        key: Key('battle-replays-loading-state'),
        title: 'Carregando replays',
        message: 'Buscando simulacoes salvas e trilhas de decisao do deck.',
        accent: AppTheme.frost400,
      );
    }

    if (_error != null) {
      return AppStatePanel(
        key: const Key('battle-replays-error-state'),
        icon: Icons.error_outline_rounded,
        title: 'Nao foi possivel carregar battle',
        message: _error,
        accent: Theme.of(context).colorScheme.error,
        actionLabel: 'Tentar novamente',
        onAction: _loadReplays,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= AppTheme.breakpointExpanded;
        final selectedReplay = _selectedReplay;

        if (isDesktop && (_replays.isNotEmpty || selectedReplay != null)) {
          return _buildMasterDetail(selectedReplay);
        }

        if (selectedReplay != null) {
          return _buildDetailPane(selectedReplay);
        }

        if (_replays.isEmpty) return _buildEmptyState();
        return _buildReplayList();
      },
    );
  }

  Widget _buildMasterDetail(BattleReplayDetail? selectedReplay) {
    return Row(
      key: const Key('battle-replays-master-detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const Key('battle-replays-history-pane'),
          width: 344,
          child: _replays.isEmpty
              ? _buildEmptyState()
              : _buildReplayList(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space12,
                    AppTheme.space12,
                    AppTheme.space12,
                    AppTheme.space24,
                  ),
                ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.outlineMuted.withValues(alpha: 0.52),
        ),
        const SizedBox(width: AppTheme.paneGap),
        Expanded(
          child: selectedReplay == null
              ? const _ReplaySelectionEmpty()
              : _buildDetailPane(selectedReplay, showBack: false),
        ),
      ],
    );
  }

  Widget _buildDetailPane(BattleReplayDetail detail, {bool showBack = true}) {
    final openingHand = _openingHandExercise(detail);
    if (openingHand != null) {
      final annotationsMatch = _annotationsReplayId == detail.summary.id;
      final annotationsReady = annotationsMatch && !_annotationsLoading;
      final hasDecision =
          annotationsReady &&
          _annotations.any(
            (annotation) =>
                annotation.kind ==
                    BattleReplayAnnotationKind.mulliganDecision &&
                annotation.snapshotRef ==
                    'snapshot:${openingHand.snapshotPosition}',
          );
      if (!hasDecision) {
        return _BattleOpeningHandGate(
          exercise: openingHand,
          loading: !annotationsMatch || _annotationsLoading,
          saving: _annotationSaving,
          error: annotationsMatch ? _annotationError : null,
          onReload: () => _loadAnnotations(detail.summary.id),
          onKeep: () => _recordMulliganDecision(openingHand, 'keep'),
          onMulligan: () => _recordMulliganDecision(openingHand, 'mulligan'),
          onBack: () => setState(() => _selectedReplay = null),
          showBack: showBack,
        );
      }
    }

    final report = const BattlePostReportService().build(detail);
    return _BattleReplayDetailPane(
      detail: detail,
      report: report,
      comparisonBaseline: _comparisonBaseline,
      onUseAsComparisonBaseline: () {
        setState(() => _comparisonBaseline = report);
      },
      onClearComparisonBaseline: () {
        setState(() => _comparisonBaseline = null);
      },
      annotations: _annotationsReplayId == detail.summary.id
          ? _annotations
          : const <BattleReplayAnnotation>[],
      annotationsLoading:
          _annotationsReplayId == detail.summary.id && _annotationsLoading,
      annotationSaving: _annotationSaving,
      annotationError: _annotationsReplayId == detail.summary.id
          ? _annotationError
          : null,
      onReloadAnnotations: () => _loadAnnotations(detail.summary.id),
      onAddNote: _addReplayNote,
      onAddBookmark: () => _saveAnnotation(
        const BattleReplayAnnotationDraft(
          kind: BattleReplayAnnotationKind.bookmark,
          payload: {'label': 'Revisar este replay'},
        ),
      ),
      onHelpful: (helpful) => _saveAnnotation(
        BattleReplayAnnotationDraft(
          kind: BattleReplayAnnotationKind.helpfulFeedback,
          payload: {'helpful': helpful, 'surface': 'post_battle_report'},
        ),
        successMessage: 'Obrigado. O feedback foi salvo com este replay.',
      ),
      onDeleteAnnotation: _deleteAnnotation,
      onReflectAtEvent: _recordWouldDoDifferently,
      onReportEvent: _reportReplayEvent,
      view: _detailView,
      onViewChanged: (view) => setState(() => _detailView = view),
      onBack: () => setState(() => _selectedReplay = null),
      showBack: showBack,
    );
  }

  Widget _buildEmptyState() {
    return AppStatePanel(
      key: const Key('battle-replays-empty-state'),
      iconWidget: const ManaLoomGlyph(ManaLoomGlyphKind.battleReplay),
      title: 'Nenhum replay salvo',
      message:
          'Rode uma simulacao para criar historico. Cada replay informa o motor e o contrato de execucao usados.',
      accent: AppTheme.brass400,
      actionLabel: 'Rodar goldfish',
      onAction: _runGoldfish,
      motif: ManaLoomMotifVariant.battlefield,
    );
  }

  Widget _buildReplayList({
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(
      AppTheme.space16,
      AppTheme.space12,
      AppTheme.space16,
      AppTheme.space24,
    ),
  }) {
    final filtered = _replays
        .where((replay) {
          if (_historyStatus != 'all' && replay.status != _historyStatus) {
            return false;
          }
          if (_historyEngine != 'all' &&
              _historyEngineValue(replay) != _historyEngine) {
            return false;
          }
          if (_historyOpponent != 'all' &&
              _historyOpponentValue(replay) != _historyOpponent) {
            return false;
          }
          if (_historyRevision != 'all' &&
              _historyRevisionValue(replay) != _historyRevision) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _loadReplays,
      child: ListView.builder(
        key: const Key('battle-replays-history-list'),
        padding: padding,
        itemCount: filtered.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space10),
              child: _BattleHistoryFilters(
                replays: _replays,
                filteredCount: filtered.length,
                status: _historyStatus,
                engine: _historyEngine,
                opponent: _historyOpponent,
                revision: _historyRevision,
                onStatusChanged: (value) =>
                    setState(() => _historyStatus = value),
                onEngineChanged: (value) =>
                    setState(() => _historyEngine = value),
                onOpponentChanged: (value) =>
                    setState(() => _historyOpponent = value),
                onRevisionChanged: (value) =>
                    setState(() => _historyRevision = value),
                onClear: () {
                  setState(() {
                    _historyStatus = 'all';
                    _historyEngine = 'all';
                    _historyOpponent = 'all';
                    _historyRevision = 'all';
                  });
                },
              ),
            );
          }
          if (filtered.isEmpty) {
            return const _InlineEmptyPanel(
              key: Key('battle-history-filter-empty'),
              icon: Icons.filter_alt_off_outlined,
              title: 'Nenhum replay corresponde aos filtros',
              message:
                  'Limpe um ou mais filtros. O histórico salvo não foi removido.',
            );
          }
          if (index == filtered.length + 1) {
            if (!_historyHasMore) {
              return const SizedBox(height: AppTheme.space2);
            }
            return Center(
              child: OutlinedButton.icon(
                key: const Key('battle-history-load-more'),
                onPressed: _historyLoadingMore ? null : _loadMoreReplays,
                icon: _historyLoadingMore
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(
                  _historyLoadingMore
                      ? 'Carregando histórico'
                      : 'Carregar mais replays',
                ),
              ),
            );
          }
          final replay = filtered[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space10),
            child: _BattleReplaySummaryTile(
              replay: replay,
              selected: replay.id == _selectedReplay?.summary.id,
              onTap: () => _openReplay(replay),
            ),
          );
        },
      ),
    );
  }
}

String _historyEngineValue(BattleReplaySummary replay) {
  final value = replay.raw['engine']?.toString().trim();
  return value == null || value.isEmpty ? 'unknown' : value;
}

String _historyOpponentValue(BattleReplaySummary replay) {
  final id = replay.opponentDeckId?.trim();
  if (id != null && id.isNotEmpty) return id;
  final name = replay.opponentName?.trim();
  return name == null || name.isEmpty ? 'unknown' : 'name:$name';
}

String _historyRevisionValue(BattleReplaySummary replay) {
  final revision = replay.raw['deck_revision'];
  if (revision is Map) {
    final hash = revision['subject_deck_hash']?.toString().trim();
    if (hash != null && hash.isNotEmpty) return hash;
    final compatibility = revision['compatibility']?.toString().trim();
    if (compatibility != null && compatibility.isNotEmpty) {
      return compatibility;
    }
  }
  return 'legacy_unknown';
}

class _BattleHistoryFilters extends StatelessWidget {
  const _BattleHistoryFilters({
    required this.replays,
    required this.filteredCount,
    required this.status,
    required this.engine,
    required this.opponent,
    required this.revision,
    required this.onStatusChanged,
    required this.onEngineChanged,
    required this.onOpponentChanged,
    required this.onRevisionChanged,
    required this.onClear,
  });

  final List<BattleReplaySummary> replays;
  final int filteredCount;
  final String status;
  final String engine;
  final String opponent;
  final String revision;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onEngineChanged;
  final ValueChanged<String> onOpponentChanged;
  final ValueChanged<String> onRevisionChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final statusOptions =
        replays.map((replay) => replay.status).toSet().toList()..sort();
    final engineOptions = replays.map(_historyEngineValue).toSet().toList()
      ..sort();
    final opponentOptions = replays.map(_historyOpponentValue).toSet().toList()
      ..sort();
    final revisionOptions = replays.map(_historyRevisionValue).toSet().toList()
      ..sort();
    final opponentsByValue = <String, String>{
      for (final replay in replays)
        _historyOpponentValue(
          replay,
        ): replay.opponentName?.trim().isNotEmpty == true
            ? replay.opponentName!.trim()
            : 'Oponente não identificado',
    };
    final hasActiveFilter =
        status != 'all' ||
        engine != 'all' ||
        opponent != 'all' ||
        revision != 'all';

    return Material(
      key: const Key('battle-history-filters'),
      color: AppTheme.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.52)),
      ),
      child: ExpansionTile(
        key: const Key('battle-history-filters-expansion'),
        leading: const Icon(Icons.filter_list_rounded),
        title: const Text('Filtrar histórico'),
        subtitle: Text('$filteredCount de ${replays.length} replays'),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTheme.space12,
          AppTheme.space0,
          AppTheme.space12,
          AppTheme.space12,
        ),
        children: [
          _BattleHistoryDropdown(
            key: ValueKey('battle-history-status-$status'),
            fieldKey: const Key('battle-history-status-filter'),
            label: 'Status',
            value: status,
            options: statusOptions,
            labelFor: _historyStatusLabel,
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: AppTheme.space8),
          _BattleHistoryDropdown(
            key: ValueKey('battle-history-engine-$engine'),
            fieldKey: const Key('battle-history-engine-filter'),
            label: 'Motor',
            value: engine,
            options: engineOptions,
            labelFor: _historyEngineLabel,
            onChanged: onEngineChanged,
          ),
          const SizedBox(height: AppTheme.space8),
          _BattleHistoryDropdown(
            key: ValueKey('battle-history-opponent-$opponent'),
            fieldKey: const Key('battle-history-opponent-filter'),
            label: 'Adversário',
            value: opponent,
            options: opponentOptions,
            labelFor: (value) => value == 'all'
                ? 'Todos os adversários'
                : opponentsByValue[value]!,
            onChanged: onOpponentChanged,
          ),
          const SizedBox(height: AppTheme.space8),
          _BattleHistoryDropdown(
            key: ValueKey('battle-history-revision-$revision'),
            fieldKey: const Key('battle-history-revision-filter'),
            label: 'Revisão do deck',
            value: revision,
            options: revisionOptions,
            labelFor: _historyRevisionLabel,
            onChanged: onRevisionChanged,
          ),
          if (hasActiveFilter) ...[
            const SizedBox(height: AppTheme.space8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('battle-history-clear-filters'),
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Limpar filtros'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BattleHistoryDropdown extends StatelessWidget {
  const _BattleHistoryDropdown({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final String value;
  final List<String> options;
  final String Function(String) labelFor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: fieldKey,
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(value: 'all', child: Text(labelFor('all'))),
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(
              labelFor(option),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

String _historyStatusLabel(String value) => switch (value) {
  'all' => 'Todos os status',
  'completed' || 'success' => 'Concluído',
  'censored' => 'Censurado',
  'timeout' => 'Timeout',
  'coverage_error' => 'Sem cobertura',
  'engine_error' => 'Falha do motor',
  'cancelled' => 'Cancelado',
  'persistence_error' => 'Falha ao salvar',
  _ => value.replaceAll('_', ' '),
};

String _historyEngineLabel(String value) => switch (value) {
  'all' => 'Todos os motores',
  'xmage' => 'XMage',
  'forge' => 'Forge',
  'manaloom_native_reviewed' || 'native' => 'ManaLoom nativo',
  'unknown' => 'Motor não informado',
  _ => value,
};

String _historyRevisionLabel(String value) {
  if (value == 'all') return 'Todas as revisões';
  if (value == 'legacy_unknown') return 'Legado · revisão desconhecida';
  return 'Hash ${_shortIdentity(value)}';
}

class _BattleOpponentPickerDialog extends StatefulWidget {
  const _BattleOpponentPickerDialog({
    required this.gateway,
    required this.currentDeckId,
    this.allowSeries = false,
  });

  final BattleReplayGateway gateway;
  final String currentDeckId;
  final bool allowSeries;

  @override
  State<_BattleOpponentPickerDialog> createState() =>
      _BattleOpponentPickerDialogState();
}

class _BattleOpponentPickerDialogState
    extends State<_BattleOpponentPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _technicalIdController = TextEditingController();
  final TextEditingController _focusCardsController = TextEditingController();

  bool _isLoading = true;
  bool _showTechnicalId = false;
  bool _isCheckingPreflight = false;
  String? _error;
  String? _manualError;
  String? _selectedDeckId;
  String? _preflightOpponentId;
  BattlePreflight? _preflight;
  BattleTestObjective _objective = BattleTestObjective.general;
  BattleSeriesSize _seriesSize = BattleSeriesSize.single;
  List<BattleOpponentDeck> _decks = const <BattleOpponentDeck>[];

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _technicalIdController.dispose();
    _focusCardsController.dispose();
    super.dispose();
  }

  Future<void> _loadDecks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final decks = await widget.gateway.listOpponentDecks(
        currentDeckId: widget.currentDeckId,
      );
      if (!mounted) return;
      setState(() {
        _decks = decks;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error is BattleReplayException
            ? error.message
            : 'Nao foi possivel carregar os decks adversarios.';
      });
    }
  }

  Future<void> _selectDeck(String deckId) async {
    setState(() {
      _selectedDeckId = deckId;
      _showTechnicalId = false;
      _manualError = null;
    });
    await _loadPreflight(deckId);
  }

  Future<void> _selectSearchResult(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final matches = _decks
        .where((deck) => deck.matches(query))
        .toList(growable: false);
    final exactMatches = matches
        .where((deck) => deck.name.trim().toLowerCase() == normalizedQuery)
        .toList(growable: false);
    final candidate = exactMatches.length == 1
        ? exactMatches.single
        : matches.length == 1
        ? matches.single
        : null;
    if (candidate == null) return;
    await _selectDeck(candidate.id);
  }

  Future<BattlePreflight?> _loadPreflight(String opponentDeckId) async {
    setState(() {
      _isCheckingPreflight = true;
      _preflight = null;
      _preflightOpponentId = opponentDeckId;
      _manualError = null;
    });
    try {
      final result = await widget.gateway.loadBattlePreflight(
        deckId: widget.currentDeckId,
        opponentDeckId: opponentDeckId,
      );
      if (!mounted || _preflightOpponentId != opponentDeckId) return null;
      setState(() {
        _preflight = result;
        _isCheckingPreflight = false;
      });
      return result;
    } catch (error) {
      if (!mounted || _preflightOpponentId != opponentDeckId) return null;
      setState(() {
        _isCheckingPreflight = false;
        _manualError = error is BattleReplayException
            ? error.message
            : 'Nao foi possivel verificar os decks.';
      });
      return null;
    }
  }

  Future<void> _submit() async {
    final opponentDeckId = _showTechnicalId
        ? _technicalIdController.text.trim()
        : _selectedDeckId?.trim() ?? '';
    if (!_isUuid(opponentDeckId)) {
      setState(() {
        _manualError = 'Informe um UUID de deck valido.';
      });
      return;
    }

    var preflight = _preflightOpponentId == opponentDeckId ? _preflight : null;
    preflight ??= await _loadPreflight(opponentDeckId);
    if (!mounted || preflight == null || !preflight.canStart) return;

    final focusCards = _focusCardsController.text
        .split(RegExp(r'[,;\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    Navigator.of(context).pop(
      BattleTestSetup(
        opponentDeckId: opponentDeckId,
        objective: _objective,
        seriesSize: _seriesSize,
        focusCards: focusCards,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchController.text;
    final visibleDecks = _decks
        .where((deck) => deck.matches(query))
        .toList(growable: false);
    final ownCount = _decks.where((deck) => deck.isOwn).length;
    final publicCount = _decks.length - ownCount;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final contentHeight = (availableHeight - 170).clamp(300.0, 680.0);
    final deckBodyHeight = (availableHeight * 0.28).clamp(150.0, 260.0);
    final selectedId = _showTechnicalId
        ? _technicalIdController.text.trim()
        : _selectedDeckId;
    final hasCandidate =
        selectedId != null &&
        (_showTechnicalId ? selectedId.isNotEmpty : _isUuid(selectedId));
    final canSubmit =
        hasCandidate &&
        !_isCheckingPreflight &&
        (_preflightOpponentId != selectedId || _preflight?.canStart == true);

    return AlertDialog(
      key: const Key('battle-opponent-picker-dialog'),
      title: const Text('Escolha o deck adversario'),
      content: SizedBox(
        width: 560,
        height: contentHeight,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.allowSeries
                    ? 'Selecione um deck e quantas tentativas independentes deseja enfileirar.'
                    : 'Selecione um deck seu ou publico. O replay sera salvo no historico ao concluir.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppTheme.space14),
              if (!_isLoading && _error == null && _decks.isNotEmpty) ...[
                TextField(
                  key: const Key('battle-opponent-search-field'),
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Buscar adversario',
                    hintText: 'Nome, comandante ou formato',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _selectSearchResult,
                ),
                const SizedBox(height: AppTheme.space10),
                Text(
                  '$ownCount meus · $publicCount publicos',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textHint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
              ],
              SizedBox(
                height: deckBodyHeight,
                child: _buildDeckBody(
                  context,
                  visibleDecks: visibleDecks,
                  query: query,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              TextButton.icon(
                key: const Key('battle-opponent-technical-toggle'),
                onPressed: () {
                  setState(() {
                    _showTechnicalId = !_showTechnicalId;
                    _manualError = null;
                    _preflight = null;
                    _preflightOpponentId = null;
                  });
                },
                icon: Icon(
                  _showTechnicalId
                      ? Icons.expand_less_rounded
                      : Icons.data_object_rounded,
                ),
                label: Text(
                  _showTechnicalId ? 'Ocultar ID tecnico' : 'Usar ID tecnico',
                ),
              ),
              if (_showTechnicalId) ...[
                const SizedBox(height: AppTheme.space6),
                TextField(
                  key: const Key('battle-opponent-deck-id-field'),
                  controller: _technicalIdController,
                  decoration: InputDecoration(
                    labelText: 'UUID do deck adversario',
                    hintText: '00000000-0000-0000-0000-000000000000',
                    errorText: _manualError,
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    _preflight = null;
                    _preflightOpponentId = null;
                    if (_manualError != null) {
                      setState(() => _manualError = null);
                    } else {
                      setState(() {});
                    }
                  },
                  onSubmitted: (_) => _submit(),
                ),
              ],
              const SizedBox(height: AppTheme.space10),
              DropdownButtonFormField<BattleTestObjective>(
                key: const Key('battle-test-objective-field'),
                initialValue: _objective,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'O que voce quer observar?',
                  prefixIcon: Icon(Icons.track_changes_rounded),
                ),
                items: BattleTestObjective.values
                    .map(
                      (objective) => DropdownMenuItem(
                        value: objective,
                        child: Text(
                          objective.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _objective = value);
                },
              ),
              const SizedBox(height: AppTheme.space10),
              TextField(
                key: const Key('battle-focus-cards-field'),
                controller: _focusCardsController,
                decoration: const InputDecoration(
                  labelText: 'Cartas de foco (opcional)',
                  hintText: 'Ate 3 nomes, separados por virgula',
                  prefixIcon: Icon(Icons.center_focus_strong_rounded),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: AppTheme.space5),
              Text(
                'O foco organiza as observacoes; nao força compra, uso ou resultado.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textHint,
                  height: 1.3,
                ),
              ),
              if (widget.allowSeries) ...[
                const SizedBox(height: AppTheme.space10),
                DropdownButtonFormField<BattleSeriesSize>(
                  key: const Key('battle-series-size-field'),
                  initialValue: _seriesSize,
                  decoration: const InputDecoration(
                    labelText: 'Tamanho da amostra',
                    prefixIcon: Icon(Icons.stacked_line_chart_rounded),
                  ),
                  items: BattleSeriesSize.values
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text(size.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _seriesSize = value);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.space5),
                Text(
                  'Séries usam um seed e uma chave de idempotência diferentes '
                  'por tentativa. São amostras independentes: não há RNG '
                  'pareado, escolha automática de vencedor ou promoção de troca.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textHint,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.space8),
              _BattlePreflightPanel(
                loading: _isCheckingPreflight,
                preflight: _preflight,
                error: _preflightOpponentId == null ? null : _manualError,
              ),
              const SizedBox(height: AppTheme.space8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const Key('battle-opponent-submit-button'),
          onPressed: canSubmit ? _submit : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            _seriesSize.isSeries
                ? 'Iniciar série de ${_seriesSize.count}'
                : 'Simular Battle',
          ),
        ),
      ],
    );
  }

  Widget _buildDeckBody(
    BuildContext context, {
    required List<BattleOpponentDeck> visibleDecks,
    required String query,
  }) {
    if (_isLoading) {
      return const Center(
        key: Key('battle-opponent-loading-state'),
        child: CircularProgressIndicator(),
      );
    }
    if (_error != null) {
      return Center(
        key: const Key('battle-opponent-error-state'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppTheme.error,
              size: 30,
            ),
            const SizedBox(height: AppTheme.space10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.space10),
            OutlinedButton.icon(
              key: const Key('battle-opponent-retry-button'),
              onPressed: _loadDecks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (_decks.isEmpty) {
      return const Center(
        key: Key('battle-opponent-empty-state'),
        child: Text(
          'Nenhum outro deck com cartas foi encontrado.\nVoce ainda pode usar um ID tecnico.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    if (visibleDecks.isEmpty) {
      return Center(
        key: const Key('battle-opponent-search-empty-state'),
        child: Text(
          'Nenhum deck encontrado para “${query.trim()}”.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      key: const Key('battle-opponent-deck-list'),
      itemCount: visibleDecks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final deck = visibleDecks[index];
        final selected = deck.id == _selectedDeckId;
        final beginsSection =
            index == 0 || visibleDecks[index - 1].isOwn != deck.isOwn;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (beginsSection)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space4,
                  index == AppTheme.space0 ? AppTheme.space4 : AppTheme.space14,
                  AppTheme.space4,
                  AppTheme.space6,
                ),
                child: Text(
                  deck.isOwn ? 'MEUS DECKS' : 'DECKS PUBLICOS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.frost400,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            Semantics(
              selected: selected,
              button: true,
              label: '${deck.name}, ${deck.supportingLabel}',
              child: ListTile(
                key: Key('battle-opponent-deck-${deck.id}'),
                selected: selected,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                ),
                leading: Icon(
                  deck.isOwn ? Icons.style_outlined : Icons.public_rounded,
                  color: selected ? AppTheme.brass400 : AppTheme.frost400,
                ),
                title: Text(
                  deck.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${deck.supportingLabel}\n${deck.metadataLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppTheme.brass400 : AppTheme.textHint,
                ),
                onTap: () {
                  _selectDeck(deck.id);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BattlePreflightPanel extends StatelessWidget {
  const _BattlePreflightPanel({
    required this.loading,
    required this.preflight,
    required this.error,
  });

  final bool loading;
  final BattlePreflight? preflight;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Semantics(
        liveRegion: true,
        label: 'Verificando cobertura dos decks',
        child: const LinearProgressIndicator(
          key: Key('battle-preflight-loading'),
          minHeight: 3,
        ),
      );
    }
    if (error != null) {
      return _BattlePreflightMessage(
        key: const Key('battle-preflight-error'),
        icon: Icons.error_outline_rounded,
        color: AppTheme.error,
        title: 'Preflight indisponivel',
        message: error!,
      );
    }
    final value = preflight;
    if (value == null) {
      return const _BattlePreflightMessage(
        key: Key('battle-preflight-idle'),
        icon: Icons.shield_outlined,
        color: AppTheme.textHint,
        title: 'Selecione um adversario',
        message:
            'Validacao, revisao do deck e cobertura do motor serao verificadas antes de iniciar.',
      );
    }

    final coverage = value.engineCoverage.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' · ');
    return _BattlePreflightMessage(
      key: Key(
        value.canStart ? 'battle-preflight-ready' : 'battle-preflight-blocked',
      ),
      icon: value.canStart
          ? Icons.verified_outlined
          : Icons.warning_amber_rounded,
      color: value.canStart ? AppTheme.success : AppTheme.warning,
      title: value.canStart ? 'Pronto para Battle' : 'Battle bloqueada',
      message: value.canStart
          ? '${value.cardCount} cartas · cobertura $coverage'
          : _battlePreflightBlockerMessage(value.blockers),
    );
  }
}

class _BattlePreflightMessage extends StatelessWidget {
  const _BattlePreflightMessage({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.space10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space2),
                  Text(
                    message,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.3,
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

String _battlePreflightBlockerMessage(List<String> blockers) {
  if (blockers.isEmpty) return 'O preflight nao confirmou prontidao.';
  const labels = <String, String>{
    'deck_size_invalid': 'Tamanho do deck precisa ser corrigido',
    'deck_commander_invalid': 'Comandante do deck precisa ser corrigido',
    'deck_validation_required': 'Valide novamente o deck',
    'opponent_size_invalid': 'Deck adversario tem tamanho invalido',
    'opponent_commander_invalid': 'Comandante adversario e invalido',
    'opponent_validation_required': 'Deck adversario nao esta validado',
    'no_available_opponents': 'Nenhum adversario esta disponivel',
    'engine_not_configured': 'Motor Battle nao esta configurado',
    'engine_coverage_incomplete': 'Cartas sem cobertura de regras',
    'engine_coverage_unavailable': 'Motor Battle indisponivel',
  };
  return blockers
      .map((blocker) => labels[blocker] ?? blocker.replaceAll('_', ' '))
      .join(' · ');
}

bool _isUuid(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(value);

class _BattleReplayActions extends StatelessWidget {
  const _BattleReplayActions({
    required this.isRunning,
    required this.onRunGoldfish,
    required this.onRunBattle,
    required this.onRunLive,
    required this.onOpenCoach,
    required this.isStartingLive,
  });

  final bool isRunning;
  final VoidCallback onRunGoldfish;
  final VoidCallback onRunBattle;
  final VoidCallback? onRunLive;
  final VoidCallback? onOpenCoach;
  final bool isStartingLive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space14,
        AppTheme.space16,
        AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineMuted.withValues(alpha: 0.58),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Escolha o tipo de teste',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isRunning)
                const SizedBox(
                  width: AppTheme.space18,
                  height: AppTheme.space18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            'Consistência (Goldfish) observa mãos e curva sem adversário. '
            'Confronto (Battle) executa dois decks e salva evidências do replay. '
            '${onOpenCoach == null ? '' : 'Battle Coach para nas decisões para você jogar. '}'
            'Nenhum modo prova superioridade ou substitui regra oficial.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.32,
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (onOpenCoach == null)
                FilledButton.icon(
                  key: const Key('battle-run-goldfish-button'),
                  onPressed: isRunning ? null : onRunGoldfish,
                  icon: const Icon(Icons.speed_rounded),
                  label: const Text('Consistência · Goldfish'),
                )
              else
                OutlinedButton.icon(
                  key: const Key('battle-run-goldfish-button'),
                  onPressed: isRunning ? null : onRunGoldfish,
                  icon: const Icon(Icons.speed_rounded),
                  label: const Text('Consistência · Goldfish'),
                ),
              OutlinedButton.icon(
                key: const Key('battle-run-battle-button'),
                onPressed: isRunning ? null : onRunBattle,
                icon: const ManaLoomGlyph(
                  ManaLoomGlyphKind.battleReplay,
                  size: 20,
                ),
                label: const Text('Confronto · Battle'),
              ),
              if (onOpenCoach != null)
                FilledButton.icon(
                  key: const Key('battle-open-coach-button'),
                  onPressed: isRunning ? null : onOpenCoach,
                  icon: const ManaLoomGlyph(
                    ManaLoomGlyphKind.commander,
                    size: 20,
                  ),
                  label: const Text('Jogar · Battle Coach'),
                ),
              if (onRunLive != null)
                OutlinedButton.icon(
                  key: const Key('battle-run-live-button'),
                  onPressed: isRunning ? null : onRunLive,
                  icon: isStartingLive
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const ManaLoomGlyph(
                          ManaLoomGlyphKind.battleReplay,
                          size: 20,
                        ),
                  label: Text(
                    isStartingLive
                        ? 'Iniciando mesa…'
                        : 'Acompanhar ao vivo · experimental',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BattleSeriesProgressPanel extends StatelessWidget {
  const _BattleSeriesProgressPanel({
    required this.progress,
    required this.error,
    required this.running,
    required this.cancellationRequested,
    required this.onCancel,
    required this.onDismiss,
  });

  final BattleJobSeriesProgress? progress;
  final String? error;
  final bool running;
  final bool cancellationRequested;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = progress;
    final total = value?.total ?? 0;
    final terminal = value?.terminalCount ?? 0;
    final submitted = value?.submittedCount ?? 0;
    final active = value?.activeCount ?? 0;
    return Container(
      key: const Key('battle-series-progress-panel'),
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.62),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineMuted.withValues(alpha: 0.58),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          AppTheme.space10,
          AppTheme.space16,
          AppTheme.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ManaLoomGlyph(
                  ManaLoomGlyphKind.battleReplay,
                  size: 18,
                  color: AppTheme.brass400,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    total == 0
                        ? 'Série independente'
                        : 'Série independente · $terminal/$total encerradas',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (running)
                  TextButton.icon(
                    key: const Key('battle-series-cancel-button'),
                    onPressed: cancellationRequested ? null : onCancel,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: Text(
                      cancellationRequested ? 'Interrompendo…' : 'Interromper',
                    ),
                  )
                else
                  IconButton(
                    key: const Key('battle-series-dismiss-button'),
                    tooltip: 'Fechar resumo da série',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            if (total > 0) ...[
              LinearProgressIndicator(
                key: const Key('battle-series-progress'),
                value: terminal / total,
                minHeight: 3,
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                '$submitted/$total enfileiradas · $active em andamento. '
                'Cada tentativa usa job, seed e idempotência próprios.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: AppTheme.space8),
              Text(
                error!,
                key: const Key('battle-series-error'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (value != null && value.attempts.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final attempt in value.attempts) ...[
                      Container(
                        key: Key('battle-series-attempt-${attempt.index}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space10,
                          vertical: AppTheme.space6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                          border: Border.all(
                            color: attempt.job.isTerminal
                                ? AppTheme.success.withValues(alpha: 0.42)
                                : AppTheme.frost400.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '#${attempt.index}/${attempt.total} · '
                          'seed ${attempt.seed} · '
                          '${_battleJobListStatusLabel(attempt.job.status)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTheme.space8),
            Text(
              'Nesta etapa, o app coordena a fila; cada job criado já é salvo '
              'no PostgreSQL. Se o app fechar antes de enfileirar tudo, os jobs '
              'existentes permanecem, mas a retomada automática da série ainda '
              'não está disponível.',
              style: theme.textTheme.labelSmall?.copyWith(
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

class _BattleLiveJobStrip extends StatelessWidget {
  const _BattleLiveJobStrip({
    required this.jobs,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpen,
  });

  final List<BattleJob> jobs;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<BattleJob> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleJobs = jobs.take(4).toList(growable: false);
    return Container(
      key: const Key('battle-live-jobs-strip'),
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 184),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineMuted.withValues(alpha: 0.58),
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          AppTheme.space8,
          AppTheme.space16,
          AppTheme.space10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ManaLoomGlyph(
                  ManaLoomGlyphKind.battleReplay,
                  size: 18,
                  color: AppTheme.frost400,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    'Jobs recentes · acompanhamento experimental',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('battle-live-jobs-refresh-button'),
                  tooltip: 'Atualizar jobs',
                  onPressed: loading ? null : onRetry,
                  icon: const Icon(Icons.sync_rounded, size: 20),
                ),
              ],
            ),
            if (loading)
              const LinearProgressIndicator(
                key: Key('battle-live-jobs-loading'),
                minHeight: 2,
              )
            else if (error != null)
              Wrap(
                spacing: AppTheme.space8,
                runSpacing: AppTheme.space6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  TextButton(
                    key: const Key('battle-live-jobs-retry-button'),
                    onPressed: onRetry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              )
            else if (visibleJobs.isEmpty)
              Text(
                'Nenhum job assíncrono para este deck.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              )
            else
              for (final job in visibleJobs)
                InkWell(
                  key: Key('battle-live-job-${job.jobId}'),
                  onTap: () => onOpen(job),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_battleJobListStatusLabel(job.status)} · '
                            '${job.progress.current}/${job.progress.total} '
                            'etapas · ${job.jobId}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppTheme.frost400,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _battleJobListStatusLabel(BattleJobStatus status) => switch (status) {
  BattleJobStatus.queued => 'Na fila',
  BattleJobStatus.claimed => 'Preparando',
  BattleJobStatus.running => 'Em execução',
  BattleJobStatus.cancelPending => 'Cancelando',
  BattleJobStatus.completed => 'Concluído',
  BattleJobStatus.censored => 'Censurado',
  BattleJobStatus.timeout => 'Tempo esgotado',
  BattleJobStatus.coverageError => 'Sem cobertura',
  BattleJobStatus.engineError => 'Falha do motor',
  BattleJobStatus.cancelled => 'Cancelado',
  BattleJobStatus.persistenceError => 'Falha ao salvar',
};

class _BattleReplaySummaryTile extends StatelessWidget {
  const _BattleReplaySummaryTile({
    required this.replay,
    required this.onTap,
    this.selected = false,
  });

  final BattleReplaySummary replay;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppTheme.frost400.withValues(alpha: 0.08)
          : AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        key: Key('battle-replay-summary-${replay.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: selected
                  ? AppTheme.frost400.withValues(alpha: 0.48)
                  : AppTheme.outlineMuted.withValues(alpha: 0.62),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.frost400.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const ManaLoomGlyph(
                      ManaLoomGlyphKind.battleReplay,
                      color: AppTheme.frost400,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replay.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          replay.resultLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textHint,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ReplayMetaChip(label: replay.statusLabel),
                  _ReplayMetaChip(label: replay.turnLabel),
                  _ReplayMetaChip(label: replay.eventLabel),
                  if (replay.createdAt != null)
                    _ReplayMetaChip(label: _formatDate(replay.createdAt!)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplaySelectionEmpty extends StatelessWidget {
  const _ReplaySelectionEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const Key('battle-replays-selection-empty'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ManaLoomGlyph(
                ManaLoomGlyphKind.battleReplay,
                size: 36,
                color: AppTheme.frost400,
              ),
              const SizedBox(height: AppTheme.space14),
              Text(
                'Selecione um replay',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.space6),
              Text(
                'O historico permanece visivel enquanto voce percorre a partida.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpeningHandExercise {
  const _OpeningHandExercise({
    required this.snapshotPosition,
    required this.player,
    required this.handSize,
    required this.mulliganNumber,
  });

  final int snapshotPosition;
  final BattleReplayPlayerSnapshot player;
  final int handSize;
  final int mulliganNumber;
}

_OpeningHandExercise? _openingHandExercise(BattleReplayDetail detail) {
  final rawDeckAId = detail.summary.raw['deck_a_id']?.toString().trim();
  final rawDeckBId = detail.summary.raw['deck_b_id']?.toString().trim();
  final subjectDeckKey = rawDeckAId == detail.summary.deckId
      ? 'deck_a'
      : rawDeckBId == detail.summary.deckId
      ? 'deck_b'
      : null;
  if (subjectDeckKey == null) return null;

  for (
    var position = 0;
    position < detail.visualSnapshots.length;
    position += 1
  ) {
    final snapshot = detail.visualSnapshots[position];
    final marker = [
      snapshot.phase,
      snapshot.step,
      snapshot.action,
      snapshot.event['phase'],
      snapshot.event['step'],
      snapshot.event['action'],
      snapshot.event['event_type'],
    ].whereType<Object>().map((value) => value.toString().trim().toLowerCase());
    final isOpeningHand = marker.any(
      (value) =>
          value == 'opening_hand' ||
          value == 'initial_hand' ||
          value == 'mulligan',
    );
    if (!isOpeningHand) continue;

    BattleReplayPlayerSnapshot? subjectPlayer;
    for (final candidate in snapshot.players) {
      if (candidate.deckKey?.trim().toLowerCase() == subjectDeckKey) {
        subjectPlayer = candidate;
        break;
      }
    }
    if (subjectPlayer == null || subjectPlayer.hand.isEmpty) continue;
    final handSize = subjectPlayer.hand.length;
    if (handSize < 1 || handSize > 7) continue;
    final rawMulliganNumber =
        snapshot.event['mulligan_number'] ??
        snapshot.event['mulligan_count'] ??
        0;
    final parsedMulliganNumber = rawMulliganNumber is int
        ? rawMulliganNumber
        : int.tryParse(rawMulliganNumber.toString()) ?? 0;
    final mulliganNumber = parsedMulliganNumber.clamp(0, 7).toInt();
    return _OpeningHandExercise(
      snapshotPosition: position,
      player: subjectPlayer,
      handSize: handSize,
      mulliganNumber: mulliganNumber,
    );
  }
  return null;
}

class _BattleOpeningHandGate extends StatelessWidget {
  const _BattleOpeningHandGate({
    required this.exercise,
    required this.loading,
    required this.saving,
    required this.error,
    required this.onReload,
    required this.onKeep,
    required this.onMulligan,
    required this.onBack,
    required this.showBack,
  });

  final _OpeningHandExercise exercise;
  final bool loading;
  final bool saving;
  final String? error;
  final VoidCallback onReload;
  final VoidCallback onKeep;
  final VoidCallback onMulligan;
  final VoidCallback onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocked = loading || saving || error != null;
    return ListView(
      key: const Key('battle-opening-hand-gate'),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space12,
        AppTheme.space16,
        AppTheme.space24,
      ),
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Replays'),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.brass400.withValues(alpha: 0.44),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.pan_tool_alt_outlined,
                    color: AppTheme.brass400,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      'Sua decisão antes da leitura',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                'Observe a mão inicial e registre o que você faria. Só depois '
                'serão abertas a timeline e a heurística detalhada. O histórico '
                'pode já indicar o outcome; isto é uma revisão, não uma decisão '
                'cega da partida, e não existe resposta correta aqui.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              _VisualCardZone(
                key: const Key('battle-opening-hand-cards'),
                title: 'Mão inicial observada',
                cards: exercise.player.hand,
                fallbackCount: exercise.handSize,
                fallbackLabel: 'cartas',
              ),
              const SizedBox(height: AppTheme.space12),
              if (loading || saving)
                LinearProgressIndicator(
                  key: const Key('battle-opening-hand-progress'),
                  minHeight: 3,
                ),
              if (loading) ...[
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Confirmando se esta mão já tem uma escolha salva…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (error != null) ...[
                _BattleAnnotationError(message: error!, onRetry: onReload),
                const SizedBox(height: AppTheme.space10),
              ],
              Wrap(
                spacing: AppTheme.space8,
                runSpacing: AppTheme.space8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('battle-opening-hand-mulligan'),
                    onPressed: blocked ? null : onMulligan,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Eu faria Mulligan'),
                  ),
                  FilledButton.icon(
                    key: const Key('battle-opening-hand-keep'),
                    onPressed: blocked ? null : onKeep,
                    icon: const Icon(Icons.pan_tool_alt_outlined),
                    label: const Text('Eu faria Keep'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space10),
              Text(
                'A escolha será salva na sua conta PostgreSQL com a revisão '
                'deste deck. É um exercício antes da análise detalhada: não '
                'controla nem reescreve a batalha automática já executada.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textHint,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BattleReplayDetailPane extends StatelessWidget {
  const _BattleReplayDetailPane({
    required this.detail,
    required this.report,
    required this.comparisonBaseline,
    required this.onUseAsComparisonBaseline,
    required this.onClearComparisonBaseline,
    required this.annotations,
    required this.annotationsLoading,
    required this.annotationSaving,
    required this.annotationError,
    required this.onReloadAnnotations,
    required this.onAddNote,
    required this.onAddBookmark,
    required this.onHelpful,
    required this.onDeleteAnnotation,
    required this.onReflectAtEvent,
    required this.onReportEvent,
    required this.view,
    required this.onViewChanged,
    required this.onBack,
    this.showBack = true,
  });

  final BattleReplayDetail detail;
  final BattlePostReport report;
  final BattlePostReport? comparisonBaseline;
  final VoidCallback onUseAsComparisonBaseline;
  final VoidCallback onClearComparisonBaseline;
  final List<BattleReplayAnnotation> annotations;
  final bool annotationsLoading;
  final bool annotationSaving;
  final String? annotationError;
  final VoidCallback onReloadAnnotations;
  final VoidCallback onAddNote;
  final VoidCallback onAddBookmark;
  final ValueChanged<bool> onHelpful;
  final ValueChanged<BattleReplayAnnotation> onDeleteAnnotation;
  final ValueChanged<int> onReflectAtEvent;
  final ValueChanged<int> onReportEvent;
  final _ReplayDetailView view;
  final ValueChanged<_ReplayDetailView> onViewChanged;
  final VoidCallback onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = detail.summary;
    return ListView(
      key: const Key('battle-replay-detail-pane'),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space12,
        AppTheme.space16,
        AppTheme.space24,
      ),
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Replays'),
            ),
          ),
        Container(
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
                summary.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                '${summary.resultLabel} · ${summary.turnLabel} · ${summary.sourceLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.32,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              SegmentedButton<_ReplayDetailView>(
                segments: const [
                  ButtonSegment(
                    value: _ReplayDetailView.timeline,
                    icon: Icon(Icons.table_chart_outlined),
                    label: Text('Replay'),
                  ),
                  ButtonSegment(
                    value: _ReplayDetailView.decisions,
                    icon: Icon(Icons.account_tree_outlined),
                    label: Text('Decisoes'),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (selection) {
                  onViewChanged(selection.first);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        switch (view) {
          _ReplayDetailView.timeline => _ReplayTimeline(
            detail: detail,
            onReflectAtEvent: onReflectAtEvent,
            onReportEvent: onReportEvent,
          ),
          _ReplayDetailView.decisions => _ReplayDecisions(detail: detail),
        },
        const SizedBox(height: AppTheme.space12),
        _BattlePostReportPanel(report: report),
        const SizedBox(height: AppTheme.space12),
        _BattleAnnotationsPanel(
          annotations: annotations,
          loading: annotationsLoading,
          saving: annotationSaving,
          error: annotationError,
          onReload: onReloadAnnotations,
          onAddNote: onAddNote,
          onAddBookmark: onAddBookmark,
          onHelpful: onHelpful,
          onDelete: onDeleteAnnotation,
        ),
        const SizedBox(height: AppTheme.space12),
        _BattleComparisonControls(
          current: report,
          baseline: comparisonBaseline,
          onUseCurrent: onUseAsComparisonBaseline,
          onClear: onClearComparisonBaseline,
        ),
        const SizedBox(height: AppTheme.space12),
        _ReplayTechnicalDetails(detail: detail),
      ],
    );
  }
}

class _BattlePostReportPanel extends StatelessWidget {
  const _BattlePostReportPanel({required this.report});

  final BattlePostReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcome = _battleReportOutcomePresentation(report);
    final activities = report.observedActivityCounts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final unknown =
        report.unknownObservables
            .map(_battleObservableLabel)
            .toList(growable: false)
          ..sort();
    final unavailable =
        report.unavailableObservables
            .map(_battleObservableLabel)
            .toList(growable: false)
          ..sort();
    final engine = report.identity.engine?.trim();
    final commit = report.identity.engineCommit?.trim();

    return Material(
      key: const Key('battle-post-report'),
      color: AppTheme.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: outcome.color.withValues(alpha: 0.38)),
      ),
      child: ExpansionTile(
        key: const Key('battle-post-report-expansion'),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space14,
          vertical: AppTheme.space4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTheme.space14,
          AppTheme.space0,
          AppTheme.space14,
          AppTheme.space14,
        ),
        leading: Icon(outcome.icon, color: outcome.color),
        title: Text(
          outcome.label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          'Relatorio descritivo · n=${report.n} · ${_nullableMetric(report.turnCount, suffix: ' turnos')}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        children: [
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              _ReplayMetaChip(
                label: _nullableMetric(
                  report.durationMs,
                  suffix: ' ms',
                  unknown: 'Duracao —',
                ),
              ),
              _ReplayMetaChip(
                label: engine == null || engine.isEmpty
                    ? 'Motor —'
                    : 'Motor $engine',
              ),
              if (commit != null && commit.isNotEmpty)
                _ReplayMetaChip(label: 'Commit ${_shortIdentity(commit)}'),
              _ReplayMetaChip(
                label: report.reliability.eventsTruncated == true
                    ? 'Eventos truncados'
                    : 'Completude não presumida',
              ),
            ],
          ),
          if (report.lifeCurve.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            _BattleLifeCurveSummary(points: report.lifeCurve),
          ],
          const SizedBox(height: AppTheme.space12),
          _BattleReportEvidenceSection(
            icon: Icons.visibility_outlined,
            title: 'Atividade observada',
            items: activities.isEmpty
                ? const ['Nenhuma atividade tipada disponível']
                : activities
                      .take(8)
                      .map(
                        (entry) =>
                            '${_battleActivityLabel(entry.key)} · ${entry.value}',
                      )
                      .toList(growable: false),
          ),
          if (unknown.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space10),
            _BattleReportEvidenceSection(
              icon: Icons.help_outline_rounded,
              title: 'Desconhecido neste replay',
              items: unknown,
            ),
          ],
          if (unavailable.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space10),
            _BattleReportEvidenceSection(
              icon: Icons.visibility_off_outlined,
              title: 'O motor não expõe',
              items: unavailable,
            ),
          ],
          const SizedBox(height: AppTheme.space10),
          Text(
            'Uma execução não prova superioridade, valor de carta ou ausência de uso.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textHint,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleLifeCurveSummary extends StatelessWidget {
  const _BattleLifeCurveSummary({required this.points});

  final List<BattleLifeObservation> points;

  @override
  Widget build(BuildContext context) {
    final byPlayer = <String, List<BattleLifeObservation>>{};
    for (final point in points) {
      byPlayer.putIfAbsent(point.player, () => []).add(point);
    }
    final theme = Theme.of(context);
    return Column(
      key: const Key('battle-post-report-life-curve'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Curva de vida observada',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.frost400,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        for (final entry in byPlayer.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space4),
            child: Text(
              '${entry.key}: ${entry.value.map((point) => point.life).join(' → ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _BattleReportEvidenceSection extends StatelessWidget {
  const _BattleReportEvidenceSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.frost400),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              Text(
                items.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BattleAnnotationsPanel extends StatelessWidget {
  const _BattleAnnotationsPanel({
    required this.annotations,
    required this.loading,
    required this.saving,
    required this.error,
    required this.onReload,
    required this.onAddNote,
    required this.onAddBookmark,
    required this.onHelpful,
    required this.onDelete,
  });

  final List<BattleReplayAnnotation> annotations;
  final bool loading;
  final bool saving;
  final String? error;
  final VoidCallback onReload;
  final VoidCallback onAddNote;
  final VoidCallback onAddBookmark;
  final ValueChanged<bool> onHelpful;
  final ValueChanged<BattleReplayAnnotation> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedbackRecorded = annotations.any(
      (annotation) =>
          annotation.kind == BattleReplayAnnotationKind.helpfulFeedback,
    );
    return Material(
      key: const Key('battle-annotations-panel'),
      color: AppTheme.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.52)),
      ),
      child: ExpansionTile(
        key: const Key('battle-annotations-expansion'),
        initiallyExpanded: annotations.isNotEmpty || error != null,
        leading: const Icon(Icons.edit_note_rounded),
        title: const Text('Meu caderno de Battle'),
        subtitle: Text(
          annotations.isEmpty
              ? 'Notas privadas vinculadas ao replay e à revisão do deck'
              : '${annotations.length} registros privados neste replay',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTheme.space14,
          AppTheme.space0,
          AppTheme.space14,
          AppTheme.space14,
        ),
        children: [
          if (loading || saving)
            const LinearProgressIndicator(
              key: Key('battle-annotations-progress'),
              minHeight: 3,
            ),
          const SizedBox(height: AppTheme.space10),
          Text(
            'Salvo na sua conta no PostgreSQL; não usa shared_preferences. '
            'Exportar ou excluir a conta inclui estes registros. O replay '
            'original continua imutável.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppTheme.space10),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              FilledButton.tonalIcon(
                key: const Key('battle-annotation-add-note'),
                onPressed: saving ? null : onAddNote,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Adicionar nota'),
              ),
              OutlinedButton.icon(
                key: const Key('battle-annotation-add-bookmark'),
                onPressed: saving ? null : onAddBookmark,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Marcar replay'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              feedbackRecorded
                  ? 'Feedback de utilidade já registrado.'
                  : 'Este relatório ajudou sua revisão?',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!feedbackRecorded) ...[
            const SizedBox(height: AppTheme.space6),
            Wrap(
              spacing: AppTheme.space8,
              children: [
                TextButton.icon(
                  key: const Key('battle-annotation-helpful-yes'),
                  onPressed: saving ? null : () => onHelpful(true),
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  label: const Text('Sim'),
                ),
                TextButton.icon(
                  key: const Key('battle-annotation-helpful-no'),
                  onPressed: saving ? null : () => onHelpful(false),
                  icon: const Icon(Icons.thumb_down_alt_outlined),
                  label: const Text('Ainda não'),
                ),
              ],
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: AppTheme.space10),
            _BattleAnnotationError(message: error!, onRetry: onReload),
          ],
          if (!loading && annotations.isEmpty && error == null) ...[
            const SizedBox(height: AppTheme.space12),
            const _InlineEmptyPanel(
              key: Key('battle-annotations-empty'),
              icon: Icons.menu_book_outlined,
              title: 'Seu caderno está vazio',
              message:
                  'Adicione uma nota, marque o replay ou registre uma reflexão antes de avançar uma jogada.',
            ),
          ],
          if (annotations.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            for (final annotation in annotations)
              _BattleAnnotationTile(
                annotation: annotation,
                saving: saving,
                onDelete: () => onDelete(annotation),
              ),
          ],
        ],
      ),
    );
  }
}

class _BattleAnnotationError extends StatelessWidget {
  const _BattleAnnotationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('battle-annotations-error'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: AppTheme.space8),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _BattleAnnotationTile extends StatelessWidget {
  const _BattleAnnotationTile({
    required this.annotation,
    required this.saving,
    required this.onDelete,
  });

  final BattleReplayAnnotation annotation;
  final bool saving;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference =
        annotation.eventRef ?? annotation.snapshotRef ?? 'replay inteiro';
    return Container(
      key: ValueKey('battle-annotation-${annotation.id}'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            color: AppTheme.frost400,
            size: 20,
          ),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annotation.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                Text(
                  annotation.detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  'Referência: $reference · revisão ${_shortIdentity(annotation.subjectDeckRevision)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('battle-annotation-delete-${annotation.id}'),
            tooltip: 'Excluir anotação',
            onPressed: saving ? null : onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _BattleComparisonControls extends StatelessWidget {
  const _BattleComparisonControls({
    required this.current,
    required this.baseline,
    required this.onUseCurrent,
    required this.onClear,
  });

  final BattlePostReport current;
  final BattlePostReport? baseline;
  final VoidCallback onUseCurrent;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = baseline;
    final isCurrentBaseline = selected?.replayId == current.replayId;
    final comparison = selected == null || isCurrentBaseline
        ? null
        : const BattlePostReportService().compare(
            left: [selected],
            right: [current],
          );

    return Material(
      key: const Key('battle-comparison-panel'),
      color: AppTheme.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.52)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.compare_arrows_rounded,
                  color: AppTheme.frost400,
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: Text(
                    'Comparação descritiva',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected != null)
                  IconButton(
                    key: const Key('battle-comparison-clear'),
                    tooltip: 'Limpar comparação',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space6),
            if (selected == null) ...[
              Text(
                'Use este replay como base e abra outro replay do histórico. '
                'A comparação só é liberada para revisão, adversário, motor, '
                'commit e timeout iguais.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppTheme.space10),
              OutlinedButton.icon(
                key: const Key('battle-comparison-use-current'),
                onPressed: onUseCurrent,
                icon: const Icon(Icons.push_pin_outlined),
                label: const Text('Usar como base'),
              ),
            ] else if (isCurrentBaseline) ...[
              Text(
                'Base selecionada (n=1). Abra outro replay salvo para comparar.',
                key: const Key('battle-comparison-baseline-selected'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.frost400,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.space6),
              Text(
                'Seed igual é somente um rótulo de correlação; não forma par RNG.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ] else if (comparison != null && !comparison.isAllowed) ...[
              Text(
                'Comparação bloqueada: as execuções não pertencem à mesma coorte.',
                key: const Key('battle-comparison-blocked'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.space6),
              Text(
                comparison.blockers
                    .map(_battleComparisonBlockerLabel)
                    .join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space10),
              OutlinedButton.icon(
                key: const Key('battle-comparison-replace-baseline'),
                onPressed: onUseCurrent,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Usar este como nova base'),
              ),
            ] else if (comparison != null) ...[
              Row(
                key: const Key('battle-comparison-allowed'),
                children: [
                  Expanded(
                    child: _BattleComparisonSample(
                      label: 'Base',
                      sample: comparison.left,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space10),
                  Expanded(
                    child: _BattleComparisonSample(
                      label: 'Atual',
                      sample: comparison.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                comparison.sharedSeedLabels.isEmpty
                    ? 'Amostras independentes; nenhuma alegação de superioridade.'
                    : 'Há seed com mesmo rótulo, mas as amostras continuam '
                          'independentes e sem alegação de superioridade.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BattleComparisonSample extends StatelessWidget {
  const _BattleComparisonSample({required this.label, required this.sample});

  final String label;
  final BattleOutcomeSample sample;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label · n=${sample.n}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            '${sample.completed} concluída(s) · '
            '${sample.censored} censurada(s) · '
            '${sample.timeouts} timeout(s)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _battleComparisonBlockerLabel(BattleComparisonBlocker blocker) {
  return switch (blocker) {
    BattleComparisonBlocker.emptySample => 'amostra vazia',
    BattleComparisonBlocker.unknownOutcome => 'outcome desconhecido',
    BattleComparisonBlocker.missingDeckRevision => 'revisão ausente',
    BattleComparisonBlocker.deckRevisionMismatch => 'revisões diferentes',
    BattleComparisonBlocker.missingOpponent => 'adversário ausente',
    BattleComparisonBlocker.opponentMismatch => 'adversários diferentes',
    BattleComparisonBlocker.missingOpponentRevision =>
      'revisão do adversário ausente',
    BattleComparisonBlocker.opponentRevisionMismatch =>
      'revisões do adversário diferentes',
    BattleComparisonBlocker.missingEngine => 'motor ausente',
    BattleComparisonBlocker.engineMismatch => 'motores diferentes',
    BattleComparisonBlocker.missingEngineCommit => 'commit do motor ausente',
    BattleComparisonBlocker.engineCommitMismatch =>
      'commits do motor diferentes',
    BattleComparisonBlocker.missingTimeoutPolicy => 'timeout ausente',
    BattleComparisonBlocker.timeoutPolicyMismatch => 'timeouts diferentes',
  };
}

({String label, IconData icon, Color color}) _battleReportOutcomePresentation(
  BattlePostReport report,
) {
  return switch (report.outcome) {
    BattleReportOutcome.completed => (
      label: switch (report.completedResult) {
        BattleCompletedResult.subjectWin =>
          'Execucao concluida · vitoria do deck',
        BattleCompletedResult.opponentWin =>
          'Execucao concluida · vitoria do adversario',
        BattleCompletedResult.draw => 'Execucao concluida · empate',
        BattleCompletedResult.unknown =>
          'Execucao concluida · resultado desconhecido',
      },
      icon: Icons.check_circle_outline_rounded,
      color: AppTheme.success,
    ),
    BattleReportOutcome.censored => (
      label: 'Execucao censurada pelo limite',
      icon: Icons.hourglass_bottom_rounded,
      color: AppTheme.warning,
    ),
    BattleReportOutcome.timeout => (
      label: 'Motor excedeu o tempo',
      icon: Icons.timer_off_outlined,
      color: AppTheme.error,
    ),
    BattleReportOutcome.unknown => (
      label: 'Outcome nao informado',
      icon: Icons.help_outline_rounded,
      color: AppTheme.textHint,
    ),
  };
}

String _battleObservableLabel(BattleReportObservable observable) {
  return switch (observable) {
    BattleReportObservable.outcome => 'outcome',
    BattleReportObservable.turnCount => 'turnos',
    BattleReportObservable.duration => 'duração',
    BattleReportObservable.lifeCurve => 'curva de vida',
    BattleReportObservable.typedActivity => 'atividade tipada',
    BattleReportObservable.eventStreamCompleteness => 'completude dos eventos',
    BattleReportObservable.namedDrawIdentity => 'identidade de compras ocultas',
    BattleReportObservable.aiDecisionRationale => 'racional da IA',
    BattleReportObservable.combatActivity => 'combate',
    BattleReportObservable.deckRevision => 'revisão do deck',
    BattleReportObservable.opponent => 'adversário',
    BattleReportObservable.engine => 'motor',
    BattleReportObservable.engineCommit => 'commit do motor',
    BattleReportObservable.timeoutPolicy => 'política de timeout',
  };
}

String _battleActivityLabel(String type) {
  return switch (type) {
    'spell_cast' || 'cast' || 'casts' => 'Mágicas conjuradas',
    'ability_activated' || 'activate' || 'activates' => 'Habilidades ativadas',
    'attack' || 'attacks' => 'Ataques',
    'block' || 'blocks' => 'Bloqueios',
    'damage' || 'combat_damage' => 'Dano',
    'life_change' => 'Mudanças de vida',
    'zone_change' => 'Mudanças de zona',
    _ => type.replaceAll('_', ' '),
  };
}

String _nullableMetric(
  int? value, {
  String suffix = '',
  String unknown = 'Turnos —',
}) => value == null ? unknown : '$value$suffix';

String _shortIdentity(String value) =>
    value.length <= 10 ? value : value.substring(0, 10);

class _ReplayTimeline extends StatelessWidget {
  const _ReplayTimeline({
    required this.detail,
    required this.onReflectAtEvent,
    required this.onReportEvent,
  });

  final BattleReplayDetail detail;
  final ValueChanged<int> onReflectAtEvent;
  final ValueChanged<int> onReportEvent;

  @override
  Widget build(BuildContext context) {
    if (detail.visualSnapshots.isNotEmpty) {
      return _ReplayVisualViewer(
        detail: detail,
        onReflectAtEvent: onReflectAtEvent,
        onReportEvent: onReportEvent,
      );
    }

    if (detail.events.isEmpty) {
      final text = detail.replayText?.trim();
      if (text != null && text.isNotEmpty) {
        return _ReplayTextBlock(text: text);
      }
      return const _InlineEmptyPanel(
        key: Key('battle-replay-no-events-state'),
        icon: Icons.timeline_outlined,
        title: 'Replay sem jogadas registradas',
        message: 'Ainda nao ha relato suficiente para exibir esta partida.',
      );
    }

    return _ReplayEventList(events: detail.events);
  }
}

class _ReplayEventList extends StatefulWidget {
  const _ReplayEventList({required this.events});

  final List<BattleReplayEvent> events;

  @override
  State<_ReplayEventList> createState() => _ReplayEventListState();
}

class _ReplayEventListState extends State<_ReplayEventList> {
  static const _pageSize = 100;

  final TextEditingController _queryController = TextEditingController();
  int _visibleCount = _pageSize;
  String _action = 'all';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReplayEventList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.events, widget.events)) {
      _visibleCount = _pageSize;
      _action = 'all';
      _queryController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions =
        widget.events
            .map((event) => event.action.trim())
            .where((action) => action.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    final normalizedQuery = _queryController.text.trim().toLowerCase();
    final filtered = widget.events
        .where((event) {
          if (_action != 'all' && event.action != _action) return false;
          if (normalizedQuery.isEmpty) return true;
          final turn = event.turn == null
              ? ''
              : 'turno ${event.turn} t${event.turn}';
          final capability =
              event.raw['capability']?.toString() ??
              event.raw['source_capability']?.toString() ??
              '';
          return <String>[
            event.action,
            event.actor ?? '',
            event.phase ?? '',
            event.message,
            turn,
            capability,
          ].any((value) => value.toLowerCase().contains(normalizedQuery));
        })
        .toList(growable: false);
    final visible = filtered.take(_visibleCount).toList(growable: false);
    final theme = Theme.of(context);

    return Column(
      key: const Key('battle-replay-event-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final queryField = TextField(
              key: const Key('battle-replay-event-query'),
              controller: _queryController,
              decoration: const InputDecoration(
                labelText: 'Filtrar replay',
                hintText: 'Jogador, acao, turno ou capacidade',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() => _visibleCount = _pageSize),
            );
            final actionField = DropdownButtonFormField<String>(
              key: const Key('battle-replay-event-action-filter'),
              initialValue: _action,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo de evento'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('Todos os eventos'),
                ),
                ...actions.map(
                  (action) => DropdownMenuItem(
                    value: action,
                    child: Text(
                      action,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _action = value ?? 'all';
                  _visibleCount = _pageSize;
                });
              },
            );
            if (compact) {
              return Column(
                children: [
                  queryField,
                  const SizedBox(height: AppTheme.space8),
                  actionField,
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 2, child: queryField),
                const SizedBox(width: AppTheme.space10),
                Expanded(child: actionField),
              ],
            );
          },
        ),
        const SizedBox(height: AppTheme.space8),
        Text(
          'Mostrando ${visible.length} de ${filtered.length} eventos observados',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.textHint,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.space10),
        if (visible.isEmpty)
          const _InlineEmptyPanel(
            key: Key('battle-replay-event-filter-empty'),
            icon: Icons.filter_alt_off_outlined,
            title: 'Nenhum evento corresponde ao filtro',
            message:
                'Limpe a busca ou escolha outro tipo. Isso nao prova que uma jogada nao ocorreu.',
          )
        else
          for (var index = 0; index < visible.length; index++)
            _ReplayEventTile(event: visible[index], ordinal: index),
        if (visible.length < filtered.length)
          Center(
            child: OutlinedButton.icon(
              key: const Key('battle-replay-events-show-more'),
              onPressed: () => setState(() => _visibleCount += _pageSize),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text(
                'Mostrar mais (${filtered.length - visible.length} restantes)',
              ),
            ),
          ),
      ],
    );
  }
}

class _ReplayDecisions extends StatelessWidget {
  const _ReplayDecisions({required this.detail});

  final BattleReplayDetail detail;

  @override
  Widget build(BuildContext context) {
    if (detail.decisions.isEmpty) {
      return const _InlineEmptyPanel(
        key: Key('battle-replay-no-decisions-state'),
        icon: Icons.account_tree_outlined,
        title: 'Sem decisoes registradas',
        message:
            'Quando a simulacao explicar escolhas importantes, elas aparecem aqui.',
      );
    }

    return Column(
      children: detail.decisions
          .map((decision) => _ReplayDecisionTile(decision: decision))
          .toList(growable: false),
    );
  }
}

class _ReplayTechnicalDetails extends StatelessWidget {
  const _ReplayTechnicalDetails({required this.detail});

  final BattleReplayDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = const JsonEncoder.withIndent('  ').convert(detail.raw);
    return Material(
      key: const Key('battle-replay-technical-details'),
      color: AppTheme.surfaceElevated,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppTheme.outlineMuted.withValues(alpha: 0.52)),
      ),
      child: ExpansionTile(
        key: const Key('battle-replay-technical-details-expansion'),
        leading: const Icon(Icons.data_object_rounded),
        title: const Text('Dados técnicos'),
        subtitle: const Text(
          'Payload sanitizado para diagnóstico; zonas privadas não são exibidas.',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTheme.space12,
          AppTheme.space0,
          AppTheme.space12,
          AppTheme.space12,
        ),
        children: [_ReplayTextBlock(text: text)],
      ),
    );
  }
}

class _ReplayVisualViewer extends StatefulWidget {
  const _ReplayVisualViewer({
    required this.detail,
    required this.onReflectAtEvent,
    required this.onReportEvent,
  });

  final BattleReplayDetail detail;
  final ValueChanged<int> onReflectAtEvent;
  final ValueChanged<int> onReportEvent;

  @override
  State<_ReplayVisualViewer> createState() => _ReplayVisualViewerState();
}

class _ReplayVisualViewerState extends State<_ReplayVisualViewer> {
  int _index = 0;
  int _furthestRevealedIndex = 0;
  bool _isPlaying = false;
  double _playbackRate = 1;
  Timer? _playbackTimer;

  @override
  void didUpdateWidget(covariant _ReplayVisualViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.detail.visualSnapshots.length) {
      _index = widget.detail.visualSnapshots.length - 1;
    }
    if (oldWidget.detail.summary.id != widget.detail.summary.id) {
      _stopPlayback();
      _index = 0;
      _furthestRevealedIndex = 0;
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _move(int delta) {
    final next = (_index + delta).clamp(
      0,
      widget.detail.visualSnapshots.length - 1,
    );
    if (next == _index) return;
    _reveal(next);
  }

  void _reveal(int next) {
    setState(() {
      _index = next;
      if (next > _furthestRevealedIndex) {
        _furthestRevealedIndex = next;
      }
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (_isPlaying) {
      setState(() => _isPlaying = false);
    }
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
      return;
    }
    if (_index >= widget.detail.visualSnapshots.length - 1) {
      setState(() {
        _index = 0;
        _furthestRevealedIndex = 0;
      });
    }
    setState(() => _isPlaying = true);
    _schedulePlaybackTick();
  }

  void _schedulePlaybackTick() {
    _playbackTimer?.cancel();
    final delay = Duration(milliseconds: (1200 / _playbackRate).round());
    _playbackTimer = Timer(delay, () {
      if (!mounted || !_isPlaying) return;
      final lastIndex = widget.detail.visualSnapshots.length - 1;
      if (_index >= lastIndex) {
        _stopPlayback();
        return;
      }
      _reveal(_index + 1);
      if (_index >= lastIndex) {
        _stopPlayback();
      } else {
        _schedulePlaybackTick();
      }
    });
  }

  void _setPlaybackRate(double rate) {
    setState(() => _playbackRate = rate);
    if (_isPlaying) _schedulePlaybackTick();
  }

  void _moveToNextKeyMoment() {
    final snapshots = widget.detail.visualSnapshots;
    for (
      var candidate = _index + 1;
      candidate < snapshots.length;
      candidate++
    ) {
      if (_isReplayKeyMoment(snapshots[candidate])) {
        _reveal(candidate);
        return;
      }
    }
  }

  int? _nextKeyMomentIndex() {
    final snapshots = widget.detail.visualSnapshots;
    for (
      var candidate = _index + 1;
      candidate < snapshots.length;
      candidate++
    ) {
      if (_isReplayKeyMoment(snapshots[candidate])) return candidate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshots = widget.detail.visualSnapshots;
    final snapshot = snapshots[_index];
    final canMoveBack = _index > 0;
    final canMoveForward = _index < snapshots.length - 1;
    final nextKeyMoment = _nextKeyMomentIndex();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final canCaptureBeforeNext =
        _index == _furthestRevealedIndex &&
        _index < snapshots.length - 1 &&
        _index < widget.detail.events.length;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (canMoveBack) _move(-1);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (canMoveForward) _move(1);
        },
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (!reduceMotion) _togglePlayback();
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () {
          if (nextKeyMoment != null) _moveToNextKeyMoment();
        },
      },
      child: Focus(
        key: const Key('battle-replay-keyboard-focus'),
        autofocus: true,
        child: Container(
          key: const Key('battle-replay-visual-viewer'),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: AppTheme.outlineMuted.withValues(alpha: 0.58),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space12,
                  AppTheme.space12,
                  AppTheme.space12,
                  AppTheme.space8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReplayStepBadge(label: snapshot.turnLabel),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            snapshot.phaseLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.frost400,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space4),
                          Text(
                            snapshot.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                              height: 1.32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (snapshot.activePlayer != null) ...[
                            const SizedBox(height: AppTheme.space4),
                            Text(
                              'Ativo: ${snapshot.activePlayer}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                          if (snapshot.priorityPlayer != null) ...[
                            const SizedBox(height: AppTheme.space3),
                            Text(
                              'Prioridade: ${snapshot.priorityPlayer}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('battle-visual-prev-button'),
                      tooltip: 'Anterior',
                      onPressed: canMoveBack ? () => _move(-1) : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    IconButton(
                      key: const Key('battle-visual-next-button'),
                      tooltip: 'Proximo',
                      onPressed: canMoveForward ? () => _move(1) : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
              if (snapshots.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                  ),
                  child: Wrap(
                    spacing: AppTheme.space8,
                    runSpacing: AppTheme.space6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        key: const Key('battle-visual-play-button'),
                        tooltip: reduceMotion
                            ? 'Reproducao automatica desativada por reduced motion'
                            : _isPlaying
                            ? 'Pausar replay'
                            : 'Reproduzir replay',
                        onPressed: reduceMotion ? null : _togglePlayback,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      PopupMenuButton<double>(
                        key: const Key('battle-visual-speed-button'),
                        tooltip: 'Velocidade do replay',
                        onSelected: _setPlaybackRate,
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 0.5, child: Text('0,5×')),
                          PopupMenuItem(value: 1, child: Text('1×')),
                          PopupMenuItem(value: 2, child: Text('2×')),
                        ],
                        child: _ReplayMetaChip(
                          label: '${_playbackRate.toStringAsFixed(1)}×',
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('battle-visual-next-key-moment-button'),
                        onPressed: nextKeyMoment == null
                            ? null
                            : _moveToNextKeyMoment,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                        label: const Text('Proximo destaque'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('battle-visual-reflect-before-next'),
                        onPressed: canCaptureBeforeNext
                            ? () => widget.onReflectAtEvent(_index)
                            : null,
                        icon: const Icon(
                          Icons.psychology_alt_outlined,
                          size: 17,
                        ),
                        label: const Text('Eu faria diferente'),
                      ),
                      IconButton(
                        key: const Key('battle-visual-report-event'),
                        tooltip: 'Reportar evento observado',
                        onPressed: _index < widget.detail.events.length
                            ? () => widget.onReportEvent(_index)
                            : null,
                        icon: const Icon(Icons.flag_outlined),
                      ),
                      _ReplayMetaChip(
                        label: '${_index + 1}/${snapshots.length}',
                      ),
                    ],
                  ),
                ),
              if (snapshots.length > 1)
                Slider(
                  key: const Key('battle-visual-turn-slider'),
                  value: _index.toDouble(),
                  min: 0,
                  max: (snapshots.length - 1).toDouble(),
                  divisions: snapshots.length - 1,
                  label: '${_index + 1}/${snapshots.length}',
                  semanticFormatterCallback: (value) =>
                      'Jogada ${value.round() + 1} de ${snapshots.length}',
                  onChanged: (value) => _reveal(value.round()),
                ),
              if (_index > 0)
                _ReplayObservedChanges(
                  changes: _observedSnapshotChanges(
                    snapshots[_index - 1],
                    snapshot,
                  ),
                ),
              if (snapshot.stack.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space10,
                    AppTheme.space0,
                    AppTheme.space10,
                    AppTheme.space10,
                  ),
                  child: _VisualCardZone(
                    key: const Key('battle-visual-zone-stack'),
                    title: 'Pilha',
                    cards: snapshot.stack,
                    fallbackCount: snapshot.stack.length,
                    fallbackLabel: 'objetos',
                    compact: true,
                  ),
                ),
              if (snapshot.combat.isNotEmpty)
                _BattleCombatPanel(combat: snapshot.combat),
              _VisualPlayerBoards(
                players: snapshot.players,
                activePlayer: snapshot.activePlayer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isReplayKeyMoment(BattleReplayVisualSnapshot snapshot) {
  final action = snapshot.action.trim().toLowerCase();
  return const {
        'casts',
        'cast',
        'activates',
        'activate',
        'attacks',
        'attack',
        'blocks',
        'block',
        'resolves',
        'resolve',
        'dies',
        'damage',
        'combat_damage',
        'game_over',
      }.contains(action) ||
      snapshot.combat.isNotEmpty ||
      snapshot.stack.isNotEmpty;
}

List<String> _observedSnapshotChanges(
  BattleReplayVisualSnapshot previous,
  BattleReplayVisualSnapshot current,
) {
  final changes = <String>[];
  final previousPlayers = <String, BattleReplayPlayerSnapshot>{
    for (final player in previous.players) _snapshotPlayerKey(player): player,
  };

  for (final currentPlayer in current.players) {
    final previousPlayer = previousPlayers[_snapshotPlayerKey(currentPlayer)];
    if (previousPlayer == null) continue;

    final previousLife = previousPlayer.life;
    final currentLife = currentPlayer.life;
    if (previousLife != null &&
        currentLife != null &&
        previousLife != currentLife) {
      final delta = currentLife - previousLife;
      changes.add(
        '${currentPlayer.name}: vida ${delta > 0 ? 'aumentou' : 'diminuiu'} '
        '${delta.abs()} (${previousLife.toString()} → ${currentLife.toString()}).',
      );
    }

    final previousBattlefield = _observedCardCounts(previousPlayer.battlefield);
    final currentBattlefield = _observedCardCounts(currentPlayer.battlefield);
    final names = <String>{
      ...previousBattlefield.keys,
      ...currentBattlefield.keys,
    }.toList()..sort();
    for (final name in names) {
      final before = previousBattlefield[name] ?? 0;
      final after = currentBattlefield[name] ?? 0;
      if (after > before) {
        changes.add(
          '${currentPlayer.name}: ${_observedCardLabel(name, after - before)} '
          'entrou no campo observado.',
        );
      } else if (before > after) {
        changes.add(
          '${currentPlayer.name}: ${_observedCardLabel(name, before - after)} '
          'saiu do campo observado.',
        );
      }
    }

    final previousCards = _observedCardsByStableKey(previousPlayer.battlefield);
    final currentCards = _observedCardsByStableKey(currentPlayer.battlefield);
    for (final entry in currentCards.entries) {
      final before = previousCards[entry.key];
      final after = entry.value;
      if (before == null ||
          before.isTapped == null ||
          after.isTapped == null ||
          before.isTapped == after.isTapped) {
        continue;
      }
      changes.add(
        '${currentPlayer.name}: ${after.name} ficou '
        '${after.isTapped! ? 'virada' : 'desvirada'} no estado observado.',
      );
    }
  }
  return changes.take(10).toList(growable: false);
}

String _snapshotPlayerKey(BattleReplayPlayerSnapshot player) {
  final deckKey = player.deckKey?.trim().toLowerCase();
  if (deckKey != null && deckKey.isNotEmpty) return 'deck:$deckKey';
  return 'name:${player.name.trim().toLowerCase()}';
}

Map<String, int> _observedCardCounts(List<BattleReplayVisualCard> cards) {
  final counts = <String, int>{};
  for (final card in cards) {
    final name = card.name.trim();
    if (name.isEmpty) continue;
    counts[name] = (counts[name] ?? 0) + 1;
  }
  return counts;
}

Map<String, BattleReplayVisualCard> _observedCardsByStableKey(
  List<BattleReplayVisualCard> cards,
) {
  final result = <String, BattleReplayVisualCard>{};
  final nameOccurrences = <String, int>{};
  for (final card in cards) {
    final id = card.id?.trim();
    if (id != null && id.isNotEmpty) {
      result['id:$id'] = card;
      continue;
    }
    final name = card.name.trim().toLowerCase();
    final occurrence = nameOccurrences[name] ?? 0;
    nameOccurrences[name] = occurrence + 1;
    result['name:$name:$occurrence'] = card;
  }
  return result;
}

String _observedCardLabel(String name, int count) =>
    count == 1 ? name : '$count× $name';

class _ReplayObservedChanges extends StatelessWidget {
  const _ReplayObservedChanges({required this.changes});

  final List<String> changes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('battle-replay-observed-changes'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppTheme.space10,
        AppTheme.space0,
        AppTheme.space10,
        AppTheme.space10,
      ),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.frost400.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mudanças observadas',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.frost400,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          if (changes.isEmpty)
            Text(
              'Nenhuma mudança nos campos comparáveis deste snapshot. '
              'Isso não prova ausência de outras ações.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )
          else
            for (final change in changes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space4),
                child: Text(
                  '• $change',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _BattleCombatPanel extends StatelessWidget {
  const _BattleCombatPanel({required this.combat});

  final List<BattleReplayCombatGroup> combat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('battle-visual-combat-panel'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppTheme.space10,
        AppTheme.space0,
        AppTheme.space10,
        AppTheme.space10,
      ),
      padding: const EdgeInsets.all(AppTheme.space10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Combate observado',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTheme.space6),
          for (final group in combat)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space5),
              child: Text(
                _combatGroupLabel(group),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _combatGroupLabel(BattleReplayCombatGroup group) {
  final attackers = group.attackers.map((card) => card.name).join(', ');
  final blockers = group.blockers.map((card) => card.name).join(', ');
  final defender = group.defenderName?.trim().isNotEmpty == true
      ? group.defenderName!.trim()
      : 'defensor não identificado';
  final attackLabel = attackers.isEmpty
      ? 'Atacantes não identificados'
      : attackers;
  final blockLabel = blockers.isEmpty
      ? 'sem bloqueadores observados'
      : blockers;
  return '$attackLabel → $defender · $blockLabel';
}

class _VisualPlayerBoards extends StatelessWidget {
  const _VisualPlayerBoards({
    required this.players,
    required this.activePlayer,
  });

  final List<BattleReplayPlayerSnapshot> players;
  final String? activePlayer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 760 && players.length == 2;
        if (!sideBySide) {
          return Column(
            children: [
              for (final player in players)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space10,
                    AppTheme.space0,
                    AppTheme.space10,
                    AppTheme.space10,
                  ),
                  child: _VisualPlayerBoard(
                    player: player,
                    isActive: player.name == activePlayer,
                  ),
                ),
            ],
          );
        }

        return Padding(
          key: const Key('battle-visual-player-grid'),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space10,
            AppTheme.space0,
            AppTheme.space10,
            AppTheme.space10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < players.length; index++) ...[
                if (index > 0) const SizedBox(width: AppTheme.space10),
                Expanded(
                  child: _VisualPlayerBoard(
                    player: players[index],
                    isActive: players[index].name == activePlayer,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VisualPlayerBoard extends StatelessWidget {
  const _VisualPlayerBoard({required this.player, required this.isActive});

  final BattleReplayPlayerSnapshot player;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('battle-visual-player-${player.name}'),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.frost400.withValues(alpha: 0.08)
            : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isActive
              ? AppTheme.frost400.withValues(alpha: 0.44)
              : AppTheme.outlineMuted.withValues(alpha: 0.54),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _ReplayMetaChip(
                label: player.life == null ? 'Vida —' : '${player.life} vida',
              ),
              const SizedBox(width: AppTheme.space6),
              _ReplayMetaChip(
                label: player.mana == null ? 'Mana —' : '${player.mana} mana',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space10),
          _VisualCardZone(
            key: Key('battle-visual-zone-battlefield-${player.name}'),
            title: 'Campo',
            cards: player.battlefield,
            fallbackCount: player.lands,
            fallbackLabel: 'terrenos',
          ),
          const SizedBox(height: AppTheme.space10),
          _VisualCardZone(
            key: Key('battle-visual-zone-hand-${player.name}'),
            title: 'Mao',
            cards: player.hand,
            fallbackCount: player.handSize,
            fallbackLabel: 'cartas',
          ),
          const SizedBox(height: AppTheme.space10),
          _VisualCardZone(
            key: Key('battle-visual-zone-graveyard-${player.name}'),
            title: 'Cemiterio',
            cards: player.graveyard,
            fallbackCount: player.graveyardSize,
            fallbackLabel: 'cartas',
            compact: true,
          ),
          if (player.command.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space10),
            _VisualCardZone(
              key: Key('battle-visual-zone-command-${player.name}'),
              title: 'Zona de comando',
              cards: player.command,
              fallbackCount: player.command.length,
              fallbackLabel: 'cartas',
              compact: true,
            ),
          ],
          if (player.exile.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space10),
            _VisualCardZone(
              key: Key('battle-visual-zone-exile-${player.name}'),
              title: 'Exilio',
              cards: player.exile,
              fallbackCount: player.exile.length,
              fallbackLabel: 'cartas',
              compact: true,
            ),
          ],
          const SizedBox(height: AppTheme.space8),
          Text(
            player.librarySize == null
                ? 'Biblioteca: não observada'
                : 'Biblioteca: ${player.librarySize}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.textHint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualCardZone extends StatelessWidget {
  const _VisualCardZone({
    super.key,
    required this.title,
    required this.cards,
    required this.fallbackCount,
    required this.fallbackLabel,
    this.compact = false,
  });

  final String title;
  final List<BattleReplayVisualCard> cards;
  final int? fallbackCount;
  final String fallbackLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              cards.isNotEmpty
                  ? '${cards.length}'
                  : fallbackCount == null
                  ? 'não observado'
                  : '$fallbackCount $fallbackLabel',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textHint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space6),
        if (cards.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space10,
              vertical: AppTheme.space9,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSlate.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: AppTheme.outlineMuted.withValues(alpha: 0.44),
              ),
            ),
            child: Text(
              fallbackCount == null
                  ? 'Zona não observada por este motor'
                  : fallbackCount! > 0
                  ? '$fallbackCount $fallbackLabel sem imagem neste replay'
                  : '0 $fallbackLabel observados',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textHint,
              ),
            ),
          )
        else
          _BattleVisualCardCarousel(
            key: Key('battle-visual-card-carousel-${_safeReplayKey(title)}'),
            cards: cards,
            compact: compact,
          ),
      ],
    );
  }
}

class _BattleVisualCardCarousel extends StatefulWidget {
  const _BattleVisualCardCarousel({
    super.key,
    required this.cards,
    required this.compact,
  });

  final List<BattleReplayVisualCard> cards;
  final bool compact;

  @override
  State<_BattleVisualCardCarousel> createState() =>
      _BattleVisualCardCarouselState();
}

class _BattleVisualCardCarouselState extends State<_BattleVisualCardCarousel> {
  PageController? _controller;
  double? _viewportFraction;
  int _index = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _ensureController(double viewportFraction) {
    if (_controller == null || _viewportFraction != viewportFraction) {
      _controller?.dispose();
      _viewportFraction = viewportFraction;
      _controller = PageController(
        viewportFraction: viewportFraction,
        initialPage: _index.clamp(0, widget.cards.length - 1).toInt(),
      );
    }
    return _controller!;
  }

  void _move(int delta) {
    if (widget.cards.isEmpty) return;
    final next = (_index + delta).clamp(0, widget.cards.length - 1);
    if (next == _index) return;
    _controller?.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final scaleAllowance = ((textScale - 1).clamp(0, 1) * 36).toDouble();
    final height = (widget.compact ? 112.0 : 132.0) + scaleAllowance;
    final cardExtent = widget.compact ? 76.0 : 92.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final viewportFraction = (cardExtent / width)
            .clamp(0.08, 0.44)
            .toDouble();
        final controller = _ensureController(viewportFraction);

        return SizedBox(
          height: height,
          child: Stack(
            children: [
              PageView.builder(
                key: const Key('battle-visual-card-carousel'),
                controller: controller,
                padEnds: false,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.cards.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final card = widget.cards[index];
                  final isActive = index == _index;
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    scale: isActive ? 1 : 0.94,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isActive ? 1 : 0.78,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            right: AppTheme.space8,
                          ),
                          child: _VisualCardTile(
                            card: card,
                            compact: widget.compact,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (widget.cards.length > 1) ...[
                Positioned(
                  left: 0,
                  top: 18,
                  child: _BattleCarouselNavButton(
                    tooltip: 'Carta anterior',
                    icon: Icons.chevron_left_rounded,
                    onPressed: _index > 0 ? () => _move(-1) : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 18,
                  child: _BattleCarouselNavButton(
                    tooltip: 'Proxima carta',
                    icon: Icons.chevron_right_rounded,
                    onPressed: _index < widget.cards.length - 1
                        ? () => _move(1)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VisualCardTile extends StatelessWidget {
  const _VisualCardTile({required this.card, required this.compact});

  final BattleReplayVisualCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 54.0 : 66.0;
    final height = compact ? 76.0 : 92.0;
    final theme = Theme.of(context);
    final imageUrl = _battleCardImageUrl(card);

    return Semantics(
      key: Key('battle-visual-card-${card.name}'),
      button: true,
      label: 'Ver ${card.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          onTap: () => _showReplayCardPreview(context, card),
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedCardImage(
                      key: Key('battle-visual-card-image-${card.name}'),
                      imageUrl: imageUrl,
                      width: width,
                      height: height,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    if (card.isTapped == true)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.overlayBlack40,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.rotate_90_degrees_ccw_rounded,
                              color: AppTheme.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  card.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (card.powerToughnessLabel != null)
                  Text(
                    card.powerToughnessLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textHint,
                      height: 1.08,
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

class _BattleCarouselNavButton extends StatelessWidget {
  const _BattleCarouselNavButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceElevated.withValues(alpha: 0.86),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

void _showReplayCardPreview(BuildContext context, BattleReplayVisualCard card) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final imageUrl = _battleCardImageUrl(card, version: 'normal');
      return Dialog(
        insetPadding: const EdgeInsets.all(AppTheme.space20),
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),
                Center(
                  child: CachedCardImage(
                    imageUrl: imageUrl,
                    width: 220,
                    height: 306,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                if (card.typeLine != null && card.typeLine!.trim().isNotEmpty)
                  Text(
                    card.typeLine!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: AppTheme.space8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (card.manaCost != null &&
                        card.manaCost!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space8,
                          vertical: AppTheme.space5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSlate,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                          border: Border.all(
                            color: AppTheme.outlineMuted.withValues(alpha: 0.6),
                          ),
                        ),
                        child: ManaCostRow(cost: card.manaCost, symbolSize: 17),
                      ),
                    if (card.powerToughnessLabel != null)
                      _ReplayMetaChip(label: card.powerToughnessLabel!),
                    if (card.isTapped == true)
                      const _ReplayMetaChip(label: 'Virada'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _BattleNoteInput {
  const _BattleNoteInput({required this.text, this.title});

  final String text;
  final String? title;
}

class _BattleReflectionInput {
  const _BattleReflectionInput({required this.stance, this.reason});

  final String stance;
  final String? reason;
}

class _BattleEventReportInput {
  const _BattleEventReportInput({required this.reasonCode, this.details});

  final String reasonCode;
  final String? details;
}

Future<_BattleNoteInput?> _showBattleNoteDialog(BuildContext context) async {
  return showDialog<_BattleNoteInput>(
    context: context,
    builder: (_) => const _BattleNoteDialog(),
  );
}

Future<_BattleReflectionInput?> _showBattleReflectionDialog(
  BuildContext context,
) async {
  return showDialog<_BattleReflectionInput>(
    context: context,
    builder: (_) => const _BattleReflectionDialog(),
  );
}

Future<_BattleEventReportInput?> _showBattleEventReportDialog(
  BuildContext context,
) async {
  return showDialog<_BattleEventReportInput>(
    context: context,
    builder: (_) => const _BattleEventReportDialog(),
  );
}

class _BattleNoteDialog extends StatefulWidget {
  const _BattleNoteDialog();

  @override
  State<_BattleNoteDialog> createState() => _BattleNoteDialogState();
}

class _BattleNoteDialogState extends State<_BattleNoteDialog> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _textController.text.trim().isNotEmpty;
    return AlertDialog(
      key: const Key('battle-note-dialog'),
      title: const Text('Adicionar nota privada'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('battle-note-title'),
              controller: _titleController,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Título (opcional)'),
            ),
            const SizedBox(height: AppTheme.space8),
            TextField(
              key: const Key('battle-note-text'),
              controller: _textController,
              minLines: 3,
              maxLines: 7,
              maxLength: 2000,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'O que você quer rever?',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('battle-note-save'),
          onPressed: canSave
              ? () => Navigator.of(context).pop(
                  _BattleNoteInput(
                    text: _textController.text.trim(),
                    title: _trimmedOrNull(_titleController.text),
                  ),
                )
              : null,
          child: const Text('Salvar na conta'),
        ),
      ],
    );
  }
}

class _BattleReflectionDialog extends StatefulWidget {
  const _BattleReflectionDialog();

  @override
  State<_BattleReflectionDialog> createState() =>
      _BattleReflectionDialogState();
}

class _BattleReflectionDialogState extends State<_BattleReflectionDialog> {
  final _reasonController = TextEditingController();
  String _stance = 'would_change';

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('battle-reflection-dialog'),
      title: const Text('Antes da próxima jogada'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registre sua leitura agora. Depois você pode avançar; '
              'isso não muda o replay nem define uma resposta correta.',
            ),
            const SizedBox(height: AppTheme.space12),
            DropdownButtonFormField<String>(
              key: const Key('battle-reflection-stance'),
              initialValue: _stance,
              decoration: const InputDecoration(labelText: 'Minha leitura'),
              items: const [
                DropdownMenuItem(
                  value: 'would_change',
                  child: Text('Eu mudaria a escolha'),
                ),
                DropdownMenuItem(
                  value: 'would_repeat',
                  child: Text('Eu repetiria a escolha'),
                ),
                DropdownMenuItem(
                  value: 'unsure',
                  child: Text('Ainda não tenho certeza'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _stance = value);
              },
            ),
            const SizedBox(height: AppTheme.space8),
            TextField(
              key: const Key('battle-reflection-reason'),
              controller: _reasonController,
              minLines: 2,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Por quê? (opcional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('battle-reflection-save'),
          onPressed: () => Navigator.of(context).pop(
            _BattleReflectionInput(
              stance: _stance,
              reason: _trimmedOrNull(_reasonController.text),
            ),
          ),
          child: const Text('Registrar e continuar'),
        ),
      ],
    );
  }
}

class _BattleEventReportDialog extends StatefulWidget {
  const _BattleEventReportDialog();

  @override
  State<_BattleEventReportDialog> createState() =>
      _BattleEventReportDialogState();
}

class _BattleEventReportDialogState extends State<_BattleEventReportDialog> {
  final _detailsController = TextEditingController();
  String _reasonCode = 'incorrect_event';

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('battle-event-report-dialog'),
      title: const Text('Reportar evento observado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('battle-event-report-reason'),
              initialValue: _reasonCode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Motivo'),
              items: const [
                DropdownMenuItem(
                  value: 'incorrect_event',
                  child: Text('Evento incorreto'),
                ),
                DropdownMenuItem(
                  value: 'wrong_attribution',
                  child: Text('Atribuição ao lado errado'),
                ),
                DropdownMenuItem(
                  value: 'hidden_information',
                  child: Text('Informação privada exposta'),
                ),
                DropdownMenuItem(
                  value: 'missing_context',
                  child: Text('Contexto importante ausente'),
                ),
                DropdownMenuItem(value: 'other', child: Text('Outro')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _reasonCode = value);
              },
            ),
            const SizedBox(height: AppTheme.space8),
            TextField(
              key: const Key('battle-event-report-details'),
              controller: _detailsController,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Detalhes (opcional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('battle-event-report-save'),
          onPressed: () => Navigator.of(context).pop(
            _BattleEventReportInput(
              reasonCode: _reasonCode,
              details: _trimmedOrNull(_detailsController.text),
            ),
          ),
          child: const Text('Enviar reporte'),
        ),
      ],
    );
  }
}

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _ReplayEventTile extends StatelessWidget {
  const _ReplayEventTile({required this.event, required this.ordinal});

  final BattleReplayEvent event;
  final int ordinal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: ValueKey('battle-replay-event-item-$ordinal'),
      margin: const EdgeInsets.only(bottom: AppTheme.space10),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReplayStepBadge(label: event.turnLabel),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.phaseLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.frost400,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  event.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayDecisionTile extends StatelessWidget {
  const _ReplayDecisionTile({required this.decision});

  final BattleReplayDecision decision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space10),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReplayStepBadge(label: decision.turnLabel),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  decision.choice,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  decision.reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.34,
                  ),
                ),
                if (decision.score != null) ...[
                  const SizedBox(height: AppTheme.space6),
                  Text(
                    'Avaliacao ${decision.score!.toStringAsFixed(2)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textHint,
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

class _ReplayMetaChip extends StatelessWidget {
  const _ReplayMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space9,
        vertical: AppTheme.space5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.54),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReplayStepBadge extends StatelessWidget {
  const _ReplayStepBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space7),
      decoration: BoxDecoration(
        color: AppTheme.brass500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.brass500.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.brass400,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ReplayTextBlock extends StatelessWidget {
  const _ReplayTextBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: AppTheme.fontSm,
          height: 1.38,
        ),
      ),
    );
  }
}

String _battleCardImageUrl(
  BattleReplayVisualCard card, {
  String version = 'small',
}) {
  final provided = card.imageUrl?.trim();
  if (provided != null && provided.isNotEmpty) {
    if (version == 'small') return provided.replaceFirst('/normal/', '/small/');
    if (version == 'normal') {
      return provided.replaceFirst('/small/', '/normal/');
    }
    return provided;
  }
  final encoded = Uri.encodeComponent(card.name.trim());
  return 'https://api.scryfall.com/cards/named?exact=$encoded&format=image&version=$version';
}

String _safeReplayKey(String value) {
  final sanitized = value
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return sanitized.isEmpty ? 'cards' : sanitized;
}

class _InlineEmptyPanel extends StatelessWidget {
  const _InlineEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.frost400, size: 22),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
