import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/image_cache_policy.dart';
import '../services/scryfall_image_request_policy.dart';
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

  @visibleForTesting
  static String sizeScryfallImageUrlForTesting(
    String imageUrl, {
    int? decodeWidth,
    int? decodeHeight,
  }) => _sizeScryfallImageUrl(
    imageUrl,
    ImageDecodeTarget(width: decodeWidth, height: decodeHeight),
  );

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeTarget = AppImageCachePolicy.targetFor(
          width: width,
          height: height,
          constrainedWidth: constraints.maxWidth,
          constrainedHeight: constraints.maxHeight,
          devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
        );
        final sizedPrimaryUrl = _sizeScryfallImageUrl(primaryUrl, decodeTarget);
        final sizedFallbackUrl = fallbackUrl == null
            ? null
            : _sizeScryfallImageUrl(fallbackUrl, decodeTarget);
        final image = _networkImage(
          sizedPrimaryUrl,
          fallbackUrl: sizedFallbackUrl,
          decodeTarget: decodeTarget,
        );

        if (borderRadius != null) {
          return ClipRRect(borderRadius: borderRadius!, child: image);
        }

        return image;
      },
    );
  }

  Widget _networkImage(
    String effectiveImageUrl, {
    String? fallbackUrl,
    required ImageDecodeTarget decodeTarget,
  }) {
    final needsScryfallWebResilience =
        kIsWeb &&
        (isScryfallApiImageUrl(effectiveImageUrl) ||
            (fallbackUrl != null && isScryfallApiImageUrl(fallbackUrl)));
    if (needsScryfallWebResilience) {
      return _ScryfallWebCardImage(
        key: networkImageKey,
        primaryUrl: effectiveImageUrl,
        fallbackUrl: fallbackUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        decodeTarget: decodeTarget,
        loadingWidget: _loadingWidget,
        errorWidget: _errorWidget,
      );
    }

    final image = CachedNetworkImage(
      key: networkImageKey,
      imageUrl: effectiveImageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      httpHeaders: _scryfallHeaders,
      memCacheWidth: decodeTarget.width,
      memCacheHeight: decodeTarget.height,
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
            memCacheWidth: decodeTarget.width,
            memCacheHeight: decodeTarget.height,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (_, __) => _loadingWidget(),
            errorWidget: (_, __, ___) => _errorWidget(),
          );
        }
        return _errorWidget();
      },
    );

    return image;
  }

  static String _sizeScryfallImageUrl(
    String imageUrl,
    ImageDecodeTarget decodeTarget,
  ) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || uri.host != 'cards.scryfall.io') return imageUrl;
    final segments = List<String>.of(uri.pathSegments);
    if (segments.isEmpty ||
        !const {'small', 'normal', 'large'}.contains(segments.first)) {
      return imageUrl;
    }

    final decodeDimension = decodeTarget.width ?? decodeTarget.height;
    if (decodeDimension == null) return imageUrl;
    segments[0] = switch (decodeDimension) {
      <= 128 => 'small',
      <= 768 => 'normal',
      _ => 'large',
    };
    return uri.replace(pathSegments: segments).toString();
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

class _ScryfallWebCardImage extends StatefulWidget {
  const _ScryfallWebCardImage({
    super.key,
    required this.primaryUrl,
    required this.fallbackUrl,
    required this.width,
    required this.height,
    required this.fit,
    required this.alignment,
    required this.decodeTarget,
    required this.loadingWidget,
    required this.errorWidget,
  });

  final String primaryUrl;
  final String? fallbackUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final ImageDecodeTarget decodeTarget;
  final Widget Function() loadingWidget;
  final Widget Function() errorWidget;

  @override
  State<_ScryfallWebCardImage> createState() => _ScryfallWebCardImageState();
}

class _ScryfallWebCardImageState extends State<_ScryfallWebCardImage> {
  late String _currentUrl;
  String? _remainingFallbackUrl;
  Timer? _retryTimer;
  var _retryIndex = 0;
  var _requestSequence = 0;
  var _requestGeneration = 0;
  var _requestReady = false;
  var _errorRecoveryPending = false;
  var _terminalError = false;

