# Porcelain Photo Booth — UI/UX and Screen Contract v3.2

## UX-00: Product language
The Porcelain UI evokes carefully crafted analog photography instruments, subtle cream enamel, warm paper and champagne metallic controls. No exaggerated skeuomorphic textures, generic gradients or deceptive low-contrast neumorphism. Operator feels powerful and organized; Guest feels calm, warm and simple. UI content is accessible and localized-ready; no hardcoded copy inside reusable widgets. Visual reference: `reference/15_screen_concept_reference.png` represents aspiration, not exact layouts/correctness.

## UX-01: Semantic design tokens (initial proposed tokens; adjust after on-device contrast review)
```
color.canvas        #F5F0E9
color.surface       #FAF7F1
color.raised        #EEE6DC
color.inset         #DCD1C3
color.primaryText   #493E34
color.secondaryText #74685D
color.accent        #AF885E
color.accentStrong  #815F3D
color.divider       #D8CCBD
color.success       #416851
color.warning       #98622E
color.danger        #9D4640
radius.control      16 dp
radius.card         24 dp
radius.dialog       28 dp
space.base          4 dp; space.unit = 4,8,12,16,20,24,32,40
motion.tap          120-180 ms; motion.modal ~200-260 ms
```
These are palette candidates; verify accessible contrast of all text, selected states and controls. Distinct focused/selected outlines mandatory. Elevation shadows are presentation aids only; pressed state includes visible border, inset effect and slight translation. Semantics and reduced-motion support. All touch targets >=44 logical dp; guest primary buttons generally >=72 dp. Text typography: platform font/body with carefully licensed serif for headings; preview and export must use known embedded fonts for deterministic template text.

## UX-02: Theme profiles
`ThemeTokens` drives color, text styles, radii, surfaces, highlights, depth, motion and decorative graphic selection. Three named profiles: Porcelain Studio (default, completed M02), Vintage Light Oak (light wood kiosk harmony), Darkroom Walnut (dark retro). Each theme must preserve accessibility. Appearance persists per booth, with optional event override, and preview before apply. Changing app theme does not secretly recolor operator-authored photo templates.

## UX-03: Global responsive layout
The app is tablet-first. Studio uses nav rail / stacked pane in landscape, collapses inspector and layer tree into accessible tabs/sheets in narrower portrait. Guest uses full-bleed or framed camera preview proportionally, with controls anchored to safe areas. Each booth stores preferred orientation portrait/landscape. Studio can adapt independently. Rotation changes must preserve selected editor layer, undo history, and in-flight session. Do not force rotation during active capture without policy. iPad OS orientation lock requires full-screen deployment configuration where needed; Android large screens require physical verification. Provide operator warning if device does not honor lock. Below 600 dp (split screen, or a phone opening the web test build) the Studio keeps its width for content: a top bar with the wordmark, Diagnostics and Lock Studio, and the other five sections in a bottom bar (UX-P1, CR-003).

## UX-04: Global navigation model
Startup -> First Run if needed -> PIN login/unlock -> Studio Dashboard. Studio sections: Home, Events, Templates, Gallery, Settings/Diagnostics. `LaunchBooth` requires valid event and preflight; enters isolated Guest route subtree. Guest escape gesture/menu absent; operator exit via discreet long-press or multi-step gesture plus PIN, discoverable in operator documentation but not by ordinary guest taps. PIN verifies before any Studio route. Guest screens cannot open platform file share/picker. Distinct platform back-button interception; no route to prior guest/session.

## UX-05: Operator screen specifications
Each item states its critical interaction and empty/loading/error states. No dead controls.

**S01 Onboarding**: Welcome -> privacy and storage explanation -> create PIN with confirmation -> choose booth name/theme -> camera permissions explanatory interstitial -> test camera -> sample event. Skip noncritical demo; required operator access must be configured. Retry/cancel for permission denial, documented PIN recovery.

**S02 Dashboard**: Hero Start Booth action (disabled with explanation until valid event), last active event summary, Events/Templates/Gallery/Settings cards, camera/storage/preflight status. Empty state: create event; diagnostics warning: accessible repair shortcut. No fake session statistics: the Gallery card counts the stored sessions (UX-P1).

**S03 Events List**: Filter Active/Draft/Archived, search, event cards with preview thumbnail and last session count, New, Duplicate, Archive, Open, Launch. Confirmation on destructive actions; event cards scalable and keyboard navigation supported. Each card opens with a cover in the event's guest look, its designs laid on it like prints with the default on top (UX-P1).

