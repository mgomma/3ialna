---
mode: agent
description: Debug a bug safely in a Flutter + Android method-channel app.
---
Debug and fix the reported issue with minimal side effects.

Checklist:
1. Reproduce with clear assumptions.
2. Identify root cause (not only symptom).
3. Apply the smallest safe patch.
4. If issue touches platform communication, verify Dart and Kotlin contract consistency.
5. Ensure no regressions in PIN protection, blocking, scheduling, and overlays.
6. Run validation commands and summarize outcomes.

Output format:
- Root cause
- Files changed
- Why the fix is safe
- Remaining risks and recommended follow-up tests
