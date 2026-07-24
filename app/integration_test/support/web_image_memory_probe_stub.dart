import 'dart:async';

void markWebImageMemoryPhase(String phase) {}

Future<bool> waitForWebImageMemoryProbeReady({
  Duration timeout = const Duration(seconds: 20),
}) async => false;

Future<bool> waitForWebImageMemoryCheckpoint(
  String phase, {
  Duration timeout = const Duration(seconds: 20),
}) async => false;
