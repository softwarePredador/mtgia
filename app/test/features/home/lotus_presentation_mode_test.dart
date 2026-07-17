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
  });

  test('restores every orientation when leaving the life counter', () async {
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
}