**S04 Event Editor**: Tabs General (title/date/venue), Templates (allowed/default/order), Capture (lens, orientation, preview/out mirroring, shots, countdown, retakes), Guest UI (welcome/consent/finish timeout), Output (size and JPEG/PNG), Privacy (retention). Save validates and persists atomically. Unsaved changes prompt; archived event editable only after restore decision.

**S04-Q New Event** (CR-003, owner 2026-10-25): three steps, Occasion (name required, date, venue, optional occasion that picks a fitting guest look), Look (experience pack; photo design from the library or a ready-made design, suited ones first; live welcome and print preview) and Ready (summary of the event and the booth defaults it starts from). Create and check the booth saves the event, activates it and opens its launch checks (Booth Mode still starts only there); Save as draft opens it in S04. A ready-made design joins the library when the event is created; photos per guest follow the design. A missing name is asked for only when the operator goes on; leaving with entered details asks first. On windows at least 980 dp wide the live preview and the step's actions sit in a pane beside the step and stay in view; narrower, they follow the step's content. No bar overlays scrolling content.

**S05 Event Preview / Launch**: Simulator with fixture images, output preview, preflight checks (camera, template assets, slot binding, storage, output, orientation) with blocking failures vs warnings. Start enters Guest lock only if critical checks pass. The heading carries a seal (gilded check when nothing blocks, a lock otherwise) and the counts of passed, warning and blocking checks (UX-P1).

**S06 Template Library**: Grid/list starter templates with aspect thumbnails, search/filter/tags, New, Duplicate, Import, Edit, Preview, Export, Archive. Clearly show template aspect ratio and reference count. Empty and damaged-asset states.

**S07 Template Studio Main**: Landscape: left tool rail (select, background, photo slot, PNG, text, shape, layers), central zoomable canvas, right inspector or layer list, toolbar with Back/Undo/Redo/Zoom/Preview/Save. Portrait: condensed top bar, bottom tool shelf, layers/inspector sheets. Visible selection bounding box and handles, current zoom percentage, guides, export/page-safe outline. Exit with unsaved work guarded.

**S08 Asset Browser**: Tabs Uploaded, Decorations, Backgrounds, Starter; thumbnail cards; import from sanctioned system chooser; detect transparent alpha; preview, rename, reuse, remove if unreferenced. Warn on huge/corrupt files, avoid temporarily located URIs.

**S09 Layer Tree**: All layers sorted by z, drag reorder, thumbnail/type icon, lock, visibility, duplicate, delete, rename. Global order includes photo slots and decoration layers; no implicit per-slot overlay hierarchy. Conflicting actions on locked layer disabled.

**S10 Layer Inspector**: Contextual properties x/y/width/height (document units), rotation, opacity, anchor, crop/focal point for photo slot, text font/alignment/line-height, shape fill/stroke, image fit/crop. Numeric precision and input validation; changes are undoable and persisted.

**S11 Template Preview**: Sample/photo-fixture composition with simulated slot inputs and exact output aspect, alternate export-quality zoom, warnings for missing assets/fonts, return to editor. Preview cannot hide clipping bugs with widget snapshots.

**S12 Template Package Management**: Import/select archive -> security validation -> asset check -> collision resolution (new ID/new revision) -> preview -> commit; Export package -> verification -> platform file share. Show progress, unknown version errors and actionable remediation.

**S13 Gallery**: Event selector, count and dates, thumbnail grid, select multiple, Export, Delete with confirmation, session statuses. No guest-visible access. Large events paginated and efficiently thumbnailized.

**S14 Session Detail**: Captured originals/retakes, preferred shot bindings, template revision, final outputs, image dimensions, timestamps, filter, export/re-render/recovery actions. Correctly label incomplete or failed renders.

**S15 Camera Settings**: Device cameras discovered, front/rear lens selection, live test, preview mirroring vs output mirroring, capture quality, permission state/error help. Feature capabilities shown only if supported.

**S16 Output Settings**: Presets (2x6/4x6 etc.), JPEG/PNG quality, disk usage estimates, export defaults, printer 'Not configured' state and explanation. No misleading working print controls.

**S17 Appearance Settings**: Porcelain/Light Oak/Darkroom previews, system motion, high-contrast preference, guest background style, operator layout preferences. Theme changes can be previewed/cancelled.

**S18 Device Diagnostics**: Camera test, file-write test, free storage, app/version, orientation support, power information if available, permission status, template asset audit, sanitized error history. Run self-test with measured outcomes and repair instructions.

**S19 Preflight Checklist**: Each check displays PASS/WARN/BLOCK with explanation; operator can open appropriate repair control, rerun, start if no blockers. Printer unconfigured is informational in export-only mode.

