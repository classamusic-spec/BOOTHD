import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../core/templates/slot_placeholder.dart';
import '../../domain/repositories/template_store.dart';
import '../../domain/services/composition_renderer.dart';
import '../../domain/template/template_document.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';
import 'editor_copy.dart';

enum _Quality { screen, print }

/// Template preview (S11): the template drawn by the print renderer itself
/// (never a widget snapshot), with a placeholder in every photo slot, at
/// screen size or as the full 300 dpi print, pinch to zoom. Warnings for
/// missing images, fallback fonts and overflowing words are listed.
class TemplatePreviewScreen extends ConsumerStatefulWidget {
  const TemplatePreviewScreen({
    super.key,
    required this.templateId,
    this.document,
  });

  final String templateId;

  /// The editor's current, possibly unsaved, document; otherwise the
  /// newest saved revision is shown.
  final TemplateDocument? document;

  @override
  ConsumerState<TemplatePreviewScreen> createState() =>
      _TemplatePreviewScreenState();
}

class _TemplatePreviewScreenState extends ConsumerState<TemplatePreviewScreen> {
  var _quality = _Quality.screen;
  TemplateDocument? _document;
  String _name = 'Template';
  Object? _error;
  RenderArtifact? _artifact;
  Size? _renderedFor;
  _Quality? _renderedQuality;
  var _rendering = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final latest = await ref
          .read(templateRepositoryProvider)
          .loadLatest(widget.templateId);
      if (!mounted) return;
      setState(() {
        _name = latest.summary.templateName;
        _document = widget.document ?? latest.document;
      });
    } on TemplateStoreException catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _render(Size size, double pixelRatio) async {
    final document = _document;
    if (document == null || _rendering) return;
    _rendering = true;
    final quality = _quality;
    try {
      final renderer = ref.read(compositionRendererProvider);
      final render = placeholderRender(
        document,
        ref.read(assetRepositoryProvider),
      );
      final artifact = quality == _Quality.print
          ? await renderer.renderExport(render)
          : await renderer.renderPreview(
              render,
              maxWidthPx: (size.width * pixelRatio).round().clamp(1, 4096),
              maxHeightPx: (size.height * pixelRatio).round().clamp(1, 4096),
            );
      if (!mounted) return;
      setState(() {
        _artifact = artifact;
        _renderedFor = size;
        _renderedQuality = quality;
        _error = null;
      });
    } on RenderFailure catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      _rendering = false;
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.templates);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final document = _document;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.rail,
                border: Border(bottom: BorderSide(color: colors.divider)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PorcelainSpace.lg,
                  vertical: PorcelainSpace.sm,
                ),
                child: Wrap(
                  spacing: PorcelainSpace.md,
                  runSpacing: PorcelainSpace.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PorcelainButton(
                      label: widget.document == null ? 'Templates' : 'Editor',
                      icon: PorcelainIcons.back,
                      variant: PorcelainButtonVariant.quiet,
                      size: PorcelainButtonSize.compact,
                      onPressed: _back,
                    ),
                    Semantics(
                      header: true,
                      child: Text(
                        'Preview: $_name',
                        style: theme.text.titleLarge,
                      ),
                    ),
                    PorcelainSegmentedControl<_Quality>(
                      selected: _quality,
                      onChanged: (q) => setState(() {
                        _quality = q;
                        _artifact = null;
                      }),
                      segments: const [
                        PorcelainSegment(
                          value: _Quality.screen,
                          label: 'Screen',
                        ),
                        PorcelainSegment(
                          value: _Quality.print,
                          label: 'Print quality',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: switch (_error) {
                final TemplateStoreException error => EmptyState(
                  icon: PorcelainIcons.error,
                  title: "This template couldn't be opened",
                  message: EditorCopy.storeError(error),
                  tone: PorcelainTone.danger,
                ),
                final RenderFailure error => EmptyState(
                  icon: PorcelainIcons.error,
                  title: "This template can't be printed yet",
                  message: error.code == RenderFailureCode.missingAsset
                      ? 'One of its images is missing or changed on this '
                            'device. Replace it in the editor.'
                      : 'Something in it could not be drawn. Open it in '
                            'the editor and check its layers.',
                  tone: PorcelainTone.danger,
                ),
                _ when document == null => const Center(
                  child: CircularProgressIndicator(),
                ),
                _ => LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth - PorcelainSpace.xxl * 2,
                      constraints.maxHeight - 140,
                    );
                    if (_artifact == null ||
                        _renderedQuality != _quality ||
                        (_quality == _Quality.screen && _renderedFor != size)) {
                      final ratio = MediaQuery.devicePixelRatioOf(context);
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _render(size, ratio),
                      );
                    }
                    return _body(document);
                  },
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(TemplateDocument document) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final artifact = _artifact;
    final page = document.page;
    String size(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: artifact == null
              ? const Center(child: CircularProgressIndicator())
              : InteractiveViewer(
                  maxScale: _quality == _Quality.print ? 6 : 3,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(PorcelainSpace.xxl),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadowKey,
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: AspectRatio(
                          aspectRatio: page.widthPx / page.heightPx,
                          child: Image.memory(
                            Uint8List.fromList(artifact.bytes),
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            gaplessPlayback: true,
                            semanticLabel:
                                'The template as it prints, with sample '
                                'placeholders in the photo spaces',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            PorcelainSpace.xxl,
            0,
            PorcelainSpace.xxl,
            PorcelainSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${size(page.width)} × ${size(page.height)} ${page.unit.code} '
                'at ${page.dpi} dpi: ${page.widthPx} × ${page.heightPx} px. '
                '${_quality == _Quality.print ? 'This is the full print, pixel for pixel; pinch to look closely.' : 'Drawn by the print renderer at screen size.'}',
                style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
              ),
              if (artifact != null && artifact.warnings.isNotEmpty) ...[
                const SizedBox(height: PorcelainSpace.xs),
                Wrap(
                  spacing: PorcelainSpace.xs,
                  runSpacing: PorcelainSpace.xs,
                  children: [
                    for (final warning in artifact.warnings.toSet())
                      StatusBadge(
                        label: switch (warning.code) {
                          RenderWarningCode.fontFallback =>
                            'A font was replaced by Inter',
                          RenderWarningCode.textOverflow =>
                            'Words spill out of their box',
                        },
                        tone: PorcelainTone.warning,
                        icon: PorcelainIcons.warning,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
