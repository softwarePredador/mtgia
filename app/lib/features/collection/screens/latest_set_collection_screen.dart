import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import 'set_cards_screen.dart';

class LatestSetCollectionScreen extends StatelessWidget {
  final ApiClient? apiClient;

  const LatestSetCollectionScreen({super.key, this.apiClient});

  @override
  Widget build(BuildContext context) {
    return SetCardsScreen(loadLatest: true, apiClient: apiClient);
  }
}
