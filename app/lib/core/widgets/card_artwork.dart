import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'cached_card_image.dart';

/// Named image treatments used by product surfaces.
///
/// Call sites choose the visual job instead of hand-picking geometry. This
/// keeps printed cards uncropped while allowing intentional art crops for
/// atmospheric backgrounds and set thumbnails.
enum CardArtworkVariant {
  gallery,
  spotlight,
  recentDeck,
  fullCard,
  artCrop,
  setArt,
}

/// Estado que a superfície pode afirmar sobre a arte exibida.
///
/// [offline] só deve ser usado quando o chamador possui um sinal explícito de
/// falta de conexão. Uma falha genérica de imagem permanece [error].
enum CardArtworkDisplayState {
  loading,
  exact,
  reference,
  missing,
  offline,
  error,
}

/// Qualidade declarada pela URL de origem, sem inferir resolução por nome.
enum CardArtworkResolution { low, standard, high, unknown }

@visibleForTesting
CardArtworkResolution cardArtworkResolutionForUrl(String? rawUrl) {
  final value = rawUrl?.trim();
  if (value == null || value.isEmpty) return CardArtworkResolution.unknown;
  final uri = Uri.tryParse(value);
  if (uri == null) return CardArtworkResolution.unknown;

  final version = uri.queryParameters['version']?.trim().toLowerCase();
  final sourceKind = version == null || version.isEmpty
      ? (uri.pathSegments.isEmpty ? null : uri.pathSegments.first.toLowerCase())
      : version;
  return switch (sourceKind) {
    'small' => CardArtworkResolution.low,
    'normal' => CardArtworkResolution.standard,
    'large' ||
    'png' ||
    'art_crop' ||
    'border_crop' => CardArtworkResolution.high,
    _ => CardArtworkResolution.unknown,
  };
}

@immutable
class CardArtworkSpec {
  const CardArtworkSpec({
    required this.aspectRatio,
    required this.fit,
    required this.borderRadius,
  });

  static const double mtgCardAspectRatio = 63 / 88;

  final double aspectRatio;
  final BoxFit fit;
  final double borderRadius;

  static CardArtworkSpec forVariant(CardArtworkVariant variant) {
    return switch (variant) {
      CardArtworkVariant.gallery => const CardArtworkSpec(
        aspectRatio: mtgCardAspectRatio,
        fit: BoxFit.contain,
        borderRadius: AppTheme.radiusSm,
      ),
      CardArtworkVariant.spotlight => const CardArtworkSpec(
        aspectRatio: mtgCardAspectRatio,
        fit: BoxFit.contain,
        borderRadius: AppTheme.radiusSm,
      ),
      CardArtworkVariant.recentDeck => const CardArtworkSpec(
        aspectRatio: mtgCardAspectRatio,
        fit: BoxFit.contain,
        borderRadius: AppTheme.radiusSm,
      ),
      CardArtworkVariant.fullCard => const CardArtworkSpec(
        aspectRatio: mtgCardAspectRatio,
        fit: BoxFit.contain,
        borderRadius: AppTheme.radiusLg,
      ),
      CardArtworkVariant.artCrop => const CardArtworkSpec(
        aspectRatio: 16 / 9,
        fit: BoxFit.cover,
        borderRadius: AppTheme.radiusLg,
      ),
      CardArtworkVariant.setArt => const CardArtworkSpec(
        aspectRatio: 3 / 2,
        fit: BoxFit.cover,
        borderRadius: AppTheme.radiusMd,
      ),
    };
  }
}

class CardArtwork extends StatefulWidget {
  const CardArtwork({
    super.key,
    required this.variant,
    required this.imageUrl,
    required this.semanticLabel,
    this.fallbackImageUrl,
    this.imageKey,
    this.networkImageKey,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.constrainAspectRatio = true,
    this.borderRadius,
    this.loadingPlaceholder,
    this.errorPlaceholder,
    this.imageIsReference = false,
    this.offline = false,
    this.showStatusBadge = true,
  });

  final CardArtworkVariant variant;
  final String? imageUrl;
  final String? fallbackImageUrl;
  final Key? imageKey;
  final Key? networkImageKey;
  final double? width;
  final double? height;
  final String semanticLabel;
  final Alignment alignment;
  final bool constrainAspectRatio;
  final BorderRadius? borderRadius;
  final Widget? loadingPlaceholder;
  final Widget? errorPlaceholder;
  final bool imageIsReference;
  final bool offline;
  final bool showStatusBadge;

