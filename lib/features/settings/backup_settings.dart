import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backup/backup_providers.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../domain/backup/backup_manifest.dart';
import '../../domain/services/backup_service.dart';
import '../../domain/services/operator_files.dart';
import '../../shared/backup/backup_copy.dart';
import '../../shared/formatters/byte_format.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

/// Settings > Backup (M10, AC-1006): one file with the booth's database
/// and, if chosen, every guest's photos, checked from end to end before it
/// is offered to the share sheet. Restoring happens on a tablet with
/// nothing on it yet, from the first screen.
class BackupSettings extends ConsumerStatefulWidget {
  const BackupSettings({super.key});

  @override
  ConsumerState<BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends ConsumerState<BackupSettings> {
  var _contents = BackupContents.everything;
  double? _progress;
  BackupResult? _result;
  String? _error;
  var _sharing = false;

  Future<void> _make() async {
    setState(() {
      _progress = 0;
      _error = null;
      _result = null;
    });
    try {
      final result = await ref
          .read(backupServiceProvider)
          .create(
            _contents,
            onProgress: (done) {
              if (mounted) setState(() => _progress = done);
            },
          );
      if (mounted) setState(() => _result = result);
    } on BackupException catch (error) {
      if (mounted) {
        setState(() => _error = BackupCopy.problem(error.problem));
      }
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  Future<void> _share(BuildContext anchorContext, BackupResult result) async {
    final box = anchorContext.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    setState(() => _sharing = true);
    try {
      final report = await ref
          .read(operatorFilesProvider)
          .shareFile(
            result.path,
            mimeType: 'application/x-tar',
            anchor: (
              left: origin.dx,
              top: origin.dy,
              width: size.width,
              height: size.height,
            ),
          );
      if (!mounted) return;
      PorcelainToast.show(
        context,
        switch (report.outcome) {
          ShareOutcome.shared => 'Backup handed on. Check it arrived.',
          ShareOutcome.dismissed => 'Not shared. The backup is still here.',
          ShareOutcome.unknown =>
            "The tablet didn't say where the backup went. Check it arrived.",
        },
        tone: report.outcome == ShareOutcome.dismissed
            ? PorcelainTone.neutral
            : PorcelainTone.success,
      );
    } on Exception {
      if (mounted) {
        PorcelainToast.show(
          context,
          'The backup could not be shared.',
          tone: PorcelainTone.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    // The browser test build (ADR-0018) has no backup file format: its
    // database is not a file. Photos leave through the Gallery instead.
    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Back up this booth',
            subtitle: 'Backups are made in the tablet app.',
          ),
          PorcelainCard(
            child: Text(
              'In the browser, events, templates and photos are kept in this '
              'browser on this device only, and clearing the site data '
              'deletes them. Download photos from the Gallery after each '
              'event (select the sessions, then Export).',
              style: theme.text.bodyLarge,
            ),
          ),
        ],
      );
    }
    final muted = theme.text.bodySmall.copyWith(color: theme.colors.inkMuted);
    final estimate = ref.watch(backupEstimateProvider(_contents)).value;
    final busy = _progress != null;
    final counts = estimate?.counts ?? const <String, int>{};
    final fits = estimate?.fits ?? true;
    final result = _result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Back up this booth',
          subtitle:
              'One file to set this booth up again on another tablet: its '
              'events, templates and, if you choose, every guest photo.',
        ),
        PorcelainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PorcelainSegmentedControl<BackupContents>(
                segments: const [
                  PorcelainSegment(
                    value: BackupContents.everything,
                    label: 'Everything',
                    icon: PorcelainIcons.gallery,
                  ),
                  PorcelainSegment(
                    value: BackupContents.setupOnly,
                    label: 'Setup only',
                    icon: PorcelainIcons.events,
                  ),
                ],
                selected: _contents,
                onChanged: busy
                    ? null
                    : (value) => setState(() {
                        _contents = value;
                        _result = null;
                        _error = null;
                      }),
                disabledReason: busy ? 'A backup is being made.' : null,
              ),
              const SizedBox(height: PorcelainSpace.md),
              Text(
                _contents == BackupContents.everything
                    ? 'Settings, events, templates and the photos of '
                          '${counts['sessions'] ?? 0} sessions '
                          '(${counts['photos'] ?? 0} camera photos, '
                          '${counts['finishedPhotos'] ?? 0} finished).'
                    : 'Settings, ${counts['events'] ?? 0} events and '
                          '${counts['templates'] ?? 0} templates, without '
                          'any guest photo.',
                style: theme.text.bodyMedium,
              ),
              const SizedBox(height: PorcelainSpace.xs),
              Text(
                estimate == null
                    ? 'Working out the size…'
                    : 'About ${formatBytes(estimate.bytes)}'
                          '${estimate.freeBytes == null ? '' : ' · ${formatBytes(estimate.freeBytes!)} free on this tablet'}',
                style: muted,
              ),
              if (!fits) ...[
                const SizedBox(height: PorcelainSpace.sm),
                StatusBadge(
                  label: BackupCopy.problem(BackupProblem.noSpace),
                  tone: PorcelainTone.danger,
                ),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: PorcelainSpace.sm),
                StatusBadge(label: error, tone: PorcelainTone.danger),
              ],
              const SizedBox(height: PorcelainSpace.lg),
              Row(
                children: [
                  PorcelainButton(
                    label: 'Make a backup',
                    icon: PorcelainIcons.backup,
                    variant: PorcelainButtonVariant.primary,
                    busy: busy,
                    busyLabel: 'Making the backup',
                    onPressed: busy || !fits || estimate == null
                        ? null
                        : () => unawaited(_make()),
                    disabledReason: !fits
                        ? BackupCopy.problem(BackupProblem.noSpace)
                        : estimate == null
                        ? 'Working out the size.'
                        : null,
                  ),
                  if (_progress case final progress?) ...[
                    const SizedBox(width: PorcelainSpace.md),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.text.bodyMedium,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: PorcelainSpace.md),
          PorcelainCard(
            padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PorcelainListRow(
                  icon: PorcelainIcons.backup,
                  title: result.fileName,
                  subtitle:
                      '${formatBytes(result.bytes)} · made '
                      '${formatTimestamp(result.manifest.createdAtUtc.toLocal())} · '
                      'read back and checked',
                  showChevron: false,
                  trailing: const StatusBadge(
                    label: 'Ready',
                    tone: PorcelainTone.success,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PorcelainSpace.lg,
                    PorcelainSpace.xs,
                    PorcelainSpace.lg,
                    PorcelainSpace.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (anchor) => PorcelainButton(
                        label: 'Share backup',
                        icon: PorcelainIcons.export,
                        busy: _sharing,
                        onPressed: _sharing
                            ? null
                            : () => unawaited(_share(anchor, result)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: PorcelainSpace.md),
        Text(
          "A backup holds guests' photos: keep it on encrypted storage and "
          'delete old ones. It never holds the operator PIN, the recovery '
          'code, the texting pairing or any phone number. The copy on this '
          'tablet is removed the next time the app starts.',
          style: muted,
        ),
        const SizedBox(height: PorcelainSpace.xxl),
        const SectionHeader(
          title: 'Restore',
          subtitle:
              'Install the app on a tablet with nothing on it and choose '
              '"Restore from a backup" on its first screen. A restore never '
              'mixes with a booth already in use.',
        ),
      ],
    );
  }
}
