// UX-P1 (CR-003): page sections enter one after another and are in the
// semantics tree throughout, with nothing moving under reduced motion
// (AC-UXP-06); segmented controls give up padding, then scroll, rather
// than break a label (AC-UXP-07); the dashboard counts the gallery's
// sessions instead of always saying there are none (AC-UXP-08).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme_data.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_entrance.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_segmented_control.dart';

import '../support/screen_catalog.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool reduceMotion = false,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: porcelainThemeData(PorcelainThemeProfile.porcelainStudio),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: page!,
      ),
      home: Scaffold(body: child),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// How opaque the section holding [text] is.
double _opacity(WidgetTester tester, String text) => tester
    .widget<FadeTransition>(
      find
          .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
          .first,
    )
    .opacity
    .value;

const _sections = PorcelainEntrance(
  child: Column(
    children: [
      EntranceItem(index: 0, child: Text('First')),
      EntranceItem(index: 1, child: Text('Second')),
      EntranceItem(index: 6, child: Text('Last')),
    ],
  ),
);

const _labels = ['Everything', 'Finished', 'Waiting to finish', 'Ended early'];

Widget _control(double? width, ValueChanged<int> onChanged) => Center(
  child: SizedBox(
    width: width,
    child: PorcelainSegmentedControl<int>(
      segments: [
        for (final (i, label) in _labels.indexed)
          PorcelainSegment(value: i, label: label),
      ],
      selected: 0,
      onChanged: onChanged,
    ),
  ),
);

void main() {
  group('page entrance', () {
    testWidgets('sections fade in and rise one after another, readable by '
        'assistive technology throughout', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _sections, settle: false);
      final startTop = tester.getTopLeft(find.text('First')).dy;
      expect(_opacity(tester, 'First'), 0);
      expect(
        find.bySemanticsLabel('Last'),
        findsOneWidget,
        reason: 'a section is in the semantics tree before it shows',
      );

      await tester.pump(const Duration(milliseconds: 120));
      expect(
        _opacity(tester, 'First'),
        greaterThan(_opacity(tester, 'Second')),
      );
      expect(_opacity(tester, 'Second'), greaterThan(_opacity(tester, 'Last')));

      await tester.pumpAndSettle();
      for (final text in ['First', 'Second', 'Last']) {
        expect(_opacity(tester, text), 1, reason: text);
      }
      expect(
        tester.getTopLeft(find.text('First')).dy,
        lessThan(startTop),
        reason: 'it rose into place',
      );
      semantics.dispose();
    });

    testWidgets('nothing moves with reduced motion', (tester) async {
      await _pump(tester, _sections, reduceMotion: true, settle: false);
      expect(tester.hasRunningAnimations, isFalse);
      for (final text in ['First', 'Second', 'Last']) {
        expect(_opacity(tester, text), 1, reason: text);
      }
    });
  });

  group('segmented control', () {
    /// The control's width with room to spare, and each label's height
    /// there: one line.
    Future<(double, Map<String, double>)> roomy(WidgetTester tester) async {
      await _pump(tester, _control(null, (_) {}));
      return (
        tester.getSize(find.byType(PorcelainSegmentedControl<int>)).width,
        {
          for (final label in _labels)
            label: tester.getSize(find.text(label)).height,
        },
      );
    }

    testWidgets('a little short of room, the segments give up padding and '
        'keep every label on one line', (tester) async {
      final (natural, lines) = await roomy(tester);
      await _pump(tester, _control(natural - 40, (_) {}));
      expect(
        find.descendant(
          of: find.byType(PorcelainSegmentedControl<int>),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(
        tester.getSize(find.byType(PorcelainSegmentedControl<int>)).width,
        natural - 40,
      );
      for (final label in _labels) {
        expect(
          tester.getSize(find.text(label)).height,
          lines[label],
          reason: label,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('far short of room, the track keeps its width and scrolls; '
        'no label breaks', (tester) async {
      final (natural, lines) = await roomy(tester);
      int? chosen;
      await _pump(tester, _control(natural / 2, (value) => chosen = value));
      expect(
        find.descendant(
          of: find.byType(PorcelainSegmentedControl<int>),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      for (final label in _labels) {
        expect(
          tester.getSize(find.text(label)).height,
          lines[label],
          reason: label,
        );
      }
      await tester.drag(
        find.byType(SingleChildScrollView),
        Offset(-natural, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ended early'));
      expect(chosen, 3, reason: 'the last segment is reachable');
    });
  });

  group('dashboard', () {
    testWidgets('says the gallery is empty when it is', (tester) async {
      await show(tester, 'dashboard');
      expect(find.text('No sessions yet'), findsOneWidget);
    });

    testWidgets('counts the sessions in the gallery', (tester) async {
      await show(tester, 'gallery sessions');
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('18 sessions'), findsOneWidget);
    });
  });
}
