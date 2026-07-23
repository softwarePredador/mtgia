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
  static const bool _allowLoopbackHttpImages = bool.fromEnvironment(
    'MANALOOM_ALLOW_LOOPBACK_HTTP_IMAGES',
    defaultValue: false,
  );
  static const _scryfallHeaders = <String, String>{
    'User-Agent': 'ManaLoom/1.0',
    'Accept': 'image/*',
  };

  final String? imageUrl;
  final String? fallbackImageUrl;
  final Key? networkImageKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final Widget? loadingPlaceholder;
  final Widget? errorPlaceholder;

  const CachedCardImage({
    super.key,
    required this.imageUrl,
    this.fallbackImageUrl,
    this.networkImageKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.loadingPlaceholder,
    this.errorPlaceholder,
  });

  @visibleForTesting
  static String? sanitizeImageUrlForTesting(
    String? rawUrl, {
    bool allowLoopbackHttp = false,
  }) => _sanitizeImageUrl(rawUrl, allowLoopbackHttp: allowLoopbackHttp);

  static String? _sanitizeImageUrl(
    String? rawUrl, {
    bool allowLoopbackHttp = _allowLoopbackHttpImages,
  }) {
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
      final httpUri = Uri.tryParse(normalized);
      final isLoopback =
          httpUri != null &&
          const {'127.0.0.1', '::1', 'localhost'}.contains(httpUri.host);
      if (!allowLoopbackHttp || !isLoopback) {
        normalized = 'https://${normalized.substring('http://'.length)}';
      }
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
      key: networkImageKey,
      imageUrl: effectiveImageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
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
            alignment: alignment,
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
    if (errorPlaceholder != null) {
      return SizedBox(width: width, height: height, child: errorPlaceholder);
    }
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
    if (loadingPlaceholder != null) {
      return SizedBox(width: width, height: height, child: loadingPlaceholder);
    }
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
    if (errorPlaceholder != null) {
      return SizedBox(width: width, height: height, child: errorPlaceholder);
    }
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
