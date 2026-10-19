import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../shared/guest/guest_layout.dart';
import '../../shared/widgets/porcelain_button.dart';
import 'booth_copy.dart';
import 'delivery_copy.dart';
import 'guest_parts.dart';

/// S27 Finished (CR-001 fix 11, CR-002): the finished photo as saved,
/// read back from storage, as a print with still gold confetti around;
/// "Saved to the booth gallery", a large Next guest, and a note that the
/// booth resets by itself. No print button: there is no printer (A-13),
/// and nothing here suggests the guest takes a print away.
///
/// With [onTextPhotos] it is S30 Delivery choice (UX-PD1): Text my photos
/// as the main action and No thanks, finish beside it, never a condition
/// of finishing; with [offline], a note that the text can only go if the
/// booth reconnects.
class GuestFinished extends StatelessWidget {
  const GuestFinished({
    super.key,
    required this.photo,
    required this.aspect,
    required this.onNextGuest,
    this.onTextPhotos,
    this.offline = false,
  });

  final Uint8List photo;

  /// The finished photo's width over height.
  final double aspect;
  final VoidCallback onNextGuest;

  /// Offered when the event texts photos and the service is ready (S30).
  final VoidCallback? onTextPhotos;

  /// The text would wait for a connection.
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    return GuestBackdrop(
      child: Stack(
        children: [
          const Positioned.fill(child: GuestConfetti()),
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = GuestScale.forSize(constraints.biggest);
                  final landscape =
                      constraints.maxWidth > constraints.maxHeight;
                  final box = Size(
                    constraints.maxWidth * (landscape ? 0.4 : 0.44),
                    constraints.maxHeight * (landscape ? 0.78 : 0.6),
                  );
                  final border = scale(12);
                  var width = box.width;
                  var height = (width - 2 * border) / aspect + 2 * border;
                  if (height > box.height) {
                    height = box.height;
                    width = (height - 2 * border) * aspect + 2 * border;
                  }
                  final ratio = MediaQuery.devicePixelRatioOf(context);
                  final print = Semantics(
                    label: BoothCopy.finishedPhoto,
                    image: true,
                    child: GuestPrint(
                      scale: scale,
                      border: 12,
                      angle: -0.06,
                      child: SizedBox(
                        width: width - 2 * border,
                        height: height - 2 * border,
                        child: Image.memory(
                          photo,
                          fit: BoxFit.contain,
                          cacheWidth: math.max(
                            64,
                            ((width - 2 * border) * ratio).ceil(),
                          ),
                          gaplessPlayback: true,
                          excludeFromSemantics: true,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  );
                  final words = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: scale(420)),
                        child: GuestHeading(
                          title: BoothCopy.readyTitle,
                          scale: scale,
                        ),
                      ),
                      SizedBox(height: scale(PorcelainSpace.lg)),
                      ExcludeSemantics(
                        child: Icon(
                          PorcelainIcons.enjoy,
                          size: scale(40),
                          color: colors.guestAccentText,
                          fill: 1,
                        ),
                      ),
                      SizedBox(height: scale(PorcelainSpace.lg)),
                      Text(
                        BoothCopy.savedToGallery,
                        textAlign: TextAlign.center,
                        style: scale.text(theme.text.guestBody),
                      ),
                      SizedBox(height: scale(PorcelainSpace.xxxl)),
                      if (onTextPhotos case final textPhotos?) ...[
                        PorcelainButton(
                          label: DeliveryCopy.textMyPhotos,
                          icon: PorcelainIcons.textMessage,
                          variant: PorcelainButtonVariant.primary,
                          size: PorcelainButtonSize.guest,
                          caps: true,
                          onPressed: textPhotos,
                        ),
                        SizedBox(height: scale(PorcelainSpace.md)),
                        PorcelainButton(
                          label: DeliveryCopy.noThanksFinish,
                          size: PorcelainButtonSize.large,
                          onPressed: onNextGuest,
                        ),
                        if (offline) ...[
                          SizedBox(height: scale(PorcelainSpace.md)),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: scale(400)),
                            child: Text(
                              DeliveryCopy.offlineNote,
                              textAlign: TextAlign.center,
                              style: scale.text(theme.text.guestCaption),
                            ),
                          ),
                        ],
                      ] else
                        PorcelainButton(
                          label: BoothCopy.nextGuest,
                          icon: PorcelainIcons.nextGuest,
                          size: PorcelainButtonSize.guest,
                          caps: true,
                          onPressed: onNextGuest,
                        ),
                      SizedBox(height: scale(PorcelainSpace.md)),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: scale(380)),
                        child: Text(
                          BoothCopy.resetSoon,
                          textAlign: TextAlign.center,
                          style: scale.text(theme.text.guestCaption),
                        ),
                      ),
                    ],
                  );
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        minWidth: constraints.maxWidth,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: scale(PorcelainSpace.xxl),
                          vertical: scale(PorcelainSpace.xl),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Center(child: print)),
                            SizedBox(width: scale(PorcelainSpace.xl)),
                            Expanded(child: Center(child: words)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
