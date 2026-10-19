// Delivery job states and provider statuses (PD-05, AC-0913, AC-0915).
//
// A provider report only ever moves a job forward: callbacks arrive out of
// order and repeat, and an older status must never undo a newer one.
// `delivered` is reported only when the provider says so; `accepted`,
// `queued` and `sent` never mean the guest received anything.

export type DeliveryState =
  | 'created'
  | 'uploading'
  | 'dispatch_pending'
  | 'dispatching'
  | 'provider_accepted'
  | 'provider_sent'
  | 'delivered'
  | 'failed_retryable'
  | 'failed_permanent'
  | 'delivery_unknown'
  | 'expired'
  | 'canceled';

/** States after which nothing changes the job again. */
export const finalStates: ReadonlySet<DeliveryState> = new Set([
  'delivered',
  'failed_permanent',
  'expired',
  'canceled',
]);

/** Twilio message statuses (Programmable Messaging). */
export type ProviderStatus =
  | 'accepted'
  | 'scheduled'
  | 'queued'
  | 'sending'
  | 'sent'
  | 'delivered'
  | 'undelivered'
  | 'failed'
  | 'canceled'
  | 'read'
  | 'receiving'
  | 'received';

/** How far along each state is, for monotonic updates. */
const rank: Record<DeliveryState, number> = {
  created: 0,
  uploading: 1,
  dispatch_pending: 2,
  failed_retryable: 2,
  dispatching: 3,
  delivery_unknown: 4,
  provider_accepted: 5,
  provider_sent: 6,
  delivered: 7,
  failed_permanent: 7,
  expired: 7,
  canceled: 7,
};

/**
 * The job state a provider status means, or null for statuses that say
 * nothing new (`read` belongs to other channels; inbound statuses are not
 * about our message).
 */
export function stateForProviderStatus(status: string): DeliveryState | null {
  switch (status) {
    case 'accepted':
    case 'scheduled':
    case 'queued':
      return 'provider_accepted';
    case 'sending':
    case 'sent':
      return 'provider_sent';
    case 'delivered':
      return 'delivered';
    case 'undelivered':
    case 'failed':
    case 'canceled':
      return 'failed_permanent';
    default:
      return null;
  }
}

/**
 * Whether a job in `current` may move to `next` because of a provider
 * report: forward only, never out of a final state, and a job in
 * `delivery_unknown` is resolved by any report for its message.
 */
export function providerMayMove(current: DeliveryState, next: DeliveryState): boolean {
  if (finalStates.has(current)) return false;
  return rank[next] > rank[current];
}

/** What the booth and operators are told about a job (UX-PD3, UX-PD6). */
export type PublicStatus =
  | 'queued'
  | 'uploading'
  | 'submitting'
  | 'submitted'
  | 'sent'
  | 'delivered'
  | 'failed'
  | 'unknown'
  | 'expired'
  | 'canceled';

export function publicStatus(state: DeliveryState): PublicStatus {
  switch (state) {
    case 'created':
      return 'queued';
    case 'uploading':
      return 'uploading';
    case 'dispatch_pending':
    case 'dispatching':
    case 'failed_retryable':
      return 'submitting';
    case 'provider_accepted':
      return 'submitted';
    case 'provider_sent':
      return 'sent';
    case 'delivered':
      return 'delivered';
    case 'failed_permanent':
      return 'failed';
    case 'delivery_unknown':
      return 'unknown';
    case 'expired':
      return 'expired';
    case 'canceled':
      return 'canceled';
  }
}
