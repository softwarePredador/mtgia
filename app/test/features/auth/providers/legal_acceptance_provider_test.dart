import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/auth/providers/legal_acceptance_provider.dart';
import 'package:manaloom/features/commercial/legal_policy.dart';

Map<String, Object?> _legal({
  String? acceptedTerms = '2026-01-01',
  String? acceptedPrivacy = '2026-01-01',
  String currentTerms = currentTermsVersion,
  String currentPrivacy = currentPrivacyVersion,
  bool required = true,
}) => {
  'legal': {
    'accepted_terms_version': acceptedTerms,
    'accepted_privacy_version': acceptedPrivacy,
    'current_terms_version': currentTerms,
    'current_privacy_version': currentPrivacy,
    'reacceptance_required': required,
    'accept_path': '/users/me/legal-acceptance',
  },
};

class _ScriptedApi extends ApiClient {
  _ScriptedApi({this.getResponse, this.postResponse});

  ApiResponse? getResponse;
  ApiResponse? postResponse;
  final posts = <Map<String, dynamic>>[];
  final gets = <String>[];

  @override
  Future<ApiResponse> get(String endpoint) async {
    gets.add(endpoint);
    return getResponse ?? ApiResponse(500, const {});
  }

  @override
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    posts.add({'endpoint': endpoint, ...body});
    return postResponse ?? ApiResponse(500, const {});
  }
}

void main() {
  group('LegalAcceptanceProvider (BT-LEGAL-ACCEPT-001)', () {
    test(
      'after login a pending re-acceptance asks for the prompt once',
      () async {
        final api = _ScriptedApi(getResponse: ApiResponse(200, _legal()));
        final provider = LegalAcceptanceProvider(apiClient: api);
        addTearDown(provider.dispose);

        await provider.refresh();
        expect(api.gets, ['/users/me/legal-acceptance']);
        expect(provider.reacceptanceRequired, isTrue);
        expect(provider.takePrompt(), isTrue);
        expect(provider.takePrompt(), isFalse);

        await provider.refresh();
        expect(provider.promptPending, isFalse);
      },
    );

    test('an account already up to date is never prompted', () async {
      final provider = LegalAcceptanceProvider(
        apiClient: _ScriptedApi(
          getResponse: ApiResponse(
            200,
            _legal(
              acceptedTerms: currentTermsVersion,
              acceptedPrivacy: currentPrivacyVersion,
              required: false,
            ),
          ),
        ),
      );
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.reacceptanceRequired, isFalse);
      expect(provider.promptPending, isFalse);
    });

    test('every blocked write asks for the prompt again', () {
      final provider = LegalAcceptanceProvider(apiClient: _ScriptedApi());
      addTearDown(provider.dispose);

      provider.markRequiredFromBody({
        'error': 'legal_acceptance_required',
        ..._legal(),
      });
      expect(provider.takePrompt(), isTrue);

      provider.markRequiredFromBody({'error': 'legal_acceptance_required'});
      expect(provider.reacceptanceRequired, isTrue);
      expect(provider.takePrompt(), isTrue);
    });

    test('accepting sends the exact versions bundled in the app', () async {
      final api = _ScriptedApi(
        postResponse: ApiResponse(
          200,
          _legal(
            acceptedTerms: currentTermsVersion,
            acceptedPrivacy: currentPrivacyVersion,
            required: false,
          ),
        ),
      );
      final provider = LegalAcceptanceProvider(apiClient: api)
        ..markRequiredFromBody(_legal());
      addTearDown(provider.dispose);

      expect(await provider.accept(), isTrue);

      expect(api.posts.single, {
        'endpoint': '/users/me/legal-acceptance',
        'legal_accepted': true,
        'terms_version': currentTermsVersion,
        'privacy_version': currentPrivacyVersion,
      });
      expect(provider.reacceptanceRequired, isFalse);
      expect(provider.promptPending, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test(
      'a newer server text asks to update the app, never accepts blindly',
      () async {
        final provider = LegalAcceptanceProvider(
          apiClient: _ScriptedApi(
            postResponse: ApiResponse(400, {
              'error': 'legal_acceptance_required',
              'message': 'Aceite a versão atual.',
              ..._legal(currentTerms: '2099-01-01'),
            }),
          ),
        );
        addTearDown(provider.dispose);

        expect(await provider.accept(), isFalse);
        expect(provider.errorMessage, contains('Atualize o app'));
        expect(provider.isSubmitting, isFalse);
      },
    );

    test('a failed status read keeps the state and asks nothing', () async {
      final provider = LegalAcceptanceProvider(
        apiClient: _ScriptedApi(getResponse: ApiResponse(503, const {})),
      );
      addTearDown(provider.dispose);

      await provider.refresh();

      expect(provider.status, isNull);
      expect(provider.promptPending, isFalse);
    });

    test('reset forgets the previous account', () async {
      final provider = LegalAcceptanceProvider(
        apiClient: _ScriptedApi(getResponse: ApiResponse(200, _legal())),
      );
      addTearDown(provider.dispose);
      await provider.refresh();

      provider.reset();

      expect(provider.status, isNull);
      expect(provider.promptPending, isFalse);
      await provider.refresh();
      expect(provider.promptPending, isTrue);
    });
  });

  group('ApiClient legal acceptance hook', () {
    tearDown(() => ApiClient.resetForTesting(performanceUnavailable: true));

    test('a 403 legal_acceptance_required reaches the app handler', () async {
      ApiClient.resetForTesting(
        performanceUnavailable: true,
        token: 'token',
        httpClient: MockClient((request) async {
          final blocked = request.url.path == '/decks';
          return http.Response(
            jsonEncode(
              blocked
                  ? {'error': 'legal_acceptance_required', ..._legal()}
                  : {'error': 'capability_unavailable'},
            ),
            403,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );
      final bodies = <Object?>[];
      ApiClient.setLegalAcceptanceRequiredHandler(bodies.add);

      final blocked = await ApiClient().post('/decks', const {'name': 'x'});
      await ApiClient().get('/notifications');

      expect(blocked.statusCode, 403);
      expect(bodies, hasLength(1));
      expect((bodies.single as Map)['error'], 'legal_acceptance_required');
    });
  });
}
