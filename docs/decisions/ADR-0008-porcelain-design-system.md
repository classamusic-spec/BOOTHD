# ADR-0008: Porcelain design system, theme profiles and adaptive Studio shell

- Status: Accepted (M02, 2026-10-18). Owner sign-off on the visual result
  (AC-0209 "exceeds the board") is pending.
- Implements: UX-01, UX-02, UX-03, UX-07, S02, S17 (part), CR-001 items 1–8.
- Covers: AC-0201..AC-0211. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M02).
- Widens a layer allow-list (ADR-0005): `core` may import
  `material_symbols_icons`.

## Context

CR-001 makes the concept board a mood to exceed, with measurable bars:
guest text at 7:1, other text at 4.5:1, boundaries and focus at 3:1, 44 pt
or larger targets, every state designed, both orientations for every
screen, licensed type and icons, purposeful motion with a reduced variant.
UX-01 proposed palette values "to adjust after contrast review"; some fail
the bar (below).

## Decision

### 1. Tokens

- `PorcelainTheme` is a `ThemeExtension` carrying `PorcelainColors` (34
  colour roles) and `PorcelainTypography` (24 styles), so theme changes
  interpolate. Spacing, radii, sizes, breakpoints, motion and the depth
  recipe are constants (`lib/core/design_system/`).
