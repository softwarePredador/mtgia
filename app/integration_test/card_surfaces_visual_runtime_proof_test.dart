// Prova visual do fallback de carta sem arte.
//
// `card-back-fallback-web` não tinha roteiro: o manifesto registra
// `runtime: in_app_browser` e `generated_at` em julho, ou seja, alguém dirigiu
// um navegador e recortou a captura.
//
// Aqui ele é exercitado por `flutter drive`, e isso é legítimo porque o
// contrato dele não pede gesto nenhum: "1280x720; disposable card image URL
// absent and restored after capture". O requisito é o fallback aparecer.
//
// Os outros dois pacotes de carta NÃO estão aqui, de propósito.
// `card-details-navigation-web` exige "browser history navigation" e
// `optimization-card-reader-web` exige "real mouse hover, click and physical
// Escape". Evento sintético do Flutter pula o caminho de ponteiro e teclado
// sobre platform view -- e a arte na web é um `<img>` de plataforma
// (`cached_card_image.dart:285-288`), justamente onde esse caminho costuma
// falhar. Capturá-los por aqui provaria menos do que o contrato promete.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/cached_card_image.dart';

import 'runtime_test_helpers.dart';

const _captureRuntimeProof = bool.fromEnvironment(
  'MANALOOM_CAPTURE_RUNTIME_PROOF',
);
const _uiSourceDigest = String.fromEnvironment('MANALOOM_UI_SOURCE_DIGEST');
const _uiProofProfile = String.fromEnvironment('MANALOOM_UI_PROOF_PROFILE');
const _uiProofTarget = String.fromEnvironment('MANALOOM_UI_PROOF_TARGET');
const _uiProofDeviceContract = String.fromEnvironment(
  'MANALOOM_UI_PROOF_DEVICE_CONTRACT',
);
const _artImageUrlRaw = String.fromEnvironment(
  'MANALOOM_VISUAL_RING_IMAGE_URL',
);

/// Vazio vira `null` para o widget cair no verso do ManaLoom.
final String? _artImageUrl = _artImageUrlRaw.isEmpty ? null : _artImageUrlRaw;

const _visualWidth = int.fromEnvironment(
  'MANALOOM_VISUAL_WIDTH',
  defaultValue: 1280,
);
const _visualHeight = int.fromEnvironment(
  'MANALOOM_VISUAL_HEIGHT',
  defaultValue: 720,
);

/// Uma superfície por pacote, com os nomes que os manifestos já exigem.
const _cardBackCheckpoints = <String>['01_missing_art_uses_manaloom_card_back'];
const _navigationCheckpoints = <String>[
  '01_deck_card_preview_modal',
  '02_full_details_without_modal',
  '03_back_to_deck_without_modal',
];
const _readerCheckpoints = <String>['01_hover_card', '02_full_reader'];

void _emitContext(String surface, List<String> checkpoints) {
  if (!_captureRuntimeProof) return;
  // ignore: avoid_print
  print(
    'VISUAL_PROOF_CONTEXT ${jsonEncode(<String, Object>{'schema_version': 'manaloom_ui_runtime_context_v1', 'surface': surface, 'source_digest': _uiSourceDigest, 'profile': _uiProofProfile, 'runtime': 'flutter_drive', 'target': _uiProofTarget, 'device_contract': _uiProofDeviceContract, 'required_checkpoints': checkpoints})}',
  );
}

void _assertProofEnvironment() {
  if (!_captureRuntimeProof) return;
  expect(_uiSourceDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
  expect(_uiProofProfile, isNotEmpty);
  expect(_uiProofTarget, 'web_real_build');
  expect(_uiProofDeviceContract.toLowerCase(), contains('chrome'));
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  expect(tester.takeException(), isNull, reason: 'antes do checkpoint $name');
  // No pre-voo em `flutter-tester` nao ha superficie para converter em imagem:
  // o teste continua exercitando a tela e as assercoes, sem gravar PNG.
  if (!_captureRuntimeProof) return;
  await captureRuntimeCheckpoint(
    binding,
    tester,
    name,
    beforeTakeScreenshot: () async {
      // Um build Web real pode precisar de mais de um frame de raster depois de
      // `convertFlutterSurfaceToImage`; sem isto a primeira captura sai válida
      // porém quase preta.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
    },
  );
  expect(tester.takeException(), isNull, reason: 'depois do checkpoint $name');
}

Widget _moldura(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.darkTheme,
  home: Scaffold(backgroundColor: AppTheme.surfaceSlate, body: child),
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  /// `setSurfaceSize` do binding de integracao exige estar DENTRO do teste --
  /// chamado em `setUp` ele estoura `'inTest': is not true`. Medido, nao
  /// suposto.
  Future<void> dimensionar() async {
    await binding.setSurfaceSize(
      Size(_visualWidth.toDouble(), _visualHeight.toDouble()),
    );
    addTearDown(() => binding.setSurfaceSize(null));
  }

  testWidgets('carta sem arte cai no verso do ManaLoom', (tester) async {
    _assertProofEnvironment();
    _emitContext('card_back_fallback', _cardBackCheckpoints);
    await dimensionar();

    // A URL ausente é o ponto: o contrato antigo dizia "disposable card image
    // URL absent and restored after capture", o que na prática era apagar a URL
    // no fixture e repor depois. Aqui a ausência é declarada, não encenada.
    await tester.pumpWidget(
      _moldura(
        const Center(
          child: SizedBox(
            width: 336,
            height: 468,
            child: CachedCardImage(
              imageUrl: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _capture(binding, tester, _cardBackCheckpoints[0]);
  });
}
