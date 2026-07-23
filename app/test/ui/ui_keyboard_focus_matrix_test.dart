import 'dart:convert';
import 'dart:io';

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
    expect(manualWeb['status'], anyOf('partial', 'pass'));
    if (manualWeb['status'] != 'pass') {
      expect(manualWeb['remaining'], isNotEmpty);
    }
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
