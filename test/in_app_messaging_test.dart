import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sora/app/core/models/in_app_message_model.dart';
import 'package:sora/app/core/widgets/in_app_message_presenter.dart';

void main() {
  group('InAppMessageModel', () {
    test('parses campaign values and colors', () {
      final message = InAppMessageModel.fromJson({
        'id': 12,
        'type': 'card',
        'title': 'Offer',
        'body': 'Body',
        'background_color': '#112233',
        'text_color': '#FFFFFF',
        'button_color': '#B09263',
        'button_text_color': '#000000',
        'target_platform': 'all',
        'target_language': 'all',
        'starts_at': '2026-07-17T00:00:00Z',
      });

      expect(message.type, InAppMessageType.card);
      expect(message.backgroundColor, const Color(0xFF112233));
      expect(message.buttonColor, const Color(0xFFB09263));
      expect(message.displayOnce, isTrue);
    });

    test('validates six-digit hex colors', () {
      expect(isValidHexColor('#B09263'), isTrue);
      expect(isValidHexColor('B09263'), isFalse);
      expect(isValidHexColor('#FFF'), isFalse);
    });
  });

  for (final type in InAppMessageType.values) {
    testWidgets('${type.label} message renders', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final message = InAppMessageModel(
        id: type.index + 1,
        type: type,
        title: 'Campaign title',
        body: 'A short campaign message for active Sora users.',
        imageUrl: type == InAppMessageType.image
            ? 'https://invalid.test/campaign.jpg'
            : '',
        backgroundColor: Colors.white,
        textColor: const Color(0xFF171717),
        buttonColor: const Color(0xFFB09263),
        buttonTextColor: Colors.white,
        primaryButtonText: 'Open',
        primaryActionUrl: '/item/1',
        secondaryButtonText: 'Not now',
        secondaryActionUrl: '',
        targetPlatform: 'all',
        targetLanguage: 'all',
        displayOnce: true,
        isActive: true,
        startsAt: DateTime.utc(2026, 7, 17),
        endsAt: null,
      );

      late BuildContext hostContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );

      InAppMessagePresenter.show(
        context: hostContext,
        message: message,
        onAction: (_) async {},
      );
      await tester.pump();

      if (type == InAppMessageType.image) {
        expect(find.byIcon(Icons.close), findsOneWidget);
      } else {
        expect(find.text('Campaign title'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      if (type == InAppMessageType.banner) {
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
      }
    });
  }
}
