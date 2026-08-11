import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/shell_app_bar_actions.dart';
import 'package:manaloom/features/auth/providers/auth_provider.dart';
import 'package:manaloom/features/auth/screens/login_screen.dart';
import 'package:manaloom/features/decks/widgets/deck_details_dialogs.dart';
import 'package:manaloom/features/messages/providers/message_provider.dart';
import 'package:manaloom/features/notifications/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class _NoopApiClient extends ApiClient {}

class _RejectingAuthProvider extends AuthProvider {
  _RejectingAuthProvider() : super(apiClient: _NoopApiClient());

  int loginCalls = 0;

  @override
  String? get errorMessage => 'Confira os dados e tente novamente.';

  @override
  Future<bool> login(String email, String password) async {
    loginCalls++;
    return false;
  }
}

void main() {
  final matrix = _loadJson('test/ui/fixtures/ui_keyboard_focus_matrix.json');

  test('declares executable evidence for every required Web interaction', () {
    final interactions = matrix['interactions'] as Map<String, dynamic>;
    expect(interactions.keys.toSet(), {
      'tab_forward',
      'shift_tab',
      'enter',
      'space',
      'escape',
      'modal_trap',
      'focus_restoration',
      'browser_back',
      'visible_focus',
      'reduced_motion',
    });
    for (final contract in interactions.values.cast<Map<String, dynamic>>()) {
      final path = contract['test'] as String;
      final anchor = contract['anchor'] as String;
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'missing $path');
      expect(
        file.readAsStringSync(),
        contains(anchor),
        reason: '$path lost $anchor',
      );
    }

    for (final path
        in (matrix['modal_sources'] as List<dynamic>).cast<String>()) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('TraversalEdgeBehavior.leaveFlutterView')));
      expect(source, isNot(contains('requestFocus: false')));
    }

    final manualWeb = matrix['manual_web'] as Map<String, dynamic>;
    final requiredRoutes = _stringSet(manualWeb['required_routes']);
    final observedRoutes = _stringSet(manualWeb['observed_routes']);
    final missingRoutes = requiredRoutes.difference(observedRoutes);
    final remainingRoutes = _stringSet(manualWeb['remaining_routes']);

    expect(requiredRoutes, contains('/decks/:id/battle-replays'));
    expect(requiredRoutes, contains('/decks/:id/battle-coach'));
    expect(requiredRoutes, isNot(contains('/battle/replays')));
    expect(remainingRoutes, missingRoutes);

    final manualStatus = manualWeb['status'];
    expect(manualStatus, anyOf('pending', 'pass'));
    if (manualStatus == 'pass') {
      expect(missingRoutes, isEmpty);
      expect(manualWeb['remaining'], isEmpty);
      expect(remainingRoutes, isEmpty);
    } else {
      expect(manualStatus, 'pending');
      expect(missingRoutes, isNotEmpty);
      expect(manualWeb['remaining'], isNotEmpty);
      expect(
        _stringSet(manualWeb['passed']),
        isNot(contains('authenticated_routes')),
        reason: 'Incomplete route coverage cannot claim authenticated routes.',
      );
    }

    final battleCoach =
        (matrix['surface_followups'] as Map<String, dynamic>)['battle_coach']
            as Map<String, dynamic>;
    final runtimeManifest = File(battleCoach['web_runtime_evidence'] as String);
    final aggregateReview = File(battleCoach['aggregate_review'] as String);
    expect(runtimeManifest.existsSync(), isTrue);
    expect(aggregateReview.existsSync(), isTrue);
    expect(
      (battleCoach['required_interactions'] as List).cast<String>(),
      containsAll(<String>[
        'tab_forward',
        'shift_tab',
        'enter',
        'space',
        'escape_modal',
        'modal_trap',
        'focus_restoration',
        'visible_focus',
        'reduced_motion',
      ]),
    );

    final qualificationIssues = _keyboardRuntimeQualificationIssues(
      manifest: _loadJson(runtimeManifest.path),
      manifestHash: sha256
          .convert(runtimeManifest.readAsBytesSync())
          .toString(),
      aggregate: _loadJson(aggregateReview.path),
      currentSourceDigest: _currentUiSourceDigest(),
      aggregateManifestPath: battleCoach['aggregate_manifest_path'] as String,
      aggregateReleaseCheck: battleCoach['aggregate_release_check'] as String,
    );

    if (manualStatus == 'pass') {
      expect(battleCoach['web_keyboard_status'], 'pass_current_digest');
      expect(
        qualificationIssues,
        isEmpty,
        reason: qualificationIssues.join('\n'),
      );
    } else {
      expect(battleCoach['web_keyboard_status'], 'pending_current_digest');
      expect(
        qualificationIssues,
        isNotEmpty,
        reason: 'Pending evidence must not accidentally qualify as current.',
      );
    }
  });

  test('keyboard runtime qualification rejects stale digest and hash', () {
    const currentDigest =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const staleDigest =
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
    const observedHash =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    const wrongHash =
        'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
    const manifestPath =
        'docs/qa/ui-live/current/battle-coach-web-keyboard/'
        'capture-manifest.json';

    final issues = _keyboardRuntimeQualificationIssues(
      manifest: {
        'status': 'PASS_RUNTIME',
        'source_digest': staleDigest,
        'target': 'web_real_build',
        'runtime_console': {'status': 'pass', 'forbidden_entries': 0},
        'checkpoint_count': 19,
      },
      manifestHash: observedHash,
      aggregate: {
        'status': 'PASS',
        'source_digest': staleDigest,
        'runtime': {
          'capture_manifests': [
            {'path': manifestPath, 'sha256': wrongHash},
          ],
        },
        'release_checks': {'web_hardware_keyboard': 'pending'},
      },
      currentSourceDigest: currentDigest,
      aggregateManifestPath: manifestPath,
      aggregateReleaseCheck: 'web_hardware_keyboard',
    );

    expect(
      issues,
      containsAll(<String>[
        'runtime manifest source digest is stale',
        'aggregate review source digest is stale',
        'runtime manifest hash does not match aggregate binding',
        'aggregate release check is not pass_current_digest',
      ]),
    );
  });

  test('keyboard runtime qualification accepts an exact current binding', () {
    const currentDigest =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const manifestHash =
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    const manifestPath =
        'docs/qa/ui-live/current/battle-coach-web-keyboard/'
        'capture-manifest.json';

    final issues = _keyboardRuntimeQualificationIssues(
      manifest: {
        'status': 'PASS_RUNTIME',
        'source_digest': currentDigest,
        'target': 'web_real_build',
        'runtime_console': {'status': 'pass', 'forbidden_entries': 0},
        'checkpoint_count': 19,
      },
      manifestHash: manifestHash,
      aggregate: {
        'status': 'PASS',
        'source_digest': currentDigest,
        'runtime': {
          'capture_manifests': [
            {'path': manifestPath, 'sha256': manifestHash},
          ],
        },
        'release_checks': {'web_hardware_keyboard': 'pass_current_digest'},
      },
      currentSourceDigest: currentDigest,
      aggregateManifestPath: manifestPath,
      aggregateReleaseCheck: 'web_hardware_keyboard',
    );

    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  testWidgets('login follows forward and reverse form focus order', (
    tester,
  ) async {
    final provider = _RejectingAuthProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, const Key('login-email-field')), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, const Key('login-password-field')), isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(_hasFocus(tester, const Key('login-email-field')), isTrue);
  });

  testWidgets('Enter and Space activate shell actions', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const _ShellActionsSubject(),
        ),
        GoRoute(path: '/messages', builder: (_, __) => const Text('messages')),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const Text('notifications'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MessageProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedTooltip(tester), 'Mensagens');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('messages'), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedTooltip(tester), 'Notificações');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('notifications'), findsOneWidget);
  });

  testWidgets('deck dialog traps focus and restores it after Escape', (
    tester,
  ) async {
    await tester.pumpWidget(_dialogSubject());
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, const Key('focus-dialog-launcher')), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(
      _hasFocus(tester, const Key('deck-description-editor-field')),
      isTrue,
    );

    for (var step = 0; step < 6; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        _primaryFocusIsInside(tester, dialog),
        isTrue,
        reason: 'step $step',
      );
    }

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(_hasFocus(tester, const Key('focus-dialog-launcher')), isTrue);
  });

  testWidgets('browser back closes the modal and restores launcher focus', (
    tester,
  ) async {
    await tester.pumpWidget(_dialogSubject());
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, const Key('focus-dialog-launcher')), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(_hasFocus(tester, const Key('focus-dialog-launcher')), isTrue);
  });

  test('theme exposes non-transparent focus feedback', () {
    expect(AppTheme.darkTheme.focusColor.a, greaterThan(0));
    final focusedBorder = AppTheme.darkTheme.inputDecorationTheme.focusedBorder;
    expect(focusedBorder, isA<OutlineInputBorder>());
    expect(
      (focusedBorder! as OutlineInputBorder).borderSide.color,
      AppTheme.brass400,
    );
  });
}

