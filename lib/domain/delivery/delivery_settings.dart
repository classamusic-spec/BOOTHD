import 'package:meta/meta.dart';

/// An event's phone-delivery settings (UX-PD5, AC-0901). Off by default:
/// texting appears for guests only when the operator turns it on here,
/// the booth is paired, and the service reports that sending is ready.
@immutable
final class EventDeliverySettings {
  const EventDeliverySettings({
    this.enabled = false,
    this.offlineQueue = true,
    this.linkDays = defaultLinkDays,
    this.sendLimit = defaultSendLimit,
  });

  static const defaultLinkDays = 7;
  static const defaultSendLimit = 200;
  static const maxLinkDays = 30;
  static const maxSendLimit = 10000;

  /// Offer "Text my photos" to guests.
  final bool enabled;

  /// Accept a request while the booth is offline and try for up to 24
  /// hours (guests are told the text may come later).
  final bool offlineQueue;

  /// How long the guest's download link works (the service's maximum
  /// applies).
  final int linkDays;

  /// The most texts this event may send.
  final int sendLimit;

  bool get valid =>
      linkDays >= 1 &&
      linkDays <= maxLinkDays &&
      sendLimit >= 1 &&
      sendLimit <= maxSendLimit;

  EventDeliverySettings copyWith({
    bool? enabled,
    bool? offlineQueue,
    int? linkDays,
    int? sendLimit,
  }) => EventDeliverySettings(
    enabled: enabled ?? this.enabled,
    offlineQueue: offlineQueue ?? this.offlineQueue,
    linkDays: linkDays ?? this.linkDays,
    sendLimit: sendLimit ?? this.sendLimit,
  );

  @override
  bool operator ==(Object other) =>
      other is EventDeliverySettings &&
      other.enabled == enabled &&
      other.offlineQueue == offlineQueue &&
      other.linkDays == linkDays &&
      other.sendLimit == sendLimit;

  @override
  int get hashCode => Object.hash(enabled, offlineQueue, linkDays, sendLimit);
}
