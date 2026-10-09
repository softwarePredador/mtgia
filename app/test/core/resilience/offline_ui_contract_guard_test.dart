import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// An offline promise, in code or in text shown to the user.
final _offlineClaim = RegExp(r'\boffline\b|sem conexão', caseSensitive: false);

void main() {
  test('offline claims exist only on governed runtime surfaces', () {
    final claims = <String>{};
    final firstLines = <String, String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // The guard is about promises the app makes, and those live in code and
      // string literals. A comment that says "offline" promises nothing, so
      // comments are blanked before the search.
      final code = stripDartComments(entity.readAsStringSync());
      final match = _offlineClaim.firstMatch(code);
      if (match == null) continue;
      claims.add(entity.path);
      final lines = code.split('\n');
      final line = code.substring(0, match.start).split('\n').length;
      firstLines[entity.path] =
          '${entity.path}:$line: '
          '${lines[line - 1].trim()}';
    }

    const governed = <String>{
      'lib/core/resilience/offline_capability.dart',
      'lib/core/widgets/app_state_panel.dart',
      'lib/core/widgets/card_artwork.dart',
    };
    expect(
      claims,
      governed,
      reason:
          'claims outside the governed surfaces: '
          '${claims.difference(governed).map((path) => firstLines[path])}',
    );
  });

  group('stripDartComments', () {
    bool claims(String source) =>
        _offlineClaim.hasMatch(stripDartComments(source));

    test('ignores offline in line, doc and block comments', () {
      const source = '''
// Works offline.
/// Queued offline until the sync.
final a = 1; /* offline */ final b = 2;
/** sem conexão */
''';
      expect(claims(source), isFalse);
      final stripped = stripDartComments(source);
      expect(stripped.length, source.length);
      expect(stripped.split('\n').length, source.split('\n').length);
      expect(stripped, contains('final a = 1;'));
      expect(stripped, contains('final b = 2;'));
    });

    test('catches offline in strings and in code', () {
      expect(claims("final label = 'Funciona offline';"), isTrue);
      expect(claims('final label = "Sem conexão com o servidor";'), isTrue);
      expect(claims('enum State { online, offline }'), isTrue);
    });

    test('a // inside a string does not start a comment', () {
      expect(claims("final url = 'https://example.com/offline';"), isTrue);
      expect(claims('final hint = "// funciona offline";'), isTrue);
      expect(claims("final url = 'https://x'; final offline = 1;"), isTrue);
      expect(claims("final url = 'https://x'; // offline"), isFalse);
      expect(claims("final quote = 'it\\'s // offline';"), isTrue);
    });

    test('block comments nest', () {
      const source = '/* outer /* inner */ still offline */ final x = 1;';
      expect(claims(source), isFalse);
      expect(stripDartComments(source), endsWith(' final x = 1;'));
      expect(claims('/* a /* b /* c */ d */ e */ final offline = 1;'), isTrue);
    });

    test('raw strings keep offline and have no escapes', () {
      expect(claims("final path = r'C:\\offline';"), isTrue);
      expect(claims('final hint = r"// offline";'), isTrue);
      expect(claims(r"final path = r'C:\'; // offline"), isFalse);
      expect(claims(r"final text = r'''// offline''';"), isTrue);
    });

    test('triple-quoted strings keep offline across lines', () {
      const source = """
final text = '''
first line
// funciona offline
''';
""";
      expect(claims(source), isTrue);
      expect(claims('final text = """a "quoted" offline""";'), isTrue);
      expect(claims("final text = '''it's'''; // offline"), isFalse);
    });

    test('interpolation is code: its strings count, its comments do not', () {
      expect(claims(r"final s = '${map['offline']}';"), isTrue);
      expect(claims(r"final s = '${a /* offline */}';"), isFalse);
      expect(claims(r"""final s = '${"'"}'; // offline"""), isFalse);
      expect(claims(r"""final s = "${'//'} offline";"""), isTrue);
      expect(claims(r"final s = '${{'k': 1}['k']} // offline';"), isTrue);
      const source = r"""
final text = '''${
  value // offline
}''';
""";
      expect(claims(source), isFalse);
    });
  });

  test('cached reads and provider errors cannot regress to false claims', () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final scanner = File(
      'lib/features/scanner/utils/scanner_error_mapper.dart',
    ).readAsStringSync();
    final messages = File(
      'lib/features/messages/providers/message_provider.dart',
    ).readAsStringSync();

    expect(home, isNot(contains('offline-cache')));
    expect(home, contains('cached-read-only'));
    expect(scanner, contains('OfflineProductFlow.cardCatalog'));
    expect(messages, isNot(contains("_error = '\$e'")));
    expect(messages, contains('FriendlyErrorContext.directMessage'));
  });
}

