import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    testWidgets('AppTheme constants and static methods', (tester) async {
      // 1. TextStyles
      expect(AppTheme.headingLg.fontSize, 24);
      expect(AppTheme.headingMd.fontSize, 18);
      expect(AppTheme.bodyLg.fontSize, 14);
      expect(AppTheme.bodyMd.fontSize, 13);
      expect(AppTheme.labelMd.fontSize, 12);

      // 2. ThemeData
      final theme = AppTheme.light;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, isNotNull);

      // 3. Breakpoints
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              AppTheme.isMobile(context);
              AppTheme.isTablet(context);
              AppTheme.isDesktop(context);
              return const SizedBox();
            },
          ),
        ),
      );

      // 4. Decorations
      final inputDeco = AppTheme.inputDecoration(label: 'Test', icon: Icons.person);
      expect(inputDeco.labelText, 'Test');

      final cardDecoNormal = AppTheme.cardDecoration(isHovered: false);
      final cardDecoHover = AppTheme.cardDecoration(isHovered: true);
      expect(cardDecoNormal.boxShadow!.first.blurRadius, 16);
      expect(cardDecoHover.boxShadow!.first.blurRadius, 24);

      // 5. Buttons
      final primaryBtn = AppTheme.primaryButtonStyle(isLoading: false);
      expect(primaryBtn, isNotNull);
      final secondaryBtn = AppTheme.secondaryButtonStyle();
      expect(secondaryBtn, isNotNull);

      // 6. Snackbars
      final successSnack = AppTheme.successSnackBar('Success');
      expect(successSnack.backgroundColor, isNotNull);
      final errorSnack = AppTheme.errorSnackBar('Error');
      expect(errorSnack.duration, const Duration(seconds: 5));
      final infoSnack = AppTheme.infoSnackBar('Info');
      expect(infoSnack.backgroundColor, isNotNull);
    });

    testWidgets('AppTheme Widgets render correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AppTheme.badge(label: 'Badge', bgColor: Colors.red, textColor: Colors.white),
                  AppTheme.emptyState(icon: Icons.inbox, title: 'Empty', subtitle: 'Nothing here'),
                  AppTheme.loadingState(message: 'Loading...'),
                  AppTheme.errorState('Error occurred', onRetry: () {}),
                  AppTheme.glowCircle(color: Colors.blue, size: 50),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Badge'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
