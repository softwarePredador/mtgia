import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../../core/widgets/mana_symbols.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../../decks/models/deck_card_item.dart';
import '../../decks/providers/deck_provider.dart';
import '../../cards/screens/card_detail_screen.dart';
import '../providers/community_provider.dart';

class CommunityDeckDetailScreen extends StatefulWidget {
  final String deckId;

  const CommunityDeckDetailScreen({super.key, required this.deckId});

  @override
  State<CommunityDeckDetailScreen> createState() =>
      _CommunityDeckDetailScreenState();
}

class _CommunityDeckDetailScreenState extends State<CommunityDeckDetailScreen> {
  Map<String, dynamic>? _deckData;
  List<CommunityDeckComment> _comments = const <CommunityDeckComment>[];
  List<CommunityTradeMatch> _tradeMatches = const <CommunityTradeMatch>[];
  final _commentController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  bool _isCopying = false;
  bool _isSubmittingComment = false;
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDeck() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<CommunityProvider>();
    final results = await Future.wait<dynamic>([
      provider.fetchPublicDeckDetails(widget.deckId),
      provider.fetchDeckComments(widget.deckId),
      provider.fetchTradeMatches(deckId: widget.deckId),
    ]);
    final data = results[0] as Map<String, dynamic>?;
    final comments = results[1] as List<CommunityDeckComment>;
    final tradeMatches = results[2] as List<CommunityTradeMatch>;

