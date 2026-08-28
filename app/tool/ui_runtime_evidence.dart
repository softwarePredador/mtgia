import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

const uiLiveEvidenceCriteria = <String>{
  'visual_hierarchy',
  'brand_and_mtg_identity',
  'color_and_contrast',
  'typography',
  'spacing_and_density',
  'responsive_fit',
  'interaction_clarity',
  'state_coverage',
  'accessibility_visual',
  'attractiveness',
};

class UiRuntimeEvidenceException implements Exception {
  const UiRuntimeEvidenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UiRuntimeExtractionResult {
  const UiRuntimeExtractionResult({
    required this.manifestFile,
    required this.manifest,
  });

  final File manifestFile;
  final Map<String, Object?> manifest;
}

class AndroidEgressAssessment {
  const AndroidEgressAssessment({
    required this.findings,
    required this.loopbackAttempts,
  });

  final List<String> findings;
  final int loopbackAttempts;

  bool get isClean => findings.isEmpty;

  Map<String, Object> toJson() => <String, Object>{
    'status': isClean ? 'pass' : 'fail',
    'external_or_unclassified_attempts': findings.length,
    'loopback_attempts': loopbackAttempts,
    'findings': findings,
  };
}

class AndroidEgressReceiptVerification {
  const AndroidEgressReceiptVerification({
    required this.receipt,
    required this.receiptSha256,
  });

  final Map<String, dynamic> receipt;
  final String receiptSha256;

  Map<String, Object> toManifestJson() {
    final identity = _objectOrEmpty(receipt['identity']);
    final assessment = _objectOrEmpty(receipt['network_egress']);
    return <String, Object>{
      'status': 'pass',
      'receipt_schema': receipt['schema_version']!.toString(),
      'receipt_sha256': receiptSha256,
      'run_id': receipt['run_id']!.toString(),
      'package': identity['package']!.toString(),
      'uid': identity['uid']!,
      'observed_pids': _integerList(identity['observed_pids']),
      'external_or_unclassified_attempts':
          assessment['external_or_unclassified_attempts']!,
      'loopback_attempts': assessment['loopback_attempts']!,
    };
  }
}

AndroidEgressAssessment assessAndroidNetworkEgress(
  String log, {
  Set<String> allowedLoopbackHosts = const {'127.0.0.1', 'localhost', '::1'},
}) {
  final findings = <String>[];
  var loopbackAttempts = 0;
  final marker = RegExp(
    r'(Making request to:|https?://|UnknownHostException|Unable to resolve host|'
    r'getaddrinfo|ConnectException|SocketException|CctTransportBackend)',
    caseSensitive: false,
  );
  final url = RegExp(r'https?://[^\s,)]+', caseSensitive: false);
  final hostAfterMarker = RegExp(
    r'(?:host|to:|address)[= ]+\[?([A-Za-z0-9._:-]+)\]?',
    caseSensitive: false,
  );

  for (final rawLine in const LineSplitter().convert(log)) {
    if (!marker.hasMatch(rawLine)) continue;
    final hosts = <String>{};
    for (final match in url.allMatches(rawLine)) {
      final parsed = Uri.tryParse(match.group(0) ?? '');
      final value = parsed?.host.toLowerCase() ?? '';
      if (value.isNotEmpty) hosts.add(value);
    }
    for (final match in hostAfterMarker.allMatches(rawLine)) {
      var value = match.group(1)?.toLowerCase() ?? '';
      if (value == 'http:' || value == 'https:') continue;
      if (':'.allMatches(value).length == 1) {
        value = value.replaceAll(RegExp(r':\d+$'), '');
      }
      if (value.isNotEmpty) hosts.add(value);
    }
    final external = hosts.difference(allowedLoopbackHosts);
    if (external.isNotEmpty) {
      findings.add('external:${external.toList()..sort()}:${rawLine.trim()}');
      continue;
    }
    if (hosts.isNotEmpty) {
      loopbackAttempts++;
      continue;
    }
    findings.add('unclassified:${rawLine.trim()}');
  }
  return AndroidEgressAssessment(
    findings: List<String>.unmodifiable(findings),
    loopbackAttempts: loopbackAttempts,
  );
}

AndroidEgressReceiptVerification sealAndroidEgressReceipt({
  required File receiptFile,
  required File runtimeLog,
  required File nativeLog,
  required File pidTrace,
  required File policyFile,
  required String expectedRunId,
  required String expectedSourceDigest,
  required String expectedProfile,
  required String expectedTarget,
}) {
  final candidate = _validateAndroidEgressReceiptEnvelope(
    receiptFile: receiptFile,
    runtimeLog: runtimeLog,
    nativeLog: nativeLog,
    pidTrace: pidTrace,
    policyFile: policyFile,
    expectedRunId: expectedRunId,
    expectedSourceDigest: expectedSourceDigest,
    expectedProfile: expectedProfile,
    expectedTarget: expectedTarget,
    requireTerminal: false,
  );
  final identity = _objectOrEmpty(candidate['identity']);
  final uid = identity['uid'] as int;
  final window = _extractAndroidEgressWindow(
    nativeLog.readAsStringSync(),
    runId: expectedRunId,
    uid: uid,
  );
  final pidAssessment = _parseAndroidPidTrace(
    pidTrace.readAsStringSync(),
    expectedUid: uid,
    expectedRunId: expectedRunId,
  );
  final sampledPids = _integerList(identity['sampled_pids']).toSet();
  if (!_sameIntSet(sampledPids, pidAssessment.sampledPids)) {
    throw const UiRuntimeEvidenceException(
      'Android egress sampled PID set does not match the raw trace.',
    );
  }
  final observedPids = <int>{
    ...pidAssessment.sampledPids,
    ...window.loggedPids,
  }.toList()..sort();
  identity['logged_pids'] = window.loggedPids.toList()..sort();
  identity['observed_pids'] = observedPids;
  candidate['identity'] = identity;
  final allowedHosts = _androidLoopbackHosts(policyFile);
  final assessment = assessAndroidNetworkEgress(
    '${runtimeLog.readAsStringSync()}\n${window.text}',
    allowedLoopbackHosts: allowedHosts,
  );
  candidate['network_egress'] = assessment.toJson();
  candidate['status'] = assessment.isClean
      ? 'PASS_ANDROID_EGRESS'
      : 'FAIL_ANDROID_EGRESS';
  candidate['sealed_at'] = DateTime.now().toUtc().toIso8601String();
  final artifacts = _objectOrEmpty(candidate['artifacts']);
  artifacts['runtime_log_sha256'] = sha256
      .convert(runtimeLog.readAsBytesSync())
      .toString();
  artifacts['native_log_sha256'] = sha256
      .convert(nativeLog.readAsBytesSync())
      .toString();
  artifacts['native_window_sha256'] = sha256
      .convert(utf8.encode(window.text))
      .toString();
  artifacts['pid_trace_sha256'] = sha256
      .convert(pidTrace.readAsBytesSync())
      .toString();
  artifacts['policy_sha256'] = sha256
      .convert(policyFile.readAsBytesSync())
      .toString();
  candidate['artifacts'] = artifacts;
  _writeJsonAtomically(receiptFile, candidate);
  if (!assessment.isClean) {
    throw UiRuntimeEvidenceException(
      'Android network egress attempt detected: '
      '${assessment.findings.join(' | ')}',
    );
  }
  return verifyAndroidEgressReceipt(
    receiptFile: receiptFile,
    runtimeLog: runtimeLog,
    policyFile: policyFile,
    expectedRunId: expectedRunId,
    expectedSourceDigest: expectedSourceDigest,
    expectedProfile: expectedProfile,
    expectedTarget: expectedTarget,
  );
}

AndroidEgressReceiptVerification verifyAndroidEgressReceipt({
  required File receiptFile,
  required File runtimeLog,
  required File policyFile,
  required String expectedRunId,
  required String expectedSourceDigest,
  required String expectedProfile,
  required String expectedTarget,
}) {
  if (!receiptFile.existsSync() ||
      FileSystemEntity.typeSync(receiptFile.path, followLinks: false) !=
          FileSystemEntityType.file) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt is missing, non-regular or a symlink.',
    );
  }
  final receipt = _readJsonObject(receiptFile, 'Android egress receipt');
  final artifacts = _objectOrEmpty(receipt['artifacts']);
  final nativePath = artifacts['native_log_path']?.toString() ?? '';
  final pidTracePath = artifacts['pid_trace_path']?.toString() ?? '';
  if (nativePath.isEmpty || pidTracePath.isEmpty) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt is missing native log or PID trace path.',
    );
  }
  final nativeLog = File(nativePath);
  final pidTrace = File(pidTracePath);
  final validated = _validateAndroidEgressReceiptEnvelope(
    receiptFile: receiptFile,
    runtimeLog: runtimeLog,
    nativeLog: nativeLog,
    pidTrace: pidTrace,
    policyFile: policyFile,
    expectedRunId: expectedRunId,
    expectedSourceDigest: expectedSourceDigest,
    expectedProfile: expectedProfile,
    expectedTarget: expectedTarget,
    requireTerminal: true,
  );
  final identity = _objectOrEmpty(validated['identity']);
  final uid = identity['uid'] as int;
  final window = _extractAndroidEgressWindow(
    nativeLog.readAsStringSync(),
    runId: expectedRunId,
    uid: uid,
  );
  final assessment = assessAndroidNetworkEgress(
    '${runtimeLog.readAsStringSync()}\n${window.text}',
    allowedLoopbackHosts: _androidLoopbackHosts(policyFile),
  );
  final embedded = _objectOrEmpty(validated['network_egress']);
  if (!assessment.isClean ||
      embedded['status'] != 'pass' ||
      embedded['external_or_unclassified_attempts'] != 0 ||
      embedded['loopback_attempts'] != assessment.loopbackAttempts ||
      !_sameStringList(embedded['findings'], assessment.findings)) {
    throw UiRuntimeEvidenceException(
      'Android egress receipt assessment does not match the raw logs: '
      '${assessment.findings.join(' | ')}',
    );
  }
  return AndroidEgressReceiptVerification(
    receipt: validated,
    receiptSha256: sha256.convert(receiptFile.readAsBytesSync()).toString(),
  );
}

