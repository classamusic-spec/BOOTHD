<!-- The owner's Experience Pack System v2.0 prompt, as given in the
     session that produced EP00 (verbatim). Acceptance criteria are
     cited as AC-EP01 to AC-EP17 (section 16, in order). -->

# PORCELAIN PHOTO BOOTH — EXPERIENCE PACK SYSTEM V2.0
## Complete Claude Code Add-On Master Prompt

**Feature:** Customizable Guest Experience Themes  
**Project:** Porcelain Photo Booth  
**Platform:** Flutter / Dart — iPadOS and Android tablets  
**Release Target:** First commercial release  
**Feature Priority:** P0  
**Integration:** Existing Porcelain Photo Booth v3.2 architecture

---

## 1. MISSION

Extend Porcelain Photo Booth into a premium, customizable event experience platform.

Operators must be able to choose an entire Guest Experience Theme during event creation, customize its presentation, preview the complete guest journey, and assign independently designed photo templates.

The two existing operator interfaces are APPROVED and must be preserved:

1. Clean Porcelain UI
2. Vintage Light Wood UI

Do not replace or redesign those interfaces without explicit approval.

The application must support distinct Guest Experience Themes with different visuals, controls, animations, countdowns, sounds, guest messaging, and photo template recommendations.

Do not implement themes as disconnected copies of the guest application.

All themes must share the existing camera, session, template rendering, gallery, MMS delivery, persistence, privacy, and recovery infrastructure.

## 2. APPROVED EXPERIENCE COLLECTION

Implement the following eight bundled experiences:

| ID | Experience | Visual personality |
|---|---|---|
| porcelain-classic | Porcelain Classic | Ivory, champagne, elegant tactile controls |
| vintage-oak | Vintage Light Wood | Warm wood, brass, vintage mechanical details |
| retro-film | Retro Film | Film reels, analog cameras, sepia and cream |
| disco-nights | Disco Nights | Midnight purple, neon accents, celebration |
| storybook-garden | Storybook Garden | Illustrated flowers, bees, playful garden details |
| midnight-gala | Midnight Gala | Art Deco, black, champagne, formal luxury |
| kid-party-arcade | Kid Party Arcade | Oversized toy controls, cheerful party graphics |
| retro-game-quest | Retro Game Quest | Original handheld and arcade-inspired gaming UI |

All eight must work in portrait and landscape guest layouts.

Two additional variants are required within Retro Game Quest:
- Handheld Retro
- Arcade Cabinet

Variants share the Retro Game Quest family but may differ in layout, visual assets, button treatments and countdown defaults.

## 3. THREE INDEPENDENT CUSTOMIZATION LAYERS

Keep these concepts separate:

### Operator App Appearance
Controls the dashboard, event management and Template Studio appearance.

Supported appearances:
- Clean Porcelain
- Vintage Light Wood

### Guest Experience Theme
Controls Welcome, Template Selection, Get Ready, Countdown, Camera Stage, Between-Shot Feedback, Review, Delivery and Finish.

### Photo Template
Controls the actual photographic composition, photo slots, text, backgrounds, foreground decorations, masks, framing and printed/exported image.

A guest experience must not force operators to use only photo templates from the same category.

Example: an event may use the Retro Game Quest interface with a minimalist portrait photo template.

Theme recommendations may be suggested but must not become unnecessary hard restrictions.

## 4. EXPERIENCE PACK ARCHITECTURE

Create a versioned, declarative ExperiencePack document model.

Required properties:

- schemaVersion
- packId
- packVersion
- displayName
- description
- themeFamily
- supportedVariants
- designTokenReferences
- typographyReferences
- screenLayoutPresetIds
- physicalButtonStyleId
- guestCopyDefaults
- countdownPresetId
- transitionPresetIds
- shutterEffectPresetId
- soundPresetIds
- celebrationPresetId
- decorativeAssetReferences
- compatibleOrientations
- accessibilityDefaults
- recommendedTemplateTags
- operatorCustomizableProperties

An EventExperienceConfiguration must store:
- selected pack ID and version
- selected variant
- custom colors where supported
- welcome message
- get-ready message
- finish message
- countdown override
- sound enabled/disabled and volume
- animation intensity
- celebration enabled/disabled
- camera-stage presentation mode
- linked photo template recommendations
- configuration revision

Snapshot the resolved configuration when a guest session begins.

A change to the event experience must not modify an active session.

Only bundled and validated assets and predefined components may be used.

Do not load arbitrary executable code or remote scripts from Experience Packs.

Unknown pack versions, missing assets or unsupported preset IDs must produce explicit validation errors or safe fallback to Porcelain Classic.

