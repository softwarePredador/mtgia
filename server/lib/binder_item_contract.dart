class BinderItemInputException implements Exception {
  const BinderItemInputException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

const binderConditions = {'NM', 'LP', 'MP', 'HP', 'DMG'};
const binderListTypes = {'have', 'want'};

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);
final RegExp _languagePattern = RegExp(r'^[a-z]{2,3}(?:-[a-z0-9]{2,8})*$');

String readBinderCardId(Object? value) {
  if (value is! String || !_uuidPattern.hasMatch(value.trim())) {
    throw const BinderItemInputException(
      'binder_card_id_invalid',
      'card_id inválido.',
    );
  }
  return value.trim().toLowerCase();
}

int readBinderQuantity(Object? value, {int fallback = 1}) {
  if (value == null) return fallback;
  final quantity = switch (value) {
    int number => number,
    num number when number.isFinite && number == number.roundToDouble() =>
      number.toInt(),
    _ => null,
  };
  if (quantity == null || quantity < 1) {
    throw const BinderItemInputException(
      'binder_quantity_invalid',
      'Quantidade deve ser um inteiro maior ou igual a 1.',
    );
  }
  return quantity;
}

String readBinderCondition(Object? value, {String fallback = 'NM'}) {
  if (value == null) return fallback;
  if (value is! String) {
    throw const BinderItemInputException(
      'binder_condition_invalid',
      'Condição inválida. Use: NM, LP, MP, HP, DMG.',
    );
  }
  final normalized = value.trim().toUpperCase();
  if (!binderConditions.contains(normalized)) {
    throw const BinderItemInputException(
      'binder_condition_invalid',
      'Condição inválida. Use: NM, LP, MP, HP, DMG.',
    );
  }
  return normalized;
}

String readBinderLanguage(Object? value, {String fallback = 'en'}) {
  if (value == null) return fallback;
  if (value is! String) {
    throw const BinderItemInputException(
      'binder_language_invalid',
      'Idioma inválido.',
    );
  }
  final normalized = value.trim().toLowerCase().replaceAll('_', '-');
  if (normalized.length > 35 || !_languagePattern.hasMatch(normalized)) {
    throw const BinderItemInputException(
      'binder_language_invalid',
      'Idioma inválido.',
    );
  }
  return normalized;
}

String readBinderListType(Object? value, {String fallback = 'have'}) {
  if (value == null) return fallback;
  if (value is! String) {
    throw const BinderItemInputException(
      'binder_list_type_invalid',
      'list_type inválido. Use: have, want.',
    );
  }
  final normalized = value.trim().toLowerCase();
  if (!binderListTypes.contains(normalized)) {
    throw const BinderItemInputException(
      'binder_list_type_invalid',
      'list_type inválido. Use: have, want.',
    );
  }
  return normalized;
}

bool readBinderBoolean(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is! bool) {
    throw const BinderItemInputException(
      'binder_boolean_invalid',
      'Campo booleano inválido.',
    );
  }
  return value;
}

double? readBinderPrice(Object? value) {
  if (value == null) return null;
  final price = value is num ? value.toDouble() : double.tryParse('$value');
  if (price == null || !price.isFinite || price < 0) {
    throw const BinderItemInputException(
      'binder_price_invalid',
      'Preço inválido.',
    );
  }
  return price;
}

/// Troca e venda do fichário (SCOPE-P0-TRD-00, decisão D-39 do dono): na
/// beta, oferecer uma cópia para troca exige a capability `trades`, e para
/// venda, ou com preço de venda, exige `marketplace`. Com a capability
/// fechada, a escrita responde 422, erro explícito, em vez de zerar em
/// silêncio. Gravar `false` ou `null` continua valendo: é o que o app manda
/// quando a pessoa não oferece a cópia, e é também como se tira uma oferta.
const binderCommerceUnavailableCode = 'binder_commerce_unavailable';
const binderCommerceUnavailableMessage =
    'Troca e venda de cartas não estão disponíveis nesta beta.';

class BinderCommerceUnavailableException implements Exception {
  const BinderCommerceUnavailableException({
    required this.field,
    required this.capability,
  });

  /// O campo do corpo que pediu a oferta: `for_trade`, `for_sale` ou `price`.
  final String field;

  /// A capability que a oferta exige: `trades` ou `marketplace`.
  final String capability;

  @override
  String toString() => binderCommerceUnavailableMessage;
}

/// Recusa a escrita que ofereceria a cópia com a capability fechada. Campo
/// ausente do corpo vale `null` e nunca é recusado.
void ensureBinderCommerceAllowed({
  required bool? forTrade,
  required bool? forSale,
  required double? price,
  required bool Function(String capability) isAllowed,
}) {
  if (forTrade == true && !isAllowed('trades')) {
    throw const BinderCommerceUnavailableException(
      field: 'for_trade',
      capability: 'trades',
    );
  }
  if (forSale == true && !isAllowed('marketplace')) {
    throw const BinderCommerceUnavailableException(
      field: 'for_sale',
      capability: 'marketplace',
    );
  }
  if (price != null && !isAllowed('marketplace')) {
    throw const BinderCommerceUnavailableException(
      field: 'price',
      capability: 'marketplace',
    );
  }
}

/// Corpo da resposta 422, no formato de erro do fichário.
Map<String, Object> binderCommerceUnavailableBody(
  BinderCommerceUnavailableException error,
) => {
  'error': binderCommerceUnavailableMessage,
  'code': binderCommerceUnavailableCode,
  'field': error.field,
  'capability': error.capability,
};

String? readBinderNotes(Object? value) {
  if (value == null) return null;
  if (value is! String || value.length > 2000) {
    throw const BinderItemInputException(
      'binder_notes_invalid',
      'Observação inválida.',
    );
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
