import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/cached_card_image.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Deck copiado para sua coleção! 🎉'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erro ao copiar deck'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.length < 3) return;
    setState(() => _isSubmittingComment = true);
    final ok = await context.read<CommunityProvider>().addDeckComment(
      widget.deckId,
      body,
    );
    if (!mounted) return;
    _commentController.clear();
    setState(() => _isSubmittingComment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Comentário publicado.' : 'Falha ao comentar.'),
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
              icon:
                  _isCopying
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
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
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
                        horizontal: 8,
                        vertical: 4,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap:
                            deck['owner_id'] != null
                                ? () => context.push(
                                  '/community/user/${deck['owner_id']}',
                                )
                                : null,
                        child: Text(
                          deck['owner_username'] ?? 'Anônimo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.brass400,
                            fontSize: AppTheme.fontMd,
                            decoration:
                                deck['owner_id'] != null
                                    ? TextDecoration.underline
                                    : null,
                            decorationColor: AppTheme.brass400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                  const SizedBox(height: 12),
                  Text(
                    deck['description'],
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontMd,
                    ),
                  ),
                ],
                if (deck['synergy_score'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppTheme.brass400,
                      ),
                      const SizedBox(width: 4),
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
          ),

          const SizedBox(height: 16),

          // Copy button prominent
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCopying ? null : _copyDeck,
              icon:
                  _isCopying
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textPrimary,
                        ),
                      )
                      : const Icon(Icons.file_copy_outlined),
              label: Text(
                _isCopying ? 'Copiando...' : 'Copiar Deck para minha coleção',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brass500,
                foregroundColor: AppTheme.backgroundAbyss,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          _VisualAnalysisPanel(analysis: visualAnalysis),

          if (_tradeMatches.isNotEmpty) ...[
            const SizedBox(height: 14),
            _TradeMatchesPanel(matches: _tradeMatches),
          ],

          const SizedBox(height: 14),
          _CommunityFeedbackPanel(
            comments: _comments,
            controller: _commentController,
            isSubmitting: _isSubmittingComment,
            isReporting: _isReporting,
            onSubmit: _submitComment,
            onReport: _reportDeck,
          ),

          const SizedBox(height: 20),

          // Commander section
          if (commander.isNotEmpty) ...[
            const Text(
              '🏆 Comandante',
              style: TextStyle(
                color: AppTheme.brass400,
                fontWeight: FontWeight.bold,
                fontSize: AppTheme.fontLg,
              ),
            ),
            const SizedBox(height: 8),
            ...commander.map(
              (card) => _buildCardTile(card as Map<String, dynamic>),
            ),
            const SizedBox(height: 16),
          ],

          // Main board sections
          ...mainBoard.entries.map((entry) {
            final type = entry.key;
            final cards = entry.value as List;
            final totalQty = cards.fold<int>(
              0,
              (sum, c) => sum + ((c as Map)['quantity'] as int),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$type ($totalQty)',
                  style: const TextStyle(
                    color: AppTheme.brass400,
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontLg,
                  ),
                ),
                const SizedBox(height: 6),
                ...cards.map(
                  (card) => _buildCardTile(card as Map<String, dynamic>),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: ListTile(
        dense: true,
        onTap: () {
          final deckCard = DeckCardItem.fromJson(card);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CardDetailScreen(card: deckCard)),
          );
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
        trailing:
            manaCost.isNotEmpty
                ? Text(
                  manaCost,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                )
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
      padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 10),
          Text(
            reading,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(label: 'baixo', value: '${curve['low'] ?? 0}'),
              _MetricPill(label: 'médio', value: '${curve['mid'] ?? 0}'),
              _MetricPill(label: 'alto', value: '${curve['high'] ?? 0}'),
              if (colors.isNotEmpty)
                _MetricPill(label: 'cores', value: colors.join('')),
            ],
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
      padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 10),
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
          const SizedBox(height: 8),
          ...matches
              .take(3)
              .map(
                (match) => Padding(
                  padding: const EdgeInsets.only(top: 8),
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
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 10),
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
                icon:
                    isReporting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.flag_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comentar no deck',
              hintText: 'Sugira ajuste, risco ou carta para testar.',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon:
                  isSubmitting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send_outlined),
              label: const Text('Publicar'),
            ),
          ),
          const SizedBox(height: 10),
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
                    padding: const EdgeInsets.only(top: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
