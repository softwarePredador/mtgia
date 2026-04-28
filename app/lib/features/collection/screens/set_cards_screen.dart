import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/cached_card_image.dart';
import '../../cards/screens/card_detail_screen.dart';
import '../../decks/models/deck_card_item.dart';
import '../models/mtg_set.dart';

class SetCardsScreen extends StatefulWidget {
  final MtgSet? initialSet;
  final String? setCode;
  final bool loadLatest;
  final ApiClient? apiClient;

  const SetCardsScreen({
    super.key,
    this.initialSet,
    this.setCode,
    this.loadLatest = false,
    this.apiClient,
  }) : assert(loadLatest || initialSet != null || setCode != null);

  @override
  State<SetCardsScreen> createState() => _SetCardsScreenState();
}

class _SetCardsScreenState extends State<SetCardsScreen> {
  late final ApiClient _apiClient;
  final ScrollController _scrollController = ScrollController();

  MtgSet? _set;
  final List<DeckCardItem> _cards = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient();
    _set = widget.initialSet;
    _scrollController.addListener(_onScroll);
    _loadSetAndCards();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSetAndCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _cards.clear();
      _page = 1;
      _hasMore = true;
    });

    try {
      if (_set == null || widget.loadLatest) {
        _set = await _fetchSetMetadata();
      }
      await _fetchCardsPage(page: 1, append: false);
    } catch (e) {
      if (!mounted) return;
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

  Future<MtgSet> _fetchSetMetadata() async {
    final endpoint =
        widget.loadLatest
            ? '/sets?limit=1&page=1'
            : '/sets?code=${Uri.encodeQueryComponent(widget.setCode ?? _set?.code ?? '')}&limit=1&page=1';
    final response = await _apiClient.get(endpoint);
    if (response.statusCode != 200) {
      throw Exception('Falha ao buscar coleção (${response.statusCode})');
    }

    final body = response.data as Map<String, dynamic>;
    final sets =
        (body['data'] as List?)
            ?.whereType<Map>()
            .map((e) => MtgSet.fromJson(e.cast<String, dynamic>()))
            .toList() ??
        const <MtgSet>[];
    if (sets.isEmpty) {
      throw Exception('Coleção não encontrada no banco local');
    }
    return sets.first;
  }

  Future<void> _fetchCardsPage({
    required int page,
    required bool append,
  }) async {
    final setCode = _set?.code;
    if (setCode == null || setCode.isEmpty) {
      throw Exception('Código da coleção ausente');
    }

    const limit = 100;
    final response = await _apiClient.get(
      '/cards?set=${Uri.encodeQueryComponent(setCode)}&limit=$limit&page=$page&dedupe=true',
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao buscar cartas da coleção (${response.statusCode})',
      );
    }

    final body = response.data as Map<String, dynamic>;
    final incoming =
        (body['data'] as List?)
            ?.whereType<Map>()
            .map((e) => _cardFromJson(e.cast<String, dynamic>()))
            .toList() ??
        const <DeckCardItem>[];

    if (!mounted) return;
    setState(() {
      if (append) {
        _cards.addAll(incoming);
      } else {
        _cards
          ..clear()
          ..addAll(incoming);
      }
      _page = page;
      _hasMore = incoming.length == limit;
    });
  }

  DeckCardItem _cardFromJson(Map<String, dynamic> json) {
    return DeckCardItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Carta sem nome',
      manaCost: json['mana_cost']?.toString(),
      typeLine: json['type_line']?.toString() ?? '',
      oracleText: json['oracle_text']?.toString(),
      colors:
          (json['colors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      colorIdentity:
          (json['color_identity'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: json['image_url']?.toString(),
      setCode: json['set_code']?.toString() ?? _set?.code ?? '',
      setName: json['set_name']?.toString() ?? _set?.name,
      setReleaseDate: json['set_release_date']?.toString() ?? _set?.releaseDate,
      rarity: json['rarity']?.toString() ?? '',
      quantity: 1,
      isCommander: false,
    );
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
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final set = _set;
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: Text(
          widget.loadLatest ? 'Última Edição' : set?.code ?? 'Coleção',
        ),
        backgroundColor: AppTheme.surfaceElevated,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadSetAndCards,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar coleção',
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
        title: 'Falha ao carregar coleção',
        message: _error,
        accent: AppTheme.error,
        actionLabel: 'Tentar novamente',
        onAction: _loadSetAndCards,
      );
    }

    final set = _set;
    if (set == null) {
      return AppStatePanel(
        icon: Icons.inventory_2_outlined,
        title: 'Coleção indisponível',
        message: 'Não foi possível identificar a coleção no banco local.',
        accent: AppTheme.warning,
      );
    }

    return Column(
      children: [
        _SetHeader(set: set, loadedCards: _cards.length),
        Expanded(
          child:
              _cards.isEmpty
                  ? _EmptySetCardsState(set: set, onRefresh: _loadSetAndCards)
                  : RefreshIndicator(
                    color: AppTheme.manaViolet,
                    onRefresh: _loadSetAndCards,
                    child: ListView.separated(
                      key: const Key('setCardsList'),
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
                        return _SetCardTile(card: _cards[index]);
                      },
                    ),
                  ),
        ),
      ],
    );
  }
}

