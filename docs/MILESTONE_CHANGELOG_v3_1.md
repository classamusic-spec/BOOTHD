# Milestone renumbering from v3.0 → v3.1
**Rationale:** User confirmed cross-platform Flutter from inception. New M01 high-risk cross-platform spike inserted before UI design. Old M01–M10 shift by +1; existing AC IDs shift accordingly, keeping their suffix.

| v3.0 | v3.1 |
|---|---|
| M00 Baseline | M00 Baseline (strengthened dual-build gate) |
| — | **M01 iPad+Android renderer and actual-camera feasibility** |
| M01 Design | M02 Design |
| M02 Events | M03 Events |
| M03 Renderer | M04 Renderer |
| M04 Editor | M05 Editor |
| M05 Camera | M06 Camera |
| M06 Guest | M07 Guest |
| M07 Gallery | M08 Gallery |
| M08 Resilience | M09 Resilience |
| M09 Certification | M10 Certification |
| M10 Release | M11 Release |

Example: former AC-0303 (PNG overlay) is now AC-0403; early spike overlay verification is AC-0102. All historical acceptance tests remain required.

**Compatibility notice:** This package supersedes v3.0. Do not run old M01 prompts or mix old/new acceptance IDs in `docs/ACCEPTANCE_EVIDENCE.md`.
