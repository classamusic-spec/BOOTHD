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

FIX-01 photos, flower, marker and FIX-04 halo discs are generated in code
(`lib/features/diagnostics/spikes/render/fixture_images.dart`) and encoded
by a pure-Dart PNG writer, so hosts and devices render identical inputs.

## `expected_renders/`

Host goldens for FIX-01: the 1200x1800 export and the 1440x2160 editor
workspace. Produced by `flutter test --update-goldens test/rendering/`
on Flutter 3.47.7 (Linux host). Update only after an intentional rendering
change, and record why in the implementation log.