    if (mounted) {
      setState(() {
        _deckData = data;
        _comments = comments;
        _tradeMatches = tradeMatches;
        _isLoading = false;
        _error = data == null ? 'Não foi possível carregar o deck' : null;
      });
    }
  }

  Future<void> _copyDeck() async {
    setState(() => _isCopying = true);

    final result = await context.read<DeckProvider>().copyPublicDeck(
      widget.deckId,
    );

    if (!mounted) return;
    setState(() => _isCopying = false);

    if (result['success'] == true) {
      final copiedDeck = result['deck'];
      final copiedDeckId = copiedDeck is Map
          ? copiedDeck['id']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Deck copiado para sua coleção! 🎉'),
          backgroundColor: AppTheme.success,
          action: copiedDeckId == null || copiedDeckId.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Abrir deck',
                  textColor: AppTheme.backgroundAbyss,
                  onPressed: () => context.go('/decks/$copiedDeckId'),
                ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Não foi possível copiar este deck agora. Tente novamente.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escreva pelo menos 3 caracteres para comentar.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _isSubmittingComment = true);
    final ok = await context.read<CommunityProvider>().addDeckComment(
      widget.deckId,
      body,
    );
    if (!mounted) return;
    if (ok) {
      _commentController.clear();
    }
    setState(() => _isSubmittingComment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Comentário publicado.'
              : 'Não foi possível publicar. Seu texto foi mantido para tentar novamente.',
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
    if (ok) await _loadDeck();
  }

  Future<void> _reportDeck() async {
    setState(() => _isReporting = true);
    final ok = await context.read<CommunityProvider>().reportDeck(
      widget.deckId,
      reason: 'other',
      details: 'Denuncia enviada pelo app.',
    );
    if (!mounted) return;
    setState(() => _isReporting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Denúncia registrada.' : 'Falha ao denunciar.'),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: Text(_deckData?['name'] ?? 'Deck Público'),
        backgroundColor: AppTheme.backgroundAbyss,
        actions: [
          if (_deckData != null)
            IconButton(
              icon: _isCopying
                  ? const SizedBox(
                      width: AppTheme.iconSpinnerSm,
                      height: AppTheme.iconSpinnerSm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.brass400,
                      ),
                    )
                  : const Icon(Icons.copy, color: AppTheme.brass400),
              tooltip: 'Copiar para meus decks',
              onPressed: _isCopying ? null : _copyDeck,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brass500),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.space12),
            ElevatedButton(
              onPressed: _loadDeck,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final deck = _deckData!;
    final commander = (deck['commander'] as List?) ?? [];
    final mainBoard = (deck['main_board'] as Map<String, dynamic>?) ?? {};
    final stats = (deck['stats'] as Map<String, dynamic>?) ?? {};
    final visualAnalysis =
        deck['visual_analysis'] as Map<String, dynamic>? ?? const {};

    return SingleChildScrollView(
      child: ResponsivePageFrame(
        key: const Key('community-deck-detail-frame'),
        maxWidth: AppTheme.contentMaxWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop =
                  constraints.maxWidth >= AppTheme.breakpointExpanded;
              final deckContents = _buildDeckContents(commander, mainBoard);
              final contextColumn = _buildContextColumn(
                visualAnalysis,
                isDesktop: isDesktop,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDeckHeader(deck, stats),
                  const SizedBox(height: AppTheme.paneGap),
                  if (isDesktop)
                    Row(
                      key: const Key('community-deck-desktop-panes'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: deckContents),
                        const SizedBox(width: AppTheme.paneGap),
                        SizedBox(
                          width: AppTheme.inspectorWidth,
                          child: contextColumn,
                        ),
                      ],
                    )
                  else
                    Column(
                      key: const Key('community-deck-mobile-stack'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        contextColumn,
                        const SizedBox(height: AppTheme.paneGap),
                        deckContents,
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDeckHeader(
    Map<String, dynamic> deck,
    Map<String, dynamic> stats,
  ) {
    return Container(
      key: const Key('community-deck-header'),
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deck['name'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontXxl,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space8,
                  vertical: AppTheme.space4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brass400.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  _capitalize(deck['format'] ?? ''),
                  style: const TextStyle(
                    color: AppTheme.brass400,
                    fontWeight: FontWeight.w600,
                    fontSize: AppTheme.fontSm,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.space4),
              Expanded(
                child: GestureDetector(
                  onTap: deck['owner_id'] != null
                      ? () =>
                            context.push('/community/user/${deck['owner_id']}')
                      : null,
                  child: Text(
                    deck['owner_username'] ?? 'Anônimo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.brass400,
                      fontSize: AppTheme.fontMd,
                      decoration: deck['owner_id'] != null
                          ? TextDecoration.underline
                          : null,
                      decorationColor: AppTheme.brass400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space16),
              Text(
                '${stats['total_cards'] ?? 0} cartas',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontMd,
                ),
              ),
            ],
          ),
          if (deck['description'] != null &&
              (deck['description'] as String).isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Text(
              deck['description'],
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontMd,
              ),
            ),
          ],
          if (deck['synergy_score'] != null) ...[
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppTheme.brass400,
                ),
                const SizedBox(width: AppTheme.space4),
                Text(
                  'Sinergia: ${deck['synergy_score']}%',
                  style: const TextStyle(
                    color: AppTheme.brass400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextColumn(
    Map<String, dynamic> visualAnalysis, {
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: AppTheme.space240, child: _buildCopyButton()),
            ],
          )
        else
          SizedBox(width: double.infinity, child: _buildCopyButton()),
        const SizedBox(height: AppTheme.space16),
        _VisualAnalysisPanel(analysis: visualAnalysis),
        if (_tradeMatches.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space14),
          _TradeMatchesPanel(matches: _tradeMatches),
        ],
        const SizedBox(height: AppTheme.space14),
        _CommunityFeedbackPanel(
          comments: _comments,
          controller: _commentController,
          isSubmitting: _isSubmittingComment,
          isReporting: _isReporting,
          onSubmit: _submitComment,
          onReport: _reportDeck,
        ),
      ],
    );
  }

  Widget _buildCopyButton() {
    return ElevatedButton.icon(
      key: const Key('community-deck-copy-button'),
      onPressed: _isCopying ? null : _copyDeck,
      icon: _isCopying
          ? const SizedBox(
              width: AppTheme.space18,
              height: AppTheme.space18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textPrimary,
              ),
            )
          : const Icon(Icons.file_copy_outlined),
      label: Text(_isCopying ? 'Copiando...' : 'Copiar para meus decks'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.brass500,
        foregroundColor: AppTheme.backgroundAbyss,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space18,
          vertical: AppTheme.space14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  Widget _buildDeckContents(List commander, Map<String, dynamic> mainBoard) {
    if (commander.isEmpty && mainBoard.isEmpty) {
      return Container(
        key: const Key('community-deck-empty-list'),
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSlate.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.outlineMuted),
        ),
        child: const Row(
          children: [
            Icon(Icons.style_outlined, color: AppTheme.textSecondary),
            SizedBox(width: AppTheme.space10),
            Expanded(
              child: Text(
                'A lista de cartas deste deck ainda não está disponível.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const Key('community-deck-card-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (commander.isNotEmpty) ...[
          const Text(
            'Comandante',
            style: TextStyle(
              color: AppTheme.brass400,
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.fontLg,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          ...commander.map(
            (card) => _buildCardTile(card as Map<String, dynamic>),
          ),
          const SizedBox(height: AppTheme.space16),
        ],
        ...mainBoard.entries.map((entry) {
          final cards = entry.value as List;
          final totalQty = cards.fold<int>(
            0,
            (sum, card) => sum + ((card as Map)['quantity'] as int),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key} ($totalQty)',
                style: const TextStyle(
                  color: AppTheme.brass400,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontLg,
                ),
              ),
              const SizedBox(height: AppTheme.space6),
              ...cards.map(
                (card) => _buildCardTile(card as Map<String, dynamic>),
              ),
              const SizedBox(height: AppTheme.space12),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCardTile(Map<String, dynamic> card) {
    final qty = card['quantity'] as int? ?? 1;
    final name = card['name'] as String? ?? '';
    final typeLine = card['type_line'] as String? ?? '';
    final manaCost = card['mana_cost'] as String? ?? '';
    final imageUrl = card['image_url'] as String?;

    return Card(
      color: AppTheme.surfaceElevated,
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: ListTile(
        dense: true,
        onTap: () {
          final deckCard = DeckCardItem.fromJson(card);
          openCardDetailRoute(context, deckCard);
        },
        leading: CachedCardImage(
          imageUrl: imageUrl,
          width: 32,
          height: 45,
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        ),
        title: Text(
          '${qty}x $name',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontMd,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          typeLine,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: AppTheme.fontSm,
          ),
        ),
        trailing: manaCost.isNotEmpty
            ? ManaCostRow(cost: manaCost, symbolSize: 16)
            : null,
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _VisualAnalysisPanel extends StatelessWidget {
  const _VisualAnalysisPanel({required this.analysis});

  final Map<String, dynamic> analysis;

  @override
  Widget build(BuildContext context) {
    final headline = analysis['headline']?.toString() ?? 'Análise pública';
    final reading =
        analysis['reading']?.toString() ??
        'Análise visual será refinada conforme o deck receber histórico.';
    final curve = analysis['curve_shape'] as Map<String, dynamic>? ?? const {};
    final colors = (analysis['color_identity_hint'] as List? ?? const [])
        .map((entry) => entry.toString())
        .toList(growable: false);

    return Container(
      key: const Key('community-deck-visual-analysis'),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.frost400.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppTheme.frost400),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  headline,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space10),
          Text(
            reading,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
          const SizedBox(height: AppTheme.space10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(label: 'baixo', value: '${curve['low'] ?? 0}'),
              _MetricPill(label: 'médio', value: '${curve['mid'] ?? 0}'),
              _MetricPill(label: 'alto', value: '${curve['high'] ?? 0}'),
              if (colors.isNotEmpty) _ColorIdentityMetric(colors: colors),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorIdentityMetric extends StatelessWidget {
  const _ColorIdentityMetric({required this.colors});

  final List<String> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space9,
        vertical: AppTheme.space6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: AppTheme.outlineMuted.withValues(alpha: 0.55),
          width: AppTheme.strokeHairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'cores',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppTheme.space6),
          ColorIdentityPips(
            colors: colors,
            symbolSize: 14,
            spacing: 2,
            decorated: false,
          ),
        ],
      ),
    );
  }
}

class _TradeMatchesPanel extends StatelessWidget {
  const _TradeMatchesPanel({required this.matches});

  final List<CommunityTradeMatch> matches;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('community-deck-trade-matches'),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.brass400.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppTheme.brass400),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  'Matches de cartas faltantes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          ...matches
              .take(3)
              .map(
                (match) => Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space8),
                  child: Text(
                    '${match.cardName} com ${match.ownerName}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
          if (matches.length > 3) ...[
            const SizedBox(height: AppTheme.space8),
            Text(
              '+${matches.length - 3} matches adicionais em trade.',
              style: const TextStyle(color: AppTheme.brass400),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommunityFeedbackPanel extends StatelessWidget {
  const _CommunityFeedbackPanel({
    required this.comments,
    required this.controller,
    required this.isSubmitting,
    required this.isReporting,
    required this.onSubmit,
    required this.onReport,
  });

  final List<CommunityDeckComment> comments;
  final TextEditingController controller;
  final bool isSubmitting;
  final bool isReporting;
  final VoidCallback onSubmit;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('community-deck-feedback-panel'),
      padding: const EdgeInsets.all(AppTheme.space14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, color: AppTheme.frost400),
              const SizedBox(width: AppTheme.space10),
              Expanded(
                child: Text(
                  'Feedback da comunidade',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Denunciar deck',
                onPressed: isReporting ? null : onReport,
                icon: isReporting
                    ? const SizedBox.square(
                        dimension: AppTheme.iconSpinnerSm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          TextField(
            key: const Key('community-deck-comment-field'),
            controller: controller,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comentar no deck',
              hintText: 'Sugira ajuste, risco ou carta para testar.',
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSubmit = !isSubmitting && value.text.trim().length >= 3;
              return Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  key: const Key('community-deck-comment-submit-button'),
                  onPressed: canSubmit ? onSubmit : null,
                  icon: isSubmitting
                      ? const SizedBox.square(
                          dimension: AppTheme.iconSpinnerSm,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('Publicar'),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.space10),
          if (comments.isEmpty)
            const Text(
              'Ainda não há comentários neste deck.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            ...comments
                .take(3)
                .map(
                  (comment) => Padding(
                    padding: const EdgeInsets.only(top: AppTheme.space8),
                    child: Text(
                      '${comment.authorName ?? 'Jogador'}: ${comment.body}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space10,
        vertical: AppTheme.space7,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundAbyss.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: AppTheme.fontSm,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
