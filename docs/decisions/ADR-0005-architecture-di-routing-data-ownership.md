# ADR-0005: Layers, DI, routing and data ownership

- Status: Accepted (M00, 2026-10-17)
- Related: ARCHITECTURE A-01..A-05, A-11; FLUTTER_PLATFORM_STRATEGY §2, §6

## Decision

### Layers and import rules (enforced)

| Layer | Path | May import (own code) | May import (packages) |
| --- | --- | --- | --- |
| Entry point | `lib/main.dart` | app | none |
| Composition root | `lib/app/` | everything | any |
| Domain | `lib/domain/` | domain | `meta`, `collection`; no `dart:ui`/`dart:io` |
| Core | `lib/core/` | core, domain | flutter, flutter_riverpod, go_router, meta, collection |
| Shared widgets | `lib/shared/` | shared, core, domain | as core |
| Features | `lib/features/<name>/` | own feature, shared, core, domain | as core |
| Infrastructure | `lib/infrastructure/` | infrastructure, core, domain | any (plugins live here) |

- Features never import infrastructure, the app layer or another feature.
- `dart:io`, `dart:ffi` and `dart:isolate` are for infrastructure and app only.
- `test/architecture/layer_boundaries_test.dart` checks every file in `lib/`
  and unit-tests the rules with deliberate violations. Widening a package
  allow-list is an architecture change that needs an ADR.
- Directories are created when they get real code; the target map is
  ARCHITECTURE A-03.

### Dependency injection (Riverpod 3)

- `ProviderScope` at the root (`lib/app/bootstrap.dart`). Its `overrides`
  are the composition root: domain interfaces are bound to infrastructure
  adapters there, and tests bind fakes the same way.
- Providers are declared next to the type they expose. Providers for domain
  service interfaces are declared in `lib/core` as "must be overridden"
  (throwing) and bound in `bootstrap`, so features depend on interfaces only.
  None exist yet; the first arrives with the M01 camera adapter.
- Note: `flutter_riverpod` 3 depends on `flutter_test` (for its widget-test
  helpers), so test packages appear in the runtime dependency graph; the
  licence report treats them as shipped (conservative).

### Routing (GoRouter 18)

- One router built in `lib/app/router.dart`; route paths in
  `lib/core/routing/route_paths.dart` so features can navigate without
  importing the app layer.
- Unknown locations render a detail-free fallback (no route or exception
  text). M02/M03 add the Studio subtree, the isolated guest subtree and
  operator guards (UX-04); from then on the fallback must keep guests inside
  the guest subtree.

### Data ownership (single writer per record)

| Data | Owner (writer) | Store | Arrives |
| --- | --- | --- | --- |
| Booth profile, events, event-template links, settings | EventRepository | Drift/SQLite | M03 |
| Operator PIN verifier | OperatorAuthService | platform secure storage | M03 |
| Templates and immutable revisions | TemplateRepository | Drift + managed JSON manifests | M04 |
| Imported assets (PNG, fonts) | AssetRepository | managed files + hash index | M04 |
| Sessions, captured originals, slot bindings | SessionRepository / BoothSessionCoordinator | Drift + managed files | M06/M07 |
| Rendered outputs | ExportService / OutputCoordinator | managed files + Drift record | M04/M07 |
| Pending file operations | FileTransactionService journal | Drift | M07/M10 |
| Phone delivery intents (optional) | DeliveryService | Drift (encrypted phone) | M09 |

- Files are referenced by paths relative to managed app directories, never
  absolute or picker URIs. Originals are immutable.
- Drift 2.35.2 resolves against this toolchain (dry run 2026-10-17); it is
  added in M03, not before.
- No network dependency for capture, editing, events, rendering, gallery or
  export. The optional M09 delivery client is the only network code.
