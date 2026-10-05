/// Visibilidade de deck (DCK-P0-00, onda 01: "deck vazio nunca público").
///
/// - Deck novo nasce privado: `is_public` ausente vale `false`.
/// - Publicar (`is_public: true`) exige a galeria aberta (`gallery_public`) e
///   um deck com cartas depois da mudança. Fora disso a escrita responde 422,
///   erro explícito, antes de gravar.
/// - Uma mudança de cartas que deixa um deck público vazio o torna privado na
///   mesma transação: deck vazio nunca fica público.
/// - `is_public: false` sempre vale: despublicar não depende de capability.
library;

const deckPublicationUnavailableCode = 'deck_publication_unavailable';
const deckPublicRequiresCardsCode = 'deck_public_requires_cards';

class DeckVisibilityException implements Exception {
  const DeckVisibilityException(this.code, this.message);

  final String code;
  final String message;

  Map<String, Object> get responseBody => {
    'error': message,
    'error_code': code,
  };

  @override
  String toString() => message;
}

/// Recusa pôr o deck como público com a galeria fechada ou com o deck vazio
/// depois da mudança. [requested] é o `is_public` do corpo; `null` (campo
/// ausente) e `false` nunca são recusados.
void ensureDeckPublicationAllowed({
  required bool? requested,
  required int cardCountAfter,
  required bool galleryOpen,
}) {
  if (requested != true) return;
  if (!galleryOpen) {
    throw const DeckVisibilityException(
      deckPublicationUnavailableCode,
      'Publicar decks não está disponível nesta beta.',
    );
  }
  if (cardCountAfter <= 0) {
    throw const DeckVisibilityException(
      deckPublicRequiresCardsCode,
      'Um deck vazio não pode ser público. Adicione cartas antes de publicar.',
    );
  }
}

/// A visibilidade que o deck guarda depois de uma mudança de cartas.
bool deckVisibilityAfterCardChange({
  required bool isPublic,
  required int cardCountAfter,
}) => isPublic && cardCountAfter > 0;
