import '../basic_land_utils.dart' as land_utils;
import 'optimization_functional_roles.dart';

/// Resolves the persisted meta-insight role from card rules metadata.
///
/// Card names are deliberately not accepted as input: names such as
/// "Lander Rizzi" or "Island Fish" are not rules evidence that a card is a
/// land. Unknown metadata stays unknown instead of being promoted by a name
/// substring.
String inferMetaInsightRole({
  required String typeLine,
  required String oracleText,
  String? manaCost,
  Object? cmc,
}) {
  if (land_utils.isLandTypeLine(typeLine)) return 'mana_base';

  final resolved = resolveCardFunctionalRoles(
    oracleText: oracleText,
    typeLine: typeLine,
    name: '',
    manaCost: manaCost,
    cmc: cmc,
  );

  return switch (resolved.primaryRole) {
    'land' => 'mana_base',
    'draw' => 'card_advantage',
    'utility' => 'unknown',
    final role => role,
  };
}
