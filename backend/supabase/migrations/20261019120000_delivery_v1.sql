-- Porcelain Photo Booth phone delivery, schema v1 (M09, ADR-0015).
--
-- Only the delivery backend reads or writes these tables, through its
-- service connection. Row-level security is enabled on every table with no
-- policies, so the public `anon` and `authenticated` roles can reach
-- nothing; booths never talk to the database directly.
--
-- Phone numbers are stored only as AES-GCM ciphertext (key in the
-- backend's secret store) plus a keyed HMAC digest for suppression and
-- throttles and the last four digits for operators. Bearer tokens (booth
-- credentials, access tokens, pairing codes, upload, download and preview
-- grants) are stored only as SHA-256 hashes.

-- An operator business: its sender identity, limits and the attestations
-- that gate live sending (PD-07).
create table tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 1 and 80),
  -- The sender identity at the start of every text (PD-02).
  brand_name text not null check (length(btrim(brand_name)) between 1 and 40),
  privacy_url text not null check (privacy_url ~ '^https://[^ ]+$'),
  terms_url text not null check (terms_url ~ '^https://[^ ]+$'),
  support_contact text not null check (length(support_contact) between 3 and 120),
  -- The operator's switch, off until set; sends also need both
  -- attestations below and a configured sender.
  sending_enabled boolean not null default false,
  -- Recorded by an administrator from evidence (PD-07); never inferred.
  registration_attested_at timestamptz,
  registration_reference text check (registration_reference is null
    or length(registration_reference) between 3 and 120),
  legal_review_attested_at timestamptz,
  daily_send_limit integer not null default 200
    check (daily_send_limit between 0 and 100000),
  -- The most any one event may send; events may set less.
  event_send_limit integer not null default 500
    check (event_send_limit between 0 and 100000),
  -- Estimated spend ceiling per calendar month (UTC), in US cents, and the
  -- estimate per text it is counted with (PD-08: estimates, not bills).
  monthly_budget_cents integer not null default 2000
    check (monthly_budget_cents between 0 and 10000000),
  estimated_cost_millicents integer not null default 3200
    check (estimated_cost_millicents between 1 and 100000),
  link_days_default integer not null default 7,
  link_days_max integer not null default 14 check (link_days_max between 1 and 30),
  -- The largest preview accepted, below the provider's 5 MB ceiling.
  preview_max_bytes integer not null default 600000
    check (preview_max_bytes between 50000 and 4999999),
  created_at timestamptz not null default now(),
  check (link_days_default between 1 and link_days_max)
);

