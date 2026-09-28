import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'semantic role lookups read tag objects instead of array string keys',
    () {
      // As duas rotas que faziam essa consulta (recommendations e
      // weakness-analysis) saíram na D-31 (BT-AI-029). A guarda passa a valer
      // para todo o código do servidor: consulta nova por papel semântico lê
      // os objetos de `cstv2.tags`, nunca as chaves como texto.
      final offenders = <String>[];
      for (final root in ['lib', 'routes', 'bin']) {
        for (final file in Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
          if (file.readAsStringSync().contains('cstv2.tags ?| @role_tags')) {
            offenders.add(file.path);
          }
        }
      }
      expect(offenders, isEmpty);
    },
  );
}
