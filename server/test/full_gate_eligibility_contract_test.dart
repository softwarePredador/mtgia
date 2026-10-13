import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// G-10: `scripts/manaloom_full_gate_eligibility.py` lista, a partir do
/// registry do próprio SHA, quais tarefas IMPLEMENTED_LOCAL_PENDING_FULL_GATE
/// ficam elegíveis a PASS quando o full fica verde nesse SHA. Só lê.
///
/// O teste monta um repositório Git descartável com um registry, receipts,
/// um commit de servidor, um de UI e um fora do SHA, e confere cada classe,
/// o ponto fixo das dependências, o receipt do full e que nada no repositório
/// muda. A prova de UI falha fechada: os commits da tarefa vêm do aceite, dos
/// receipts citados e dos commits do SHA cujo assunto nomeia o ID (direto, em
/// faixa, em lista e pela família no escopo, inclusive com várias famílias);
/// o commit que só cita o ID no corpo conta para a UI, mas não é rastro; um
/// merge citado conta para a UI pelo que traz (`--diff-merges=separate`), e o
/// commit fora do SHA citado num receipt não é rastro; sem nenhum commit que
/// mude código, a tarefa não sai `elegivel`. A dependência da rodada que pode
/// ficar (prova de UI, sem rastro, pendência declarada, em cadeia) deixa a
/// dependente em `elegivel_se_dependencia_subir`. A lista e o comando de
/// confirmação do modelo de receipt não dependem da configuração do Git de
/// quem roda (`log.diffMerges`, `diff.renames`): um merge mostra o que
/// trouxe, e um arquivo movido para fora da UI mostra o caminho antigo.
void main() {
  final script = File(
    '${Directory.current.parent.path}/scripts/manaloom_full_gate_eligibility.py',
  );
  const pending = 'IMPLEMENTED_LOCAL_PENDING_FULL_GATE';

  late Directory repo;
  late String head;
  late String serverCommit;
  late String uiCommit;
  late String outsideCommit;
  late String messageUiCommit;
  late String seriesCommit;
  late String familyCommit;
  late String docsOnlyCommit;
  late String mergeCommit;
  late String uiMergeCommit;
  late String multiFamilyCommit;
  late String subjectServerCommit;
  late String bodyUiCommit;
  late String renameCommit;

  /// Configuração do Git de quem roda que muda a saída de `git show`: com ela,
  /// `-m` mostra um merge vazio e a renomeação esconde o caminho antigo.
  const hostileConfig = {'log.diffMerges': 'combined', 'diff.renames': 'true'};

  Future<String> git(
    List<String> args, {
    Map<String, String> config = const {},
  }) async {
    final result = await Process.run('git', [
      '-c',
      'user.name=Teste',
      '-c',
      'user.email=teste@example.invalid',
      '-c',
      'commit.gpgsign=false',
      '-c',
      'core.hooksPath=/dev/null',
      for (final entry in config.entries) ...[
        '-c',
        '${entry.key}=${entry.value}',
      ],
      '-C',
      repo.path,
      ...args,
    ]);
    if (result.exitCode != 0) {
      fail('git ${args.join(' ')}: ${result.stderr}');
    }
    return (result.stdout as String).trim();
  }

  void write(String path, String contents) {
    File('${repo.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(contents);
  }

  Map<String, Object?> task(
    String id,
    String status, {
    List<String> deps = const [],
    String acceptance = 'Aceite.',
  }) => {
    'id': id,
    'priority': 'P0 CORE',
    'status': status,
    'delivery': 'Entrega de $id.',
    'depends_on': deps,
    'acceptance': acceptance,
  };

  setUpAll(() async {
    repo = await Directory.systemTemp.createTemp('manaloom_g10_');
    await git(['init', '-q', '-b', 'master']);
    write(
      'scripts/manaloom_ui_source_digest.sh',
      'SOURCE_ROOTS=(\n  "app/lib"\n  "app/pubspec.yaml"\n)\n',
    );
    write('server/lib/servico.dart', 'void a() {}\n');
    write('app/lib/tela.dart', 'void b() {}\n');
    write('app/lib/movida.dart', 'void movida() {\n  print(26);\n}\n');
    write('docs/qa/execution/2026-10-01/T1.md', '# receipt T1\n');
    await git(['add', '-A']);
    await git(['commit', '-q', '-m', 'base']);

    // Commit fora do SHA: numa branch que nunca entra no master.
    await git(['checkout', '-q', '-b', 'lado']);
    write('server/lib/lado.dart', 'void c() {}\n');
    await git(['add', '-A']);
    await git(['commit', '-q', '-m', 'lado']);
    outsideCommit = await git(['rev-parse', 'HEAD']);
    await git(['checkout', '-q', 'master']);

    write('server/lib/servico.dart', 'void a() { print(1); }\n');
    await git(['add', '-A']);
    await git(['commit', '-q', '-m', 'servidor']);
    serverCommit = await git(['rev-parse', 'HEAD']);
    write('app/lib/tela.dart', 'void b() { print(2); }\n');
    await git(['add', '-A']);
    await git(['commit', '-q', '-m', 'ui']);
    uiCommit = await git(['rev-parse', 'HEAD']);

    // Commits que só a mensagem liga à tarefa: o aceite não os cita.
    Future<String> commit(String path, String contents, String message) async {
      write(path, contents);
      await git(['add', '-A']);
      await git(['commit', '-q', '-m', message]);
      return git(['rev-parse', 'HEAD']);
    }

    messageUiCommit = await commit(
      'app/lib/tela10.dart',
      'void t10() {}\n',
      'feat(T10): tela nova\n\nSem citar caminho no aceite.',
    );
    seriesCommit = await commit(
      'app/lib/serie.dart',
      'void serie() {}\n',
      'feat(R-01..02, S-001/003): tela da série',
    );
    familyCommit = await commit(
      'app/lib/familia.dart',
      'void familia() {}\n',
      'fix(F-P0): ajuste da tela da família',
    );
    docsOnlyCommit = await commit(
      'docs/T13.md',
      '# T13\n',
      'docs(T13): registra a tarefa no backlog',
    );
    // Merge que só entra como referência: conta para a UI, nunca como rastro.
    await git(['checkout', '-q', '-b', 'pr']);
    await commit(
      'server/lib/pr.dart',
      'void pr() {}\n',
      'feat: servidor do PR',
    );
    await git(['checkout', '-q', 'master']);
    await git(['merge', '-q', '--no-ff', '-m', 'merge do PR', 'pr']);
    mergeCommit = await git(['rev-parse', 'HEAD']);
    // Merge que traz UI: só o `-m` mostra o que ele trouxe.
    await git(['checkout', '-q', '-b', 'pr-ui']);
    await commit('app/lib/pr_ui.dart', 'void prUi() {}\n', 'feat: tela do PR');
    await git(['checkout', '-q', 'master']);
    await git(['merge', '-q', '--no-ff', '-m', 'merge do PR de UI', 'pr-ui']);
    uiMergeCommit = await git(['rev-parse', 'HEAD']);
    multiFamilyCommit = await commit(
      'app/lib/familias.dart',
      'void familias() {}\n',
      'fix(G-P0, H-UX/K-P1): tela das três famílias',
    );
    // O assunto nomeia T25, V-01..02 e a família X-P0: rastro. O corpo só
    // cita T23 e Y-01..02, como o exemplo na mensagem de uma ferramenta.
    subjectServerCommit = await commit(
      'server/lib/ferramenta.dart',
      'void ferramenta() {}\n',
      'fix(T25, V-01..02, X-P0): ferramenta do servidor\n\n'
          'Exemplo no corpo: T23 e Y-01..02 saem sem rastro.',
    );
    // Só o corpo cita T24, mas o commit toca a UI: pede a prova de UI.
    bodyUiCommit = await commit(
      'app/lib/corpo_ui.dart',
      'void corpoUi() {}\n',
      'chore: ajuste da tela\n\nToca a tela da T24.',
    );
    // Arquivo movido para fora da UI: o caminho antigo está em app/lib.
    File(
      '${repo.path}/app/lib/movida.dart',
    ).renameSync('${repo.path}/server/lib/movida.dart');
    await git(['add', '-A']);
    await git([
      'commit',
      '-q',
      '-m',
      'refactor(T26): move a tela para o servidor',
    ]);
    renameCommit = await git(['rev-parse', 'HEAD']);
    write('docs/qa/execution/2026-10-03/T10.md', '# receipt T10\n');
    write(
      'docs/qa/execution/2026-10-04/T11.md',
      '# receipt T11\n\nFeito em `${uiCommit.substring(0, 12)}`.\n',
    );
    write(
      'docs/qa/execution/2026-10-05/T16.md',
      '# receipt T16\n\nFeito em `${outsideCommit.substring(0, 12)}`.\n',
    );

    final s = serverCommit.substring(0, 9);
    final u = uiCommit.substring(0, 10);
    final o = outsideCommit.substring(0, 9);
    write(
      'docs/generated/TASK_REGISTRY.json',
      jsonEncode({
        'schema_version': 2,
        'tasks': [
          task('T-PASS', 'PASS'),
          task('T-TODO', 'TODO'),
          task(
            'T1',
            pending,
            deps: ['T-PASS'],
            acceptance:
                'Feito no commit `$s`. Evidência: `server/lib/servico.dart` '
                'e receipt `docs/qa/execution/2026-10-01/T1.md`.',
          ),
          task(
            'T2',
            pending,
            deps: ['T1'],
            acceptance: 'Feito em $u; tela nova.',
          ),
          task('T3', pending, deps: ['T-TODO']),
          task('T4', pending, acceptance: 'Feito em `$o`.'),
          task(
            'T5',
            pending,
            acceptance: 'Receipt `docs/qa/execution/2026-10-02/T5.md`.',
          ),
          task('T6', pending, deps: ['T4']),
          task(
            'T7',
            pending,
            acceptance:
                'Feito. Segue aberto: aplicar a migration na produção, no '
                'lote de deploy.',
          ),
          task('T8', pending, acceptance: 'Tela em `app/lib/tela.dart:12`.'),
          task('T9', 'TODO', deps: ['T1']),
          task(
            'T10',
            pending,
            acceptance: 'Receipt `docs/qa/execution/2026-10-03/T10.md`.',
          ),
          task(
            'T11',
            pending,
            acceptance: 'Receipt `docs/qa/execution/2026-10-04/T11.md`.',
          ),
          task(
            'T12',
            pending,
            acceptance: 'Evidência: `server/lib/servico.dart:1`.',
          ),
          task('T13', pending, acceptance: 'Só o registro.'),
          task(
            'T14',
            pending,
            acceptance: 'Conferido no master `${mergeCommit.substring(0, 9)}`.',
          ),
          task('R-01', pending, acceptance: 'Feito em `$s`.'),
          task('R-02', pending, acceptance: 'Feito em `$s`.'),
          task('R-03', pending, acceptance: 'Feito em `$s`.'),
          task('S-001', pending, acceptance: 'Feito em `$s`.'),
          task('S-002', pending, acceptance: 'Feito em `$s`.'),
          task('S-003', pending, acceptance: 'Feito em `$s`.'),
          task('F-P0-01', pending, acceptance: 'Feito em `$s`.'),
          task(
            'T15',
            pending,
            acceptance:
                'Conferido no master `${uiMergeCommit.substring(0, 9)}`.',
          ),
          task(
            'T16',
            pending,
            acceptance: 'Receipt `docs/qa/execution/2026-10-05/T16.md`.',
          ),
          task('G-P0-01', pending, acceptance: 'Feito em `$s`.'),
          task('H-UX-01', pending, acceptance: 'Feito em `$s`.'),
          task('K-P1-01', pending, acceptance: 'Feito em `$s`.'),
          // T17 vem antes de T18 na ordem: só o ponto fixo pega a cadeia.
          task('T17', pending, deps: ['T18'], acceptance: 'Feito em `$s`.'),
          task('T18', pending, deps: ['T2'], acceptance: 'Feito em `$s`.'),
          task('T19', pending, deps: ['T1'], acceptance: 'Feito em `$s`.'),
          task('T20', pending, deps: ['T12'], acceptance: 'Feito em `$s`.'),
          task(
            'T21',
            pending,
            acceptance: 'Feito em `$s`. Falta: ligar o job na produção.',
          ),
          task('T22', pending, deps: ['T21'], acceptance: 'Feito em `$s`.'),
          for (final id in [
            'T23',
            'T24',
            'T25',
            'V-01',
            'V-02',
            'X-P0-01',
            'Y-01',
            'Y-02',
            'T26',
          ])
            task(id, pending, acceptance: 'Só o registro.'),
        ],
      }),
    );
    await git(['add', '-A']);
    await git(['commit', '-q', '-m', 'registry']);
    head = await git(['rev-parse', 'HEAD']);
  });

  tearDownAll(() async {
    await repo.delete(recursive: true);
  });

  Future<(int, String)> run(
    List<String> args, {
    Map<String, String> config = const {},
  }) async {
    final entries = config.entries.toList();
    final result = await Process.run(
      'python3',
      [script.path, '--repo', repo.path, ...args],
      environment: {
        'PYTHONDONTWRITEBYTECODE': '1',
        // A configuração do Git de quem roda, injetada como o Git a lê.
        if (entries.isNotEmpty) 'GIT_CONFIG_COUNT': '${entries.length}',
        for (var i = 0; i < entries.length; i++) ...{
          'GIT_CONFIG_KEY_$i': entries[i].key,
          'GIT_CONFIG_VALUE_$i': entries[i].value,
        },
      },
    );
    return (result.exitCode, '${result.stdout}${result.stderr}');
  }

  Future<Map<String, dynamic>> evaluate(
    List<String> args, {
    Map<String, String> config = const {},
  }) async {
    final (code, output) = await run([
      ...args,
      '--format',
      'json',
    ], config: config);
    expect(code, 0, reason: output);
    return jsonDecode(output) as Map<String, dynamic>;
  }

  Map<String, String> classes(Map<String, dynamic> result) => {
    for (final row in result['tasks'] as List<dynamic>)
      (row as Map<String, dynamic>)['id'] as String:
          row['classification'] as String,
  };

  test(
    'classifica cada pendente pelo SHA, dependências e prova de UI',
    () async {
      final result = await evaluate(['--sha', head]);

      expect(result['schema'], 'manaloom.full_gate_eligibility.v1');
      expect(result['sha'], head);
      expect(result['conditional'], isTrue);
      expect(
        (result['registry'] as Map<String, dynamic>)['source'],
        'git:$head:docs/generated/TASK_REGISTRY.json',
      );
      expect(classes(result), {
        'T1': 'elegivel',
        'T2': 'elegivel_com_prova_ui',
        'T3': 'bloqueada_por_dependencia',
        'T4': 'commit_citado_fora_do_sha',
        'T5': 'receipt_ausente_no_sha',
        'T6': 'bloqueada_por_dependencia',
        'T7': 'elegivel_sem_rastro_de_ui',
        'T8': 'elegivel_com_prova_ui',
        'T10': 'elegivel_com_prova_ui',
        'T11': 'elegivel_com_prova_ui',
        'T12': 'elegivel_sem_rastro_de_ui',
        'T13': 'elegivel_sem_rastro_de_ui',
        'T14': 'elegivel_sem_rastro_de_ui',
        'R-01': 'elegivel_com_prova_ui',
        'R-02': 'elegivel_com_prova_ui',
        'R-03': 'elegivel',
        'S-001': 'elegivel_com_prova_ui',
        'S-002': 'elegivel',
        'S-003': 'elegivel_com_prova_ui',
        'F-P0-01': 'elegivel_com_prova_ui',
        'T15': 'elegivel_com_prova_ui',
        'T16': 'elegivel_sem_rastro_de_ui',
        'G-P0-01': 'elegivel_com_prova_ui',
        'H-UX-01': 'elegivel_com_prova_ui',
        'K-P1-01': 'elegivel_com_prova_ui',
        'T17': 'elegivel_se_dependencia_subir',
        'T18': 'elegivel_se_dependencia_subir',
        'T19': 'elegivel',
        'T20': 'elegivel_se_dependencia_subir',
        'T21': 'elegivel',
        'T22': 'elegivel_se_dependencia_subir',
        'T23': 'elegivel_sem_rastro_de_ui',
        'T24': 'elegivel_com_prova_ui',
        'T25': 'elegivel',
        'V-01': 'elegivel',
        'V-02': 'elegivel',
        'X-P0-01': 'elegivel',
        'Y-01': 'elegivel_sem_rastro_de_ui',
        'Y-02': 'elegivel_sem_rastro_de_ui',
        'T26': 'elegivel_com_prova_ui',
      });
      final rows = {
        for (final row in result['tasks'] as List<dynamic>)
          (row as Map<String, dynamic>)['id']: row,
      };
      expect(rows['T1']!['cited_commits'], [serverCommit]);
      expect(rows['T1']!['implementation_commits'], [serverCommit]);
      expect(rows['T10']!['subject_commits'], [messageUiCommit]);
      expect(rows['T10']!['ui_commits'], [messageUiCommit]);
      expect(rows['T10']!['ui_paths_from_commits'], ['app/lib/tela10.dart']);
      expect(rows['T11']!['receipt_commits'], [uiCommit]);
      expect(rows['T11']!['ui_paths_from_commits'], ['app/lib/tela.dart']);
      expect(rows['T12']!['implementation_commits'], isEmpty);
      expect(rows['T13']!['subject_commits'], [docsOnlyCommit]);
      expect(rows['T13']!['implementation_commits'], isEmpty);
      expect(rows['T14']!['cited_commits'], [mergeCommit]);
      expect(rows['T14']!['implementation_commits'], isEmpty);
      for (final id in ['R-01', 'R-02', 'S-001', 'S-003']) {
        expect(rows[id]!['subject_commits'], [seriesCommit], reason: id);
      }
      for (final id in ['R-03', 'S-002']) {
        expect(rows[id]!['subject_commits'], isEmpty, reason: id);
      }
      expect(rows['F-P0-01']!['subject_commits'], [familyCommit]);
      // Um merge citado que traz app/lib pede a prova de UI, sem rastro.
      expect(rows['T15']!['cited_commits'], [uiMergeCommit]);
      expect(rows['T15']!['ui_commits'], [uiMergeCommit]);
      expect(rows['T15']!['ui_paths_from_commits'], ['app/lib/pr_ui.dart']);
      expect(rows['T15']!['implementation_commits'], isEmpty);
      // Commit fora do SHA citado num receipt: não bloqueia, mas não é rastro.
      expect(rows['T16']!['commits_outside_sha'], isEmpty);
      expect(rows['T16']!['receipt_commits'], [outsideCommit]);
      expect(rows['T16']!['receipt_commits_outside_sha'], [outsideCommit]);
      expect(rows['T16']!['implementation_commits'], isEmpty);
      for (final id in ['G-P0-01', 'H-UX-01', 'K-P1-01']) {
        expect(rows[id]!['subject_commits'], [multiFamilyCommit], reason: id);
      }
      // Só o assunto dá rastro (direto, em faixa e pela família no escopo).
      for (final id in ['T25', 'V-01', 'V-02', 'X-P0-01']) {
        expect(rows[id]!['subject_commits'], [subjectServerCommit], reason: id);
        expect(rows[id]!['body_only_commits'], isEmpty, reason: id);
        expect(rows[id]!['implementation_commits'], [
          subjectServerCommit,
        ], reason: id);
      }
      // Um commit só de servidor que cita o ID só no corpo não é rastro.
      for (final id in ['T23', 'Y-01', 'Y-02']) {
        expect(rows[id]!['subject_commits'], isEmpty, reason: id);
        expect(rows[id]!['body_only_commits'], [
          subjectServerCommit,
        ], reason: id);
        expect(rows[id]!['implementation_commits'], isEmpty, reason: id);
        expect(rows[id]!['ui_commits'], isEmpty, reason: id);
      }
      // Mas a menção só no corpo conta para a UI: falha fechada.
      expect(rows['T24']!['body_only_commits'], [bodyUiCommit]);
      expect(rows['T24']!['implementation_commits'], isEmpty);
      expect(rows['T24']!['ui_commits'], [bodyUiCommit]);
      expect(rows['T24']!['ui_paths_from_commits'], ['app/lib/corpo_ui.dart']);
      // O arquivo movido para fora de app/lib pede a prova de UI.
      expect(rows['T26']!['implementation_commits'], [renameCommit]);
      expect(rows['T26']!['ui_paths_from_commits'], ['app/lib/movida.dart']);
      Map<String, Object> dep(String id, String classification, bool open) => {
        'id': id,
        'classification': classification,
        'declares_open_items': open,
      };
      expect(rows['T1']!['round_dependencies'], isEmpty);
      expect(rows['T2']!['round_dependencies'], [dep('T1', 'elegivel', false)]);
      expect(rows['T17']!['round_dependencies'], [
        dep('T18', 'elegivel_se_dependencia_subir', false),
      ]);
      expect(rows['T18']!['round_dependencies'], [
        dep('T2', 'elegivel_com_prova_ui', false),
      ]);
      expect(rows['T19']!['round_dependencies'], [
        dep('T1', 'elegivel', false),
      ]);
      expect(rows['T20']!['round_dependencies'], [
        dep('T12', 'elegivel_sem_rastro_de_ui', false),
      ]);
      expect(rows['T22']!['round_dependencies'], [
        dep('T21', 'elegivel', true),
      ]);
      expect(rows['T1']!['receipts'], ['docs/qa/execution/2026-10-01/T1.md']);
      expect(rows['T2']!['ui_paths_from_commits'], ['app/lib/tela.dart']);
      expect(rows['T8']!['ui_paths'], ['app/lib/tela.dart']);
      expect(rows['T3']!['open_dependencies'], [
        {'id': 'T-TODO', 'status': 'TODO'},
      ]);
      expect(rows['T6']!['open_dependencies'], [
        {'id': 'T4', 'status': pending},
      ]);
      expect(rows['T4']!['commits_outside_sha'], [outsideCommit]);
      expect(rows['T7']!['declares_open_items'], isTrue);
      expect(rows['T1']!['declares_open_items'], isFalse);
      expect(result['summary'], {
        'pending': 40,
        'bloqueada_por_dependencia': 2,
        'commit_citado_fora_do_sha': 1,
        'elegivel': 9,
        'elegivel_com_prova_ui': 15,
        'elegivel_se_dependencia_subir': 4,
        'elegivel_sem_rastro_de_ui': 8,
        'receipt_ausente_no_sha': 1,
      });
    },
  );

  test(
    'a lista não depende do log.diffMerges nem do diff.renames de quem roda',
    () async {
      final baseline = await evaluate(['--sha', head]);
      for (final config in [
        hostileConfig,
        {'log.diffMerges': 'dense-combined'},
        {'log.diffMerges': 'remerge'},
        {'log.diffMerges': 'off'},
        {'diff.renames': 'copies'},
      ]) {
        final result = await evaluate(['--sha', head], config: config);
        final rows = {
          for (final row in result['tasks'] as List<dynamic>)
            (row as Map<String, dynamic>)['id']: row,
        };
        // O merge de UI citado continua mostrando o que trouxe.
        expect(
          rows['T15']!['classification'],
          'elegivel_com_prova_ui',
          reason: '$config',
        );
        expect(rows['T15']!['ui_paths_from_commits'], [
          'app/lib/pr_ui.dart',
        ], reason: '$config');
        // O arquivo movido para fora de app/lib continua pedindo a prova.
        expect(
          rows['T26']!['classification'],
          'elegivel_com_prova_ui',
          reason: '$config',
        );
        expect(result['tasks'], baseline['tasks'], reason: '$config');
        expect(result['summary'], baseline['summary'], reason: '$config');
      }
    },
  );

  test('lê o registry do SHA pedido, não o do worktree', () async {
    final registry = File('${repo.path}/docs/generated/TASK_REGISTRY.json');
    final committed = registry.readAsStringSync();
    addTearDown(() => registry.writeAsStringSync(committed));
    registry.writeAsStringSync(
      committed.replaceAll('"status":"TODO"', '"status":"PASS"'),
    );

    final result = await evaluate(['--sha', head]);

    expect(classes(result)['T3'], 'bloqueada_por_dependencia');
    final overridden = await evaluate([
      '--sha',
      head,
      '--registry-file',
      registry.path,
    ]);
    expect(classes(overridden)['T3'], 'elegivel_sem_rastro_de_ui');
    expect(
      (overridden['registry'] as Map<String, dynamic>)['source'],
      registry.path,
    );
  });

  test('SHA sem registry e SHA desconhecido: entrada inválida (2)', () async {
    final (noRegistry, output) = await run(['--sha', serverCommit]);
    expect(noRegistry, 2, reason: output);
    expect(output, contains('não existe no SHA'));

    final (unknown, unknownOutput) = await run(['--sha', 'f' * 40]);
    expect(unknown, 2, reason: unknownOutput);
    expect(unknownOutput, contains('SHA desconhecido'));
  });

  test(
    'receipt do full: válido no mesmo SHA; inválido segura a lista (3)',
    () async {
      final dir = await Directory.systemTemp.createTemp('manaloom_g10_rcpt_');
      addTearDown(() => dir.delete(recursive: true));
      Map<String, Object?> receipt({
        String? sha,
        String mode = 'full',
        String status = 'PASS',
        bool dirty = false,
      }) => {
        'schema': 'manaloom.gate_run_receipt.v1',
        'gate': {'id': 'local_ci', 'mode': mode},
        'status': status,
        'gate_eligible': status == 'PASS',
        'git_sha': sha ?? head,
        'completed_at': '2026-10-10T12:00:00Z',
        'source': {
          'stable': true,
          'start': {'git_sha': sha ?? head, 'git_dirty': dirty},
          'end': {'git_sha': sha ?? head, 'git_dirty': dirty},
        },
      };
      File writeReceipt(String name, Map<String, Object?> body) =>
          File('${dir.path}/$name.json')..writeAsStringSync(jsonEncode(body));

      final good = await evaluate([
        '--sha',
        head,
        '--receipt',
        writeReceipt('bom', receipt()).path,
      ]);
      expect(good['conditional'], isFalse);
      expect(
        (good['full_receipt'] as Map<String, dynamic>)['status'],
        'valido',
      );
      expect(classes(good)['T1'], 'elegivel');

      final release = await evaluate([
        '--sha',
        head,
        '--receipt',
        writeReceipt('release', receipt(mode: 'release')).path,
      ]);
      expect(
        (release['full_receipt'] as Map<String, dynamic>)['status'],
        'valido',
      );

      for (final (name, body, problem) in [
        ('outro_sha', receipt(sha: serverCommit), 'não é o SHA pedido'),
        ('quick', receipt(mode: 'quick'), 'full, e2e ou release'),
        ('falhou', receipt(status: 'FAIL'), 'não PASS'),
        ('sujo', receipt(dirty: true), 'worktree sujo'),
      ]) {
        final (code, output) = await run([
          '--sha',
          head,
          '--receipt',
          writeReceipt(name, body).path,
          '--format',
          'json',
        ]);
        expect(code, 3, reason: '$name: $output');
        final result = jsonDecode(output) as Map<String, dynamic>;
        final full = result['full_receipt'] as Map<String, dynamic>;
        expect(full['status'], 'invalido', reason: name);
        expect(
          (full['problems'] as List<dynamic>).join(' '),
          contains(problem),
        );
        expect(
          classes(result).values.where((value) => value.startsWith('elegivel')),
          isEmpty,
          reason: '$name: nenhuma tarefa sobe com receipt inválido',
        );
        expect(classes(result)['T1'], 'bloqueada_pelo_receipt');
      }
    },
  );

  test('markdown para o receipt e nada muda no repositório', () async {
    final status = await git([
      'status',
      '--porcelain',
      '--untracked-files=all',
    ]);
    final staged = await git(['diff', '--cached', '--name-only']);
    final refs = await git(['for-each-ref']);

    final (code, output) = await run(['--sha', head]);

    expect(code, 0, reason: output);
    expect(output, contains('# Elegibilidade a PASS no SHA `$head`'));
    expect(output, contains('lista condicional'));
    expect(output, contains('| `T2` | P0 CORE | `elegivel_com_prova_ui` |'));
    expect(output, contains('aceite declara pendência'));
    expect(
      output,
      contains('| `T12` | P0 CORE | `elegivel_sem_rastro_de_ui` |'),
    );
    expect(output, contains('sem commit da tarefa no SHA'));
    expect(
      output,
      contains(
        '| `T18` | P0 CORE | `elegivel_se_dependencia_subir` | '
        '`T2` (`elegivel_com_prova_ui` nesta rodada) |',
      ),
    );
    expect(
      output,
      contains('`T21` (`elegivel` nesta rodada, com pendência declarada)'),
    );
    expect(output, contains('sobe só se subir no mesmo receipt: T2'));
    // O commit que só cita T23 no corpo não entra em "Commits da tarefa".
    expect(
      output,
      contains(
        '| `T23` | P0 CORE | `elegivel_sem_rastro_de_ui` | — | nenhum citado '
        '| nenhum | sem commit da tarefa no SHA: a prova de UI não pode ser '
        'dispensada sem citar os commits; citada só no corpo de '
        '${subjectServerCommit.substring(0, 9)} (conta para a UI, não é '
        'rastro) |',
      ),
    );
    expect(output, contains('`${serverCommit.substring(0, 9)}`'));
    expect(
      await git(['status', '--porcelain', '--untracked-files=all']),
      status,
    );
    expect(await git(['diff', '--cached', '--name-only']), staged);
    expect(await git(['for-each-ref']), refs);
    expect(await git(['rev-parse', 'HEAD']), head);
  });

  test(
    'a confirmação do modelo de receipt lista o que um merge trouxe e o '
    'caminho antigo de um arquivo movido, com qualquer configuração',
    () async {
      final template =
          File(
            '${Directory.current.parent.path}/docs/qa/'
            'MANALOOM_FULL_GATE_PASS_RECEIPT_TEMPLATE_2026-10-10.md',
          ).readAsStringSync();
      final commands = [
        for (final match in RegExp(
          r'`git (show [^`]*<commit>)`',
        ).allMatches(template))
          match.group(1)!,
      ];
      expect(commands, hasLength(greaterThanOrEqualTo(2)));
      for (final command in commands) {
        for (final config in [const <String, String>{}, hostileConfig]) {
          for (final (commit, uiPath) in [
            (uiMergeCommit, 'app/lib/pr_ui.dart'),
            (renameCommit, 'app/lib/movida.dart'),
          ]) {
            final listed = await git([
              for (final arg in command.split(' '))
                arg == '<commit>' ? commit : arg,
            ], config: config);
            expect(
              listed.split('\n'),
              contains(uiPath),
              reason: 'git $command em $commit com $config',
            );
          }
        }
      }
    },
  );
}
