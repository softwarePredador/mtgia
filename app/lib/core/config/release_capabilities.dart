import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

enum ReleaseCapability {
  accountRegistration('account_registration'),
  catalogPrivate('catalog_private'),
  decksPrivate('decks_private'),
  collectionPrivate('collection_private'),
  aiAnalyzeOptimizeAdvisory('ai_analyze_optimize_advisory'),
  aiGenerateRebuild('ai_generate_rebuild'),
  battleBatch('battle_batch'),
  battleLive('battle_live'),
  battleCoach('battle_coach'),
  scanner('scanner'),
  lifeCounterLocal('life_counter_local'),
  galleryPublic('gallery_public'),
  profilesPublic('profiles_public'),
  comments('comments'),
  follows('follows'),
  userSearch('user_search'),
  directMessages('direct_messages'),
  socialPush('social_push'),
  binderPublic('binder_public'),
  trades('trades'),
  marketplace('marketplace'),
  billingCheckout('billing_checkout'),
  subscriptions('subscriptions'),
  ads('ads'),
  artPaywall('art_paywall'),
  learningReads('learning_reads'),
  learningWrites('learning_writes'),
  legacyAiRoutes('legacy_ai_routes'),
  deckReplaceAll('deck_replace_all');

  const ReleaseCapability(this.wireName);

  final String wireName;
}

enum ReleaseCapabilitiesLoadState { initial, loading, ready, unavailable }

@immutable
class ReleaseCapabilityEntry {
  const ReleaseCapabilityEntry({
    required this.allowed,
    required this.implementationStatus,
    required this.releaseCapability,
    required this.liveVerifiedAsOf,
  });

  static const denied = ReleaseCapabilityEntry(
    allowed: false,
    implementationStatus: '',
    releaseCapability: '',
    liveVerifiedAsOf: null,
  );

  /// Effective authorization calculated by the backend.
  ///
  /// `implementation_status` and `release_capability` remain informational
  /// axes. The client deliberately does not infer access from either one.
  final bool allowed;
  final String implementationStatus;
  final String releaseCapability;
  final String? liveVerifiedAsOf;

  static ReleaseCapabilityEntry? tryParse(Object? value) {
    final json = _stringKeyedMap(value);
    if (json == null ||
        !_hasExactKeys(json, _entryKeys) ||
        !_implementationStatusValues.contains(json['implementation_status']) ||
        !_releaseCapabilityValues.contains(json['release_capability']) ||
        json['allowed'] is! bool ||
        !_isValidTimestamp(json['live_verified_as_of'])) {
      return null;
    }

    final releaseCapability = json['release_capability']! as String;
    final allowed = json['allowed']! as bool;
    if (allowed != (releaseCapability == 'on')) return null;

    return ReleaseCapabilityEntry(
      allowed: allowed,
      implementationStatus: (json['implementation_status']! as String).trim(),
      releaseCapability: releaseCapability,
      liveVerifiedAsOf: _nullableStringValue(json['live_verified_as_of']),
    );
  }
}

@immutable
class ReleaseCapabilitiesSnapshot {
  ReleaseCapabilitiesSnapshot._({
    required this.isValid,
    required this.policyVersion,
    required this.policyDigestSha256,
    required Map<ReleaseCapability, ReleaseCapabilityEntry> entries,
  }) : entries = Map.unmodifiable(entries);

  factory ReleaseCapabilitiesSnapshot.denied() {
    return ReleaseCapabilitiesSnapshot._(
      isValid: false,
      policyVersion: '',
      policyDigestSha256: '',
      entries: const <ReleaseCapability, ReleaseCapabilityEntry>{},
    );
  }