Widget _dialogSubject() {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const Key('focus-dialog-launcher'),
            onPressed: () => showDeckDescriptionEditorDialog(
              context: context,
              currentDescription: 'Plano inicial',
            ),
            child: const Text('Editar descrição'),
          ),
        ),
      ),
    ),
  );
}

class _ShellActionsSubject extends StatelessWidget {
  const _ShellActionsSubject();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(actions: const [ShellAppBarActions()]));
  }
}

bool _hasFocus(WidgetTester tester, Key key) {
  return _primaryFocusIsInside(tester, find.byKey(key));
}

String? _focusedTooltip(WidgetTester tester) {
  final primaryContext = FocusManager.instance.primaryFocus?.context;
  if (primaryContext == null) return null;
  final focusElement = primaryContext as Element;
  String? tooltip;
  focusElement.visitAncestorElements((ancestor) {
    if (ancestor.widget is Tooltip) {
      tooltip = (ancestor.widget as Tooltip).message;
      return false;
    }
    return true;
  });
  return tooltip;
}

bool _primaryFocusIsInside(WidgetTester tester, Finder ancestorFinder) {
  final primaryContext = FocusManager.instance.primaryFocus?.context;
  if (primaryContext is! Element) return false;
  final ancestor = ancestorFinder.evaluate().single;
  if (primaryContext == ancestor) return true;
  var found = false;
  primaryContext.visitAncestorElements((element) {
    if (element == ancestor) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

Map<String, dynamic> _loadJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _stringSet(dynamic value) {
  if (value is! List) return const <String>{};
  return value.map((item) => item.toString()).toSet();
}

String _currentUiSourceDigest() {
  final result = Process.runSync(
    '../scripts/manaloom_ui_source_digest.sh',
    const <String>[],
  );
  if (result.exitCode != 0) {
    throw TestFailure(
      'UI source digest failed (${result.exitCode}): ${result.stderr}',
    );
  }
  final digest = result.stdout.toString().trim();
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(digest)) {
    throw TestFailure('UI source digest is invalid: $digest');
  }
  return digest;
}

List<String> _keyboardRuntimeQualificationIssues({
  required Map<String, dynamic> manifest,
  required String manifestHash,
  required Map<String, dynamic> aggregate,
  required String currentSourceDigest,
  required String aggregateManifestPath,
  required String aggregateReleaseCheck,
}) {
  final issues = <String>[];
  if (manifest['status'] != 'PASS_RUNTIME') {
    issues.add('runtime manifest status is not PASS_RUNTIME');
  }
  if (manifest['source_digest'] != currentSourceDigest) {
    issues.add('runtime manifest source digest is stale');
  }
  if (manifest['target'] != 'web_real_build') {
    issues.add('runtime manifest target is not a real Web build');
  }
  final runtimeConsole = _object(manifest['runtime_console']);
  if (runtimeConsole['status'] != 'pass' ||
      runtimeConsole['forbidden_entries'] != 0) {
    issues.add('runtime manifest console is not clean');
  }
  final checkpointCount = manifest['checkpoint_count'];
  if (checkpointCount is! int || checkpointCount <= 0) {
    issues.add('runtime manifest has no keyboard checkpoints');
  }

  if (aggregate['status'] != 'PASS') {
    issues.add('aggregate review status is not PASS');
  }
  if (aggregate['source_digest'] != currentSourceDigest) {
    issues.add('aggregate review source digest is stale');
  }
  final references = _objectList(
    _object(aggregate['runtime'])['capture_manifests'],
  );
  Map<String, dynamic>? binding;
  for (final reference in references) {
    if (reference['path'] == aggregateManifestPath) {
      binding = reference;
      break;
    }
  }
  if (binding == null) {
    issues.add('runtime manifest is not bound by the aggregate review');
  } else if (binding['sha256'] != manifestHash) {
    issues.add('runtime manifest hash does not match aggregate binding');
  }
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(manifestHash)) {
    issues.add('runtime manifest hash is invalid');
  }

  final releaseChecks = _object(aggregate['release_checks']);
  if (releaseChecks[aggregateReleaseCheck] != 'pass_current_digest') {
    issues.add('aggregate release check is not pass_current_digest');
  }
  return issues;
}

Map<String, dynamic> _object(dynamic value) {
  if (value is! Map) return <String, dynamic>{};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Map<String, dynamic>> _objectList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.whereType<Map>().map(_object).toList(growable: false);
}
