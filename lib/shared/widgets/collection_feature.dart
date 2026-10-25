import 'package:flutter/material.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_theme.dart';
import 'atelier_showcase.dart';
import 'porcelain_button.dart';
import 'porcelain_card.dart';

/// A collection introduction with live print previews and one real action.
class CollectionFeature extends StatelessWidget {
  const CollectionFeature({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });
  final String eyebrow;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: theme.text.eyebrow),
        const SizedBox(height: 12),
        Text(title, style: theme.text.headlineLarge),
        const SizedBox(height: 12),
        Text(
          description,
          style: theme.text.bodyLarge.copyWith(color: theme.colors.inkMuted),
        ),
        const SizedBox(height: 24),
        PorcelainButton(
          label: actionLabel,
          icon: PorcelainIcons.chevron,
          variant: PorcelainButtonVariant.primary,
          onPressed: onPressed,
        ),
      ],
    );
    return PorcelainCard(
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 660
            ? Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 32),
                  const Expanded(child: AtelierShowcase(height: 300)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: 28),
                  const AtelierShowcase(height: 250),
                ],
              ),
      ),
    );
  }
}
