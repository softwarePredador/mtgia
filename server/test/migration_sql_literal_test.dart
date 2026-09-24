import 'dart:io';

import 'package:test/test.dart';

import '../bin/migrate.dart' as migrate;

/// D-65 (BT-DB-004): nenhuma migration monta SQL com código que pode mudar.
///
/// As migrations 023 e 024 interpolavam uma constante de `server/lib`; a
/// constante mudou depois e um banco novo passou a sair diferente da produção.
/// Aqui cada `up` e `down` da lista de `bin/migrate.dart` tem de ser texto
/// literal: sem `$nome`, sem `${...}`, sem identificador, chamada ou `+`.
void main() {
  final source = File('bin/migrate.dart').readAsStringSync();
  final start = source.indexOf('final migrations = <Migration>[');
  final end = source.indexOf('\n];\n\nclass Migration {', start);
  final list = source.substring(start, end);

  test('o lexer enxerga todas as migrations da lista', () {
    expect(start, greaterThan(0));
    expect(end, greaterThan(start));
    final entries = RegExp(r'\n  Migration\(\n').allMatches(list).length;
    expect(entries, migrate.migrations.length);
    final ups = RegExp(r'\n    up: ').allMatches(list).length;
    final downs = RegExp(r'\n    down: ').allMatches(list).length;
    expect(ups, migrate.migrations.length);
    expect(
      downs,
      migrate.migrations.where((migration) => migration.down != null).length,
    );
  });

  test('todo up e down é SQL literal, sem interpolação', () {
    final violations = <String>[];
    for (final match in RegExp(r'\n    (up|down): ').allMatches(list)) {
      final version = RegExp(
        r"version: '(\d{3})'",
      ).allMatches(list.substring(0, match.start)).last.group(1);
      final problem = literalProblem(list, match.end);
      if (problem != null) {
        violations.add('$version ${match.group(1)}: $problem');
      }
    }
    expect(violations, isEmpty);
  });

  group('o lexer reconhece interpolação e código', () {
    for (final (label, value, expected) in const [
      ("string crua", "r'''SELECT 1'''\n  ),", null),
      ("dólar escapado", "'''SELECT \\\$1'''\n  ),", null),
      ("literais adjacentes", "'SELECT ' 'FROM t'\n  ),", null),
      ("interpolação simples", "'''\$sqlConstante;'''\n  ),", 'interpola'),
      (
        "interpolação com chaves",
        "'''\${lista.join(';')}'''\n  ),",
        'interpola',
      ),
      (
        "identificador",
        "collectionAvailabilityViewsSql,\n  ),",
        'não é literal',
      ),
      ("concatenação", "'''SELECT 1''' + sufixo,\n  ),", 'depois do literal'),
    ]) {
      test(label, () {
        final problem = literalProblem(value, 0);
        if (expected == null) {
          expect(problem, isNull);
        } else {
          expect(problem, contains(expected));
        }
      });
    }
  });
}

/// Confere o valor que começa em [offset]: uma ou mais strings literais
/// seguidas de `,` ou `)`. Devolve o problema, ou nulo.
String? literalProblem(String text, int offset) {
  var index = offset;
  var literals = 0;
  while (true) {
    while (index < text.length && ' \n\t'.contains(text[index])) {
      index++;
    }
    final raw = text.startsWith('r', index);
    final quoteStart = raw ? index + 1 : index;
    String? quote;
    for (final candidate in const ["'''", '"""', "'", '"']) {
      if (text.startsWith(candidate, quoteStart)) {
        quote = candidate;
        break;
      }
    }
    if (quote == null) {
      if (literals == 0) return 'não é literal: ${_preview(text, index)}';
      if (index < text.length && ',)'.contains(text[index])) return null;
      return 'algo depois do literal: ${_preview(text, index)}';
    }
    var cursor = quoteStart + quote.length;
    while (true) {
      if (cursor >= text.length) return 'string sem fim';
      if (!raw && text[cursor] == r'\') {
        cursor += 2;
        continue;
      }
      if (!raw && text[cursor] == r'$') {
        return 'interpola: ${_preview(text, cursor)}';
      }
      if (text.startsWith(quote, cursor)) {
        cursor += quote.length;
        break;
      }
      cursor++;
    }
    literals++;
    index = cursor;
  }
}

String _preview(String text, int at) {
  final end = at + 40 < text.length ? at + 40 : text.length;
  return text.substring(at, end).replaceAll('\n', ' ');
}
