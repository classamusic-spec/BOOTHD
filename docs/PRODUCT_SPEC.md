# Porcelain Photo Booth — Functional Product Specification v3.2

## P-01: Vision / success
A commercial event operator can configure a booth, design personalized layered photo templates, launch a locked guest experience, capture high-resolution images from the tablet, save template-composited print-ready photographs locally, and operate for hours offline on selected iPad/Android devices. The guest experience must be extremely simple; the editing power lives exclusively in Studio Mode.

## P-02: User roles
**Operator**: manages devices, events, templates, exports, gallery, privacy and diagnostics. **Guest**: launches a session, optionally selects a permitted template, captures and retakes allowed shots, views final composition, finishes. No guest login, previous-session gallery or direct export path. **Service technician** (optional concept, not separate v1 role): operator-level diagnostics.

## P-03: Non-negotiables
Cross-platform tablet support; user-configurable booth orientation per device (portrait/landscape); default Porcelain theme; offline-first; built-in camera; full advanced template editor in first release; original photo preservation; deterministic rendering; local gallery; export ready with printer later; commercial reliability.

## P-04: Navigation and feature areas
Studio: first run/setup, dashboard, Events List, Event Editor, booth Preflight, Template Library, full Template Editor, Asset Browser, Layer Tree/Inspector, Template Preview, Gallery, Session Details, Appearance, Camera, Output, Storage/Privacy, Device Diagnostics, Operator PIN. Guest: Welcome, optional Template Chooser, Preview/Countdown, Capturing/Between Shots, Review/Retake, Processing, Finished/Next Guest, Guest-Safe Error.

## P-05: Events (P0)
Fields: stable ID; title; optional date/venue/notes; created/modified timestamps; lifecycle [draft, active, archived]; selected theme; allowed template IDs and default template; camera lens; preview mirroring; output mirroring; orientation; countdown seconds; capture count (initially 1–4); inter-shot interval; individual/full-session retake policy and limits; guest template-selection enabled; filter preset; completion timeout; gallery retention setting; output preset; optional privacy/consent text. Event duplicate preserves configuration but creates a new ID and does not copy guest sessions. Archiving does not silently delete photos.

Rules: Active event must have at least one validated template; all referenced assets must be available; configured capture count must be compatible with photo-slot mapping or a documented mapping strategy; preflight checks camera permission, write access, free storage, supported orientation and export readiness. Event editing from Booth Mode prohibited. Templates can be shared across events; events reference immutable template revision on session start.

## P-06: Template library (P0)
Create from blank/preset, duplicate, rename, archive/delete with dependency warning, categorize/tag/search, thumbnail, compare document sizes, edit, preview with fixture/test images, export portable package, import/validate package, mark favorites. Starter templates should demonstrate portrait and landscape, strip and full-page, transparent PNG overlap, and text. License original decorative assets; placeholder assets must be appropriately labeled.

## P-07: Advanced Template Studio (P0, fully required)
- Canvas presets: 2x6, 4x6 portrait and landscape, 4x4; later custom physical size after renderer correctness, preferably part of v1 if tested.
- Logical page coordinate system independent of device-pixel ratio; guide for safe area/bleed/export page bounds.
- Layers: background (solid/gradient/image), photo slot (crop/fit/clip/mask, border), image/transparent PNG (scale/alpha), text (font/size/alignment/color), shapes (basic geometric fill/stroke); image decoration is an ordinary image layer, not a child of slot.
- Global z-order, visibility, lock, rename, copy/duplicate/delete, layer tree reorder, bring front/back, align/distribute basics, snap-to-center/edges, togglable guides/grid.
- Canvas multi-touch pan/zoom distinct from selected-layer drag; rotation and resize handles; aspect lock; exact x/y/w/h/rotation/opacity numeric properties; keyboard support if available; undo/redo via edit commands with gesture coalescing, autosave and save/reopen.
- Import transparent PNG/JPEG from supported platform pickers; managed copy and integrity validation; duplicate assets by ID/reference; inspect missing sources.
- Preview fixture photos, rendering export and warning for missing inputs and unsupported filters/fonts.
- Critically: slot clipping ONLY clips the photograph within it; global decorative images overlay slots and can extend outside slot edges. Artwork outside page bounds is visible in editor work area if enabled but not exported except explicit bleed.
- Persistence is editable JSON manifest + asset IDs, not a flattened image. Revisions and migration are compulsory.

V1 excludes collaborative editing, AI fills, remote asset marketplaces, animation timelines and nested smart-object libraries. Basic group selection may be P1 if it destabilizes MVP; layer grouping can be specified as a documented extension. Full individual transform tools are P0.

## P-08: Camera (P0)
Front/rear when supported; correct preview aspect ratio; explicit preview vs saved-output mirroring; configurable capture resolution from supported presets; automatic focus/exposure by default; optional framing guides; countdown 3/5/10 or integer configurable within safe range; shot progress; inter-shot pacing; visual flash; honest shutter feedback; non-destructive retakes; warm-up, interruption handling and camera diagnostics. Native preview must never be rasterized for high-res output. Camera choice and orientation are event/device-aware and hardware-gated.

## P-09: Guest session flow (P0)
Idle -> Preparing -> Template Choice (optional) -> Preview -> Countdown -> Capture -> (repeat as configured) -> Review/Retake -> Rendering -> Saved -> Finished -> Reset -> Idle. An explicit persistent session state machine is mandatory. Invalid transitions rejected. Lifecycle interruptions suspend capture and re-evaluate permissions/device, without accidentally firing delayed shutter actions. Save originals and durable session checkpoint before generating output. Retake results create new asset; previous originals retained until operator retention action. Finished-screen confirmation only after durable output. Auto reset must not interrupt in-flight capture or atomic save.