class _SetHeader extends StatelessWidget {
  final MtgSet set;
  final int loadedCards;

  const _SetHeader({required this.set, required this.loadedCards});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                _InfoChip(
                  icon: Icons.confirmation_number_outlined,
                  label: set.code,
                  accent: AppTheme.mythicGold,
                ),
                _StatusChip(set: set),
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: set.releaseDate ?? 'Sem data',
                ),
                _InfoChip(
                  icon: Icons.style_outlined,
                  label:
                      set.cardCount > 0
                          ? '$loadedCards/${set.cardCount} cartas'
                          : '$loadedCards cartas locais',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              set.name,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: AppTheme.fontXl,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${set.type ?? 'tipo indisponível'} • dados servidos pelo banco local',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetCardTile extends StatelessWidget {
  final DeckCardItem card;

  const _SetCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      child: ListTile(
        key: Key('set-card-${card.name}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 60,
            child:
                card.imageUrl == null || card.imageUrl!.isEmpty
                    ? Container(
                      color: AppTheme.surfaceElevated,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                    )
                    : CachedCardImage(
                      imageUrl: card.imageUrl,
                      fit: BoxFit.cover,
                    ),
          ),
        ),
        title: Text(
          card.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${card.typeLine.isEmpty ? '-' : card.typeLine} • ${card.rarity}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        dense: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
          );
        },
      ),
    );
  }
}

class _EmptySetCardsState extends StatelessWidget {
  final MtgSet set;
  final VoidCallback onRefresh;

  const _EmptySetCardsState({required this.set, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return AppStatePanel(
      icon:
          set.isFuture
              ? Icons.hourglass_top_rounded
              : Icons.inventory_2_outlined,
      title:
          set.isFuture
              ? 'Dados parciais de set futuro'
              : 'Nenhuma carta local nesta coleção',
      message:
          set.isFuture
              ? 'A coleção ${set.code} já existe no catálogo sincronizado, mas as cartas podem aparecer só após o próximo sync do MTGJSON.'
              : 'O catálogo conhece a coleção, mas ainda não há cartas locais para ${set.code}. Rode o sync para atualizar a base.',
      accent: set.isFuture ? AppTheme.primarySoft : AppTheme.warning,
      actionLabel: 'Recarregar',
      onAction: onRefresh,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.accent = AppTheme.primarySoft,
  });

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
          Icon(icon, size: 14, color: accent),
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

class _StatusChip extends StatelessWidget {
  final MtgSet set;

  const _StatusChip({required this.set});

  @override
  Widget build(BuildContext context) {
    final color = switch (set.status) {
      'future' => AppTheme.primarySoft,
      'new' => AppTheme.success,
      'current' => AppTheme.mythicGold,
      _ => AppTheme.textSecondary,
    };
    return _InfoChip(
      icon: Icons.fiber_manual_record,
      label: set.statusLabel,
      accent: color,
    );
  }
}
