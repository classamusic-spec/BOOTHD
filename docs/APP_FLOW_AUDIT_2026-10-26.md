# App flow and sticker placement audit — October 26, 2026

Requested scope: pull the latest main/default branch, understand and audit the
working app, combine the changes, and make sticker placement clean in the
Template Studio. The repository's default branch is
`claude/new-session-fh2zxl`, not a branch literally named `main`. Its latest
commit at fetch was `8563d1c`, already included in the working branch's merge
commit `e63e333`. The pull returned **Already up to date**.

## How the app works

| Stage | User journey and behavior | Main implementation |
| --- | --- | --- |
| Start and access | First-run setup explains local storage, sets the operator PIN and recovery, and configures the booth. Later starts use the access guard to route to Studio, unlock, or the running booth. | `lib/app/router.dart`, `lib/core/routing/access_redirect.dart`, `lib/features/onboarding/`, `lib/features/operator_access/` |
| Studio | Dashboard, Events, Templates, Gallery, Settings, and Diagnostics retain their own navigation stacks. Narrow windows have the upstream top/bottom navigation. | `lib/features/studio_shell/studio_shell.dart` |
| Make a template | Templates → New template offers searchable ready-made designs, occasion collections and blank formats. A choice creates a stored template and opens the editor. | `lib/features/template_library/`, `lib/core/templates/` |
| Edit and save | Independent photo, text, image and shape layers share one paint order. Artwork → Stickers & art adds editable PNG layers. Move, resize, rotate, reorder, undo and redo operate on the document; drafts autosave and Save creates an immutable revision. Preview and print export share scene semantics. | `lib/features/template_studio/`, `lib/domain/template/editing/`, `lib/core/composition/` |
| Create an event | Name/occasion → Look/design → Ready. A starter design joins the template library on creation. The event's capture count follows the chosen template. Create activates the event and opens launch checks; Save draft opens the event editor. | `lib/features/events/create/quick_event_screen.dart`, `quick_event_designs.dart` |
| Launch and capture | Launch checks inspect the selected templates, storage and camera readiness. Guest sessions choose a template when needed, count down, capture original photos, review/retake, render the full-resolution composition and reset for the next guest. | `lib/features/events/preflight_screen.dart`, `lib/core/booth/booth_session_controller.dart`, `lib/features/booth/` |
| Operator access | Holding the top-right corner for three seconds and entering the PIN opens the booth's operator controls and event photo reel. Guests cannot use Studio or browse earlier sessions. | `lib/features/booth/hidden_operator_exit.dart`, `booth_operator_screen.dart`, `booth_photo_reel.dart` |
| Keep the photos | Gallery provides session/event browsing and operator export. Template packages carry their referenced artwork. Capture, editing and local export do not require an online service. | `lib/features/gallery/`, `lib/core/templates/template_library.dart`, `lib/infrastructure/templates/zip_template_packages.dart` |

The browser review directly inspected the rebuilt startup and privacy screens.
The remaining flows were exercised through the app's isolated Flutter test
fixtures, including simulated camera sessions, rather than modifying an
operator's browser data or credentials.

## Placement fixes

1. **Oversized inserted stickers.** The artwork picker previously returned only
   an asset, so stickers followed the generic image default: centred at up to
   half-page size over the photos. The picker now preserves sticker intent.
   New stickers use at most 24% of the page's shorter side, preserve their
   source aspect ratio, and remain inside the print-safe margin. A bounded
   candidate search prefers clear space and minimizes overlap with text,
   photos and existing artwork. On a densely filled page it chooses the least
   overlapping candidate; placement is still editable, not a guarantee of
   collision-free automatic layout on every possible document.
2. **Distortion when resizing.** New stickers use `ImageFit.contain` and the full
   source crop, so changing a frame's edge cannot stretch or crop away the
   sticker. Imported/general images retain their existing behavior. Undo,
   redo, explicit save, reopen and asset-byte preservation are tested.
3. **Occasion header collisions.** Portrait sticker frames now end at x=332
   and title frames begin at x=360. Footer artwork ends at x=320 and captions
   begin at x=340. Every occasion companion is checked for artwork/title frame
   separation and rendered at its print dimensions without overflow warnings.
4. **Small-art preview differences.** Repeated portrait stickers now use the
   same 272-pixel print size. Artwork positions and sizes align to a four-pixel
   print grid, including the strip's 240-pixel footer sticker at y=1376. This
   keeps half/quarter-size previews aligned with print pixels. Existing image
   files, rendering tolerances and negative-control assertions were retained.

Sticker layers remain above the photos, independently selectable, and can be
intentionally dragged across photo boundaries. They are never clipped by a
photo-slot mask. No image-generation service, package dependency, document
schema migration, or messaging configuration was added by this audit.

## Verification and limits

- **PASS:** 691 focused tests covering access/setup, event creation, capture
  session logic, gallery, template library/editor, asset alpha, geometry,
  save/reopen, and preview/export parity. Log:
  `build/local-verification/app-audit-focused-tests.log`.
- **PASS:** all 40 affected preview comparisons on a focused rerun, with
  unchanged tolerances. These cases also ran in the 691-test pass. Log:
  `build/local-verification/sticker-preview-parity.log`.
- **PASS:** four screenshots of the real Template Studio widget using the
  bundled production fonts and an inserted, selected, saved sticker: iPad and
  Android viewport sizes in portrait and landscape. Log:
  `build/local-verification/sticker-builder-review.log`; PNGs:
  `build/local-verification/sticker-builder/`.
- **PASS:** 80 chooser, library and editor screen checks: all tablet sizes,
  200% text, labeled controls, tap targets, contrast and dead-control checks.
  Log: `build/local-verification/app-audit-screens.log`. The fresh run kept the
  host awake and allowed for host scheduling delays; behavior assertions were
  unchanged.
- **PASS:** 30 final geometry, library/editor interaction and screenshot checks
  after correcting the full print-safe margin on the narrow 2×6 strip. Log:
  `build/local-verification/sticker-final-placement-tests.log`.
- **PASS:** all 48 occasion prints rendered for review. Catalog:
  `build/local-verification/occasion-catalog/occasion-overview.png`.
- **PASS:** static analysis, formatting of the 10 changed/new Dart files and
  the release web build. Logs: `app-audit-analyze.log`, `app-audit-format.log`,
  `app-audit-web-build.log` under `build/local-verification/`.
- **PASS:** 223 additional checks against the clean committed code, with the
  unrelated local edits stashed: sticker geometry, every starter design,
  editor/library interactions, quick events, access, guest sessions and
  gallery/export. Clean-code analysis also passed. Logs:
  `app-audit-committed-tests.log`, `app-audit-committed-analyze.log` under
  `build/local-verification/`.
- The broad full-suite run was interrupted after host timeouts and cascading
  test-harness errors. It is not counted as a full-suite pass. Corrected-code
  focused reruns are the evidence above. Original log:
  `build/local-verification/app-audit-full-tests.log`.
- Physical iPad/Android camera capture and device certification were not run.
  Live phone delivery and external messaging were not exercised. The web build
  remains the repository's demonstration/test target.

Pre-existing startup/storage and onboarding edits were preserved separately
from the placement change. The earlier backup stash was retained.
