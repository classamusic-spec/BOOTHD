// AC-0402 (deterministic order, visibility, opacity), AC-0404 (photo crop
// and clip resolved per slot), A-07 step 2 (orientation applied once,
// mirroring as configured): compiling documents into scenes.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/template/document_issues.dart';
import 'package:porcelain_photo_booth/domain/template/document_scene.dart';
import 'package:porcelain_photo_booth/domain/template/geometry.dart';
import 'package:porcelain_photo_booth/domain/template/page_spec.dart';
import 'package:porcelain_photo_booth/domain/template/template_assets.dart';
import 'package:porcelain_photo_booth/domain/template/template_document.dart';
import 'package:porcelain_photo_booth/domain/template/template_layers.dart';

import '../../support/template_builders.dart';

const bindings = {
  0: SlotBinding(photoId: 'p0', size: PixelSize(1600, 1200)),
  1: SlotBinding(photoId: 'p1', size: PixelSize(1200, 1600)),
};

Matcher closeRect(PixelRect expected) => predicate<PixelRect>(
  (r) =>
      (r.left - expected.left).abs() < 1e-6 &&
      (r.top - expected.top).abs() < 1e-6 &&
      (r.width - expected.width).abs() < 1e-6 &&
      (r.height - expected.height).abs() < 1e-6,
  '$expected',
);

T nodeOf<T extends SceneNode>(DocumentScene scene, String layerId) =>
    scene.nodeFor(layerId)! as T;