class UiLiveEvidenceVerification {
  const UiLiveEvidenceVerification({
    required this.reviewFile,
    required this.captureManifestFile,
    required this.screenshotCount,
    required this.surface,
    required this.sourceDigest,
  });

  final File reviewFile;
  final File captureManifestFile;
  final int screenshotCount;
  final String surface;
  final String sourceDigest;

  Map<String, Object> toJson() => <String, Object>{
    'status': 'PASS',
    'review': reviewFile.path,
    'capture_manifest': captureManifestFile.path,
    'surface': surface,
    'source_digest': sourceDigest,
    'screenshot_count': screenshotCount,
    'evidence_levels': const <String>[
      'PASS_AUTOMATED',
      'PASS_RUNTIME',
      'PASS_VISUAL_REVIEWED',
    ],
  };
}

UiRuntimeExtractionResult extractUiRuntimeEvidence({
  required File logFile,
  required Directory repoRoot,
  required String outputRelativePath,
  required String expectedSourceDigest,
  bool replace = false,
  DateTime? generatedAt,
}) {
  _expectSha256(expectedSourceDigest, 'expected source digest');
  if (!logFile.existsSync()) {
    throw UiRuntimeEvidenceException(
      'Runtime log does not exist: ${logFile.path}',
    );
  }

  final relativeOutput = _safeRelativePath(outputRelativePath);
  if (!relativeOutput.startsWith('docs/qa/ui-live/')) {
    throw const UiRuntimeEvidenceException(
      'Runtime evidence must live below docs/qa/ui-live/.',
    );
  }
  final output = Directory('${repoRoot.absolute.path}/$relativeOutput');
  if (output.existsSync()) {
    if (!replace) {
      throw UiRuntimeEvidenceException(
        'Evidence output already exists: ${output.path}. '
        'Use --replace only for the exact current evidence directory.',
      );
    }
    if (!relativeOutput.startsWith('docs/qa/ui-live/current/')) {
      throw const UiRuntimeEvidenceException(
        '--replace is restricted to docs/qa/ui-live/current/.',
      );
    }
    output.deleteSync(recursive: true);
  }

  final logBytes = logFile.readAsBytesSync();
  final log = utf8.decode(logBytes, allowMalformed: false);
  final runtimeConsole = _expectCleanRuntimeLog(log);
  final parsed = _parseRuntimeLog(log);
  final context = parsed.context;
  if (context['schema_version'] != 'manaloom_ui_runtime_context_v1') {
    throw const UiRuntimeEvidenceException(
      'Unsupported or missing VISUAL_PROOF_CONTEXT schema.',
    );
  }
  if (context['source_digest'] != expectedSourceDigest) {
    throw UiRuntimeEvidenceException(
      'Runtime source digest ${context['source_digest']} does not match '
      '$expectedSourceDigest.',
    );
  }
  final target = _requiredText(context, 'target');
  final deviceContract = _requiredText(context, 'device_contract');
  if (!_runtimeTargetContractIsCoherent(target, deviceContract)) {
    throw UiRuntimeEvidenceException(
      'Runtime target $target contradicts its device contract.',
    );
  }

  final requiredCheckpoints = _stringList(
    context['required_checkpoints'],
    'required_checkpoints',
  );
  if (requiredCheckpoints.isEmpty) {
    throw const UiRuntimeEvidenceException(
      'Runtime context must declare at least one required checkpoint.',
    );
  }
  if (requiredCheckpoints.toSet().length != requiredCheckpoints.length) {
    throw const UiRuntimeEvidenceException(
      'Runtime context contains duplicate required checkpoints.',
    );
  }
  if (parsed.screenshots.keys
          .toSet()
          .difference(requiredCheckpoints.toSet())
          .isNotEmpty ||
      requiredCheckpoints
          .toSet()
          .difference(parsed.screenshots.keys.toSet())
          .isNotEmpty) {
    throw UiRuntimeEvidenceException(
      'Captured checkpoints ${parsed.screenshots.keys.toList()} do not match '
      'required checkpoints $requiredCheckpoints.',
    );
  }

  output.createSync(recursive: true);
  final screenshotEntries = <Map<String, Object>>[];
  for (final name in requiredCheckpoints) {
    final bytes = parsed.screenshots[name]!;
    final image = img.decodePng(bytes);
    if (image == null || image.width <= 0 || image.height <= 0) {
      throw UiRuntimeEvidenceException(
        'Checkpoint $name is not a valid non-empty PNG.',
      );
    }
    _expectVisuallyMeaningfulScreenshot(image, name);
    final fileName = '$name.png';
    final relativePath = '$relativeOutput/$fileName';
    File('${output.path}/$fileName').writeAsBytesSync(bytes, flush: true);
    screenshotEntries.add(<String, Object>{
      'checkpoint': name,
      'path': relativePath,
      'sha256': sha256.convert(bytes).toString(),
      'bytes': bytes.length,
      'width': image.width,
      'height': image.height,
    });
  }

  final timestamp = (generatedAt ?? DateTime.now().toUtc()).toUtc();
  final manifest = <String, Object?>{
    'schema_version': 'manaloom_ui_runtime_capture_v1',
    'status': 'PASS_RUNTIME',
    'generated_at': timestamp.toIso8601String(),
    'source_digest': expectedSourceDigest,
    'surface': _requiredText(context, 'surface'),
    'profile': _requiredText(context, 'profile'),
    'runtime': _requiredText(context, 'runtime'),
    'target': target,
    'device_contract': deviceContract,
    'runtime_console': runtimeConsole,
    'log_sha256': sha256.convert(logBytes).toString(),
    'checkpoint_count': screenshotEntries.length,
    'required_checkpoints': requiredCheckpoints,
    'screenshots': screenshotEntries,
  };
  final manifestFile = File('${output.path}/capture-manifest.json');
  _writeJson(manifestFile, manifest);
  return UiRuntimeExtractionResult(
    manifestFile: manifestFile,
    manifest: manifest,
  );
}

UiRuntimeExtractionResult indexUiRuntimeScreenshotDirectory({
  required Directory screenshotDirectory,
  required File runtimeLog,
  required Directory repoRoot,
  required String manifestRelativePath,
  required String expectedSourceDigest,
  required String surface,
  required String profile,
  required String runtime,
  required String target,
  required String deviceContract,
  File? androidEgressReceipt,
  String? androidEgressRunId,
  DateTime? generatedAt,
}) {
  _expectSha256(expectedSourceDigest, 'expected source digest');
  if (!runtimeLog.existsSync()) {
    throw UiRuntimeEvidenceException(
      'Runtime log does not exist: ${runtimeLog.path}',
    );
  }
  if (!screenshotDirectory.existsSync()) {
    throw UiRuntimeEvidenceException(
      'Screenshot directory does not exist: ${screenshotDirectory.path}',
    );
  }

  final repoPath = repoRoot.absolute.path;
  final screenshotPath = screenshotDirectory.absolute.path;
  final screenshotPrefix = '$repoPath${Platform.pathSeparator}';
  if (!screenshotPath.startsWith(screenshotPrefix)) {
    throw const UiRuntimeEvidenceException(
      'Indexed screenshots must live inside the repository.',
    );
  }
  final screenshotRelativeRoot = screenshotPath
      .substring(screenshotPrefix.length)
      .replaceAll(Platform.pathSeparator, '/');
  _safeRelativePath(screenshotRelativeRoot);

  final relativeManifest = _safeRelativePath(manifestRelativePath);
  if (!relativeManifest.startsWith('docs/qa/ui-live/current/') ||
      !relativeManifest.endsWith('.json')) {
    throw const UiRuntimeEvidenceException(
      'Indexed runtime manifest must be a JSON file below '
      'docs/qa/ui-live/current/.',
    );
  }

  final logBytes = runtimeLog.readAsBytesSync();
  final log = utf8.decode(logBytes, allowMalformed: false);
  final runtimeConsole = _expectCleanRuntimeLog(log);
  final context = _parseRuntimeContextMarker(log);
  if (context['schema_version'] != 'manaloom_ui_runtime_context_v1') {
    throw const UiRuntimeEvidenceException(
      'Unsupported or missing VISUAL_PROOF_CONTEXT schema.',
    );
  }
  if (context['source_digest'] != expectedSourceDigest) {
    throw UiRuntimeEvidenceException(
      'Runtime source digest ${context['source_digest']} does not match '
      '$expectedSourceDigest.',
    );
  }
  final expectedContext = <String, String>{
    'surface': surface,
    'profile': profile,
    'runtime': runtime,
    'target': target,
    'device_contract': deviceContract,
  };
  for (final entry in expectedContext.entries) {
    if (_requiredText(context, entry.key) != entry.value) {
      throw UiRuntimeEvidenceException(
        'Runtime context ${entry.key} does not match the indexed '
        '${entry.key}.',
      );
    }
  }
  if (!_runtimeTargetContractIsCoherent(target, deviceContract)) {
    throw UiRuntimeEvidenceException(
      'Runtime target $target contradicts its device contract.',
    );
  }
  AndroidEgressReceiptVerification? androidEgress;
  if (target == 'android_physical') {
    if (androidEgressReceipt == null ||
        androidEgressRunId == null ||
        androidEgressRunId.trim().isEmpty) {
      throw const UiRuntimeEvidenceException(
        'Physical Android runtime requires a bound egress receipt and run ID.',
      );
    }
    androidEgress = verifyAndroidEgressReceipt(
      receiptFile: androidEgressReceipt,
      runtimeLog: runtimeLog,
      policyFile: File(
        '$repoPath/app/test/ui/fixtures/ui_live_evidence_policy.json',
      ),
      expectedRunId: androidEgressRunId,
      expectedSourceDigest: expectedSourceDigest,
      expectedProfile: profile,
      expectedTarget: target,
    );
  }
  final requiredCheckpoints = _stringList(
    context['required_checkpoints'],
    'required_checkpoints',
  );
  if (requiredCheckpoints.isEmpty ||
      requiredCheckpoints.toSet().length != requiredCheckpoints.length) {
    throw const UiRuntimeEvidenceException(
      'Runtime context must declare unique required checkpoints.',
    );
  }

  final pngFiles =
      screenshotDirectory
          .listSync(followLinks: false)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  if (pngFiles.isEmpty) {
    throw const UiRuntimeEvidenceException(
      'Indexed runtime directory contains no PNG screenshots.',
    );
  }
  final indexedCheckpoints = pngFiles
      .map(
        (file) => file.uri.pathSegments.last.replaceFirst(
          RegExp(r'\.png$', caseSensitive: false),
          '',
        ),
      )
      .toSet();
  if (!_sameSet(indexedCheckpoints, requiredCheckpoints.toSet())) {
    throw UiRuntimeEvidenceException(
      'Indexed checkpoints ${indexedCheckpoints.toList()..sort()} do not '
      'match runtime checkpoints ${requiredCheckpoints.toList()..sort()}.',
    );
  }

  final screenshotEntries = <Map<String, Object>>[];
  for (final file in pngFiles) {
    final checkpoint = file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.png$', caseSensitive: false),
      '',
    );
    _expectCheckpointName(checkpoint);
    final bytes = file.readAsBytesSync();
    final image = img.decodePng(bytes);
    if (image == null || image.width <= 0 || image.height <= 0) {
      throw UiRuntimeEvidenceException(
        'Checkpoint $checkpoint is not a valid non-empty PNG.',
      );
    }
    _expectVisuallyMeaningfulScreenshot(image, checkpoint);
    screenshotEntries.add(<String, Object>{
      'checkpoint': checkpoint,
      'path': '$screenshotRelativeRoot/${file.uri.pathSegments.last}',
      'sha256': sha256.convert(bytes).toString(),
      'bytes': bytes.length,
      'width': image.width,
      'height': image.height,
    });
  }

  final timestamp = (generatedAt ?? DateTime.now().toUtc()).toUtc();
  final manifest = <String, Object?>{
    'schema_version': 'manaloom_ui_runtime_capture_v1',
    'status': 'PASS_RUNTIME',
    'generated_at': timestamp.toIso8601String(),
    'source_digest': expectedSourceDigest,
    'surface': surface,
    'profile': profile,
    'runtime': runtime,
    'target': target,
    'device_contract': deviceContract,
    'runtime_console': runtimeConsole,
    if (androidEgress != null)
      'android_network_egress': androidEgress.toManifestJson(),
    'log_sha256': sha256.convert(logBytes).toString(),
    'checkpoint_count': screenshotEntries.length,
    'required_checkpoints': requiredCheckpoints,
    'screenshots': screenshotEntries,
  };
  final manifestFile = File('$repoPath/$relativeManifest');
  _writeJson(manifestFile, manifest);
  return UiRuntimeExtractionResult(
    manifestFile: manifestFile,
    manifest: manifest,
  );
}

