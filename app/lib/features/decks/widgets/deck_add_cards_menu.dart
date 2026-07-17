import 'package:flutter/material.dart';

import '../../../core/config/launch_features.dart';
import '../../../core/theme/app_theme.dart';

class DeckAddCardsMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;
  final bool scannerEnabled;

  const DeckAddCardsMenu({
    super.key,
    required this.onSelected,
    this.scannerEnabled = LaunchFeatures.scannerEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'search',
        child: ListTile(
          leading: Icon(Icons.search),
          title: Text('Buscar Carta'),
          subtitle: Text('Pesquisar por nome'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
      if (scannerEnabled)
        const PopupMenuItem(
          value: 'scan',
          child: ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Escanear Carta'),
            subtitle: Text('Usar câmera (OCR)'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
    ];

    return PopupMenuButton<String>(
      tooltip: 'Adicionar cartas',
      onSelected: onSelected,
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      itemBuilder: (context) => items,
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        elevation: 6,
        shadowColor: AppTheme.backgroundAbyss.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add),
                const SizedBox(width: 10),
                Text(
                  'Adicionar Cartas',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
