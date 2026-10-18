import 'package:meta/meta.dart';

import '../value_objects/orientation.dart';

/// What events need to know about an immutable template revision (A-05,
/// A-15): its identity, page size and number of photo slots. The full
/// document arrives with the production template model (M04).
@immutable
final class TemplateRevisionSummary {
  const TemplateRevisionSummary({
    required this.revisionId,
    required this.templateId,
    required this.templateName,
    required this.revisionNumber,
    required this.pageWidthPx,
    required this.pageHeightPx,
    required this.photoSlotCount,
    this.templateArchived = false,
  });

  final String revisionId;
  final String templateId;
  final String templateName;
  final int revisionNumber;

  /// Output page size at the template's print resolution, e.g. 1200x1800
  /// for 4x6 inch portrait at 300 DPI.
  final int pageWidthPx;
  final int pageHeightPx;
  final int photoSlotCount;

  /// The template was archived in the library; the revision still exists.
  final bool templateArchived;

  PageOrientation get pageOrientation =>
      PageOrientation.fromPixelSize(width: pageWidthPx, height: pageHeightPx);

  @override
  bool operator ==(Object other) =>
      other is TemplateRevisionSummary &&
      other.revisionId == revisionId &&
      other.templateId == templateId &&
      other.templateName == templateName &&
      other.revisionNumber == revisionNumber &&
      other.pageWidthPx == pageWidthPx &&
      other.pageHeightPx == pageHeightPx &&
      other.photoSlotCount == photoSlotCount &&
      other.templateArchived == templateArchived;

  @override
  int get hashCode => Object.hash(revisionId, templateArchived);
}
