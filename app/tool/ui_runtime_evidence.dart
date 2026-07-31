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
  _expectCleanRuntimeLog(log);
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
    'runtime_console': const <String, Object>{
      'status': 'pass',
      'forbidden_entries': 0,
    },
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
  _expectCleanRuntimeLog(log);
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
    'runtime_console': const <String, Object>{
      'status': 'pass',
      'forbidden_entries': 0,
    },
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
  required Set<String> captureTargets,
  required void Function(bool condition, String message) expect,
}) {
  final policy = _readJsonObject(policyFile, 'live UI evidence policy');
  expect(
    policy['schema_version'] == 'manaloom_ui_live_evidence_policy_v1',
    'unsupported live UI evidence policy schema',
  );
  final surfaces = _objectListOrEmpty(policy['surfaces']);
  final p0Surface = surfaces.cast<Map<String, dynamic>?>().firstWhere(
    (surface) => surface?['id'] == 'authenticated_p0_matrix',
    orElse: () => null,
  );
  expect(
    p0Surface != null,
    'live UI evidence policy has no authenticated P0 surface',
  );
  if (p0Surface != null) {
    final requiredProfiles = _objectOrEmpty(p0Surface['required_profiles']);
    for (final entry in requiredProfiles.entries) {
      final requiredCount = switch (entry.value) {
        int count => count,
        num count => count.toInt(),
        String value => int.tryParse(value.trim()),
        _ => null,
      };
      expect(
        requiredCount != null && requiredCount > 0,
        'policy profile ${entry.key} has an invalid checkpoint count',
      );
      expect(
        captureCountsByProfile[entry.key] == requiredCount,
        'runtime profile ${entry.key} must contain exactly '
        '$requiredCount screenshots',
      );
    }

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

void _expectCleanRuntimeLog(String log) {
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
    '--device-contract <text>\n'
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
