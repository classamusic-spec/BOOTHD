import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/routing/route_paths.dart';
import '../../shared/widgets/botanical_ornament.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_list_row.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_stepper.dart';
import '../../shared/widgets/porcelain_switch.dart';
import '../../shared/widgets/porcelain_text_field.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/responsive_grid.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/studio_page.dart';
import '../../shared/widgets/tone.dart';

/// Developer catalogue of every Porcelain component in every state
/// (AC-0202), for design review and state goldens. Debug and profile builds
/// only. Static interaction states are forced with [PressStatePreview].
class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key, this.animateLoading = true});

  /// The loading skeleton and busy spinner animate forever; goldens turn
  /// them off so frames can settle.
  final bool animateLoading;

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  var _switch = true;
  var _shots = 3;
  var _segment = 0;

  void _noop() {}

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    Widget labelled(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.text.labelMedium.copyWith(color: theme.colors.inkMuted),
        ),
        const SizedBox(height: PorcelainSpace.xs),
        child,
      ],
    );
    const gap = SizedBox(height: PorcelainSpace.xl);

    return Scaffold(
      body: StudioPage(
        header: StudioPageHeader(
          eyebrow: 'Developer tools',
          title: 'Component gallery',
          subtitle: 'Every Porcelain component in every state.',
          actions: [
            PorcelainButton(
              label: 'Back to Diagnostics',
              icon: PorcelainIcons.back,
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RoutePaths.diagnostics),
            ),
          ],
        ),
        children: [
          _Section(
            title: 'Buttons',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final variant in PorcelainButtonVariant.values) ...[
                  Wrap(
                    spacing: PorcelainSpace.md,
                    runSpacing: PorcelainSpace.md,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      labelled(
                        'Rest',
                        PorcelainButton(
                          label: variant.name,
                          variant: variant,
                          onPressed: _noop,
                        ),
                      ),
                      labelled(
                        'Hover',
                        PressStatePreview(
                          hovered: true,
                          child: PorcelainButton(
                            label: variant.name,
                            variant: variant,
                            onPressed: _noop,
                          ),
                        ),
                      ),
                      labelled(
                        'Focus',
                        PressStatePreview(
                          focused: true,
                          child: PorcelainButton(
                            label: variant.name,
                            variant: variant,
                            onPressed: _noop,
                          ),
                        ),
                      ),
                      labelled(
                        'Pressed',
                        PressStatePreview(
                          pressed: true,
                          child: PorcelainButton(
                            label: variant.name,
                            variant: variant,
                            onPressed: _noop,
                          ),
                        ),
                      ),
                      labelled(
                        'Disabled',
                        PorcelainButton(
                          label: variant.name,
                          variant: variant,
                          onPressed: null,
                          disabledReason: 'Shown when tapped.',
                        ),
                      ),
                      if (widget.animateLoading)
                        labelled(
                          'Busy',
                          PorcelainButton(
                            label: variant.name,
                            busyLabel: 'Saving',
                            busy: true,
                            variant: variant,
                            onPressed: _noop,
                          ),
                        ),
                      labelled(
                        'Success',
                        PorcelainButton(
                          label: 'Saved',
                          variant: variant,
                          feedback: PorcelainButtonFeedback.success,
                          onPressed: _noop,
                        ),
                      ),
                      labelled(
                        'Error',
                        PorcelainButton(
                          label: 'Try again',
                          variant: variant,
                          feedback: PorcelainButtonFeedback.error,
                          onPressed: _noop,
                        ),
                      ),
                    ],
                  ),
                  gap,
                ],
                Wrap(
                  spacing: PorcelainSpace.md,
                  runSpacing: PorcelainSpace.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final size in PorcelainButtonSize.values)
                      PorcelainButton(
                        label: size.name,
                        icon: PorcelainIcons.start,
                        size: size,
                        variant: PorcelainButtonVariant.primary,
                        onPressed: _noop,
                      ),
                    PorcelainIconButton(
                      icon: PorcelainIcons.add,
                      semanticLabel: 'Add',
                      onPressed: _noop,
                    ),
                    const PorcelainIconButton(
                      icon: PorcelainIcons.add,
                      semanticLabel: 'Add (disabled)',
                      onPressed: null,
                      disabledReason: 'Shown when tapped.',
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Cards',
            child: ResponsiveGrid(
              minTileWidth: 200,
              children: [
                const PorcelainCard(child: Text('Static card')),
                PorcelainCard(onPressed: _noop, child: const Text('Pressable')),
                PressStatePreview(
                  pressed: true,
                  child: PorcelainCard(
                    onPressed: _noop,
                    child: const Text('Pressed'),
                  ),
                ),
                PorcelainCard(
                  selected: true,
                  onPressed: _noop,
                  child: const Text('Selected'),
                ),
                const PorcelainCard(
                  disabledReason: 'Shown when tapped.',
                  child: Text('Disabled'),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Toggles, steppers and selectors',
            child: Wrap(
              spacing: PorcelainSpace.xxl,
              runSpacing: PorcelainSpace.xl,
              children: [
                labelled(
                  'Switch',
                  PorcelainSwitch(
                    value: _switch,
                    semanticLabel: 'Sample switch',
                    onChanged: (value) => setState(() => _switch = value),
                  ),
                ),
                labelled(
                  'Off',
                  PorcelainSwitch(
                    value: false,
                    semanticLabel: 'Off switch',
                    onChanged: (_) {},
                  ),
                ),
                labelled(
                  'Disabled',
                  const PorcelainSwitch(
                    value: true,
                    semanticLabel: 'Disabled switch',
                    onChanged: null,
                    disabledReason: 'Shown when tapped.',
                  ),
                ),
                labelled(
                  'Stepper',
                  PorcelainStepper(
                    label: 'Photos per session',
                    value: _shots,
                    min: 1,
                    max: 4,
                    decreaseLabel: 'Fewer photos',
                    increaseLabel: 'More photos',
                    minimumReason: 'A session takes at least 1 photo.',
                    maximumReason: 'A session takes at most 4 photos.',
                    onChanged: (value) => setState(() => _shots = value),
                  ),
                ),
                labelled(
                  'Segmented',
                  PorcelainSegmentedControl<int>(
                    selected: _segment,
                    onChanged: (value) => setState(() => _segment = value),
                    segments: const [
                      PorcelainSegment(value: 0, label: 'One'),
                      PorcelainSegment(value: 1, label: 'Two'),
                      PorcelainSegment(value: 2, label: 'Three'),
                    ],
                  ),
                ),
                SizedBox(
                  width: 420,
                  child: PorcelainSwitchRow(
                    title: 'Switch row',
                    subtitle: 'The whole row is the control.',
                    icon: PorcelainIcons.motion,
                    value: _switch,
                    onChanged: (value) => setState(() => _switch = value),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Inputs',
            child: ResponsiveGrid(
              minTileWidth: 260,
              children: const [
                PorcelainTextField(
                  label: 'Event name',
                  hint: 'For example, Spring Gala',
                  helper: 'Shown to operators only.',
                ),
                PorcelainTextField(
                  label: 'Countdown seconds',
                  hint: '3',
                  error: 'Enter a whole number from 1 to 10.',
                ),
                PorcelainTextField(
                  label: 'Venue',
                  enabled: false,
                  disabledReason: 'Arrives in M03.',
                ),
              ],
            ),
          ),
          _Section(
            title: 'Status and feedback',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: PorcelainSpace.sm,
                  runSpacing: PorcelainSpace.sm,
                  children: [
                    for (final tone in PorcelainTone.values)
                      StatusBadge(label: tone.name, tone: tone),
                  ],
                ),
                gap,
                ResponsiveGrid(
                  minTileWidth: 300,
                  spacing: PorcelainSpace.md,
                  children: [
                    for (final tone in PorcelainTone.values)
                      PorcelainToastCard(
                        message: 'A ${tone.name} toast message.',
                        tone: tone,
                      ),
                  ],
                ),
                gap,
                Wrap(
                  spacing: PorcelainSpace.sm,
                  runSpacing: PorcelainSpace.sm,
                  children: [
                    PorcelainButton(
                      label: 'Show toast',
                      onPressed: () => PorcelainToast.show(
                        context,
                        'Toasts are announced to screen readers.',
                      ),
                    ),
                    PorcelainButton(
                      label: 'Open sheet',
                      onPressed: () => showPorcelainSheet<void>(
                        context: context,
                        title: 'A porcelain sheet',
                        body: const Text(
                          'Sheets hold short tasks and confirmations.',
                        ),
                        actions: (sheetContext) => [
                          PorcelainButton(
                            label: 'Close',
                            variant: PorcelainButtonVariant.primary,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _Section(
            title: 'Lists',
            child: ResponsiveGrid(
              minTileWidth: 300,
              children: [
                PorcelainCard(
                  child: Column(
                    children: [
                      PorcelainListRow(
                        icon: PorcelainIcons.appearance,
                        title: 'Selected row',
                        subtitle: 'Master-detail selection',
                        selected: true,
                        onPressed: _noop,
                      ),
                      PorcelainListRow(
                        icon: PorcelainIcons.camera,
                        title: 'Row',
                        subtitle: 'Opens something',
                        onPressed: _noop,
                      ),
                      const PorcelainListRow(
                        icon: PorcelainIcons.security,
                        title: 'Disabled row',
                        subtitle: 'Explains itself when tapped',
                        disabledReason: 'Shown when tapped.',
                      ),
                    ],
                  ),
                ),
                PorcelainCard(
                  child: widget.animateLoading
                      ? const SkeletonList(semanticLabel: 'Loading sessions')
                      : const Text('Loading skeleton (animated)'),
                ),
              ],
            ),
          ),
          const _Section(
            title: 'Empty and error states',
            child: ResponsiveGrid(
              minTileWidth: 340,
              children: [
                PorcelainCard(
                  child: EmptyState(
                    icon: PorcelainIcons.gallery,
                    title: 'Nothing here yet',
                    message: 'Empty states explain what will appear.',
                  ),
                ),
                PorcelainCard(
                  child: EmptyState(
                    icon: PorcelainIcons.error,
                    tone: PorcelainTone.danger,
                    title: 'Could not load',
                    message: 'Errors say what happened and what to do.',
                    actions: [
                      PorcelainButton(
                        label: 'Retry',
                        icon: PorcelainIcons.retry,
                        onPressed: null,
                        disabledReason: 'Sample only.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Template thumbnails and ornaments',
            child: Wrap(
              spacing: PorcelainSpace.xxl,
              runSpacing: PorcelainSpace.xl,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                BotanicalOrnament.sprig(width: 140, height: 140),
                BotanicalOrnament.wreath(diameter: 180),
                BotanicalOrnament.flourish(),
              ],
            ),
          ),
          _Section(
            title: 'Type scale',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display small', style: theme.text.displaySmall),
                Text('Headline medium', style: theme.text.headlineMedium),
                Text('Headline small', style: theme.text.headlineSmall),
                Text('Title large', style: theme.text.titleLarge),
                Text('Title medium', style: theme.text.titleMedium),
                Text('Body large, for reading', style: theme.text.bodyLarge),
                Text('Body medium', style: theme.text.bodyMedium),
                Text('Body small caption', style: theme.text.bodySmall),
                Text('Label large', style: theme.text.labelLarge),
                Text('EYEBROW', style: theme.text.eyebrow),
                Text('1200 × 1800 px · 0123456789', style: theme.text.numeric),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        child,
      ],
    );
  }
}
