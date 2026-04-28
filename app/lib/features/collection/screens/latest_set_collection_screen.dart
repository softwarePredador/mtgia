import 'package:flutter/material.dart';

import 'set_cards_screen.dart';

class LatestSetCollectionScreen extends StatelessWidget {
  const LatestSetCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SetCardsScreen(loadLatest: true);
  }
}
