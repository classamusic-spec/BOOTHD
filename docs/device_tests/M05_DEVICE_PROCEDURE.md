# M05 device procedure: Template Studio and template library

For the owner or a tester with a physical iPad (plus a Mac with Xcode) and a
physical Android tablet. Simulators and emulators do not count. Record every
result in `docs/ACCEPTANCE_EVIDENCE.md` (M05) with the device model, OS
version, app commit, build mode and date. The M04 render lab procedure
still applies and should be run on the same commit first.

## 0. Setup

- Flutter 3.47.7 exactly; `tool/check.sh` passes on the commit under test.
- Android: USB debugging on; `flutter devices` lists the tablet.
- iPad: follow `docs/IOS_VALIDATION.md`; `flutter devices` lists the iPad.
- Install a profile build (`flutter run --profile -d <device-id>`), finish
  setup and unlock the Studio.
- Put one transparent PNG (for example a logo with a clear background, or
  `assets/decorations/gold_confetti.png` from the repository) and one
  ordinary photo JPEG in the device's Files app (iPad: On My iPad;
  Android: Downloads).

## 1. Exit gate: a floral photo template, reopened, exported at 300 dpi

Do this once in landscape and once in portrait.

1. Templates > New template. "Choose your style" shows five designs and
   four blank pages, each rendered as it prints (no people). Choose Floral
   Elegance, name it "Device test", Continue. The Template Studio opens on
   it; the header says "All changes saved".
2. Select photo 2 on the canvas and drag it a little: it moves under the
   finger with snap guides near edges and centres; release; Undo puts it
   back exactly; Redo moves it again.
3. Drag a corner handle (resize keeps the opposite corner still), then the
   rotation handle (snaps every 15 degrees). One Undo each.
4. Inspector: type an exact X of 50 px and a rotation of 0, Done: the
   photo moves exactly there.
5. Artwork > Your images > Import an image…: pick the PNG from Files. It
   appears on the page; move it so it crosses the edge of photo 1 and part
   of it is off the page. On the canvas the part beyond the page shows
   faded; over the photo it is not cut.
6. Layers: drag the new image below photo 1 and back above it; hide it and
   show it; lock it (the canvas will not move it) and unlock it; rename it;
   duplicate it; delete the copy.
7. Add a text layer, type a line, choose Cormorant Garamond and a colour;
   add a rounded rectangle shape.
8. Wait two seconds: the header reads "Unsaved · draft kept". Force-quit the
   app (app switcher, swipe away). Relaunch, unlock, open "Device test":
   "Pick up where you left off?" appears; Restore: everything from steps 2
   to 7 is there and still editable (move one layer, Undo).
9. Save: "Saved as revision 2." Leave the editor, reopen the template: it
   opens on revision 2, "All changes saved", every layer editable.
10. Preview > Print quality: the full 300 dpi render (600 x 1800 for the
    2x6 strip). Compare it by eye with the canvas: same placement,
    artwork over photo 1 as on the canvas, nothing beyond the page.
11. In Files, delete or move the PNG you imported. Reopen the template:
    the image still shows (it was copied into the booth), and Preview still
    renders it.

Record: pass or fail for each step, with a screenshot of steps 5, 8, 9
and 10 per orientation, and any step that felt slow (over half a second).

## 2. Library and packages

1. Templates: the card for "Device test" shows revision 2. More >
   Duplicate makes "Device test copy"; More > Rename; More > Archive asks
   first, then the card leaves the list and appears under Archived;
   Restore brings it back.
2. More > Export package: the share sheet opens anchored to the card (on
   iPad a popover). Save the file to Files. Its name is
   `Device-test-r2.porcelain-template`.
3. Templates > Import: pick that file. "Imported "Device test"." The new
   card renders the same design.
4. Import a file that is not a package (the JPEG): "That file isn't a
   Porcelain template package…" and "Nothing was imported."; the library
   is unchanged.

## 3. Twenty-plus layers (stress)

1. New template > Blank 4x6 portrait. Add 6 photos, 8 texts, 7 shapes and 8
   decorations (Artwork > Decorations), so the Layers panel lists 30.
2. Drag layers around for a minute, pinch-zoom in to 400% and back to fit,
   rotate the tablet twice. Note any stutter. With a profile build attached
   (`flutter run --profile`), press `P` in the terminal to show the
   performance overlay and record the worst frame times while dragging and
   just after a zoom ends (images are decoded again then).
3. Preview > Print quality renders all 30 layers at 1200 x 1800; note the
   time from tap to image.
4. Record peak memory from Xcode Instruments (Allocations and Metal) or the
   Android Studio memory profiler during steps 2 and 3.

## 4. Accessibility and input

1. With VoiceOver or TalkBack on, move through the Studio toolbar, the
   Layers rows (each reads its name and type, and its hide and lock
   buttons) and the inspector fields.
2. With the system text size at its largest, the library, the editor and
   the asset browser still lay out without clipped words.
3. With a hardware keyboard: arrow keys nudge the selection, Shift+arrows
   nudge further, Cmd/Ctrl+Z and Shift+Cmd/Ctrl+Z undo and redo,
   Cmd/Ctrl+D duplicates, Delete deletes, Cmd/Ctrl+S saves.

## Evidence template (one per device)

```text
M05 Template Studio | date | tester
Device: <model>, <OS version>, app commit <sha>, profile
Exit gate landscape: steps 1-11 <PASS/FAIL each>; screenshots <files>
Exit gate portrait: steps 1-11 <PASS/FAIL each>; screenshots <files>
Draft after force-quit: <restored / lost>
Library and packages: 1 <>, 2 <file name>, 3 <>, 4 <>
Stress: worst frame while dragging <ms>, after zoom <ms>, print preview <s>,
  peak memory <MB> (tool <Instruments / Android Studio>)
Accessibility: <notes>; keyboard: <notes>
Anything odd: <notes>
```