## 5. SHARED DESIGN SYSTEM

Build a physical-feeling control family that can be reused between experiences.

Required button families:

- PorcelainButton
- WoodButton
- ToyArcadeButton
- RetroGameButton
- GalaButton
- NeonPartyButton

All controls must share semantic action handling while supporting different presentations.

Each primary button must have:
- raised state
- pressed state
- disabled state
- loading state
- selected state where applicable
- keyboard/accessibility focus state
- large label and optional icon
- visual depth through highlights, shadows and borders
- pressed animation
- optional synchronized haptic/audio feedback
- clear high-contrast readable labeling

Guest-facing primary actions should normally have at least a 72-point touch dimension, preferably larger when layout permits.

Do not rely on a drop shadow alone to indicate that a control is interactive.

Use real touch feedback and reversible animation state.

Buttons must remain responsive while the camera is active and while decorative animations run.

## 6. KID PARTY ARCADE — DETAILED REQUIREMENTS

Create a friendly party-themed guest experience with a premium toy/arcade aesthetic.

### Visual identity

Suggested palette:
- Sunny yellow
- Coral
- Sky blue
- Mint
- Warm cream
- Rich dark outlines where needed for contrast

Visual motifs:
- Confetti
- Balloons
- Stars
- Friendly party shapes
- Oversized rounded panels
- Colorful toy-like bezels
- Large physical arcade-style buttons

Avoid an excessive number of simultaneous animated objects.

### Physical buttons

Implement a ToyArcadeButton that feels like pressing a large plastic toy or arcade button.

Requirements:
- pronounced raised idle surface
- tactile rim or bezel
- clear pressed displacement
- responsive release
- readable label
- optional press sound
- obvious disabled state
- no overly realistic visual effect that reduces usability

Example labels:
- LET'S PLAY!
- TAKE PHOTOS!
- GO!
- TRY AGAIN
- SEE MY PICTURES
- TEXT MY PHOTOS
- ALL DONE!

### Welcome screen

Large centered interactive START element.

Optional animated balloon or confetti decorations.

Simple friendly welcome message.

No small instruction paragraphs.

### Camera and countdown

Create Party Pop Countdown:

- Large 3, 2, 1
- Gentle bounce/squash movement
- Optional short pop sounds
- Friendly Get Ready animation
- Subtle star/confetti accents
- Clear Photo X of Y progress
- No rapid flashing or intense strobing

### Review and completion

Use two large clearly differentiated actions:
- KEEP IT!
- TRY AGAIN

Never trigger an actual retake until the correct photo and session state have been confirmed.

Completion may show a gentle confetti celebration and a large finish button.

### Kid-friendly delivery

Display simple instructions but retain the full compliant photo delivery consent process.

Where guests are children, phone entry and explicit delivery consent must be provided by an appropriate adult/guardian under the applicable event and legal policies.

Never automatically collect a child's number, enroll guests in marketing, or imply that consent is optional when actual messaging consent is required.

### Suggested bundled photo templates

Provide original editable templates:
- Birthday Blast Strip
- Balloon Party Portrait
- Carnival Ticket Photos
- Confetti Memories
- Rainbow Star Collage
- Party Champion Frame

Each template must use the existing non-destructive layered template document model.

All decorative PNG artwork must remain editable and independent of photo-slot clipping.

## 7. RETRO GAME QUEST — DETAILED REQUIREMENTS

Create an original vintage video game-inspired guest experience.

Include two presentation variants:

### Variant A — Handheld Retro

Appearance:
- warm cream or gray-beige console shell
- optional sage-green or muted pixel-screen palette
- embossed bezel
- thick rounded screen border
- decorative D-pad and circular face-button motifs
- readable retro-inspired typography
- subtle physical plastic highlights

The guest camera appears within the screen-like stage when Live Template Mode is enabled.

An oversized tactile START button begins the session.

### Variant B — Arcade Cabinet

Appearance:
- bold arcade marquee
- dark housing or colorful cabinet trim
- illuminated but restrained button accents
- digital score-style headings
- oversized round physical controls
- decorative joystick motifs

Do not require guests to operate an actual joystick or D-pad.

Primary actions must remain accessible touchscreen controls.

### RetroGameButton

Support raised plastic, inset pressed state, broad touch area, distinct focus and disabled appearance.

Do not make pixel text so small that it becomes unreadable.

### Guest wording

Welcome:
- PRESS START
- PLAYER ONE READY?
- NEW GAME

Countdown:
- READY?
- 3, 2, 1
- GO!

Between shots:
- NICE MOVE!
- NEXT ROUND
- PHOTO 2 OF 3

