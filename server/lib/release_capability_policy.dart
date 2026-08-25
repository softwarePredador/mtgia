import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const releaseCapabilitiesSchemaVersion = 'release_capabilities_v1';
const releaseCapabilitiesDefaultPath = 'config/release_capabilities.json';
const isolatedReleaseCapabilitiesFileEnvironment =
    'MANALOOM_ISOLATED_RELEASE_CAPABILITIES_FILE';
const isolatedReleaseCapabilitiesApprovalEnvironment =
    'MANALOOM_CONFIRM_ISOLATED_RELEASE_CAPABILITIES';
const isolatedReleaseCapabilitiesApproval =
    'I_UNDERSTAND_THIS_IS_DISPOSABLE_TEST_ONLY';

const releaseCapabilityKeys = <String>{
  'account_registration',
  'catalog_private',
  'decks_private',
  'collection_private',
  'life_counter_local',
  'ai_analyze_optimize_advisory',
  'ai_generate_rebuild',
  'battle_batch',
  'battle_live',
  'battle_coach',
  'scanner',
  'gallery_public',
  'profiles_public',
  'comments',
  'follows',
  'user_search',
  'direct_messages',
  'social_push',
  'binder_public',
  'trades',
  'marketplace',
  'billing_checkout',
  'subscriptions',
  'ads',
  'art_paywall',
  'learning_reads',
  'learning_writes',
  'legacy_ai_routes',
  'deck_replace_all',
};

const _topLevelKeys = <String>{
  'schema_version',
  'policy_version',
  'product',
  'release_channel',
  'offer_mode',
  'implementation_status',
  'live_verified_as_of',
  'capabilities',
};

const _entryKeys = <String>{
  'implementation_status',
  'release_capability',
  'allowed',
  'live_verified_as_of',
};

const _releaseCapabilityValues = <String>{
  'on',
  'off',
  'experimental_allowlist',
};

const releaseImplementationStatusValues = <String>{
  'contained_legacy',
  'experimental_guarded',
  'experimental_p0_open',
  'implemented_guarded',
  'implemented_p0_open',
  'not_implemented',
};

class ReleaseCapabilityEntry {
  const ReleaseCapabilityEntry({
    required this.implementationStatus,
    required this.releaseCapability,
    required this.allowed,
    required this.liveVerifiedAsOf,
  });

  final String implementationStatus;
  final String releaseCapability;
  final bool allowed;
  final String? liveVerifiedAsOf;

  Map<String, Object?> toJson() => {
    'implementation_status': implementationStatus,
    'release_capability': releaseCapability,
    'allowed': allowed,
    'live_verified_as_of': liveVerifiedAsOf,
  };
}

class ReleaseCapabilityDecision {
  const ReleaseCapabilityDecision._({
    required this.allowed,
    required this.capability,
    required this.errorCode,
    required this.statusCode,
  });

  const ReleaseCapabilityDecision.allowed()
    : this._(
        allowed: true,
        capability: null,
        errorCode: null,
        statusCode: null,
      );

  final bool allowed;
  final String? capability;
  final String? errorCode;
  final int? statusCode;
}

class ReleaseCapabilityPolicy {
  const ReleaseCapabilityPolicy._({
    required this.schemaVersion,
    required this.policyVersion,
    required this.product,
    required this.releaseChannel,
    required this.offerMode,
    required this.implementationStatus,
    required this.liveVerifiedAsOf,
    required this.policyDigestSha256,
    required this.configurationStatus,
    required this.capabilities,
  });

  final String schemaVersion;
  final String policyVersion;
  final String product;
  final String releaseChannel;
  final String offerMode;
  final String implementationStatus;
  final String? liveVerifiedAsOf;
  final String policyDigestSha256;
  final String configurationStatus;
  final Map<String, ReleaseCapabilityEntry> capabilities;

  bool get isValid => configurationStatus == 'valid';

  bool isAllowed(String capability) {
    return isValid && (capabilities[capability]?.allowed ?? false);
  }

  ReleaseCapabilityEntry entry(String capability) {
    return capabilities[capability] ?? _disabledEntry;
  }

