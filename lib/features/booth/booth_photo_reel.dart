import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_motion.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../domain/gallery/gallery_models.dart';
import '../../domain/services/gallery_services.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/gallery/gallery_thumbnail.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_spinner.dart';

/// The running event's finished photos, newest first, one at a time: for
/// the operator in Booth Mode once the PIN has been entered (S28). Swiped
/// or stepped with buttons; nothing here changes, exports or shares them
/// (the Studio's Gallery does that).
class BoothPhotoReel extends ConsumerStatefulWidget {
  const BoothPhotoReel({
    super.key,
    required this.eventId,
    required this.onClose,
  });

  final String eventId;
  final VoidCallback onClose;

  @override
  ConsumerState<BoothPhotoReel> createState() => _BoothPhotoReelState();
}

class _BoothPhotoReelState extends ConsumerState<BoothPhotoReel> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _show(int index) {
    final motion = PorcelainMotion.of(context);
    if (motion.isReduced) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: motion.page,
        curve: PorcelainMotion.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final sessions = ref.watch(gallerySessionsProvider(widget.eventId));
    final done = PorcelainButton(
      label: 'Done',
      icon: PorcelainIcons.back,
      onPressed: widget.onClose,
    );
    final Widget body = switch (sessions) {
      AsyncData(:final value) => () {
        final photos = [
          for (final session in value)
            if (session.latestOutput case final output?) (session, output),
        ];
        if (photos.isEmpty) {
          return _Message(
            icon: PorcelainIcons.gallery,
            title: 'No photos yet',
            message:
                "Each guest's finished photo appears here as soon as it is "
                'saved.',
            action: done,
          );
        }
        final index = _index.clamp(0, photos.length - 1);
        final (session, _) = photos[index];
        final height = (MediaQuery.sizeOf(context).height * 0.5).clamp(
          220.0,
          560.0,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Photo reel',
                textAlign: TextAlign.center,
                style: theme.text.headlineMedium,
              ),
            ),
            const SizedBox(height: PorcelainSpace.xxs),
            Text(
              photos.length == 1
                  ? '1 finished photo'
                  : '${photos.length} finished photos, newest first',
              textAlign: TextAlign.center,
              style: theme.text.bodyMedium.copyWith(color: colors.inkMuted),
            ),
            const SizedBox(height: PorcelainSpace.lg),
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pages,
                itemCount: photos.length,
                onPageChanged: (page) => setState(() => _index = page),
                itemBuilder: (context, page) {
                  final (session, output) = photos[page];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PorcelainSpace.sm,
                      vertical: PorcelainSpace.xs,
                    ),
                    child: Center(
                      child: PrintFrame(
                        aspectRatio: output.widthPx / output.heightPx,
                        child: GalleryThumbnail(
                          semanticLabel:
                              'Finished photo of session ${session.number}',
                          source: ThumbnailSource(
                            kind: ThumbnailKind.output,
                            id: output.id,
                            relativePath: output.relativePath,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: PorcelainSpace.md),
            Text(
              _caption(session),
              textAlign: TextAlign.center,
              style: theme.text.labelLarge,
            ),
            const SizedBox(height: PorcelainSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PorcelainIconButton(
                  icon: PorcelainIcons.back,
                  semanticLabel: 'Newer photo',
                  onPressed: index > 0 ? () => _show(index - 1) : null,
                  disabledReason: 'This is the newest photo.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PorcelainSpace.lg,
                  ),
                  child: Text(
                    '${index + 1} of ${photos.length}',
                    style: theme.text.titleSmall,
                  ),
                ),
                PorcelainIconButton(
                  icon: PorcelainIcons.chevron,
                  semanticLabel: 'Older photo',
                  onPressed: index < photos.length - 1
                      ? () => _show(index + 1)
                      : null,
                  disabledReason: 'This is the oldest photo.',
                ),
              ],
            ),
            const SizedBox(height: PorcelainSpace.lg),
            done,
          ],
        );
      }(),
      AsyncError() => _Message(
        icon: PorcelainIcons.error,
        title: "The photos couldn't be read",
        message: 'Try again, or look in the Gallery after Booth Mode.',
        action: Wrap(
          alignment: WrapAlignment.center,
          spacing: PorcelainSpace.sm,
          runSpacing: PorcelainSpace.sm,
          children: [
            done,
            PorcelainButton(
              label: 'Try again',
              icon: PorcelainIcons.retry,
              onPressed: () =>
                  ref.invalidate(gallerySessionsProvider(widget.eventId)),
            ),
          ],
        ),
      ),
      _ => Padding(
        padding: const EdgeInsets.all(PorcelainSpace.xxl),
        child: Semantics(
          label: 'Loading the photos',
          child: Center(
            child: PorcelainSpinner(color: colors.accentIcon, size: 32),
          ),
        ),
      ),
    };
    return body;
  }

  static String _caption(GallerySession session) =>
      'Session ${session.number} · '
      '${formatClock((session.endedAtUtc ?? session.startedAtUtc).toLocal())}';
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: theme.colors.accentIcon),
        const SizedBox(height: PorcelainSpace.md),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.text.headlineSmall,
          ),
        ),
        const SizedBox(height: PorcelainSpace.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.text.bodyLarge.copyWith(color: theme.colors.inkMuted),
        ),
        const SizedBox(height: PorcelainSpace.xl),
        action,
      ],
    );
  }
}