-- Single-use codes an administrator issues to pair a booth.
create table pairing_codes (
  code_hash text primary key check (code_hash ~ '^[0-9a-f]{64}$'),
  tenant_id uuid not null references tenants (id) on delete cascade,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create table registered_booths (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants (id) on delete restrict,
  name text not null check (length(btrim(name)) between 1 and 40),
  credential_hash text not null unique check (credential_hash ~ '^[0-9a-f]{64}$'),
  -- The credential before the last rotation, accepted briefly so a lost
  -- rotation response does not strand the booth.
  previous_credential_hash text check (previous_credential_hash is null
    or previous_credential_hash ~ '^[0-9a-f]{64}$'),
  previous_valid_until timestamptz,
  revoked_at timestamptz,
  daily_send_limit integer not null default 150
    check (daily_send_limit between 0 and 100000),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz
);

-- Short-lived access tokens exchanged for a booth's credential.
create table booth_access_tokens (
  token_hash text primary key check (token_hash ~ '^[0-9a-f]{64}$'),
  booth_id uuid not null references registered_booths (id) on delete cascade,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create index booth_access_tokens_by_expiry on booth_access_tokens (expires_at);

-- Staging only sends to these recipients (PD-09: approved test numbers).
create table approved_test_recipients (
  tenant_id uuid not null references tenants (id) on delete cascade,
  recipient_digest text not null check (recipient_digest ~ '^[0-9a-f]{64}$'),
  label text not null check (length(btrim(label)) between 1 and 40),
  created_at timestamptz not null default now(),
  primary key (tenant_id, recipient_digest)
);

create type delivery_state as enum (
  'created',            -- intent and consent accepted, waiting for images
  'uploading',          -- upload grants issued
  'dispatch_pending',   -- images verified; ready for the dispatcher
  'dispatching',        -- claimed by the dispatcher (leased)
  'provider_accepted',  -- the provider accepted the message (not sent)
  'provider_sent',      -- the provider reports it sent (not delivered)
  'delivered',          -- the provider reports it delivered (not read)
  'failed_retryable',   -- a safe retry is scheduled
  'failed_permanent',   -- will not be sent
  'delivery_unknown',   -- submission outcome unknown: reconcile, then review
  'expired',            -- not sent within the queue window
  'canceled'            -- canceled before submission
);

create table delivery_jobs (
  id uuid primary key default gen_random_uuid(),
  booth_id uuid not null references registered_booths (id) on delete restrict,
  tenant_id uuid not null references tenants (id) on delete restrict,
  event_id text not null check (event_id ~ '^[0-9a-f-]{36}$'),
  event_name text not null check (length(btrim(event_name)) between 1 and 80),
  event_send_limit integer not null check (event_send_limit between 1 and 100000),
  session_id text not null check (session_id ~ '^[0-9a-f-]{36}$'),
  output_id text not null check (output_id ~ '^[0-9a-f-]{36}$'),
  idempotency_key text not null check (idempotency_key ~ '^[0-9A-Za-z-]{16,64}$'),
  -- SHA-256 of the request's content, so a reused idempotency key with
  -- different content is refused rather than answered with another job.
  request_digest text not null check (request_digest ~ '^[0-9a-f]{64}$'),
  -- AES-GCM ciphertext of the E.164 number; null once erased.
  recipient_ciphertext text,
  recipient_digest text not null check (recipient_digest ~ '^[0-9a-f]{64}$'),
  recipient_last4 text not null check (recipient_last4 ~ '^[0-9]{4}$'),
  link_days integer not null check (link_days between 1 and 30),
  state delivery_state not null default 'created',
  -- What the booth declared at upload-init; verified on upload.
  final_format text check (final_format is null or final_format in ('jpeg', 'png')),
  final_sha256 text check (final_sha256 is null or final_sha256 ~ '^[0-9a-f]{64}$'),
  final_bytes integer check (final_bytes is null or final_bytes between 1 and 26214400),
  final_width integer check (final_width is null or final_width between 1 and 20000),
  final_height integer check (final_height is null or final_height between 1 and 20000),
  final_key text check (final_key is null or final_key ~ '^final/[0-9a-f-]{36}\.(jpg|png)$'),
  preview_sha256 text check (preview_sha256 is null or preview_sha256 ~ '^[0-9a-f]{64}$'),
  preview_bytes integer check (preview_bytes is null or preview_bytes between 1 and 4999999),
  preview_width integer check (preview_width is null or preview_width between 1 and 4096),
  preview_height integer check (preview_height is null or preview_height between 1 and 4096),
  preview_key text check (preview_key is null or preview_key ~ '^preview/[0-9a-f-]{36}\.jpg$'),
  provider_message_sid text unique check (provider_message_sid is null
    or provider_message_sid ~ '^[A-Z]{2}[0-9a-f]{32}$'),
  attempts integer not null default 0 check (attempts between 0 and 20),
  next_attempt_at timestamptz,
  lease_until timestamptz,
  -- When the current submission attempt began (reconciliation window).
  submit_started_at timestamptz,
  reconcile_after timestamptz,
  review_reason text check (review_reason is null or review_reason ~ '^[A-Z0-9_]{3,64}$'),
  failure_code text check (failure_code is null or failure_code ~ '^[A-Z0-9_]{3,64}$'),
  -- Not submitted by then: expired and its number erased (PD-01: 24 h
  -- after consent).
  expires_at timestamptz not null,
  dispatched_at timestamptz,
  link_expires_at timestamptz,
  link_revoked_at timestamptz,
  purged_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (booth_id, idempotency_key),
  check ((state in ('dispatching', 'provider_accepted', 'provider_sent', 'delivered'))
    <= (final_key is not null and preview_key is not null)),
  check ((state in ('provider_accepted', 'provider_sent', 'delivered'))
    <= (provider_message_sid is not null))
);

create index delivery_jobs_ready on delivery_jobs (state, next_attempt_at);
create index delivery_jobs_by_recipient on delivery_jobs (recipient_digest, created_at);
create index delivery_jobs_by_booth on delivery_jobs (booth_id, created_at);
create index delivery_jobs_by_event on delivery_jobs (tenant_id, event_id, created_at);
create index delivery_jobs_by_tenant on delivery_jobs (tenant_id, created_at);
create index delivery_jobs_to_purge on delivery_jobs (link_expires_at) where purged_at is null;

-- The guest's consent, exactly as accepted (PD-06). Immutable.
create table consent_receipts (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null unique references delivery_jobs (id) on delete cascade,
  booth_id uuid not null,
  event_id text not null,
  session_id text not null,
  recipient_digest text not null check (recipient_digest ~ '^[0-9a-f]{64}$'),
  accepted boolean not null check (accepted),
  text_version text not null check (text_version ~ '^[0-9A-Za-z._-]{1,32}$'),
  -- SHA-256 of the consent text the guest saw.
  text_digest text not null check (text_digest ~ '^[0-9a-f]{64}$'),
  accepted_at timestamptz not null,
  locale text not null check (locale ~ '^[a-z]{2}(-[A-Z]{2})?$'),
  source_screen text not null check (source_screen ~ '^S[0-9]{2}$'),
  received_at timestamptz not null default now()
);

create function consent_receipts_are_immutable() returns trigger
language plpgsql as $$
begin
  raise exception 'consent receipts are immutable';
end $$;

create trigger consent_receipts_are_immutable
  before update on consent_receipts
  for each row execute function consent_receipts_are_immutable();

-- Single-use upload grants: one for the finished photo, one for the
-- preview, never anything else (PD-05 upload-init).
create table upload_grants (
  token_hash text primary key check (token_hash ~ '^[0-9a-f]{64}$'),
  job_id uuid not null references delivery_jobs (id) on delete cascade,
  kind text not null check (kind in ('final', 'preview')),
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create index upload_grants_by_job on upload_grants (job_id, kind);

-- Bearer grants: the guest's download link and the provider's preview
-- fetch link. Only the hash of each token is stored (PD-04).
create table access_grants (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references delivery_jobs (id) on delete cascade,
  kind text not null check (kind in ('download', 'preview')),
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  access_count integer not null default 0 check (access_count >= 0),
  max_access integer check (max_access is null or max_access between 1 and 10000),
  created_at timestamptz not null default now()
);

create index access_grants_by_job on access_grants (job_id, kind);

-- Opt-outs (STOP) and manual blocks; kept as keyed digests only, beyond
-- photo retention (PD-06).
create table suppression_entries (
  recipient_digest text not null check (recipient_digest ~ '^[0-9a-f]{64}$'),
  scope text not null default 'tenant' check (scope ~ '^[a-z0-9:-]{1,80}$'),
  reason text not null check (reason in ('stop', 'manual', 'carrier')),
  created_at timestamptz not null default now(),
  primary key (recipient_digest, scope)
);

-- Provider status reports, idempotent per message and status (PD-05).
create table provider_events (
  id bigserial primary key,
  message_sid text not null check (message_sid ~ '^[A-Z]{2}[0-9a-f]{32}$'),
  status text not null check (status ~ '^[a-z_]{2,32}$'),
  error_code text check (error_code is null or error_code ~ '^[0-9]{1,6}$'),
  received_at timestamptz not null default now(),
  unique (message_sid, status)
);

-- Every state a job entered, with its time and code (UX-PD6 history).
create table delivery_history (
  id bigserial primary key,
  job_id uuid not null references delivery_jobs (id) on delete cascade,
  state delivery_state not null,
  code text check (code is null or code ~ '^[A-Z0-9_]{3,64}$'),
  at timestamptz not null default now()
);

create index delivery_history_by_job on delivery_history (job_id, id);

create table deletion_audit (
  id bigserial primary key,
  job_id uuid,
  reason text not null check (reason in ('expired', 'revoked', 'canceled',
    'retention', 'failed', 'operator')),
  objects_deleted integer not null default 0 check (objects_deleted >= 0),
  provider_media text not null check (provider_media in
    ('none', 'deleted', 'not_supported', 'failed')),
  created_at timestamptz not null default now()
);

-- Fixed-window counters for rate limits.
create table rate_counters (
  key text not null check (length(key) between 1 and 200),
  window_start timestamptz not null,
  count integer not null default 0,
  primary key (key, window_start)
);

-- When background work last ran, for booth diagnostics (UX-PD6).
create table service_health (
  key text primary key check (key ~ '^[a-z_.]{1,40}$'),
  at timestamptz not null,
  detail text check (detail is null or length(detail) <= 200)
);

-- Deny by default: no policies, so only the service connection (which
-- bypasses row-level security) can use any of this.
alter table tenants enable row level security;
alter table pairing_codes enable row level security;
alter table registered_booths enable row level security;
alter table booth_access_tokens enable row level security;
alter table approved_test_recipients enable row level security;
alter table delivery_jobs enable row level security;
alter table consent_receipts enable row level security;
alter table upload_grants enable row level security;
alter table access_grants enable row level security;
alter table suppression_entries enable row level security;
alter table provider_events enable row level security;
alter table delivery_history enable row level security;
alter table deletion_audit enable row level security;
alter table rate_counters enable row level security;
alter table service_health enable row level security;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'revoke all on all tables in schema public from anon';
    execute 'revoke all on all sequences in schema public from anon';
    execute 'revoke all on all functions in schema public from anon';
  end if;
  if exists (select 1 from pg_roles where rolname = 'authenticated') then
    execute 'revoke all on all tables in schema public from authenticated';
    execute 'revoke all on all sequences in schema public from authenticated';
    execute 'revoke all on all functions in schema public from authenticated';
  end if;
  -- Supabase only: the two private buckets (no public access, no
  -- policies; the backend uses its service key).
  if exists (select 1 from information_schema.schemata where schema_name = 'storage') then
    execute $sql$insert into storage.buckets (id, name, public, file_size_limit,
      allowed_mime_types) values
      ('delivery-final', 'delivery-final', false, 26214400, array['image/jpeg', 'image/png']),
      ('delivery-preview', 'delivery-preview', false, 4999999, array['image/jpeg'])
      on conflict (id) do nothing$sql$;
  end if;
end $$;