  factory ReleaseCapabilitiesSnapshot.fromJson(Object? value) {
    final json = _stringKeyedMap(value);
    if (json == null || !_hasValidEnvelope(json)) {
      return ReleaseCapabilitiesSnapshot.denied();
    }

    final rawCapabilities = _stringKeyedMap(json['capabilities']);
    final expectedCapabilityKeys = {
      for (final capability in ReleaseCapability.values) capability.wireName,
    };
    if (rawCapabilities == null ||
        !_hasExactKeys(rawCapabilities, expectedCapabilityKeys)) {
      return ReleaseCapabilitiesSnapshot.denied();
    }

    final entries = <ReleaseCapability, ReleaseCapabilityEntry>{};
    for (final capability in ReleaseCapability.values) {
      final entry = ReleaseCapabilityEntry.tryParse(
        rawCapabilities[capability.wireName],
      );
      if (entry == null) return ReleaseCapabilitiesSnapshot.denied();
      entries[capability] = entry;
    }

    return ReleaseCapabilitiesSnapshot._(
      isValid: true,
      policyVersion: (json['policy_version'] as String).trim(),
      policyDigestSha256: (json['policy_digest_sha256'] as String).trim(),
      entries: entries,
    );
  }

  @visibleForTesting
  factory ReleaseCapabilitiesSnapshot.forTesting(
    Iterable<ReleaseCapability> allowed,
  ) {
    final allowedSet = allowed.toSet();
    return ReleaseCapabilitiesSnapshot._(
      isValid: true,
      policyVersion: 'test',
      policyDigestSha256: List.filled(64, '0').join(),
      entries: {
        for (final capability in ReleaseCapability.values)
          capability: ReleaseCapabilityEntry(
            allowed: allowedSet.contains(capability),
            implementationStatus: 'test',
            releaseCapability: allowedSet.contains(capability) ? 'on' : 'off',
            liveVerifiedAsOf: null,
          ),
      },
    );
  }

  static const schemaVersion = 'release_capabilities_v1';
  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
  static const _topLevelKeys = <String>{
    'schema_version',
    'policy_version',
    'product',
    'release_channel',
    'offer_mode',
    'implementation_status',
    'live_verified_as_of',
    'policy_digest_sha256',
    'configuration_status',
    'capabilities',
  };

  final bool isValid;
  final String policyVersion;
  final String policyDigestSha256;
  final Map<ReleaseCapability, ReleaseCapabilityEntry> entries;

  bool isAllowed(ReleaseCapability capability) {
    return isValid && (entries[capability]?.allowed ?? false);
  }

  bool areAllAllowed(Iterable<ReleaseCapability> capabilities) {
    return capabilities.every(isAllowed);
  }

  static bool _hasValidEnvelope(Map<String, Object?> json) {
    final policyVersion = json['policy_version'];
    final digest = json['policy_digest_sha256'];
    return _hasExactKeys(json, _topLevelKeys) &&
        json['schema_version'] == schemaVersion &&
        json['product'] == 'brewtact' &&
        json['release_channel'] == 'free_beta' &&
        json['offer_mode'] == 'free_beta_no_commerce' &&
        json['configuration_status'] == 'valid' &&
        policyVersion is String &&
        policyVersion.trim().isNotEmpty &&
        _implementationStatusValues.contains(json['implementation_status']) &&
        _isValidTimestamp(json['live_verified_as_of']) &&
        digest is String &&
        _sha256Pattern.hasMatch(digest.trim());
  }
}

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

const _implementationStatusValues = <String>{
  'contained_legacy',
  'experimental_guarded',
  'experimental_p0_open',
  'implemented_guarded',
  'implemented_p0_open',
  'not_implemented',
};

typedef ReleaseCapabilitiesFetcher =
    Future<ApiResponse> Function(String endpoint);

class ReleaseCapabilitiesProvider extends ChangeNotifier {
  ReleaseCapabilitiesProvider({
    ApiClient? apiClient,
    ReleaseCapabilitiesFetcher? fetcher,
  }) : _apiClient = apiClient ?? ApiClient(),
       _fetcher = fetcher;