int validateRuntimeScreenshotDirectory(Directory screenshotDirectory) {
  if (!screenshotDirectory.existsSync()) {
    throw UiRuntimeEvidenceException(
      'Screenshot directory does not exist: ${screenshotDirectory.path}',
    );
  }
  final pngFiles =
      screenshotDirectory
          .listSync(followLinks: false)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
  if (pngFiles.isEmpty) {
    throw const UiRuntimeEvidenceException(
      'Runtime screenshot directory contains no PNG screenshots.',
    );
  }
  for (final file in pngFiles) {
    final checkpoint = file.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.png$', caseSensitive: false),
      '',
    );
    _expectCheckpointName(checkpoint);
    final image = img.decodePng(file.readAsBytesSync());
    if (image == null || image.width <= 0 || image.height <= 0) {
      throw UiRuntimeEvidenceException(
        'Checkpoint $checkpoint is not a valid non-empty PNG.',
      );
    }
    _expectVisuallyMeaningfulScreenshot(image, checkpoint);
  }
  return pngFiles.length;
}

void _expectVisuallyMeaningfulScreenshot(img.Image image, String checkpoint) {
  const maximumSamplesPerAxis = 64;
  const quantizationStep = 16;
  const minimumRgbSpread = 8;
  const minimumNonDominantSampleRatio = 0.005;
  final columns = image.width < maximumSamplesPerAxis
      ? image.width
      : maximumSamplesPerAxis;
  final rows = image.height < maximumSamplesPerAxis
      ? image.height
      : maximumSamplesPerAxis;
  var minimumRed = 255;
  var maximumRed = 0;
  var minimumGreen = 255;
  var maximumGreen = 0;
  var minimumBlue = 255;
  var maximumBlue = 0;
  final quantizedColorCounts = <int, int>{};

  for (var row = 0; row < rows; row++) {
    final y = rows == 1 ? 0 : (row * (image.height - 1)) ~/ (rows - 1);
    for (var column = 0; column < columns; column++) {
      final x = columns == 1
          ? 0
          : (column * (image.width - 1)) ~/ (columns - 1);
      final pixel = image.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();
      if (red < minimumRed) minimumRed = red;
      if (red > maximumRed) maximumRed = red;
      if (green < minimumGreen) minimumGreen = green;
      if (green > maximumGreen) maximumGreen = green;
      if (blue < minimumBlue) minimumBlue = blue;
      if (blue > maximumBlue) maximumBlue = blue;
      final quantizedColor =
          ((red ~/ quantizationStep) << 8) |
          ((green ~/ quantizationStep) << 4) |
          (blue ~/ quantizationStep);
      quantizedColorCounts.update(
        quantizedColor,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
  }

  final widestChannelSpread = <int>[
    maximumRed - minimumRed,
    maximumGreen - minimumGreen,
    maximumBlue - minimumBlue,
  ].reduce((left, right) => left > right ? left : right);
  final sampleCount = rows * columns;
  final dominantColorCount = quantizedColorCounts.values.reduce(
    (left, right) => left > right ? left : right,
  );
  final nonDominantSampleCount = sampleCount - dominantColorCount;
  final minimumNonDominantSampleCount =
      (sampleCount * minimumNonDominantSampleRatio).ceil();
  if (widestChannelSpread < minimumRgbSpread ||
      quantizedColorCounts.length < 2 ||
      nonDominantSampleCount < minimumNonDominantSampleCount) {
    throw UiRuntimeEvidenceException(
      'Checkpoint $checkpoint is visually blank or uniform; '
      'runtime proof requires rendered interface content.',
    );
  }
}

UiLiveEvidenceVerification verifyUiLiveEvidence({
  required File reviewFile,
  required Directory repoRoot,
  required String expectedSourceDigest,
}) {
  _expectSha256(expectedSourceDigest, 'expected source digest');
  if (!reviewFile.existsSync()) {
    throw UiRuntimeEvidenceException(
      'Live UI review is missing: ${reviewFile.path}',
    );
  }
  final review = _readJsonObject(reviewFile, 'live UI review');
  final findings = <String>[];

  void expect(bool condition, String message) {
    if (!condition) findings.add(message);
  }

  expect(
    review['schema_version'] == 'manaloom_ui_live_review_v1',
    'unsupported review schema',
  );
  expect(review['status'] == 'PASS', 'aggregate review status is not PASS');
  expect(
    review['source_digest'] == expectedSourceDigest,
    'review source digest is stale',
  );

  final automated = _objectOrEmpty(review['automated']);
  expect(
    automated['status'] == 'PASS_AUTOMATED',
    'automated evidence is not PASS_AUTOMATED',
  );
  expect(
    _stringListOrEmpty(automated['commands']).isNotEmpty,
    'automated evidence must list executed commands',
  );
  expect(
    _hasIsoTimestamp(automated['verified_at']),
    'automated verified_at is missing or invalid',
  );

  final runtime = _objectOrEmpty(review['runtime']);
  expect(
    runtime['status'] == 'PASS_RUNTIME',
    'runtime evidence is not PASS_RUNTIME',
  );
  final captureReferences = <Map<String, dynamic>>[
    ..._objectListOrEmpty(runtime['capture_manifests']),
  ];
  if (captureReferences.isEmpty) {
    final legacyReference = _objectOrEmpty(runtime['capture_manifest']);
    if (legacyReference.isNotEmpty) captureReferences.add(legacyReference);
  }
  expect(
    captureReferences.isNotEmpty,
    'runtime capture manifest path is missing',
  );

  final captureManifestFiles = <File>[];
  final captureManifestHashes = <String>{};
  final captureNames = <String>{};
  final captureHashes = <String>{};
  final captureProfiles = <String>{};
  final captureSurfaces = <String>{};
  final captureTargets = <String>{};
  final captureCountsByProfile = <String, int>{};
  final captureTargetsByProfile = <String, String>{};
  final captureSurfacesByProfile = <String, String>{};
  var screenshotCount = 0;
  final hasMultipleCaptures = captureReferences.length > 1;
  for (final captureReference in captureReferences) {
    final captureRelativePath = captureReference['path']?.toString() ?? '';
    final captureExpectedHash = captureReference['sha256']?.toString() ?? '';
    Map<String, dynamic> capture = <String, dynamic>{};
    if (captureRelativePath.isEmpty) {
      findings.add('runtime capture manifest path is missing');
      continue;
    }
    try {
      final safeManifestPath = _safeRelativePath(captureRelativePath);
      final captureManifestFile = File(
        '${repoRoot.absolute.path}/$safeManifestPath',
      );
      if (!captureManifestFile.existsSync()) {
        findings.add('runtime capture manifest does not exist');
        continue;
      }
      final manifestBytes = captureManifestFile.readAsBytesSync();
      final observedManifestHash = sha256.convert(manifestBytes).toString();
      expect(
        observedManifestHash == captureExpectedHash,
        'runtime capture manifest hash does not match',
      );
      captureManifestFiles.add(captureManifestFile);
      captureManifestHashes.add(observedManifestHash);
      capture = _readJsonObject(
        captureManifestFile,
        'runtime capture manifest',
      );

      expect(
        capture['schema_version'] == 'manaloom_ui_runtime_capture_v1',
        'unsupported runtime capture schema',
      );
      expect(
        capture['status'] == 'PASS_RUNTIME',
        'capture status is not PASS_RUNTIME',
      );
      expect(
        capture['source_digest'] == expectedSourceDigest,
        'capture source digest is stale',
      );
      expect(
        capture['target'] == 'android_physical' ||
            capture['target'] == 'android_emulator' ||
            capture['target'] == 'web_real_build',
        'capture target is not an attested Android or real Web runtime',
      );
      final target = capture['target']?.toString() ?? '';
      final deviceContract = capture['device_contract']?.toString() ?? '';
      expect(
        _runtimeTargetContractIsCoherent(target, deviceContract),
        'capture target contradicts its device contract',
      );
      final runtimeConsole = _objectOrEmpty(capture['runtime_console']);
      expect(
        runtimeConsole['status'] == 'pass' &&
            runtimeConsole['forbidden_entries'] == 0,
        'runtime console is not clean',
      );
      if (target == 'android_physical') {
        final androidEgress = _objectOrEmpty(capture['android_network_egress']);
        final observedPidList = _integerList(androidEgress['observed_pids']);
        final observedPids = observedPidList.toSet();
        final uid = androidEgress['uid'];
        final loopbackAttempts = androidEgress['loopback_attempts'];
        expect(
          androidEgress['status'] == 'pass' &&
              androidEgress['receipt_schema'] ==
                  'manaloom.android_ui_egress_receipt.v2' &&
              _isSha256(androidEgress['receipt_sha256']?.toString() ?? '') &&
              (androidEgress['run_id']?.toString().isNotEmpty ?? false) &&
              androidEgress['package'] == 'com.mtgia.mtg_app' &&
              uid is int &&
              uid > 0 &&
              androidEgress['external_or_unclassified_attempts'] == 0 &&
              loopbackAttempts is int &&
              loopbackAttempts >= 0 &&
              observedPids.isNotEmpty &&
              observedPidList.length == observedPids.length &&
              observedPids.every((pid) => pid > 0),
          'physical Android capture lacks a clean bound egress receipt',
        );
      }

      final profile = capture['profile']?.toString() ?? '';
      final surface = capture['surface']?.toString() ?? '';
      expect(profile.trim().isNotEmpty, 'capture profile is missing');
      expect(surface.trim().isNotEmpty, 'capture surface is missing');
      captureProfiles.add(profile);
      captureSurfaces.add(surface);
      captureTargets.add(target);
      final screenshotEntries = _objectListOrEmpty(capture['screenshots']);
      expect(screenshotEntries.isNotEmpty, 'capture contains no screenshots');
      captureCountsByProfile[profile] = screenshotEntries.length;
      captureTargetsByProfile[profile] = target;
      final existingSurface = captureSurfacesByProfile[profile];
      expect(
        existingSurface == null || existingSurface == surface,
        'runtime profile $profile is shared by multiple surfaces',
      );
      captureSurfacesByProfile[profile] = surface;
      screenshotCount += screenshotEntries.length;
      for (final screenshot in screenshotEntries) {
        final checkpoint = screenshot['checkpoint']?.toString() ?? '';
        final captureName = hasMultipleCaptures
            ? '$profile:$checkpoint'
            : checkpoint;
        final relativePath = screenshot['path']?.toString() ?? '';
        final expectedHash = screenshot['sha256']?.toString() ?? '';
        if (!captureNames.add(captureName)) {
          findings.add('duplicate capture checkpoint $captureName');
        }
        if (!_isSha256(expectedHash)) {
          findings.add('invalid screenshot hash for $captureName');
          continue;
        }
        captureHashes.add(expectedHash);
        final safePath = _safeRelativePath(relativePath);
        final imageFile = File('${repoRoot.absolute.path}/$safePath');
        if (!imageFile.existsSync()) {
          findings.add('screenshot is missing for $captureName');
          continue;
        }
        final bytes = imageFile.readAsBytesSync();
        if (sha256.convert(bytes).toString() != expectedHash) {
          findings.add('screenshot hash does not match for $captureName');
        }
        final image = img.decodePng(bytes);
        if (image == null) {
          findings.add('screenshot is not valid PNG for $captureName');
          continue;
        }
        expect(
          screenshot['width'] == image.width &&
              screenshot['height'] == image.height,
          'screenshot dimensions do not match for $captureName',
        );
      }
    } on UiRuntimeEvidenceException catch (error) {
      findings.add(error.message);
    }
  }

  final evidencePolicyFile = File(
    '${repoRoot.absolute.path}/'
    'app/test/ui/fixtures/ui_live_evidence_policy.json',
  );
  if (evidencePolicyFile.existsSync()) {
    _validateUiLiveEvidencePolicy(
      policyFile: evidencePolicyFile,
      review: review,
      captureCountsByProfile: captureCountsByProfile,
      captureTargetsByProfile: captureTargetsByProfile,
      captureSurfacesByProfile: captureSurfacesByProfile,
      captureTargets: captureTargets,
      expect: expect,
    );
  }

  final visual = _objectOrEmpty(review['visual_review']);
  expect(
    visual['status'] == 'PASS_VISUAL_REVIEWED',
    'visual review is not PASS_VISUAL_REVIEWED',
  );
  expect(
    _hasIsoTimestamp(visual['reviewed_at']),
    'visual reviewed_at is missing or invalid',
  );
  final reviewer = _objectOrEmpty(visual['reviewer']);
  expect(
    const {'agent', 'human'}.contains(reviewer['kind']),
    'visual reviewer kind must be agent or human',
  );
  expect(
    (reviewer['name']?.toString().trim().isNotEmpty ?? false),
    'visual reviewer name is missing',
  );
  for (final field in const [
    'visual_thesis',
    'content_plan',
    'interaction_thesis',
  ]) {
    expect(
      visual[field]?.toString().trim().isNotEmpty ?? false,
      '$field is missing from visual review',
    );
  }

  final criteria = _objectOrEmpty(visual['criteria']);
  expect(
    _sameSet(criteria.keys.toSet(), uiLiveEvidenceCriteria),
    'visual criteria must be exactly ${uiLiveEvidenceCriteria.toList()..sort()}',
  );
  for (final criterion in uiLiveEvidenceCriteria) {
    final decision = _objectOrEmpty(criteria[criterion]);
    expect(
      decision['status'] == 'pass',
      'visual criterion $criterion is not pass',
    );
    expect(
      decision['note']?.toString().trim().isNotEmpty ?? false,
      'visual criterion $criterion has no review note',
    );
  }

  if (hasMultipleCaptures) {
    final reviewedManifestHashes = _stringListOrEmpty(
      visual['reviewed_capture_manifest_sha256'],
    ).toSet();
    final reviewedProfiles = _stringListOrEmpty(
      visual['reviewed_profiles'],
    ).toSet();
    expect(
      _sameSet(reviewedManifestHashes, captureManifestHashes),
      'visual review manifest hashes do not cover every runtime capture',
    );
    expect(
      _sameSet(reviewedProfiles, captureProfiles),
      'visual review profiles do not cover every runtime capture',
    );
    expect(
      visual['reviewed_screenshot_count'] == screenshotCount,
      'visual review screenshot count does not cover every runtime capture',
    );
  } else {
    final reviewedCheckpoints = _stringListOrEmpty(
      visual['reviewed_checkpoints'],
    ).toSet();
    final reviewedHashes = _stringListOrEmpty(
      visual['reviewed_screenshot_sha256'],
    ).toSet();
    expect(
      _sameSet(reviewedCheckpoints, captureNames),
      'visual review did not inspect every captured checkpoint',
    );
    expect(
      _sameSet(reviewedHashes, captureHashes),
      'visual review screenshot hashes do not match the capture',
    );
  }
  expect(
    _stringListOrEmpty(visual['blocking_findings']).isEmpty,
    'visual review has unresolved blocking findings',
  );

  if (findings.isNotEmpty) {
    throw UiRuntimeEvidenceException(
      'Live UI evidence failed:\n- ${findings.join('\n- ')}',
    );
  }

  return UiLiveEvidenceVerification(
    reviewFile: reviewFile,
    captureManifestFile: captureManifestFiles.first,
    screenshotCount: screenshotCount,
    surface: (captureSurfaces.toList()..sort()).join(','),
    sourceDigest: expectedSourceDigest,
  );
}

void _validateUiLiveEvidencePolicy({
  required File policyFile,
  required Map<String, dynamic> review,
  required Map<String, int> captureCountsByProfile,
  required Map<String, String> captureTargetsByProfile,
  required Map<String, String> captureSurfacesByProfile,
  required Set<String> captureTargets,
  required void Function(bool condition, String message) expect,
}) {
  final policy = _readJsonObject(policyFile, 'live UI evidence policy');
  expect(
    policy['schema_version'] == 'manaloom_ui_live_evidence_policy_v1',
    'unsupported live UI evidence policy schema',
  );
  final surfaces = _objectListOrEmpty(policy['surfaces']);
  for (final surface in surfaces) {
    final surfaceId = surface['id']?.toString().trim() ?? '';
    final requiredProfiles = _objectOrEmpty(surface['required_profiles']);
    for (final entry in requiredProfiles.entries) {
      final requiredCount = switch (entry.value) {
        int count => count,
        num count => count.toInt(),
        String value => int.tryParse(value.trim()),
        _ => null,
      };
      expect(
        surfaceId.isNotEmpty,
        'policy surface with required profiles has no id',
      );
      expect(
        requiredCount != null && requiredCount > 0,
        'policy profile ${entry.key} has an invalid checkpoint count',
      );
      expect(
        captureCountsByProfile[entry.key] == requiredCount,
        'runtime profile ${entry.key} must contain exactly '
        '$requiredCount screenshots',
      );
      expect(
        captureSurfacesByProfile[entry.key] == surfaceId,
        'runtime profile ${entry.key} must belong to surface $surfaceId',
      );
    }
  }
  final p0Surface = surfaces.cast<Map<String, dynamic>?>().firstWhere(
    (surface) => surface?['id'] == 'authenticated_p0_matrix',
    orElse: () => null,
  );
  expect(
    p0Surface != null,
    'live UI evidence policy has no authenticated P0 surface',
  );
  if (p0Surface != null) {
    final androidContract = _objectOrEmpty(
      p0Surface['android_runtime_contract'],
    );
    final currentAndroidProfile =
        androidContract['current_profile']?.toString().trim() ?? '';
    if (currentAndroidProfile.isNotEmpty) {
      final acceptedTargets = _stringListOrEmpty(
        androidContract['accepted_targets'],
      ).toSet();
      final observedTarget = captureTargetsByProfile[currentAndroidProfile];
      expect(
        observedTarget != null,
        'current Android runtime profile is missing',
      );
      expect(
        observedTarget != null && acceptedTargets.contains(observedTarget),
        'current Android runtime profile target is not accepted by policy',
      );
      if (androidContract['emulator_must_not_be_reported_as_physical'] ==
          true) {
        expect(
          !currentAndroidProfile.toLowerCase().contains('emulator') ||
              observedTarget == 'android_emulator',
          'emulator profile is not attested as android_emulator',
        );
        expect(
          !currentAndroidProfile.toLowerCase().contains('physical') ||
              observedTarget == 'android_physical',
          'physical profile is not attested as android_physical',
        );
      }
    }
  }

  final releaseChecks = _objectOrEmpty(review['release_checks']);
  final claimsPhysicalPass = releaseChecks.entries.any(
    (entry) =>
        entry.key.toLowerCase().contains('android_physical') &&
        entry.value.toString().toLowerCase().startsWith('pass'),
  );
  expect(
    !claimsPhysicalPass || captureTargets.contains('android_physical'),
    'release checks claim Android physical evidence without a physical capture',
  );
}

class _ParsedRuntimeLog {
  const _ParsedRuntimeLog({required this.context, required this.screenshots});

  final Map<String, dynamic> context;
  final Map<String, Uint8List> screenshots;
}

Map<String, dynamic> _parseRuntimeContextMarker(String log) {
  Map<String, dynamic>? context;
  for (final rawLine in const LineSplitter().convert(log)) {
    final contextOffset = rawLine.indexOf('VISUAL_PROOF_CONTEXT ');
    if (contextOffset < 0) continue;
    if (context != null) {
      throw const UiRuntimeEvidenceException(
        'Runtime log contains more than one VISUAL_PROOF_CONTEXT.',
      );
    }
    final payload = rawLine.substring(
      contextOffset + 'VISUAL_PROOF_CONTEXT '.length,
    );
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      throw const UiRuntimeEvidenceException(
        'VISUAL_PROOF_CONTEXT is not a JSON object.',
      );
    }
    context = decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  if (context == null) {
    throw const UiRuntimeEvidenceException(
      'Runtime log has no VISUAL_PROOF_CONTEXT.',
    );
  }
  return context;
}

bool _runtimeTargetContractIsCoherent(String target, String deviceContract) {
  final normalized = deviceContract.toLowerCase();
  return switch (target) {
    'android_emulator' =>
      normalized.contains('emulator') && !normalized.contains('physical'),
    'android_physical' =>
      normalized.contains('physical') && !normalized.contains('emulator'),
    'web_real_build' =>
      normalized.contains('web') ||
          normalized.contains('chrome') ||
          normalized.contains('browser'),
    _ => false,
  };
}

_ParsedRuntimeLog _parseRuntimeLog(String log) {
  Map<String, dynamic>? context;
  final chunks = <String, StringBuffer>{};
  final completed = <String, Uint8List>{};

  for (final rawLine in const LineSplitter().convert(log)) {
    final contextOffset = rawLine.indexOf('VISUAL_PROOF_CONTEXT ');
    if (contextOffset >= 0) {
      if (context != null) {
        throw const UiRuntimeEvidenceException(
          'Runtime log contains more than one VISUAL_PROOF_CONTEXT.',
        );
      }
      final payload = rawLine.substring(
        contextOffset + 'VISUAL_PROOF_CONTEXT '.length,
      );
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        throw const UiRuntimeEvidenceException(
          'VISUAL_PROOF_CONTEXT is not a JSON object.',
        );
      }
      context = decoded.map((key, value) => MapEntry(key.toString(), value));
      continue;
    }

    final markerOffset = rawLine.indexOf('SCREENSHOT_');
    if (markerOffset < 0) continue;
    final line = rawLine.substring(markerOffset);
    if (line.startsWith('SCREENSHOT_BEGIN ')) {
      final name = line.substring('SCREENSHOT_BEGIN '.length).trim();
      _expectCheckpointName(name);
      if (chunks.containsKey(name) || completed.containsKey(name)) {
        throw UiRuntimeEvidenceException(
          'Duplicate screenshot begin marker for $name.',
        );
      }
      chunks[name] = StringBuffer();
      continue;
    }
    if (line.startsWith('SCREENSHOT_CHUNK ')) {
      final payload = line.substring('SCREENSHOT_CHUNK '.length);
      final separator = payload.indexOf(' ');
      if (separator <= 0) {
        throw const UiRuntimeEvidenceException(
          'Malformed screenshot chunk marker.',
        );
      }
      final name = payload.substring(0, separator);
      final chunk = payload.substring(separator + 1).trim();
      final buffer = chunks[name];
      if (buffer == null || chunk.isEmpty) {
        throw UiRuntimeEvidenceException(
          'Screenshot chunk has no active begin marker for $name.',
        );
      }
      buffer.write(chunk);
      continue;
    }
    if (line.startsWith('SCREENSHOT_END ')) {
      final name = line.substring('SCREENSHOT_END '.length).trim();
      final buffer = chunks.remove(name);
      if (buffer == null) {
        throw UiRuntimeEvidenceException(
          'Screenshot end has no active begin marker for $name.',
        );
      }
      try {
        completed[name] = Uint8List.fromList(base64Decode(buffer.toString()));
      } on FormatException {
        throw UiRuntimeEvidenceException(
          'Screenshot $name contains invalid Base64.',
        );
      }
    }
  }

  if (context == null) {
    throw const UiRuntimeEvidenceException(
      'Runtime log has no VISUAL_PROOF_CONTEXT.',
    );
  }
  if (chunks.isNotEmpty) {
    throw UiRuntimeEvidenceException(
      'Runtime log has unfinished screenshots: ${chunks.keys.join(', ')}.',
    );
  }
  if (completed.isEmpty) {
    throw const UiRuntimeEvidenceException(
      'Runtime log has no completed screenshots.',
    );
  }
  return _ParsedRuntimeLog(context: context, screenshots: completed);
}

Map<String, Object> _expectCleanRuntimeLog(String log) {
  final forbidden = <String>[
    '══╡ EXCEPTION CAUGHT',
    'A RenderFlex overflowed',
    '[🖼️ CachedCardImage] falha',
    'Unhandled Exception',
  ];
  final findings = <String>{};
  for (final line in const LineSplitter().convert(log)) {
    if (line.contains('SCREENSHOT_CHUNK ')) continue;
    for (final pattern in forbidden) {
      if (line.contains(pattern)) findings.add(pattern);
    }
  }
  if (findings.isNotEmpty) {
    throw UiRuntimeEvidenceException(
      'Runtime console contains forbidden entries: ${findings.join(', ')}.',
    );
  }
  return <String, Object>{
    'status': 'pass',
    'forbidden_entries': findings.length,
    'derived_from_raw_log': true,
  };
}

class _AndroidEgressWindow {
  const _AndroidEgressWindow({required this.text, required this.loggedPids});

  final String text;
  final Set<int> loggedPids;
}

class _AndroidLogcatIdentity {
  const _AndroidLogcatIdentity({required this.uid, required this.pid});

  final int uid;
  final int pid;
}

class _AndroidPidTraceAssessment {
  const _AndroidPidTraceAssessment({
    required this.sampledPids,
    required this.samplesBeforeLaunch,
    required this.samplesDuringJourney,
    required this.drainSamples,
    required this.drainAfterEndSamples,
    required this.consecutiveZeroBeforeEnd,
    required this.consecutiveZeroAfterEnd,
    required this.samplerFailures,
  });

  final Set<int> sampledPids;
  final int samplesBeforeLaunch;
  final int samplesDuringJourney;
  final int drainSamples;
  final int drainAfterEndSamples;
  final int consecutiveZeroBeforeEnd;
  final int consecutiveZeroAfterEnd;
  final int samplerFailures;
}

_AndroidEgressWindow _extractAndroidEgressWindow(
  String nativeText, {
  required String runId,
  required int uid,
}) {
  final lines = const LineSplitter().convert(nativeText);
  final begin = 'MANALOOM_ANDROID_EGRESS_BEGIN run_id=$runId uid=$uid';
  final end = 'MANALOOM_ANDROID_EGRESS_END run_id=$runId uid=$uid';
  final beginIndexes = <int>[];
  final endIndexes = <int>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (line.contains('MANALOOM_ANDROID_EGRESS_BEGIN')) {
      if (!line.contains(begin)) {
        throw const UiRuntimeEvidenceException(
          'Android native log contains a foreign BEGIN marker.',
        );
      }
      beginIndexes.add(index);
    }
    if (line.contains('MANALOOM_ANDROID_EGRESS_END')) {
      if (!line.contains(end)) {
        throw const UiRuntimeEvidenceException(
          'Android native log contains a foreign END marker.',
        );
      }
      endIndexes.add(index);
    }
  }
  if (beginIndexes.length != 1 ||
      endIndexes.length != 1 ||
      beginIndexes.single >= endIndexes.single) {
    throw const UiRuntimeEvidenceException(
      'Android native log markers must be unique and ordered.',
    );
  }
  final windowLines = lines.sublist(beginIndexes.single, endIndexes.single + 1);
  final loggedPids = <int>{};
  for (final line in windowLines) {
    if (line.trim().isEmpty || line.startsWith('--------- beginning of ')) {
      continue;
    }
    final identity = _androidLogcatIdentity(line);
    if (identity == null || identity.uid != uid) {
      throw UiRuntimeEvidenceException(
        'Android native log line is not attributable to the expected UID/PID: '
        '$line',
      );
    }
    loggedPids.add(identity.pid);
  }
  if (loggedPids.isEmpty) {
    throw const UiRuntimeEvidenceException(
      'Android native log window has no attributable UID process.',
    );
  }
  for (final line in lines.skip(endIndexes.single + 1)) {
    if (_androidLogcatIdentity(line) != null) {
      throw const UiRuntimeEvidenceException(
        'Android native log contains an app UID event after END.',
      );
    }
  }
  return _AndroidEgressWindow(
    text: '${windowLines.join('\n')}\n',
    loggedPids: Set<int>.unmodifiable(loggedPids),
  );
}

