import 'dart:io';

import 'package:test/test.dart';

/// D-28 ("com os seletores acompanhando"): os seletores de candidatos do
/// Optimize não admitem carta sem linha de legalidade no formato. Só o
/// ranking de edições (`ORDER BY CASE ... WHEN cl.status IS NULL`) ainda
/// olha a ausência, para pôr a edição legal antes da desconhecida.
void main() {
  test('nenhum filtro de candidato admite legalidade ausente', () {
    final files =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .toList();
    final offenders = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final admitsMissing =
            line.contains('cl.status IS NULL') && !line.contains('WHEN');
        if (admitsMissing || line.contains('COUNT(cl.status) = 0')) {
          offenders.add('${file.path}:${index + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('o filtro por nome exige uma linha legal ou restrita', () {
    final source =
        File('lib/ai/optimize_format_legality_support.dart').readAsStringSync();
    expect(
      source,
      contains("HAVING BOOL_OR(cl.status IN ('legal', 'restricted'))"),
    );
  });
}
