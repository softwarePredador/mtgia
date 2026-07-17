import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/friendly_error_mapper.dart';
import '../../../core/utils/scryfall_image_helper.dart';
import '../../../core/widgets/app_state_panel.dart';
import '../../../core/widgets/responsive_page_frame.dart';
import '../models/mtg_set.dart';
import 'set_cards_screen.dart';

class SetsCatalogScreen extends StatefulWidget {
  final ApiClient? apiClient;
  final bool showAppBar;

  const SetsCatalogScreen({super.key, this.apiClient, this.showAppBar = true});

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
        _error = FriendlyErrorMapper.fromException(
          e,
          context: FriendlyErrorContext.setsCatalog,
        );
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
      throw Exception(
        FriendlyErrorMapper.fromApiResponse(
          response,
          context: FriendlyErrorContext.setsCatalog,
        ),
      );
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
      final message = FriendlyErrorMapper.fromException(
        e,
        context: FriendlyErrorContext.setsCatalog,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.error),
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
    if (widget.apiClient == null) {
      context.push(
        '/collection/sets/${Uri.encodeComponent(set.code.toLowerCase())}',
      );
      return;
    }

    // Injected clients are used by isolated tests/previews where no GoRouter
    // is mounted. Production navigation remains URL-addressable above.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => SetCardsScreen(initialSet: set, apiClient: widget.apiClient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: AppTheme.backgroundAbyss,
      child: ResponsivePageFrame(
        maxWidth: AppTheme.contentMaxWidth,
        child: SizedBox(
          key: const Key('sets-catalog-responsive-canvas'),
          width: double.infinity,
          child: Column(
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
        ),
      ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundAbyss,
      appBar: AppBar(
        title: const Text('Coleções MTG'),
        backgroundColor: AppTheme.backgroundAbyss,
        actions: [
          IconButton(
            tooltip: 'Recarregar coleções',
            onPressed: _isLoading ? null : _loadFirstPage,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brass400),
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
      color: AppTheme.brass400,
      onRefresh: _loadFirstPage,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemCount = visibleSets.length + (_isLoadingMore ? 1 : 0);
          Widget itemBuilder(BuildContext context, int index) {
            if (index >= visibleSets.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.brass400),
                ),
              );
            }
            final set = visibleSets[index];
            return _SetCatalogTile(set: set, onTap: () => _openSet(set));
          }

          if (constraints.maxWidth >= 960) {
            return GridView.builder(
              key: const Key('setsCatalogGrid'),
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 620,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 104,
              ),
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            );
          }
          return ListView.separated(
            key: const Key('setsCatalogList'),
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: itemBuilder,
          );
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
      key: const Key('sets-catalog-header'),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Container(
                key: const Key('sets-catalog-hero'),
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: TextField(
                        key: const Key('setsSearchField'),
                        controller: controller,
                        onChanged: onChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome ou código da coleção...',
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.outlineMuted,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.outlineMuted,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            borderSide: const BorderSide(
                              color: AppTheme.brass400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        selectedColor: AppTheme.brass400.withValues(alpha: 0.16),
        backgroundColor: AppTheme.surfaceSlate,
        side: BorderSide(
          color: selected ? AppTheme.brass400 : AppTheme.outlineMuted,
        ),
        labelStyle: TextStyle(
          color: selected ? AppTheme.brass400 : AppTheme.textSecondary,
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
    return Material(
      color: AppTheme.surfaceSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.outlineMuted, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('set-tile-${set.code}'),
        onTap: onTap,
        isThreeLine: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: _SetCatalogArtwork(set: set),
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

class _SetCatalogArtwork extends StatelessWidget {
  static const _imageHeaders = <String, String>{
    'User-Agent': 'ManaLoom/1.0',
    'Accept': 'image/*',
  };

  final MtgSet set;

  const _SetCatalogArtwork({required this.set});

  @override
  Widget build(BuildContext context) {
    final persistedArtwork = set.representativeImageUrl?.trim();
    final artworkUrl =
        ScryfallImageHelper.withVersion(
          persistedArtwork,
          version: 'art_crop',
        ) ??
        (persistedArtwork?.isNotEmpty == true ? persistedArtwork : null);

    return Semantics(
      container: true,
      image: true,
      label:
          artworkUrl == null
              ? 'Símbolo da coleção ${set.name}'
              : 'Arte representativa da coleção ${set.name}',
      child: SizedBox(
        key: Key('set-artwork-frame-${set.code}'),
        width: 84,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (artworkUrl != null)
                CachedNetworkImage(
                  key: Key('set-artwork-image-${set.code}'),
                  imageUrl: artworkUrl,
                  fit: BoxFit.cover,
                  httpHeaders: _imageHeaders,
                  fadeInDuration: const Duration(milliseconds: 180),
                  placeholder: (_, __) => const _SetArtworkLoading(),
                  errorWidget: (_, __, ___) => _SetIconArtwork(set: set),
                )
              else
                _SetIconArtwork(set: set),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.transparent, AppTheme.overlayBlack65],
                    stops: [0.48, 1],
                  ),
                ),
              ),
              Positioned(
                left: 7,
                bottom: 6,
                child: Container(
                  key: Key('set-code-badge-${set.code}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundAbyss.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(
                      color: AppTheme.brass400.withValues(alpha: 0.64),
                    ),
                  ),
                  child: Text(
                    set.code,
                    style: const TextStyle(
                      color: AppTheme.brass400,
                      fontSize: AppTheme.fontXs,
                      height: AppTheme.lineHeightSingle,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetIconArtwork extends StatelessWidget {
  static final Map<String, Future<String?>> _svgCache = {};

  final MtgSet set;

  const _SetIconArtwork({required this.set});

  @override
  Widget build(BuildContext context) {
    final iconUrl = set.resolvedIconSvgUri;
    return DecoratedBox(
      key: Key('set-icon-fallback-${set.code}'),
      decoration: const BoxDecoration(gradient: AppTheme.goldAccentGradient),
      child: Center(
        child:
            iconUrl == null
                ? const _SetIconTerminalFallback()
                : Padding(
                  padding: const EdgeInsets.fromLTRB(18, 9, 18, 20),
                  child: FutureBuilder<String?>(
                    key: Key('set-icon-request-${set.code}'),
                    future: _svgCache.putIfAbsent(
                      iconUrl,
                      () => _loadSvg(iconUrl),
                    ),
                    builder: (context, snapshot) {
                      final svg = snapshot.data;
                      if (svg == null) {
                        return const _SetIconTerminalFallback();
                      }
                      return SvgPicture.string(
                        svg,
                        key: Key('set-icon-image-${set.code}'),
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          AppTheme.backgroundAbyss,
                          BlendMode.srcIn,
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }

  static Future<String?> _loadSvg(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: const {'Accept': 'image/svg+xml,image/*'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final svg = response.body.trim();
      if (!svg.contains('<svg')) return null;
      return svg;
    } catch (_) {
      return null;
    }
  }
}

class _SetArtworkLoading extends StatelessWidget {
  const _SetArtworkLoading();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceSlate, AppTheme.surfaceElevated],
        ),
      ),
      child: _SetIconTerminalFallback(),
    );
  }
}

class _SetIconTerminalFallback extends StatelessWidget {
  const _SetIconTerminalFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.auto_awesome_mosaic_outlined,
      size: 28,
      color: AppTheme.backgroundAbyss,
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
        Icon(icon, size: 13, color: AppTheme.frost400),
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
      'future' => AppTheme.frost400,
      'new' => AppTheme.success,
      'current' => AppTheme.brass400,
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