  @override
  State<CardArtwork> createState() => _CardArtworkState();
}

class _CardArtworkState extends State<CardArtwork> {
  late CardArtworkDisplayState _displayState;
  late CardArtworkResolution _resolution;

  @override
  void initState() {
    super.initState();
    _resetDisplayState();
  }

  @override
  void didUpdateWidget(CardArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl ||
        widget.fallbackImageUrl != oldWidget.fallbackImageUrl ||
        widget.imageIsReference != oldWidget.imageIsReference ||
        widget.offline != oldWidget.offline) {
      _resetDisplayState();
    }
  }

  void _resetDisplayState() {
    _resolution = cardArtworkResolutionForUrl(
      widget.imageUrl ?? widget.fallbackImageUrl,
    );
    _displayState = switch ((
      widget.offline,
      _hasImageUrl,
      _primaryIsReference,
    )) {
      (true, _, _) => CardArtworkDisplayState.offline,
      (false, false, _) => CardArtworkDisplayState.missing,
      (false, true, true) => CardArtworkDisplayState.reference,
      (false, true, false) => CardArtworkDisplayState.loading,
    };
  }

  bool get _hasImageUrl =>
      _nonEmpty(widget.imageUrl) != null ||
      _nonEmpty(widget.fallbackImageUrl) != null;

  bool get _primaryIsReference {
    if (widget.imageIsReference) return true;
    final primary = _nonEmpty(widget.imageUrl);
    final fallback = _nonEmpty(widget.fallbackImageUrl);
    if (primary == null && fallback != null) return true;
    if (primary != null && primary == fallback) return true;
    return _looksLikeReferenceArtwork(primary);
  }

  void _handleLoadState(CardImageLoadState state) {
    if (!mounted || widget.offline) return;

    final nextState = switch (state) {
      CardImageLoadState.missing => CardArtworkDisplayState.missing,
      CardImageLoadState.loading =>
        _primaryIsReference
            ? CardArtworkDisplayState.reference
            : CardArtworkDisplayState.loading,
      CardImageLoadState.primaryReady =>
        _primaryIsReference
            ? CardArtworkDisplayState.reference
            : CardArtworkDisplayState.exact,
      CardImageLoadState.fallbackReady => CardArtworkDisplayState.reference,
      CardImageLoadState.failed => CardArtworkDisplayState.error,
    };
    final nextResolution = switch (state) {
      CardImageLoadState.fallbackReady => cardArtworkResolutionForUrl(
        widget.fallbackImageUrl,
      ),
      CardImageLoadState.primaryReady => cardArtworkResolutionForUrl(
        widget.imageUrl ?? widget.fallbackImageUrl,
      ),
      _ => _resolution,
    };
    if (_displayState == nextState && _resolution == nextResolution) return;
    setState(() {
      _displayState = nextState;
      _resolution = nextResolution;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spec = CardArtworkSpec.forVariant(widget.variant);
    final radius =
        widget.borderRadius ?? BorderRadius.circular(spec.borderRadius);
    final badge = widget.showStatusBadge ? _badgeSpec : null;
    final artwork = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Semantics(
        container: true,
        image: true,
        label: _semanticLabel,
        child: ExcludeSemantics(
          child: ClipRRect(
            borderRadius: radius,
            child: ColoredBox(
              color: AppTheme.surfaceSlate,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedCardImage(
                      key: widget.imageKey,
                      imageUrl: widget.offline ? null : widget.imageUrl,
                      fallbackImageUrl: widget.offline
                          ? null
                          : widget.fallbackImageUrl,
                      networkImageKey: widget.networkImageKey,
                      width: double.infinity,
                      height: double.infinity,
                      fit: spec.fit,
                      alignment: widget.alignment,
                      loadingPlaceholder: widget.loadingPlaceholder,
                      errorPlaceholder: widget.errorPlaceholder,
                      onLoadStateChanged: _handleLoadState,
                    ),
                    if (badge != null)
                      Positioned(
                        left: AppTheme.space5,
                        bottom: AppTheme.space5,
                        child: _CardArtworkStatusBadge(
                          spec: badge,
                          showText: constraints.maxWidth >= 120,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.constrainAspectRatio) return artwork;
    return AspectRatio(aspectRatio: spec.aspectRatio, child: artwork);
  }

  String get _semanticLabel {
    final base = widget.semanticLabel.trim();
    final detail = switch (_displayState) {
      CardArtworkDisplayState.loading => 'carregando imagem',
      CardArtworkDisplayState.exact => null,
      CardArtworkDisplayState.reference => 'arte de referência',
      CardArtworkDisplayState.missing => 'imagem não disponível',
      CardArtworkDisplayState.offline => 'imagem não disponível sem conexão',
      CardArtworkDisplayState.error => 'falha ao carregar imagem',
    };
    final parts = <String>[if (base.isNotEmpty) base];
    if (detail != null && !_alreadyDescribes(base, detail)) parts.add(detail);
    if (_resolution == CardArtworkResolution.low &&
        _displayState != CardArtworkDisplayState.missing &&
        _displayState != CardArtworkDisplayState.offline &&
        _displayState != CardArtworkDisplayState.error &&
        !_alreadyDescribes(base, 'baixa resolução')) {
      parts.add('imagem em baixa resolução');
    }
    return parts.join(', ');
  }

  _CardArtworkBadgeSpec? get _badgeSpec {
    if (_displayState == CardArtworkDisplayState.reference) {
      return const _CardArtworkBadgeSpec(
        key: 'reference',
        shortLabel: 'Referência',
        longLabel: 'Arte de referência',
        icon: Icons.collections_bookmark_outlined,
        color: AppTheme.frost400,
      );
    }
    if (_displayState == CardArtworkDisplayState.missing) {
      return const _CardArtworkBadgeSpec(
        key: 'missing',
        shortLabel: 'Sem imagem',
        longLabel: 'Imagem não disponível',
        icon: Icons.image_not_supported_outlined,
        color: AppTheme.warning,
      );
    }
    if (_displayState == CardArtworkDisplayState.offline) {
      return const _CardArtworkBadgeSpec(
        key: 'offline',
        shortLabel: 'Sem conexão',
        longLabel: 'Imagem não disponível sem conexão',
        icon: Icons.wifi_off_rounded,
        color: AppTheme.frost400,
      );
    }
    if (_displayState == CardArtworkDisplayState.error) {
      return const _CardArtworkBadgeSpec(
        key: 'error',
        shortLabel: 'Falha na imagem',
        longLabel: 'Falha ao carregar imagem',
        icon: Icons.broken_image_outlined,
        color: AppTheme.error,
      );
    }
    if (_displayState == CardArtworkDisplayState.exact &&
        _resolution == CardArtworkResolution.low) {
      return const _CardArtworkBadgeSpec(
        key: 'low-resolution',
        shortLabel: 'Baixa resolução',
        longLabel: 'Imagem em baixa resolução',
        icon: Icons.hd_outlined,
        color: AppTheme.warning,
      );
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static bool _looksLikeReferenceArtwork(String? value) {
    if (value == null) return false;
    final uri = Uri.tryParse(value);
    return uri?.host.toLowerCase() == 'api.scryfall.com' &&
        uri?.path == '/cards/named';
  }

  static bool _alreadyDescribes(String base, String detail) {
    final normalizedBase = base.toLowerCase();
    final normalizedDetail = detail.toLowerCase();
    if (normalizedDetail.contains('referência')) {
      return normalizedBase.contains('referência');
    }
    return normalizedBase.contains(normalizedDetail);
  }
}

@immutable
class _CardArtworkBadgeSpec {
  const _CardArtworkBadgeSpec({
    required this.key,
    required this.shortLabel,
    required this.longLabel,
    required this.icon,
    required this.color,
  });

  final String key;
  final String shortLabel;
  final String longLabel;
  final IconData icon;
  final Color color;
}

class _CardArtworkStatusBadge extends StatelessWidget {
  const _CardArtworkStatusBadge({required this.spec, required this.showText});

  final _CardArtworkBadgeSpec spec;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: spec.longLabel,
      child: Container(
        key: Key('card-artwork-status-${spec.key}'),
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        padding: EdgeInsets.symmetric(
          horizontal: showText ? AppTheme.space6 : AppTheme.space4,
          vertical: AppTheme.space3,
        ),
        decoration: BoxDecoration(
          color: AppTheme.backgroundAbyss.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
          border: Border.all(color: spec.color.withValues(alpha: 0.72)),
          boxShadow: const [
            BoxShadow(color: AppTheme.overlayBlack40, blurRadius: 4),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon, size: 14, color: spec.color),
            if (showText) ...[
              const SizedBox(width: AppTheme.space4),
              Text(
                spec.shortLabel,
                style: TextStyle(
                  color: spec.color,
                  fontSize: AppTheme.fontXs,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
