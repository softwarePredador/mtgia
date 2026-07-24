import 'dart:async';

import 'package:web/web.dart' as web;

const _phaseAttribute = 'data-manaloom-image-memory-phase';
const _ackAttribute = 'data-manaloom-image-memory-ack';
const _readyAttribute = 'data-manaloom-image-memory-cdp-ready';
const _errorAttribute = 'data-manaloom-image-memory-probe-error';

void markWebImageMemoryPhase(String phase) {
  final root = web.document.documentElement;
  if (root == null) return;
  root
    ..removeAttribute(_ackAttribute)
    ..setAttribute(_phaseAttribute, phase);
}

Future<bool> waitForWebImageMemoryProbeReady({
  Duration timeout = const Duration(seconds: 20),
}) => _waitForAttribute(_readyAttribute, '1', timeout: timeout);

Future<bool> waitForWebImageMemoryCheckpoint(
  String phase, {
  Duration timeout = const Duration(seconds: 20),
}) => _waitForAttribute(_ackAttribute, phase, timeout: timeout);

Future<bool> _waitForAttribute(
  String name,
  String expected, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final root = web.document.documentElement;
    if (root?.getAttribute(_errorAttribute)?.isNotEmpty ?? false) {
      return false;
    }
    if (root?.getAttribute(name) == expected) {
      return true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return false;
}
