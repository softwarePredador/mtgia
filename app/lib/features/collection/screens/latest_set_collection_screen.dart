import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';

class LatestSetCollectionScreen extends StatefulWidget {
  const LatestSetCollectionScreen({super.key});

  @override
  State<LatestSetCollectionScreen> createState() =>
      _LatestSetCollectionScreenState();
}

class _LatestSetCollectionScreenState extends State<LatestSetCollectionScreen> {
  final ApiClient _apiClient = ApiClient();
  final ScrollController _scrollController = ScrollController();

  String? _setCode;
  String? _setName;
  String? _releaseDate;

  final List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLatestSetAndCards();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestSetAndCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _cards.clear();
      _page = 1;
      _hasMore = true;
    });

    try {
      final setResponse = await _apiClient.get('/sets?limit=1&page=1');
      if (setResponse.statusCode != 200) {
        throw Exception(
          'Falha ao buscar última edição (${setResponse.statusCode})',
        );
      }

      final setData = setResponse.data as Map<String, dynamic>;
      final sets =
          (setData['data'] as List?)?.whereType<Map>().toList() ?? const [];
      if (sets.isEmpty) {
        throw Exception('Nenhuma edição encontrada no banco');
      }

      final latestSet = sets.first.cast<String, dynamic>();
      _setCode = (latestSet['code'] as String?)?.toUpperCase();
      _setName = latestSet['name']?.toString();
      _releaseDate = latestSet['release_date']?.toString();

      await _fetchCardsPage(page: 1, append: false);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCardsPage({
    required int page,
    required bool append,
  }) async {
    final setCode = _setCode;
    if (setCode == null || setCode.isEmpty) return;

    const limit = 100;
    final response = await _apiClient.get(
      '/cards?set=${Uri.encodeQueryComponent(setCode)}&limit=$limit&page=$page&dedupe=true',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao buscar cartas da edição (${response.statusCode})',
      );
    }

    final body = response.data as Map<String, dynamic>;
    final incoming =
        (body['data'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    setState(() {
      if (!append) {
        _cards
          ..clear()
          ..addAll(incoming);
      } else {
        _cards.addAll(incoming);
      }

      _page = page;
      _hasMore = incoming.length == limit;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await _fetchCardsPage(page: _page + 1, append: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar mais cartas: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: const Text('Última Edição'),
        backgroundColor: AppTheme.surfaceElevated,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadLatestSetAndCards,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar edição',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.manaViolet),
      );
    }

    if (_error != null) {
      return AppStatePanel(
        icon: Icons.error_outline_rounded,
        title: 'Falha ao carregar coleção mais recente',
        message: _error,
        accent: AppTheme.error,
        actionLabel: 'Tentar novamente',
        onAction: _loadLatestSetAndCards,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.outlineMuted, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldAccentGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      child: Text(
                        _setCode ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTheme.fontSm,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: _releaseDate ?? '-',
                    ),
                    _InfoChip(
                      icon: Icons.style_outlined,
                      label: '${_cards.length} cartas',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _setName ?? 'Edição',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTheme.fontXl,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Acompanhe as cartas da edição mais recente com scroll contínuo e recarga manual.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.manaViolet,
            onRefresh: _loadLatestSetAndCards,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: _cards.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= _cards.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.manaViolet,
                      ),
                    ),
                  );
                }

                final card = _cards[index];
                final imageUrl = card['image_url']?.toString();

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSlate,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.outlineMuted,
                      width: 0.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 60,
                        child:
                            imageUrl == null || imageUrl.isEmpty
                                ? Container(
                                  color: AppTheme.surfaceElevated,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.textSecondary,
                                    size: 18,
                                  ),
                                )
                                : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        color: AppTheme.surfaceElevated,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: AppTheme.textSecondary,
                                          size: 18,
                                        ),
                                      ),
                                ),
                      ),
                    ),
                    title: Text(
                      card['name']?.toString() ?? '-',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${card['type_line'] ?? '-'} • ${card['rarity'] ?? '-'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    dense: true,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primarySoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
