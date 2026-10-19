import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/di/service_providers.dart';
import '../../domain/backup/backup_manifest.dart';
import '../../domain/services/backup_service.dart';
import '../../domain/services/operator_files.dart';
import '../../shared/backup/backup_copy.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_spinner.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

enum _Phase { choose, checking, ready, restoring, failed }

/// Restoring a backup on a booth with nothing on it yet (S01, M10,
/// AC-1001, AC-1006): choose the file, which is copied into the app and
/// checked from end to end before anything changes; read what it holds;
/// restore, which swaps it in and starts the app again. Setup then asks
/// for a new PIN and recovery code (a backup never carries them).
class RestoreBackupPanel extends ConsumerStatefulWidget {
  const RestoreBackupPanel({super.key, required this.onCancel});

  /// Back to the welcome step; nothing was changed.
  final VoidCallback onCancel;

  @override
  ConsumerState<RestoreBackupPanel> createState() => _RestoreBackupPanelState();
}

class _RestoreBackupPanelState extends ConsumerState<RestoreBackupPanel> {
  var _phase = _Phase.choose;
  double _progress = 0;
  RestoreCandidate? _candidate;
  String? _fileName;
  String? _problem;

  BackupService get _backups => ref.read(backupServiceProvider);

  void _onProgress(double done) {
    if (mounted) setState(() => _progress = done);
  }

  Future<void> _choose() async {
    final previous = _candidate;
    if (previous != null) unawaited(_backups.discard(previous));
    setState(() {
      _candidate = null;
      _problem = null;
    });
    final PickedStream? file;
    try {
      file = await ref
          .read(operatorFilesProvider)
          .pickStream(PickableFile.backup);
    } on FilePickException {
      if (mounted) _fail("The chosen file couldn't be read.");
      return;
    }
    if (file == null || !mounted) return;
    setState(() {
      _phase = _Phase.checking;
      _progress = 0;
      _fileName = file!.name;
    });
    try {
      final candidate = await _backups.inspect(file, onProgress: _onProgress);
      if (!mounted) return;
      setState(() {
        _candidate = candidate;
        _phase = _Phase.ready;
      });
    } on BackupException catch (error) {
      if (mounted) _fail(BackupCopy.problem(error.problem));
    }
  }

  Future<void> _restore() async {
    final candidate = _candidate!;
    setState(() {
      _phase = _Phase.restoring;
      _progress = 0;
    });
    try {
      await _backups.stage(candidate, onProgress: _onProgress);
    } on BackupException catch (error) {
      if (mounted) _fail(BackupCopy.problem(error.problem));
      return;
    }
    // The app starts again: the restore is swapped in before anything
    // opens the database, then setup continues.
    await ref.read(appRestartProvider)();
  }

  void _fail(String problem) => setState(() {
    _phase = _Phase.failed;
    _problem = problem;
    _candidate = null;
  });

  void _cancel() {
    final candidate = _candidate;
    if (candidate != null) unawaited(_backups.discard(candidate));
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final muted = theme.text.bodyMedium.copyWith(color: colors.inkMuted);
    final candidate = _candidate;

    Widget working(String label) => Column(
      children: [
        const SizedBox(height: PorcelainSpace.lg),
        PorcelainSpinner(color: colors.accentIcon),
        const SizedBox(height: PorcelainSpace.lg),
        Semantics(
          liveRegion: true,
          child: Text(
            '$label ${(_progress * 100).round()}%',
            textAlign: TextAlign.center,
            style: theme.text.titleMedium,
          ),
        ),
        if (_fileName case final name?) ...[
          const SizedBox(height: PorcelainSpace.xs),
          Text(name, textAlign: TextAlign.center, style: muted),
        ],
        const SizedBox(height: PorcelainSpace.lg),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Restore from a backup', style: theme.text.headlineLarge),
        ),
        const SizedBox(height: PorcelainSpace.md),
        switch (_phase) {
          _Phase.choose => Text(
            'Choose a backup made by Porcelain Photo Booth (Settings > '
            'Backup on the old tablet). It is checked from end to end '
            'before anything changes here.',
            style: muted,
          ),
          _Phase.checking => working('Checking the backup…'),
          _Phase.restoring => working('Restoring… keep the app open.'),
          _Phase.failed => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusBadge(
                label: _problem ?? '',
                tone: PorcelainTone.danger,
                icon: PorcelainIcons.warning,
              ),
              const SizedBox(height: PorcelainSpace.sm),
              Text('Nothing on this tablet was changed.', style: muted),
            ],
          ),
          _Phase.ready => _Summary(manifest: candidate!.manifest),
        },
        const SizedBox(height: PorcelainSpace.xl),
        if (_phase != _Phase.checking && _phase != _Phase.restoring)
          Wrap(
            spacing: PorcelainSpace.sm,
            runSpacing: PorcelainSpace.sm,
            alignment: WrapAlignment.end,
            children: [
              PorcelainButton(
                label: 'Cancel',
                variant: PorcelainButtonVariant.quiet,
                onPressed: _cancel,
              ),
              if (_phase == _Phase.ready)
                PorcelainButton(
                  label: 'Choose another file',
                  icon: PorcelainIcons.upload,
                  onPressed: () => unawaited(_choose()),
                ),
              PorcelainButton(
                label: _phase == _Phase.ready
                    ? 'Restore'
                    : _phase == _Phase.failed
                    ? 'Choose another file'
                    : 'Choose backup file',
                icon: _phase == _Phase.ready
                    ? PorcelainIcons.restoreBackup
                    : PorcelainIcons.upload,
                variant: PorcelainButtonVariant.primary,
                onPressed: _phase == _Phase.ready
                    ? () => unawaited(_restore())
                    : () => unawaited(_choose()),
              ),
            ],
          ),
      ],
    );
  }
}

/// What a checked backup holds, and what a restore will and will not bring
/// back.
class _Summary extends StatelessWidget {
  const _Summary({required this.manifest});

  final BackupManifest manifest;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusBadge(
          label: 'Checked: complete and unchanged',
          tone: PorcelainTone.success,
        ),
        const SizedBox(height: PorcelainSpace.md),
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manifest.boothName.isEmpty
                    ? 'A booth backup'
                    : '"${manifest.boothName}"',
                style: theme.text.titleLarge,
              ),
              Text(
                'Made ${formatTimestamp(manifest.createdAtUtc.toLocal())} '
                'by version ${manifest.appVersion}',
                style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
              ),
              const SizedBox(height: PorcelainSpace.sm),
              Text(
                BackupCopy.contents(manifest.counts),
                style: theme.text.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.md),
        Text(
          'After restoring you choose a new PIN and recovery code, and '
          'texting needs pairing again: a backup never carries them.',
          style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
        ),
      ],
    );
  }
}
