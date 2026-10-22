import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/delivery/delivery_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/delivery/delivery_intent.dart';
import '../../domain/gallery/gallery_models.dart';
import '../../domain/gallery/print_file_facts.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/gallery_services.dart';
import '../../domain/session/session_shots.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/gallery/gallery_actions.dart';
import '../../shared/gallery/gallery_copy.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_material.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tone.dart';
import 'export_sheet.dart';
import 'gallery_thumbnail.dart';
import 'session_deliveries.dart';

/// One session in full (S14, AC-0802): every camera photo and retake with
/// the one each photo space uses, the frozen template revision, every
/// finished photo with its size, format, print resolution and a check of
/// the file, the session's settings and timeline, and its exports. From
/// here the operator exports, makes the finished photo (again) or deletes.
class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  var _rendering = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.gallery);
    }
  }

  Future<void> _render() async {
    setState(() => _rendering = true);
    await GalleryActions.render(context, ref, widget.sessionId);
    if (mounted) setState(() => _rendering = false);
  }

  Future<void> _delete(SessionDetail detail) async {
    final deleted = await GalleryActions.deleteSessions(context, ref, [
      widget.sessionId,
    ]);
    if (deleted && mounted) _back();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final detail = ref.watch(sessionDetailProvider(widget.sessionId));
    return Scaffold(
      body: StudioMaterial(
        area: StudioMaterialArea.canvas,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.rail,
                border: Border(bottom: BorderSide(color: colors.divider)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PorcelainSpace.lg,
                    vertical: PorcelainSpace.sm,
                  ),
                  child: Row(
                    children: [
                      PorcelainButton(
                        label: 'Gallery',
                        icon: PorcelainIcons.back,
                        variant: PorcelainButtonVariant.quiet,
                        size: PorcelainButtonSize.compact,
                        onPressed: _back,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: switch (detail) {
                AsyncData(value: final detail?) => _Detail(
                  detail: detail,
                  rendering: _rendering,
                  onRender: _render,
                  onDelete: () => _delete(detail),
                ),
                AsyncData() => EmptyState(
                  icon: PorcelainIcons.gallery,
                  title: 'This session no longer exists',
                  message: 'It may have been deleted. Return to the gallery.',
                  actions: [
                    PorcelainButton(
                      label: 'Back to the gallery',
                      icon: PorcelainIcons.back,
                      onPressed: () => context.go(RoutePaths.gallery),
                    ),
                  ],
                ),
                AsyncError() => EmptyState(
                  icon: PorcelainIcons.error,
                  title: "This session couldn't be read",
                  message: GalleryCopy.loadFailedMessage,
                  tone: PorcelainTone.danger,
                  actions: [
                    PorcelainButton(
                      label: 'Try again',
                      icon: PorcelainIcons.retry,
                      onPressed: () => ref.invalidate(
                        sessionDetailProvider(widget.sessionId),
                      ),
                    ),
                  ],
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(PorcelainSpace.xxxl),
                  child: SkeletonList(semanticLabel: 'Loading the session'),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({
    required this.detail,
    required this.rendering,
    required this.onRender,
    required this.onDelete,
  });

  final SessionDetail detail;
  final bool rendering;
  final VoidCallback onRender;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = detail.session;
    final latest = detail.latestOutput;
    final started = session.startedAtUtc.toLocal();
    final texts =
        ref.watch(sessionDeliveriesProvider(session.id)).value ??
        const <DeliveryIntent>[];
    final inProgress =
        session.status == SessionStatus.capturing ||
        session.status == SessionStatus.reviewing;
    final complete = session.shots.isComplete;
    final renderLabel = switch (session.status) {
      SessionStatus.rendering => GalleryCopy.finishNow,
      _ when latest != null => GalleryCopy.makeAgain,
      _ => GalleryCopy.makePrint,
    };
    final renderBlocked = inProgress
        ? GalleryCopy.cannotRenderInProgress
        : !complete
        ? GalleryCopy.cannotRenderIncomplete
        : null;

    return StudioPage(
      header: StudioPageHeader(
        eyebrow: detail.eventTitle,
        title: GalleryCopy.sessionTitle(detail.number),
        subtitle:
            '${formatTimestamp(started)} · '
            '${GalleryCopy.statusOf(session, hasOutput: latest != null)}',
        actions: [
          PorcelainButton(
            label: GalleryCopy.export,
            icon: PorcelainIcons.export,
            variant: PorcelainButtonVariant.primary,
            onPressed: inProgress
                ? null
                : () => unawaited(
                    showGalleryExportSheet(context, sessionIds: [session.id]),
                  ),
            disabledReason: inProgress
                ? GalleryCopy.cannotRenderInProgress
                : null,
          ),
          PorcelainButton(
            label: renderLabel,
            icon: PorcelainIcons.retry,
            busy: rendering,
            busyLabel: GalleryCopy.making,
            onPressed: renderBlocked == null && !rendering ? onRender : null,
            disabledReason: renderBlocked,
          ),
          PorcelainButton(
            label: GalleryCopy.deleteConfirm,
            icon: PorcelainIcons.delete,
            variant: PorcelainButtonVariant.danger,
            onPressed: inProgress ? null : onDelete,
            disabledReason: inProgress
                ? GalleryCopy.cannotRenderInProgress
                : null,
          ),
        ],
      ),
      children: [
        _FinishedSection(detail: detail),
        if (texts.isNotEmpty) SessionDeliveries(intents: texts),
        _PhotosSection(detail: detail),
        _TemplateSection(detail: detail),
        _SessionSection(detail: detail),
        _ExportsSection(detail: detail),
      ],
    );
  }
}

/// A label and its value, as a row of facts.
class _FactRow extends StatelessWidget {
  const _FactRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 170,
              child: Text(
                label,
                style: theme.text.bodyMedium.copyWith(
                  color: theme.colors.inkMuted,
                ),
              ),
            ),
            Expanded(child: Text(value, style: theme.text.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

String _inches(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.roundToDouble()
      ? '${rounded.round()}'
      : rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

/// The finished photos: the newest shown large and checked, every one
/// listed with its facts and its own export.
class _FinishedSection extends ConsumerWidget {
  const _FinishedSection({required this.detail});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final latest = detail.latestOutput;
    final template = detail.template;
    if (latest == null) {
      final session = detail.session;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Finished photo'),
          PorcelainCard(
            child: Row(
              children: [
                Icon(PorcelainIcons.pending, color: colors.inkMuted, size: 28),
                const SizedBox(width: PorcelainSpace.md),
                Expanded(
                  child: Text(
                    !session.shots.isComplete
                        ? 'No finished photo: the session ended before every '
                              'photo was taken. Its camera photos are below.'
                        : session.status == SessionStatus.rendering
                        ? 'Not made yet. The booth makes it while idle; '
                              '“${GalleryCopy.finishNow}” makes it now.'
                        : 'No finished photo yet. '
                              '“${GalleryCopy.makePrint}” makes one from these '
                              'photos and the template revision.',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final check = ref.watch(
      outputCheckProvider((
        relativePath: latest.relativePath,
        sha256: latest.sha256,
        format: latest.format,
        widthPx: latest.widthPx,
        heightPx: latest.heightPx,
        pageWidthPx: template?.pageWidthPx,
        pageHeightPx: template?.pageHeightPx,
      )),
    );
    final quality = detail.session.plan.output;
    final preview = LayoutBuilder(
      builder: (context, constraints) {
        final ratio = MediaQuery.devicePixelRatioOf(context);
        return switch (check) {
          AsyncData(value: OutputCheck(bytes: final bytes?)) => PrintFrame(
            aspectRatio: latest.widthPx / latest.heightPx,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              cacheWidth: (constraints.maxWidth * ratio).round().clamp(1, 1600),
              semanticLabel:
                  'Finished photo of ${GalleryCopy.sessionTitle(detail.number)}',
            ),
          ),
          AsyncData() => PrintFrame(
            aspectRatio: latest.widthPx / latest.heightPx,
            child: Center(
              child: Icon(PorcelainIcons.image, color: colors.inkMuted),
            ),
          ),
          _ => PrintFrame(
            aspectRatio: latest.widthPx / latest.heightPx,
            child: GalleryThumbnail(
              source: ThumbnailSource(
                kind: ThumbnailKind.output,
                id: latest.id,
                relativePath: latest.relativePath,
              ),
            ),
          ),
        };
      },
    );

    final readiness = check.value?.readiness;
    final inches = readiness?.inches;
    final facts = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FactRow('Pixel size', '${latest.widthPx} × ${latest.heightPx} px'),
        _FactRow(
          'Print size',
          inches == null
              ? '—'
              : '${_inches(inches.$1)} × ${_inches(inches.$2)} in at '
                    '${readiness!.facts.dpi} dpi',
        ),
        _FactRow(
          'File',
          latest.format == OutputFormat.png
              ? 'PNG (lossless), ${GalleryCopy.bytes(latest.byteLength)}'
              : 'JPEG, quality ${quality.jpegQuality}, '
                    '${GalleryCopy.bytes(latest.byteLength)}',
        ),
        _FactRow(
          'Made',
          '${formatTimestamp(latest.createdAtUtc.toLocal())} · '
              '${latest.origin == SessionOutputOrigin.session ? "the session's own" : 're-rendered in the gallery'}',
        ),
        _FactRow('Renderer', 'version ${latest.renderVersion}'),
        const SizedBox(height: PorcelainSpace.md),
        _ReadinessList(check: check),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Finished photo',
          subtitle: detail.outputs.length > 1
              ? '${detail.outputs.length} versions; the newest is shown and '
                    'exported. Earlier ones are kept.'
              : 'Made from the camera photos below and the template revision.',
        ),
        PorcelainCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 640;
              final picture = ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  maxHeight: 420,
                ),
                child: Center(child: preview),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 300, child: picture),
                    const SizedBox(width: PorcelainSpace.xl),
                    Expanded(child: facts),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: picture),
                  const SizedBox(height: PorcelainSpace.lg),
                  facts,
                ],
              );
            },
          ),
        ),
        if (detail.outputs.length > 1) ...[
          const SizedBox(height: PorcelainSpace.md),
          PorcelainCard(
            padding: const EdgeInsets.all(PorcelainSpace.md),
            child: Column(
              children: [
                for (final (index, output) in detail.outputs.indexed)
                  _FactRow(
                    'Version ${index + 1}',
                    '${formatTimestamp(output.createdAtUtc.toLocal())} · '
                        '${output.origin == SessionOutputOrigin.session ? "the session's own" : 're-rendered'} · '
                        '${GalleryCopy.bytes(output.byteLength)}'
                        '${output.sha256 == latest.sha256 ? ' · identical to the newest' : ''}',
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The print-ready check, item by item.
class _ReadinessList extends StatelessWidget {
  const _ReadinessList({required this.check});

  final AsyncValue<OutputCheck> check;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final value = check.value;
    if (value == null) {
      return Text(
        'Checking the file…',
        style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
      );
    }
    final readiness = value.readiness;
    final items = [
      (
        PrintCheckId.intact,
        value.problem == 'missing'
            ? 'The file is missing from storage'
            : value.problem == 'checksum'
            ? 'The file no longer matches its record'
            : 'Reads back exactly as saved',
      ),
      (PrintCheckId.format, 'A complete, standard image file'),
      (PrintCheckId.pixelSize, "The template's page size, pixel for pixel"),
      (PrintCheckId.resolution, 'Carries its print resolution'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(
          label: readiness.ready ? 'Print-ready' : 'Needs attention',
          tone: readiness.ready ? PorcelainTone.success : PorcelainTone.danger,
        ),
        const SizedBox(height: PorcelainSpace.sm),
        for (final (id, label) in items)
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(bottom: PorcelainSpace.xxs),
              child: Row(
                children: [
                  Icon(
                    readiness.failed.contains(id)
                        ? PorcelainIcons.error
                        : PorcelainIcons.success,
                    size: 18,
                    color:
                        (readiness.failed.contains(id)
                                ? PorcelainTone.danger
                                : PorcelainTone.success)
                            .foreground(colors),
                    semanticLabel: readiness.failed.contains(id)
                        ? 'Failed:'
                        : 'Passed:',
                  ),
                  const SizedBox(width: PorcelainSpace.sm),
                  Expanded(child: Text(label, style: theme.text.bodySmall)),
                ],
              ),
            ),
          ),
        if (!readiness.ready)
          Padding(
            padding: const EdgeInsets.only(top: PorcelainSpace.xs),
            child: Text(
              '“${GalleryCopy.makeAgain}” makes a new copy from the originals.',
              style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
            ),
          ),
      ],
    );
  }
}

/// Every camera photo by shot and attempt, the one in the print marked.
class _PhotosSection extends StatelessWidget {
  const _PhotosSection({required this.detail});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final session = detail.session;
    final shots = session.shots;
    final used = <String>{
      for (var shot = 0; shot < session.plan.shotCount; shot++)
        if (shots.selected(shot) case final photo?) photo.originalId,
    };
    final rounds = {for (final photo in session.photos) photo.round}.toList()
      ..sort();
    final mirrored = session.plan.capture.mirrorOutput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Camera photos',
          subtitle:
              '${GalleryCopy.photos(session.photos.length)}, kept exactly as '
              'the camera saved them'
              '${mirrored ? '; mirrored in the finished photo' : ''}.',
        ),
        if (session.photos.isEmpty)
          const PorcelainCard(
            child: Text('No photo was taken in this session.'),
          )
        else
          PorcelainCard(
            padding: const EdgeInsets.all(PorcelainSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final round in rounds) ...[
                  if (rounds.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: PorcelainSpace.sm,
                        top: PorcelainSpace.sm,
                      ),
                      child: Text(
                        round == 0 ? 'First set' : 'Set ${round + 1} (retaken)',
                        style: theme.text.titleSmall,
                      ),
                    ),
                  Wrap(
                    spacing: PorcelainSpace.md,
                    runSpacing: PorcelainSpace.md,
                    children: [
                      for (final photo in session.photos)
                        if (photo.round == round)
                          _PhotoCard(
                            photo: photo,
                            original: detail.originals[photo.originalId],
                            used: used.contains(photo.originalId),
                          ),
                    ],
                  ),
                ],
                const SizedBox(height: PorcelainSpace.sm),
                Text(
                  'Retakes are new photos; earlier ones are never replaced.',
                  style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.photo,
    required this.original,
    required this.used,
  });

  final ShotPhoto photo;
  final CapturedStill? original;
  final bool used;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final still = original;
    final label = photo.attempt == 1
        ? 'Photo ${photo.shot + 1}'
        : 'Photo ${photo.shot + 1}, retake ${photo.attempt - 1}';
    return Semantics(
      container: true,
      label: '$label${used ? ', in the finished photo' : ', not used'}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: 168,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 126,
                decoration: BoxDecoration(
                  borderRadius: PorcelainRadius.controlAll,
                  border: Border.all(
                    color: used ? colors.primaryEdge : colors.hairline,
                    width: used ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: PorcelainRadius.controlAll,
                  child: still == null
                      ? ColoredBox(
                          color: colors.inset,
                          child: Center(
                            child: Text(
                              'Record missing',
                              style: theme.text.bodySmall,
                            ),
                          ),
                        )
                      : GalleryThumbnail(
                          fit: BoxFit.cover,
                          source: ThumbnailSource(
                            kind: ThumbnailKind.original,
                            id: still.id,
                            relativePath: still.relativePath,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: PorcelainSpace.xs),
              Text(label, style: theme.text.labelLarge),
              Text(
                [
                  formatClock(photo.capturedAtUtc.toLocal()),
                  if (still != null) '${still.widthPx} × ${still.heightPx}',
                ].join(' · '),
                style: theme.text.bodySmall.copyWith(color: colors.inkMuted),
              ),
              if (used)
                Text(
                  'In the finished photo',
                  style: theme.text.labelSmall.copyWith(
                    color: colors.accentText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The frozen template revision and which photo fills each photo space.
class _TemplateSection extends StatelessWidget {
  const _TemplateSection({required this.detail});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final template = detail.template;
    final session = detail.session;
    final shots = session.shots;
    final plan = session.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Template',
          subtitle:
              'The revision this session was frozen to; editing the '
              'template later never changes it.',
        ),
        PorcelainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FactRow(
                'Template',
                template == null
                    ? 'Its record could not be read'
                    : '${template.templateName}, revision '
                          '${template.revisionNumber}'
                          '${template.templateArchived ? ' (archived)' : ''}',
              ),
              if (template != null)
                _FactRow(
                  'Page',
                  '${template.pageWidthPx} × ${template.pageHeightPx} px, '
                      '${template.pageOrientation.name}',
                ),
              for (var shot = 0; shot < plan.shotCount; shot++)
                _FactRow('Photo space ${plan.slotFor(shot) + 1}', switch (shots
                    .selected(shot)) {
                  null => 'No photo',
                  final photo when photo.attempt == 1 => 'Photo ${shot + 1}',
                  final photo =>
                    'Photo ${shot + 1}, retake ${photo.attempt - 1}',
                }),
            ],
          ),
        ),
      ],
    );
  }
}

/// When it ran, how it ended and the settings it was frozen with.
class _SessionSection extends StatelessWidget {
  const _SessionSection({required this.detail});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final session = detail.session;
    final plan = session.plan;
    final ended = session.endedAtUtc;
    final capture = plan.capture;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Session'),
        PorcelainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FactRow(
                'Started',
                formatTimestamp(session.startedAtUtc.toLocal()),
              ),
              _FactRow(
                'Ended',
                ended == null
                    ? 'Not yet'
                    : '${formatTimestamp(ended.toLocal())} '
                          '(${ended.difference(session.startedAtUtc).inSeconds} s)',
              ),
              _FactRow(
                'Outcome',
                GalleryCopy.statusOf(
                  session,
                  hasOutput: detail.outputs.isNotEmpty,
                ),
              ),
              _FactRow('Finishing attempts', '${session.renderAttempts}'),
              _FactRow(
                'Photos',
                '${capture.shotCount}, ${capture.countdownSeconds} s '
                    'countdown, ${switch (capture.retakePolicy) {
                      RetakePolicy.none => 'no retakes',
                      RetakePolicy.perShot => 'up to ${capture.retakeLimit} retakes of each photo',
                      RetakePolicy.wholeSession => 'the whole set retaken up to ${capture.retakeLimit} times',
                    }}',
              ),
              _FactRow(
                'Camera',
                '${capture.lens.name} lens; '
                    '${capture.mirrorOutput ? 'mirrored' : 'not mirrored'} in '
                    'the finished photo',
              ),
              _FactRow(
                'Output',
                plan.output.format == OutputFormat.png
                    ? 'PNG'
                    : 'JPEG, quality ${plan.output.jpegQuality}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Where this session's files went.
class _ExportsSection extends StatelessWidget {
  const _ExportsSection({required this.detail});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Exports',
          subtitle: 'What the platform reported when files were handed on.',
        ),
        PorcelainCard(
          child: detail.exports.isEmpty
              ? const Text('Not exported yet.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final export in detail.exports)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: PorcelainSpace.sm,
                        ),
                        child: MergeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${formatTimestamp(export.createdAtUtc.toLocal())}: '
                                '${GalleryCopy.exportRecord(export)}',
                                style: theme.text.bodyMedium,
                              ),
                              Text(
                                export.fileNames.join(', '),
                                style: theme.text.bodySmall.copyWith(
                                  color: theme.colors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
