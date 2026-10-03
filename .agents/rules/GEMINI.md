# GEMINI.md

Project instructions for Gemini. Read this before making changes. Where this file conflicts with an explicit instruction in a prompt, follow the prompt. Where this file conflicts with the existing codebase's established conventions, follow the codebase and flag the discrepancy.

> **Setup:** Fill in the `TODO` fields in the "Project Overview" and "Commands" sections. Delete any section that doesn't apply.

---

## 1. Project Overview

- **Name:** TODO
- **Purpose:** TODO (one or two sentences: what it does and for whom)
- **Language(s) / Runtime(s):** TODO
- **Framework(s):** TODO
- **Datastores / Infra:** TODO
- **Architecture style:** TODO (e.g., monolith, modular monolith, microservices, serverless)

### Repository layout

```
TODO: paste a trimmed directory tree and one-line descriptions, e.g.
src/        application code
tests/      unit, integration, and e2e tests
docs/       architecture notes and ADRs
scripts/    developer and CI tooling
```

---

## 2. Commands

Always use these commands rather than inventing alternatives. Prefer the project's task runner (Makefile, npm scripts, etc.) over raw tool invocations.

| Task | Command |
|---|---|
| Install dependencies | `TODO` |
| Run locally | `TODO` |
| Run all tests | `TODO` |
| Run a single test | `TODO` |
| Lint | `TODO` |
| Format | `TODO` |
| Type-check | `TODO` |
| Build | `TODO` |

**Before declaring any task complete, run lint, type-check, and the relevant tests, and report the results.** Never claim something passes without having run it.

---

## 3. How to Work

### Approach
1. **Understand first.** Read the relevant code, tests, and docs before changing anything. Don't guess at APIs, function signatures, or file locations; look them up.
2. **Plan non-trivial changes.** For anything touching more than a couple of files or changing behavior, outline the approach briefly before editing.
3. **Make small, focused changes.** One logical change at a time. Avoid drive-by refactors, unrelated formatting changes, and scope creep. If you spot an unrelated problem, mention it instead of fixing it silently.
4. **Preserve behavior unless asked to change it.** Refactors must not alter observable behavior. Back them with tests.
5. **Verify.** Run the checks in Section 2 after changes.
6. **Ask when ambiguous.** If requirements are unclear or a decision has significant trade-offs, ask rather than assume. State assumptions explicitly when you proceed.

### Honesty and scope
- Do not fabricate libraries, functions, flags, or documentation. If unsure, say so and verify.
- Do not delete, disable, or weaken tests, lint rules, type checks, or security controls to make a change pass. Fix the underlying issue.
- Do not add new dependencies without justification (see Section 8).
- Flag risks, trade-offs, and known limitations in your summary.

---

## 4. Code Quality

### Principles
- **Readability over cleverness.** Code is read far more often than written. Optimize for the next maintainer.
- **SOLID, DRY, KISS, YAGNI.** Prefer simple designs. Don't build abstractions for hypothetical future needs. Duplicate twice, abstract on the third occurrence, and only when the abstraction is clear.
- **Single responsibility.** Functions do one thing; modules have one reason to change.
- **Composition over inheritance.** Depend on interfaces/abstractions, not concrete implementations.
- **Make illegal states unrepresentable.** Use types, enums, and validation to rule out invalid data.
- **Prefer pure functions and immutability** where practical. Isolate side effects at the edges.

### Style
- Follow the project's formatter and linter configuration exactly. Do not hand-format against it.
- Use meaningful, intention-revealing names. Avoid abbreviations, single-letter names (outside tight loops), and misleading names.
- Keep functions short and shallow. Prefer early returns and guard clauses over deep nesting.
- Avoid magic numbers and strings; use named constants or configuration.
- Remove dead code, commented-out code, and unused imports rather than leaving them behind.
- Match the idioms of the language in use (e.g., PEP 8 for Python, Effective Go, Google/Airbnb style for JS/TS) unless the repo specifies otherwise.

### Comments and documentation
- Comment the **why**, not the **what**. If a comment restates the code, improve the code instead.
- Document public APIs (parameters, return values, errors raised, side effects, units).
- Keep docs next to the code and update them in the same change as the behavior they describe.
- Record significant architectural decisions as short ADRs in `docs/adr/`.
- Use `TODO(owner): description` for deferred work, and link an issue where possible.

---

## 5. Testing

- **Every behavior change needs tests.** New features get new tests; bug fixes get a regression test that fails before the fix and passes after.
- Follow the **test pyramid**: many fast unit tests, fewer integration tests, a small number of end-to-end tests.
- Tests must be **deterministic, isolated, and fast.** No reliance on test order, wall-clock time, network access, or shared mutable state. Inject clocks, randomness, and external clients.
- Use the **Arrange-Act-Assert** (Given-When-Then) structure. Test one behavior per test with a descriptive name.
- Test behavior and contracts, not implementation details. Avoid over-mocking; mock only at system boundaries (network, filesystem, clock, third-party services).
- Cover edge cases: empty/null inputs, boundaries, error paths, concurrency, and invalid input.
- Do not chase coverage numbers for their own sake, but do not reduce coverage on changed code. Target: TODO% (or "match existing project thresholds").
- Fix or quarantine flaky tests with an owner and issue; never ignore them.

---

## 6. Error Handling and Logging

- **Fail fast and explicitly.** Validate inputs at boundaries; return or raise meaningful errors.
- Never swallow exceptions silently. Catch only what you can handle, and preserve the original cause/stack trace when rethrowing or wrapping.
- Use specific error types rather than generic ones. Don't use exceptions for normal control flow.
- Make failure modes of external calls explicit: timeouts, retries with exponential backoff and jitter, and idempotency for retried operations. Set timeouts on every network call.
- **Logging:** use the project's structured logger, not `print`/`console.log`. Use appropriate levels (DEBUG, INFO, WARN, ERROR). Include correlation/request IDs and useful context.
- **Never log secrets, credentials, tokens, or personal data (PII).** Redact or omit sensitive fields.
- Surface actionable error messages to users without leaking internals.

