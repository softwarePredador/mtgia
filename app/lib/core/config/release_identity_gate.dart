import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import 'release_capabilities.dart';

/// The release identity compiled into this artifact (BT-REL-002, D-13).
///
/// The release scripts pass the capability matrix of the promoted SHA by
/// dart-define. The comparison uses only what is compiled: on the Web a
/// cached `main.dart.js` could read a newer `release-identity.json` asset and
/// believe it is current, so the asset is never trusted here.
@immutable
class CompiledReleaseIdentity {
  const CompiledReleaseIdentity._({
    required this.kind,
    required this.gitSha,
    required this.surface,
    required this.capabilitiesDigest,
    required this.allowedCapabilities,
  });

  /// Reads the four dart-defines. Every other parse goes through [parse].
  factory CompiledReleaseIdentity.fromEnvironment() => parse(
    gitSha: const String.fromEnvironment('RELEASE_GIT_SHA'),
    surface: const String.fromEnvironment('RELEASE_SURFACE'),
    capabilitiesDigest: const String.fromEnvironment(
      'RELEASE_CAPABILITIES_DIGEST',
    ),
    allowedCapabilities: const String.fromEnvironment(
      'RELEASE_CAPABILITIES_ALLOWED',
    ),
  );

  /// No digest and no list is a development build, which trusts the backend
  /// as before. A digest or a list outside the contract is invalid and denies
  /// every capability.
  static CompiledReleaseIdentity parse({
    required String gitSha,
    required String surface,
    required String capabilitiesDigest,
    required String allowedCapabilities,
  }) {
    final digest = capabilitiesDigest.trim();
    final allowedRaw = allowedCapabilities.trim();
    if (digest.isEmpty && allowedRaw.isEmpty) {
      return CompiledReleaseIdentity._(
        kind: CompiledReleaseIdentityKind.development,
        gitSha: gitSha.trim(),
        surface: surface.trim(),
        capabilitiesDigest: '',
        allowedCapabilities: const {},
      );
    }

    final known = {
      for (final capability in ReleaseCapability.values)
        capability.wireName: capability,
    };
    final allowed = <ReleaseCapability>{};
    var valid =
        _sha256Pattern.hasMatch(digest) &&
        _gitShaPattern.hasMatch(gitSha.trim()) &&
        _surfaces.contains(surface.trim());
    if (allowedRaw.isNotEmpty) {
      for (final name in allowedRaw.split(',')) {
        final capability = known[name.trim()];
        if (capability == null || !allowed.add(capability)) valid = false;
      }
    }
    return CompiledReleaseIdentity._(
      kind: valid
          ? CompiledReleaseIdentityKind.release
          : CompiledReleaseIdentityKind.invalid,
      gitSha: gitSha.trim(),
      surface: surface.trim(),
      capabilitiesDigest: digest,
      allowedCapabilities: Set.unmodifiable(valid ? allowed : const {}),
    );
  }

  static final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
  static final _gitShaPattern = RegExp(r'^[0-9a-f]{40}$');
  static const _surfaces = {'app', 'android'};

  final CompiledReleaseIdentityKind kind;
  final String gitSha;
  final String surface;
  final String capabilitiesDigest;
  final Set<ReleaseCapability> allowedCapabilities;
}

enum CompiledReleaseIdentityKind { development, release, invalid }

/// Applies the D-13 rule to every `/capabilities` response before the
/// [ReleaseCapabilitiesProvider] parses it.
///
/// - A capability stays allowed only if the backend allows it and this
///   artifact allowed it at build time, so a newer backend never turns on
///   code this build did not ship.
/// - Capabilities this code does not know are dropped.
/// - Known capabilities the backend omitted are denied.
/// - A digest different from the compiled one, or an unknown capability
///   offered as allowed, raises [updateAvailable].
class ReleaseIdentityGate {
  ReleaseIdentityGate({CompiledReleaseIdentity? identity, ApiClient? apiClient})
    : identity = identity ?? CompiledReleaseIdentity.fromEnvironment(),
      _apiClient = apiClient ?? ApiClient();

  final CompiledReleaseIdentity identity;
  final ApiClient _apiClient;

  /// True when the backend runs a different release than this artifact.
  final ValueNotifier<bool> updateAvailable = ValueNotifier(false);

  /// The [ReleaseCapabilitiesFetcher] for the provider.
  Future<ApiResponse> fetch(String endpoint) async =>
      apply(await _apiClient.get(endpoint));

  ApiResponse apply(ApiResponse response) {
    if (identity.kind == CompiledReleaseIdentityKind.development ||
        response.statusCode != 200) {
      return response;
    }
    if (identity.kind == CompiledReleaseIdentityKind.invalid) {
      // An artifact with a broken identity cannot prove what it shipped.
      return ApiResponse(
        503,
        const {'error': 'release_identity_invalid'},
        durationMs: response.durationMs,
        requestId: response.requestId,
        responseRequestId: response.responseRequestId,
      );
    }

    final body = response.data;
    if (body is! Map || body['capabilities'] is! Map) return response;
    final backendCapabilities = body['capabilities'] as Map;

    var newRelease =
        body['policy_digest_sha256']?.toString().trim() !=
        identity.capabilitiesDigest;
    final known = {
      for (final capability in ReleaseCapability.values) capability.wireName,
    };
    for (final entry in backendCapabilities.entries) {
      if (known.contains(entry.key)) continue;
      final value = entry.value;
      if (value is Map && value['allowed'] == true) newRelease = true;
    }

    final gated = <String, Object?>{
      for (final capability in ReleaseCapability.values)
        capability.wireName: _gateEntry(
          backendCapabilities[capability.wireName],
          compiledAllows: identity.allowedCapabilities.contains(capability),
        ),
    };
    updateAvailable.value = newRelease;
    return ApiResponse(
      response.statusCode,
      {...body.cast<String, Object?>(), 'capabilities': gated},
      durationMs: response.durationMs,
      requestId: response.requestId,
      responseRequestId: response.responseRequestId,
    );
  }

  static Object? _gateEntry(Object? entry, {required bool compiledAllows}) {
    if (entry == null) return _deniedEntry;
    if (entry is! Map) return entry;
    if (compiledAllows || entry['allowed'] != true) return entry;
    return {
      ...entry.cast<String, Object?>(),
      'release_capability': 'off',
      'allowed': false,
    };
  }

  static const _deniedEntry = <String, Object?>{
    'implementation_status': 'not_implemented',
    'release_capability': 'off',
    'allowed': false,
    'live_verified_as_of': null,
  };

  void dispose() => updateAvailable.dispose();
}
