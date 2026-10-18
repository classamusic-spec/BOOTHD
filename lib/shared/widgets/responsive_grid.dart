import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design_system/porcelain_metrics.dart';

/// Lays [children] out in as many equal columns as fit, each at least
/// [minTileWidth] wide (up to [maxColumns]). Tiles in a row share the
/// tallest tile's height, so cards line up in both orientations. With
/// [balanced], fewer columns are used when that fills every row (four
/// items as 2 × 2 rather than 3 + 1).
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.maxColumns = 4,
    this.spacing = PorcelainSpace.xl,
    this.balanced = false,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double spacing;
  final bool balanced;

  /// Number of columns that fit [width].
  static int columnsFor(
    double width, {
    required double minTileWidth,
    required int maxColumns,
    required double spacing,
  }) {
    final fit = ((width + spacing) / (minTileWidth + spacing)).floor();
    return math.max(1, math.min(maxColumns, fit));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = columnsFor(
          constraints.maxWidth,
          minTileWidth: minTileWidth,
          maxColumns: maxColumns,
          spacing: spacing,
        );
        if (balanced && children.length > columns) {
          for (var c = columns; c >= 2; c--) {
            if (children.length % c == 0) {
              columns = c;
              break;
            }
          }
        }
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          final cells = <Widget>[];
          for (var column = 0; column < columns; column++) {
            if (column > 0) cells.add(SizedBox(width: spacing));
            final index = start + column;
            cells.add(
              Expanded(
                child: index < children.length
                    ? children[index]
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cells,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
}
