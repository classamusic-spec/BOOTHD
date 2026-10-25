# Web test build on Vercel (ADR-0018)

The web build is for testing and demonstrations only. It is not a release
platform, is not certified and cannot lock a browser into kiosk mode.

## Deploy (no token in the repository)

1. In Vercel: **Add New → Project → Import** `classamusic-spec/BOOTHD`.
2. Pick branch `claude/new-session-fh2zxl` (or whichever branch holds this
   code). Leave **Framework Preset** as *Other*; `vercel.json` already sets:
   - install: `bash tool/web/vercel_build.sh install` (fetches Flutter 3.47.7)
   - build: `bash tool/web/vercel_build.sh build`
   - output: `build/web`
3. Deploy. The first build takes several minutes (Flutter download plus a
   ~2 minute web compile). Every push to the branch redeploys.

No secrets are needed for the booth itself. Never put Vercel, Supabase or
Twilio keys in this repository.

## Testing at a party

- Open the `https://…vercel.app` link in Chrome (Android, laptop) or Safari
  (iPad/iPhone) and allow the camera. HTTPS is required for the camera.
- Everything (events, templates, photos) is stored **in that browser on that
  device**. Clearing site data or a private window deletes it. Download
  photos from Gallery → Export before clearing anything.
- Add it to the home screen and use the browser's full screen. A browser can
  be left by its own controls, so keep an eye on the device; for a locked
  kiosk use the tablet apps with Guided Access / screen pinning.
- Backups are made in the tablet apps only.

## Texting (optional, later)

Phone delivery needs the Supabase backend and a registered Twilio sender
(see `docs/delivery/SETUP_AND_CREDENTIALS.md`). For the web booth, also set
the backend secret `DELIVERY_BOOTH_ORIGINS` to the exact Vercel origin, for
example `https://your-project.vercel.app` (comma-separate several). Without
it the browser is refused by CORS and texting stays unavailable; capture,
gallery and export still work.

## Local check

```
bash tool/web/vercel_build.sh install && bash tool/web/vercel_build.sh build
node tool/web/serve.mjs 8787        # serves build/web with vercel.json headers
```
