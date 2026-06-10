import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';

void main() {
  test('global widget tokens keep ManaLoom color hierarchy consistent', () {
    final theme = AppTheme.darkTheme;
    const selected = <WidgetState>{WidgetState.selected};
    const normal = <WidgetState>{};

    expect(theme.bottomNavigationBarTheme.selectedItemColor, AppTheme.brass500);
    expect(
      theme.bottomNavigationBarTheme.unselectedItemColor,
      AppTheme.textSecondary,
    );

    expect(theme.popupMenuTheme.color, AppTheme.surfaceElevated);
    expect(theme.listTileTheme.textColor, AppTheme.textPrimary);
    expect(theme.listTileTheme.iconColor, AppTheme.textSecondary);
    expect(theme.listTileTheme.selectedColor, AppTheme.brass400);

    expect(theme.switchTheme.thumbColor?.resolve(selected), AppTheme.brass400);
    expect(
      theme.switchTheme.thumbColor?.resolve(normal),
      AppTheme.textSecondary,
    );

    expect(theme.checkboxTheme.fillColor?.resolve(selected), AppTheme.brass500);
    expect(theme.radioTheme.fillColor?.resolve(selected), AppTheme.brass400);

    expect(
      theme.segmentedButtonTheme.style?.foregroundColor?.resolve(selected),
      AppTheme.brass400,
    );
    expect(
      theme.segmentedButtonTheme.style?.foregroundColor?.resolve(normal),
      AppTheme.textSecondary,
    );

    expect(theme.textSelectionTheme.cursorColor, AppTheme.brass400);
    expect(theme.textSelectionTheme.selectionHandleColor, AppTheme.brass400);
  });
}
