import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/app_environment.dart';
import '../../domain/value_objects/orientation.dart';

/// Engineering-baseline home screen for milestone M00.
///
/// Shows only facts the build can verify about itself. The Studio dashboard
/// (S02) replaces it in M02. It has no actions on purpose: everything it
/// could link to belongs to a later milestone, and the product rules forbid
/// dead controls.
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
                    'Engineering baseline · M00',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'This build contains the project foundation only. Studio '
                    'Mode, Booth Mode, camera capture and template rendering '
                    'arrive in later milestones and are intentionally absent.',
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
