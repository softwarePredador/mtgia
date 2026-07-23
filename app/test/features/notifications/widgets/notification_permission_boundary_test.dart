import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/notifications/widgets/notification_permission_boundary.dart';

void main() {
  testWidgets('requests permission once after the notification surface opens', (
    tester,
  ) async {
    var requests = 0;

    await tester.pumpWidget(
      NotificationPermissionBoundary(
        requestPermission: () async {
          requests++;
        },
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('notifications'),
        ),
      ),
    );
    expect(requests, 1);
    expect(find.text('notifications'), findsOneWidget);

    await tester.pump();
    expect(requests, 1);
  });
}
