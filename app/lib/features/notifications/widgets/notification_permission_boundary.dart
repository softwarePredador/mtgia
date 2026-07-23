import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/services/push_notification_service.dart';

typedef NotificationPermissionRequest = Future<void> Function();

class NotificationPermissionBoundary extends StatefulWidget {
  const NotificationPermissionBoundary({
    super.key,
    required this.child,
    this.requestPermission,
  });

  final Widget child;
  final NotificationPermissionRequest? requestPermission;

  @override
  State<NotificationPermissionBoundary> createState() =>
      _NotificationPermissionBoundaryState();
}

class _NotificationPermissionBoundaryState
    extends State<NotificationPermissionBoundary> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        (widget.requestPermission ??
            PushNotificationService().requestPermissionAndRegister)(),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
