/// The picture that stands in for a guest's photo wherever a template is
/// shown without one: the editor canvas, library cards and the template
/// preview (S06, S07, S11). Drawn in code; no people (CR-001 #12).
///
/// It goes through the same painter as a real photo, so slot shapes,
/// masks, borders and the artwork layered over a slot look exactly as they
/// will in print.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/repositories/template_store.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/template/template_document.dart';

/// The photo id every placeholder slot binds to.
const slotPlaceholderPhotoId = 'slot-placeholder';

/// Square, so a slot of any shape crops it around the centred camera.
const slotPlaceholderSizePx = 960;

Future<Uint8List>? _png;

/// PNG bytes of the placeholder, drawn once per process.
Future<Uint8List> slotPlaceholderPng() => _png ??= _draw();

/// [document] with the placeholder in every photo slot and its artwork
/// read from [assets]: what the library, editor and template preview
/// render.
TemplateRender placeholderRender(
  TemplateDocument document,
  AssetRepository assets,
) => TemplateRender(
  document: document,
  photos: {
    for (final slot in document.photoSlots)
      slot.slotIndex: const SlotPhoto(slotPlaceholderPhotoId),
  },
  source: _PlaceholderSource(assets),
);

final class _PlaceholderSource implements RenderSource {
  const _PlaceholderSource(this.assets);

  final AssetRepository assets;

  @override
  Future<Uint8List> readAsset(String assetId) async {
    try {
      return await assets.read(assetId);
    } on TemplateStoreException catch (error) {
      throw RenderFailure(
        RenderFailureCode.missingAsset,
        detail: '${error.code.diagnostic}: $assetId',
      );
    }
  }

  @override
  Future<Uint8List> readPhoto(String photoId) => slotPlaceholderPng();
}

Future<Uint8List> _draw() async {
  const size = slotPlaceholderSizePx;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const area = ui.Rect.fromLTWH(0, 0, size + 0.0, size + 0.0);
  const centre = ui.Offset(size / 2, size / 2);

  // Warm paper with a soft champagne glow towards the middle.
  canvas.drawRect(
    area,
    ui.Paint()
      ..shader = ui.Gradient.radial(centre, size * 0.75, const [
        ui.Color(0xFFF7F0E4),
        ui.Color(0xFFE6D6BC),
      ]),
  );
  // A faint diagonal sheen, like light across a print.
  canvas.drawRect(
    area,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        area.topLeft,
        area.bottomRight,
        const [
          ui.Color(0x00FFFFFF),
          ui.Color(0x33FFFFFF),
          ui.Color(0x00FFFFFF),
        ],
        const [0.3, 0.5, 0.7],
      ),
  );

  // A camera, small enough to stay whole in a 3:1 slot.
  final unit = size * 0.07;
  final ink = ui.Paint()
    ..color = const ui.Color(0xB39C7B52)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = unit * 0.22
    ..strokeJoin = ui.StrokeJoin.round;
  final body = ui.RRect.fromRectAndRadius(
    ui.Rect.fromCenter(
      center: centre.translate(0, unit * 0.25),
      width: unit * 3.4,
      height: unit * 2.4,
    ),
    ui.Radius.circular(unit * 0.5),
  );
  final hump = ui.Path()
    ..moveTo(body.left + unit * 0.95, body.top)
    ..lineTo(body.left + unit * 1.25, body.top - unit * 0.45)
    ..lineTo(body.right - unit * 1.25, body.top - unit * 0.45)
    ..lineTo(body.right - unit * 0.95, body.top);
  canvas
    ..drawRRect(body, ink)
    ..drawPath(hump, ink)
    ..drawCircle(body.center, unit * 0.72, ink)
    ..drawCircle(
      ui.Offset(body.right - unit * 0.55, body.top + unit * 0.5),
      unit * 0.1,
      ui.Paint()..color = const ui.Color(0xB39C7B52),
    );

  // Corner ticks, like a viewfinder.
  final tick = unit * 0.9;
  final inset = size * 0.33;
  for (final (x, y, sx, sy) in [
    (inset, inset, 1.0, 1.0),
    (size - inset, inset, -1.0, 1.0),
    (inset, size - inset, 1.0, -1.0),
    (size - inset, size - inset, -1.0, -1.0),
  ]) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(x, y + sy * tick)
        ..lineTo(x, y)
        ..lineTo(x + sx * tick, y),
      ink..strokeWidth = math.max(2, unit * 0.12),
    );
  }

  final image = await recorder.endRecording().toImage(size, size);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
