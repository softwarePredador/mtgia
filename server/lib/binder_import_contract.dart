import 'binder_item_contract.dart';

class BinderImportInputException implements Exception {
  const BinderImportInputException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

const binderImportMaxItems = 100;

final RegExp _inputIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,95}$');

class BinderImportItem {
  const BinderImportItem({
    required this.inputId,
    required this.cardId,
    required this.quantity,
    required this.condition,
    required this.isFoil,
    required this.language,
    required this.listType,
    this.baselineQuantity,
    this.targetQuantity,
  });

  final String inputId;
  final String cardId;
  final int quantity;
  final String condition;
  final bool isFoil;
  final String language;
  final String listType;
  final int? baselineQuantity;
  final int? targetQuantity;

  String get identityKey => '$cardId|$condition|$isFoil|$language|$listType';

  Map<String, dynamic> toSqlJson() => {
    'input_id': inputId,
    'card_id': cardId,
    'quantity': quantity,
    'condition': condition,
    'is_foil': isFoil,
    'language': language,
    'list_type': listType,
  };
}

List<BinderImportItem> readBinderImportItems(
  Object? value, {
  required bool requireApplyPlan,
}) {
  if (value is! List || value.isEmpty) {
    throw const BinderImportInputException(
      'binder_import_items_required',
      'Envie ao menos uma carta para revisar.',
    );
  }
  if (value.length > binderImportMaxItems) {
    throw const BinderImportInputException(
      'binder_import_items_limit_exceeded',
      'Revise no máximo 100 cartas por lote.',
    );
  }

  final items = <BinderImportItem>[];
  final inputIds = <String>{};
  final identities = <String>{};
  for (final raw in value) {
    if (raw is! Map) {
      throw const BinderImportInputException(
        'binder_import_item_invalid',
        'Um item do lote é inválido.',
      );
    }
    final item = _readBinderImportItem(
      raw.cast<Object?, Object?>(),
      requireApplyPlan: requireApplyPlan,
    );
    if (!inputIds.add(item.inputId)) {
      throw const BinderImportInputException(
        'binder_import_input_id_duplicate',
        'O lote contém identificadores repetidos.',
      );
    }
    if (!identities.add(item.identityKey)) {
      throw const BinderImportInputException(
        'binder_import_identity_duplicate',
        'Agrupe linhas da mesma cópia física antes de aplicar o lote.',
      );
    }
    items.add(item);
  }
  return List.unmodifiable(items);
}

String readBinderImportBatchId(Object? value) {
  if (value is! String || !_inputIdPattern.hasMatch(value.trim())) {
    throw const BinderImportInputException(
      'binder_import_batch_id_invalid',
      'batch_id inválido.',
    );
  }
  return value.trim();
}

BinderImportItem _readBinderImportItem(
  Map<Object?, Object?> raw, {
  required bool requireApplyPlan,
}) {
  final inputIdValue = raw['input_id'];
  if (inputIdValue is! String ||
      !_inputIdPattern.hasMatch(inputIdValue.trim())) {
    throw const BinderImportInputException(
      'binder_import_input_id_invalid',
      'input_id inválido.',
    );
  }

  try {
    final quantity = readBinderQuantity(raw['quantity']);
    final baseline =
        requireApplyPlan
            ? _readNonNegativeQuantity(
              raw['baseline_quantity'],
              code: 'binder_import_baseline_invalid',
              message: 'baseline_quantity inválida.',
            )
            : null;
    final target =
        requireApplyPlan
            ? _readNonNegativeQuantity(
              raw['target_quantity'],
              code: 'binder_import_target_invalid',
              message: 'target_quantity inválida.',
            )
            : null;
    if (requireApplyPlan && target != baseline! + quantity) {
      throw const BinderImportInputException(
        'binder_import_plan_mismatch',
        'O plano mudou. Revise o lote novamente antes de aplicar.',
      );
    }

    return BinderImportItem(
      inputId: inputIdValue.trim(),
      cardId: readBinderCardId(raw['card_id']),
      quantity: quantity,
      condition: readBinderCondition(raw['condition']),
      isFoil: readBinderBoolean(raw['is_foil']),
      language: readBinderLanguage(raw['language']),
      listType: readBinderListType(raw['list_type']),
      baselineQuantity: baseline,
      targetQuantity: target,
    );
  } on BinderItemInputException catch (error) {
    throw BinderImportInputException(error.code, error.message);
  }
}

int _readNonNegativeQuantity(
  Object? value, {
  required String code,
  required String message,
}) {
  final quantity = switch (value) {
    int number => number,
    num number when number.isFinite && number == number.roundToDouble() =>
      number.toInt(),
    _ => null,
  };
  if (quantity == null || quantity < 0) {
    throw BinderImportInputException(code, message);
  }
  return quantity;
}
