-- Representative data as schema version 2 (M04) stores it: everything in
-- seed_v1.sql, plus template assets and the assets each revision uses. The
-- migration test loads this into a version 2 database built from
-- drift_schemas/booth/drift_schema_v2.json, opens it with the current app
-- code and checks every value survives. Keep this file when the schema
-- changes.

INSERT INTO booth_profiles VALUES (
  'b0000000-0000-4000-8000-000000000001', 'Ballroom booth',
  'lightOak', 'high', 'reduced',
  'back', 0, 1, 'landscape', 'png', 95,
  '2026-10-01T08:00:00.000Z', '2026-10-17T18:45:12.345Z'
);

INSERT INTO templates VALUES
  ('a0000000-0000-4000-8000-00000000000a', 'Two-up classic', NULL,
   '2026-10-02T10:00:00.000Z', '2026-10-03T10:00:00.000Z', NULL),
  ('a0000000-0000-4000-8000-00000000000b', 'Retro strip', 'strips',
   '2026-10-02T11:00:00.000Z', '2026-10-05T11:00:00.000Z',
   '2026-10-05T11:00:00.000Z');

INSERT INTO template_revisions VALUES
  ('a1000000-0000-4000-8000-0000000000a1', 'a0000000-0000-4000-8000-00000000000a',
   1, 1, 'templates/a0000000-0000-4000-8000-00000000000a/1.json',
   '1111111111111111111111111111111111111111111111111111111111111111',
   1200, 1800, 2, '2026-10-02T10:00:00.000Z'),
  ('a2000000-0000-4000-8000-0000000000a2', 'a0000000-0000-4000-8000-00000000000a',
   2, 1, 'templates/a0000000-0000-4000-8000-00000000000a/2.json',
   '2222222222222222222222222222222222222222222222222222222222222222',
   1200, 1800, 2, '2026-10-03T10:00:00.000Z'),
  ('b1000000-0000-4000-8000-0000000000b1', 'a0000000-0000-4000-8000-00000000000b',
   1, 1, 'templates/a0000000-0000-4000-8000-00000000000b/1.json',
   '3333333333333333333333333333333333333333333333333333333333333333',
   600, 1800, 3, '2026-10-02T11:00:00.000Z');

INSERT INTO events VALUES
  -- A draft with nothing chosen yet.
  ('e0000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001',
   'Spring fair', NULL, NULL, NULL, 'draft',
   'front', 1, 0, 'portrait', 3, 3, 3, 'perShot', 1,
   NULL, NULL, NULL, 0, 30, NULL, 'jpeg', 92, 'keepUntilDeleted', NULL,
   '2026-10-10T09:00:00.000Z', '2026-10-10T09:05:00.000Z', NULL),
  -- The active event the booth is running, with two templates.
  ('e0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001',
   'Hannah & Theo''s wedding', '2026-11-14', 'The Orangery', 'Arrive 2 h early.',
   'active',
   'back', 0, 1, 'landscape', 2, 5, 4, 'wholeSession', 2,
   'Welcome, friends', 'Two photos, then you''re done.', 'Photos stay on this booth.',
   1, 45, 'darkroomWalnut', 'png', 95, 'deleteAfterDays', 30,
   '2026-10-11T09:00:00.000Z', '2026-10-17T18:00:00.000Z', NULL),
  -- An archived event.
  ('e0000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000001',
   'Office party', '2025-12-19', NULL, NULL, 'archived',
   'front', 1, 0, 'portrait', 1, 10, 1, 'none', 0,
   NULL, NULL, NULL, 0, 120, 'porcelainStudio', 'jpeg', 80,
   'keepUntilDeleted', NULL,
   '2025-12-01T09:00:00.000Z', '2026-01-05T09:00:00.000Z',
   '2026-01-05T09:00:00.000Z');

INSERT INTO event_templates VALUES
  ('e0000000-0000-4000-8000-000000000002', 'a2000000-0000-4000-8000-0000000000a2', 0, 0),
  ('e0000000-0000-4000-8000-000000000002', 'a1000000-0000-4000-8000-0000000000a1', 1, 1),
  ('e0000000-0000-4000-8000-000000000003', 'b1000000-0000-4000-8000-0000000000b1', 0, 1);

INSERT INTO app_settings VALUES (
  1, 'b0000000-0000-4000-8000-000000000001',
  '2026-10-01T08:10:00.000Z', 'e0000000-0000-4000-8000-000000000002'
);

INSERT INTO operator_access VALUES (
  1,
  'pbkdf2-sha256$120000$AAAAAAAAAAAAAAAAAAAAAA$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  2, '2026-10-17T18:30:00.000Z', 0, NULL
);

INSERT INTO assets VALUES
  ('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'png',
   'assets/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.png',
   48213, 800, 800, 'flower.png', 'package', '2026-10-02T10:00:00.000Z'),
  ('bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', 'jpeg',
   'assets/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.jpg',
   912345, 3000, 2000, NULL, 'imported', '2026-10-03T10:00:00.000Z'),
  ('cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc', 'ttf',
   'assets/cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc.ttf',
   312000, NULL, NULL, 'Script.ttf', 'package', '2026-10-03T10:00:00.000Z');

INSERT INTO template_revision_assets VALUES
  ('a1000000-0000-4000-8000-0000000000a1', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
  ('a2000000-0000-4000-8000-0000000000a2', 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
  ('a2000000-0000-4000-8000-0000000000a2', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'),
  ('a2000000-0000-4000-8000-0000000000a2', 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc');
