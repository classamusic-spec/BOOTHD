// Third-party code the delivery backend uses, pinned (deno.lock records
// their integrity). Nothing else is imported from outside this repository.

// Postgres client (Unlicense); runs in Supabase Edge Functions and Deno.
export { default as postgres } from 'npm:postgres@3.4.9';
export type { Sql, TransactionSql } from 'npm:postgres@3.4.9';

// Twilio's official helper library (MIT), its webhook signature module
// only (PD-05: "verify provider signature using official SDK"). It needs
// nothing but Node's built-in crypto, url and querystring modules.
export {
  getExpectedTwilioSignature,
  validateRequest,
} from 'npm:twilio@6.2.0/lib/webhooks/webhooks.js';