  ReleaseCapabilityDecision decisionFor({
    required String path,
    required String method,
    Map<String, String> queryParameters = const {},
  }) {
    final capability = requiredCapabilityForRequest(
      path: path,
      method: method,
      queryParameters: queryParameters,
    );
    if (capability == null) {
      if (isReleaseCapabilityControlPlaneRequest(path: path, method: method)) {
        return const ReleaseCapabilityDecision.allowed();
      }
      return const ReleaseCapabilityDecision._(
        allowed: false,
        capability: null,
        errorCode: 'capability_route_unclassified',
        statusCode: HttpStatus.notFound,
      );
    }
    if (!isValid) {
      return ReleaseCapabilityDecision._(
        allowed: false,
        capability: capability,
        errorCode: 'capability_policy_invalid',
        statusCode: HttpStatus.serviceUnavailable,
      );
    }
    if (!isAllowed(capability)) {
      return ReleaseCapabilityDecision._(
        allowed: false,
        capability: capability,
        errorCode: 'capability_unavailable',
        statusCode: HttpStatus.notFound,
      );
    }
    return const ReleaseCapabilityDecision.allowed();
  }

  Map<String, Object?> toPublicJson() => {
    'schema_version': schemaVersion,
    'policy_version': policyVersion,
    'product': product,
    'release_channel': releaseChannel,
    'offer_mode': offerMode,
    'implementation_status': implementationStatus,
    'live_verified_as_of': liveVerifiedAsOf,
    'policy_digest_sha256': policyDigestSha256,
    'configuration_status': configurationStatus,
    'capabilities': {
      for (final key in releaseCapabilityKeys) key: entry(key).toJson(),
    },
  };

  Map<String, Object?> readinessCheck() => {
    'status': isValid ? 'healthy' : 'unhealthy',
    'policy_version': policyVersion,
    'offer_mode': offerMode,
    'policy_digest_sha256': policyDigestSha256,
    'configuration_status': configurationStatus,
  };

  static ReleaseCapabilityPolicy load({
    String? configPath,
    Map<String, String>? environment,
  }) {
    final runtimeEnvironment = environment ?? Platform.environment;
    final isolatedConfigPath =
        runtimeEnvironment[isolatedReleaseCapabilitiesFileEnvironment]?.trim();
    if (configPath == null &&
        isolatedConfigPath != null &&
        isolatedConfigPath.isNotEmpty) {
      if (!_isolatedConfigIsAuthorized(
        isolatedConfigPath,
        runtimeEnvironment,
      )) {
        final marker = utf8.encode(
          'unauthorized-isolated-release-capabilities:$isolatedConfigPath',
        );
        return _invalidPolicy(sha256.convert(marker).toString());
      }
      configPath = isolatedConfigPath;
    }
    final candidatePaths =
        configPath == null
            ? const [
              releaseCapabilitiesDefaultPath,
              'server/$releaseCapabilitiesDefaultPath',
            ]
            : [configPath];
    File? file;
    for (final candidatePath in candidatePaths) {
      final candidate = File(candidatePath);
      if (candidate.existsSync()) {
        file = candidate;
        break;
      }
    }
    if (file == null) {
      final marker = utf8.encode('missing:${candidatePaths.join('|')}');
      return _invalidPolicy(sha256.convert(marker).toString());
    }

    List<int> bytes;
    try {
      bytes = file.readAsBytesSync();
    } catch (_) {
      final marker = utf8.encode('unreadable:${file.path}');
      return _invalidPolicy(sha256.convert(marker).toString());
    }
    final digest = sha256.convert(bytes).toString();

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return _invalidPolicy(digest);
      }
      return _parse(decoded, digest);
    } catch (_) {
      return _invalidPolicy(digest);
    }
  }

  static ReleaseCapabilityPolicy _parse(
    Map<String, dynamic> decoded,
    String digest,
  ) {
    if (!_hasExactKeys(decoded, _topLevelKeys) ||
        decoded['schema_version'] != releaseCapabilitiesSchemaVersion ||
        decoded['product'] != 'brewtact' ||
        decoded['release_channel'] != 'free_beta' ||
        decoded['offer_mode'] != 'free_beta_no_commerce' ||
        !_isNonEmptyString(decoded['policy_version']) ||
        !releaseImplementationStatusValues.contains(
          decoded['implementation_status'],
        ) ||
        !_isValidTimestamp(decoded['live_verified_as_of'])) {
      return _invalidPolicy(digest);
    }

    final rawCapabilities = decoded['capabilities'];
    if (rawCapabilities is! Map<String, dynamic> ||
        !_hasExactKeys(rawCapabilities, releaseCapabilityKeys)) {
      return _invalidPolicy(digest);
    }

    final entries = <String, ReleaseCapabilityEntry>{};
    for (final key in releaseCapabilityKeys) {
      final raw = rawCapabilities[key];
      if (raw is! Map<String, dynamic> ||
          !_hasExactKeys(raw, _entryKeys) ||
          !releaseImplementationStatusValues.contains(
            raw['implementation_status'],
          ) ||
          !_releaseCapabilityValues.contains(raw['release_capability']) ||
          raw['allowed'] is! bool ||
          !_isValidTimestamp(raw['live_verified_as_of'])) {
        return _invalidPolicy(digest);
      }
      final releaseCapability = raw['release_capability'] as String;
      final allowed = raw['allowed'] as bool;
      if (allowed != (releaseCapability == 'on')) {
        return _invalidPolicy(digest);
      }
      entries[key] = ReleaseCapabilityEntry(
        implementationStatus: raw['implementation_status'] as String,
        releaseCapability: releaseCapability,
        allowed: allowed,
        liveVerifiedAsOf: raw['live_verified_as_of'] as String?,
      );
    }

    return ReleaseCapabilityPolicy._(
      schemaVersion: decoded['schema_version'] as String,
      policyVersion: decoded['policy_version'] as String,
      product: decoded['product'] as String,
      releaseChannel: decoded['release_channel'] as String,
      offerMode: decoded['offer_mode'] as String,
      implementationStatus: decoded['implementation_status'] as String,
      liveVerifiedAsOf: decoded['live_verified_as_of'] as String?,
      policyDigestSha256: digest,
      configurationStatus: 'valid',
      capabilities: Map.unmodifiable(entries),
    );
  }
}

