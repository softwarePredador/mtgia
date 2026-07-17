/// Divide um script PostgreSQL somente em terminadores `;` de nivel superior.
///
/// Preserva ponto e virgula dentro de strings, identificadores, comentarios e
/// corpos dollar-quoted (`$$...$$` ou `$tag$...$tag$`), como os usados por
/// funcoes e blocos `DO` em PL/pgSQL.
List<String> splitPostgresStatements(String script) {
  final statements = <String>[];
  final current = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var inLineComment = false;
  var blockCommentDepth = 0;
  String? dollarTag;

  var index = 0;
  while (index < script.length) {
    if (dollarTag != null) {
      if (script.startsWith(dollarTag, index)) {
        current.write(dollarTag);
        index += dollarTag.length;
        dollarTag = null;
      } else {
        current.write(script[index]);
        index++;
      }
      continue;
    }

    final char = script[index];
    final next = index + 1 < script.length ? script[index + 1] : null;

    if (inLineComment) {
      current.write(char);
      index++;
      if (char == '\n') inLineComment = false;
      continue;
    }

    if (blockCommentDepth > 0) {
      if (char == '/' && next == '*') {
        current.write('/*');
        blockCommentDepth++;
        index += 2;
      } else if (char == '*' && next == '/') {
        current.write('*/');
        blockCommentDepth--;
        index += 2;
      } else {
        current.write(char);
        index++;
      }
      continue;
    }

    if (inSingleQuote) {
      current.write(char);
      index++;
      if (char == "'" && next == "'") {
        current.write(next);
        index++;
      } else if (char == r'\' && next != null) {
        current.write(next);
        index++;
      } else if (char == "'") {
        inSingleQuote = false;
      }
      continue;
    }

    if (inDoubleQuote) {
      current.write(char);
      index++;
      if (char == '"' && next == '"') {
        current.write(next);
        index++;
      } else if (char == '"') {
        inDoubleQuote = false;
      }
      continue;
    }

    if (char == '-' && next == '-') {
      current.write('--');
      inLineComment = true;
      index += 2;
      continue;
    }
    if (char == '/' && next == '*') {
      current.write('/*');
      blockCommentDepth = 1;
      index += 2;
      continue;
    }
    if (char == "'") {
      current.write(char);
      inSingleQuote = true;
      index++;
      continue;
    }
    if (char == '"') {
      current.write(char);
      inDoubleQuote = true;
      index++;
      continue;
    }
    if (char == r'$') {
      final tag = _dollarQuoteTagAt(script, index);
      if (tag != null) {
        current.write(tag);
        dollarTag = tag;
        index += tag.length;
        continue;
      }
    }
    if (char == ';') {
      _appendStatement(statements, current);
      index++;
      continue;
    }

    current.write(char);
    index++;
  }

  _appendStatement(statements, current);
  return List<String>.unmodifiable(statements);
}

String? _dollarQuoteTagAt(String script, int start) {
  if (script[start] != r'$') return null;
  var cursor = start + 1;
  if (cursor >= script.length) return null;
  if (script[cursor] == r'$') return r'$$';
  if (!_isIdentifierStart(script.codeUnitAt(cursor))) return null;

  cursor++;
  while (cursor < script.length &&
      _isIdentifierPart(script.codeUnitAt(cursor))) {
    cursor++;
  }
  if (cursor >= script.length || script[cursor] != r'$') return null;
  return script.substring(start, cursor + 1);
}

bool _isIdentifierStart(int codeUnit) =>
    codeUnit == 95 ||
    (codeUnit >= 65 && codeUnit <= 90) ||
    (codeUnit >= 97 && codeUnit <= 122);

bool _isIdentifierPart(int codeUnit) =>
    _isIdentifierStart(codeUnit) || (codeUnit >= 48 && codeUnit <= 57);

void _appendStatement(List<String> statements, StringBuffer current) {
  final statement = current.toString().trim();
  current.clear();
  if (statement.isNotEmpty) statements.add(statement);
}
