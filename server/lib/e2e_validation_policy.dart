import 'dart:io';

const manaloomE2eIsolatedRuntimeEnvironment = 'MANALOOM_E2E_ISOLATED_RUNTIME';
const manaloomE2eValidationRunTokenEnvironment =
    'MANALOOM_E2E_VALIDATION_RUN_TOKEN';
const manaloomEnableProductLearningWritesEnvironment =
    'MANALOOM_ENABLE_PRODUCT_LEARNING_WRITES';

bool isManaloomE2eIsolatedRuntime({Map<String, String>? environment}) {
  final resolvedEnvironment = environment ?? Platform.environment;
  if (resolvedEnvironment[manaloomE2eIsolatedRuntimeEnvironment]?.trim() !=
      '1') {
    return false;
  }
  final token =
      resolvedEnvironment[manaloomE2eValidationRunTokenEnvironment]?.trim() ??
      '';
  return RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(token);
}

bool shouldWriteProductLearning({Map<String, String>? environment}) {
  final resolvedEnvironment = environment ?? Platform.environment;

  // Product-learning writes stay fail-closed until the promotion and consent
  // boundary has its own reviewed receipt. An isolated E2E request suppresses
  // them even when its token is missing or malformed: a broken harness must
  // never fall through to product learning.
  if (resolvedEnvironment[manaloomE2eIsolatedRuntimeEnvironment]?.trim() ==
      '1') {
    return false;
  }

  return resolvedEnvironment[manaloomEnableProductLearningWritesEnvironment]
          ?.trim() ==
      '1';
}

bool shouldRunGlobalHousekeeping({Map<String, String>? environment}) =>
    !isManaloomE2eIsolatedRuntime(environment: environment);
