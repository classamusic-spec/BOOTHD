// Recipient numbers (PD-01, AC-0903): parsed to E.164, and only regions
// the service is certified for are accepted. Release 1: US mobile numbers
// (NANP country code 1 with a US area code shape). Other regions are
// parsed structurally and refused as unsupported, never sent.

export type PhoneProblem =
  | 'PHONE_INVALID'
  | 'PHONE_REGION_UNSUPPORTED';

export type ParsedPhone =
  | { ok: true; e164: string; region: 'US'; last4: string }
  | { ok: false; problem: PhoneProblem };

/** Area codes that are not geographic subscriber numbers. */
const notSubscriber = new Set(['555', '900', '976']);

/**
 * NANP area codes outside the 50 states and DC: Canada, the Caribbean and
 * US territories. They share country code 1 but are not certified in
 * release 1 (other carriers, rules and prices), so they are refused as
 * unsupported. Keep in step with `lib/domain/delivery/phone_number.dart`;
 * both are checked against `backend/test/fixtures/phone_cases.json`.
 */
export const nonUsNanpAreaCodes = new Set([
  // Canada
  '204',
  '226',
  '236',
  '249',
  '250',
  '257',
  '263',
  '289',
  '306',
  '343',
  '354',
  '365',
  '367',
  '368',
  '382',
  '387',
  '403',
  '416',
  '418',
  '428',
  '431',
  '437',
  '438',
  '450',
  '460',
  '468',
  '474',
  '506',
  '514',
  '519',
  '548',
  '579',
  '581',
  '584',
  '587',
  '604',
  '613',
  '639',
  '647',
  '672',
  '683',
  '705',
  '709',
  '742',
  '753',
  '778',
  '780',
  '782',
  '807',
  '819',
  '825',
  '867',
  '873',
  '879',
  '902',
  '905',
  '942',
  // Caribbean and Atlantic
  '242',
  '246',
  '264',
  '268',
  '284',
  '345',
  '441',
  '473',
  '649',
  '658',
  '664',
  '721',
  '758',
  '767',
  '784',
  '809',
  '829',
  '849',
  '868',
  '869',
  '876',
  // US territories (not certified in release 1)
  '340',
  '670',
  '671',
  '684',
  '787',
  '939',
]);

/**
 * Parses `input` (an E.164 string such as `+15550123456`, or digits with
 * punctuation) for `region`. Accepts only NANP numbers: 10 digits after
 * the `1`, area code and exchange starting 2-9, no N11 codes.
 */
export function parsePhone(input: string, region: 'US' = 'US'): ParsedPhone {
  const trimmed = input.trim();
  if (!/^\+?[0-9 ()./-]{7,24}$/.test(trimmed)) {
    return { ok: false, problem: 'PHONE_INVALID' };
  }
  let digits = trimmed.replace(/[^0-9]/g, '');
  if (trimmed.startsWith('+')) {
    if (!digits.startsWith('1')) {
      return { ok: false, problem: 'PHONE_REGION_UNSUPPORTED' };
    }
    digits = digits.slice(1);
  } else if (digits.length === 11 && digits.startsWith('1')) {
    digits = digits.slice(1);
  }
  if (digits.length !== 10) return { ok: false, problem: 'PHONE_INVALID' };
  const area = digits.slice(0, 3);
  const exchange = digits.slice(3, 6);
  const nxx = /^[2-9][0-9]{2}$/;
  const n11 = /^[2-9]11$/;
  if (!nxx.test(area) || !nxx.test(exchange) || n11.test(area) || n11.test(exchange)) {
    return { ok: false, problem: 'PHONE_INVALID' };
  }
  if (notSubscriber.has(area)) return { ok: false, problem: 'PHONE_INVALID' };
  if (region !== 'US' || nonUsNanpAreaCodes.has(area)) {
    return { ok: false, problem: 'PHONE_REGION_UNSUPPORTED' };
  }
  return { ok: true, e164: `+1${digits}`, region: 'US', last4: digits.slice(6) };
}

/** `•••-•••-1234`: the only form logs and operator views ever show. */
export function maskPhone(last4: string): string {
  return `•••-•••-${last4}`;
}
