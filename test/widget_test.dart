import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/core/theme/app_theme.dart';

void main() {
  testWidgets('App shell builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
  });
}
