import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_colors.dart';
import '../../core/design_system/porcelain_icons.dart';

/// Status tones. A tone always pairs its colour with an icon and words, so
/// status is never carried by colour alone.
enum PorcelainTone {
  neutral,
  info,
  success,
  warning,
  danger;

  /// Text and icon colour; >=4.5:1 on [surfaceColor] and on every surface.
  Color foreground(PorcelainColors colors) => switch (this) {
    PorcelainTone.neutral => colors.inkMuted,
    PorcelainTone.info => colors.accentText,
    PorcelainTone.success => colors.success,
    PorcelainTone.warning => colors.warning,
    PorcelainTone.danger => colors.danger,
  };

  Color surfaceColor(PorcelainColors colors) => switch (this) {
    PorcelainTone.neutral => colors.inset,
    PorcelainTone.info => colors.selected,
    PorcelainTone.success => colors.successSurface,
    PorcelainTone.warning => colors.warningSurface,
    PorcelainTone.danger => colors.dangerSurface,
  };

  IconData get icon => switch (this) {
    PorcelainTone.neutral => PorcelainIcons.pending,
    PorcelainTone.info => PorcelainIcons.info,
    PorcelainTone.success => PorcelainIcons.success,
    PorcelainTone.warning => PorcelainIcons.warning,
    PorcelainTone.danger => PorcelainIcons.error,
  };
}
