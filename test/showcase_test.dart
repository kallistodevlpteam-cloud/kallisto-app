import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kallisto_design_system/main.dart';
import 'package:kallisto_design_system/design_system/tokens.dart';
import 'package:kallisto_design_system/showcase/sections/buttons.dart';
import 'package:kallisto_design_system/showcase/sections/cards.dart';
import 'package:kallisto_design_system/showcase/sections/layouts.dart';
import 'package:kallisto_design_system/showcase/sections/forms.dart';
import 'package:kallisto_design_system/showcase/sections/data_display.dart';
import 'package:kallisto_design_system/showcase/sections/feedback.dart';
import 'package:kallisto_design_system/showcase/sections/motion.dart';

Future<void> surface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> specimen(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
  bool reduced = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: KTokens.theme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: tester.view.physicalSize,
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduced,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('Hanken Grotesk')
      ..addFont(rootBundle.load('assets/fonts/HankenGrotesk.ttf'));
    await loader.load();
  });
  testWidgets('All collections navigate on desktop and theme switches', (
    tester,
  ) async {
    await surface(tester, const Size(1440, 1000));
    await tester.pumpWidget(const KallistoShowcase());
    await tester.pumpAndSettle();
    expect(
      find.text('Precise by design.\nCalm in every detail.'),
      findsOneWidget,
    );
    for (var i = 1; i < 8; i++) {
      await tester.tap(find.byKey(ValueKey('nav-$i')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Collection $i renders');
    }
    await tester.tap(find.byTooltip('Use dark theme'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Use light theme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile drawer navigates and closes', (tester) async {
    await surface(tester, const Size(390, 844));
    await tester.pumpWidget(const KallistoShowcase());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    expect(find.text('Images that carry context'), findsOneWidget);
    expect(find.byType(Drawer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tablet rail does not offer an unavailable expansion', (
    tester,
  ) async {
    await surface(tester, const Size(768, 1024));
    await tester.pumpWidget(const KallistoShowcase());
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand sidebar'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('nav-3')));
    await tester.pumpAndSettle();
    expect(find.text('The workspace frame'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('All sections fit a $width px viewport', (tester) async {
      await surface(tester, Size(width, 1000));
      for (final section in <Widget>[
        const ButtonsSection(),
        const CardsSection(),
        const LayoutsSection(),
        const FormsSection(),
        const DataDisplaySection(),
        const FeedbackSection(),
        const MotionSection(),
      ]) {
        await specimen(tester, section);
        expect(
          tester.takeException(),
          isNull,
          reason: '${section.runtimeType} at $width',
        );
      }
    });
  }

  testWidgets('Large text fits component sections on a phone', (tester) async {
    await surface(tester, const Size(390, 844));
    for (final section in <Widget>[
      const ButtonsSection(),
      const CardsSection(),
      const FormsSection(),
      const FeedbackSection(),
      const MotionSection(),
    ]) {
      await specimen(tester, section, scale: 1.5);
      expect(
        tester.takeException(),
        isNull,
        reason: '${section.runtimeType} at 150% text',
      );
    }
  });

  testWidgets('Save action prevents duplicate submissions and resolves', (
    tester,
  ) async {
    await surface(tester, const Size(1200, 1000));
    await specimen(tester, const ButtonsSection());
    final save = find.byKey(const ValueKey('save-demo'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(find.text('Saving…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(find.text('Saved · try again'), findsOneWidget);
  });

  testWidgets('Form validates missing data then accepts valid inputs', (
    tester,
  ) async {
    await surface(tester, const Size(1200, 1200));
    await specimen(tester, const FormsSection());
    await tapVisible(tester, find.text('Validate sample'));
    expect(find.text('Enter at least 3 characters.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('project-name')),
      'Courtyard residence',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'studio@example.com',
    );
    await tapVisible(tester, find.text('Validate sample'));
    expect(find.text('Sample validation passed'), findsOneWidget);
  });

  testWidgets('Card filters and image preview work', (tester) async {
    await surface(tester, const Size(1200, 1000));
    await specimen(tester, const CardsSection());
    await tester.tap(find.text('Image cards'));
    await tester.pumpAndSettle();
    expect(find.text('More than a container'), findsNothing);
    await tester.tap(find.text('The courtyard residence').first);
    await tester.pumpAndSettle();
    expect(find.text('Project preview'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Project preview'), findsNothing);
  });

  testWidgets('Error state offers retry and displays success', (tester) async {
    await surface(tester, const Size(1000, 1000));
    await specimen(tester, const FeedbackSection());
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry sample'));
    await tester.pumpAndSettle();
    expect(find.text('You’re all set'), findsOneWidget);
    expect(find.text('1 sample retries'), findsOneWidget);
  });

  testWidgets('Table search reports empty results', (tester) async {
    await surface(tester, const Size(1100, 1000));
    await specimen(tester, const DataDisplaySection());
    await tester.enterText(find.byType(TextField), 'no-matching-project');
    await tester.pumpAndSettle();
    expect(find.text('No projects match this search.'), findsOneWidget);
  });

  testWidgets('Reduced motion resolves playground immediately', (tester) async {
    await surface(tester, const Size(1200, 1000));
    await specimen(tester, const MotionSection(), reduced: true);
    await tester.tap(find.byKey(const ValueKey('play-motion')));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedOpacity>(find.byKey(const ValueKey('fade-specimen')))
          .duration,
      Duration.zero,
    );
    expect(
      find.text('Animations resolve immediately. No nonessential movement.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Every layout variant reflows inside a narrow preview', (
    tester,
  ) async {
    await surface(tester, const Size(1000, 1100));
    await specimen(tester, const LayoutsSection());
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(320);
    await tester.pumpAndSettle();
    for (final title in [
      'Split workspace',
      'Board',
      'List + detail',
      'Card grid',
    ]) {
      await tapVisible(tester, find.text(title));
      expect(tester.takeException(), isNull, reason: title);
    }
  });

  testWidgets('Dialog drawer and bottom sheet dismiss with Escape', (
    tester,
  ) async {
    await surface(tester, const Size(1100, 1000));
    await specimen(tester, const FeedbackSection());
    for (final pair in <(String, String)>[
      ('Open dialog', 'Share this sample?'),
      ('Open drawer', 'Project inspector'),
      ('Open bottom sheet', 'Quick actions'),
    ]) {
      await tapVisible(tester, find.text(pair.$1));
      expect(find.text(pair.$2), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(pair.$2), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Spring easing stays valid through both directions', (
    tester,
  ) async {
    await surface(tester, const Size(1200, 1000));
    await specimen(tester, const MotionSection());
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spring').last);
    await tester.pumpAndSettle();
    for (var run = 0; run < 2; run++) {
      await tester.tap(find.byKey(const ValueKey('play-motion')));
      await tester.pump();
      for (var frame = 0; frame < 25; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('Transition page opens and returns', (tester) async {
    await surface(tester, const Size(1000, 1000));
    await specimen(tester, const MotionSection());
    await tapVisible(tester, find.text('Open transition'));
    expect(find.text('A continuous experience.'), findsOneWidget);
    await tester.tap(find.text('Back to motion'));
    await tester.pumpAndSettle();
    expect(find.text('Motion tokens'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Form reset clears entered notes and validation', (tester) async {
    await surface(tester, const Size(1000, 1100));
    await specimen(tester, const FormsSection());
    await tester.enterText(find.byType(TextFormField).at(2), 'Sample notes');
    await tapVisible(tester, find.text('Validate sample'));
    await tapVisible(tester, find.text('Reset'));
    expect(find.text('Sample notes'), findsNothing);
    expect(find.text('Enter at least 3 characters.'), findsNothing);
  });
}
