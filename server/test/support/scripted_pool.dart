import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

/// Pool roteirizado para testes sem PostgreSQL.
///
/// Cada `execute` consome o próximo passo, na ordem: um [Result] é devolvido,
/// qualquer outro objeto é lançado. As consultas e os parâmetros ficam
/// registrados para o teste conferir o que chegou ao banco. `run` e `runTx`
/// executam no próprio pool, como uma sessão.
class ScriptedPool implements Pool<Object?>, TxSession {
  ScriptedPool(Iterable<Object> steps) : _steps = List.of(steps);

  final List<Object> _steps;
  final List<String> queries = [];
  final List<Object?> parameters = [];
  var _next = 0;

  int get executedCount => _next;
  bool get exhausted => _next == _steps.length;

  @override
  bool get isOpen => true;

  @override
  Future<void> get closed async {}

  @override
  Future<void> close({bool force = false}) async {}

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    queries.add(query is Sql ? query.toString() : '$query');
    this.parameters.add(parameters);
    if (_next >= _steps.length) {
      throw StateError('Consulta inesperada #${_next + 1}: $query');
    }
    final step = _steps[_next++];
    if (step is Result) return step;
    throw step;
  }

  @override
  Future<Statement> prepare(Object query) =>
      throw UnimplementedError('prepare não é usado nestes testes');

  @override
  Future<R> run<R>(
    Future<R> Function(Session session) fn, {
    SessionSettings? settings,
    Object? locality,
  }) => fn(this);

  @override
  Future<R> runTx<R>(
    Future<R> Function(TxSession session) fn, {
    TransactionSettings? settings,
    Object? locality,
  }) => fn(this);

  @override
  Future<void> rollback() async {}

  @override
  Future<R> withConnection<R>(
    Future<R> Function(Connection connection) fn, {
    ConnectionSettings? settings,
    Object? locality,
  }) => throw UnimplementedError('withConnection não é usado nestes testes');
}

/// Resultado com as colunas nomeadas, para `toColumnMap()` funcionar.
Result scriptedResult({
  List<String> columns = const [],
  List<List<Object?>> rows = const [],
}) {
  final schema = ResultSchema([
    for (final column in columns)
      ResultSchemaColumn(
        typeOid: 0,
        type: Type.unspecified,
        columnName: column,
      ),
  ]);
  return Result(
    rows: [for (final row in rows) ResultRow(values: row, schema: schema)],
    affectedRows: rows.length,
    schema: schema,
  );
}

/// Contexto de requisição com provedores explícitos por tipo.
class ScriptedRequestContext implements RequestContext {
  ScriptedRequestContext(this.request, {Map<Type, Object> providers = const {}})
    : _providers = providers;

  @override
  final Request request;
  final Map<Type, Object> _providers;

  @override
  Map<String, String> get mountedParams => const {};

  @override
  RequestContext provide<T extends Object?>(T Function() create) => this;

  @override
  T read<T>() {
    final value = _providers[T];
    if (value == null) {
      throw StateError('Sem provedor de $T neste teste.');
    }
    return value as T;
  }
}