---

## 7. Security

Treat security as a requirement, aligned with the OWASP Top 10 and OWASP ASVS.

- **Never commit secrets.** No API keys, passwords, tokens, or private keys in code, config, tests, logs, or docs. Use environment variables or a secrets manager. If you find a committed secret, flag it for rotation.
- **Validate and sanitize all external input** (user input, API payloads, files, headers, environment). Prefer allow-lists over deny-lists.
- **Prevent injection.** Use parameterized queries / prepared statements and safe templating. Never build SQL, shell commands, or HTML by string concatenation with untrusted data.
- **Authentication and authorization:** enforce checks server-side on every protected operation, apply least privilege, and deny by default. Use vetted libraries; do not roll your own crypto or auth.
- **Cryptography:** use well-established algorithms and libraries (e.g., Argon2/bcrypt for passwords, AES-GCM, TLS 1.2+). Never use MD5/SHA-1 for security purposes.
- **Protect data in transit and at rest.** Minimize collection and retention of sensitive data.
- **Dependencies:** keep them updated, pin versions, and avoid abandoned or unvetted packages. Run the project's vulnerability scanner.
- Avoid unsafe constructs (`eval`, unsafe deserialization, disabled TLS verification, overly permissive CORS) unless explicitly required and documented.
- Apply secure defaults for headers, cookies (`HttpOnly`, `Secure`, `SameSite`), and CSRF protection where relevant.

---

## 8. Dependencies

- Prefer the standard library and existing project dependencies before adding a new package.
- Before adding a dependency, consider: maintenance status, license compatibility, security history, size, and whether the need is large enough to justify it.
- Pin versions and commit the lockfile. Do not edit lockfiles by hand.
- Remove unused dependencies.

---

## 9. Performance and Reliability

- **Measure before optimizing.** Don't make speculative optimizations that hurt readability; profile and target real bottlenecks.
- Be mindful of algorithmic complexity, N+1 queries, unnecessary allocations, blocking I/O on hot paths, and unbounded memory growth.
- Paginate or stream large result sets. Add indexes deliberately and verify them with query plans.
- Design for failure: timeouts, circuit breakers, graceful degradation, and idempotent operations.
- Make concurrent code safe: avoid shared mutable state, document thread-safety, and prevent race conditions and deadlocks.
- Make operations observable: metrics, structured logs, and tracing where the project supports them.

---

## 10. API and Data Design

- Design APIs to be consistent, predictable, and backward compatible. Don't introduce breaking changes without versioning and a migration path.
- Use appropriate HTTP semantics and status codes (for REST), and consistent error response shapes.
- Validate request and response schemas; keep them documented (e.g., OpenAPI).
- **Database migrations** must be versioned, reversible where possible, and safe to run on a live system (avoid long locks; use expand/contract for breaking schema changes). Never edit a migration that has already shipped.
- Use transactions for multi-step operations that must succeed or fail together.
- Store timestamps in UTC; handle time zones and money (use decimal/integer minor units, not floats) carefully.

---

## 11. Version Control and Collaboration

### Commits
- Make small, atomic commits that each build and pass tests.
- Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): summary`
  - Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
  - Summary: imperative mood, ≤ 72 characters, no trailing period. Explain the *why* in the body when it isn't obvious.
  - Mark breaking changes with `!` or a `BREAKING CHANGE:` footer.

### Branches and pull requests
- Branch from the main branch with descriptive names: `feat/short-description`, `fix/issue-123-short-description`.
- Keep PRs small and focused. Each PR should include: a clear description of what and why, how it was tested, linked issues, and notes on risks or rollout.
- Update tests and documentation in the same PR as the code change.
- Do not force-push to shared branches, rewrite published history, or commit directly to the main branch.
- Never commit generated artifacts, build output, local config, or credentials. Respect `.gitignore`.

### Code review
- When reviewing, prioritize correctness, security, design, and test quality over style nitpicks (which tooling should handle). Be specific and constructive.

---

## 12. CI/CD and Deployment

- All changes must pass CI (lint, type-check, tests, security scans, build) before merging.
- Builds must be reproducible. Use pinned versions and lockfiles.
- Configuration is environment-specific and kept out of code (twelve-factor style). Never hardcode environment values.
- Prefer small, frequent, reversible releases. Support rollback and use feature flags for risky changes.
- Infrastructure is managed as code and reviewed like application code.

---

## 13. Accessibility and Internationalization (if there is a UI)

- Meet WCAG 2.1 AA: semantic HTML, keyboard navigability, sufficient color contrast, text alternatives for images, and proper labels/ARIA only where needed.
- Don't hardcode user-facing strings; use the project's i18n mechanism. Handle locale-specific formatting for dates, numbers, and currencies.

---

## 14. Do and Don't Summary

**Do**
- Read the surrounding code and follow existing conventions.
- Write or update tests with every behavior change.
- Run lint, type-check, and tests before reporting completion.
- Keep changes small, focused, and well-explained.
- Surface assumptions, trade-offs, and risks.
- Validate inputs, handle errors explicitly, and protect secrets.

**Don't**
- Invent APIs, packages, or facts.
- Disable tests, linters, or security checks to get a green build.
- Commit secrets, credentials, or personal data.
- Introduce breaking changes, new dependencies, or large refactors without being asked.
- Leave dead code, debug prints, or unexplained TODOs behind.
- Make unrelated changes in the same commit or PR.