  @visibleForTesting
  ReleaseCapabilitiesProvider.seeded(Iterable<ReleaseCapability> allowed)
    : _apiClient = ApiClient(),
      _fetcher = null {
    _snapshot = ReleaseCapabilitiesSnapshot.forTesting(allowed);
    _loadState = ReleaseCapabilitiesLoadState.ready;
  }

  static const endpoint = '/capabilities';

  final ApiClient _apiClient;
  final ReleaseCapabilitiesFetcher? _fetcher;

  ReleaseCapabilitiesSnapshot _snapshot = ReleaseCapabilitiesSnapshot.denied();
  ReleaseCapabilitiesLoadState _loadState =
      ReleaseCapabilitiesLoadState.initial;
  int _generation = 0;
  bool _disposed = false;

  ReleaseCapabilitiesSnapshot get snapshot => _snapshot;
  ReleaseCapabilitiesLoadState get loadState => _loadState;

  bool isAllowed(ReleaseCapability capability, {bool buildSupported = true}) {
    return buildSupported && _snapshot.isAllowed(capability);
  }

  bool areAllAllowed(Iterable<ReleaseCapability> capabilities) {
    return _snapshot.areAllAllowed(capabilities);
  }

  Future<bool> refresh() async {
    final generation = ++_generation;
    _snapshot = ReleaseCapabilitiesSnapshot.denied();
    _loadState = ReleaseCapabilitiesLoadState.loading;
    _notifyIfMounted();

    try {
      final response =
          await (_fetcher?.call(endpoint) ?? _apiClient.get(endpoint));
      if (!_isCurrent(generation)) return false;

      if (response.statusCode != 200) {
        _markUnavailable();
        return false;
      }

      final parsed = ReleaseCapabilitiesSnapshot.fromJson(response.data);
      if (!parsed.isValid) {
        _markUnavailable();
        return false;
      }

      _snapshot = parsed;
      _loadState = ReleaseCapabilitiesLoadState.ready;
      _notifyIfMounted();
      return true;
    } catch (_) {
      if (!_isCurrent(generation)) return false;
      _markUnavailable();
      return false;
    }
  }

  void reset() {
    _generation++;
    _snapshot = ReleaseCapabilitiesSnapshot.denied();
    _loadState = ReleaseCapabilitiesLoadState.initial;
    _notifyIfMounted();
  }

  void _markUnavailable() {
    _snapshot = ReleaseCapabilitiesSnapshot.denied();
    _loadState = ReleaseCapabilitiesLoadState.unavailable;
    _notifyIfMounted();
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
  }

  void _notifyIfMounted() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}

@immutable
class ReleaseRouteBuildSupport {
  const ReleaseRouteBuildSupport({
    this.scanner = false,
    this.battleLive = false,
    this.battleCoach = false,
    this.billingCheckout = false,
  });

  final bool scanner;
  final bool battleLive;
  final bool battleCoach;
  final bool billingCheckout;
}

