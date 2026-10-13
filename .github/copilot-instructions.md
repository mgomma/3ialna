<!-- TOKENSHIELD:START -->
<!-- TokenShield: AI Token & Cost Optimizer (v1.0.0). Managed block - do not edit manually. -->

# TokenShield Optimization Directives

## Active Optimizations

### Code Search & Navigation (CodeGraph)
- **MANDATORY**: When locating symbols, callers, or implementations, ALWAYS query CodeGraph (`codegraph_explore` or `codegraph`) before grepping.
- **FORBIDDEN**: NEVER perform brute-force directory grep searches when CodeGraph semantic indexing is available.

### CLI Output Compression (RTK)
- **MANDATORY**: When proposing or running terminal commands for `git`, `test`, `build`, `ls`, or `grep`, ALWAYS prefix them with `rtk` (e.g. `rtk git status`, `rtk git diff`, `rtk test`, `rtk ls`).
- **FORBIDDEN**: NEVER execute or propose raw `git` commands (`git status`, `git diff`, `git log`) directly in terminal. Always route through `rtk git <cmd>` to compress token output by 60-90%.
- Report only test failure details and status summaries rather than full stdout logs.

### Concise Direct Responses (full mode)
- **MANDATORY**: Answer code-first and immediately. Provide dense, direct solutions targeting ~35% response token reduction.
- **FORBIDDEN**: NEVER output conversational preambles ("Sure!", "I can help with that", "Great question", "Certainly!"), recap summaries, or conversational sign-offs.

### Context Compaction & Session Hygiene
- **MANDATORY**: Reuse previously loaded symbols from working memory. Keep state summaries minimal when switching tasks.
- **FORBIDDEN**: NEVER re-read or re-fetch files already inspected in the active turn or session.

### Local Semantic Cache (token-cache MCP)
- **MANDATORY**: For boilerplate, configuration, or repeat questions, ALWAYS invoke `cache_lookup` before generating an answer.
- **FORBIDDEN**: NEVER query the full model if a valid cached response is available locally (100% token savings).

### AST Skeleton Pruning (skeleton_view MCP)
- **MANDATORY**: When exploring unfamiliar or large files (>100 lines), ALWAYS invoke `skeleton_view({ file: "path" })` first to inspect signatures, interfaces, and types.
- **PREFERRED**: Avoid ingesting full implementation bodies unless you are directly editing that exact function or need to understand call-site logic (~90% context savings).
- When full file reads are needed, restrict to 100-line windows around target symbols.

### Smart Context Exclusions
- **MANDATORY**: Automatically omit lock files (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`), build outputs (`dist/`, `build/`, `.next/`, `out/`), minified files (`*.min.js`, `*.bundle.js`), and binary files from prompt context.
- Enforce `.copilotignore` patterns to block build outputs, secrets, and non-source artifacts from AI context.

### Diff-Only Modifications
- **MANDATORY**: For file edits, ALWAYS output changes as targeted unified diffs or focused modification blocks with ±3 lines of context.
- **FORBIDDEN**: NEVER rewrite or reprint entire unmodified files or whole classes (~92% output token savings).

### Autonomous Loop Guardrails
- **MANDATORY**: Abort and pause for user input if a tool or command fails 3 times in succession.
- NEVER exceed 10 file modifications in a single autonomous task without asking confirmation.
- NEVER read the same file more than 2 times in a single conversation.

### Smart Model Routing
- When generating suggestions for minor edits, documentation comments, or commit messages, recommend using fast/lightweight models (e.g. Gemini 2.0 Flash, Claude Haiku, GPT-4o-mini) to save ~80% inference cost.

### Git Diff Scoping
- **MANDATORY**: When reviewing code, generating pull request summaries, or writing tests, scope file context strictly to lines changed in `git diff` plus direct 1-hop AST callers/callees.

### Prompt Prefix Caching
- **MANDATORY**: Maintain a deterministic, byte-stable instruction prefix across turns to maximize cloud KV-cache hit rates (75–90% cost savings).
- **MANDATORY**: Sink ephemeral turn metadata (timestamps, turn counters, run UUIDs) to the very bottom of the prompt suffix. Never prepend dynamic tokens before static rules.

### License Header Stripping
- Strip copyright license headers and preamble blocks before ingesting files. Preserve inline comments (they aid comprehension).

### Test Failure Isolator
- When executing test suites, filter terminal output to include ONLY failing assertion lines, file names, and stack traces. Omit passing tests.

## Diagnostic Exceptions
- Always show complete error traces and assertion messages when diagnosing test/build failures.
- Never compress security vulnerability findings or critical alerts.

<!-- TOKENSHIELD:END -->

# Copilot Instructions for 3ialna

This repository is a Flutter mobile app with Android-native integrations for parental control and prayer-time locking.

## Core Stack
- Flutter (Dart, null safety)
- Android native (Kotlin) via method channels
- iOS folder exists, but most parental-control enforcement is Android-first

## Project Architecture (Current)
- `lib/data/local`: local persistence and settings services
- `lib/data/system`: platform/system integration (permissions, channels, usage, overlay, location, notifications)
- `lib/domain/models`: app/domain models
- `lib/presentation`: feature screens and widgets
- `lib/l10n`: localization delegates and translations

## What Copilot Should Optimize For
- Keep changes small, targeted, and easy to review.
- Preserve existing architecture boundaries (`presentation` -> `data/system` and `data/local` via services).
- Prefer extending existing services/screens over adding duplicate abstractions.
- Keep Android-specific logic in native Kotlin or `lib/data/system` bridges.
- Respect localization (`context.l10n`) for user-facing strings.
- Maintain permission-safe behavior and graceful fallback when permissions are missing.

## Coding Guidelines
- Follow `flutter_lints` and idiomatic Dart style.
- Avoid introducing new packages unless clearly required.
- Reuse existing models and service APIs when possible.
- Do not rewrite unrelated files or perform broad refactors unless requested.
- Add short comments only for non-obvious logic.

## Validation Workflow
Use these commands after non-trivial changes:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter run` (or targeted manual validation on Android device/emulator)

## High-Risk Areas
- App blocking and accessibility flows
- Usage tracking and foreground monitoring
- Overlay behavior and lock/unlock timing
- PIN authentication and parental settings security
- Method channel contract changes between Dart and Kotlin

When generating code, favor safety and backwards compatibility in these areas.
