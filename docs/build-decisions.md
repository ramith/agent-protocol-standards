# Build Decisions — agentic-identity Skill Suite

Decided 2026-08-05. These settle the open design choices from `agentic-identity-skills-handoff.md` and `docs/claude-skill-authoring.md`.

## D1. Validation checklist lives in SKILL.md body

The full assertion checklist (the keystone artifact) goes in the SKILL.md body, not in `references/validation.md`. Rationale: the checklist always arrives when the skill loads — a persona cannot skip it — and it survives context compaction (first 5,000 tokens of an invoked skill are retained). References hold field tables, copyable artifacts, and worked examples.

Consequence: keep the rest of SKILL.md ruthlessly short so body + checklist stays well under 500 lines and the checklist sits early in the file.

## D2. Persona pairing stays chat-only

Invocation remains `@persona use <skill>` as the handoff assumes. No wrapper agents, no edits to third-party personas.

Consequence (accepted risk): delivery depends on the subagent choosing to load the skill. Mitigations required in every skill:
- `description` + `when_to_use` written so the routing is unambiguous.
- The skill body opens with an explicit role directive: reviewers check each assertion and report failures as findings; implementers turn each assertion into code/tests.
- Every skill's eval set includes a should-trigger case (see D4).

## D3. Project skills now, plugin at the milestone — REVISED 2026-08-05

Originally "plugin from day one"; revised the same day after weighing the development loop. **Amended again 2026-08-05: skill folders live at the repo root** (`<repo>/<skill-name>/`), not inside `.claude/skills/` — the root folders are the single source of truth. Because Claude Code only auto-loads skills from `.claude/skills/`, a git-ignored symlink per skill (created by `scripts/link-skills.sh`) makes them loadable during development; Claude Code follows skill-directory symlinks. Packaging as the `agentic-identity` plugin (`.claude-plugin/plugin.json` + marketplace) remains the suite-level milestone once the shape is validated across the knowledge layer.

Accepted until packaging: no namespace (skills are bare `/<skill-name>`), and a same-named personal skill in `~/.claude/skills/` would override the project copy (precedence: enterprise > personal > project).

## D4. Every skill ships three quality mechanisms

1. **Evals** — `evals/evals.json` per skill: ~3 real-task cases, 1 fabrication-bait case (must cite references or refuse — never invent claim names/event URIs), 1 persona-composition case reflecting D2. Run via skill-creator; benchmark with-skill vs without-skill.
2. **Active staleness check** — `scripts/staleness.sh` reads machine-readable fetch dates from `references/_source.md` and its output is injected into the skill content on every invocation via `` !`command` `` (e.g. "sources verified 12 days ago — OK" / "STALE: re-fetch before answering version-sensitive questions").
3. **Stable assertion IDs** — every checklist assertion carries an ID (`ACG-001`, `MCP-003`, `A2A-002`, `ADD-*`, `RSG-*`), severity, and spec reference, so reviewer findings, implementation tests, and security probes all cite the same ID.

## D5. Version pinning with consumer-facing drift disclosure (highlighted)

Every skill corresponds to a **specific revision** of each standard/protocol it encodes, shown in a highlighted banner at the top of SKILL.md and mirrored machine-readably in `references/_source.md`. On version-sensitive questions, Claude checks the currently published revision (via each source's `latest-url`) against the pin; if a newer revision exists, the user is told both versions and **chooses** whether to proceed on the pinned revision or wait for re-verification.

Rationale: these standards are fast-evolving. Proceeding on a pinned revision is legitimate; proceeding *unknowingly* is the failure mode. This extends the handoff's §9 staleness discipline from an author-side duty to a consumer-facing disclosure. Codified as principle P11 in `docs/skill-development-playbook.md`.

## D6. Validator + CI, advisory on main

`scripts/validate-suite.sh` checks every skill mechanically: frontmatter sane, pinned-versions banner matches `_source.md` exactly, SKILL.md < 500 lines, assertion IDs unique and registered, five-case evals present, staleness script runs clean. It runs in CI on every push, but work happens directly on main and CI does not block merges. Consequence (accepted): the definition-of-done checkbox "validator green" is the real gate — run it locally before declaring a skill done.

## D7. Per-skill eval fixtures

Each skill carries its own test inputs under `evals/fixtures/`; there is no shared test-design corpus. Consequence: the judgment skill will need whole-architecture fixtures of its own, including one per canonical failure class (consent-vs-action; no kill switch).

## D8. Extracts only — no vendored spec texts

The repo holds extractions and citations only. Full spec texts live in a scratch directory during authoring and are re-fetched for quarterly diffs. Zero copyright exposure; `_source.md` URLs remain the single source of truth.

## D9. Eval protocol: default model + Haiku; personas vary per skill

Evals run on the team's default model plus one Haiku pass — Haiku is the canary that fails first when instructions are ambiguous. Composition-test personas are chosen per skill for protocol fit and recorded in that skill's `evals/`, accepting reduced cross-skill comparability.

## D10. Public repo with sanitization discipline

The repo stays public. Consequence — a standing content rule for every commit: no personal names, no employer/vendor names tied to the project's origin, no client/engagement context (feature names, procurement language, programme identity). Examples stay generic; the deployment skill targets "the enterprise IAM stack in use," not a named vendor. The repo was swept and generalized 2026-08-05 before the baseline push (skill renames: `enterprise-iam-deployment`, `delegation-mandate-precedents`). The bundled the-fool skill is committed with MIT attribution (see README acknowledgements).

Known residual: git commit metadata and the repository's GitHub owner remain visible by nature of git/GitHub — the rule governs document *content*.

## Unchanged from the handoff

Build order (agent-credentials-grants first, then stop and validate the shape), persona-neutral content rules, extract-don't-summarize, self-containment, disjoint descriptions, `_source.md` citation discipline.
