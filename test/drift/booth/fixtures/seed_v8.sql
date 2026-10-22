-- Representative data as schema version 8 (EP01) stores it: everything in
-- seed_v7.sql, with each event's guest experience in place of its theme
-- override, recommendation tags on one template and a guest session that
-- froze the experience it showed. The migration test loads this into a
-- version 8 database built from drift_schemas/booth/drift_schema_v8.json,
-- opens it with the current app code and checks every value survives.
-- Keep this file when the schema changes.

INSERT INTO booth_profiles VALUES (
  'b0000000-0000-4000-8000-000000000001', 'Ballroom booth',
  'lightOak', 'high', 'reduced',
  'back', 0, 1, 'landscape', 'png', 95,
  '2026-10-01T08:00:00.000Z', '2026-10-17T18:45:12.345Z'
);

INSERT INTO templates VALUES
  ('a0000000-0000-4000-8000-00000000000a', 'Two-up classic', NULL,
   '{"schemaVersion":1,"categoryTags":["wedding"],"recommendedExperienceIds":["porcelain-classic"],"occasionTags":["evening"],"visualStyleTags":["elegant"],"defaultCaptureCount":2}',
   '2026-10-02T10:00:00.000Z', '2026-10-03T10:00:00.000Z', NULL),
  ('a0000000-0000-4000-8000-00000000000b', 'Retro strip', 'strips', NULL,
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
   NULL, NULL, NULL, 0, 30,
   '{"schemaVersion":1,"packId":"vintage-oak","packVersion":1,"soundVolume":70,"celebrationEnabled":true,"cameraStage":"fullTemplate","recommendedTemplateIds":[],"childrenMayBeGuests":false,"revision":1}',
   'jpeg', 92, 'keepUntilDeleted', NULL,
   '2026-10-10T09:00:00.000Z', '2026-10-10T09:05:00.000Z', NULL),
  -- The active event the booth is running, with two templates.
  ('e0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001',
   'Hannah & Theo''s wedding', '2026-11-14', 'The Orangery', 'Arrive 2 h early.',
   'active',
   'back', 0, 1, 'landscape', 2, 5, 4, 'wholeSession', 2,
   'Welcome, friends', 'Two photos, then you''re done.', 'Photos stay on this booth.',
   1, 45,
   '{"schemaVersion":1,"packId":"porcelain-classic","packVersion":1,"variantId":"darkroom","soundVolume":70,"celebrationEnabled":true,"cameraStage":"fullTemplate","recommendedTemplateIds":[],"childrenMayBeGuests":false,"revision":2}',
   'png', 95, 'deleteAfterDays', 30,
   '2026-10-11T09:00:00.000Z', '2026-10-17T18:00:00.000Z', NULL),
  -- An archived event.
  ('e0000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000001',
   'Office party', '2025-12-19', NULL, NULL, 'archived',
   'front', 1, 0, 'portrait', 1, 10, 1, 'none', 0,
   NULL, NULL, NULL, 0, 120,
   '{"schemaVersion":1,"packId":"porcelain-classic","packVersion":1,"soundVolume":70,"celebrationEnabled":true,"cameraStage":"fullTemplate","recommendedTemplateIds":[],"childrenMayBeGuests":false,"revision":1}',
   'jpeg', 80,
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

INSERT INTO assets VALUES
  ('dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd', 'png',
   'assets/dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd.png',
   20480, 1200, 1200, 'Floral corner', 'bundled', '2026-10-18T09:00:00.000Z');

INSERT INTO template_drafts VALUES
  ('a0000000-0000-4000-8000-00000000000a', 'a2000000-0000-4000-8000-0000000000a2',
   '{"schemaVersion": 1, "page": {"width": 4, "height": 6, "unit": "in", "dpi": 300}, "assets": {}, "layers": []}',
   '2026-10-18T10:15:00.000Z');

INSERT INTO original_photos VALUES
  ('20261114180500-0a1b2c3d', 'originals/20261114180500-0a1b2c3d.jpg',
   4032, 3024, 3145728,
   '1111111111111111111111111111111111111111111111111111111111111111',
   'back', 90, 'landscapeLeft', 1, 0, 1, 'session',
   '2026-11-14T18:05:00.000Z', '2026-11-14T18:05:01.250Z'),
  ('m01-spike-still', 'originals/m01-spike-still.jpg',
   3024, 4032, 2097152,
   '2222222222222222222222222222222222222222222222222222222222222222',
   'front', 270, 'unknown', NULL, 1, 0, 'legacy',
   '2026-10-02T11:00:00.000Z', '2026-10-18T12:00:00.000Z');

INSERT INTO pending_original_commits VALUES
  ('20261114180900-4e5f6a7b',
   '3333333333333333333333333333333333333333333333333333333333333333',
   1048576, '{"schemaVersion": 1, "id": "20261114180900-4e5f6a7b"}',
   '2026-11-14T18:09:00.000Z');

INSERT INTO original_photos VALUES
  ('20261114181000-00000001', 'originals/20261114181000-00000001.jpg',
   4032, 3024, 3100000,
   '4444444444444444444444444444444444444444444444444444444444444444',
   'front', 270, 'portraitUp', 6, 1, 0, 'session',
   '2026-11-14T18:10:00.000Z', '2026-11-14T18:10:01.000Z'),
  ('20261114181010-00000002', 'originals/20261114181010-00000002.jpg',
   4032, 3024, 3200000,
   '5555555555555555555555555555555555555555555555555555555555555555',
   'front', 270, 'portraitUp', 6, 1, 0, 'session',
   '2026-11-14T18:10:10.000Z', '2026-11-14T18:10:11.000Z'),
  ('20261114181030-00000003', 'originals/20261114181030-00000003.jpg',
   4032, 3024, 3150000,
   '6666666666666666666666666666666666666666666666666666666666666666',
   'front', 270, 'portraitUp', 6, 1, 0, 'session',
   '2026-11-14T18:10:30.000Z', '2026-11-14T18:10:31.000Z'),
  ('20261114182000-00000004', 'originals/20261114182000-00000004.jpg',
   4032, 3024, 3050000,
   '7777777777777777777777777777777777777777777777777777777777777777',
   'front', 270, 'portraitUp', 6, 1, 0, 'session',
   '2026-11-14T18:20:00.000Z', '2026-11-14T18:20:01.000Z'),
  ('20261114182010-00000005', 'originals/20261114182010-00000005.jpg',
   4032, 3024, 3060000,
   '8888888888888888888888888888888888888888888888888888888888888888',
   'front', 270, 'portraitUp', 6, 1, 0, 'session',
   '2026-11-14T18:20:10.000Z', '2026-11-14T18:20:11.000Z');

INSERT INTO capture_sessions VALUES
  ('c0000000-0000-4000-8000-000000000001',
   'e0000000-0000-4000-8000-000000000002', 1,
   'a1000000-0000-4000-8000-0000000000a1', 2,
   '{"schemaVersion":1,"eventId":"e0000000-0000-4000-8000-000000000002","templateRevisionId":"a1000000-0000-4000-8000-0000000000a1","slotIndexes":[0,1],"capture":{"lens":"back","mirrorPreview":false,"mirrorOutput":true,"orientation":"landscape","shotCount":2,"countdownSeconds":5,"shotIntervalSeconds":4,"retakePolicy":"perShot","retakeLimit":2},"output":{"format":"png","jpegQuality":95},"finishTimeoutSeconds":45}',
   'completed', NULL, 1, 'd0000000-0000-4000-8000-000000000001',
   '2026-11-14T18:09:50.000Z', '2026-11-14T18:11:00.000Z',
   '2026-11-14T18:11:00.000Z'),
  ('c0000000-0000-4000-8000-000000000002',
   'e0000000-0000-4000-8000-000000000002', 2,
   'a1000000-0000-4000-8000-0000000000a1', 2,
   '{"schemaVersion":1,"eventId":"e0000000-0000-4000-8000-000000000002","templateRevisionId":"a1000000-0000-4000-8000-0000000000a1","slotIndexes":[0,1],"capture":{"lens":"back","mirrorPreview":false,"mirrorOutput":true,"orientation":"landscape","shotCount":2,"countdownSeconds":5,"shotIntervalSeconds":4,"retakePolicy":"perShot","retakeLimit":2},"output":{"format":"png","jpegQuality":95},"finishTimeoutSeconds":45,"experience":{"schemaVersion":1,"packId":"porcelain-classic","packVersion":1,"variantId":"darkroom","displayName":"Porcelain Classic · Darkroom","themeFamily":"porcelain","palette":{"backdrop":"#FF16110D","backdropAccent":"#FF231C16","panel":"#FF2F261F","panelEdge":"#FF4A3D31","ink":"#FFF3EADF","inkMuted":"#FFC4B4A2","accent":"#FFD8B57B","onAccent":"#FF1C140D","accentEdge":"#FFEBD3A4","highlight":"#FF3E3329","decorationA":"#FFB08F5C","decorationB":"#FF7E8C62"},"typography":{"display":"cormorant","body":"inter"},"layoutPresetId":"porcelain-stage","buttonStyle":"porcelain","copy":{"start":"Start","chooseTitle":"Choose your style","getReady":"Get ready!","lookHere":"Look at the camera","countdownLead":"Get ready","countdownGo":"Smile!","snap":"Snap!","lovely":"Lovely!","nextPhotoSoon":"Next photo coming up","shotProgress":"Photo {n} of {total}","reviewTitle":"How do they look?","keepThese":"Keep these","keepIt":"Keep it","retake":"Retake","retakeAll":"Retake all","creatingTitle":"Creating your photos","readyTitle":"Your photos are ready!","savedMessage":"Saved to the booth gallery.","textMyPhotos":"Text my photos","nextGuest":"Next guest"},"countdownPresetId":"porcelain-press","transitionPresetIds":["fade","rise"],"shutterEffectPresetId":"soft-glow","sounds":{"press":"porcelain-tap","start":"porcelain-chime","tick":"porcelain-tap","go":"porcelain-chime","shutter":"shutter-soft","success":"porcelain-chime","celebrate":"porcelain-chime"},"soundEnabled":false,"soundVolume":70,"celebrationPresetId":"sparkles","decorations":["floral-spray"],"animation":"gentle","cameraStage":"fullTemplate","minTouchTarget":72.0,"childrenMayBeGuests":false,"configurationRevision":1}}',
   'rendering', NULL, 1, NULL,
   '2026-11-14T18:19:50.000Z', '2026-11-14T18:20:30.000Z', NULL);

INSERT INTO session_photos VALUES
  ('c0000000-0000-4000-8000-000000000001', 0, 1, 0, 0,
   '20261114181000-00000001', '2026-11-14T18:10:00.000Z'),
  ('c0000000-0000-4000-8000-000000000001', 1, 1, 0, 1,
   '20261114181010-00000002', '2026-11-14T18:10:10.000Z'),
  ('c0000000-0000-4000-8000-000000000001', 1, 2, 0, 1,
   '20261114181030-00000003', '2026-11-14T18:10:30.000Z'),
  ('c0000000-0000-4000-8000-000000000002', 0, 1, 0, 0,
   '20261114182000-00000004', '2026-11-14T18:20:00.000Z'),
  ('c0000000-0000-4000-8000-000000000002', 1, 1, 0, 1,
   '20261114182010-00000005', '2026-11-14T18:20:10.000Z');

INSERT INTO session_outputs VALUES
  ('d0000000-0000-4000-8000-000000000001',
   'c0000000-0000-4000-8000-000000000001',
   'outputs/d0000000-0000-4000-8000-000000000001.png',
   '9999999999999999999999999999999999999999999999999999999999999999',
   2456789, 1200, 1800, 'png', 2, '2026-11-14T18:11:00.000Z', 'session'),
  ('d0000000-0000-4000-8000-000000000002',
   'c0000000-0000-4000-8000-000000000001',
   'outputs/d0000000-0000-4000-8000-000000000002.png',
   '9999999999999999999999999999999999999999999999999999999999999999',
   2456789, 1200, 1800, 'png', 2, '2026-11-20T09:30:00.000Z', 'rerender');

INSERT INTO export_batches VALUES
  ('f0000000-0000-4000-8000-000000000001', 'shared',
   'com.apple.DocumentManagerUICore.SaveToFiles', 2, 1,
   '2026-11-20T10:00:00.000Z');

INSERT INTO export_batch_items VALUES
  ('f0000000-0000-4000-8000-000000000001',
   'c0000000-0000-4000-8000-000000000001', 'finished',
   'd0000000-0000-4000-8000-000000000002',
   'hannah-theo-s-wedding-0001-20261114-1809.png'),
  ('f0000000-0000-4000-8000-000000000001',
   'c0000000-0000-4000-8000-000000000001', 'original',
   '20261114181030-00000003', 'hannah-theo-s-wedding-0001-photo2-retake1.jpg');

INSERT INTO pending_file_deletions VALUES
  ('originals/20261101120000-deleted0.jpg', '2026-11-20T10:05:00.000Z');

-- Version 7 (M09): phone delivery.
INSERT INTO event_delivery_options VALUES
  ('e0000000-0000-4000-8000-000000000002', 1, 0, 5, 150);

INSERT INTO delivery_pairings VALUES
  (1, 'https://photos.example.test', 'b2000000-0000-4000-8000-000000000001',
   'Ballroom booth', 'Porcelain Booth', '2026-11-10T09:00:00.000Z', 0,
   '{"ready":true,"reasons":[],"brandName":"Porcelain Booth","privacyUrl":"https://photos.example.test/privacy","termsUrl":"https://photos.example.test/terms","supportContact":"help@example.test","linkDaysMax":14,"previewMaxBytes":600000}',
   '2026-11-14T18:00:00.000Z');

INSERT INTO delivery_intents VALUES
  ('f1000000-0000-4000-8000-000000000001',
   'c0000000-0000-4000-8000-000000000001',
   'e0000000-0000-4000-8000-000000000002',
   'd0000000-0000-4000-8000-000000000001',
   '0147', 0, 'pd-consent-1',
   'abababababababababababababababababababababababababababababababab',
   '2026-11-14T18:11:30.000Z', 'en-US', 5, 150, 0,
   'k1000000-0000-4000-8000-000000000001', 'finished', NULL,
   'f2000000-0000-4000-8000-000000000001', 'delivered',
   '2026-11-14T18:12:40.000Z', NULL, 1, NULL,
   '2026-11-15T18:11:30.000Z',
   '[{"phase":"queuedLocally","at":"2026-11-14T18:11:30.000Z"},{"phase":"delivered","at":"2026-11-14T18:12:40.000Z"}]',
   '2026-11-14T18:11:30.000Z', '2026-11-14T18:12:40.000Z'),
  ('f1000000-0000-4000-8000-000000000002',
   'c0000000-0000-4000-8000-000000000001',
   'e0000000-0000-4000-8000-000000000002',
   'd0000000-0000-4000-8000-000000000001',
   '0100', 1, 'pd-consent-1',
   'abababababababababababababababababababababababababababababababab',
   '2026-11-14T18:12:00.000Z', 'en-US', 5, 150, 1,
   'k1000000-0000-4000-8000-000000000002', 'queued', NULL, NULL, NULL,
   NULL, 'OFFLINE', 2, '2026-11-14T18:13:00.000Z',
   '2026-11-15T18:12:00.000Z', '[]',
   '2026-11-14T18:12:00.000Z', '2026-11-14T18:12:30.000Z');

INSERT INTO delivery_remote_revocations VALUES
  ('f2000000-0000-4000-8000-000000000009', '2026-11-20T10:06:00.000Z');