void main() {
  test('the scene is the page in pixels, every node in paint order', () {
    final scene = compileScene(sampleDocument(), bindings: bindings);
    expect((scene.widthPx, scene.heightPx), (1200, 1800));
    expect(
      [for (final node in scene.nodes) node.layerId],
      ['bg', 'slot-1', 'slot-2', 'flower', 'title', 'frame'],
    );
    expect(scene.nodes.first, isA<FillNode>());
  });

  test('hidden and fully transparent layers are left out', () {
    final document = sampleDocument(
      layers: const [
        ShapeLayer(
          id: 'hidden',
          zIndex: 1,
          frame: NormalizedRect.page,
          shape: ShapeKind.rect,
          fill: ink,
          visible: false,
        ),
        ShapeLayer(
          id: 'clear',
          zIndex: 2,
          frame: NormalizedRect.page,
          shape: ShapeKind.rect,
          fill: ink,
          opacity: 0,
        ),
        ShapeLayer(
          id: 'half',
          zIndex: 3,
          frame: NormalizedRect.page,
          shape: ShapeKind.rect,
          fill: ink,
          opacity: 0.5,
        ),
      ],
      assets: {},
    );
    final scene = compileScene(document, bindings: const {});
    expect([for (final node in scene.nodes) node.layerId], ['half']);
    expect(scene.nodes.single.opacity, 0.5);
  });

  test('frames convert to page pixels, overflow included, and rotate about '
      'their pivot', () {
    final document = sampleDocument(
      layers: const [
        ShapeLayer(
          id: 'corner-pivot',
          zIndex: 1,
          frame: NormalizedRect(x: 0.9, y: 0.5, width: 0.3, height: 0.1),
          shape: ShapeKind.rect,
          fill: ink,
          rotationDegrees: 90,
          pivot: NormalizedPoint(0, 0),
        ),
      ],
      assets: {},
    );
    final placement = compileScene(
      document,
      bindings: const {},
    ).nodes.single.placement;
    expect(
      placement.rect,
      closeRect(const PixelRect(left: 1080, top: 900, width: 360, height: 180)),
    );
    expect(placement.rotationRadians, closeTo(math.pi / 2, 1e-12));
    expect(placement.pivot, const PixelPoint(1080, 900));
    // Clockwise about the top-left corner: the far end of the bar now points
    // down, and the bar lies left of the pivot.
    final farEnd = placement.toPage(const PixelPoint(1440, 900));
    expect(farEnd.x, closeTo(1080, 1e-9));
    expect(farEnd.y, closeTo(1260, 1e-9));
    expect(
      placement.bounds,
      closeRect(const PixelRect(left: 900, top: 900, width: 180, height: 360)),
    );
  });

  group('photo slots (AC-0404)', () {
    test('cover crops around the focal point, contain letterboxes', () {
      final document = sampleDocument(
        layers: const [
          PhotoSlotLayer(
            id: 'cover',
            zIndex: 1,
            slotIndex: 0,
            frame: NormalizedRect(x: 0.1, y: 0.06, width: 0.8, height: 0.4),
            focal: NormalizedPoint(0.5, 0.0),
          ),
          PhotoSlotLayer(
            id: 'contain',
            zIndex: 2,
            slotIndex: 1,
            frame: NormalizedRect(x: 0.1, y: 0.54, width: 0.8, height: 0.4),
            fit: PhotoFit.contain,
          ),
        ],
        assets: {},
      );
      final scene = compileScene(document, bindings: bindings);
      // Slot 960x720; photo 1600x1200 has the same aspect: no crop.
      final cover = nodeOf<PhotoNode>(scene, 'cover');
      expect(
        cover.sourceCrop,
        closeRect(const PixelRect(left: 0, top: 0, width: 1600, height: 1200)),
      );
      expect(cover.destRect, cover.placement.rect);
      // Photo 1200x1600 contained in 960x720: 540x720, centred.
      final contain = nodeOf<PhotoNode>(scene, 'contain');
      expect(
        contain.destRect,
        closeRect(
          const PixelRect(left: 330, top: 972, width: 540, height: 720),
        ),
      );
      expect(
        contain.sourceCrop,
        closeRect(const PixelRect(left: 0, top: 0, width: 1200, height: 1600)),
      );
    });

    test('a focal point near an edge keeps the crop inside the photo', () {
      final crop = coverCrop(
        sourceWidth: 1200,
        sourceHeight: 1600,
        targetWidth: 960,
        targetHeight: 720,
        focal: const NormalizedPoint(0.5, 0.02),
      );
      expect(
        crop,
        closeRect(const PixelRect(left: 0, top: 0, width: 1200, height: 900)),
      );
    });

    test('output mirroring flips the photo, keeping the focal point where '
        'guests see it', () {
      const layer = PhotoSlotLayer(
        id: 's',
        zIndex: 1,
        slotIndex: 0,
        frame: NormalizedRect(x: 0, y: 0, width: 0.5, height: 1),
        focal: NormalizedPoint(0, 0.5),
      );
      PhotoNode compile({required bool mirrored}) =>
          compileScene(
                sampleDocument(layers: const [layer], assets: {}),
                bindings: {
                  0: SlotBinding(
                    photoId: 'p',
                    size: const PixelSize(1600, 1200),
                    mirrored: mirrored,
                  ),
                },
              ).nodes.single
              as PhotoNode;
      // Slot 600x1800 (1:3) from a 4:3 photo keeps a 400x1200 strip.
      final plain = compile(mirrored: false);
      expect(plain.mirrored, isFalse);
      expect(
        plain.sourceCrop,
        closeRect(const PixelRect(left: 0, top: 0, width: 400, height: 1200)),
      );
      // Mirrored, the left of what guests see is the right of the original.
      final mirrored = compile(mirrored: true);
      expect(mirrored.mirrored, isTrue);
      expect(
        mirrored.sourceCrop,
        closeRect(
          const PixelRect(left: 1200, top: 0, width: 400, height: 1200),
        ),
      );
    });

    test('clip shapes resolve to page pixels', () {
      final scene = compileScene(sampleDocument(), bindings: bindings);
      final rounded = nodeOf<PhotoNode>(scene, 'slot-2');
      // 0.05 of the shorter side (720 px).
      expect(rounded.clip, isA<SceneRoundedRectClip>());
      expect(
        (rounded.clip as SceneRoundedRectClip).radiusPx,
        closeTo(36, 1e-9),
      );
      expect(rounded.border!.widthPx, closeTo(2 * 300 / 72, 1e-9));
      expect(nodeOf<PhotoNode>(scene, 'slot-1').clip, isA<SceneRectClip>());
    });

    test('a slot without a photo, or with an empty one, is an error', () {
      List<DocumentIssueCode> codes(Map<int, SlotBinding> bound) {
        try {
          compileScene(sampleDocument(), bindings: bound);
        } on SceneCompileException catch (error) {
          return [for (final issue in error.issues) issue.code];
        }
        return const [];
      }

      expect(codes({0: bindings[0]!}), [DocumentIssueCode.missingAsset]);
      expect(
        codes({
          ...bindings,
          1: const SlotBinding(photoId: 'p1', size: PixelSize(0, 10)),
        }),
        [DocumentIssueCode.invalidValue],
      );
    });

    test('documents with errors never compile', () {
      expect(
        () =>
            compileScene(sampleDocument(assets: const {}), bindings: bindings),
        throwsA(isA<SceneCompileException>()),
      );
    });
  });

  group('images, text and shapes', () {
    TemplateDocument withImage(ImageFit fit, {NormalizedRect? crop}) =>
        sampleDocument(
          layers: [
            ImageLayer(
              id: 'i',
              zIndex: 1,
              assetId: TestAssets.flower,
              frame: const NormalizedRect(
                x: 0,
                y: 0,
                width: 0.5,
                height: 1 / 3,
              ),
              fit: fit,
              crop: crop ?? NormalizedRect.page,
            ),
          ],
          assets: {TestAssets.flower: TestAssets.png},
        );

    test('image fits: fill stretches, contain centres, cover crops', () {
      // Frame 600x600; image 800x600.
      ImageNode node(ImageFit fit, {NormalizedRect? crop}) =>
          compileScene(
                withImage(fit, crop: crop),
                bindings: const {},
              ).nodes.single
              as ImageNode;
      final fill = node(ImageFit.fill);
      expect(
        fill.destRect,
        closeRect(const PixelRect(left: 0, top: 0, width: 600, height: 600)),
      );
      expect(
        fill.sourceCrop,
        closeRect(const PixelRect(left: 0, top: 0, width: 800, height: 600)),
      );
      expect(
        node(ImageFit.contain).destRect,
        closeRect(const PixelRect(left: 0, top: 75, width: 600, height: 450)),
      );
      expect(
        node(ImageFit.cover).sourceCrop,
        closeRect(const PixelRect(left: 100, top: 0, width: 600, height: 600)),
      );
      // A crop selects part of the image before fitting.
      expect(
        node(
          ImageFit.fill,
          crop: const NormalizedRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
        ).sourceCrop,
        closeRect(const PixelRect(left: 400, top: 0, width: 400, height: 300)),
      );
    });

    test('text and stroke sizes convert from points at the page dpi', () {
      final scene = compileScene(sampleDocument(), bindings: bindings);
      final title = nodeOf<TextNode>(scene, 'title');
      expect(title.sizePx, closeTo(18 * 300 / 72, 1e-9));
      expect(title.font, AssetFont(TestAssets.font));
      final frame = nodeOf<ShapeNode>(scene, 'frame');
      expect(frame.stroke!.widthPx, closeTo(1.5 * 300 / 72, 1e-9));
      expect(frame.cornerRadiusPx, closeTo(0.03 * 0.96 * 1200, 1e-9));
      expect(scene.fonts, {AssetFont(TestAssets.font)});
    });

    test('the same document at twice the dpi scales every size', () {
      const page600 = PageSpec(
        width: 4,
        height: 6,
        unit: LengthUnit.inch,
        dpi: 600,
      );
      final at300 = compileScene(sampleDocument(), bindings: bindings);
      final at600 = compileScene(
        sampleDocument(page: page600),
        bindings: bindings,
      );
      for (var i = 0; i < at300.nodes.length; i++) {
        expect(
          at600.nodes[i].placement.rect,
          closeRect(at300.nodes[i].placement.rect.scaled(2)),
        );
      }
      expect(
        nodeOf<TextNode>(at600, 'title').sizePx,
        closeTo(2 * nodeOf<TextNode>(at300, 'title').sizePx, 1e-9),
      );
    });
  });

  group('backgrounds', () {
    test('a gradient spans the page corner to corner along its angle', () {
      SceneGradientFill gradient(double angle) =>
          (compileScene(
                        sampleDocument(
                          layers: [
                            BackgroundLayer(
                              id: 'bg',
                              zIndex: 0,
                              fill: LinearGradientFill(
                                angleDegrees: angle,
                                stops: const [
                                  GradientStop(0, ivory),
                                  GradientStop(1, ink),
                                ],
                              ),
                            ),
                          ],
                          assets: {},
                        ),
                        bindings: const {},
                      ).nodes.single
                      as FillNode)
                  .fill
              as SceneGradientFill;
      final down = gradient(90);
      expect(down.start.x, closeTo(600, 1e-9));
      expect(down.start.y, closeTo(0, 1e-9));
      expect(down.end.y, closeTo(1800, 1e-9));
      final across = gradient(0);
      expect(across.start.x, closeTo(0, 1e-9));
      expect(across.end.x, closeTo(1200, 1e-9));
      // 45°: the line through the centre reaches the projection of the
      // corners, |600 cos| + |900 sin| either side.
      final diagonal = gradient(45);
      final half = 600 * math.cos(math.pi / 4) + 900 * math.sin(math.pi / 4);
      expect(diagonal.end.x - 600, closeTo(half * math.cos(math.pi / 4), 1e-9));
    });

    test('an image background covers the page by default', () {
      final scene = compileScene(
        sampleDocument(
          layers: [
            BackgroundLayer(
              id: 'bg',
              zIndex: 0,
              fill: ImageFill(TestAssets.paper),
            ),
          ],
          assets: {
            TestAssets.paper: const TemplateAsset(
              mediaType: AssetMediaType.jpeg,
              byteLength: 9,
              widthPx: 1800,
              heightPx: 1800,
            ),
          },
        ),
        bindings: const {},
      );
      final fill = (scene.nodes.single as FillNode).fill as SceneImageFill;
      expect(
        fill.sourceCrop,
        closeRect(
          const PixelRect(left: 300, top: 0, width: 1200, height: 1800),
        ),
      );
      expect(scene.drawScale(fill.source), closeTo(1, 1e-9));
    });
  });

  test('draw scales tell the renderer how large to decode each image', () {
    final scene = compileScene(sampleDocument(), bindings: bindings);
    // Slot 1 is 960x720 from a 1600x1200 photo: drawn at 0.6.
    expect(scene.drawScale(const PhotoImageRef('p0')), closeTo(0.6, 1e-9));
    // The flower (800x600) is stretched to 600x594: the larger of the two
    // scales keeps enough pixels in both directions.
    expect(
      scene.drawScale(AssetImageRef(TestAssets.flower)),
      closeTo(0.99, 1e-9),
    );
    expect(
      scene.imageSizes[const PhotoImageRef('p1')],
      const PixelSize(1200, 1600),
    );
    expect(scene.drawScale(const PhotoImageRef('absent')), 0);
  });
}