  bool get _currentRequestNeedsGate => isScryfallApiImageUrl(_currentUrl);

  bool get _canRecover =>
      (_currentRequestNeedsGate &&
          scryfallImageRetryPolicy.delayForRetry(_retryIndex) != null) ||
      _remainingFallbackUrl != null;

  @override
  void initState() {
    super.initState();
    _resetUrls();
    _prepareCurrentRequest();
  }

  @override
  void didUpdateWidget(_ScryfallWebCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.primaryUrl == oldWidget.primaryUrl &&
        widget.fallbackUrl == oldWidget.fallbackUrl) {
      return;
    }
    _retryTimer?.cancel();
    _requestGeneration += 1;
    _resetUrls();
    _prepareCurrentRequest();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _requestGeneration += 1;
    super.dispose();
  }

  void _resetUrls() {
    _currentUrl = widget.primaryUrl;
    _remainingFallbackUrl = widget.fallbackUrl;
    _retryIndex = 0;
    _requestSequence = 0;
    _requestReady = false;
    _errorRecoveryPending = false;
    _terminalError = false;
  }

  void _prepareCurrentRequest() {
    final generation = ++_requestGeneration;
    if (!_currentRequestNeedsGate) {
      _markRequestReady(generation);
      return;
    }

    _requestReady = false;
    unawaited(_waitForScryfallPermit(generation));
  }

  Future<void> _waitForScryfallPermit(int generation) async {
    try {
      await scryfallImageRequestGate.acquire();
    } catch (error) {
      // The production gate only uses DateTime/Future.delayed, but a permit
      // failure must never leave card artwork stuck on its placeholder.
      debugPrint('[🖼️ CachedCardImage] falha no gate Scryfall -> $error');
    }
    _markRequestReady(generation);
  }

  void _markRequestReady(int generation) {
    if (!mounted || generation != _requestGeneration) {
      return;
    }
    setState(() {
      _requestSequence += 1;
      _requestReady = true;
      _errorRecoveryPending = false;
    });
  }

  void _queueErrorRecovery(Object error) {
    if (_errorRecoveryPending || _terminalError || !_requestReady) {
      return;
    }
    _errorRecoveryPending = true;
    final failedSequence = _requestSequence;
    debugPrint(
      '[🖼️ CachedCardImage] falha ao carregar $_currentUrl '
      '(tentativa ${_retryIndex + 1}) -> $error',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || failedSequence != _requestSequence || _terminalError) {
        return;
      }
      _recoverFromError();
    });
  }

  void _recoverFromError() {
    final retryDelay = _currentRequestNeedsGate
        ? scryfallImageRetryPolicy.delayForRetry(_retryIndex)
        : null;
    if (retryDelay != null) {
      _retryIndex += 1;
      setState(() {
        _requestReady = false;
        _errorRecoveryPending = false;
      });
      _retryTimer = Timer(retryDelay, _prepareCurrentRequest);
      return;
    }

    final fallbackUrl = _remainingFallbackUrl;
    if (fallbackUrl != null) {
      setState(() {
        _currentUrl = fallbackUrl;
        _remainingFallbackUrl = null;
        _retryIndex = 0;
        _requestReady = false;
        _errorRecoveryPending = false;
      });
      _prepareCurrentRequest();
      return;
    }

    setState(() {
      _requestReady = false;
      _errorRecoveryPending = false;
      _terminalError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_terminalError) {
      return widget.errorWidget();
    }
    if (!_requestReady) {
      return widget.loadingWidget();
    }

    return CachedNetworkImage(
      key: ValueKey('$_currentUrl#$_requestSequence'),
      imageUrl: _currentUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      httpHeaders: CachedCardImage._scryfallHeaders,
      memCacheWidth: widget.decodeTarget.width,
      memCacheHeight: widget.decodeTarget.height,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => widget.loadingWidget(),
      errorWidget: (_, __, error) {
        _queueErrorRecovery(error);
        return _canRecover ? widget.loadingWidget() : widget.errorWidget();
      },
    );
  }
}
