---
description: 'Strategic planning and architecture assistant focused on thoughtful analysis before implementation. Helps developers understand codebases, clarify requirements, and develop comprehensive implementation strategies.'
tools: ['codebase', 'extensions', 'fetch', 'findTestFiles', 'githubRepo', 'problems', 'search', 'searchResults', 'usages', 'vscodeAPI', 'github']
---
# Advanced GitHub Workflow with Copilot Chat

This guide outlines a systematic approach to software development, integrating GitHub's issue tracking and branching features with the power of GitHub Copilot Chat. We will use a practical example to illustrate the entire lifecycle of a feature, from conception to merge.

**The Goal:** To create a robust, transparent, and collaborative development process where every piece of work is tracked, reviewed, and automated as much as possible.

## Planning, Architecture & Competitive Research Guidance

Purpose
- Provide a compact, repeatable checklist and step-by-step guidance for any agent or human planning a new feature, architecture change, or research task in this repository.
- This guidance is intended to be appended to the existing chatmode content so agents always run through a consistent discovery → options → decision → deliverables loop.

Important policy (enforced)
- DO NOT create new `*.md` files under `.github/issues/` programmatically.
- When creating issues programmatically, either:
  - Use an existing `.github/issues/*.md` file as the canonical body (read-only), or
  - Assemble the issue body in-memory (string) and pass it to the programmatic issue-creation API.
- Always persist and return created issue numbers/IDs and store a filename ↔ issue number mapping for idempotency.

When to use this guidance
- Kickoff for any non-trivial feature, refactor, or research (security, encryption, storage, external integration).
- When an agent/human must evaluate multiple technical approaches or when cross-team alignment is needed.
- Prior to opening implementation PRs — produce an architecture decision record and prototype where applicable.

Discovery checklist (quick repo analysis)
- Read the relevant platform directories (`ios/`, `android/`, `core/`, `shared/`) to find existing models, storage layers, and interfaces.
- Search for Core Data models / SQL usage (`CoreDataModels.swift`, `Entities.kt`, `DataModels.cs`, `models/`).
- Identify existing cryptography/key-management code and any Keychain or secure-storage helpers.
- Find tests and CI workflows: check `shared/__tests__`, `scripts/`, and `.github/workflows/`.
- Capture current constraints: target OS ranges, CI runner limits, native vs. server reliance, regulatory concerns (GDPR, local laws).

Architecture & design checklist (produce artifacts)
- Produce a small architecture diagram or ASCII diagram describing the components affected (storage, auth, UI, sync).
- List assumptions (storage size, offline behavior, migration frequency, threat model).
- Enumerate options (brief bullets) and trade-offs for each (complexity, security, performance, maintainability).
- For storage/encryption decisions, include a tiny prototype plan (3–5 file POC) and an automated test plan.

Options & pros/cons (common choices for this repo)
- Core Data (Apple) + Apple-provided encryption primitives
  - Pros: integrates with SwiftUI/Core Data stack, migration support, good Xcode tooling.
  - Cons: encryption requires additional work; cross-platform compatibility limited.
- Core Data + SQLCipher / Encrypted SQLite
  - Pros: strong, battle-tested DB-level encryption; portable formats.
  - Cons: native bindings, larger binary, licensing considerations, extra CI build complexity.
- Encrypted file store (binary blobs + local key encryption)
  - Pros: simpler to reason about, easier cross-platform parity.
  - Cons: less queryable, may require full-file reads/writes for many use cases.
- Server-assisted encrypted sync (end-to-end encrypted)
  - Pros: enables multi-device sync with stronger guarantees.
  - Cons: raises operational, legal, and infrastructure cost; out of scope for local-first features unless explicitly accepted.

Alternative plans
- Start with an OS-native solution (Core Data + Keychain) as v1 and design an adapter layer so switching to SQLCipher later requires minimal changes (Repository abstraction + clear storage contract).
- Build a small cross-platform encrypted storage interface in `shared/` (TypeScript/JS) to validate sync/export flows before committing to a heavy native implementation.
- Prototype both Core Data and SQLCipher approaches as two tiny branches, run benchmarks, and choose based on measurable results.

Competitive research (how to run and capture findings)
- Identify 3–5 competitor apps or libraries to study (example categories: personal finance apps in target markets, secure local stores, open-source encrypted DBs).
- For each, record:
  - storage format, encryption approach, sync model, privacy claims, and monetization model.
  - trade-offs observed (size, performance, UX for exports/backup).
- Produce a short "findings" artifact: one-page markdown per competitor and a short recommendation (keep in `.docs/` or link to the issue).

Deliverables for an architecture / research issue
- Decision doc (short ADR) with chosen approach, alternatives considered, and reason.
- Short prototype (branch) with at least:
  - Basic CRUD tests and a small benchmark (latency for 1000 records).
  - Migration test that simulates an upgrade from an older schema.
  - Integration test showing key storage retrieval (e.g., Keychain + LocalAuthentication).
- Acceptance criteria (example)
  - Data is persisted and recovered across app restarts.
  - Encrypted data cannot be read with the raw DB without keys.
  - Migration path tested for the current schema → new schema.
  - Benchmarks meet the target latency (define targets in the issue).

Decision record template (use as issue checklist)
- Title: ADR — <concise decision title>
- Status: Proposed / Accepted / Deprecated
- Context: Problem statement and constraints
- Options considered: bullet list with short trade-offs
- Decision: chosen option + rationale
- Consequences: follow-up tasks, migration, compatibility notes
- Date & Authors

Edge cases to explicitly cover
- No-key recovery: user loses device and Keychain — how to export/import backups safely?
- Large datasets: thousands of transactions — ensure read/write performance and memory usage tests.
- Migration failures: interrupted migration during an update — ensure atomicity/rollback.
- Biometric edge cases: biometric unavailable or changed — fallback flows to PIN or passphrase.
- Cross-platform parity: formats for export/import and whether they are compatible across iOS/Android/Windows.

Testing & Quality gates
- Before merging implementation PRs, ensure:
  - Unit tests for core storage APIs (CRUD + encryption).
  - Integration smoke test on the minimum supported OS versions (macOS 16+, iOS versions if applicable).
  - Lint/type checks pass and CI workflow runs successfully (fix CI scripts if new native libs are added).
- Optional: add a small performance harness to `scripts/` or `shared/` to run on CI for basic benchmarks.

How agents should produce issues (practical rules)
- Include these sections in the body: Context, Decision Options, Trade-offs, Proposed Deliverables, Acceptance Criteria, Migrations, Tests.
- After creating an issue, return the created issue number/ID and persist a mapping (filename -> issue_number) to make future runs idempotent.
- When creating sub-issues, call `mcp_github_add_sub_issue` (or equivalent) and confirm the parent issue body reflects the "Blocks/Depends on" relationships.

Small checklist to include in the issue body (copyable)
- Problem/Goal
- Constraints & Assumptions
- Alternatives considered (1–3)
- Chosen approach & short rationale
- Prototype plan (files/dirs to add)
- Tests to implement
- Acceptance criteria (clear, testable)
- Estimated effort (scoping: S/M/L)

Quick git commands to commit this change (macOS `zsh`)
```bash
git add [feature.plan.chatmode.md](http://_vscodecontentref_/1)
git commit -m "chore(chatmode): add planning, architecture & competitive research guidance"
git push origin HEAD
```
