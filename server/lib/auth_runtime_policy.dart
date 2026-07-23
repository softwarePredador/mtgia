import 'dart:convert';
import 'dart:io';

const jwtSecretMinimumProductionBytes = 32;
const jwtSecretMinimumProductionCharacters = 32;
const maximumTrustedProxyHops = 5;
const trustedProxyHopsEnvironmentKey = 'MANALOOM_TRUSTED_PROXY_HOPS';
const trustedProxyPeersEnvironmentKey = 'MANALOOM_TRUSTED_PROXY_PEERS';

/// Validates the authentication settings that must be safe before the server
/// accepts traffic. Error messages deliberately describe only the violated
/// contract and never include secret values.
void validateAuthRuntimeEnvironment(
  Map<String, String> environment, {
  bool requireProduction = false,
}) {
  final runtimeMode =
      (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase();
  if (runtimeMode != 'development' && runtimeMode != 'production') {
    throw StateError('ENVIRONMENT deve ser development ou production.');
  }
  if (requireProduction && runtimeMode != 'production') {
    throw StateError('O preflight de release exige ENVIRONMENT=production.');
  }

  JwtSecretPolicy.validate(
    environment['JWT_SECRET'],
    production: runtimeMode == 'production',
  );
  TrustedProxyPolicy.fromEnvironment(
    environment,
    production: runtimeMode == 'production',
  );
  if (runtimeMode == 'production') {
    AccountEmailDeliveryPolicy.validate(environment);
  }
}

class AccountEmailDeliveryPolicy {
  const AccountEmailDeliveryPolicy._();

  static void validate(Map<String, String> environment) {
    for (final key in const [
      'PASSWORD_RESET_WEBHOOK_URL',
      'PASSWORD_RESET_APP_URL',
      'EMAIL_VERIFICATION_WEBHOOK_URL',
      'EMAIL_VERIFICATION_APP_URL',
    ]) {
      final value = environment[key]?.trim();
      final uri = value == null ? null : Uri.tryParse(value);
      if (uri == null ||
          uri.scheme.toLowerCase() != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw StateError('$key deve ser uma URL HTTPS sem credenciais.');
      }
    }
    for (final key in const [
      'PASSWORD_RESET_WEBHOOK_TOKEN',
      'EMAIL_VERIFICATION_WEBHOOK_TOKEN',
    ]) {
      final value = environment[key];
      if (value == null || value.trim() != value || value.length < 16) {
        throw StateError('$key não atende ao contrato de produção.');
      }
    }
    if (environment['MANALOOM_PASSWORD_RESET_TEST_RESPONSE'] != null ||
        environment['MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE'] != null) {
      throw StateError('Exposição de tokens de teste é proibida em produção.');
    }
  }
}

class JwtSecretPolicy {
  const JwtSecretPolicy._();

  static void validate(String? secret, {required bool production}) {
    if (secret == null || secret.isEmpty) {
      throw StateError('JWT_SECRET não configurado.');
    }
    if (secret != secret.trim()) {
      throw StateError('JWT_SECRET não pode iniciar ou terminar com espaços.');
    }
    if (secret.runes.length > 4096) {
      throw StateError('JWT_SECRET excede o tamanho máximo aceito.');
    }

    final normalized = secret.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    const universalPlaceholders = <String>[
      'change_this',
      'changeme',
      'your_super_secret',
      'your-super-secret',
      'placeholder',
      'example_secret',
    ];
    if (universalPlaceholders.any(normalized.contains)) {
      throw StateError('JWT_SECRET usa um placeholder conhecido.');
    }

    if (!production) {
      if (utf8.encode(secret).length < 16) {
        throw StateError(
          'JWT_SECRET deve ter ao menos 16 bytes fora de produção.',
        );
      }
      return;
    }

    final byteLength = utf8.encode(secret).length;
    if (byteLength < jwtSecretMinimumProductionBytes ||
        secret.runes.length < jwtSecretMinimumProductionCharacters) {
      throw StateError(
        'JWT_SECRET de produção deve ter ao menos '
        '$jwtSecretMinimumProductionCharacters caracteres e '
        '$jwtSecretMinimumProductionBytes bytes.',
      );
    }

    const forbiddenProductionMarkers = <String>[
      'not_for_production',
      'not-for-production',
      'local_test',
      'local-test',
      'jwt_secret',
      'jwt-secret',
      'password',
    ];
    if (forbiddenProductionMarkers.any(normalized.contains)) {
      throw StateError('JWT_SECRET de produção usa um padrão previsível.');
    }

    final uniqueCharacters = secret.runes.toSet().length;
    if (uniqueCharacters < 10) {
      throw StateError(
        'JWT_SECRET de produção possui diversidade insuficiente.',
      );
    }
  }
}

class TrustedProxyPolicy {
  const TrustedProxyPolicy._(this.trustedHops, this.trustedPeers);

  final int trustedHops;
  final List<_IpNetwork> trustedPeers;

  bool get isEnabled => trustedHops > 0;

  static TrustedProxyPolicy fromEnvironment(
    Map<String, String> environment, {
    required bool production,
  }) {
    final raw = environment[trustedProxyHopsEnvironmentKey]?.trim();
    if (raw == null || raw.isEmpty) {
      if (production) {
        throw StateError(
          '$trustedProxyHopsEnvironmentKey é obrigatório em produção.',
        );
      }
      return const TrustedProxyPolicy._(0, []);
    }

    final hops = int.tryParse(raw);
    if (hops == null || hops < 0 || hops > maximumTrustedProxyHops) {
      throw StateError(
        '$trustedProxyHopsEnvironmentKey deve estar entre 0 e '
        '$maximumTrustedProxyHops.',
      );
    }
    if (production && hops == 0) {
      throw StateError(
        '$trustedProxyHopsEnvironmentKey deve ser maior que zero em produção.',
      );
    }
    final rawPeers = environment[trustedProxyPeersEnvironmentKey]?.trim();
    if (hops > 0 && (rawPeers == null || rawPeers.isEmpty)) {
      throw StateError(
        '$trustedProxyPeersEnvironmentKey é obrigatório quando proxy é confiável.',
      );
    }
    final peers = <_IpNetwork>[];
    if (rawPeers != null && rawPeers.isNotEmpty) {
      final entries = rawPeers.split(',').map((value) => value.trim()).toList();
      if (entries.length > 16 || entries.any((value) => value.isEmpty)) {
        throw StateError('$trustedProxyPeersEnvironmentKey é inválido.');
      }
      for (final entry in entries) {
        final network = _IpNetwork.tryParse(entry);
        if (network == null) {
          throw StateError(
            '$trustedProxyPeersEnvironmentKey contém rede inválida.',
          );
        }
        peers.add(network);
      }
    }
    return TrustedProxyPolicy._(hops, List.unmodifiable(peers));
  }

  ClientIdentityResolution resolve(
    Map<String, String> headers, {
    String? remoteAddress,
  }) {
    if (!isEnabled) {
      final directPeer = _parseCanonicalInternetAddress(remoteAddress);
      if (directPeer != null) {
        return ClientIdentityResolution.success(
          directPeer.address,
          source: ClientIdentitySource.directPeer,
        );
      }
      return ClientIdentityResolution.success(
        _buildNonProxyFingerprint(headers),
        source: ClientIdentitySource.requestFingerprint,
      );
    }

    final peer = _parseCanonicalInternetAddress(remoteAddress);
    if (peer == null) {
      return const ClientIdentityResolution.failure('missing_remote_peer');
    }
    if (!trustedPeers.any((network) => network.contains(peer))) {
      return const ClientIdentityResolution.failure('untrusted_proxy_peer');
    }

    final forwardedFor = _header(headers, 'x-forwarded-for');
    if (forwardedFor == null || forwardedFor.trim().isEmpty) {
      return const ClientIdentityResolution.failure('missing_forwarded_for');
    }

    final chain = forwardedFor.split(',').map((value) => value.trim()).toList();
    if (chain.length < trustedHops ||
        chain.length > 32 ||
        chain.any((value) => value.isEmpty)) {
      return const ClientIdentityResolution.failure(
        'invalid_forwarded_for_chain',
      );
    }

    // Select from the right. Client-supplied values prepended to XFF therefore
    // cannot move the trusted client hop when the edge proxy appends/overwrites
    // the actual peer address as required by the deployment contract.
    final clientIndex = chain.length - trustedHops;
    InternetAddress? clientAddress;
    for (var index = clientIndex; index < chain.length; index++) {
      final address = _parseCanonicalInternetAddress(chain[index]);
      if (address == null) {
        return const ClientIdentityResolution.failure(
          'invalid_forwarded_for_address',
        );
      }
      if (index == clientIndex) clientAddress = address;
    }

    return ClientIdentityResolution.success(
      clientAddress!.address,
      source: ClientIdentitySource.trustedForwardedFor,
    );
  }
}

enum ClientIdentitySource {
  trustedForwardedFor,
  directPeer,
  requestFingerprint,
}

class ClientIdentityResolution {
  const ClientIdentityResolution.success(
    this.identifier, {
    required this.source,
  }) : failureCode = null;

  const ClientIdentityResolution.failure(this.failureCode)
    : identifier = null,
      source = null;

  final String? identifier;
  final ClientIdentitySource? source;
  final String? failureCode;

  bool get isValid => identifier != null;
}

ClientIdentityResolution resolveRateLimitClientIdentity({
  required Map<String, String> headers,
  required Map<String, String> environment,
  String? remoteAddress,
}) {
  final production =
      (environment['ENVIRONMENT'] ?? 'development').trim().toLowerCase() ==
      'production';
  try {
    return TrustedProxyPolicy.fromEnvironment(
      environment,
      production: production,
    ).resolve(headers, remoteAddress: remoteAddress);
  } on StateError {
    return const ClientIdentityResolution.failure(
      'invalid_proxy_configuration',
    );
  }
}

class _IpNetwork {
  const _IpNetwork(this.networkBytes, this.prefixLength);

  final List<int> networkBytes;
  final int prefixLength;

  static _IpNetwork? tryParse(String value) {
    final separator = value.indexOf('/');
    final addressText = separator == -1 ? value : value.substring(0, separator);
    final address = _parseCanonicalInternetAddress(addressText);
    if (address == null) return null;

    final bitLength = address.rawAddress.length * 8;
    final prefix =
        separator == -1
            ? bitLength
            : int.tryParse(value.substring(separator + 1));
    if (prefix == null || prefix < 0 || prefix > bitLength) return null;
    if ((bitLength == 32 && prefix < 8) || (bitLength == 128 && prefix < 32)) {
      return null;
    }

    final bytes = List<int>.from(address.rawAddress);
    final fullBytes = prefix ~/ 8;
    final remainingBits = prefix % 8;
    if (remainingBits > 0 && fullBytes < bytes.length) {
      final mask = (0xff << (8 - remainingBits)) & 0xff;
      bytes[fullBytes] &= mask;
    }
    for (
      var index = fullBytes + (remainingBits > 0 ? 1 : 0);
      index < bytes.length;
      index++
    ) {
      bytes[index] = 0;
    }
    return _IpNetwork(List.unmodifiable(bytes), prefix);
  }

  bool contains(InternetAddress address) {
    final candidate = address.rawAddress;
    if (candidate.length != networkBytes.length) return false;

    final fullBytes = prefixLength ~/ 8;
    for (var index = 0; index < fullBytes; index++) {
      if (candidate[index] != networkBytes[index]) return false;
    }
    final remainingBits = prefixLength % 8;
    if (remainingBits == 0) return true;
    final mask = (0xff << (8 - remainingBits)) & 0xff;
    return (candidate[fullBytes] & mask) == (networkBytes[fullBytes] & mask);
  }
}

/// Dart Frog's production server binds to [InternetAddress.anyIPv6]. IPv4
/// connections can therefore surface as IPv4-mapped IPv6 peers
/// (`::ffff:a.b.c.d`). Canonicalizing that transport representation before
/// CIDR comparison keeps the allowlist exact without broadening trusted peers.
InternetAddress? _parseCanonicalInternetAddress(String? value) {
  final parsed = InternetAddress.tryParse(value?.trim() ?? '');
  if (parsed == null) return null;
  final bytes = parsed.rawAddress;
  final isIpv4MappedIpv6 =
      bytes.length == 16 &&
      bytes.take(10).every((byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  if (!isIpv4MappedIpv6) return parsed;
  return InternetAddress.tryParse(bytes.sublist(12).join('.'));
}

String _buildNonProxyFingerprint(Map<String, String> headers) {
  final fingerprintParts =
      <String>[
        _header(headers, 'user-agent')?.trim() ?? '',
        _header(headers, 'accept-language')?.trim() ?? '',
        _header(headers, 'sec-ch-ua')?.trim() ?? '',
        _header(headers, 'host')?.trim() ?? '',
      ].where((value) => value.isNotEmpty).toList();

  if (fingerprintParts.isEmpty) {
    return 'anonymous';
  }
  return 'fingerprint:${Object.hashAll(fingerprintParts)}';
}

String? _header(Map<String, String> headers, String name) {
  final normalizedName = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == normalizedName) return entry.value;
  }
  return null;
}
