// A fresh Postgres database per test, with the delivery migration applied
// exactly as deployed. The server comes from DELIVERY_TEST_DATABASE_URL
// (tool/test.sh starts a throwaway cluster and sets it).

import { postgres, type Sql } from '../../supabase/functions/_shared/deps.ts';

const adminUrl = Deno.env.get('DELIVERY_TEST_DATABASE_URL') ??
  'postgres://postgres@127.0.0.1:54329/postgres';

const migrationsDir = new URL('../../supabase/migrations/', import.meta.url);

export interface TestDatabase {
  url: string;
  sql: Sql;
  drop(): Promise<void>;
}

export async function migrationSql(): Promise<string> {
  const names: string[] = [];
  for await (const entry of Deno.readDir(migrationsDir)) {
    if (entry.name.endsWith('.sql')) names.push(entry.name);
  }
  names.sort();
  const parts = await Promise.all(
    names.map((name) => Deno.readTextFile(new URL(name, migrationsDir))),
  );
  return parts.join('\n');
}

export async function freshDatabase(): Promise<TestDatabase> {
  const admin = postgres(adminUrl, { max: 1, onnotice: () => {} });
  const name = `delivery_test_${crypto.randomUUID().replaceAll('-', '').slice(0, 16)}`;
  try {
    // Supabase's public roles, with Supabase's default grants, so the
    // migration's revocations are exercised as they would be there.
    await admin.unsafe(`do $$ begin
      if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
      if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
      exception when duplicate_object then null; end $$`);
    await admin.unsafe(`create database ${name}`);
  } finally {
    await admin.end();
  }
  const url = adminUrl.replace(/\/[^/]*$/, `/${name}`);
  const sql = postgres(url, { max: 4, onnotice: () => {} });
  await sql.unsafe(`alter default privileges in schema public
    grant all on tables to anon, authenticated;
    alter default privileges in schema public grant all on sequences to anon, authenticated;
    grant usage on schema public to anon, authenticated;`);
  await sql.unsafe(await migrationSql());
  return {
    url,
    sql,
    async drop() {
      await sql.end();
      const cleanup = postgres(adminUrl, { max: 1, onnotice: () => {} });
      try {
        await cleanup.unsafe(`drop database if exists ${name} with (force)`);
      } finally {
        await cleanup.end();
      }
    },
  };
}
