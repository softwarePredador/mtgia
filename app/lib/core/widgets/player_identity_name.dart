import 'package:flutter/material.dart';

/// Shared display-name treatment for private and public player identities.
///
/// The visual name is capped at two lines to protect the surrounding layout,
/// while semantics and the tooltip preserve the complete backend value.
class PlayerIdentityName extends StatelessWidget {
  const PlayerIdentityName({
    super.key,
    required this.name,
    required this.style,
    this.textAlign = TextAlign.start,
    this.semanticPrefix = 'Nome do jogador',
  });

  final String name;
  final TextStyle? style;
  final TextAlign textAlign;
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final normalized = name.trim().isEmpty ? 'Jogador' : name.trim();
    return Semantics(
      label: '$semanticPrefix: $normalized',
      child: ExcludeSemantics(
        child: Tooltip(
          message: normalized,
          child: Text(
            normalized,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            textAlign: textAlign,
            style: style,
          ),
        ),
      ),
    );
  }
}
