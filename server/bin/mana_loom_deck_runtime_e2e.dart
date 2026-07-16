#!/usr/bin/env dart

import 'dart:io';

import 'run_commander_only_optimization_validation.dart'
    as commander_only_validation;

const _liveMutationApprovalEnvironment = 'MANALOOM_CONFIRM_LIVE_MUTATIONS';
const _explicitApprovalPhrase = 'I_HAVE_EXPLICIT_APPROVAL';

Future<void> main(List<String> args) {
  final config = commander_only_validation.RuntimeValidationConfig.parse(args);
  if (config.apply &&
      Platform.environment[_liveMutationApprovalEnvironment] !=
          _explicitApprovalPhrase) {
    stderr.writeln(
      'BLOCKED: o wrapper deck runtime E2E mutavel exige aprovacao live '
      'explicita.',
    );
    stderr.writeln(
      'Defina $_liveMutationApprovalEnvironment=$_explicitApprovalPhrase '
      'somente para a execucao autorizada.',
    );
    exitCode = 2;
    return Future<void>.value();
  }
  return commander_only_validation.main(args);
}
