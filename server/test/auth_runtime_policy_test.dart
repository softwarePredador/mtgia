import 'package:server/auth_runtime_policy.dart';
import 'package:test/test.dart';

void main() {
  const productionSecret = '4L!u9v#Q2m@R7x%T5p&K8s*D3n+W6y=H1c?J0z_A';

  test('runtime selector carries every auth and email contract coordinate', () {
    final source = {
      for (final key in authRuntimeEnvironmentKeys) key: 'value-$key',
      'UNRELATED': 'ignored',
    };

    final selected = authRuntimeEnvironmentValues((key) => source[key]);

    expect(selected.keys, unorderedEquals(authRuntimeEnvironmentKeys));
    expect(selected, isNot(contains('UNRELATED')));
    expect(
      selected,
      containsPair(
        'MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE',
        'value-MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE',
      ),
    );
  });

  group('JWT secret runtime policy', () {
    test('accepts a non-placeholder production secret without exposing it', () {
      expect(
        () => validateAuthRuntimeEnvironment(const {
          'ENVIRONMENT': 'production',
          'JWT_SECRET': productionSecret,
          'MANALOOM_TRUSTED_PROXY_HOPS': '1',
          'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
          'PASSWORD_RESET_WEBHOOK_URL': 'https://email.example/reset',
          'PASSWORD_RESET_WEBHOOK_TOKEN': 'reset-webhook-token-safe',
          'PASSWORD_RESET_APP_URL': 'https://app.example/#/reset-password',
          'EMAIL_VERIFICATION_WEBHOOK_URL': 'https://email.example/verify',
          'EMAIL_VERIFICATION_WEBHOOK_TOKEN': 'verify-webhook-token-safe',
          'EMAIL_VERIFICATION_APP_URL': 'https://app.example/#/verify-email',
        }),
        returnsNormally,
      );
    });

    test('rejects short production secrets without echoing the value', () {
      const weakSecret = 'short-secret-value';

      expect(
        () => validateAuthRuntimeEnvironment(const {
          'ENVIRONMENT': 'production',
          'JWT_SECRET': weakSecret,
          'MANALOOM_TRUSTED_PROXY_HOPS': '1',
          'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
        }),
        throwsA(
          isA<StateError>().having(
            (error) => error.message.toString(),
            'redacted message',
            isNot(contains(weakSecret)),
          ),
        ),
      );
    });

    test('rejects known placeholders and predictable production markers', () {
      for (final secret in const [
        'CHANGE_THIS_TO_A_SECURE_RANDOM_STRING',
        'local_test_jwt_secret_not_for_production_20260717',
        'password_password_password_password_2026',
      ]) {
        expect(
          () => validateAuthRuntimeEnvironment({
            'ENVIRONMENT': 'production',
            'JWT_SECRET': secret,
            'MANALOOM_TRUSTED_PROXY_HOPS': '1',
            'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
          }),
          throwsStateError,
          reason: 'secret pattern should be rejected without being logged',
        );
      }
    });

    test('allows explicit local test markers only outside production', () {
      expect(
        () => validateAuthRuntimeEnvironment(const {
          'ENVIRONMENT': 'development',
          'JWT_SECRET': 'local_test_jwt_secret_not_for_production_20260717',
        }),
        returnsNormally,
      );
    });
  });

  group('account email delivery policy', () {
    const valid = {
      'PASSWORD_RESET_WEBHOOK_URL': 'https://email.example/reset',
      'PASSWORD_RESET_WEBHOOK_TOKEN': 'reset-webhook-token-safe',
      'PASSWORD_RESET_APP_URL': 'https://app.example/#/reset-password',
      'EMAIL_VERIFICATION_WEBHOOK_URL': 'https://email.example/verify',
      'EMAIL_VERIFICATION_WEBHOOK_TOKEN': 'verify-webhook-token-safe',
      'EMAIL_VERIFICATION_APP_URL': 'https://app.example/#/verify-email',
    };

    test('accepts complete HTTPS delivery coordinates', () {
      expect(() => AccountEmailDeliveryPolicy.validate(valid), returnsNormally);
    });

    test('rejects absent, insecure or test-token configuration', () {
      expect(
        () => AccountEmailDeliveryPolicy.validate({
          ...valid,
          'PASSWORD_RESET_WEBHOOK_URL': 'http://email.example/reset',
        }),
        throwsStateError,
      );
      expect(
        () => AccountEmailDeliveryPolicy.validate({
          ...valid,
          'MANALOOM_EMAIL_VERIFICATION_TEST_RESPONSE': 'anything',
        }),
        throwsStateError,
      );
    });
  });

  group('trusted proxy policy', () {
    test('production fails closed without an explicit trusted hop count', () {
      expect(
        () => validateAuthRuntimeEnvironment(const {
          'ENVIRONMENT': 'production',
          'JWT_SECRET': productionSecret,
        }),
        throwsStateError,
      );
    });

    test('untrusted forwarded headers do not change development identity', () {
      final first = resolveRateLimitClientIdentity(
        headers: const {
          'X-Forwarded-For': '198.51.100.1',
          'User-Agent': 'same-client',
          'Host': 'localhost',
        },
        environment: const {'ENVIRONMENT': 'development'},
      );
      final second = resolveRateLimitClientIdentity(
        headers: const {
          'X-Forwarded-For': '203.0.113.250',
          'User-Agent': 'same-client',
          'Host': 'localhost',
        },
        environment: const {'ENVIRONMENT': 'development'},
      );

      expect(first.isValid, isTrue);
      expect(first.source, ClientIdentitySource.requestFingerprint);
      expect(second.identifier, first.identifier);
    });

    test('selects the trusted client hop from the right', () {
      final identity = resolveRateLimitClientIdentity(
        headers: const {
          'X-Forwarded-For': 'attacker-controlled, 203.0.113.10, 10.0.0.8',
        },
        environment: const {
          'ENVIRONMENT': 'production',
          'MANALOOM_TRUSTED_PROXY_HOPS': '2',
          'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
        },
        remoteAddress: '10.0.0.42',
      );

      expect(identity.isValid, isTrue);
      expect(identity.identifier, '203.0.113.10');
      expect(identity.source, ClientIdentitySource.trustedForwardedFor);
    });

    test('canonicalizes IPv4-mapped IPv6 peers without widening trust', () {
      final identity = resolveRateLimitClientIdentity(
        headers: const {'X-Forwarded-For': '::ffff:203.0.113.10'},
        environment: const {
          'ENVIRONMENT': 'production',
          'MANALOOM_TRUSTED_PROXY_HOPS': '1',
          'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.42/32',
        },
        remoteAddress: '::ffff:10.0.0.42',
      );

      expect(identity.isValid, isTrue);
      expect(identity.identifier, '203.0.113.10');
      expect(identity.source, ClientIdentitySource.trustedForwardedFor);
    });

    test('still rejects a mapped peer outside the exact IPv4 allowlist', () {
      final identity = resolveRateLimitClientIdentity(
        headers: const {'X-Forwarded-For': '203.0.113.10'},
        environment: const {
          'ENVIRONMENT': 'production',
          'MANALOOM_TRUSTED_PROXY_HOPS': '1',
          'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.42/32',
        },
        remoteAddress: '::ffff:10.0.0.43',
      );

      expect(identity.isValid, isFalse);
      expect(identity.failureCode, 'untrusted_proxy_peer');
    });

    test('separates the production overlay peer from the Traefik task IP', () {
      const environment = {
        'ENVIRONMENT': 'production',
        'MANALOOM_TRUSTED_PROXY_HOPS': '1',
        'MANALOOM_TRUSTED_PROXY_PEERS': '10.11.0.4/32',
      };

      final transportPeer = resolveRateLimitClientIdentity(
        headers: const {'X-Forwarded-For': '203.0.113.10'},
        environment: environment,
        remoteAddress: '::ffff:10.11.0.4',
      );
      final logicalTraefikAddress = resolveRateLimitClientIdentity(
        headers: const {'X-Forwarded-For': '203.0.113.10'},
        environment: environment,
        remoteAddress: '::ffff:10.11.0.202',
      );

      expect(transportPeer.isValid, isTrue);
      expect(transportPeer.identifier, '203.0.113.10');
      expect(logicalTraefikAddress.isValid, isFalse);
      expect(logicalTraefikAddress.failureCode, 'untrusted_proxy_peer');
    });

    test('rejects missing, short or malformed trusted proxy chains', () {
      const environment = {
        'ENVIRONMENT': 'production',
        'MANALOOM_TRUSTED_PROXY_HOPS': '2',
        'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
      };

      expect(
        resolveRateLimitClientIdentity(
          headers: const {},
          environment: environment,
          remoteAddress: '10.0.0.42',
        ).isValid,
        isFalse,
      );
      expect(
        resolveRateLimitClientIdentity(
          headers: const {'X-Forwarded-For': '203.0.113.10'},
          environment: environment,
          remoteAddress: '10.0.0.42',
        ).isValid,
        isFalse,
      );
      expect(
        resolveRateLimitClientIdentity(
          headers: const {'X-Forwarded-For': '203.0.113.10, not-an-ip'},
          environment: environment,
          remoteAddress: '10.0.0.42',
        ).isValid,
        isFalse,
      );
    });

    test('does not trust alternate client IP headers', () {
      final identity = resolveRateLimitClientIdentity(
        headers: const {
          'X-Real-IP': '203.0.113.10',
          'CF-Connecting-IP': '203.0.113.11',
        },
        environment: const {
          'ENVIRONMENT': 'production',
          'MANALOOM_TRUSTED_PROXY_HOPS': '1',
          'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
        },
        remoteAddress: '10.0.0.42',
      );

      expect(identity.isValid, isFalse);
      expect(identity.failureCode, 'missing_forwarded_for');
    });

    test('rejects an XFF chain received from an untrusted direct peer', () {
      final identity = resolveRateLimitClientIdentity(
        headers: const {'X-Forwarded-For': '203.0.113.10'},
        environment: const {
          'ENVIRONMENT': 'production',
          'MANALOOM_TRUSTED_PROXY_HOPS': '1',
          'MANALOOM_TRUSTED_PROXY_PEERS': '10.0.0.0/8',
        },
        remoteAddress: '198.51.100.99',
      );

      expect(identity.isValid, isFalse);
      expect(identity.failureCode, 'untrusted_proxy_peer');
    });

    test('rejects wildcard and malformed trusted peer networks', () {
      for (final peers in const ['0.0.0.0/0', '::/0', 'not-a-network']) {
        expect(
          () => TrustedProxyPolicy.fromEnvironment({
            'MANALOOM_TRUSTED_PROXY_HOPS': '1',
            'MANALOOM_TRUSTED_PROXY_PEERS': peers,
          }, production: true),
          throwsStateError,
        );
      }
    });
  });
}
