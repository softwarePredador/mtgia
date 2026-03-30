import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LotusPresentationMode {
  LotusPresentationMode._();

  static const SystemUiOverlayStyle _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static Future<void> enter() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [],
    );
    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
  }

  static Future<void> exit() async {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
  }
}
