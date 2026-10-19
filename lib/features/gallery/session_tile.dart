import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../domain/gallery/gallery_models.dart';
import '../../domain/services/gallery_services.dart';
import '../../shared/formatters/date_format.dart';
import '../../shared/gallery/gallery_copy.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/tone.dart';
import 'gallery_thumbnail.dart';

/// The tone of a session's state in the grid and its details.
PorcelainTone galleryTone(GallerySessionState state) => switch (state) {
  GallerySessionState.finished => PorcelainTone.success,
  GallerySessionState.waitingToFinish ||
  GallerySessionState.renderFailed => PorcelainTone.warning,
  GallerySessionState.notFinished ||
  GallerySessionState.inProgress => PorcelainTone.neutral,
};

/// One session in the gallery grid (S13): its finished photo as a print on
/// a tray (or its first camera photo when there is none), number, time and
/// state in words. In select mode a tap selects it; otherwise it opens the
/// session.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    required this.onPressed,
    this.selecting = false,
    this.selected = false,
    this.onLongPress,
  });

  final GallerySession session;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final bool selecting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final output = session.latestOutput;
    final cover = session.coverOriginalId;
    final time = formatClock(session.startedAtUtc.toLocal());
    final state = GalleryCopy.state(session);
    final tone = galleryTone(session.state);
    final Widget picture;
    if (output != null) {
      picture = Padding(
        padding: const EdgeInsets.all(PorcelainSpace.md),
        child: Center(
          child: PrintFrame(
            aspectRatio: output.widthPx / output.heightPx,
            child: GalleryThumbnail(
              source: ThumbnailSource(
                kind: ThumbnailKind.output,
                id: output.id,
                relativePath: output.relativePath,
              ),
            ),
          ),
        ),
      );
    } else if (cover != null) {
      picture = GalleryThumbnail(
        fit: BoxFit.cover,
        source: ThumbnailSource(
          kind: ThumbnailKind.original,
          id: cover,
          relativePath: 'originals/$cover.jpg',
        ),
      );
    } else {
      picture = Center(
        child: Icon(PorcelainIcons.camera, size: 28, color: colors.inkMuted),
      );
    }

    // Long press is a shortcut into select mode; the Select button offers
    // the same to assistive technologies, so it stays out of semantics.
    return GestureDetector(
      onLongPress: onLongPress,
      excludeFromSemantics: true,
      child: PorcelainCard(
        padding: const EdgeInsets.all(PorcelainSpace.sm),
        selected: selected,
        semanticLabel:
            '${GalleryCopy.sessionTitle(session.number)}, $time, $state',
        onPressed: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: PorcelainRadius.controlAll,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: colors.inset),
                    picture,
                    if (selecting && !selected)
                      PositionedDirectional(
                        top: PorcelainSpace.sm,
                        end: PorcelainSpace.sm,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.raised.withValues(alpha: 0.85),
                            border: Border.all(color: colors.outline, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: PorcelainSpace.sm),
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PorcelainSpace.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'No. ${session.number}',
                            style: theme.text.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: theme.text.labelMedium.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          tone.icon,
                          size: 14,
                          color: tone.foreground(colors),
                          fill: 1,
                        ),
                        const SizedBox(width: PorcelainSpace.xs),
                        Expanded(
                          child: Text(
                            state,
                            style: theme.text.labelSmall.copyWith(
                              color: tone.foreground(colors),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