_AndroidLogcatIdentity? _androidLogcatIdentity(String line) {
  final epochUid = RegExp(
    r'^\s*\d+(?:\.\d+)?\s+(\d+)\s+(\d+)\s+\d+\s+[VDIWEFAS]\s+',
  ).firstMatch(line);
  if (epochUid != null) {
    final uid = int.tryParse(epochUid.group(1)!);
    final pid = int.tryParse(epochUid.group(2)!);
    if (uid != null && pid != null) {
      return _AndroidLogcatIdentity(uid: uid, pid: pid);
    }
  }
  final threadtimeUid = RegExp(
    r'^\s*\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d+\s+(\d+)\s+'
    r'(\d+)\s+\d+\s+[VDIWEFAS]\s+',
  ).firstMatch(line);
  if (threadtimeUid == null) return null;
  final uid = int.tryParse(threadtimeUid.group(1)!);
  final pid = int.tryParse(threadtimeUid.group(2)!);
  return uid == null || pid == null
      ? null
      : _AndroidLogcatIdentity(uid: uid, pid: pid);
}

_AndroidPidTraceAssessment _parseAndroidPidTrace(
  String trace, {
  required int expectedUid,
  required String expectedRunId,
}) {
  final sampledPids = <int>{};
  var samplesBeforeLaunch = 0;
  var samplesDuringJourney = 0;
  var drainSamples = 0;
  var drainAfterEndSamples = 0;
  var consecutiveZeroBeforeEnd = 0;
  var consecutiveZeroAfterEnd = 0;
  var samplerFailures = 0;
  var preLaunchClean = true;
  for (final line in const LineSplitter().convert(trace)) {
    if (line.trim().isEmpty) continue;
    final fields = line.split('\t');
    if (fields.length != 7 ||
        !const {'sample', 'empty', 'error'}.contains(fields[0])) {
      throw const UiRuntimeEvidenceException(
        'Android PID trace contains a malformed row.',
      );
    }
    final phase = fields[1];
    final timestamp = int.tryParse(fields[2]);
    final uid = int.tryParse(fields[3]);
    final pid = int.tryParse(fields[4]);
    if (timestamp == null ||
        timestamp <= 0 ||
        uid != expectedUid ||
        pid == null ||
        fields[6] != expectedRunId) {
      throw const UiRuntimeEvidenceException(
        'Android PID trace identity is malformed or cross-run.',
      );
    }
    if (phase == 'pre_launch') {
      samplesBeforeLaunch++;
      if (fields[0] != 'empty') preLaunchClean = false;
    }
    if (phase == 'continuous') samplesDuringJourney++;
    if (phase.startsWith('drain')) drainSamples++;
    if (phase == 'drain_after_end') drainAfterEndSamples++;
    if (fields[0] == 'error') {
      samplerFailures++;
      continue;
    }
    if (fields[0] == 'sample') {
      if (pid <= 0 || fields[5].trim().isEmpty || fields[5] == '-') {
        throw const UiRuntimeEvidenceException(
          'Android PID trace sample is incomplete.',
        );
      }
      sampledPids.add(pid);
      if (phase == 'drain_before_end') consecutiveZeroBeforeEnd = 0;
      if (phase == 'drain_after_end') consecutiveZeroAfterEnd = 0;
    } else if (pid != 0) {
      throw const UiRuntimeEvidenceException(
        'Android PID trace empty row has a PID.',
      );
    } else {
      if (phase == 'drain_before_end') consecutiveZeroBeforeEnd++;
      if (phase == 'drain_after_end') consecutiveZeroAfterEnd++;
    }
  }
  if (samplerFailures != 0 ||
      samplesBeforeLaunch < 1 ||
      samplesDuringJourney < 1 ||
      drainSamples < 6 ||
      drainAfterEndSamples < 3 ||
      consecutiveZeroBeforeEnd < 3 ||
      consecutiveZeroAfterEnd < 3 ||
      !preLaunchClean ||
      sampledPids.isEmpty) {
    throw const UiRuntimeEvidenceException(
      'Android PID trace does not cover pre-launch, journey and final drain.',
    );
  }
  return _AndroidPidTraceAssessment(
    sampledPids: Set<int>.unmodifiable(sampledPids),
    samplesBeforeLaunch: samplesBeforeLaunch,
    samplesDuringJourney: samplesDuringJourney,
    drainSamples: drainSamples,
    drainAfterEndSamples: drainAfterEndSamples,
    consecutiveZeroBeforeEnd: consecutiveZeroBeforeEnd,
    consecutiveZeroAfterEnd: consecutiveZeroAfterEnd,
    samplerFailures: samplerFailures,
  );
}