abstract final class ReleaseCapabilityRouteGuard {
  static String? redirectFor({
    required Uri uri,
    required ReleaseCapabilitiesSnapshot capabilities,
    required ReleaseRouteBuildSupport buildSupport,
  }) {
    final path = _normalizedPath(uri.path);

    if (path == '/register' &&
        !capabilities.isAllowed(ReleaseCapability.accountRegistration)) {
      return _replacePath(uri, '/login');
    }

    if ((path == '/life-counter' || path.startsWith('/life-counter/')) &&
        !capabilities.isAllowed(ReleaseCapability.lifeCounterLocal)) {
      return '/home';
    }

    if (path == '/decks/generate' &&
        !capabilities.isAllowed(ReleaseCapability.aiGenerateRebuild)) {
      return '/decks';
    }

    if (path.startsWith('/decks/')) {
      final optimizeIntent = uri.queryParameters['optimize']
          ?.trim()
          .toLowerCase();
      final optimizeAllowed = switch (optimizeIntent) {
        'rebuild' => capabilities.isAllowed(
          ReleaseCapability.aiGenerateRebuild,
        ),
        'post_game' => capabilities.isAllowed(
          ReleaseCapability.aiAnalyzeOptimizeAdvisory,
        ),
        _ => true,
      };
      if (!optimizeAllowed) {
        return _withoutQueryParameter(uri, 'optimize');
      }
    }

    if (path.endsWith('/scan') &&
        !(buildSupport.scanner &&
            capabilities.isAllowed(ReleaseCapability.scanner))) {
      return _replacePath(uri, path.replaceFirst(RegExp(r'/scan$'), '/search'));
    }

    if (path.startsWith('/decks/') &&
        path.endsWith('/search') &&
        !capabilities.isAllowed(ReleaseCapability.catalogPrivate)) {
      return _deckDetailsFallback(path);
    }

    if (path.contains('/battle-coach') &&
        !(buildSupport.battleCoach &&
            capabilities.isAllowed(ReleaseCapability.battleCoach))) {
      return _deckDetailsFallback(path);
    }

    if (path.contains('/battle-live/') &&
        !(buildSupport.battleLive &&
            capabilities.isAllowed(ReleaseCapability.battleLive))) {
      return _deckDetailsFallback(path);
    }

    if (path.endsWith('/battle-replays') &&
        !capabilities.isAllowed(ReleaseCapability.battleBatch)) {
      return _deckDetailsFallback(path);
    }

    if (path.startsWith('/community/search-users') &&
        !capabilities.isAllowed(ReleaseCapability.userSearch)) {
      return '/home';
    }

    if (path.startsWith('/community/user/')) {
      const required = <ReleaseCapability>{
        ReleaseCapability.profilesPublic,
        ReleaseCapability.follows,
        ReleaseCapability.galleryPublic,
        ReleaseCapability.binderPublic,
        ReleaseCapability.directMessages,
        ReleaseCapability.trades,
      };
      if (!capabilities.areAllAllowed(required)) return '/home';
    }

    if (path.startsWith('/community/decks/')) {
      const required = <ReleaseCapability>{
        ReleaseCapability.galleryPublic,
        ReleaseCapability.profilesPublic,
        ReleaseCapability.comments,
        ReleaseCapability.trades,
      };
      if (!capabilities.areAllAllowed(required)) return '/home';
    }

    if (path == '/community') {
      final tab = _exactHubTabId(uri.queryParameters['tab']);
      final allowed = switch (tab) {
        1 => capabilities.areAllAllowed(const {
          ReleaseCapability.galleryPublic,
          ReleaseCapability.follows,
        }),
        2 => capabilities.areAllAllowed(const {
          ReleaseCapability.profilesPublic,
          ReleaseCapability.userSearch,
        }),
        3 => capabilities.isAllowed(ReleaseCapability.marketplace),
        _ => capabilities.isAllowed(ReleaseCapability.galleryPublic),
      };
      if (!allowed) {
        return _firstAllowedCommunityLocation(capabilities) ?? '/home';
      }
    }

    if (path.startsWith('/messages') &&
        !capabilities.isAllowed(ReleaseCapability.directMessages)) {
      return '/home';
    }

    if (path.startsWith('/notifications') &&
        !capabilities.isAllowed(ReleaseCapability.socialPush)) {
      return '/home';
    }

    if ((path == '/collection' ||
            path.startsWith('/collection/') ||
            path == '/binder' ||
            path.startsWith('/binder/')) &&
        !capabilities.isAllowed(ReleaseCapability.collectionPrivate)) {
      return '/home';
    }

    if ((path == '/collection/sets' ||
            path.startsWith('/collection/sets/') ||
            path == '/collection/latest-set') &&
        !capabilities.isAllowed(ReleaseCapability.catalogPrivate)) {
      return '/collection?tab=0';
    }

    if (path.startsWith('/trades') &&
        !capabilities.isAllowed(ReleaseCapability.trades)) {
      return '/collection?tab=0';
    }

    if (path == '/collection/matches' &&
        !capabilities.isAllowed(ReleaseCapability.trades)) {
      return '/collection?tab=0';
    }

    if (path == '/market' || path == '/marketplace' || path == '/quotes') {
      if (!capabilities.isAllowed(ReleaseCapability.marketplace)) {
        return '/collection?tab=0';
      }
    }

    if (path == '/collection') {
      final tab = _exactHubTabId(uri.queryParameters['tab']);
      final tabAllowed = switch (tab) {
        1 => capabilities.isAllowed(ReleaseCapability.marketplace),
        2 => capabilities.isAllowed(ReleaseCapability.trades),
        3 => capabilities.isAllowed(ReleaseCapability.catalogPrivate),
        _ => capabilities.isAllowed(ReleaseCapability.collectionPrivate),
      };
      if (!tabAllowed) {
        return '/collection?tab=0';
      }
    }

    if ((path == '/upgrade' || path == '/checkout') &&
        !(buildSupport.billingCheckout &&
            capabilities.isAllowed(ReleaseCapability.billingCheckout))) {
      return '/plans';
    }

    if ((path == '/decks' || path.startsWith('/decks/')) &&
        !capabilities.isAllowed(ReleaseCapability.decksPrivate)) {
      return '/home';
    }

    if ((path == '/cards' ||
            path.startsWith('/cards/') ||
            path == '/sets' ||
            path.startsWith('/sets/')) &&
        !capabilities.isAllowed(ReleaseCapability.catalogPrivate)) {
      return '/home';
    }

    return null;
  }

