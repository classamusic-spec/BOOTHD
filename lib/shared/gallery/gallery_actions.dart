import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../core/gallery/gallery_service.dart';
import '../../domain/repositories/session_repository.dart';
import '../widgets/porcelain_button.dart';
import '../widgets/porcelain_sheet.dart';
import '../widgets/porcelain_switch.dart';
import '../widgets/porcelain_toast.dart';
import '../widgets/tone.dart';
import 'gallery_copy.dart';

/// Gallery actions with their confirmations and results (S13, S14,
/// AC-0804, AC-0805).
abstract final class GalleryActions {
  /// Asks, then deletes [sessionIds]. Returns whether anything was
  /// deleted.
  static Future<bool> deleteSessions(
    BuildContext context,
    WidgetRef ref,
    List<String> sessionIds, {
    String? title,
    String? body,
    bool acknowledge = false,
  }) async {
    final confirmed = await confirmDeletion(
      context,
      title: title ?? GalleryCopy.deleteSessionsTitle(sessionIds.length),
      body: body ?? GalleryCopy.deleteSessionsBody(sessionIds.length),
      acknowledge: acknowledge,
    );
    if (!confirmed || !context.mounted) return false;
    return _delete(
      context,
      ref,
      () => ref.read(galleryServiceProvider).deleteSessions(sessionIds),
      done: GalleryCopy.deleted(sessionIds.length),
    );
  }

  /// Runs a deletion the operator already confirmed.
  static Future<bool> _delete(
    BuildContext context,
    WidgetRef ref,
    Future<DeletionOutcome> Function() delete, {
    required String done,
  }) async {
    try {
      final outcome = await delete();
      invalidateGallery(ref.invalidate);
      if (context.mounted) {
        PorcelainToast.show(
          context,
          outcome.filesPending ? '$done ${GalleryCopy.filesPending}' : done,
          tone: outcome.filesPending
              ? PorcelainTone.warning
              : PorcelainTone.success,
          icon: PorcelainIcons.delete,
        );
      }
      return true;
    } on GalleryActionFailure catch (failure) {
      if (context.mounted) {
        PorcelainToast.show(
          context,
          GalleryCopy.deleteFailed(failure.code),
          tone: PorcelainTone.danger,
        );
      }
      return false;
    }
  }

  /// Deletes, after confirmation, an archived event and all its photos.
  static Future<bool> deleteEvent(
    BuildContext context,
    WidgetRef ref, {
    required String eventId,
    required String title,
    required int sessionCount,
  }) async {
    final confirmed = await confirmDeletion(
      context,
      title: 'Delete “$title”?',
      body: sessionCount == 0
          ? 'The event and its settings are removed from this tablet. '
                "This can't be undone."
          : 'The event, its settings and its ${GalleryCopy.sessions(sessionCount)} '
                'with every camera photo and finished photo are removed '
                "from this tablet. This can't be undone; export first if you "
                'need them.',
      acknowledge: sessionCount > 0,
    );
    if (!confirmed || !context.mounted) return false;
    return _delete(
      context,
      ref,
      () => ref.read(galleryServiceProvider).deleteEvent(eventId),
      done: '“$title” deleted.',
    );
  }

  /// Deletes, after confirmation, camera photos that belong to no session.
  static Future<bool> deleteUnassigned(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final confirmed = await confirmDeletion(
      context,
      title: count == 1
          ? 'Delete 1 camera photo?'
          : 'Delete $count camera photos?',
      body:
          'These photos belong to no session: camera tests, and photos that '
          'arrived after a session stopped waiting for them. They are '
          "removed from this tablet. This can't be undone.",
    );
    if (!confirmed || !context.mounted) return false;
    return _delete(
      context,
      ref,
      () => ref.read(galleryServiceProvider).deleteUnassignedOriginals(),
      done: count == 1 ? 'Camera photo deleted.' : 'Camera photos deleted.',
    );
  }

  /// Makes a finished photo for [sessionId] (finish, re-render or make one
  /// for a session that ended without it). Returns whether one was made.
  static Future<bool> render(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    try {
      final output = await ref.read(galleryServiceProvider).render(sessionId);
      invalidateGallery(ref.invalidate);
      if (context.mounted) {
        PorcelainToast.show(
          context,
          output.origin == SessionOutputOrigin.session
              ? GalleryCopy.finished
              : GalleryCopy.rendered,
          tone: PorcelainTone.success,
        );
      }
      return true;
    } on GalleryActionFailure catch (failure) {
      invalidateGallery(ref.invalidate);
      if (context.mounted) {
        PorcelainToast.show(
          context,
          GalleryCopy.renderFailed(failure.code),
          tone: PorcelainTone.danger,
        );
      }
      return false;
    }
  }

  /// A deletion confirmation: [title], [body], Keep and a danger Delete.
  /// With [acknowledge], Delete stays disabled until the operator turns on
  /// "Delete them permanently".
  static Future<bool> confirmDeletion(
    BuildContext context, {
    required String title,
    required String body,
    bool acknowledge = false,
  }) async =>
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        sheetAnimationStyle: PorcelainMotion.of(context).isReduced
            ? AnimationStyle.noAnimation
            : null,
        builder: (_) =>
            _DeleteSheet(title: title, body: body, acknowledge: acknowledge),
      ) ==
      true;
}

class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet({
    required this.title,
    required this.body,
    required this.acknowledge,
  });

  final String title;
  final String body;
  final bool acknowledge;

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  var _sure = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final ready = !widget.acknowledge || _sure;
    return PorcelainSheet(
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          if (widget.acknowledge) ...[
            const SizedBox(height: PorcelainSpace.lg),
            PorcelainSwitchRow(
              title: 'Delete them permanently',
              subtitle: 'I have exported anything I need.',
              icon: PorcelainIcons.delete,
              value: _sure,
              onChanged: (value) => setState(() => _sure = value),
            ),
          ],
          const SizedBox(height: PorcelainSpace.xs),
          Text(
            'Records go first; files follow, and finish after a restart if '
            'interrupted.',
            style: theme.text.bodySmall.copyWith(color: theme.colors.inkMuted),
          ),
        ],
      ),
      actions: [
        PorcelainButton(
          label: GalleryCopy.keep,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PorcelainButton(
          label: GalleryCopy.deleteConfirm,
          icon: PorcelainIcons.delete,
          variant: PorcelainButtonVariant.danger,
          disabledReason: ready
              ? null
              : 'Turn on “Delete them permanently” first.',
          onPressed: ready ? () => Navigator.of(context).pop(true) : null,
        ),
      ],
    );
  }
}