bool _isolatedConfigIsAuthorized(
  String configPath,
  Map<String, String> environment,
) {
  if (environment['MANALOOM_E2E_ISOLATED_RUNTIME'] != '1' ||
      environment[isolatedReleaseCapabilitiesApprovalEnvironment] !=
          isolatedReleaseCapabilitiesApproval) {
    return false;
  }
  final runtimeEnvironment = environment['ENVIRONMENT']?.trim().toLowerCase();
  if (runtimeEnvironment != 'development' && runtimeEnvironment != 'test') {
    return false;
  }

  final candidate = File(configPath);
  if (!candidate.isAbsolute || !candidate.existsSync()) {
    return false;
  }
  try {
    final resolvedTempRoot = Directory.systemTemp.resolveSymbolicLinksSync();
    final resolvedCandidate = candidate.resolveSymbolicLinksSync();
    final tempPrefix =
        resolvedTempRoot.endsWith(Platform.pathSeparator)
            ? resolvedTempRoot
            : '$resolvedTempRoot${Platform.pathSeparator}';
    return resolvedCandidate.startsWith(tempPrefix);
  } catch (_) {
    return false;
  }
}

String? requiredCapabilityForRequest({
  required String path,
  required String method,
  Map<String, String> queryParameters = const {},
}) {
  final normalizedPath = _normalizePath(path);
  final normalizedMethod = method.toUpperCase();

  if (normalizedPath == '/auth/register') {
    return 'account_registration';
  }

  if (normalizedMethod == 'PUT' &&
      RegExp(r'^/decks/[^/]+$').hasMatch(normalizedPath)) {
    return 'deck_replace_all';
  }
  if (normalizedMethod == 'POST' &&
      (RegExp(r'^/decks/[^/]+/cards/replace$').hasMatch(normalizedPath) ||
          normalizedPath == '/import/to-deck')) {
    return 'deck_replace_all';
  }

  if (normalizedPath == '/ai/battle/sessions' ||
      normalizedPath.startsWith('/ai/battle/sessions/')) {
    return 'battle_coach';
  }
  if (RegExp(r'^/ai/battle/jobs/[^/]+/live$').hasMatch(normalizedPath)) {
    return 'battle_live';
  }
  if (normalizedPath == '/ai/battle/jobs' ||
      normalizedPath.startsWith('/ai/battle/jobs/')) {
    return 'battle_batch';
  }
  if (normalizedPath == '/ai/simulate') {
    return 'battle_batch';
  }
  if (RegExp(r'^/decks/[^/]+/battle-preflight$').hasMatch(normalizedPath)) {
    final mode = queryParameters['mode']?.trim().toLowerCase();
    return mode == 'interactive' || mode == 'coach'
        ? 'battle_coach'
        : 'battle_batch';
  }
  if (RegExp(
    r'^/decks/[^/]+/battle-replays(?:/.*)?$',
  ).hasMatch(normalizedPath)) {
    return 'battle_batch';
  }

  if (normalizedPath == '/ai/generate' ||
      normalizedPath.startsWith('/ai/generate/jobs/') ||
      normalizedPath == '/ai/rebuild' ||
      normalizedPath == '/ai/commander-reference') {
    return 'ai_generate_rebuild';
  }
  if (normalizedPath == '/ai/optimize' ||
      normalizedPath.startsWith('/ai/optimize/jobs/') ||
      normalizedPath == '/ai/archetypes' ||
      normalizedPath == '/ai/explain' ||
      RegExp(
        r'^/decks/[^/]+/(ai-analysis|analysis)$',
      ).hasMatch(normalizedPath) ||
      RegExp(
        r'^/decks/[^/]+/optimizations(?:/.*)?$',
      ).hasMatch(normalizedPath)) {
    return 'ai_analyze_optimize_advisory';
  }
  if (normalizedPath == '/ai/commander-learning') {
    return normalizedMethod == 'GET' ? 'learning_reads' : 'learning_writes';
  }
  if (normalizedPath == '/ai/ml-status' ||
      normalizedPath == '/ai/simulate-matchup' ||
      normalizedPath == '/ai/weakness-analysis' ||
      normalizedPath.startsWith('/ai/optimize/telemetry') ||
      RegExp(
        r'^/decks/[^/]+/(recommendations|simulate)$',
      ).hasMatch(normalizedPath)) {
    return 'legacy_ai_routes';
  }

  if (RegExp(r'^/community/decks/[^/]+/reports$').hasMatch(normalizedPath)) {
    return null;
  }
  if (RegExp(
    r'^/community/decks/[^/]+/comments(?:/[^/]+)?$',
  ).hasMatch(normalizedPath)) {
    return normalizedMethod == 'DELETE' ? null : 'comments';
  }
  if (normalizedPath == '/community/decks/following') {
    return 'follows';
  }
  if (normalizedPath == '/community/decks' ||
      normalizedPath.startsWith('/community/decks/')) {
    return 'gallery_public';
  }
  if (normalizedPath == '/reports' || normalizedPath.startsWith('/reports/')) {
    return null;
  }
  if (RegExp(r'^/decks/[^/]+/reports$').hasMatch(normalizedPath)) {
    return 'gallery_public';
  }
  if (normalizedPath == '/community/users') {
    return 'user_search';
  }
  if (normalizedPath.startsWith('/community/users/')) {
    return 'profiles_public';
  }
  if (RegExp(
    r'^/users/[^/]+/(follow|followers|following)$',
  ).hasMatch(normalizedPath)) {
    if (normalizedMethod == 'DELETE' &&
        RegExp(r'^/users/[^/]+/follow$').hasMatch(normalizedPath)) {
      return null;
    }
    return 'follows';
  }
  if (normalizedPath == '/conversations' ||
      normalizedPath.startsWith('/conversations/')) {
    return 'direct_messages';
  }
  if (normalizedPath == '/notifications' ||
      normalizedPath.startsWith('/notifications/') ||
      normalizedPath == '/users/me/fcm-token') {
    if (normalizedPath == '/users/me/fcm-token' &&
        normalizedMethod == 'DELETE') {
      return null;
    }
    return 'social_push';
  }
  if (normalizedPath == '/community/binders' ||
      normalizedPath.startsWith('/community/binders/')) {
    return 'binder_public';
  }
  if (normalizedPath == '/community/trade-matches' ||
      normalizedPath.startsWith('/community/trade-matches/') ||
      normalizedPath == '/trades' ||
      normalizedPath.startsWith('/trades/')) {
    return 'trades';
  }
  if (normalizedPath == '/community/marketplace' ||
      normalizedPath.startsWith('/community/marketplace/')) {
    return 'marketplace';
  }
  if (normalizedMethod == 'POST' &&
      (normalizedPath == '/users/me/plan/checkout' ||
          normalizedPath == '/billing/webhook')) {
    return 'billing_checkout';
  }

  if (normalizedPath == '/cards' ||
      normalizedPath.startsWith('/cards/') ||
      normalizedPath == '/sets' ||
      normalizedPath.startsWith('/sets/') ||
      normalizedPath == '/rules' ||
      normalizedPath.startsWith('/rules/') ||
      normalizedPath.startsWith('/market/')) {
    return 'catalog_private';
  }
  if (normalizedPath == '/binder' || normalizedPath.startsWith('/binder/')) {
    return 'collection_private';
  }
  if (normalizedPath == '/decks' ||
      normalizedPath.startsWith('/decks/') ||
      normalizedPath == '/import' ||
      normalizedPath.startsWith('/import/')) {
    return 'decks_private';
  }

  return null;
}

