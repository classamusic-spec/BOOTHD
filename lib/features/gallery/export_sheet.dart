import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../core/gallery/gallery_export_run.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../domain/gallery/export_plan.dart';
import '../../domain/services/operator_files.dart';
import '../../shared/gallery/gallery_copy.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_spinner.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

/// Exports [sessionIds] (P-12, AC-0803): the operator picks what goes,
/// then each part is checked, copied and offered to the share sheet, and
/// the sheet reports exactly what the platform said and every file that
/// did not go.
Future<void> showGalleryExportSheet(
  BuildContext context, {
  required List<String> sessionIds,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    sheetAnimationStyle: PorcelainMotion.of(context).isReduced
        ? AnimationStyle.noAnimation
        : null,
    builder: (_) => GalleryExportSheet(sessionIds: sessionIds),
  );
}

class GalleryExportSheet extends ConsumerStatefulWidget {
  const GalleryExportSheet({super.key, required this.sessionIds});

  final List<String> sessionIds;

  @override
  ConsumerState<GalleryExportSheet> createState() => _GalleryExportSheetState();
}

class _GalleryExportSheetState extends ConsumerState<GalleryExportSheet> {
  var _content = ExportContent.finishedPhotos;
  GalleryExportRun? _run;
  final _shareButton = GlobalKey();

  @override
  void dispose() {
    _run?.dispose();
    super.dispose();
  }

