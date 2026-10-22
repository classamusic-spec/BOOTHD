# ADR-0018: A web build for testing and demonstration

- Status: accepted by the owner (2026-10-22: "can you build out the WEB
  version for me", after the W0 to W7 scope was presented)
- Related: ADR-0005 (layers), ADR-0010 (template storage), ADR-0012
  (camera), ADR-0015 (phone delivery), CLAUDE.md "Non-negotiable product
  decisions"

## Context

The owner wants to try the whole app (templates, events, guest sessions
with the camera, gallery, texting) from a link, on a phone or tablet,
without an app store or a Mac. CLAUDE.md locks release 1 to iPadOS and
Android tablets and rules out "a web wrapper". The app's device code is
confined to `lib/infrastructure` behind domain ports (ADR-0005), so a
browser build needs new adapters, not a new app.

## Decision

1. The same Flutter codebase also builds for the web, as a **test and
   demonstration target**. iPadOS and Android tablets stay the only
   release targets; the web build is not certified, not a kiosk and not
   what M11/M12 sign off. CLAUDE.md records this exception.
2. The domain, core, shared and feature layers do not change for the web.
   Platform differences live in `lib/infrastructure` and are chosen in
   `lib/app/platform_bindings*.dart` by conditional import.
3. Files: infrastructure that stores files works on `package:file`'s
   `FileSystem` instead of `dart:io` directly. Native builds use the local
   file system (behaviour unchanged); the browser uses
   `IndexedDbFileSystem`: an in-memory index of paths and sizes (loaded
   at start, so existence checks stay synchronous) over IndexedDB, where
   every write and rename is one IndexedDB transaction.
4. Database: the same drift schema, opened in the browser with
   `drift_flutter`'s WebAssembly SQLite (`web/sqlite3.wasm`, release
   asset of the pinned `sqlite3` package; `web/drift_worker.js`, compiled
   from the pinned drift by `tool/web/build_web_assets.sh`).
5. Camera: the official `camera` plugin's web implementation
   (`getUserMedia`, HTTPS only). Stills are read from the plugin's file,
   checked and committed like on tablets. Resolution is whatever the
   browser grants.
6. Exports, gallery shares and backups become browser downloads (or the
   system share sheet where the browser offers it); imports use the file
   picker.
7. Kiosk: a browser cannot be locked. The kiosk check says so honestly
   and points to Guided Access / app pinning; Booth Mode asks for full
   screen and a screen wake lock where the browser allows.
8. Phone delivery: the same HTTP contract to the same backend; the
   backend allows the web build's origin by configuration. Messaging keys
   stay on the server only.
9. Deployment: GitHub Actions builds `build/web` and, when the owner adds
   Vercel secrets, deploys it; `vercel.json` sets the security headers
   the WebAssembly database needs and serves the single-page app.

## Consequences

- Data lives in one browser on one device; clearing site data deletes
  it. The app asks the browser to keep storage persistently and shows a
  warning on the web.
- One new direct dependency on `package:file` (BSD-3, Dart team, already
  transitive) and `package:web` (BSD-3, Dart team, already transitive).
- Tests: the native suite is unchanged; the IndexedDB file system and the
  web bindings are tested in Chromium (`flutter test --platform chrome`);
  a Playwright smoke test drives the built site with Chromium's fake
  camera.
- Not on the web: kiosk locking, orientation locking, device backup
  exclusion, true free-space figures (estimates only).
