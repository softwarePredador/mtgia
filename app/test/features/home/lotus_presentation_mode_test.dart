import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/home/lotus/lotus_presentation_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = <MethodCall>[];
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
    await LotusPresentationMode.enter();

    final orientationCall = platformCalls.firstWhere(
      (call) => call.method == 'SystemChrome.setPreferredOrientations',
    );
    expect(orientationCall.arguments, <String>[
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);

    await LotusPresentationMode.exit();
  });

  test('restores every orientation when leaving the life counter', () async {
    await LotusPresentationMode.enter();
    platformCalls.clear();
    await LotusPresentationMode.exit();

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
    final firstEnter = LotusPresentationMode.enter();
    final firstExit = LotusPresentationMode.exit();
    final secondEnter = LotusPresentationMode.enter();

    await Future.wait([firstEnter, firstExit, secondEnter]);

    final orientationCalls = platformCalls
        .where((call) => call.method == 'SystemChrome.setPreferredOrientations')
        .toList(growable: false);
    expect(orientationCalls, isNotEmpty);
    expect(orientationCalls.last.arguments, <String>[
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);

    await LotusPresentationMode.exit();
  });
}
