import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/app_environment.dart';
import '../../core/routing/route_paths.dart';
import '../../domain/value_objects/orientation.dart';

/// Engineering-baseline home screen (M00, extended in M01).
///
/// Shows only facts the build can verify about itself. The Studio dashboard
/// (S02) replaces it in M02. Release builds offer no actions, because every
/// feature belongs to a later milestone and dead controls are forbidden;
/// debug and profile builds add links to the M01 developer spikes.
class BaselineHomeScreen extends ConsumerWidget {
  const BaselineHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final environment = ref.watch(appEnvironmentProvider);
    final size = MediaQuery.sizeOf(context);
    final viewport = ViewportOrientation.fromLogicalSize(
      width: size.width,
      height: size.height,
    );
    final textTheme = Theme.of(context).textTheme;
    final devTools = environment.buildMode != BuildMode.release;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Porcelain Photo Booth',
                      style: textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Engineering baseline · M01',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Studio Mode, Booth Mode and the production camera and '
                    'template features arrive in later milestones and are '
                    'intentionally absent from this build.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  _Fact(label: 'Platform', value: environment.platformLabel),
                  _Fact(label: 'Build mode', value: environment.buildMode.name),
                  _Fact(
                    label: 'Viewport',
                    value:
                        '${size.width.round()} × ${size.height.round()} '
                        'logical px · ${viewport.name}',
                  ),
                  if (devTools) ...[
                    const SizedBox(height: 32),
                    Semantics(
                      header: true,
                      child: Text(
                        'Developer spikes',
                        style: textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Debug and profile builds only; absent from release.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: () => context.push(RoutePaths.renderSpike),
                          child: const Text('Render spike'),
                        ),
                        FilledButton(
                          onPressed: () => context.push(RoutePaths.cameraSpike),
                          child: const Text('Camera spike'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          spacing: 12,
          children: [
            Text(label, style: textTheme.labelLarge),
            Text(value, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
