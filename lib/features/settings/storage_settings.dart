import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/di/service_providers.dart';
import '../../core/gallery/gallery_providers.dart';
import '../../core/routing/route_paths.dart';
import '../../shared/gallery/gallery_actions.dart';
import '../../shared/gallery/gallery_copy.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tone.dart';

/// Storage (S16 disk use, P-13): what photos use on this tablet, the free
/// space, camera photos in no session, the thumbnail cache and files a
/// deletion has still to remove. Every removal is confirmed first.
class StorageSettings extends ConsumerWidget {
  const StorageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(storageUsageProvider(null));
    final free = ref.watch(freeSpaceProvider).value;
    final thumbnails = ref.watch(thumbnailCacheSizeProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'On this tablet',
          subtitle:
              'Photos stay in the app’s private storage until you delete '
              'them. Nothing is uploaded.',
        ),
        switch (usage) {
          AsyncData(value: final usage) => PorcelainCard(
            padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.sm),
            child: Column(
              children: [
                PorcelainListRow(
                  icon: PorcelainIcons.gallery,
                  title: 'Finished photos',
                  subtitle:
                      '${usage.finishedCount} in '
                      '${GalleryCopy.sessions(usage.sessionCount)}',
                  showChevron: false,
                  trailing: StatusBadge(
                    label: GalleryCopy.bytes(usage.finishedBytes),
                    tone: PorcelainTone.info,
                  ),
                ),
                PorcelainListRow(
                  icon: PorcelainIcons.camera,
                  title: 'Camera photos in sessions',
                  subtitle:
                      '${usage.originalCount}, retakes included. Kept as '
                      'taken; finished photos are made from them.',
                  showChevron: false,
                  trailing: StatusBadge(
                    label: GalleryCopy.bytes(usage.originalBytes),
                    tone: PorcelainTone.info,
                  ),
                ),
                PorcelainListRow(
                  icon: PorcelainIcons.image,
                  title: 'Camera photos in no session',
                  subtitle: usage.unassignedCount == 0
                      ? 'None'
                      : '${usage.unassignedCount}: camera tests and photos '
                            'that arrived after a session stopped waiting',
                  showChevron: false,
                  trailing: usage.unassignedCount == 0
                      ? null
                      : PorcelainButton(
                          label: 'Delete…',
                          variant: PorcelainButtonVariant.danger,
                          size: PorcelainButtonSize.compact,
                          onPressed: () => GalleryActions.deleteUnassigned(
                            context,
                            ref,
                            usage.unassignedCount,
                          ),
                        ),
                ),
                PorcelainListRow(
                  icon: PorcelainIcons.storage,
                  title: 'Free space',
                  subtitle: 'What the tablet reports as available',
                  showChevron: false,
                  trailing: StatusBadge(
                    label: free == null ? 'Unknown' : GalleryCopy.bytes(free),
                    tone: PorcelainTone.neutral,
                  ),
                ),
              ],
            ),
          ),
          AsyncError() => PorcelainCard(
            child: PorcelainListRow(
              icon: PorcelainIcons.error,
              title: "Storage use couldn't be read",
              subtitle: 'Try again in a moment.',
              showChevron: false,
              trailing: PorcelainButton(
                label: 'Try again',
                size: PorcelainButtonSize.compact,
                onPressed: () => invalidateGallery(ref.invalidate),
              ),
            ),
          ),
          _ => const SkeletonList(semanticLabel: 'Loading storage use'),
        },
        const SizedBox(height: PorcelainSpace.xxxl),
        const SectionHeader(
          title: 'Upkeep',
          subtitle: 'Safe to use at any time.',
        ),
        PorcelainCard(
          padding: const EdgeInsets.symmetric(vertical: PorcelainSpace.sm),
          child: Column(
            children: [
              PorcelainListRow(
                icon: PorcelainIcons.grid,
                title: 'Gallery thumbnails',
                subtitle:
                    'Small copies for the gallery grid, made again when '
                    'needed.',
                showChevron: false,
                trailing: PorcelainButton(
                  label: thumbnails == null
                      ? 'Clear'
                      : 'Clear ${GalleryCopy.bytes(thumbnails)}',
                  size: PorcelainButtonSize.compact,
                  onPressed: thumbnails == null || thumbnails == 0
                      ? null
                      : () async {
                          final freed = await ref
                              .read(thumbnailStoreProvider)
                              .clear();
                          invalidateGallery(ref.invalidate);
                          if (context.mounted) {
                            PorcelainToast.show(
                              context,
                              'Thumbnails cleared (${GalleryCopy.bytes(freed)}).',
                              tone: PorcelainTone.success,
                            );
                          }
                        },
                  disabledReason: thumbnails == null
                      ? 'Measuring the thumbnails…'
                      : thumbnails == 0
                      ? 'There are no thumbnails to clear.'
                      : null,
                ),
              ),
              if (usage.value case final usage? when usage.pendingCleanup > 0)
                PorcelainListRow(
                  icon: PorcelainIcons.pending,
                  title: 'Files waiting to be removed',
                  subtitle:
                      '${GalleryCopy.files(usage.pendingCleanup)} of deleted '
                      'sessions could not be removed yet. The tablet tries '
                      'again at every start.',
                  showChevron: false,
                  trailing: PorcelainButton(
                    label: 'Try now',
                    size: PorcelainButtonSize.compact,
                    onPressed: () async {
                      await ref.read(galleryServiceProvider).cleanUp();
                      invalidateGallery(ref.invalidate);
                    },
                  ),
                ),
              PorcelainListRow(
                icon: PorcelainIcons.gallery,
                title: 'Review and delete sessions',
                subtitle:
                    'In the gallery: select sessions, or delete those past '
                    "an event's retention.",
                onPressed: () => context.go(RoutePaths.gallery),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
