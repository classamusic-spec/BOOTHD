// The OpenAPI contract (backend/openapi/delivery-v1.yaml) and the service
// agree: every route is documented and every documented operation exists.

import { assertEquals } from './helpers/assert.ts';
import { parse } from './helpers/yaml.ts';
import { routeTable } from '../supabase/functions/_shared/app.ts';

Deno.test('every route is in the OpenAPI contract and nothing else is', async () => {
  const contract = parse(
    await Deno.readTextFile(new URL('../openapi/delivery-v1.yaml', import.meta.url)),
  ) as { paths: Record<string, Record<string, unknown>> };
  const documented = Object.entries(contract.paths).flatMap(([path, operations]) =>
    Object.keys(operations).map((method) => `${method.toUpperCase()} ${path}`)
  ).sort();
  const served = routeTable()
    .filter(([, path]) => path !== '/healthz' && path !== '/robots.txt')
    .map(([method, path]) => `${method} ${path}`)
    .sort();
  assertEquals(served, documented);
});
