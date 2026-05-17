---
mode: agent
description: Implement a feature with project-safe architecture and validation.
---
Implement the requested feature in this repository using existing architecture.

Requirements:
1. Keep architecture boundaries intact (`presentation`, `data/local`, `data/system`, `domain/models`).
2. Reuse existing services/models where possible.
3. If method-channel contracts change, update both Dart and Kotlin in the same task.
4. Keep parent security and app-blocking behavior safe.
5. Add only minimal, clear comments where logic is non-obvious.
6. Run and report validation (`flutter analyze`, `flutter test`, plus any targeted checks).

Deliverables:
- Summary of changed files and why
- Risk notes for edge cases
- Follow-up suggestions for tests/manual QA
