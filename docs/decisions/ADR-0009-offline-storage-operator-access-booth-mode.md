# ADR-0009: Offline storage, operator access, Booth Mode isolation and launch checks

- Status: Accepted (M03, 2026-10-18).
- Implements: A-05 (booth profile, events, event templates, template
  revision references), A-12 (operator PIN), A-15 (schema versions and
  migrations), P-05, P-13, P-14, S01, S04, S05/S19 (structure), S20 (Booth
  Mode welcome), S28 (operator exit), UX-04 (route isolation).
- Covers: AC-0301..AC-0306. Evidence: `docs/ACCEPTANCE_EVIDENCE.md` (M03).
- Builds on ADR-0005 (layers, DI, routing) and ADR-0008 (design system).

## Context

M03 is the first milestone that keeps data. CLAUDE.md requires Drift and
SQLite, managed application files, a slow salted PIN verifier with rate
limiting and a recovery protocol, guards between guest and operator
routes, and preflight checks that say NOT YET READY rather than invent
camera or render results. Everything must work offline.

## Decision

### 1. Database

- One SQLite database, `database/porcelain_booth.sqlite` under the app's
  private support directory, defined SQL-first in
  `lib/infrastructure/database/booth_schema.drift` (schema version 1).
- Tables: `booth_profiles` (one row), `app_settings` (one row: setup time,
  the booth's profile, the event running in Booth Mode), `operator_access`
  (one row: recovery-code verifier and attempt counters), `templates`,
  `template_revisions` (immutable: an update trigger aborts), `events`,
  `event_templates` (ordered allowed revisions, at most one default).
- Rules live in the domain (`EventRules`) and again in the schema, so a
  defect elsewhere cannot store an invalid event: CHECK constraints mirror
  `EventLimits`, enums are CHECKed text, a partial unique index allows one
  default per event, and foreign keys carry explicit actions (an event's
  template rows cascade with it; a revision in use cannot be deleted; the
  Booth Mode event reference clears if its event goes). Text limits count
  characters in both places (`length()` in SQLite, runes in Dart).
- Every connection: `foreign_keys = ON`, `journal_mode = WAL`,
  `synchronous = FULL` (a committed event survives power loss),
  `busy_timeout = 5000`.
- IDs are random UUID v4 strings from `Random.secure` (CHECK length 36),
  generated in the domain, never by SQLite, so they are stable across
  export and restore. Times are UTC ISO-8601 text; an event's date is a
  calendar date without a time zone.
- Enums are stored by name, never by index. Drift gave
  `PorcelainThemeProfile` an index converter because its name contains
  "INT" (type affinity); it is mapped by name explicitly.

### 2. Schema versions and migrations

- `drift_dev make-migrations` keeps a JSON dump per version
  (`drift_schemas/booth/`) and generated schema classes
  (`test/drift/booth/generated/`). The migration test opens a seeded file
  for every version (`test/drift/booth/fixtures/seed_v<N>.sql`), upgrades
  it and checks data and the resulting schema against a fresh database.
  Each new version must add a dump, a seed and a step.
- A database written by a newer app is refused before anything is changed
  (the startup screen says to update the app; no retry). A version this
  app cannot migrate is refused the same way. Drift calls `onUpgrade` for
  downgrades too, so the guard checks the direction itself.
- `tool/check.sh` regenerates all Drift output and fails if anything
  changes, so a schema edit without a version bump, dump and generated code
  cannot pass CI (mutation-tested: an edited CHECK limit and a hand-edited
  `.g.dart` both fail).

### 3. Managed files

`FileManagedStorage` owns six private areas under the support directory:
`database`, `originals`, `outputs`, `templates`, `assets`, `staging`.
`prepare()` creates them at startup; `probeWrite()` writes 4 KiB to
staging, reads it back and deletes it, and is the storage launch check.
Photo bytes arrive in M06; the stage, validate, rename and journal
protocol is CLAUDE.md's and lands with the first writer (M04/M06), with
fault injection in M10.

### 4. Operator PIN and recovery code

- PIN: exactly six digits. One digit repeated, a straight run (123456,
  987654) and a short list of common PINs are refused at setup.
- Verifier: PBKDF2-HMAC-SHA256, 120,000 iterations, 16-byte random salt,
  32-byte output, stored as `pbkdf2-sha256$<iterations>$<salt>$<hash>`.
  Derivation runs on a short-lived isolate; comparison is constant-time;
  the iteration count travels in the verifier, and a verifier below the
  current count is replaced after its next successful check. RFC 7914
  PBKDF2-SHA256 vectors pass. Host cost (AOT, this Linux VM): 100,000
  iterations 0.31 s, 200,000 iterations 0.63 s; tablet timing is a device
  check (M11).
- Storage is split: the PIN verifier sits in platform secure storage (iPad
  Keychain, "after first unlock, this device only", never synchronised;
  Android encrypted with a Keystore-wrapped key, `resetOnError: false` so
  a passing fault cannot silently erase it). The recovery-code verifier
  and the attempt counters are in the database. Neither the PIN nor the
  code is ever stored or logged; errors carry platform codes only.
- Honest limit: six digits are one million candidates, so no iteration
  count makes a stolen PIN verifier safe offline. The primary protection is
  that the verifier never leaves the sandbox and secure storage (and is
  excluded from backups, section 9); the rate limit stops guessing at the
  booth. The 16-character recovery code (Crockford base32, 80 bits) is
  strong offline.
- Rate limit, persisted in the database so a restart does not reset it:
  PIN five free tries, then 30 s, 1 min, 5 min, 15 min, 30 min and one hour
  per further failure (about 24 guesses a day once saturated); recovery
  code three tries, then 1 min, 5 min, 15 min, one hour. If the clock
  reads earlier than the last failure, the full lockout runs from now.
  Checks are serialised, so rapid taps cannot race the counter. A success
  clears the counter.
- Recovery protocol: the code is shown once at setup (typing it back is
  not required; a switch confirms it was written down). "Forgot PIN?" takes
  the code, then a new PIN, then shows a new code; the old code stops
  working. If secure storage cannot be read (missing or unreadable PIN
  verifier), unlock offers the recovery code instead. With neither PIN nor
  code, the only way back is clearing the app's data, which the setup
  screen states.
- A successful check yields an `OperatorProof` valid for five minutes;
  changing the PIN, issuing a new code and leaving Booth Mode require one.

### 5. Access phases and the route guard

`AccessController` holds one phase: `starting`, `startupFailed`, `setup`,
`locked`, `operator` or `booth`. A pure function, `accessRedirect(phase,
location)`, is GoRouter's top-level redirect, re-run on every phase change
and every navigation, including deep links and platform route pushes:

- `booth`: everything except `/booth` and `/booth/operator` goes to
  `/booth`; system back on the welcome does nothing.
- `locked`: Studio locations go to `/unlock?from=<path>`, everything else to
  `/unlock`; after unlocking, `from` is honoured only if it is a Studio
  path with no scheme or host.
- `operator`: setup, unlock and booth locations go to the dashboard.
- `setup` and `startupFailed`: only their own screen.
- `starting`: the request waits at `/starting?from=` and is judged by the
  phase that follows, so a cold-start deep link is neither lost nor
  allowed past the guard.

Every cold start opens locked (or in Booth Mode, if it was running), never
unlocked. The Studio's Lock button returns to the PIN screen.

### 6. Booth Mode (M03 scope)

- Launched only from the launch checks of an active event with no
  blockers. The event is stored in `app_settings`, so a restart resumes
  Booth Mode instead of opening the Studio.
- The welcome has one control, Start, which says in guest-safe words that
  the booth is not ready (sessions are M07). The operator exit is a
  96 dp corner that needs a three-second hold, is excluded from the
  accessibility tree and leads to a PIN pad that returns to guests after
  45 s untouched.
- The whole subtree, PIN pad and toasts included, wears the event's theme
  override (`BoothEventTheme`), so a theme chosen for a dim venue never
  flashes to a bright Studio screen.

### 7. Events and templates

- Lifecycle: draft to active only when `EventRules` finds no blocking
  issue; active back to draft; draft or active to archived; archived back
  to draft (reopen). Archived events are read-only. Duplicate copies
  settings and templates into a new draft with a new ID and "(copy)".
- Activation needs a title, valid settings, one to twelve allowed
  templates without duplicates, a default among them, and every template
  present with exactly as many photo slots as the event takes photos (one
  photo per slot; a mismatch blocks). An archived template only warns.
- New events take their camera, mirroring, guest orientation and output
  defaults from Settings (booth profile).
- M03 has no template library UI; templates appear in the database from
  M04/M05 (tests seed them directly).

### 8. Launch checks (S05/S19 structure)

`Preflight.evaluate` turns the event, its templates, device facts and
capability probes into checks with five statuses: passed, info, warning,
blocked, not yet available. Not yet available blocks the launch and names
the milestone that brings it: camera presence and permission (M06), free
space (M06), the renderer (M04) and template assets (M04). Kiosk lock is a
warning (M10). Storage is a real write probe. Orientation compares the
event's preference with the window and warns when the tablet is held the
other way. "Start Booth Mode" is enabled only when nothing blocks, and
blocked checks link to the editor tab that fixes them.

### 9. No platform backup of booth data

First-run setup promises that photos stay on the tablet. Android Auto
Backup would upload app data to the device owner's cloud account, and a
restored secure-storage value cannot decrypt on another device (its key
is in the old device's Keystore). So the Android app sets
`allowBackup="false"` (Android 11 and earlier) and data-extraction rules
that exclude every domain from cloud backup and device transfer (Android
12 and later, where `allowBackup` alone still permits transfer). On iPadOS
the Keychain item is "this device only", but the app's files are included
in iCloud and computer backups unless excluded per directory, which needs
a small native call; that is M10 (backup/restore and privacy), recorded as
a risk. The app's own verified backup is also M10.

### 10. Dependencies added

| Package | Licence | Why |
| --- | --- | --- |
| drift 2.35.2, drift_flutter 0.3.1 | MIT | CLAUDE.md storage choice |
| sqlite3 3.5.2 | MIT | SQLite bindings. Its build hook downloads a prebuilt SQLite (public domain) for each target with a pinned SHA-256, so the first build needs network; the app does not |
| flutter_secure_storage 11.2.0 | BSD-3-Clause | Keychain and Keystore-backed secret storage |
| collection, meta | BSD-3-Clause | Already transitive; now direct |
| drift_dev 2.35.1, build_runner 2.16.2 (dev) | MIT, BSD-3-Clause | Code and schema generation. build_runner 2.17.0 is retracted and 2.17.1 needs build 5, which drift_dev does not support yet |

`sqlite3_flutter_libs 0.6.0+eol` and `sqlcipher_flutter_libs 0.7.0+eol`
appear in the graph through drift_flutter. Both are deliberately empty
packages whose purpose is to keep the old native build scripts out of
builds; they ship no code.

### 11. Interface decisions made along the way

- Toasts are a root-overlay entry that lets taps through, rather than a
  SnackBar inside the shell's Scaffold, which covered sheet buttons. One
  at a time, announced to assistive technology, fading in 200 ms (none
  with reduced motion), and they keep the caller's theme.
- Setup puts its Back button and progress inside the card, so on any
  tablet size or text scale the card, not loose text, meets the corner
  ornament.
- The theme animates only after startup, so a cold start does not fade in
  from the default theme.

## Consequences

- Events, settings and access survive restarts and power loss offline;
  invalid data is refused by two independent layers.
- A newer database is never opened by an older app.
- The PIN cannot be bypassed by navigation, deep links, system back or a
  restart, and guessing is limited to about 24 tries a day once locked.
- Each future schema change costs a version bump, a dump, a seed and a
  migration step; CI enforces this.
- The iCloud backup exclusion and the app's own backup remain M10 work.

## Verification

`test/drift/booth/migration_test.dart`, `test/persistence/`,
`test/domain/` (rules, events, PIN policy, auth service, launch checks),
`test/infrastructure/` (PBKDF2 vectors, secure-store adapter, managed
files), `test/core/access_redirect_test.dart`, `test/app/access_flow_test.dart`,
`test/app/events_flow_test.dart`, the screen audits and goldens. Device
behaviour (Keychain and Keystore, real restart, PBKDF2 timing) is
BLOCKED until tablets are available.

## Open questions

1. iPadOS backup exclusion of the app's files: confirm in M10 together
   with the backup and restore design.
2. PBKDF2 iterations: raise after the M11 device benchmark if unlock stays
   under about one second; verifiers upgrade themselves.
3. Whether the owner wants a shorter or longer Booth Mode exit hold than
   three seconds.
