// AC-0202 (reusable components with press, disabled, selected, loading and
// focus states) and AC-0205 (labels, touch targets, reduced motion).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_icons.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_motion.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_page_transitions.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme_data.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_layout.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_button.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_card.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_navigation.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_segmented_control.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_sheet.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_spinner.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_stepper.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_switch.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_text_field.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_toast.dart';
import 'package:porcelain_photo_booth/shared/widgets/responsive_grid.dart';
import 'package:porcelain_photo_booth/shared/widgets/tactile_surface.dart';
import 'package:porcelain_photo_booth/shared/widgets/template_thumbnail.dart';

Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: porcelainThemeData(PorcelainThemeProfile.porcelainStudio),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: page!,
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

TactileSurface surfaceIn(WidgetTester tester, Finder control) =>
    tester.widget<TactileSurface>(
      find.descendant(of: control, matching: find.byType(TactileSurface)).first,
    );

void main() {
  group('PorcelainButton', () {
    testWidgets('activates on tap and is visibly pressed while held', (
      tester,
    ) async {
      var taps = 0;
      await pumpComponent(
        tester,
        PorcelainButton(
          label: 'Apply',
          variant: PorcelainButtonVariant.primary,
          onPressed: () => taps++,
        ),
      );
      final button = find.byType(PorcelainButton);
      expect(surfaceIn(tester, button).look.travel, 0);

      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 200));
      final pressed = surfaceIn(tester, button).look;
      expect(pressed.travel, 1, reason: 'pressed controls travel 1 dp');
      expect(pressed.inset, greaterThan(0), reason: 'and show an inset');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(surfaceIn(tester, button).look.travel, 0);
    });

    testWidgets('a disabled button explains why, and does nothing', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpComponent(
        tester,
        const PorcelainButton(
          label: 'Start Booth',
          onPressed: null,
          disabledReason: 'Needs a checked event.',
        ),
      );
      expect(
        tester.getSemantics(find.byType(PorcelainButton)),
        matchesSemantics(
          label: 'Start Booth',
          hint: 'Needs a checked event.',
          isButton: true,
          hasEnabledState: true,
          isFocusable: false,
        ),
      );
      await tester.tap(find.byType(PorcelainButton));
      await tester.pump();
      expect(find.text('Needs a checked event.'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a busy button ignores presses and announces progress', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: porcelainThemeData(PorcelainThemeProfile.porcelainStudio),
          home: Scaffold(
            body: Center(
              child: PorcelainButton(
                label: 'Save',
                busy: true,
                busyLabel: 'Saving',
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      // The spinner turns forever, so settle by time instead.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(PorcelainButton));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 0);
      expect(find.byType(PorcelainSpinner), findsOneWidget);
      expect(find.text('Saving'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(PorcelainButton)),
        matchesSemantics(
          label: 'Saving',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('keyboard focus shows a ring and Enter activates', (
      tester,
    ) async {
      var taps = 0;
      await pumpComponent(
        tester,
        PorcelainButton(label: 'Open', onPressed: () => taps++),
      );
      final button = find.byType(PorcelainButton);
      expect(surfaceIn(tester, button).focused, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(surfaceIn(tester, button).focused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('every size meets the touch target; guest size >= 72 dp', (
      tester,
    ) async {
      for (final size in PorcelainButtonSize.values) {
        await pumpComponent(
          tester,
          PorcelainButton(label: 'Go', size: size, onPressed: () {}),
        );
        final rendered = tester.getSize(find.byType(PorcelainButton));
        expect(rendered.height, greaterThanOrEqualTo(48), reason: size.name);
        expect(rendered.width, greaterThanOrEqualTo(48), reason: size.name);
        if (size == PorcelainButtonSize.guest) {
          expect(rendered.height, greaterThanOrEqualTo(72));
        }
      }
    });

    testWidgets('success and error feedback show an icon, not only colour', (
      tester,
    ) async {
      await pumpComponent(
        tester,
        Column(
          children: [
            PorcelainButton(
              label: 'Saved',
              feedback: PorcelainButtonFeedback.success,
              onPressed: () {},
            ),
            PorcelainButton(
              label: 'Try again',
              feedback: PorcelainButtonFeedback.error,
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(find.byIcon(PorcelainIcons.success), findsOneWidget);
      expect(find.byIcon(PorcelainIcons.error), findsOneWidget);
    });

    testWidgets('icon-only buttons are labelled for accessibility', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpComponent(
        tester,
        PorcelainIconButton(
          icon: PorcelainIcons.add,
          semanticLabel: 'More photos',
          onPressed: () {},
        ),
      );
      expect(
        tester.getSemantics(find.byType(PorcelainIconButton)),
        matchesSemantics(
          label: 'More photos',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('reduced motion', () {
    testWidgets('presses and state changes do not animate', (tester) async {
      await pumpComponent(
        tester,
        PorcelainButton(label: 'Apply', onPressed: () {}),
        reduceMotion: true,
      );
      final button = find.byType(PorcelainButton);
      expect(surfaceIn(tester, button).duration, Duration.zero);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump();
      expect(surfaceIn(tester, button).duration, Duration.zero);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('busy shows a still hourglass, not a turning arc', (
      tester,
    ) async {
      await pumpComponent(
        tester,
        const PorcelainSpinner(color: Color(0xFF000000)),
        reduceMotion: true,
      );
      expect(find.byIcon(PorcelainIcons.busy), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PorcelainSpinner),
          matching: find.byType(RotationTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('motion tokens resolve to zero', (tester) async {
      late PorcelainMotion reduced;
      late PorcelainMotion regular;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              reduced = PorcelainMotion.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              regular = PorcelainMotion.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(reduced.isReduced, isTrue);
      for (final duration in [
        reduced.press,
        reduced.release,
        reduced.standard,
        reduced.emphasized,
        reduced.page,
      ]) {
        expect(duration, Duration.zero);
      }
      expect(regular.press.inMilliseconds, inInclusiveRange(120, 180));
      expect(regular.release.inMilliseconds, inInclusiveRange(120, 180));
      expect(regular.emphasized.inMilliseconds, inInclusiveRange(200, 320));
    });

    testWidgets('route transitions are skipped', (tester) async {
      const child = SizedBox(key: Key('page'));
      late Widget built;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              built = const PorcelainPageTransitionsBuilder().buildTransitions(
                MaterialPageRoute<void>(builder: (_) => child),
                context,
                kAlwaysCompleteAnimation,
                kAlwaysDismissedAnimation,
                child,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(identical(built, child), isTrue);
    });
  });

  group('selection controls', () {
    testWidgets('switch toggles and reports its state', (tester) async {
      final semantics = tester.ensureSemantics();
      var value = false;
      await pumpComponent(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PorcelainSwitch(
            value: value,
            semanticLabel: 'Reduce motion',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PorcelainSwitch)),
        matchesSemantics(
          label: 'Reduce motion',
          isButton: true,
          hasToggledState: true,
          isToggled: false,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.byType(PorcelainSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(find.byIcon(PorcelainIcons.check), findsOneWidget);
      expect(tester.getSize(find.byType(PorcelainSwitch)).height, 48);
      semantics.dispose();
    });

    testWidgets('stepper changes by one and stops at its limits', (
      tester,
    ) async {
      var value = 3;
      await pumpComponent(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PorcelainStepper(
            label: 'Photos per session',
            value: value,
            min: 1,
            max: 4,
            decreaseLabel: 'Fewer photos',
            increaseLabel: 'More photos',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('More photos'));
      await tester.pumpAndSettle();
      expect(value, 4);
      await tester.tap(find.bySemanticsLabel('More photos'));
      await tester.pumpAndSettle();
      expect(value, 4, reason: 'cannot exceed max');
      await tester.tap(find.bySemanticsLabel('Fewer photos'));
      await tester.pumpAndSettle();
      expect(value, 3);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('stepper is adjustable by assistive technology', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var value = 2;
      await pumpComponent(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PorcelainStepper(
            label: 'Countdown',
            value: value,
            min: 1,
            max: 10,
            decreaseLabel: 'Shorter',
            increaseLabel: 'Longer',
            formatValue: (v) => '$v s',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      );
      final node = find.semantics.byLabel('Countdown');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Countdown')),
        matchesSemantics(
          label: 'Countdown',
          value: '2 s',
          increasedValue: '3 s',
          decreasedValue: '1 s',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      tester.semantics.performAction(node, SemanticsAction.increase);
      await tester.pumpAndSettle();
      expect(value, 3);
      semantics.dispose();
    });

    testWidgets('segmented control selects one value and says which', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var selected = 'a';
      await pumpComponent(
        tester,
        StatefulBuilder(
          builder: (context, setState) => PorcelainSegmentedControl<String>(
            selected: selected,
            onChanged: (v) => setState(() => selected = v),
            segments: const [
              PorcelainSegment(value: 'a', label: 'Active'),
              PorcelainSegment(value: 'd', label: 'Drafts'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      expect(selected, 'd');
      expect(
        tester.getSemantics(find.bySemanticsLabel('Drafts')),
        matchesSemantics(
          label: 'Drafts',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      for (final label in ['Active', 'Drafts']) {
        expect(
          tester.getSize(find.bySemanticsLabel(label)).height,
          greaterThanOrEqualTo(48),
        );
      }
      semantics.dispose();
    });
  });

  group('inputs, cards and feedback', () {
    testWidgets('text field: label above, error in words and icon', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpComponent(
        tester,
        SizedBox(
          width: 400,
          child: PorcelainTextField(
            label: 'Countdown seconds',
            controller: controller,
            error: 'Enter a whole number from 1 to 10.',
          ),
        ),
      );
      expect(find.text('Countdown seconds'), findsOneWidget);
      expect(find.text('Enter a whole number from 1 to 10.'), findsOneWidget);
      expect(find.byIcon(PorcelainIcons.error), findsOneWidget);
      await tester.enterText(find.byType(TextField), '5');
      expect(controller.text, '5');
    });

    testWidgets('a pressable card is one labelled button; selection is '
        'marked', (tester) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await pumpComponent(
        tester,
        SizedBox(
          width: 300,
          child: PorcelainCard(
            selected: true,
            onPressed: () => taps++,
            child: const Column(children: [Text('Light Oak'), Text('Sage')]),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PorcelainCard)),
        matchesSemantics(
          label: 'Light Oak\nSage',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(find.byIcon(PorcelainIcons.check), findsOneWidget);
      await tester.tap(find.byType(PorcelainCard));
      await tester.pumpAndSettle();
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('toasts appear and leave on their own', (tester) async {
      await pumpComponent(
        tester,
        Builder(
          builder: (context) => PorcelainButton(
            label: 'Notify',
            onPressed: () => PorcelainToast.show(context, 'Theme applied.'),
          ),
        ),
      );
      await tester.tap(find.text('Notify'));
      await tester.pumpAndSettle();
      expect(find.text('Theme applied.'), findsOneWidget);
      await tester.pump(PorcelainToast.displayDuration);
      await tester.pumpAndSettle();
      expect(find.text('Theme applied.'), findsNothing);
    });

    testWidgets('sheets open with a title and close from their action', (
      tester,
    ) async {
      await pumpComponent(
        tester,
        Builder(
          builder: (context) => PorcelainButton(
            label: 'Open',
            onPressed: () => showPorcelainSheet<void>(
              context: context,
              title: 'Archive event?',
              body: const Text('Photos are kept.'),
              actions: (sheet) => [
                PorcelainButton(
                  label: 'Close',
                  onPressed: () => Navigator.of(sheet).pop(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Archive event?'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Archive event?'), findsNothing);
    });
  });

  group('layout helpers', () {
    test('grid columns follow the available width', () {
      int columns(double width) => ResponsiveGrid.columnsFor(
        width,
        minTileWidth: 200,
        maxColumns: 4,
        spacing: 24,
      );
      expect(columns(150), 1);
      expect(columns(424), 2);
      expect(columns(10000), 4);
    });

    testWidgets('a balanced grid shows four items as 2 x 2', (tester) async {
      await pumpComponent(
        tester,
        SizedBox(
          width: 700,
          child: ResponsiveGrid(
            minTileWidth: 200,
            balanced: true,
            children: [
              for (var i = 0; i < 4; i++) SizedBox(height: 40, key: Key('$i')),
            ],
          ),
        ),
      );
      final first = tester.getTopLeft(find.byKey(const Key('0')));
      expect(tester.getTopLeft(find.byKey(const Key('1'))).dy, first.dy);
      expect(
        tester.getTopLeft(find.byKey(const Key('2'))).dy,
        greaterThan(first.dy),
      );
    });

    testWidgets('template thumbnails keep the exact page ratio', (
      tester,
    ) async {
      await pumpComponent(
        tester,
        const TemplateThumbnail(
          pageWidth: 2,
          pageHeight: 6,
          height: 180,
          slots: [Rect.fromLTWH(0.1, 0.1, 0.8, 0.3)],
          semanticLabel: 'Strip',
        ),
      );
      final size = tester.getSize(find.byType(TemplateThumbnail));
      expect(size.width / size.height, closeTo(2 / 6, 1e-9));
    });

    testWidgets('navigation reports the selected section', (tester) async {
      final semantics = tester.ensureSemantics();
      var selected = 0;
      for (final extended in [true, false]) {
        await pumpComponent(
          tester,
          SizedBox(
            height: 700,
            child: StatefulBuilder(
              builder: (context, setState) => PorcelainNavigation(
                extended: extended,
                selectedIndex: selected,
                onSelected: (i) => setState(() => selected = i),
                destinations: const [
                  PorcelainDestination(
                    icon: PorcelainIcons.dashboard,
                    label: 'Dashboard',
                  ),
                  PorcelainDestination(
                    icon: PorcelainIcons.events,
                    label: 'Events',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.text('Events'));
        await tester.pumpAndSettle();
        expect(selected, 1);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Events')),
          matchesSemantics(
            label: 'Events',
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );
        selected = 0;
      }
      semantics.dispose();
    });

    test('guest scale keeps the Start control well above 72 dp', () {
      expect(GuestScale.forSize(const Size(820, 1180)).factor, 1);
      final smallest = GuestScale.forSize(const Size(320, 480));
      expect(smallest.factor, 0.72);
      expect(smallest(216), greaterThanOrEqualTo(72 * 2));
    });
  });
}