  static String _normalizedPath(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }

  static int _exactHubTabId(String? raw) {
    return switch (raw) {
      '1' => 1,
      '2' => 2,
      '3' => 3,
      _ => 0,
    };
  }

  static String _deckDetailsFallback(String path) {
    final match = RegExp(r'^/decks/[^/]+').firstMatch(path);
    return match?.group(0) ?? '/decks';
  }

  static String? _firstAllowedCommunityLocation(
    ReleaseCapabilitiesSnapshot capabilities,
  ) {
    if (capabilities.isAllowed(ReleaseCapability.galleryPublic)) {
      return '/community?tab=0';
    }
    if (capabilities.areAllAllowed(const {
      ReleaseCapability.galleryPublic,
      ReleaseCapability.follows,
    })) {
      return '/community?tab=1';
    }
    if (capabilities.areAllAllowed(const {
      ReleaseCapability.profilesPublic,
      ReleaseCapability.userSearch,
    })) {
      return '/community?tab=2';
    }
    if (capabilities.isAllowed(ReleaseCapability.marketplace)) {
      return '/community?tab=3';
    }
    return null;
  }

  static String _replacePath(Uri uri, String path) {
    return Uri(
      path: path,
      queryParameters: uri.queryParametersAll.isEmpty
          ? null
          : uri.queryParametersAll,
    ).toString();
  }

  static String _withoutQueryParameter(Uri uri, String parameter) {
    final query = <String, dynamic>{};
    for (final entry in uri.queryParametersAll.entries) {
      if (entry.key == parameter) continue;
      query[entry.key] = entry.value.length == 1
          ? entry.value.single
          : entry.value;
    }
    return Uri(
      path: uri.path,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
}

Map<String, Object?>? _stringKeyedMap(Object? value) {
  if (value is! Map) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}

bool _hasExactKeys(Map<String, Object?> value, Set<String> expected) {
  return value.length == expected.length &&
      value.keys.toSet().containsAll(expected);
}

bool _isValidTimestamp(Object? value) {
  if (value == null) return true;
  return value is String &&
      value.endsWith('Z') &&
      DateTime.tryParse(value)?.isUtc == true;
}

String? _nullableStringValue(Object? value) {
  if (value == null) return null;
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
