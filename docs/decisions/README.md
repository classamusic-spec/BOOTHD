# Architecture decision records

Owner-locked decisions live in `docs/DECISIONS_AND_RISKS.md` (ADR-001 to
ADR-011, ADR-CP-001, ADR-PD-01). The records here capture the engineering
decisions taken while executing milestones, plus owner change requests (CR).

| ID | Title | Status | Milestone |
| --- | --- | --- | --- |
| [ADR-0001](ADR-0001-flutter-cross-platform-baseline.md) | Flutter single codebase, toolchain pin and project identity | Accepted | M00 |
| [ADR-0002](ADR-0002-camera-service-boundary.md) | CameraService boundary over the `camera` plugin | Accepted (draft contract) | M00, revisited M01/M06 |
| [ADR-0003](ADR-0003-scene-graph-and-renderer.md) | Shared scene graph and offscreen export renderer | Accepted (direction) | M00, proved M01, built M04 |
| [ADR-0004](ADR-0004-adaptive-orientation.md) | Adaptive orientation on iPadOS 26+/27 and Android 16/17 | Accepted | M00 |
| [ADR-0005](ADR-0005-architecture-di-routing-data-ownership.md) | Layers, DI, routing and data ownership | Accepted | M00 |
| [ADR-0006](ADR-0006-test-and-ci-strategy.md) | Test layers, CI and evidence rules | Accepted | M00 |
| [ADR-0007](ADR-0007-m01-feasibility-findings.md) | M01 feasibility spike: findings, limits and refactor plan | Accepted | M01 |
| [CR-001](CR-001-premium-ux-quality-bar.md) | Premium UX quality bar: exceed the 15-screen board | Approved by owner 2026-10-17 | Binding from M02 |

Template: context, decision, consequences, verification, open questions.
Supersede a record by adding a new one; do not rewrite accepted history.
