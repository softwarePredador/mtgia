import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../models/mtg_set.dart';
import 'set_cards_screen.dart';

class SetsCatalogScreen extends StatefulWidget {
  final ApiClient? apiClient;

  const SetsCatalogScreen({super.key, this.apiClient});

  @override
  State<SetsCatalogScreen> createState() => _SetsCatalogScreenState();
}

class _SetsCatalogScreenState extends State<SetsCatalogScreen> {
  late final ApiClient _apiClient;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  final List<MtgSet> _sets = [];
  String _query = '';
  String? _statusFilter;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  List<MtgSet> get _visibleSets {
    final filter = _statusFilter;
    if (filter == null) return _sets;
    return _sets.where((set) => set.status == filter).toList();
  }

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _query = value.trim();
      _loadFirstPage();
    });
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _sets.clear();
      _page = 1;
      _hasMore = true;
    });

    try {
      await _fetchPage(page: 1, append: false);
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

  Future<void> _fetchPage({required int page, required bool append}) async {
    const limit = 50;
    final encodedQuery = Uri.encodeQueryComponent(_query);
    final queryParam = _query.isEmpty ? '' : '&q=$encodedQuery';
    final response = await _apiClient.get(
      '/sets?limit=$limit&page=$page$queryParam',
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao buscar coleções (${response.statusCode})');
    }

    final body = response.data as Map<String, dynamic>;
    final incoming =
        (body['data'] as List?)
            ?.whereType<Map>()
            .map((e) => MtgSet.fromJson(e.cast<String, dynamic>()))
            .where((set) => set.code.isNotEmpty)
            .toList() ??
        const <MtgSet>[];

    if (!mounted) return;
    setState(() {
      if (append) {
        _sets.addAll(incoming);
      } else {
        _sets
          ..clear()
          ..addAll(incoming);
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
      await _fetchPage(page: _page + 1, append: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar mais coleções: $e')),
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
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  void _openSet(MtgSet set) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => SetCardsScreen(initialSet: set, apiClient: widget.apiClient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: const Text('Coleções MTG'),
        backgroundColor: AppTheme.surfaceElevated,
        actions: [
          IconButton(
            tooltip: 'Recarregar coleções',
            onPressed: _isLoading ? null : _loadFirstPage,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _CatalogHeader(
            controller: _searchController,
            onChanged: _onSearchChanged,
            statusFilter: _statusFilter,
            onStatusFilterChanged: (status) {
              setState(() {
                _statusFilter = status;
              });
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
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
        title: 'Falha ao carregar coleções',
        message: _error,
        accent: AppTheme.error,
        actionLabel: 'Tentar novamente',
        onAction: _loadFirstPage,
      );
    }

    final visibleSets = _visibleSets;
    if (visibleSets.isEmpty) {
      return AppStatePanel(
        icon: Icons.search_off_rounded,
        title: 'Nenhuma coleção encontrada',
        message:
            _query.isEmpty
                ? 'Tente outro filtro de status ou role a lista geral para carregar mais coleções antigas.'
                : 'Não encontramos coleções locais para "$_query". Busque por nome ou código, como ECC, SOC ou Marvel.',
        accent: AppTheme.warning,
        actionLabel: 'Limpar busca',
        onAction: () {
          _searchController.clear();
          _query = '';
          _statusFilter = null;
          _loadFirstPage();
        },
      );
    }

    return RefreshIndicator(
      color: AppTheme.manaViolet,
      onRefresh: _loadFirstPage,
      child: ListView.separated(
        key: const Key('setsCatalogList'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        itemCount: visibleSets.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= visibleSets.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.manaViolet),
              ),
            );
          }
          final set = visibleSets[index];
          return _SetCatalogTile(set: set, onTap: () => _openSet(set));
        },
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? statusFilter;
  final ValueChanged<String?> onStatusFilterChanged;

  const _CatalogHeader({
    required this.controller,
    required this.onChanged,
    required this.statusFilter,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.outlineMuted, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catálogo de Coleções',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: AppTheme.fontXxl,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Futuras, novas, atuais e antigas em uma lista local e rápida.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSm,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('setsSearchField'),
                  controller: controller,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou código do set...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        controller.text.isEmpty
                            ? null
                            : IconButton(
                              tooltip: 'Limpar busca',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                controller.clear();
                                onChanged('');
                              },
                            ),
                    filled: true,
                    fillColor: AppTheme.surfaceSlate,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(
                        color: AppTheme.outlineMuted,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(
                        color: AppTheme.outlineMuted,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: AppTheme.manaViolet),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: statusFilter == null,
                  onSelected: () => onStatusFilterChanged(null),
                ),
                _FilterChip(
                  label: 'Futuras',
                  selected: statusFilter == 'future',
                  onSelected: () => onStatusFilterChanged('future'),
                ),
                _FilterChip(
                  label: 'Novas',
                  selected: statusFilter == 'new',
                  onSelected: () => onStatusFilterChanged('new'),
                ),
                _FilterChip(
                  label: 'Atuais',
                  selected: statusFilter == 'current',
                  onSelected: () => onStatusFilterChanged('current'),
                ),
                _FilterChip(
                  label: 'Antigas',
                  selected: statusFilter == 'old',
                  onSelected: () => onStatusFilterChanged('old'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppTheme.manaViolet.withValues(alpha: 0.22),
        backgroundColor: AppTheme.surfaceSlate,
        side: BorderSide(
          color: selected ? AppTheme.manaViolet : AppTheme.outlineMuted,
        ),
        labelStyle: TextStyle(
          color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _SetCatalogTile extends StatelessWidget {
  final MtgSet set;
  final VoidCallback onTap;

  const _SetCatalogTile({required this.set, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.outlineMuted, width: 0.5),
      ),
      child: ListTile(
        key: Key('set-tile-${set.code}'),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.goldAccentGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Center(
            child: Text(
              set.code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: AppTheme.fontSm,
              ),
            ),
          ),
        ),
        title: Text(
          set.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MiniMeta(
                icon: Icons.calendar_today_outlined,
                label: set.releaseDate ?? '-',
              ),
              _MiniMeta(icon: Icons.category_outlined, label: set.type ?? '-'),
              _MiniMeta(
                icon: Icons.style_outlined,
                label: '${set.cardCount} cartas',
              ),
              _StatusPill(set: set),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.primarySoft),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: AppTheme.fontSm,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final MtgSet set;

  const _StatusPill({required this.set});

  @override
  Widget build(BuildContext context) {
    final color = switch (set.status) {
      'future' => AppTheme.primarySoft,
      'new' => AppTheme.success,
      'current' => AppTheme.mythicGold,
      _ => AppTheme.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        set.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontXs,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