## P-10: Filters (P0 modest)
Natural, monochrome, warm vintage and faded film/soft film presets applied non-destructively and reproducibly. Operator assigns event default; guest filter selection optional later. Preserve settings, avoid permanently altering source photos.

## P-11: Local gallery (P0)
Event/session searchable browser, thumbnails, session details, original captures and retakes, template snapshot, rendered outputs, render/export status, re-render (new output), select/export batch, deletion by session/event, trash or confirmation as policy dictates. Gallery inaccessible to guest. Never make cloud visibility claims.

## P-12: Export and printing (P0/P1 boundary)
P0 local JPEG/PNG output at explicit pixel dimensions and output profile with job metadata, diagnostics, duplicate prevention and output integrity. File export through platform-authorized share/export UX in Studio Mode, with display of exact target location/status. No printer required. PrintService capability interfaces and states may exist, but printer selection/driver/hardware integration is explicitly later. Disabled printer control with explanation or hidden based on platform feature flag. P1 adds compatible system printing with physical validation. Dye-sub printer bridge/cut handling after printer selection.

## P-13: Offline and data ownership (P0)
No account or internet. All user-created documents and photos stored on-device with local export, retention, deletion and backup/restore. Session metadata in SQLite; files in managed app support directories; no reliance on temporary file picker locations. No automatic guest QR/download claims. Optional offline QR would require local network/server/device trust and is deferred. Concurrency must not corrupt gallery or templates.

## P-14: Security and privacy (P0)
First-run operator PIN; store verification safely, backoff on failed attempts, accessible reset/recovery guidance without insecure bypass. Studio routes guarded; exclude file picker and gallery from guest. App-level lock combined with OS Guided Access/managed Android lock-task setup. Operator-configurable event consent text and retention. No biometric face recognition, contact collection or audio recording. Limit requested permissions to actual app functions, subject to camera plugin requirements. Logs never contain guest image bytes or sensitive content. Backups/export include explicit privacy warning.

## P-15: Settings and diagnostics (P0)
Device name and booth profile, theme selector, guest portrait/landscape orientation, app accessibility/reduced motion, default lens and mirroring, capture test, storage dashboard, output profiles, export-only printer state, logs, app/build version, permissions status, self-test action, local backup/import, retention. Include a Booth Launch Checklist with blockers and warnings. Battery/thermal availability varies; capability probing and graceful unsupported states.

## P-16: Operator workflows (P0)
- First-run: intro -> privacy/permissions explanation -> PIN -> device/booth name -> theme -> test camera -> create first event or starter event -> ready.
- Prepare event: create/duplicate event -> choose/create templates -> assign capture settings -> validate/preflight -> enter Booth Mode.
- Recover booth: operator unlock -> diagnostics -> fix permission/asset/storage/camera -> resume -> session preserved or explicitly marked partial.
- Post-event: stop booth -> review gallery -> export outputs/templates -> validate backup -> archive or delete under retention policy.

## P-17: Quality, compatibility and launch (P0)
Test on one real iPad and one real Android tablet and expand certified list. Portrait and landscape on BOTH. Ability to run offline for extended period, repeated-session soak, low-storage errors, interrupted capture, crash during rendering, reboots, app backgrounding, template package corruption, accessible interaction, consistent print-size exports, no data loss in successful captures. Device matrix, deployment instructions, supported OS/device list, signed builds and operator manual required before commercial-ready claim.

## P-18: Explicit deferrals (revised v3.2)
**Approved narrow exception:** optional consented MMS preview with private finished-photo download link via a separate secure online service, defined in `docs/PHONE_DELIVERY_SPEC.md` and implemented in M09. Core photo-taking and export remain network-independent. Deferrals: general cloud sync, internet QR gallery, unrelated email delivery, marketing texts, guest accounts, subscriptions, AI effects, sticker marketplace, DSLR, animated GIF/video, multi-device sync and physical printer adapters. Do not mistake the approved optional MMS service for a general-purpose cloud backend.

## P-19: Out-of-scope assumptions requiring validation
No printer brand known; no specific physical iPad/Android tablet identified; no approved custom font license/assets; privacy regulations/event consent vary geographically; full screen/orientation capabilities vary by iPad configuration and Android OS/device mode. Do not present these as solved.

## P-20: Measurable top-level success criteria
1. Operator can create event and template from scratch offline.
2. PNG can overlap two slots while preserving transparency and export exactly as preview semantics.
3. Template survives save/reload/import/export without changing layout.
4. Both real tablet families can capture 1–4 stills and render final images with no internet.
5. Final 2x6 and 4x6 exports match requested pixels and correct orientation.
6. Gallery retains originals and final, supports batch export and deletion.
7. Portrait and landscape are independently configured, rendered and tested.
8. Guest cannot reach operator pages without PIN, and controls reset safely.
9. Repeated sessions, failure recovery, backup/restore and release tests are evidenced.
10. No real printing is claimed without a certified printer.

## v3.2 product scope — Optional phone-number photo delivery
Added guest feature: MMS JPEG preview + high-quality private download link, with explicit consent and a `No thanks` route. Wi-Fi/hotspot normally available but capture-to-export remains fully offline. New S30–S36 delivery screens plus operator event-level enabled/disabled setting, local queue and server delivery center. US phone recipient coverage initially; carrier/provider approvals and costs are prerequisites. Only finished composite uploaded; no raw camera originals. See `docs/PHONE_DELIVERY_SPEC.md` (normative for detailed behavior), `docs/PHONE_DELIVERY_UX.md` and `docs/PHONE_DELIVERY_ACCEPTANCE.md`. This replaces previous blanket SMS/cloud prohibition ONLY for this isolated optional service.