Map<String, dynamic> _validateAndroidEgressReceiptEnvelope({
  required File receiptFile,
  required File runtimeLog,
  required File nativeLog,
  required File pidTrace,
  required File policyFile,
  required String expectedRunId,
  required String expectedSourceDigest,
  required String expectedProfile,
  required String expectedTarget,
  required bool requireTerminal,
}) {
  _expectSha256(expectedSourceDigest, 'expected Android egress source digest');
  for (final entry in <String, File>{
    'receipt': receiptFile,
    'runtime log': runtimeLog,
    'native log': nativeLog,
    'PID trace': pidTrace,
    'policy': policyFile,
  }.entries) {
    if (!entry.value.existsSync() ||
        FileSystemEntity.typeSync(entry.value.path, followLinks: false) !=
            FileSystemEntityType.file) {
      throw UiRuntimeEvidenceException(
        'Android egress ${entry.key} is missing, non-regular or a symlink.',
      );
    }
  }

  final receipt = _readJsonObject(receiptFile, 'Android egress receipt');
  final policy = _readJsonObject(policyFile, 'UI live evidence policy');
  final contract = _objectOrEmpty(policy['android_physical_egress']);
  final expectedSchema = contract['receipt_schema']?.toString() ?? '';
  final expectedPackage = contract['package']?.toString() ?? '';
  if (expectedSchema != 'manaloom.android_ui_egress_receipt.v2' ||
      expectedPackage.isEmpty) {
    throw const UiRuntimeEvidenceException(
      'UI policy does not define the governed Android egress v2 contract.',
    );
  }
  if (receipt['schema_version'] != expectedSchema ||
      receipt['run_id'] != expectedRunId ||
      receipt['source_digest'] != expectedSourceDigest ||
      receipt['profile'] != expectedProfile ||
      receipt['target'] != expectedTarget) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt identity is stale or cross-run.',
    );
  }
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{7,127}$').hasMatch(expectedRunId)) {
    throw const UiRuntimeEvidenceException('Android egress run ID is invalid.');
  }
  if (requireTerminal && receipt['status'] != 'PASS_ANDROID_EGRESS') {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt is not terminal PASS.',
    );
  }
  if (!requireTerminal && receipt['status'] != 'PENDING_DERIVED_ASSESSMENT') {
    throw const UiRuntimeEvidenceException(
      'Android egress candidate receipt has an invalid status.',
    );
  }

  final runRootValue = receipt['run_root']?.toString() ?? '';
  if (!File(runRootValue).isAbsolute) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt run_root must be absolute.',
    );
  }
  final runRoot = Directory(runRootValue);
  if (!runRoot.existsSync() ||
      FileSystemEntity.typeSync(runRoot.path, followLinks: false) !=
          FileSystemEntityType.directory) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt run_root is missing or unsafe.',
    );
  }
  final resolvedRoot = runRoot.resolveSymbolicLinksSync();
  final artifacts = _objectOrEmpty(receipt['artifacts']);
  final stateFiles = <String, File>{
    'state_before_path': File(artifacts['state_before_path']?.toString() ?? ''),
    'state_isolated_path': File(
      artifacts['state_isolated_path']?.toString() ?? '',
    ),
    'state_after_path': File(artifacts['state_after_path']?.toString() ?? ''),
  };
  for (final file in [
    receiptFile,
    runtimeLog,
    nativeLog,
    pidTrace,
    ...stateFiles.values,
  ]) {
    if (!file.isAbsolute ||
        !file.existsSync() ||
        FileSystemEntity.typeSync(file.path, followLinks: false) !=
            FileSystemEntityType.file) {
      throw const UiRuntimeEvidenceException(
        'Android egress artifact is missing or unsafe.',
      );
    }
    final resolved = file.resolveSymbolicLinksSync();
    if (resolved != resolvedRoot &&
        !resolved.startsWith('$resolvedRoot${Platform.pathSeparator}')) {
      throw const UiRuntimeEvidenceException(
        'Android egress artifact escapes its canonical run root.',
      );
    }
  }
  if (artifacts['native_log_path'] != nativeLog.absolute.path ||
      artifacts['pid_trace_path'] != pidTrace.absolute.path) {
    throw const UiRuntimeEvidenceException(
      'Android egress log or PID trace path is cross-run.',
    );
  }

  final identity = _objectOrEmpty(receipt['identity']);
  final uid = identity['uid'];
  final sampledPids = _integerList(identity['sampled_pids']);
  if (identity['package'] != expectedPackage ||
      (identity['serial']?.toString().isEmpty ?? true) ||
      (identity['model']?.toString().isEmpty ?? true) ||
      (identity['api'] is! int) ||
      (uid is! int) ||
      uid <= 0 ||
      sampledPids.isEmpty ||
      sampledPids.any((pid) => pid <= 0) ||
      sampledPids.toSet().length != sampledPids.length) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt package/UID/PID/device identity is invalid.',
    );
  }
  final window = _extractAndroidEgressWindow(
    nativeLog.readAsStringSync(),
    runId: expectedRunId,
    uid: uid,
  );
  final pidAssessment = _parseAndroidPidTrace(
    pidTrace.readAsStringSync(),
    expectedUid: uid,
    expectedRunId: expectedRunId,
  );
  if (!_sameIntSet(sampledPids.toSet(), pidAssessment.sampledPids)) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt sampled PID set is not derived from the trace.',
    );
  }
  final derivedObserved = <int>{
    ...pidAssessment.sampledPids,
    ...window.loggedPids,
  };
  final loggedPidList = _integerList(identity['logged_pids']);
  final observedPidList = _integerList(identity['observed_pids']);
  final loggedPids = loggedPidList.toSet();
  final observedPids = observedPidList.toSet();
  if (requireTerminal) {
    if (loggedPidList.length != loggedPids.length ||
        observedPidList.length != observedPids.length ||
        !_sameIntSet(loggedPids, window.loggedPids) ||
        !_sameIntSet(observedPids, derivedObserved)) {
      throw const UiRuntimeEvidenceException(
        'Android egress terminal PID coverage is not derived from raw artifacts.',
      );
    }
  } else if (loggedPids.isNotEmpty || observedPids.isNotEmpty) {
    throw const UiRuntimeEvidenceException(
      'Android egress candidate must not predeclare derived PID coverage.',
    );
  }

  final detector = _objectOrEmpty(receipt['detector']);
  final appData = _objectOrEmpty(receipt['app_data']);
  final network = _objectOrEmpty(receipt['network']);
  final presentation = _objectOrEmpty(receipt['presentation']);
  final cleanup = _objectOrEmpty(receipt['cleanup']);
  final requiredTrue = <Object?>[
    detector['logcat_started_before_begin'],
    detector['begin_before_child'],
    detector['end_after_force_stop_and_drain'],
    detector['sampler_started_before_launch'],
    detector['all_uid_pids_enumerated'],
    appData['pre_launch_clean'],
    appData['post_run_clean'],
    appData['datatransport_store_absent'],
    network['snapshot_complete'],
    network['isolation_confirmed'],
    network['adb_usb_preserved'],
    network['reverse_loopback_only'],
    network['restored_exactly'],
    presentation['snapshot_complete'],
    presentation['rotation_and_immersive_restored_exactly'],
    cleanup['state_dir_absent'],
  ];
  if (requiredTrue.any((value) => value != true) ||
      detector['temporal_anchor'] != '-T 1' ||
      detector['log_format'] != 'epoch_uid' ||
      detector['begin_marker_count'] != 1 ||
      detector['end_marker_count'] != 1 ||
      detector['sampler_failures'] != pidAssessment.samplerFailures ||
      detector['samples_before_launch'] != pidAssessment.samplesBeforeLaunch ||
      detector['samples_during_journey'] !=
          pidAssessment.samplesDuringJourney ||
      detector['drain_samples'] != pidAssessment.drainSamples ||
      detector['consecutive_zero_samples_before_end'] !=
          pidAssessment.consecutiveZeroBeforeEnd ||
      detector['consecutive_zero_samples_after_end'] !=
          pidAssessment.consecutiveZeroAfterEnd ||
      cleanup['app_processes'] != 0 ||
      cleanup['sampler_processes'] != 0 ||
      cleanup['logcat_processes'] != 0 ||
      cleanup['external_routes'] != 0 ||
      cleanup['restore_failures'] != 0 ||
      cleanup['guard_processes'] != 0) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt does not prove detector coverage and cleanup.',
    );
  }

  final stateHashes = <String, String>{
    for (final entry in stateFiles.entries)
      entry.key: sha256.convert(entry.value.readAsBytesSync()).toString(),
  };
  if (presentation['before_sha256'] != stateHashes['state_before_path'] ||
      presentation['isolated_sha256'] != stateHashes['state_isolated_path'] ||
      presentation['restored_sha256'] != stateHashes['state_after_path'] ||
      stateHashes['state_before_path'] != stateHashes['state_after_path']) {
    throw const UiRuntimeEvidenceException(
      'Android presentation/network state was not restored byte-exactly.',
    );
  }
  _validateAndroidStateArtifacts(
    beforeFile: stateFiles['state_before_path']!,
    isolatedFile: stateFiles['state_isolated_path']!,
    afterFile: stateFiles['state_after_path']!,
    identity: identity,
    receiptNetwork: network,
  );

  if (requireTerminal) {
    final expectedHashes = <String, String>{
      'runtime_log_sha256': sha256
          .convert(runtimeLog.readAsBytesSync())
          .toString(),
      'native_log_sha256': sha256
          .convert(nativeLog.readAsBytesSync())
          .toString(),
      'native_window_sha256': sha256
          .convert(utf8.encode(window.text))
          .toString(),
      'pid_trace_sha256': sha256.convert(pidTrace.readAsBytesSync()).toString(),
      'policy_sha256': sha256.convert(policyFile.readAsBytesSync()).toString(),
    };
    for (final entry in expectedHashes.entries) {
      if (artifacts[entry.key] != entry.value) {
        throw UiRuntimeEvidenceException(
          'Android egress receipt ${entry.key} hash is stale.',
        );
      }
    }
  }
  return receipt;
}

