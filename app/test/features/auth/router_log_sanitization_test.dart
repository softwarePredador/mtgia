import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('router and login logs never interpolate redirect destinations', () {
    final routerSource = File('lib/main.dart').readAsStringSync();
    final loginSource =
        File('lib/features/auth/screens/login_screen.dart').readAsStringSync();

    expect(routerSource, isNot(contains('location=\$location')));
    expect(routerSource, isNot(contains('→ \$splashUri')));
    expect(routerSource, isNot(contains('→ \$loginLocation')));
    expect(routerSource, isNot(contains('→ \$target')));
    expect(routerSource, isNot(contains('→ \$fallbackPath')));
    expect(loginSource, isNot(contains('navegando para \$target')));
  });
}