**S28 Operator Unlock**: Hidden guest escape entry -> PIN screen -> rate-limited verification -> explicit Exit Booth action -> Studio. On invalid PIN, don't reveal sensitive operator routes or device internals.

**S29 Operator Recovery**: Missing camera/template/storage/capture errors with repair guidance, session-preserving options, export logs and rollback to safe Guest Welcome when appropriate.

## UX-06: Guest screen specifications
**S20 Welcome**: Event greeting/logo/date optional; single very large tactile Start button; optional quiet privacy notice. Logo/decor chosen by operator, not branding hardcoded into export.

**S21 Template Selection**: Optional carousel/grid of approved template snapshots, one selection, large Continue; capacity to skip when only one active template. No editing operations.

**S22 Live Preview**: Built-in camera fills safe preview region without stretch; clear countdown start state, framing guide optional, status 'Photo 1 of 3', cancellation only if event allows. Guest controls large; camera settings hidden.

**S23 Countdown**: Large 3/2/1 numeral overlay (monotonic countdown), clear color/contrast, gentle visual feedback and haptics if supported; cannot accidentally fire after background/resume.

**S24 Capture Feedback**: Short flash animation, thumbnail/progress, inter-shot wait; only show 'captured' after durable original file storage. Failures are recoverable without losing existing shots.

**S25 Review/Retake**: All current selected photos in readable grid, next/edit option based on event policy, clear number of retakes remaining, confirm before full-session reset if it removes current selections. Retakes are new assets and chosen binding update.

**S26 Rendering**: Warm reassuring progress/in-progress animation, cancellable only if safe, explicit retry on failure, no 'saved' claim before verified file write. Keep session checkpoint.

**S27 Finished**: Display final output and actual success statement 'Saved to booth gallery' (operator-only storage). Print button absent or disabled with 'Printer not configured' (never imply a guest will take physical print). Large Done/Next Guest button; safe configurable auto-reset. Do not expose previous session's image on idle screen.

**S29 Guest-Safe Error**: Plain language, Retry or Call Attendant. Preserve original photos; do not present stack trace or raw storage path.

## UX-07: Mandatory interaction states
Buttons/cards: resting, pressed, hover/focus where relevant, selected, disabled (visible why), busy, error/success. Editor: no selection, selected, multi-selection if supported, locked, hidden, drag, resize, rotate, out-of-bounds, invalid input, dirty/saving/saved/recovery. Camera: unknown permission, denied, initializing, ready, interrupted, capturing, failed. Lists: loading, empty, data, error, partial import. Export: validating, rendering, writing, saved, failed, retry.

## UX-08: Screen design acceptance for both orientations
- No cropped action buttons/notch conflicts on tested devices.
- UI controls can be reached with fingers on the actual enclosure; camera remains unobstructed.
- Editor canvas zoom/pan, layer Inspector and Undo accessible portrait and landscape without losing document state.
- Guest welcome, preview, countdown, review and finish respond to orientation change or show explicit operator restriction.
- 44dp minimum controls and appropriate semantics/focus labels; large guest actions.
- Text contrast and visible selected/error states even in bright venue lighting.
- Navigation, save/exit dialogs, progress/empty/error states checked.
- Golden screenshot fixtures at a defined portrait and landscape logical size (choose based on certified devices).

## UX-09: Reference constraints
The 15-screen concept board from the earlier design exercise is an artistic design reference. It includes placeholder names, dates, images and example controls. None are production real user data. Do not bake screenshots as UI backgrounds or claim interactions simply by rendering artwork. Implement actual widgets, real persistence and UI state.

## v3.2 additional phone-delivery screens
**S30 Delivery choice**, **S31 Phone + consent**, **S32 Delivery queue/result**, **S33 private mobile download webpage**, **S34 Operator Delivery Settings**, **S35 Delivery Center**, and **S36 Delivery Diagnostics** added. Responsive on both platforms/booth orientations. S27 Finished links to S30 only if enabled, and always offers Done/Next Guest independently of network. Consent checkbox unchecked, proper number input/region gate, privacy+terms link and no marketing. Detailed UI states and microcopy are defined in `docs/PHONE_DELIVERY_UX.md`.

## Owner amendment 2026-10-17 — premium quality bar (CR-001)
The concept board is a mood reference to be exceeded, not copied. Keep its warmth and tactility; fix its conflicts with this spec (guest print/save/settings/back controls, single mirror toggle, missing states and portrait layouts, sample people). Binding requirements and the screen-by-screen critique: `docs/decisions/CR-001-premium-ux-quality-bar.md`. Acceptance: AC-0207–AC-0211.
