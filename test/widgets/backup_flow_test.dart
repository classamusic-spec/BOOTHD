// AC-1001 and AC-1006 on the operator's screens: Settings > Backup makes a
// backup of what the operator chose, only when the tablet has room, says
// it was read back and checked, and hands it to the share sheet; the first
// screen of an empty booth restores one only after it was checked from
// end to end, says what it holds and what it never holds, starts the app
// again, and then asks for a new PIN and recovery code. Nothing changes on
// the tablet when a file is refused. (The backup itself is tested on real
// files in test/infrastructure/backup.)
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/backup/backup_manifest.dart';
import 'package:porcelain_photo_booth/domain/services/backup_service.dart';
import 'package:porcelain_photo_booth/domain/services/operator_files.dart';
import 'package:porcelain_photo_booth/features/onboarding/restore_backup_panel.dart';
import 'package:porcelain_photo_booth/shared/backup/backup_copy.dart';

import '../support/app_harness.dart';
import '../support/fake_backup.dart';
import '../support/tablet_viewports.dart';

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

PickedStream _file(String name) => PickedStream(
  name: name,
  length: 1024,
  open: () => Stream.value(const [1, 2, 3]),
);

void main() {
  group('Settings > Backup', () {
    Future<TestBooth> open(WidgetTester tester, {FakeBackupService? backups}) {
      useViewport(tester, TabletViewport.ipadLandscape);
      return pumpApp(
        tester,
        location: '/studio/settings?section=backup',
        backups: backups,
      );
    }

    testWidgets('makes a checked backup of everything and hands it to the '
        'share sheet (AC-1006)', (tester) async {
      final semantics = tester.ensureSemantics();
      final booth = await open(tester);
      expect(find.textContaining('214 sessions'), findsOneWidget);
      expect(find.textContaining('About 1.8 GB'), findsOneWidget);

      await _tap(tester, 'Make a backup');
      expect(booth.backups.created, [BackupContents.everything]);
      expect(find.text('porcelain-backup-20261114-2341.tar'), findsOneWidget);
      expect(find.textContaining('read back and checked'), findsOneWidget);

      await _tap(tester, 'Share backup');
      expect(booth.files.sharedFiles.single.mimeType, 'application/x-tar');
      expect(
        booth.files.sharedFiles.single.path,
        '/backups/porcelain-backup-20261114-2341.tar',
      );
      semantics.dispose();
    });

    testWidgets('a setup-only backup holds no guest photo', (tester) async {
      final semantics = tester.ensureSemantics();
      final booth = await open(tester);
      await _tap(tester, 'Setup only');
      expect(find.textContaining('without any guest photo'), findsOneWidget);
      await _tap(tester, 'Make a backup');
      expect(booth.backups.created, [BackupContents.setupOnly]);
      semantics.dispose();
    });

    testWidgets('without room for the file, no backup is started and the '
        'reason is given (AC-1005)', (tester) async {
      final semantics = tester.ensureSemantics();
      final booth = await open(
        tester,
        backups: FakeBackupService()..freeBytes = 200 * 1024 * 1024,
      );
      final noSpace = BackupCopy.problem(BackupProblem.noSpace);
      expect(find.text(noSpace), findsOneWidget);
      await _tap(tester, 'Make a backup');
      expect(booth.backups.created, isEmpty);
      semantics.dispose();
    });

    testWidgets('a failed backup says why and offers nothing to share', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final booth = await open(
        tester,
        backups: FakeBackupService()
          ..nextFailure = const BackupException(BackupProblem.sourceDamaged),
      );
      await _tap(tester, 'Make a backup');
      expect(booth.backups.created, [BackupContents.everything]);
      expect(
        find.text(BackupCopy.problem(BackupProblem.sourceDamaged)),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Share backup'), findsNothing);
      semantics.dispose();
    });
  });

  group('first run: restore from a backup', () {
    Future<TestBooth> open(WidgetTester tester, {FakeBackupService? backups}) {
      useViewport(tester, TabletViewport.ipadPortrait);
      return pumpApp(tester, startAs: StartAs.setup, backups: backups);
    }

    testWidgets('a checked backup is shown, restored and the app starts '
        'again (AC-1001, AC-1006)', (tester) async {
      final semantics = tester.ensureSemantics();
      final booth = await open(tester);
      await _tap(tester, 'Restore from a backup');
      expect(find.byType(RestoreBackupPanel), findsOneWidget);

      booth.files.nextStream = _file('porcelain-backup-20261114-2341.tar');
      await _tap(tester, 'Choose backup file');
      expect(booth.files.picks, [PickableFile.backup]);
      expect(booth.backups.inspected, ['porcelain-backup-20261114-2341.tar']);
      expect(find.text('Checked: complete and unchanged'), findsOneWidget);
      expect(find.text('"Front entrance"'), findsOneWidget);
      expect(
        find.text(BackupCopy.contents(FakeBackupService.counts)),
        findsOneWidget,
      );
      expect(find.textContaining('new PIN and recovery code'), findsOneWidget);
      expect(booth.backups.staged, isEmpty, reason: 'nothing changed yet');

      // The restore is staged and the app is asked to start again (here the
      // harness only counts that: test/app/restartable_app_test.dart starts
      // a real scope again). Until then the panel says what is happening
      // and offers nothing to tap.
      await tester.tap(find.bySemanticsLabel('Restore').last);
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(booth.backups.staged, hasLength(1));
      expect(booth.restarts, 1);
      expect(find.textContaining('Restoring… keep the app open.'), findsOne);
      expect(find.bySemanticsLabel('Cancel'), findsNothing);
      semantics.dispose();
    });

    testWidgets('a refused file changes nothing and another can be chosen', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final booth = await open(
        tester,
        backups: FakeBackupService()
          ..nextFailure = const BackupException(BackupProblem.invalidArchive),
      );
      await _tap(tester, 'Restore from a backup');
      booth.files.nextStream = _file('half.tar');
      await _tap(tester, 'Choose backup file');
      expect(
        find.text(BackupCopy.problem(BackupProblem.invalidArchive)),
        findsOneWidget,
      );
      expect(find.text('Nothing on this tablet was changed.'), findsOneWidget);
      expect(booth.backups.staged, isEmpty);
      expect(booth.restarts, 0);

      booth.files.nextStream = _file('whole.tar');
      await _tap(tester, 'Choose another file');
      expect(find.text('Checked: complete and unchanged'), findsOneWidget);
      await _tap(tester, 'Cancel');
      expect(find.byType(RestoreBackupPanel), findsNothing);
      expect(booth.backups.discarded, hasLength(1));
      expect(find.bySemanticsLabel('Begin setup'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('after the restart, setup says what came back and asks for '
        'a new PIN', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(
        tester,
        backups: FakeBackupService()
          ..pendingReport = RestoreReport(
            createdAtUtc: FakeBackupService.made,
            boothName: 'Front entrance',
            counts: FakeBackupService.counts,
            closedDeliveries: 1,
          ),
      );
      expect(find.text('Backup restored'), findsOneWidget);
      expect(
        find.textContaining(BackupCopy.contents(FakeBackupService.counts)),
        findsOneWidget,
      );
      expect(find.textContaining('Texts that were waiting'), findsOneWidget);
      expect(find.bySemanticsLabel('Restore from a backup'), findsNothing);
      await _tap(tester, 'Continue');
      expect(find.text('Everything stays on this tablet'), findsOneWidget);
      semantics.dispose();
    });
  });
}
