// The render lab (developer tool, M04) reports renderer failures instead
// of crashing.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/di/service_providers.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/composition_renderer.dart';
import 'package:porcelain_photo_booth/features/diagnostics/render_lab/render_lab_screen.dart';

final class _FailingRenderer implements CompositionRenderer {
  @override
  Future<RenderArtifact> renderExport(
    TemplateRender render, {
    OutputProfile output = const OutputProfile(),
    int flattenArgb = 0xFFFFFFFF,
    bool includePixels = false,
  }) async => throw const RenderFailure(RenderFailureCode.missingAsset);

  @override
  Future<RenderArtifact> renderPreview(
    TemplateRender render, {
    required int maxWidthPx,
    required int maxHeightPx,
    double workspaceMargin = 0,
    bool includePixels = false,
  }) async => throw const RenderFailure(RenderFailureCode.missingAsset);
}

void main() {
  testWidgets('render lab reports renderer failures instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          compositionRendererProvider.overrideWithValue(_FailingRenderer()),
        ],
        child: const MaterialApp(home: RenderLabScreen()),
      ),
    );
    await tester.tap(find.text('Run the fixture suite'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The render lab failed: '
        'RenderFailure(RENDER_MISSING_ASSET)',
      ),
      findsOneWidget,
    );
  });
}
