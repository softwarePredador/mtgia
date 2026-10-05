import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../lib/privacy/account_deletion_outbox.dart';
import '../lib/privacy/hermes_learning_purge.dart';

/// BT-PRIV-002: a varredura do Hermes do outbox da exclusão, sem banco. O
/// casamento com os tombstones e a conferência da linha são do PostgreSQL e
/// ficam no teste de banco; aqui entram falsos, para provar a ordem: o que o
/// auxiliar lista, o que apaga sob o lock, as rodadas e os códigos.
void main() {
  late Directory tmp;
  late String dbPath;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('hermes_purge_');
    dbPath = '${tmp.path}/knowledge.db';
    File(dbPath).writeAsStringSync('');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  const deletedA = 'aaaaaaaa-0000-4000-8000-000000000001';
  const deletedB = 'bbbbbbbb-0000-4000-8000-000000000002';
  const lateInsert = 'cccccccc-0000-4000-8000-000000000003';
  const kept = 'dddddddd-0000-4000-8000-000000000004';
  const deleted = {deletedA, deletedB, lateInsert};

  AccountDeletionOutboxRow row(String id, {String runId = 'run-1'}) =>
      AccountDeletionOutboxRow(
        id: id,
        consumer: 'hermes_learning_sqlite',
        attempts: 1,
        runId: runId,
      );

  HermesLearningPurge purge(
    _FakeHelper helper, {
    String? path,
    bool rowClean = true,
  }) => HermesLearningPurge(
    HermesKnowledgeDbConfig(path: path ?? dbPath),
    helper: helper,
    matcher:
        (_, ids) async => [
          for (final id in ids)
            if (deleted.contains(id)) id,
        ],
    rowCheck: (_, __, ___) async => rowClean,
  );

  final session = _NoSession();

  test('apaga os decks apagados que o arquivo guarda e conclui com as '
      'contagens', () async {
    final helper = _FakeHelper(
      listed: _ok([deletedA, deletedB, kept]),
      purges: [
        _ok([kept], counts: {'events_deleted': 3, 'decks_deleted': 1}),
      ],
    );
    final outcome = await purge(helper).handle(session, row('r1'));
    expect(outcome, isA<OutboxDone>());
    final done = outcome as OutboxDone;
    expect(done.code, hermesLearningPurgeCode);
    expect(done.counts, {'events_deleted': 3, 'decks_deleted': 1});
    expect(helper.purgeCalls, [
      [deletedA, deletedB],
    ]);
  });

  test('sem nada a apagar, o purge roda assim mesmo: só a lista sob o lock '
      'prova o estado do arquivo', () async {
    final helper = _FakeHelper(
      listed: _ok([kept]),
      purges: [
        _ok([kept]),
      ],
    );
    final outcome = await purge(helper).handle(session, row('r1'));
    expect((outcome as OutboxDone).code, hermesLearningPurgeCode);
    expect(helper.purgeCalls, [<String>[]]);
  });

  test(
    'evento gravado entre a lista e o lock sai na rodada seguinte',
    () async {
      final helper = _FakeHelper(
        listed: _ok([deletedA, kept]),
        purges: [
          _ok([kept, lateInsert], counts: {'events_deleted': 2}),
          _ok([kept], counts: {'events_deleted': 1}),
        ],
      );
      final outcome = await purge(helper).handle(session, row('r1'));
      expect((outcome as OutboxDone).counts, {'events_deleted': 3});
      expect(helper.purgeCalls, [
        [deletedA],
        [lateInsert],
      ]);
    },
  );

  test('quem continua gravando deck apagado faz a linha falhar depois de '
      'três rodadas', () async {
    final helper = _FakeHelper(
      listed: _ok([deletedA]),
      purges: [
        for (var round = 0; round < 3; round++) _ok([lateInsert]),
      ],
    );
    final outcome = await purge(helper).handle(session, row('r1'));
    expect((outcome as OutboxFailed).code, 'hermes_purge_incomplete');
    expect(helper.purgeCalls, hasLength(3));
  });

  test('uma varredura por execução; as contagens vão uma vez só', () async {
    final helper = _FakeHelper(
      listed: _ok([deletedA]),
      purges: [
        _ok([], counts: {'events_deleted': 2}),
        _ok([]),
      ],
    );
    final handler = purge(helper);
    final first = await handler.handle(session, row('r1')) as OutboxDone;
    final second = await handler.handle(session, row('r2')) as OutboxDone;
    expect(first.counts, {'events_deleted': 2});
    expect(second.counts, isEmpty);
    expect(helper.listCalls, 1);

    final nextRun =
        await handler.handle(session, row('r3', runId: 'run-2')) as OutboxDone;
    expect(helper.listCalls, 2);
    expect(nextRun.code, hermesLearningPurgeCode);
  });

  test('linha com deck que ficou no arquivo falha', () async {
    final helper = _FakeHelper(
      listed: _ok([kept]),
      purges: [
        _ok([kept]),
      ],
    );
    final outcome = await purge(
      helper,
      rowClean: false,
    ).handle(session, row('r1'));
    expect((outcome as OutboxFailed).code, 'hermes_purge_incomplete');
  });

  test('sem caminho configurado, a linha falha e volta depois', () async {
    final helper = _FakeHelper(listed: _ok([]), purges: []);
    final handler = HermesLearningPurge(
      const HermesKnowledgeDbConfig(path: null),
      helper: helper,
      matcher: (_, ids) async => ids,
      rowCheck: (_, __, ___) async => true,
    );
    final outcome = await handler.handle(session, row('r1'));
    expect(
      (outcome as OutboxFailed).code,
      'hermes_knowledge_db_not_configured',
    );
    expect(helper.listCalls, 0);
  });

  test('pasta do knowledge.db ausente falha; arquivo ausente numa pasta que '
      'existe conclui: o Hermes nunca guardou nada ali', () async {
    final helper = _FakeHelper(listed: _ok([]), purges: []);
    final missingDir = await purge(
      helper,
      path: '${tmp.path}/nao_existe/knowledge.db',
    ).handle(session, row('r1'));
    expect(
      (missingDir as OutboxFailed).code,
      'hermes_knowledge_db_dir_missing',
    );
    final absent = await purge(
      helper,
      path: '${tmp.path}/outro.db',
    ).handle(session, row('r1'));
    expect((absent as OutboxDone).code, hermesKnowledgeDbAbsentCode);
    expect(helper.listCalls, 0);
  });

  test('arquivo ocupado ou auxiliar com erro fazem a linha falhar com o '
      'motivo', () async {
    for (final (listed, purges, code) in [
      (
        const HermesPurgeCall(HermesPurgeStatus.busy),
        <HermesPurgeCall>[],
        'hermes_knowledge_db_busy',
      ),
      (
        const HermesPurgeCall(HermesPurgeStatus.error),
        <HermesPurgeCall>[],
        'hermes_purge_helper_error',
      ),
      (
        _ok([deletedA]),
        [const HermesPurgeCall(HermesPurgeStatus.busy)],
        'hermes_knowledge_db_busy',
      ),
      (
        _ok([deletedA]),
        [const HermesPurgeCall(HermesPurgeStatus.error)],
        'hermes_purge_helper_error',
      ),
    ]) {
      final outcome = await purge(
        _FakeHelper(listed: listed, purges: purges),
      ).handle(session, row('r1'));
      expect((outcome as OutboxFailed).code, code);
    }
  });

  test('os contratos Python do expurgo e do alimentador passam (rodam com a '
      'suíte do servidor)', () async {
    for (final contract in const [
      'test/hermes_learning_purge_test.py',
      'test/pull_learning_events_deletion_test.py',
    ]) {
      final result = await Process.run(
        'python3',
        [contract],
        environment: const {'PYTHONWARNINGS': 'error::ResourceWarning'},
      );
      expect(
        result.exitCode,
        0,
        reason: '$contract\n${result.stdout}\n${result.stderr}',
      );
    }
  });

  group('ProcessHermesPurgeHelper', () {
    String script(String body) {
      final file = File('${tmp.path}/helper_${body.hashCode}.py')
        ..writeAsStringSync('import sys\n$body\n');
      return file.path;
    }

    Future<HermesPurgeCall> call(String helperScript, String command) {
      final helper = ProcessHermesPurgeHelper(
        HermesKnowledgeDbConfig(path: dbPath, helperScript: helperScript),
      );
      return command == 'list'
          ? helper.list(dbPath)
          : helper.purge(dbPath, [deletedA]);
    }

    test('lê a lista e as contagens do stdout', () async {
      final listed = await call(
        script('print(\'{"deck_ids": ["$kept"]}\')'),
        'list',
      );
      expect(listed.status, HermesPurgeStatus.ok);
      expect(listed.deckIds, [kept]);

      final purged = await call(
        script(
          'sys.stdin.read()\n'
          'print(\'{"remaining_deck_ids": [], "events_deleted": 2, '
          '"decks_deleted": 0, "deck_cards_deleted": 0}\')',
        ),
        'purge',
      );
      expect(purged.status, HermesPurgeStatus.ok);
      expect(purged.deckIds, isEmpty);
      expect(purged.counts, {
        'events_deleted': 2,
        'decks_deleted': 0,
        'deck_cards_deleted': 0,
      });
    });

    test('3 é ausente, 4 é ocupado, o resto é erro', () async {
      expect(
        (await call(script('sys.exit(3)'), 'list')).status,
        HermesPurgeStatus.absent,
      );
      expect(
        (await call(script('sys.exit(4)'), 'purge')).status,
        HermesPurgeStatus.busy,
      );
      expect(
        (await call(script('sys.exit(1)'), 'list')).status,
        HermesPurgeStatus.error,
      );
      expect(
        (await call(script('print("nao e json")'), 'list')).status,
        HermesPurgeStatus.error,
      );
    });

    test('sem o interpretador, é erro', () async {
      final helper = ProcessHermesPurgeHelper(
        HermesKnowledgeDbConfig(
          path: dbPath,
          pythonBin: '${tmp.path}/sem_python',
        ),
      );
      expect((await helper.list(dbPath)).status, HermesPurgeStatus.error);
    });
  });
}

HermesPurgeCall _ok(List<String> ids, {Map<String, int> counts = const {}}) =>
    HermesPurgeCall(HermesPurgeStatus.ok, deckIds: ids, counts: counts);

class _FakeHelper implements HermesPurgeHelper {
  _FakeHelper({required this.listed, required List<HermesPurgeCall> purges})
    : _purges = [...purges];

  final HermesPurgeCall listed;
  final List<HermesPurgeCall> _purges;
  final purgeCalls = <List<String>>[];
  var listCalls = 0;

  @override
  Future<HermesPurgeCall> list(String dbPath) async {
    listCalls++;
    return listed;
  }

  @override
  Future<HermesPurgeCall> purge(String dbPath, List<String> deckIds) async {
    purgeCalls.add([...deckIds]);
    return _purges.removeAt(0);
  }
}

class _NoSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('o teste unitário não usa banco');
}
