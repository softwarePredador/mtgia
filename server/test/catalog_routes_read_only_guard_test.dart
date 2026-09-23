import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// BT-CAT-02 e BT-CAT-04 (decisão D-35 do dono): nenhuma das 7 rotas de
/// catálogo, nem as bibliotecas que elas importam direto, grava no banco ou
/// abre cliente HTTP. As provas de comportamento das duas rotas que antes
/// escreviam estão em `cards_printings_read_only_test.dart` e
/// `cards_resolve_read_only_test.dart`; esta guarda barra a volta do padrão
/// em qualquer rota nova sob `/cards`, `/sets` ou `/rules`.
void main() {
  final dml = RegExp(
    r'\b(INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|TRUNCATE|ON\s+CONFLICT|MERGE\s+INTO)\b',
    caseSensitive: false,
  );
  final httpClient = RegExp(r"package:http/|HttpClient\(|dart:io.*HttpClient");
  final libImport = RegExp(
    r"^import '((?:\.\./)+lib/[^']+\.dart)';",
    multiLine: true,
  );

  List<String> catalogRoutes() {
    final files = <String>[];
    for (final directory in const [
      'routes/cards',
      'routes/sets',
      'routes/rules',
    ]) {
      for (final entity in Directory(directory).listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          files.add(p.normalize(entity.path));
        }
      }
    }
    return files..sort();
  }

  test('o inventário cobre as 7 rotas de catálogo', () {
    expect(catalogRoutes(), [
      'routes/cards/[id]/rulings/index.dart',
      'routes/cards/index.dart',
      'routes/cards/printings/index.dart',
      'routes/cards/resolve/batch/index.dart',
      'routes/cards/resolve/index.dart',
      'routes/rules/index.dart',
      'routes/sets/index.dart',
    ]);
  });

  test(
    'rotas de catálogo e suas bibliotecas não gravam nem chamam terceiro',
    () {
      final checked = <String>{};
      for (final route in catalogRoutes()) {
        checked.add(route);
        final source = File(route).readAsStringSync();
        for (final match in libImport.allMatches(source)) {
          checked.add(p.normalize(p.join(p.dirname(route), match.group(1)!)));
        }
      }

      expect(checked, contains('lib/catalog_read_contract.dart'));
      for (final path in checked) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(matches(httpClient)), reason: path);
        expect(source, isNot(matches(dml)), reason: path);
      }
    },
  );
}