Review:
- LEVEL COMPLETE
- KEEP THIS PHOTO
- TRY AGAIN

Finish:
- MISSION COMPLETE
- PHOTOS SAVED
- SEND TO PHONE

### Countdown presets

Arcade Start Countdown:
- READY?
- Large pixel-inspired numeric countdown
- GO!
- Optional original synth/beep cues

Handheld Boot Countdown:
- STARTING...
- Numeric countdown
- READY!

All effects must be subtle enough to leave the camera visible and keep capture timing deterministic.

### Suggested bundled photo templates

Create original editable compositions:

1. Player One Portrait
2. High Score Photo Strip
3. Handheld Screen Collage
4. Level Complete Frame
5. Arcade Ticket Memories
6. Pixel Hearts Portrait
7. Four-Player Photo Grid
8. Retro Quest Snapshot

Useful decoration elements include:
- original pixel heart icons
- progress bars
- score labels
- pixel borders
- coin-style decorative circles
- lives counters
- game achievement badges
- arcade marquee labels
- original game HUD-inspired decorations

Avoid protected logos, existing video game characters, distinctive commercial handheld silhouettes, proprietary fonts, and recognizable copied game screens.

Everything must be an original design.

## 8. LIVE TEMPLATE CAMERA INTEGRATION

The selected photo template must render around the live camera preview using the existing shared scene graph.

The active photo slot shows the moving camera feed.

Previously captured slots show saved photos.

Remaining slots show configured placeholders.

Foreground transparent PNG artwork must overlap live camera slots according to layer ordering, without inappropriate clipping.

Experience-specific decorations should render in the guest UI layer unless they are intentionally added to the final photo template.

Countdowns, Start buttons, game score-like guest progress messages and temporary UI animations must NEVER appear in the exported photo unless they are separately defined as actual template layers.

Support:
- Full Template Mode
- Camera-Focused Mode

Both must respect source image aspect ratio, cropping, transform geometry and operator configuration.

## 9. COUNTDOWN ENGINE

Create a shared CountdownPreset system.

Required bundled presets:
- Porcelain Press
- Vintage Mechanical Flip
- Film Leader
- Disco Pulse
- Storybook Magic
- Party Pop
- Arcade Start
- Handheld Boot
- Gala Elegant

Countdown state and capture scheduling must remain independent of animations.

Presentation widgets subscribe to the authoritative session countdown state.

A dropped animation frame must not change capture time.

Lifecycle interruption, cancellation or operator exit must prevent an unintended delayed capture.

Use a monotonic time source.

Support reduced motion and silent operation.

Do not use rapid flashes.

## 10. SOUND AND HAPTICS

Support locally bundled original sound effects:

Kid Party Arcade:
- toy button press
- soft pop
- cheerful confirmation
- gentle celebration chime

Retro Game Quest:
- arcade start
- select beep
- countdown tick
- original level-complete sound

Respect device audio configuration, event sound settings and accessibility preferences.

Sounds must not block state transitions.

Mute and reduced-stimulation configurations must remain usable.

No continuous background music required for first release.

## 11. EVENT CREATION — EXPERIENCE BUILDER

Update the Event Creation workflow:

Step 1: Event details
Step 2: Guest Experience selection
Step 3: Experience customization
Step 4: Photo template selection
Step 5: Camera and capture configuration
Step 6: Delivery settings
Step 7: Full experience preview
Step 8: Preflight and launch

The Experience Picker displays visual cards for all eight packs.

Selecting a card previews its appearance and countdown.

Provide customization controls for:
- Variant
- Welcome text
- Get Ready text
- Finish message
- Optional event logo
- Supported accent colors
- Countdown preset
- Sound toggle and volume
- Animation intensity
- Celebration behavior
- Preview camera layout mode

Provide Reset to Pack Defaults.

The operator must be able to switch experiences without losing event or photo template settings.

Do not force an operator to edit JSON to customize an event.

## 12. FULL EXPERIENCE PREVIEW

Implement a Preview Experience mode that simulates the entire guest journey:

Welcome → Template Choice → Live Template Camera → Get Ready → Countdown → Capture Feedback → Review → Delivery → Finish.

Support portrait and landscape previews.

Use synthetic/sample photographs and mocked camera services in simulation mode.

Clearly label simulation.

Preview must never send real MMS messages, create a real paid message, or accidentally store fake content as completed event sessions.

Provide controls to restart the preview and change the selected Experience Pack.

## 13. PHOTO TEMPLATE RECOMMENDATIONS

Extend template metadata with:
- categoryTags
- recommendedExperienceIds
- occasionTags
- ageSuitabilityNotes
- visualStyleTags
- defaultCaptureCount
- optionalPackVariant