void _validateAndroidStateArtifacts({
  required File beforeFile,
  required File isolatedFile,
  required File afterFile,
  required Map<String, dynamic> identity,
  required Map<String, dynamic> receiptNetwork,
}) {
  final before = _readJsonObject(beforeFile, 'Android state before');
  final isolated = _readJsonObject(isolatedFile, 'Android state isolated');
  final after = _readJsonObject(afterFile, 'Android state after');
  final beforeNetwork = _objectOrEmpty(before['network']);
  final isolatedNetwork = _objectOrEmpty(isolated['network']);
  final afterNetwork = _objectOrEmpty(after['network']);
  final isolatedPresentation = _objectOrEmpty(isolated['presentation']);
  final serial = identity['serial']?.toString() ?? '';
  final apiPort = receiptNetwork['api_port'];
  final webPort = receiptNetwork['web_port'];
  if (serial.isEmpty ||
      apiPort is! int ||
      webPort is! int ||
      apiPort <= 0 ||
      apiPort >= 65536 ||
      webPort <= 0 ||
      webPort >= 65536 ||
      apiPort == webPort) {
    throw const UiRuntimeEvidenceException(
      'Android isolation receipt ports or serial are invalid.',
    );
  }

  for (final entry in <String, Map<String, dynamic>>{
    'before': beforeNetwork,
    'isolated': isolatedNetwork,
    'after': afterNetwork,
  }.entries) {
    _validateAndroidStateInventoryHashes(entry.value, entry.key);
  }
  if (beforeFile.readAsBytesSync().toString() !=
      afterFile.readAsBytesSync().toString()) {
    throw const UiRuntimeEvidenceException(
      'Android before/after state artifacts differ.',
    );
  }
  if (_stringList(
        beforeNetwork['adb_reverse'],
        'before adb_reverse',
      ).isNotEmpty ||
      _stringList(
        afterNetwork['adb_reverse'],
        'after adb_reverse',
      ).isNotEmpty ||
      isolatedNetwork['wifi_on'] != '0' ||
      isolatedNetwork['mobile_data'] != '0' ||
      isolatedNetwork['airplane_mode_on'] !=
          beforeNetwork['airplane_mode_on']) {
    throw const UiRuntimeEvidenceException(
      'Android isolated network state is not canonical.',
    );
  }

  final expectedReverse = <String>[
    '$serial tcp:$apiPort tcp:$apiPort',
    '$serial tcp:$webPort tcp:$webPort',
  ]..sort();
  final actualReverse = _stringList(
    isolatedNetwork['adb_reverse'],
    'isolated adb_reverse',
  );
  if (!_sameStringList(actualReverse, expectedReverse)) {
    throw const UiRuntimeEvidenceException(
      'Android isolated ADB reverse mappings are not the exact loopback set.',
    );
  }
  for (final key in const ['routes4', 'routes6']) {
    final routes = _stringList(isolatedNetwork[key], 'isolated $key');
    if (routes.any((route) => RegExp(r'(^|\s)default(\s|$)').hasMatch(route))) {
      throw const UiRuntimeEvidenceException(
        'Android isolated state still contains an external default route.',
      );
    }
  }
  const isolatedConnectivity = <String>[
    'cellular_connected=0',
    'vpn_connected=0',
    'wifi_connected=0',
  ];
  if (!_sameStringList(isolatedNetwork['connectivity'], isolatedConnectivity) ||
      !_androidConnectivitySnapshotIsCanonical(beforeNetwork['connectivity']) ||
      !_androidConnectivitySnapshotIsCanonical(afterNetwork['connectivity'])) {
    throw const UiRuntimeEvidenceException(
      'Android connectivity snapshot is incomplete or not isolated.',
    );
  }

  final accel = _objectOrEmpty(isolatedPresentation['accelerometer_rotation']);
  final user = _objectOrEmpty(isolatedPresentation['user_rotation']);
  final immersive = _objectOrEmpty(
    isolatedPresentation['immersive_mode_confirmations'],
  );
  if (accel['present'] != true ||
      accel['value'] != '0' ||
      user['present'] != true ||
      user['value'] != '0' ||
      immersive['present'] != true ||
      immersive['value'] != 'confirmed') {
    throw const UiRuntimeEvidenceException(
      'Android isolated rotation or immersive state is not canonical.',
    );
  }
}

