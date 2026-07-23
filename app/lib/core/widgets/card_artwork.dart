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

class CardArtwork extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final spec = CardArtworkSpec.forVariant(variant);
    final radius = borderRadius ?? BorderRadius.circular(spec.borderRadius);
    final artwork = SizedBox(
      width: width,
      height: height,
      child: Semantics(
        container: true,
        image: true,
        label: semanticLabel,
        child: ExcludeSemantics(
          child: ClipRRect(
            borderRadius: radius,
            child: ColoredBox(
              color: AppTheme.surfaceSlate,
              child: CachedCardImage(
                key: imageKey,
                imageUrl: imageUrl,
                fallbackImageUrl: fallbackImageUrl,
                networkImageKey: networkImageKey,
                width: double.infinity,
                height: double.infinity,
                fit: spec.fit,
                alignment: alignment,
                loadingPlaceholder: loadingPlaceholder,
                errorPlaceholder: errorPlaceholder,
              ),
            ),
          ),
        ),
      ),
    );

    if (!constrainAspectRatio) return artwork;
    return AspectRatio(aspectRatio: spec.aspectRatio, child: artwork);
  }
}