bool isReleaseCapabilityControlPlaneRequest({
  required String path,
  required String method,
}) {
  final normalizedPath = _normalizePath(path);
  final normalizedMethod = method.toUpperCase();
  final request = '$normalizedMethod $normalizedPath';

  if (_exactControlPlaneRequests.contains(request)) {
    return true;
  }
  if (_userBlockControlPlaneMethods.contains(normalizedMethod) &&
      RegExp(r'^/users/[^/]+/block$').hasMatch(normalizedPath)) {
    return true;
  }
  if (normalizedMethod == 'DELETE' &&
      RegExp(r'^/users/[^/]+/follow$').hasMatch(normalizedPath)) {
    return true;
  }
  if (normalizedMethod == 'POST' &&
      RegExp(r'^/community/decks/[^/]+/reports$').hasMatch(normalizedPath)) {
    return true;
  }
  if (normalizedMethod == 'DELETE' &&
      RegExp(
        r'^/community/decks/[^/]+/comments/[^/]+$',
      ).hasMatch(normalizedPath)) {
    return true;
  }
  if (normalizedMethod == 'POST' &&
      RegExp(r'^/content-reports/[^/]+/appeals$').hasMatch(normalizedPath)) {
    return true;
  }
  if (normalizedMethod == 'PUT' &&
      RegExp(r'^/moderation/reports/[^/]+$').hasMatch(normalizedPath)) {
    return true;
  }
  return normalizedMethod == 'GET' &&
      RegExp(r'^/reports/[^/]+$').hasMatch(normalizedPath);
}

