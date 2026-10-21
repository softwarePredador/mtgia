import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Dá ao `flutter-tester` o que o aparelho real já tem.
///
/// O gate de evidência roda cada `integration_test` duas vezes: um pré-voo em
/// `flutter-tester` (VM do host) e depois a captura no aparelho. No host não há
/// plugin nativo, e `flutter_cache_manager` — que o `CachedNetworkImage` das
/// cartas usa — abre um banco sqflite no primeiro `CacheObjectProvider.open`.
/// Medido em 2026-09-23: `MissingPluginException(getDatabasesPath)` seguido de
/// `'_pendingFrame == null': is not true`, e os quatro testes do pré-voo caíam
/// antes de exercitar qualquer tela, bloqueando `core-product-android`.
///
/// O discriminador é `FLUTTER_TEST`, que o `flutter test` põe no ambiente do
/// processo do host. Num aparelho o código roda dentro do app, onde essa
/// variável não existe, então o plugin nativo continua valendo — o que importa,
/// porque trocar o banco no dispositivo falsificaria a própria prova.
///
/// Medi a alternativa antes de escolher esta: sondar o plugin
/// (`databaseFactory.getDatabasesPath()`) e reagir a `MissingPluginException`
/// não funciona aqui, porque nesse ponto do ciclo de vida o binding ainda não
/// existe e a chamada estoura `FlutterError` antes de chegar ao canal.
bool get _rodandoNoHost => Platform.environment.containsKey('FLUTTER_TEST');

var _bancoDeHostInstalado = false;

void _instalarBancoDeHost() {
  if (_bancoDeHostInstalado || !_rodandoNoHost) return;
  _bancoDeHostInstalado = true;

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Instala o mock de path_provider assim que houver binding.
///
/// Não dá para fazer isso junto com o factory do sqflite: `testExecutable` roda
/// ANTES de o teste chamar `ensureInitialized()`, e tocar
/// `TestDefaultBinaryMessengerBinding.instance` ali estoura
/// "Binding has not yet been initialized" — medido, não suposto.
void instalarPathProviderDeHostSeNecessario() {
  if (_pathProviderInstalado || !_rodandoNoHost) return;
  _pathProviderInstalado = true;
  final temp = Directory.systemTemp.createTempSync(
    'manaloom_integration_path_provider_',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => temp.path,
      );
}

var _pathProviderInstalado = false;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final previous = WidgetController.hitTestWarningShouldBeFatal;
  WidgetController.hitTestWarningShouldBeFatal = true;
  _instalarBancoDeHost();
  try {
    await testMain();
  } finally {
    WidgetController.hitTestWarningShouldBeFatal = previous;
  }
}