- Features and shared widgets use roles only. A test rejects raw colour
  literals outside `lib/core` (the M01 spike's fixture colours excepted).
- `buildPorcelainThemeData` maps tokens onto Material's `ThemeData` for the
  few stock widgets still used (licence page, text selection, spikes).

### 2. Palettes (three profiles, each standard and high contrast)

Porcelain Studio (default, complete), Light Oak and Darkroom Walnut share
every role, so switching profile changes no feature code (AC-0206).
Changes from the UX-01 proposals, all from the contrast review:

| UX-01 proposal | Problem | Adopted |
| --- | --- | --- |
| secondaryText `#74685D` | 4.37:1 on raised `#EEE6DC`: fails 4.5 | `inkMuted` `#66574A`: 5.35–6.83:1 on every surface |
| White text on accent `#AF885E` | 3.23:1: fails 4.5, far from the 7:1 guest bar | Champagne-gold fill (`#E6CD9B` to `#D4B078`) with espresso ink `#2A2019`: 7.8–10.3:1 |
| accent `#AF885E` for meaningful icons | 2.6:1 on the canvas: fails 3:1 | `accentIcon` `#9A7646` (3.4–4.1:1); the light gold survives as decorative `ornament` only |
| primaryText `#493E34` | 6.9:1 on inset `#DCD1C3`: below the 7:1 guest bar | `ink` `#33291F`: 11.0–14.0:1 on every surface, so all primary text meets the guest bar |
| raised `#EEE6DC` darker than canvas | inverted depth | raised controls are lighter than the canvas (`#FFFDF9` to `#F3EDE3`) |

The light gold fill has only 1.4–1.8:1 against the canvas, so primary
controls carry a gilded edge (`primaryEdge`, 4.3:1). Secondary controls and
wells carry an `outline` at 3.3–4.0:1. Pressable cards are identified by
their text and a 3:1 chevron or icon; their edge is decorative (WCAG
1.4.11 applies to the information needed to identify a control).

### 3. Contrast enforcement

- `test/design_system/contrast_test.dart` checks 82 token pairs in all six
  palettes against CR-001 thresholds, with a mutation guard.
- Every screen runs Flutter's text-contrast, Android and iOS tap-target and
  labelled-tap-target guidelines in portrait and landscape at the iPad and
  Android sizes, plus text contrast in the two other profiles.
- Finding: Flutter's text-contrast guideline samples a 1x render. Thin
  13 px text in `inkMuted` measured 3.1–3.4:1 there although its tokens are
  5.6–6.1:1, so the minimum text size is now 14 px and navigation labels
  use full `ink`. Likewise, sampled boxes must not overlap borders or
  shadows (sidebar label padding; captions clear of device-frame shadows).
  The guideline was not loosened.

### 4. Type

- Display: Cormorant Garamond Medium and SemiBold, used only at 26 px or
  more (tested). UI: Inter Regular, Medium and SemiBold, with tabular
  figures for counts and sizes. Unmodified upstream static instances with
  explicit weights, so rendering does not depend on variable-font axis
  handling. SIL OFL 1.1; licence texts bundled and registered on the
  licence page. Provenance and hashes: `docs/ASSET_PROVENANCE.md`
  (test-enforced).
- Guest styles are larger (welcome title 88 px, body 24 px, Start label
  32 px) and scale with the window via `GuestScale` (0.72 to 1.0).

### 5. Icons

Material Symbols Rounded (Google, Apache 2.0) through
`material_symbols_icons` 4.2960.0, wrapped by `PorcelainIcons` with
semantic names; only that file may import the package (tested). Chosen
over `phosphor_flutter` (last release 2024, lower pub score) for active
maintenance and variable fill, weight and grade axes: selected navigation
fills its icon; dark profiles use grade -25. Verified in the M02 release
APK: icon tree shaking keeps `fvar`/`gvar` and all four axes (82 glyphs,
15 MB to 137 KB).

### 6. Tactile depth

One painter (`TactileSurface`) draws every porcelain control: key and
ambient shadows from a continuous elevation, a vertical glaze, a rim
highlight, an inner shadow for wells and presses, the boundary, and a
2 dp focus ring 3 dp outside the shape. Pressed: inner shadow, shadows
collapse, 1 dp travel, 140 ms in and 180 ms out, held for at least one
press duration so quick taps are visibly acknowledged.

### 7. Interaction states

`Pressable` gives every control the same touch, keyboard (focus and
Enter or Space), pointer hover and accessibility behaviour. Disabled
controls always state why: the reason is the accessibility hint and is
shown as a toast when tapped. A test audits every screen for controls
that are neither enabled, busy nor explained (AC-0203). Busy, success and
error states show an icon and words, never colour alone.

### 8. Motion

Durations come from `PorcelainMotion.of(context)`, which is all-zero when
`MediaQuery.disableAnimations` is set. The operator's "Reduce motion"
choice sets that flag for the whole app; the platform setting always
applies and cannot be overridden. Section changes fade through; routes
fade and rise 2%; theme changes interpolate over 320 ms.

### 9. Studio shell and navigation

- `StatefulShellRoute` with six branches (Dashboard, Events, Templates,
  Gallery, Settings, Diagnostics) keeps each section's state; a custom
  container fades sections through.
- The sidebar (280 dp, wordmark, booth status) appears when the window is
  at least 1100 dp wide; otherwise a compact 104 dp rail that widens with
  text size. Breakpoints use the window the OS gives (ADR-0004).
- Settings is two-pane from 840 dp of content, otherwise list then
  detail; the open section is in the URL (`?section=`), so rotation keeps
  it.
- Developer tools (M01 spikes, component gallery) are routes only outside
  release builds, linked from Diagnostics.

### 10. Guest layout skeleton

`GuestLayout` picks `PortraitGuestLayout` or `LandscapeGuestLayout` from
its constraints, has three slots (message, one action, footer) and no
others, and is its own accessibility container so the guest area can be
audited. The welcome skeleton (S20) has exactly one control. Operators see
it through `/preview/guest-welcome` and as live miniatures; Booth Mode and
its isolated routes arrive in M07.

### 11. Appearance state

Riverpod `appearanceProvider` (profile, contrast, motion), in memory until
booth storage (M03). Themes are previewed before they are applied (S17);
contrast and motion apply immediately.

### 12. Goldens

`test/goldens/`: every screen in portrait and landscape at the iPad and
Android sizes for Porcelain Studio, at the iPad size for the other two
profiles, plus a full component gallery per profile and a high-contrast
dashboard (103 images, 1x, about 16 MB). Exact comparison, Linux only:
M01 showed same-version Linux hosts render identically, while macOS and
Windows rasterise text differently. Regenerate only after an intentional
change: `flutter test --update-goldens test/goldens/`.

## Consequences

- Copy is passed into shared widgets, never hard-coded there; screen copy
  still lives in feature files. Localisation tooling (gen-l10n) is a later
  decision.
- Golden updates add several MB to history each time; Git LFS is an option
  for the owner.
- The default typeface sizes and the stricter 1x contrast sampling make
  small text larger and darker than the board.
- Theme and accessibility choices reset on restart until M03.

## Open (owner)

1. Sign-off that the goldens exceed the concept board (AC-0209).
2. Confirm the palette changes above (UX-01 said values may change after
   review).
3. On-device checks belong to M11: legibility under venue lighting, 60 fps
   (120 Hz on ProMotion iPads) and the fonts on both platforms.
