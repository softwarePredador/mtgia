import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class DeckAddCardsMenu extends StatelessWidget {
  final ValueChanged<String> onSelected;

  const DeckAddCardsMenu({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      itemBuilder:
          (context) => const [
            PopupMenuItem(
              value: 'search',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Buscar Carta'),
                subtitle: Text('Pesquisar por nome'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'scan',
              child: ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Escanear Carta'),
                subtitle: Text('Usar câmera (OCR)'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
      child: const FloatingActionButton.extended(
        onPressed: null,
        icon: Icon(Icons.add),
        label: Text('Adicionar Cartas'),
      ),
    );
  }
}
