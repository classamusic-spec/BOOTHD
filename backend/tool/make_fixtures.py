"""Draws the backend's test images (run with Pillow; output is committed).

The images are synthetic (gradients and shapes drawn here), so they carry
no likeness or licence restrictions. Re-running reproduces them.
"""

import pathlib

from PIL import Image, ImageDraw

out = pathlib.Path(__file__).resolve().parent.parent / 'test' / 'fixtures'


def finished(width: int, height: int) -> Image.Image:
    image = Image.new('RGB', (width, height))
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            pixels[x, y] = (
                247 - (y * 40) // height,
                240 - (x * 30) // width,
                228 - ((x + y) * 50) // (width + height),
            )
    draw = ImageDraw.Draw(image)
    margin = width // 12
    slot = (height - 3 * margin) // 2
    for i in range(2):
        top = margin + i * (slot + margin)
        draw.rectangle([margin, top, width - margin, top + slot], fill=(84, 76, 70))
        draw.ellipse([width // 3, top + slot // 4, 2 * width // 3, top + 3 * slot // 4],
                     fill=(196, 160, 98))
    return image


final = finished(1200, 1800)
final.save(out / 'final_1200x1800.jpg', quality=88, dpi=(300, 300))
final.save(out / 'final_1200x1800.png', dpi=(300, 300), optimize=True)
final.resize((400, 600), Image.LANCZOS).save(out / 'preview_400x600.jpg', quality=80)