void _validateAndroidStateInventoryHashes(
  Map<String, dynamic> network,
  String label,
) {
  for (final key in const [
    'adb_reverse',
    'routes4',
    'routes6',
    'connectivity',
  ]) {
    final lines = _stringList(network[key], '$label $key');
    final bytes = utf8.encode(lines.isEmpty ? '' : '${lines.join('\n')}\n');
    final expected = sha256.convert(bytes).toString();
    if (network['${key == 'adb_reverse' ? 'reverse' : key}_sha256'] !=
        expected) {
      throw UiRuntimeEvidenceException(
        'Android $label $key inventory hash is inconsistent.',
      );
    }
  }
}

bool _androidConnectivitySnapshotIsCanonical(Object? value) {
  if (value is! List || value.any((entry) => entry is! String)) return false;
  final lines = value.cast<String>();
  if (lines.length != 3 ||
      !lines[0].startsWith('cellular_connected=') ||
      !lines[1].startsWith('vpn_connected=') ||
      !lines[2].startsWith('wifi_connected=')) {
    return false;
  }
  if (lines.any((line) => !RegExp(r'^[a-z_]+=[01]$').hasMatch(line))) {
    return false;
  }
  return lines[1] == 'vpn_connected=0';
}

Set<String> _androidLoopbackHosts(File policyFile) {
  final policy = _readJsonObject(policyFile, 'UI live evidence policy');
  final contract = _objectOrEmpty(policy['android_physical_egress']);
  final hosts = _stringList(
    contract['allowed_loopback_hosts'],
    'android_physical_egress.allowed_loopback_hosts',
  ).map((host) => host.toLowerCase()).toSet();
  if (!_sameSet(hosts, const {'127.0.0.1', 'localhost', '::1'})) {
    throw const UiRuntimeEvidenceException(
      'Android egress loopback policy is not the canonical exact set.',
    );
  }
  return hosts;
}

List<int> _integerList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<int>().toList(growable: false);
}

bool _sameStringList(Object? value, List<String> expected) {
  if (value is! List || value.any((entry) => entry is! String)) return false;
  final actual = value.cast<String>();
  return actual.length == expected.length &&
      List<int>.generate(
        actual.length,
        (index) => index,
      ).every((index) => actual[index] == expected[index]);
}

