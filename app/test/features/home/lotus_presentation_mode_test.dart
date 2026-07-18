import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_presentation_mode.dart';

final class _FakeWakeLockController implements LotusWakeLockController {
  final List<bool> states = <bool>[];

  @override
  Future<void> setEnabled(bool enabled) async {
    states.add(enabled);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;
  late _FakeWakeLockController wakeLockController;
  late LotusPresentationMode presentationMode;

  setUp(() {
    platformCalls = <MethodCall>[];
    wakeLockController = _FakeWakeLockController();
    presentationMode = LotusPresentationMode.forTesting(
      wakeLockController: wakeLockController,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('locks the life counter to both landscape orientations', () async {
    await presentationMode.enter();

    final orientationCall = platformCalls.firstWhere(
      (call) => call.method == 'SystemChrome.setPreferredOrientations',
    );
    expect(orientationCall.arguments, <String>[
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);

    expect(wakeLockController.states, <bool>[true]);

    await presentationMode.exit();
    expect(wakeLockController.states, <bool>[true, false]);
  });

  test('restores every orientation when leaving the life counter', () async {
    await presentationMode.enter();
    platformCalls.clear();
    await presentationMode.exit();

    final orientationCall = platformCalls.firstWhere(
      (call) => call.method == 'SystemChrome.setPreferredOrientations',
    );
    expect(orientationCall.arguments, <String>[
      'DeviceOrientation.portraitUp',
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.portraitDown',
      'DeviceOrientation.landscapeRight',
    ]);
  });

  test('keeps landscape when one counter exits while another enters', () async {
    final firstEnter = presentationMode.enter();
    final firstExit = presentationMode.exit();
    final secondEnter = presentationMode.enter();

    await Future.wait([firstEnter, firstExit, secondEnter]);

    final orientationCalls = platformCalls
        .where((call) => call.method == 'SystemChrome.setPreferredOrientations')
        .toList(growable: false);
    expect(orientationCalls, isNotEmpty);
    expect(orientationCalls.last.arguments, <String>[
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);
    expect(wakeLockController.states.last, isTrue);

    await presentationMode.exit();
    expect(wakeLockController.states.last, isFalse);
  });

  test('reapplies the wake lock after the app resumes', () async {
    await presentationMode.enter();
    wakeLockController.states.clear();

    await presentationMode.refresh();

    expect(wakeLockController.states, <bool>[true]);
    await presentationMode.exit();
  });
}