const _userBlockControlPlaneMethods = <String>{'GET', 'POST', 'DELETE'};

const _exactControlPlaneRequests = <String>{
  'GET /',
  'GET /capabilities',
  'GET /ready',
  'GET /health',
  'GET /health/live',
  'GET /health/ready',
  'GET /health/ai-history',
  'GET /health/commercial',
  'GET /health/dashboard',
  'GET /health/metrics',
  'POST /auth/login',
  'POST /auth/forgot-password',
  'POST /auth/reset-password',
  'POST /auth/change-password',
  'POST /auth/resend-verification',
  'POST /auth/revoke-sessions',
  'POST /auth/verify-email',
  'GET /auth/me',
  'GET /users/me',
  'PATCH /users/me',
  'DELETE /users/me',
  'GET /users/me/export',
  'GET /users/me/plan',
  'GET /users/me/blocks',
  'GET /users/me/activation-events',
  'POST /users/me/activation-events',
  'DELETE /users/me/fcm-token',
  'POST /content-reports',
  'GET /moderation/reports',
};

const _disabledEntry = ReleaseCapabilityEntry(
  implementationStatus: 'configuration_invalid',
  releaseCapability: 'off',
  allowed: false,
  liveVerifiedAsOf: null,
);

ReleaseCapabilityPolicy _invalidPolicy(String digest) {
  return ReleaseCapabilityPolicy._(
    schemaVersion: releaseCapabilitiesSchemaVersion,
    policyVersion: 'invalid',
    product: 'brewtact',
    releaseChannel: 'free_beta',
    offerMode: 'free_beta_no_commerce',
    implementationStatus: 'configuration_invalid',
    liveVerifiedAsOf: null,
    policyDigestSha256: digest,
    configurationStatus: 'invalid_fail_closed',
    capabilities: Map.unmodifiable({
      for (final key in releaseCapabilityKeys) key: _disabledEntry,
    }),
  );
}

bool _hasExactKeys(Map<String, dynamic> value, Set<String> expected) {
  return value.length == expected.length &&
      value.keys.toSet().containsAll(expected);
}

bool _isNonEmptyString(Object? value) {
  return value is String && value.trim().isNotEmpty;
}

bool _isValidTimestamp(Object? value) {
  if (value == null) return true;
  return value is String &&
      value.endsWith('Z') &&
      DateTime.tryParse(value)?.isUtc == true;
}

String _normalizePath(String path) {
  if (path.length > 1 && path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}
