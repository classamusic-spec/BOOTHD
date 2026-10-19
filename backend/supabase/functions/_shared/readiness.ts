// Whether a tenant may send at all (AC-0901, AC-0911): every gate must be
// open, and none of them opens by itself. The provider must be configured,
// an administrator must have recorded the sender registration and the
// legal review from evidence, and the operator's switch must be on.

import type { TenantRow } from './auth.ts';
import type { Deps } from './context.ts';

export type ReadinessReason =
  | 'PROVIDER_NOT_CONFIGURED'
  | 'REGISTRATION_NOT_ATTESTED'
  | 'LEGAL_REVIEW_NOT_ATTESTED'
  | 'SENDING_DISABLED'
  | 'PUBLIC_URL_NOT_HTTPS';

export interface Readiness {
  ready: boolean;
  reasons: ReadinessReason[];
}

export function sendingReadiness(deps: Deps, tenant: TenantRow): Readiness {
  const reasons: ReadinessReason[] = [];
  if (!deps.config.twilio) reasons.push('PROVIDER_NOT_CONFIGURED');
  if (!tenant.registration_attested_at) reasons.push('REGISTRATION_NOT_ATTESTED');
  if (!tenant.legal_review_attested_at) reasons.push('LEGAL_REVIEW_NOT_ATTESTED');
  if (!tenant.sending_enabled) reasons.push('SENDING_DISABLED');
  if (deps.config.environment !== 'test' && !deps.config.publicBaseUrl.startsWith('https://')) {
    reasons.push('PUBLIC_URL_NOT_HTTPS');
  }
  return { ready: reasons.length === 0, reasons };
}