void _writeJsonAtomically(File file, Object value) {
  file.parent.createSync(recursive: true);
  final temporary = File('${file.path}.tmp.$pid');
  if (temporary.existsSync() ||
      FileSystemEntity.typeSync(temporary.path, followLinks: false) ==
          FileSystemEntityType.link) {
    throw const UiRuntimeEvidenceException(
      'Android egress receipt temporary path already exists.',
    );
  }
  final encoded = const JsonEncoder.withIndent('  ').convert(value);
  temporary.writeAsStringSync('$encoded\n', flush: true);
  temporary.renameSync(file.path);
}

Map<String, dynamic> _readJsonObject(File file, String label) {
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw UiRuntimeEvidenceException('$label is not a JSON object.');
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  } on FormatException catch (error) {
    throw UiRuntimeEvidenceException('$label is invalid JSON: $error');
  }
}

Map<String, dynamic> _objectOrEmpty(Object? value) {
  if (value is! Map) return <String, dynamic>{};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Map<String, dynamic>> _objectListOrEmpty(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => entry.map((key, item) => MapEntry(key.toString(), item)))
      .toList(growable: false);
}

List<String> _stringList(Object? value, String label) {
  final result = _stringListOrEmpty(value);
  if (value is! List || result.length != value.length) {
    throw UiRuntimeEvidenceException('$label must be a string list.');
  }
  return result;
}

List<String> _stringListOrEmpty(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

String _requiredText(Map<String, dynamic> source, String key) {
  final value = source[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw UiRuntimeEvidenceException('Runtime context is missing $key.');
  }
  return value;
}

String _safeRelativePath(String value) {
  final normalized = value.trim().replaceAll(r'\', '/');
  final segments = normalized.split('/');
  if (normalized.isEmpty ||
      normalized.startsWith('/') ||
      segments.any((segment) => segment.isEmpty || segment == '..')) {
    throw UiRuntimeEvidenceException('Unsafe relative evidence path: $value');
  }
  return normalized;
}

void _expectCheckpointName(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9_-]{2,80}$').hasMatch(value)) {
    throw UiRuntimeEvidenceException('Unsafe screenshot checkpoint: $value');
  }
}

void _expectSha256(String value, String label) {
  if (!_isSha256(value)) {
    throw UiRuntimeEvidenceException('$label must be 64 lowercase hex chars.');
  }
}

bool _isSha256(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameIntSet(Set<int> left, Set<int> right) =>
    left.length == right.length && left.containsAll(right);

bool _hasIsoTimestamp(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed != null && value.toString().contains('T');
}

void _writeJson(File file, Object value) {
  final encoded = const JsonEncoder.withIndent('  ').convert(value);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('$encoded\n', flush: true);
}

Never _usage([String? message]) {
  if (message != null) stderr.writeln(message);
  stderr.writeln(
    'Usage:\n'
    '  dart run tool/ui_runtime_evidence.dart extract '
    '--repo-root <dir> --log <file> --output <relative-dir> '
    '--source-digest <sha256> [--replace]\n'
    '  dart run tool/ui_runtime_evidence.dart index-directory '
    '--repo-root <dir> --screenshots <relative-dir> --log <file> '
    '--manifest <relative-json> --source-digest <sha256> '
    '--surface <id> --profile <id> --runtime <id> --target <id> '
    '--device-contract <text> [--android-egress-receipt <json> '
    '--android-egress-run-id <id>]\n'
    '  dart run tool/ui_runtime_evidence.dart seal-android-egress-receipt '
    '--receipt <json> --runtime-log <file> --native-log <file> '
    '--pid-trace <tsv> '
    '--policy <json> --run-id <id> --source-digest <sha256> '
    '--profile <id> --target android_physical\n'
    '  dart run tool/ui_runtime_evidence.dart verify-android-egress-receipt '
    '--receipt <json> --runtime-log <file> --policy <json> '
    '--run-id <id> --source-digest <sha256> --profile <id> '
    '--target android_physical\n'
    '  dart run tool/ui_runtime_evidence.dart validate-directory '
    '--screenshots <directory>\n'
    '  dart run tool/ui_runtime_evidence.dart verify '
    '--repo-root <dir> --review <file> --source-digest <sha256>',
  );
  exit(2);
}

void main(List<String> args) {
  if (args.isEmpty) _usage();
  final command = args.first;
  final values = <String, String>{};
  var replace = false;
  for (var index = 1; index < args.length; index++) {
    final name = args[index];
    if (name == '--replace') {
      replace = true;
      continue;
    }
    if (!name.startsWith('--') || index + 1 >= args.length) {
      _usage('Invalid argument: $name');
    }
    values[name] = args[++index];
  }

  if (command == 'validate-directory') {
    final screenshotPath = values['--screenshots'];
    if (screenshotPath == null || screenshotPath.trim().isEmpty) {
      _usage('validate-directory is missing --screenshots');
    }
    try {
      final count = validateRuntimeScreenshotDirectory(
        Directory(screenshotPath),
      );
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(<String, Object>{
          'status': 'PASS_RUNTIME_SCREENSHOTS',
          'screenshot_count': count,
        }),
      );
    } on Object catch (error) {
      stderr.writeln(error);
      exitCode = 1;
    }
    return;
  }

  if (command == 'seal-android-egress-receipt' ||
      command == 'verify-android-egress-receipt') {
    final receiptPath = values['--receipt'];
    final runtimeLogPath = values['--runtime-log'];
    final nativeLogPath = values['--native-log'];
    final pidTracePath = values['--pid-trace'];
    final policyPath = values['--policy'];
    final runId = values['--run-id'];
    final sourceDigest = values['--source-digest'];
    final profile = values['--profile'];
    final target = values['--target'];
    if (<String?>[
          receiptPath,
          runtimeLogPath,
          policyPath,
          runId,
          sourceDigest,
          profile,
          target,
        ].any((value) => value == null || value.trim().isEmpty) ||
        (command == 'seal-android-egress-receipt' &&
            (nativeLogPath == null ||
                nativeLogPath.trim().isEmpty ||
                pidTracePath == null ||
                pidTracePath.trim().isEmpty))) {
      _usage('$command is missing a required argument');
    }
    try {
      final result = command == 'seal-android-egress-receipt'
          ? sealAndroidEgressReceipt(
              receiptFile: File(receiptPath!),
              runtimeLog: File(runtimeLogPath!),
              nativeLog: File(nativeLogPath!),
              pidTrace: File(pidTracePath!),
              policyFile: File(policyPath!),
              expectedRunId: runId!,
              expectedSourceDigest: sourceDigest!,
              expectedProfile: profile!,
              expectedTarget: target!,
            )
          : verifyAndroidEgressReceipt(
              receiptFile: File(receiptPath!),
              runtimeLog: File(runtimeLogPath!),
              policyFile: File(policyPath!),
              expectedRunId: runId!,
              expectedSourceDigest: sourceDigest!,
              expectedProfile: profile!,
              expectedTarget: target!,
            );
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(<String, Object>{
          'status': 'PASS_ANDROID_EGRESS',
          'receipt_sha256': result.receiptSha256,
          'run_id': result.receipt['run_id']!.toString(),
        }),
      );
    } on Object catch (error) {
      stderr.writeln(error);
      exitCode = 1;
    }
    return;
  }

  final repoRootPath = values['--repo-root'];
  final sourceDigest = values['--source-digest'];
  if (repoRootPath == null || sourceDigest == null) _usage();
  final repoRoot = Directory(repoRootPath);

  try {
    if (command == 'extract') {
      final logPath = values['--log'];
      final output = values['--output'];
      if (logPath == null || output == null) _usage();
      final result = extractUiRuntimeEvidence(
        logFile: File(logPath),
        repoRoot: repoRoot,
        outputRelativePath: output,
        expectedSourceDigest: sourceDigest,
        replace: replace,
      );
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(<String, Object>{
          'status': 'PASS_RUNTIME',
          'capture_manifest': result.manifestFile.path,
          'next_required_level': 'PASS_VISUAL_REVIEWED',
        }),
      );
      return;
    }
    if (command == 'index-directory') {
      final screenshotPath = values['--screenshots'];
      final logPath = values['--log'];
      final manifestPath = values['--manifest'];
      final surface = values['--surface'];
      final profile = values['--profile'];
      final runtime = values['--runtime'];
      final target = values['--target'];
      final deviceContract = values['--device-contract'];
      final androidEgressReceipt = values['--android-egress-receipt'];
      final androidEgressRunId = values['--android-egress-run-id'];
      if (<String?>[
        screenshotPath,
        logPath,
        manifestPath,
        surface,
        profile,
        runtime,
        target,
        deviceContract,
      ].any((value) => value == null || value.trim().isEmpty)) {
        _usage('index-directory is missing a required argument');
      }
      final safeScreenshotPath = _safeRelativePath(screenshotPath!);
      final result = indexUiRuntimeScreenshotDirectory(
        screenshotDirectory: Directory(
          '${repoRoot.absolute.path}/$safeScreenshotPath',
        ),
        runtimeLog: File(logPath!),
        repoRoot: repoRoot,
        manifestRelativePath: manifestPath!,
        expectedSourceDigest: sourceDigest,
        surface: surface!,
        profile: profile!,
        runtime: runtime!,
        target: target!,
        deviceContract: deviceContract!,
        androidEgressReceipt: androidEgressReceipt == null
            ? null
            : File(androidEgressReceipt),
        androidEgressRunId: androidEgressRunId,
      );
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(<String, Object>{
          'status': 'PASS_RUNTIME',
          'capture_manifest': result.manifestFile.path,
          'checkpoint_count': result.manifest['checkpoint_count']!,
          'next_required_level': 'PASS_VISUAL_REVIEWED',
        }),
      );
      return;
    }
    if (command == 'verify') {
      final reviewPath = values['--review'];
      if (reviewPath == null) _usage();
      final result = verifyUiLiveEvidence(
        reviewFile: File(reviewPath),
        repoRoot: repoRoot,
        expectedSourceDigest: sourceDigest,
      );
      stdout.writeln(
        const JsonEncoder.withIndent('  ').convert(result.toJson()),
      );
      return;
    }
    _usage('Unknown command: $command');
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