/// Returns [source] with every Dart comment blanked and every string kept.
///
/// Comment characters become spaces and line breaks stay, so offsets and line
/// numbers still point at the original file. The scanner follows the Dart
/// lexical rules that decide where a comment starts: `//` and `///` run to the
/// end of the line, `/* */` comments nest, a `//` inside a string literal is
/// text, raw strings (`r'...'`) have no escapes and no interpolation,
/// triple-quoted strings span lines, and a `${...}` interpolation is code
/// again, with its own strings and comments. It assumes the source compiles.
String stripDartComments(String source) {
  final out = StringBuffer();
  final contexts = <_LexicalContext>[_LexicalContext.code()];
  var i = 0;

  void blankUntil(int end) {
    for (; i < end; i++) {
      final char = source[i];
      out.write(char == '\n' || char == '\r' ? char : ' ');
    }
  }

  while (i < source.length) {
    final context = contexts.last;
    final char = source[i];
    final delimiter = context.delimiter;

    if (delimiter != null) {
      if (!context.raw && char == r'\' && i + 1 < source.length) {
        out.write(source.substring(i, i + 2));
        i += 2;
      } else if (!context.raw && source.startsWith(r'${', i)) {
        out.write(r'${');
        i += 2;
        contexts.add(_LexicalContext.code());
      } else if (source.startsWith(delimiter, i)) {
        out.write(delimiter);
        i += delimiter.length;
        contexts.removeLast();
      } else {
        out.write(char);
        i++;
      }
      continue;
    }

    if (source.startsWith('//', i)) {
      var end = i;
      while (end < source.length &&
          source[end] != '\n' &&
          source[end] != '\r') {
        end++;
      }
      blankUntil(end);
      continue;
    }
    if (source.startsWith('/*', i)) {
      var depth = 0;
      var end = i;
      while (end < source.length) {
        if (source.startsWith('/*', end)) {
          depth++;
          end += 2;
        } else if (source.startsWith('*/', end)) {
          depth--;
          end += 2;
          if (depth == 0) break;
        } else {
          end++;
        }
      }
      blankUntil(end);
      continue;
    }

    final raw =
        (char == 'r' || char == 'R') &&
        i + 1 < source.length &&
        _isQuote(source[i + 1]) &&
        (i == 0 || !_isIdentifierPart(source[i - 1]));
    final quoteAt = raw ? i + 1 : i;
    if (_isQuote(source[quoteAt])) {
      final quote = source[quoteAt];
      final opening = source.startsWith(quote * 3, quoteAt) ? quote * 3 : quote;
      final end = quoteAt + opening.length;
      out.write(source.substring(i, end));
      i = end;
      contexts.add(_LexicalContext.string(opening, raw: raw));
      continue;
    }

    if (char == '{') {
      context.openBraces++;
    } else if (char == '}') {
      if (context.openBraces > 0) {
        context.openBraces--;
      } else if (contexts.length > 1) {
        // The `}` that closes a `${` returns to the enclosing string.
        contexts.removeLast();
      }
    }
    out.write(char);
    i++;
  }
  return out.toString();
}

bool _isQuote(String char) => char == "'" || char == '"';

final _identifierPart = RegExp(r'[A-Za-z0-9_$]');

bool _isIdentifierPart(String char) => _identifierPart.hasMatch(char);

/// Where the scanner is: code (with the `{` it still has to close) or the
/// inside of a string literal opened by [delimiter].
class _LexicalContext {
  _LexicalContext.code() : delimiter = null, raw = false;

  _LexicalContext.string(String this.delimiter, {required this.raw});

  final String? delimiter;
  final bool raw;
  int openBraces = 0;
}