Use this metadata to recommend photo templates during event setup.

Recommendations must not prevent selection of unrelated templates.

Build editable starter template packages for Kid Party Arcade and Retro Game Quest.

Template assets should be licensed appropriately, imported into managed storage, and validated.

## 14. PERFORMANCE AND FALLBACKS

Experience Packs must work offline once bundled.

Cache static assets.

Avoid decoding full-size illustrations every frame.

Separate camera preview repainting from static decorations and animated guest controls when practical.

Measure animation smoothness and memory on actual iPad and Android hardware.

Provide:
- missing asset fallback
- fallback button style
- standard countdown fallback
- reduced-motion fallback
- silent sound fallback

An animation failure must never cancel a successful camera capture or lose saved images.

## 15. TESTING REQUIREMENTS

Add automated tests for:

- pack manifest validation and migrations
- event-specific configuration persistence
- active-session configuration snapshots
- pack switching and reset-to-default
- countdown overrides
- portrait and landscape layouts
- large-button touch targets
- pressed, disabled and loading states
- reduced-motion fallbacks
- audio disabled behavior
- missing assets and unknown preset IDs
- template recommendations
- multi-slot live camera overlays
- transparent PNG z-order and clipping
- preview simulation isolation
- countdown exclusion from final exports
- delivery consent behavior unaffected by theme
- offline camera/gallery operation
- no unintended photo captures after cancellation

Add widget golden tests for all eight themes in both orientations.

Validate important accessibility semantics and contrast.

Run physical-device integration and performance tests on a certified iPad and Android tablet.

## 16. ACCEPTANCE CRITERIA

The add-on is ready when:

1. All eight experiences are selectable during event creation.
2. Both operator UI appearances remain unchanged.
3. Kid Party Arcade includes distinct tactile controls, countdowns and original editable starter templates.
4. Retro Game Quest includes Handheld Retro and Arcade Cabinet variants.
5. Guest-facing screens consistently follow the selected pack.
6. Portrait and landscape experiences are fully functional.
7. The operator can customize allowed settings and reset to defaults.
8. Full Experience Preview can simulate the entire journey.
9. Live camera integration uses the existing template scene graph.
10. Captured photographs render correctly into the selected photo template.
11. Final exports never contain temporary UI countdown graphics.
12. MMS delivery continues using the existing shared consent and delivery infrastructure.
13. Missing optional theme assets do not cause session failures.
14. Reduced-motion and muted versions are usable.
15. Automated tests pass.
16. Physical iPad and Android testing is documented.
17. No copyrighted game UI or unlicensed assets have been incorporated.

## 17. IMPLEMENTATION MILESTONES

EP00 — Inspect existing app architecture and approve the integration plan.

EP01 — Versioned Experience Pack schema, registry, manifest validation and migrations.

EP02 — Shared physical-button design system and guest presentation tokens.

EP03 — Countdown Engine, audio presets and accessibility fallbacks.

EP04 — Kid Party Arcade experience and starter photo templates.

EP05 — Retro Game Quest, both variants and original gaming photo templates.

EP06 — Integration of all eight experiences into the shared guest screen framework.

EP07 — Event Creation Experience Builder and customization persistence.

EP08 — Full Experience Preview and photo template recommendations.

EP09 — Golden tests, integration tests, device performance, accessibility and regression verification.

Execute these stages incrementally. Incorporate approved work into the existing M02, M03, M05, M07 and delivery-related milestones without creating a second application or duplicating foundational services.

## 18. CLAUDE CODE EXECUTION RULES

Before implementing:
- Read CLAUDE.md and all applicable project specifications.
- Inspect the actual repository.
- Identify existing reusable components.
- Propose data migrations and affected files.
- Identify package/API constraints.
- Produce a milestone acceptance plan.

During implementation:
- Keep builds passing.
- Use typed models and protocol-driven services.
- Write tests with each feature.
- Do not introduce unreviewed external dependencies.
- Do not hardcode entire duplicate guest flows per theme.
- Do not modify camera, rendering, MMS or storage behavior merely for appearance.
- Do not claim physical-device tests have passed without evidence.
- Do not claim design assets are commercially licensed without verifying provenance.

After each stage:
- Run formatting and static analysis.
- Run applicable automated tests.
- Perform available platform builds.
- Report PASS, FAIL or BLOCKED with evidence.
- Document files changed and remaining work.
- Stop for approval before beginning the next stage.

First assignment: **EP00 only — inspect the current repository and produce the integration plan. Do not implement the entire add-on in one pass.**
