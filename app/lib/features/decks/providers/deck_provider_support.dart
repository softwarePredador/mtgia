import '../models/deck_details.dart';

Map<String, Map<String, dynamic>> buildCurrentCardsMap(DeckDetails deck) {
  final currentCards = <String, Map<String, dynamic>>{};

  for (final commander in deck.commander) {
    currentCards[commander.id] = {
      'card_id': commander.id,
      'quantity': commander.quantity,
      'is_commander': true,
    };
  }

  for (final entry in deck.mainBoard.entries) {
    for (final card in entry.value) {
      if (!card.isCommander) {
        currentCards[card.id] = {
          'card_id': card.id,
          'quantity': card.quantity,
          'is_commander': false,
        };
      }
    }
  }

  return currentCards;
}

Set<String>? getCommanderIdentitySet(DeckDetails? deck) {
  if (deck == null) return null;
  if (deck.commander.isEmpty) return null;
  final commander = deck.commander.first;
  final identity =
      commander.colorIdentity.isNotEmpty
          ? commander.colorIdentity
          : commander.colors;
  return identity.map((e) => e.toUpperCase()).toSet();
}