  ShareAnchor _anchor() {
    final box = _shareButton.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      final size = MediaQuery.sizeOf(context);
      return (left: size.width / 2, top: size.height / 2, width: 1, height: 1);
    }
    final origin = box.localToGlobal(Offset.zero);
    return (
      left: origin.dx,
      top: origin.dy,
      width: box.size.width,
      height: box.size.height,
    );
  }

  Future<void> _start() async {
    final run = GalleryExportRun(
      gallery: ref.read(galleryRepositoryProvider),
      exporter: ref.read(galleryExporterProvider),
      clock: ref.read(clockProvider),
      ids: ref.read(idGeneratorProvider),
      sessionIds: widget.sessionIds,
      content: _content,
    )..addListener(_changed);
    setState(() => _run = run);
    await run.prepare();
    if (run.stage == ExportRunStage.ready) await _exportPart();
  }

  Future<void> _exportPart() async {
    final run = _run;
    if (run == null) return;
    await run.exportPart(_anchor());
    invalidateGallery(ref.invalidate);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final run = _run;
    final title = GalleryCopy.exportTitle(widget.sessionIds.length);
    if (run == null) {
      return PorcelainSheet(
        title: title,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GalleryCopy.exportContent,
              style: context.porcelain.text.titleSmall,
            ),
            const SizedBox(height: PorcelainSpace.sm),
            PorcelainSegmentedControl<ExportContent>(
              selected: _content,
              onChanged: (content) => setState(() => _content = content),
              segments: [
                for (final content in ExportContent.values)
                  PorcelainSegment(
                    value: content,
                    label: GalleryCopy.content(content),
                  ),
              ],
            ),
            const SizedBox(height: PorcelainSpace.lg),
            const Text(GalleryCopy.exportExplainer),
          ],
        ),
        actions: [
          PorcelainButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          PorcelainButton(
            key: _shareButton,
            label: GalleryCopy.chooseDestination,
            icon: PorcelainIcons.share,
            variant: PorcelainButtonVariant.primary,
            onPressed: () => unawaited(_start()),
          ),
        ],
      );
    }

    final working =
        run.stage == ExportRunStage.planning ||
        run.stage == ExportRunStage.exporting;
    final report = run.lastReport;
    final finished =
        run.stage == ExportRunStage.finished ||
        run.stage == ExportRunStage.failed;
    final repeatPart =
        report != null &&
        !working &&
        !finished &&
        report.part == run.partIndex + 1;

    return PorcelainSheet(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (run.partCount > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: PorcelainSpace.md),
              child: Text(GalleryCopy.partsNote(run.partCount)),
            ),
          if (working)
            _Progress(
              label: run.stage == ExportRunStage.planning
                  ? GalleryCopy.preparing
                  : run.partCount > 1
                  ? '${GalleryCopy.part(run.partIndex + 1, run.partCount)}: '
                        '${GalleryCopy.copying}'
                  : GalleryCopy.copying,
            )
          else
            _ExportReport(run: run),
        ],
      ),
      actions: [
        if (finished)
          PorcelainButton(
            label: GalleryCopy.done,
            variant: PorcelainButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          )
        else ...[
          PorcelainButton(
            label: repeatPart ? GalleryCopy.skipPart : 'Stop',
            onPressed: working
                ? null
                : repeatPart
                ? run.skipPart
                : () => Navigator.of(context).pop(),
            disabledReason: working
                ? 'Wait for the files to be offered.'
                : null,
          ),
          PorcelainButton(
            key: _shareButton,
            label: repeatPart ? GalleryCopy.shareAgain : GalleryCopy.nextPart,
            icon: PorcelainIcons.share,
            variant: PorcelainButtonVariant.primary,
            busy: working,
            busyLabel: GalleryCopy.preparing,
            onPressed: working ? null : () => unawaited(_exportPart()),
          ),
        ],
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          PorcelainSpinner(color: colors.accentIcon, size: 22),
          const SizedBox(width: PorcelainSpace.md),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// What happened so far: each part's result as the platform reported it,
/// and every file that did not go with its reason.
class _ExportReport extends StatelessWidget {
  const _ExportReport({required this.run});

  final GalleryExportRun run;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final lines = <(String, PorcelainTone)>[];
    if (run.stage == ExportRunStage.failed) {
      lines.add((
        "The sessions' files couldn't be read (${run.failureCode}). "
            'Nothing was exported.',
        PorcelainTone.danger,
      ));
    }
    final latest = <int, int>{};
    for (var i = 0; i < run.reports.length; i++) {
      latest[run.reports[i].part] = i;
    }
    for (final index in latest.values) {
      final report = run.reports[index];
      final prefix = report.parts > 1
          ? '${GalleryCopy.part(report.part, report.parts)}: '
          : '';
      final share = report.share;
      if (report.blockedBySpace) {
        lines.add((
          prefix +
              GalleryCopy.noSpace(
                GalleryCopy.bytes(report.requiredBytes!),
                GalleryCopy.bytes(report.freeBytes ?? 0),
              ),
          PorcelainTone.warning,
        ));
      } else if (report.sent.isEmpty) {
        lines.add((prefix + GalleryCopy.nothingToExport, PorcelainTone.danger));
      } else if (share?.outcome == ShareOutcome.dismissed) {
        lines.add((prefix + GalleryCopy.sheetClosed, PorcelainTone.warning));
      } else if (share?.outcome == ShareOutcome.unknown) {
        lines.add((
          prefix + GalleryCopy.handedOverUnknown(report.sent.length),
          PorcelainTone.info,
        ));
      } else {
        lines.add((
          prefix +
              GalleryCopy.handedOver(
                report.sent.length,
                GalleryCopy.destination(share?.destination),
              ),
          PorcelainTone.success,
        ));
      }
    }
    if (run.stage == ExportRunStage.finished &&
        run.partCount == 0 &&
        run.failures.isNotEmpty) {
      lines.add((GalleryCopy.nothingToExport, PorcelainTone.danger));
    }
    final failures = run.failures;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (line, tone) in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: PorcelainSpace.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(tone.icon, color: tone.foreground(colors), size: 20),
                  const SizedBox(width: PorcelainSpace.sm),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
          if (failures.isNotEmpty) ...[
            const SizedBox(height: PorcelainSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusBadge(
                label: GalleryCopy.notSent(failures.length),
                tone: PorcelainTone.warning,
              ),
            ),
            const SizedBox(height: PorcelainSpace.sm),
            for (final failure in failures.take(30))
              Padding(
                padding: const EdgeInsets.only(bottom: PorcelainSpace.xxs),
                child: Text(
                  '${GalleryCopy.failureLine(failure)} '
                  '(${failure.problem.diagnostic})',
                  style: theme.text.bodySmall,
                ),
              ),
            if (failures.length > 30)
              Text(
                '…and ${failures.length - 30} more.',
                style: theme.text.bodySmall,
              ),
          ],
          if (run.handedOverCount > 0) ...[
            const SizedBox(height: PorcelainSpace.md),
            Text(
              GalleryCopy.exportsNote,
              style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}
