# Architecture decision records

Owner-locked decisions live in `docs/DECISIONS_AND_RISKS.md` (ADR-001 to
ADR-011, ADR-CP-001, ADR-PD-01). The records here capture the engineering
decisions taken while executing milestones, plus owner change requests (CR).

| ID | Title | Status | Milestone |
| --- | --- | --- | --- |
| [ADR-0001](ADR-0001-flutter-cross-platform-baseline.md) | Flutter single codebase, toolchain pin and project identity | Accepted | M00 |
| [ADR-0002](ADR-0002-camera-service-boundary.md) | CameraService boundary over the `camera` plugin | Accepted (contract final in ADR-0012) | M00, revisited M01/M06 |
| [ADR-0003](ADR-0003-scene-graph-and-renderer.md) | Shared scene graph and offscreen export renderer | Accepted (direction; detail in ADR-0010) | M00, proved M01, built M04 |
| [ADR-0004](ADR-0004-adaptive-orientation.md) | Adaptive orientation on iPadOS 26+/27 and Android 16/17 | Accepted | M00 |
| [ADR-0005](ADR-0005-architecture-di-routing-data-ownership.md) | Layers, DI, routing and data ownership | Accepted | M00 |
| [ADR-0006](ADR-0006-test-and-ci-strategy.md) | Test layers, CI and evidence rules | Accepted | M00 |
| [ADR-0007](ADR-0007-m01-feasibility-findings.md) | M01 feasibility spike: findings, limits and refactor plan | Accepted | M01 |
| [ADR-0008](ADR-0008-porcelain-design-system.md) | Porcelain design system, theme profiles and adaptive Studio shell | Accepted (owner approved M02) | M02 |
| [ADR-0009](ADR-0009-offline-storage-operator-access-booth-mode.md) | Offline storage, operator access, Booth Mode isolation and launch checks | Accepted | M03 |
| [ADR-0010](ADR-0010-template-model-and-production-renderer.md) | Template document model, production renderer and template store | Accepted | M04 |
| [ADR-0011](ADR-0011-template-studio-editing.md) | Template Studio editing, drafts, library and display-scale decoding | Accepted | M05 |
| [ADR-0012](ADR-0012-production-camera-service.md) | Production camera service, permissions, originals and the camera test | Accepted | M06 |
| [ADR-0013](ADR-0013-guest-session-state-machine.md) | Guest sessions: state machine, durable checkpoints and guest screens | Accepted | M07 |
| [ADR-0014](ADR-0014-gallery-export-and-printer-boundary.md) | Operator gallery, export, deletion and the printer boundary | Accepted | M08 |
| [ADR-0015](ADR-0015-phone-delivery.md) | Optional phone delivery: MMS preview and private link | Accepted for implementation; live sending BLOCKED | M09 |
| [ADR-0016](ADR-0016-resilience-backup-kiosk.md) | Resilience, backup and restore, logs, permissions and kiosk readiness | Accepted; device questions BLOCKED | M10 |
| [CR-001](CR-001-premium-ux-quality-bar.md) | Premium UX quality bar: exceed the 15-screen board | Approved by owner 2026-10-17 | Binding from M02 |
| [CR-002](CR-002-reference-boards.md) | Match the owner's reference boards | Requested by owner 2026-10-18 | M05 onward |

Template: context, decision, consequences, verification, open questions.
Supersede a record by adding a new one; do not rewrite accepted history.
