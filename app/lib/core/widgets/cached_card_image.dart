import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Widget centralizado para exibir imagens de cartas MTG com cache local.
///
/// Usa [CachedNetworkImage] internamente para:
/// - Cache em disco (não re-baixa a cada build/scroll)
/// - Placeholder animado enquanto carrega
/// - Fallback de erro (ícone) se a imagem falhar
/// - Fade-in suave ao carregar
///
/// Uso:
/// ```dart
/// CachedCardImage(
///   imageUrl: card.imageUrl,
///   width: 60,
///   height: 84,
/// )
/// ```
class CachedCardImage extends StatelessWidget {
  static const _scryfallHeaders = <String, String>{
    'User-Agent': 'ManaLoom/1.0',
    'Accept': 'image/*',
  };

  final String? imageUrl;
  final String? fallbackImageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedCardImage({
    super.key,
    required this.imageUrl,
    this.fallbackImageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  String? _sanitizeImageUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    var normalized = trimmed;
    if (normalized.startsWith('ttps://')) {
      normalized = 'h$normalized';
    } else if (normalized.startsWith('//')) {
      normalized = 'https:$normalized';
    } else if (!normalized.contains('://')) {
      normalized = 'https://$normalized';
    }

    if (normalized.startsWith('http://')) {
      normalized = 'https://${normalized.substring('http://'.length)}';
    }

    var uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    if (uri.host == 'api.scryfall.com' &&
        uri.path == '/cards/named' &&
        uri.queryParameters.containsKey('set')) {
      final query = Map<String, String>.from(uri.queryParameters)
        ..remove('set');
      query.putIfAbsent('version', () => 'normal');
      uri = uri.replace(queryParameters: query);
    }

    return uri.toString();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveImageUrl = _sanitizeImageUrl(imageUrl);
    final effectiveFallbackUrl = _sanitizeImageUrl(fallbackImageUrl);
    final primaryUrl = effectiveImageUrl ?? effectiveFallbackUrl;
    final fallbackUrl =
        effectiveFallbackUrl != null && effectiveFallbackUrl != primaryUrl
            ? effectiveFallbackUrl
            : null;

    if (primaryUrl == null) {
      return _placeholder();
    }

    final image = _networkImage(primaryUrl, fallbackUrl: fallbackUrl);

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _networkImage(String effectiveImageUrl, {String? fallbackUrl}) {
    final image = CachedNetworkImage(
      imageUrl: effectiveImageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: _scryfallHeaders,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => _loadingWidget(),
      errorWidget: (_, __, error) {
        debugPrint(
          '[🖼️ CachedCardImage] falha ao carregar $effectiveImageUrl -> $error',
        );
        if (fallbackUrl != null) {
          return CachedNetworkImage(
            imageUrl: fallbackUrl,
            width: width,
            height: height,
            fit: fit,
            httpHeaders: _scryfallHeaders,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (_, __) => _loadingWidget(),
            errorWidget: (_, __, ___) => _errorWidget(),
          );
        }
        return _errorWidget();
      },
      // Cache por 30 dias (default do flutter_cache_manager)
      // As imagens do Scryfall raramente mudam, então cache longo é seguro.
    );

    return image;
  }

  /// Placeholder estático quando não há URL (sem imagem para carregar)
  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: const Center(
        child: Icon(
          Icons.style, // ícone de carta MTG genérico
          color: AppTheme.outlineMuted,
          size: 28,
        ),
      ),
    );
  }

  /// Placeholder enquanto a imagem está baixando (sem spinner para não parecer "loading" permanente)
  Widget _loadingWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: const Center(
        child: Icon(Icons.style, color: AppTheme.outlineMuted, size: 26),
      ),
    );
  }

  Widget _errorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: AppTheme.outlineMuted,
      ),
    );
  }
}
