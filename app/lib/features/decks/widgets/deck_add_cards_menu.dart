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
      onSelected: onSelected,
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      itemBuilder: (context) => items,
      child: const FloatingActionButton.extended(
        onPressed: null,
        icon: Icon(Icons.add),
        label: Text('Adicionar Cartas'),
      ),
    );
  }
}
