import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/run_three_commander_resolution_validation.dart'
    as resolution_runner;

void main() {
  group('resolution corpus read-only preflight', () {
    test(
      'selects the corpus before authenticating or creating validation data',
      () {
        final source =
            File(
              'bin/run_three_commander_resolution_validation.dart',
            ).readAsStringSync();
        final mainSource = source.substring(
          source.indexOf('Future<void> main() async {'),
          source.indexOf('Future<ResolutionRunResult> _runResolutionForDeck'),
        );
        final registration = mainSource.indexOf('_registerValidationUser(');
        final approval = mainSource.indexOf('_hasPostgresWriteApproval()');

        expect(mainSource, contains("env['VALIDATION_PREFLIGHT_ONLY']"));
        expect(
          mainSource.indexOf('final candidates = await _loadSourceCandidates('),
          lessThan(registration),
        );
        expect(mainSource.indexOf('if (preflightOnly)'), lessThan(approval));
        expect(approval, greaterThanOrEqualTo(0));
        expect(approval, lessThan(registration));
        expect(
          mainSource.indexOf('_ensureServerIsReachable(apiBaseUrl)'),
          greaterThan(approval),
        );
        expect(source, contains('MANALOOM_CONFIRM_POSTGRES_WRITES'));
        expect(source, contains('I_HAVE_EXPLICIT_APPROVAL'));
      },
    );

    test(
      'quality gate executes preflight before probing or starting the API',
      () {
        final source =
            File(
              '../scripts/quality_gate_resolution_corpus.sh',
            ).readAsStringSync();

        expect(source, contains('VALIDATION_PREFLIGHT_ONLY=1'));
        final externalPreflightGate = source.indexOf(
          'case "\${VALIDATION_PREFLIGHT_ONLY:-0}" in',
        );
        final writeApprovalGate = source.indexOf(
          'require_postgres_write_approval "Commander resolution corpus mutating E2E"',
        );
        final apiReadyBranch = source.indexOf('if api_ready; then');
        expect(externalPreflightGate, greaterThanOrEqualTo(0));
        expect(writeApprovalGate, greaterThan(externalPreflightGate));
        expect(apiReadyBranch, greaterThan(externalPreflightGate));
        expect(
          source.substring(externalPreflightGate, apiReadyBranch),
          allOf(contains('1|true|TRUE|yes|YES)'), contains('exit 0')),
        );
        expect(
          source.indexOf('print_header "Preflight read-only do corpus"'),
          lessThan(apiReadyBranch),
        );
        expect(writeApprovalGate, lessThan(apiReadyBranch));
        expect(
          source,
          contains(
            r'source "$ROOT_DIR/scripts/lib/manaloom_mutation_guard.sh"',
          ),
        );
      },
    );

    test('mutating gate owns a collision-safe isolated loopback runtime', () {
      final source =
          File(
            '../scripts/quality_gate_resolution_corpus.sh',
          ).readAsStringSync();

      expect(source, contains('RUN_NONCE='));
      expect(source, contains('REQUESTED_VALIDATION_LIMIT='));
      expect(source, contains(r'CORPUS_COUNT="$(resolve_corpus_count)"'));
      expect(source, contains('REQUESTED_VALIDATION_LIMIT > CORPUS_COUNT'));
      expect(source, contains(r'${RUN_STAMP}_$$_${RUN_NONCE}'));
      expect(source, contains('/tmp/manaloom_resolution_corpus/'));
      expect(source, contains('REQUESTED_API_BASE_URL'));
      expect(source, contains('API_BASE_URL="http://127.0.0.1:\${PORT}"'));
      expect(source, contains(r'select_free_local_port "$PORT" 30'));
      expect(source, contains('Iniciando API isolada'));
      expect(
        source,
        contains(r'"$ROOT_DIR/server/bin/with_new_server_pg.sh" env'),
      );
      expect(source, contains('for required_tool in script lsof'));
      expect(source, contains('payload.get("status") != "ready"'));
      expect(source, contains('payload.get("service") != "mtgia-server"'));
      expect(source, contains('VALIDATION_SUMMARY_JSON_ABS='));
      expect(source, contains(r'if [[ "$path" == /* ]]'));
      expect(source, contains(r'python3 - "$VALIDATION_SUMMARY_JSON_ABS"'));
      expect(
        source,
        isNot(
          contains(r'python3 - "$SERVER_DIR/$VALIDATION_SUMMARY_JSON_PATH"'),
        ),
      );
      expect(source, contains(r'VALIDATION_RUN_TOKEN="$RUN_TOKEN"'));
      expect(source, contains("POSITION(:'validation_run_token' IN name)"));
      expect(source, contains('mock_responses != 0'));
      expect(source, contains('mock_non_actionable != 0'));
      expect(source, contains('contract_rejected != 0'));
      expect(source, contains('direct_optimizations <= 0'));
      expect(source, contains('actionable_swap_pairs <= 0'));
      expect(source, contains('contract_accepted != direct_optimizations'));
      expect(source, contains('unknown_origin_results != 0'));
      expect(source, contains('runtime_origin_total != total'));
      expect(source, isNot(contains('provider_calls <= 0')));

      final serverStart = source.indexOf(r'SERVER_PID="$!"');
      final readinessPoll = source.indexOf('if api_ready; then', serverStart);
      expect(serverStart, greaterThanOrEqualTo(0));
      expect(readinessPoll, greaterThan(serverStart));
    });

    test(
      'runner arms exact cleanup before registration and always closes DB',
      () {
        final source =
            File(
              'bin/run_three_commander_resolution_validation.dart',
            ).readAsStringSync();
        final mainSource = source.substring(
          source.indexOf('Future<void> main() async {'),
          source.indexOf('Future<ResolutionRunResult> _runResolutionForDeck'),
        );

        final identityCheck = mainSource.indexOf(
          '_assertValidationIdentityIsUnused(',
        );
        final cleanupArmed = mainSource.indexOf('cleanupRequired = true;');
        final registration = mainSource.indexOf('_registerValidationUser(');
        final cleanup = mainSource.indexOf('_cleanupValidationUser(');
        final close = mainSource.indexOf('await db.close();');

        expect(identityCheck, greaterThanOrEqualTo(0));
        expect(cleanupArmed, greaterThan(identityCheck));
        expect(registration, greaterThan(cleanupArmed));
        expect(cleanup, greaterThan(registration));
        expect(close, greaterThan(cleanup));
        expect(mainSource, isNot(contains('if (authSession != null)')));
        expect(
          source,
          contains('LOWER(email) = @email AND LOWER(username) = @username'),
        );
        expect(source, contains("payload['status'] == 'ready'"));
        expect(source, contains("payload['service'] == 'mtgia-server'"));
        expect(
          source,
          contains(
            "'Resolution Validation - \$_validationRunToken - \${candidate.commanderName}",
          ),
        );
      },
    );

    test('summary writers create parents for relative and absolute paths', () {
      final source =
          File(
            'bin/run_three_commander_resolution_validation.dart',
          ).readAsStringSync();
      final mainSource = source.substring(
        source.indexOf('Future<void> main() async {'),
        source.indexOf('Future<ResolutionRunResult> _runResolutionForDeck'),
      );
      final writerSource = source.substring(
        source.indexOf('Future<void> _writeTextArtifact'),
        source.indexOf('int _totalCards'),
      );

      expect(
        mainSource,
        contains('_writeTextArtifact(\n      _summaryJsonPath,'),
      );
      expect(mainSource, contains('_writeTextArtifact(_summaryMdPath,'));
      expect(writerSource, contains('final file = File(path);'));
      expect(writerSource, contains('file.parent.create(recursive: true)'));
      expect(writerSource, contains('file.writeAsString(contents)'));
    });

    test(
      'registration consumes its returned token without a login fallback',
      () {
        final source =
            File(
              'bin/run_three_commander_resolution_validation.dart',
            ).readAsStringSync();
        final registrationSource = source.substring(
          source.indexOf(
            'Future<ValidationAuthSession> _registerValidationUser',
          ),
          source.indexOf('Future<void> _cleanupValidationUser'),
        );

        expect(
          registrationSource,
          contains("Uri.parse('\$apiBaseUrl/auth/register')"),
        );
        expect(
          registrationSource,
          contains('response.statusCode != HttpStatus.created'),
        );
        expect(registrationSource, contains("decoded['token']?.toString()"));
        expect(
          registrationSource,
          contains('return ValidationAuthSession(token: token);'),
        );
        expect(registrationSource, isNot(contains('/auth/login')));
      },
    );

    test('persistent telemetry is measured and never deleted by the gate', () {
      final source =
          File(
            '../scripts/quality_gate_resolution_corpus.sh',
          ).readAsStringSync();
      const telemetryTables = <String>[
        'ai_optimize_cache',
        'ai_optimize_fallback_telemetry',
        'ml_prompt_feedback',
        'optimization_analysis_logs',
        'ai_logs',
        'rate_limit_events',
      ];

      expect(source, contains('persistent_telemetry_snapshot'));
      expect(source, contains('rows_created_in_window'));
      expect(source, contains('"measurement_scope"'));
      expect(source, contains('"limitation"'));
      expect(source, contains('ON CONFLICT updates'));
      expect(source, contains('"telemetry_deleted": False'));
      for (final table in telemetryTables) {
        expect(source, contains("'$table'"), reason: table);
        expect(
          source.toUpperCase(),
          isNot(contains('DELETE FROM ${table.toUpperCase()}')),
          reason: table,
        );
      }
    });

    test('fixture keeps 19 valid UUID-shaped stable corpus entries', () {
      final decoded =
          jsonDecode(
                File(
                  'test/fixtures/optimization_resolution_corpus.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final decks = (decoded['decks'] as List).cast<Map<String, dynamic>>();
      final ids = decks.map((deck) => deck['deck_id'].toString()).toList();
      final flowContracts =
          decks
              .map((deck) => deck['expected_flow_contract']?.toString())
              .toList();
      final uuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      );

      expect(decks, hasLength(19));
      expect(ids.toSet(), hasLength(19));
      expect(ids, everyElement(matches(uuid)));
      expect(flowContracts, everyElement(equals('runtime_terminal_non_mock')));
      expect(
        decks,
        everyElement(isNot(contains('provider_backed_flow_unverified'))),
      );
      expect(
        ids,
        containsAll(const [
          '104cbd8c-6877-4551-9c4f-c0742f1760ad',
          '458a8df7-afde-4232-b4da-e1ce8e9fbb0c',
          '2070158d-5aa0-4918-9325-5f1eff41d359',
          '86cfa127-c737-43d7-aec9-b41d1668880e',
          '6cfa4644-16a6-4070-9e73-619acc5e77e3',
          '764ce781-7fd9-44b2-839e-8ea563f0006f',
        ]),
      );
    });
  });

  group('resolution optimize outcome contract', () {
    Map<String, dynamic> actionableResponse({
      Object? isMock,
      Object? canApply,
      Object? learningEligible,
    }) {
      return {
        'outcome_code': 'optimized',
        if (isMock != null) 'is_mock': isMock,
        if (canApply != null) 'can_apply': canApply,
        if (learningEligible != null) 'learning_eligible': learningEligible,
        'removals': ['Old Card'],
        'additions': ['New Card'],
        'removals_detailed': <Map<String, dynamic>>[
          {'name': 'Old Card', 'card_id': 'old-card-id', 'quantity': 1},
        ],
        'additions_detailed': <Map<String, dynamic>>[
          {'name': 'New Card', 'card_id': 'new-card-id', 'quantity': 1},
        ],
      };
    }

    Map<String, dynamic> twoPairResponse() => {
      'outcome_code': 'optimized',
      'removals': ['Old Card', 'Older Card'],
      'additions': ['New Card', 'Newer Card'],
      'removals_detailed': <Map<String, dynamic>>[
        {'name': 'Old Card', 'card_id': 'old-card-id', 'quantity': 1},
        {'name': 'Older Card', 'card_id': 'older-card-id', 'quantity': 1},
      ],
      'additions_detailed': <Map<String, dynamic>>[
        {'name': 'New Card', 'card_id': 'new-card-id', 'quantity': 1},
        {'name': 'Newer Card', 'card_id': 'newer-card-id', 'quantity': 1},
      ],
    };

    test(
      'accepts balanced actionable response when optional flags are absent',
      () {
        final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
          httpStatus: HttpStatus.ok,
          responseBody: actionableResponse(),
        );

        expect(evidence.directApplyAccepted, isTrue);
        expect(evidence.rejectionReasons, isEmpty);
        expect(evidence.isMock, isNull);
        expect(evidence.canApply, isNull);
        expect(evidence.learningEligible, isNull);
        expect(evidence.removalCount, 1);
        expect(evidence.additionCount, 1);
        expect(evidence.actionableSwapCount, 1);
        expect(evidence.toJson(), containsPair('direct_apply_accepted', true));
      },
    );

    for (final flag in const ['is_mock', 'can_apply', 'learning_eligible']) {
      test('rejects present non-bool $flag while allowing absence', () {
        final response = actionableResponse()..[flag] = 'false';
        final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
          httpStatus: HttpStatus.ok,
          responseBody: response,
        );

        expect(evidence.directApplyAccepted, isFalse);
        expect(evidence.rejectionReasons, contains('${flag}_not_bool'));
      });
    }

    test('rejects mock and explicitly non-actionable HTTP 200 response', () {
      final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
        httpStatus: HttpStatus.ok,
        responseBody: const {
          'outcome_code': 'mock_non_actionable',
          'is_mock': true,
          'can_apply': false,
          'learning_eligible': false,
          'removals': <String>[],
          'additions': <String>[],
        },
      );

      expect(evidence.directApplyAccepted, isFalse);
      expect(
        evidence.rejectionReasons,
        containsAll(const [
          'mock_response',
          'can_apply_false',
          'learning_eligible_false',
          'mock_non_actionable_outcome',
          'no_recommendation_pairs',
        ]),
      );
      expect(evidence.actionableSwapCount, 0);
    });

    test('rejects unbalanced recommendation pairs', () {
      final response =
          actionableResponse()
            ..['removals'] = ['Old Card', 'Another Old Card']
            ..['removals_detailed'] = [
              {'name': 'Old Card', 'card_id': 'old-card-id', 'quantity': 1},
              {
                'name': 'Another Old Card',
                'card_id': 'another-old-card-id',
                'quantity': 1,
              },
            ];
      final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
        httpStatus: HttpStatus.ok,
        responseBody: response,
      );

      expect(evidence.directApplyAccepted, isFalse);
      expect(
        evidence.rejectionReasons,
        contains('unbalanced_recommendation_pairs'),
      );
    });

    test('rejects balanced names without details the runner can apply', () {
      final response =
          actionableResponse()
            ..['removals_detailed'] = <Map<String, dynamic>>[]
            ..['additions_detailed'] = <Map<String, dynamic>>[];
      final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
        httpStatus: HttpStatus.ok,
        responseBody: response,
      );

      expect(evidence.directApplyAccepted, isFalse);
      expect(
        evidence.rejectionReasons,
        contains('recommendation_details_not_actionable'),
      );
    });

    for (final side in const ['removal', 'addition']) {
      final rawKey = side == 'removal' ? 'removals' : 'additions';
      final detailedKey =
          side == 'removal' ? 'removals_detailed' : 'additions_detailed';

      test('rejects $side raw/detailed name multiset mismatch', () {
        final response = actionableResponse();
        final details = (response[detailedKey] as List).cast<Map>();
        details.first['name'] = 'Different Card';
        final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
          httpStatus: HttpStatus.ok,
          responseBody: response,
        );

        expect(evidence.directApplyAccepted, isFalse);
        expect(
          evidence.rejectionReasons,
          contains('${side}_raw_detail_name_mismatch'),
        );
        expect(response[rawKey], isNotEmpty);
      });

      test('rejects missing card_id in $side details', () {
        final response = actionableResponse();
        final details = (response[detailedKey] as List).cast<Map>();
        details.first.remove('card_id');
        final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
          httpStatus: HttpStatus.ok,
          responseBody: response,
        );

        expect(evidence.directApplyAccepted, isFalse);
        expect(
          evidence.rejectionReasons,
          contains('recommendation_details_not_actionable'),
        );
      });

      for (final invalidQuantity in const <Object?>[null, 2, 1.0]) {
        test('rejects quantity=$invalidQuantity in $side details', () {
          final response = actionableResponse();
          final details = (response[detailedKey] as List).cast<Map>();
          details.first['quantity'] = invalidQuantity;
          final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
            httpStatus: HttpStatus.ok,
            responseBody: response,
          );

          expect(evidence.directApplyAccepted, isFalse);
          expect(
            evidence.rejectionReasons,
            contains('recommendation_details_not_actionable'),
          );
        });
      }

      test('rejects duplicate $side names', () {
        final response = twoPairResponse();
        final raw = (response[rawKey] as List).cast<String>();
        final details = (response[detailedKey] as List).cast<Map>();
        raw[1] = raw.first;
        details[1]['name'] = details.first['name'];
        final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
          httpStatus: HttpStatus.ok,
          responseBody: response,
        );

        expect(evidence.directApplyAccepted, isFalse);
        expect(evidence.rejectionReasons, contains('duplicate_${side}_names'));
      });

      test('rejects duplicate $side card ids', () {
        final response = twoPairResponse();
        final details = (response[detailedKey] as List).cast<Map>();
        details[1]['card_id'] = details.first['card_id'];
        final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
          httpStatus: HttpStatus.ok,
          responseBody: response,
        );

        expect(evidence.directApplyAccepted, isFalse);
        expect(
          evidence.rejectionReasons,
          contains('duplicate_${side}_card_ids'),
        );
      });
    }

    test('rejects removal/addition overlap by normalized name', () {
      final response = actionableResponse();
      (response['additions'] as List).first = ' OLD CARD ';
      ((response['additions_detailed'] as List).first as Map)['name'] =
          'old card';
      final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
        httpStatus: HttpStatus.ok,
        responseBody: response,
      );

      expect(evidence.directApplyAccepted, isFalse);
      expect(
        evidence.rejectionReasons,
        contains('overlapping_recommendation_names'),
      );
    });

    test('rejects removal/addition overlap by normalized card id', () {
      final response = actionableResponse();
      ((response['additions_detailed'] as List).first as Map)['card_id'] =
          ' OLD-CARD-ID ';
      final evidence = resolution_runner.assessOptimizeOutcomeEvidence(
        httpStatus: HttpStatus.ok,
        responseBody: response,
      );

      expect(evidence.directApplyAccepted, isFalse);
      expect(
        evidence.rejectionReasons,
        contains('overlapping_recommendation_card_ids'),
      );
    });

    test('deck signature is order independent and detects a real swap', () {
      final before = <Map<String, dynamic>>[
        {
          'card_id': 'commander-id',
          'name': 'Commander',
          'quantity': 1,
          'is_commander': true,
        },
        {'card_id': 'old-card-id', 'name': 'Old Card', 'quantity': 1},
      ];
      final reordered = <Map<String, dynamic>>[
        {'name': 'Old Card', 'quantity': 1, 'card_id': 'OLD-CARD-ID'},
        {
          'quantity': 1,
          'is_commander': true,
          'name': 'Commander',
          'card_id': 'COMMANDER-ID',
        },
      ];
      final proposed = <Map<String, dynamic>>[
        before.first,
        {'card_id': 'new-card-id', 'name': 'New Card', 'quantity': 1},
      ];

      expect(
        resolution_runner.buildResolutionDeckSignature(before),
        resolution_runner.buildResolutionDeckSignature(reordered),
      );
      expect(
        resolution_runner.buildResolutionDeckSignature(proposed),
        isNot(resolution_runner.buildResolutionDeckSignature(before)),
      );
    });

    test('runner wires rejected HTTP 200 to unresolved summary evidence', () {
      final source =
          File(
            'bin/run_three_commander_resolution_validation.dart',
          ).readAsStringSync();
      final runSource = source.substring(
        source.indexOf('Future<ResolutionRunResult> _runResolutionForDeck'),
        source.indexOf('Future<bool> _ensureServerIsReachable'),
      );

      expect(runSource, contains("String flowPath = 'unresolved_rejection';"));
      expect(runSource, contains('optimizeOutcome.directApplyAccepted'));
      final proposalChanged = runSource.indexOf(
        'optimizeProposalChangedDeck = beforeSignature != proposedSignature;',
      );
      final putRequest = runSource.indexOf(
        'final putResponse = await http.put(',
      );
      final persistedReload = runSource.indexOf(
        'final persistedCards = await _loadDeckCards(pool, cloneDeckId);',
      );
      final persistedConfirmation = runSource.indexOf(
        'persistedSignature == proposedSignature',
      );
      final optimizedDirectly = runSource.indexOf(
        "flowPath = 'optimized_directly';",
      );
      expect(proposalChanged, greaterThanOrEqualTo(0));
      expect(putRequest, greaterThan(proposalChanged));
      expect(persistedReload, greaterThan(putRequest));
      expect(persistedConfirmation, greaterThan(persistedReload));
      expect(optimizedDirectly, greaterThan(persistedConfirmation));
      expect(
        runSource.substring(persistedReload, optimizedDirectly),
        contains('persistedSignature != beforeSignature'),
      );
      expect(
        runSource,
        contains("'optimize_outcome': optimizeOutcome.toJson()"),
      );
      expect(
        runSource,
        contains(
          "'persisted_signature_confirmed': optimizePersistedDeckConfirmed",
        ),
      );
      expect(
        runSource,
        contains(
          "'query_scope': 'ai_logs deck_id + endpoint optimize + run window'",
        ),
      );
      expect(
        runSource,
        contains(
          "candidate.expectedFlowContract == 'runtime_terminal_non_mock'",
        ),
      );
      expect(source, contains("'contract_rejected_http_200':"));
      expect(source, contains("'mock_non_actionable_outcomes':"));
      expect(source, contains("'candidate_swap_pairs':"));
      expect(source, contains("'rejected_candidate_swap_pairs':"));
      expect(source, contains("'provider_evidence_summary':"));
      expect(source, contains("'runtime_provenance_summary':"));
      expect(runSource, contains('qualifiesAsSafeNoChangeOutcome('));
      expect(runSource, contains("runtimeOrigin != 'unknown'"));
    });

    test(
      'runtime origin is explicit and does not invent provider evidence',
      () {
        final providerCall = resolution_runner.ProviderCallEvidence(
          id: 'log-1',
          endpoint: 'optimize',
          model: 'gpt-test',
          success: true,
          inputTokens: 10,
          outputTokens: 5,
          latencyMs: 20,
          createdAt: DateTime.utc(2026, 7, 15),
        );

        expect(
          resolution_runner.classifyResolutionRuntimeOrigin(
            strategySource: 'ai_primary',
            cacheHit: false,
            providerCalls: [providerCall],
          ),
          'provider',
        );
        expect(
          resolution_runner.classifyResolutionRuntimeOrigin(
            strategySource: 'deterministic_first',
            cacheHit: false,
            providerCalls: const [],
          ),
          'deterministic',
        );
        expect(
          resolution_runner.classifyResolutionRuntimeOrigin(
            strategySource: 'state_gate',
            cacheHit: false,
            providerCalls: const [],
          ),
          'state_gate',
        );
        expect(
          resolution_runner.classifyResolutionRuntimeOrigin(
            strategySource: 'ai_primary',
            cacheHit: true,
            providerCalls: [providerCall],
          ),
          'cache',
        );
        expect(
          resolution_runner.classifyResolutionRuntimeOrigin(
            strategySource: 'ai_primary',
            cacheHit: false,
            providerCalls: const [],
          ),
          'unknown',
        );
      },
    );

    test(
      'safe no-change accepts quality rejections, not execution failures',
      () {
        expect(
          resolution_runner.qualifiesAsSafeNoChangeOutcome(
            httpStatus: HttpStatus.unprocessableEntity,
            outcomeCode: 'no_safe_upgrade_found',
            qualityCode: 'OPTIMIZE_QUALITY_REJECTED',
            deckStateStatus: 'healthy',
          ),
          isTrue,
        );
        expect(
          resolution_runner.qualifiesAsSafeNoChangeOutcome(
            httpStatus: HttpStatus.unprocessableEntity,
            outcomeCode: 'no_safe_upgrade_found',
            qualityCode: 'OPTIMIZE_EXECUTION_FAILED',
            deckStateStatus: 'healthy',
          ),
          isFalse,
        );
        expect(
          resolution_runner.qualifiesAsSafeNoChangeOutcome(
            httpStatus: HttpStatus.internalServerError,
            outcomeCode: 'no_safe_upgrade_found',
            qualityCode: 'OPTIMIZE_QUALITY_REJECTED',
            deckStateStatus: 'healthy',
          ),
          isFalse,
        );
      },
    );
  });
}
