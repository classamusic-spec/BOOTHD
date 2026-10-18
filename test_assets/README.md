# Test assets

All fixtures are synthetic and owned by the project: no third-party
content, no real people, no personal photos (TEST_AND_DEVICE_PLAN T-02).

## `input_photos/`

| File | Content | Made with |
| --- | --- | --- |
| `exif_orientation_1_640x480.jpg` | 640x480: red left half, blue right half, green 80x60 tag top left; EXIF orientation 1 | Pillow 12.3.0, script below |
| `exif_orientation_6_640x480.jpg` | Same pixels; EXIF orientation 6 (rotate 90° clockwise to display) | Pillow 12.3.0, script below |

Used to verify EXIF reading, decoder orientation behaviour and corrupt or
truncated image handling. Regenerate with:

```python
from PIL import Image, ImageDraw
for orientation in (1, 6):
    img = Image.new('RGB', (640, 480), (30, 30, 220))
    ImageDraw.Draw(img).rectangle([0, 0, 319, 479], fill=(220, 30, 30))
    ImageDraw.Draw(img).rectangle([0, 0, 79, 59], fill=(30, 200, 60))
    exif = Image.Exif()
    exif[0x0112] = orientation
    img.save(f'exif_orientation_{orientation}_640x480.jpg', 'JPEG',
             quality=92, exif=exif.tobytes())
```

## Procedural fixtures (no files)

The render lab's images are generated in code
(`lib/features/diagnostics/render_lab/fixture_images.dart`) and encoded by
a pure-Dart PNG writer, so hosts and devices render identical inputs:
FIX-01 stripes, flower and marker; FIX-02 solid photos; FIX-03 and CLIP
quadrant photos; the CLIP ring mask; FIX-04 halo discs. Documents are built
in `render_fixtures.dart`. Package and asset tests build their hostile
inputs (truncated PNGs, header-only PNGs, ZIPs with traversal, links,
bombs and damage) in the tests themselves.

## `expected_renders/`

Host goldens, produced by `flutter test --update-goldens test/rendering/`
on Flutter 3.47.7 (Linux host):

| File | Fixture |
| --- | --- |
| `fix01_export_1200x1800.png` | FIX-01 export (M01; the M04 renderer still matches it exactly) |
| `fix01_workspace_1440x2160.png` | FIX-01 editor workspace, 10% margin (M01) |
| `fix02_export_600x1800.png` | FIX-02: 2x6 strip, three slots, title, frame (M04) |
| `fix03_export_1800x1200.png` | FIX-03: landscape, rotated slots, focal points (M04) |
| `fix05_export_1200x1800.png` | FIX-05: text in both families, alignments, wrapping (M04) |
| `clip_export_1200x1200.png` | CLIP: ellipse, mask, contain, border, mirroring, group opacity (M04) |

Update only after an intentional rendering change, and record why in the
implementation log. Device runs save renders under the same names
(`build/device_renders/`) for `device_render_comparison_test.dart`.

## `templates/v1/`

`everything.json`: a schema v1 document using every layer type, fill,
clip, fit and font kind, in canonical form. `template_json_test.dart`
reads it to prove that documents written by this version keep opening and
re-encode to the same bytes. Never edit it to make a test pass: a change in
how version 1 reads is a migration.
