import 'dart:io';

import 'package:drift/drift.dart';
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/value_objects/clock.dart';
import 'package:porcelain_photo_booth/domain/value_objects/entity_id.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';
import 'package:porcelain_photo_booth/infrastructure/database/database_connection.dart';

import 'fakes.dart';

/// A fresh in-memory booth database with production connection settings.
///
/// Streams close synchronously, so widget tests leave no drift timers
/// pending when the app is torn down.
BoothDatabase memoryDatabase({Clock? clock, IdGenerator? ids}) => BoothDatabase(
  DatabaseConnection(
    openBoothDatabaseInMemory(),
    closeStreamsSynchronously: true,
  ),
  ids: ids ?? SequentialIds('00000000-0000-4000-9000'),
  clock: clock ?? FakeClock(),
);

/// A booth database in [file], on the calling isolate.
BoothDatabase fileDatabase(File file, {Clock? clock, IdGenerator? ids}) =>
    BoothDatabase(
      DatabaseConnection(
        openBoothDatabaseFileInline(file),
        closeStreamsSynchronously: true,
      ),
      ids: ids ?? SequentialIds('00000000-0000-4000-9000'),
      clock: clock ?? FakeClock(),
    );

/// Adds a template with one revision directly to the database (the
/// template library that will do this arrives in M04/M05) and returns the
/// revision's summary.
Future<TemplateRevisionSummary> insertTemplate(
  BoothDatabase db, {
  required String templateId,
  required String revisionId,
  String name = 'Two-up classic',
  int revisionNumber = 1,
  int slots = 2,
  int width = 1200,
  int height = 1800,
  bool archived = false,
  DateTime? at,
}) async {
  final now = at ?? DateTime.utc(2026, 10, 1);
  await db
      .into(db.templates)
      .insert(
        TemplatesCompanion.insert(
          id: templateId,
          displayName: name,
          createdAt: now,
          updatedAt: now,
          archivedAt: Value(archived ? now : null),
        ),
        mode: InsertMode.insertOrIgnore,
      );
  await db
      .into(db.templateRevisions)
      .insert(
        TemplateRevisionsCompanion.insert(
          id: revisionId,
          templateId: templateId,
          revisionNumber: revisionNumber,
          documentSchemaVersion: 1,
          manifestPath: 'templates/$templateId/$revisionNumber.json',
          checksum: 'a' * 64,
          pageWidthPx: width,
          pageHeightPx: height,
          photoSlotCount: slots,
          createdAt: now,
        ),
      );
  return TemplateRevisionSummary(
    revisionId: revisionId,
    templateId: templateId,
    templateName: name,
    revisionNumber: revisionNumber,
    pageWidthPx: width,
    pageHeightPx: height,
    photoSlotCount: slots,
    templateArchived: archived,
  );
}

/// Template and revision identifiers for test fixtures.
abstract final class TestIds {
  static const templateA = '0000000a-0000-4000-8000-00000000000a';
  static const revisionA1 = '000000a1-0000-4000-8000-0000000000a1';
  static const revisionA2 = '000000a2-0000-4000-8000-0000000000a2';
  static const templateB = '0000000b-0000-4000-8000-00000000000b';
  static const revisionB1 = '000000b1-0000-4000-8000-0000000000b1';
  static const templateC = '0000000c-0000-4000-8000-00000000000c';
  static const revisionC1 = '000000c1-0000-4000-8000-0000000000c1';
  static const templateD = '0000000d-0000-4000-8000-00000000000d';
  static const revisionD1 = '000000d1-0000-4000-8000-0000000000d1';
}
