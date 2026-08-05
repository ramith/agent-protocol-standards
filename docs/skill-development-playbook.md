# Skill Development Playbook

**Status:** binding for every skill developed in this repo, current and future.
**Last updated:** 2026-08-05.

This is the process document. It exists so that skill #14, built months from now by someone who never read the original handoff, comes out with the same shape, rigor, and quality as skill #1.

How the documents in this repo relate:

| Document | Role |
|---|---|
| `agentic-identity-skills-handoff.md` | Why the suite exists; what to build; per-skill briefs |
| `docs/claude-skill-authoring.md` | Platform mechanics (frontmatter, loading, evals) — verified against live docs |
| `docs/build-decisions.md` | The locked design decisions (D1–D9) and their rationale |
| `docs/qa-strategy.md` | **Binding** accuracy QA: verification passes V1–V6, human review, continuous accuracy. Where its §4 table upgrades a gate below, the QA strategy wins |
| **This playbook** | The principles, the build process with gates, templates, and usage rules |

---

## Part 1 — Design principles (non-negotiable)

Each principle comes with a violation test. If the test fires, the skill does not ship.

**P1. Retrieval over recall.** The payload is primary-source facts: field tables, exact parameter names, copyable artifacts, cited requirements. *Violation test: any spec fact in the skill that cannot be traced to a file in `references/` with a URL + section + fetch date.*

**P2. Layers compose downward, never up.** Knowledge skills state facts and never drive workflows. Judgment skills drive review and consult knowledge. Deployment skills map "how" onto a product and consult both. *Violation test: a knowledge skill containing step-by-step task instructions, or a deployment skill asserting a spec fact its knowledge sibling doesn't carry.*

**P3. Persona-neutral facts, explicit role directive.** Content is written as domain fact usable by a reviewer, a coder, or a tester. Because pairing is chat-only (D2), the body opens with a short directive telling each role what to do with the checklist. *Violation test: instructions that only make sense for one persona, or a skill whose checklist doesn't say how reviewers vs implementers consume it.*

**P4. Ruthless self-containment.** A skill must work with no sibling loaded. Cross-references are of the form "if you also have X loaded, see it for Y" — helpful when present, harmless when absent. *Violation test: a sentence that is wrong or incomplete when a sibling skill is missing.*

**P5. Disjoint descriptions.** Routing is manual, so descriptions optimize for unambiguity between siblings, not trigger aggressiveness. *Violation test: two skills whose descriptions could both plausibly match the same request.*

**P6. The checklist is the keystone and lives in the body.** Every skill's validation checklist sits in SKILL.md (D1), early in the file, as discrete testable assertions with stable IDs (D4). One checklist serves reviewer, coder, and tester. *Violation test: an assertion written as prose ("tokens should be properly validated") instead of a testable condition ("REJECT if `aud` ≠ this resource, exact match").*

**P7. Extract, don't summarize.** Field names, parameter names, claim structures, and event URIs are reproduced exactly. Prose explanations are reworded (copyright) and kept short. *Violation test: a paraphrased field name, or a "roughly speaking" gloss where the spec gives a precise rule.*

**P8. Staleness is active, not decorative.** Machine-readable fetch dates in `_source.md`; a staleness script whose output is injected on every invocation (D4). *Violation test: a skill that can serve a superseded revision without warning the reader.*

**P9. Name the void.** Where no standard exists (agent attestation, fleet revocation, delegation mandates, gateway auth propagation), say so explicitly. A skill that pretends a standard exists is worse than no skill. *Violation test: an invented mechanism presented with the same confidence as a cited one.*

**P10. Evals are part of the skill.** A skill without `evals/evals.json` is a draft, not a skill (D4). *Violation test: shipping without the five-case eval set (Part 3, Stage 5).*

**P12. Uncertainty resolves online, never from recall.** This applies to the *authoring process itself*, not just skill content: whenever the model building or verifying a skill has a knowledge gap or is uncertain about a fact, a platform behavior, a spec detail, or a decision's premise, it searches/fetches current sources before proceeding — and records what it consulted. *Violation test: any authoring or QA step that resolved uncertainty by picking the most plausible answer instead of looking it up.*

**P11. Every skill pins its standard versions — and discloses drift. (⚠ highlighted rule)** A skill encodes a *specific revision* of each standard/protocol it covers, named in a highlighted banner at the top of SKILL.md. On version-sensitive questions, the currently published revision is checked against the pin; if a newer revision exists, the user is told both versions and chooses whether to proceed on the pinned one. *Violation test: an answer on version-sensitive ground that doesn't name the revision it comes from, or a skill that proceeds silently when its pin is superseded.*

---

## Part 2 — Uniform anatomy

Every skill follows this exact layout (developed in the repo's `.claude/skills/`; plugin packaging comes at the suite milestone, D3):

```
.claude/skills/<skill-name>/
├── SKILL.md                  # see skeleton below; < 500 lines total
├── references/
│   ├── _source.md            # machine-readable source register (template below)
│   ├── <topic>.md            # field tables, normative requirements per source
│   ├── artifacts.md          # copyable schemas / claim structures / wire examples
│   └── pitfalls.md           # known implementer mistakes, each tied to assertion IDs
├── scripts/
│   └── staleness.sh          # emits freshness verdict; injected at invocation
├── qa/
│   └── verification-report.md # V1/V2 verdicts with evidence quotes + file hashes (see docs/qa-strategy.md)
└── evals/
    ├── evals.json            # the five-case eval set + fabrication probe bank
    └── fixtures/             # this skill's own test inputs (D7) — flawed designs, sample tokens, mutations
```

### SKILL.md skeleton

````markdown
---
name: <skill-name>
description: <what it covers — disjoint from every sibling>
when_to_use: <example requests, e.g. "reviewing token flows", "implementing OBO validation">
---

<!-- Source freshness (auto-injected): -->
!`bash ${CLAUDE_SKILL_DIR}/scripts/staleness.sh`

# <Skill title>

> **⚠ PINNED STANDARD VERSIONS — this skill encodes:**
>
> | Standard | Pinned revision |
> |---|---|
> | <standard> | <exact revision — e.g. `2026-07-28`, `v1.0`, `RFC (immutable)`> |
>
> These standards evolve fast. Newer revisions may exist — apply the "Version drift protocol" below before relying on version-sensitive answers.

## How to use this skill
- **Reviewers:** check the design against every assertion below; report each failure as a finding citing its ID.
- **Implementers:** every assertion becomes a code path and a test named after its ID.
- **Security testers:** every assertion becomes a probe; a passing probe cites its ID.

## Covers / does not cover
<one paragraph each; name the sibling that covers the excluded ground>

## Verify, don't recall
<the 3–5 facts most often fabricated — each with "see references/<file>.md">

## Validation checklist
<all assertions, format: ID | severity | assertion | source§ — see Part 4>

## Reference map
<one line per references/ file: what it contains, when to read it>

## Version drift protocol
Before answering a version-sensitive question: fetch the `latest-url` for the relevant source in references/_source.md and compare the current published revision to the pinned one above. If newer, report both — "this skill pins <X>; the current revision is <Y>" — and let the user choose: proceed on the pinned revision, or pause for re-verification. Never answer silently from a superseded pin.

## Staleness note
Sources and revisions in references/_source.md. If the banner above says STALE, re-fetch before answering version-sensitive questions.
````

**Frontmatter rules for knowledge skills:** never set `disable-model-invocation` (it blocks subagent preloading and model invocation — kills chat-only pairing), never set `context: fork` (knowledge is not a task). Judgment/deployment skills may deviate only with a note in `docs/build-decisions.md`.

### `_source.md` template (machine-readable header)

```markdown
# Sources

| id | url | revision | fetched | recheck-days | latest-url |
|---|---|---|---|---|---|
| rfc8693 | https://www.rfc-editor.org/rfc/rfc8693.html | RFC (immutable) | 2026-08-05 | 0 | — |
| mcp-auth | https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization/ | 2026-07-28 | 2026-08-05 | 90 | https://modelcontextprotocol.io/specification/ |

`recheck-days: 0` = immutable, never stale. Anything else: stale when `today - fetched > recheck-days`.
`latest-url` = the page where the standard's current revision is announced; the version drift protocol (P11) fetches this. Use `—` for immutable sources. Unversioned IETF datatracker URLs resolve to the latest revision and serve as their own `latest-url`.
```

`scripts/staleness.sh` parses this table and prints one line per stale source, or `sources OK (oldest re-checkable fetch: N days)`. Keep it POSIX-portable, no dependencies.

### ⚠ Version pinning and drift disclosure (P11 — highlighted)

**Every skill corresponds to a specific standard/protocol version.** This is the rule consumers depend on most, because these standards are fast-evolving: a skill that silently serves a superseded revision is worse than no skill.

The mechanism has three layers:

1. **Pin (author-side).** The `revision` column in `_source.md` is the machine-readable pin; the banner at the top of SKILL.md is the human-readable one. The two must match exactly — the definition-of-done checks this.
2. **Disclose (invocation-time).** The pinned-versions banner plus the injected staleness output mean every consumer sees, on every invocation, which revisions the skill encodes and how old the verification is.
3. **Check and choose (answer-time).** For version-sensitive questions, Claude fetches the `latest-url` for the relevant source and compares the currently published revision against the pin. If a newer revision exists, Claude reports both ("this skill pins MCP `2026-07-28`; the current revision is `2027-xx-xx`") and **the user decides**: proceed on the pinned revision (fine for most work) or pause while the source is re-fetched and diffed. Proceeding is legitimate; proceeding *unknowingly* is the failure mode this rule eliminates.

A drift report from layer 3 is also a maintenance trigger for the skill's author (Part 6).

---

## Part 3 — The build process (stage gates)

A skill advances only when its gate passes. Do not parallelize stages for a single skill.

**Stage 0 — Scope.** Write the `description` + `when_to_use` and the "covers / does not cover" section *first*, and check them against every existing sibling for disjointness (P5).
*Gate: another person (or a fresh Claude session) can route 10 sample requests to the right skill using descriptions alone.*

**Stage 1 — Acquire sources.** Fetch every primary source into a scratch dir. Record URL, exact revision, fetch date in `_source.md`. If a source is unreachable, flag it — never substitute recall.
*Gate: `_source.md` complete; zero sources marked "from memory".*

**Stage 2 — Extract.** For each source, produce the reference file: field tables (exact names), normative MUST/SHOULD/MUST NOT list with section refs, copyable artifacts, pitfalls.
*Gate: full reverse verification (QA strategy V1 — adversarial assertion check + blind re-extraction) over the field tables; no `CONTRADICTED`/`UNSUPPORTED`.*

**Stage 3 — Author the checklist.** Recast normative requirements as assertions with IDs, severity, and source section (format in Part 4). Include the suite's two canonical failure classes where relevant (consent-to-access ≠ authorization-of-action; no functioning off-switch).
*Gate: every assertion is mechanically checkable — a tester could write a probe from the text alone, without reading the spec.*

**Stage 4 — Assemble SKILL.md.** Fill the skeleton. Checklist early. Budget: whole file < 500 lines, checklist inside the first ~4,000 tokens (compaction survival).
*Gate: line count + a read-through against P1–P9 violation tests.*

**Stage 5 — Write evals.** Five cases minimum in `evals/evals.json`:
1–3. Real tasks (one implement-shaped, one review-shaped, one question-shaped).
4. **Fabrication bait:** a question whose answer must be cited from references or explicitly refused ("what is the CAEP event URI for session revocation?"). Expected behavior: exact citation or "must re-fetch" — never invention.
5. **Composition case:** the task phrased as a persona would receive it, checking that named assertions survive into the output.
*Gate: evals run via skill-creator on the team's default model plus one Haiku pass (D9 — Haiku fails first when instructions are ambiguous); all pass on both; the with-skill vs without-skill benchmark shows the skill changes behavior (if without-skill passes everything, the skill adds nothing — rescope it).*

**Stage 6 — Composition test (chat-only, per D2).** Run the real pairing: `@<coding-persona> use <skill>` on an implementation task, and `@<reviewer-persona> use <skill>` on a review task, in fresh sessions. Choose the persona pair per skill for protocol fit and record it in the skill's `evals/` (D9), so reruns use the same pair.
*Gate: the coder's output implements the load-bearing assertions (for token skills: `cnf` check, `act`-present, audience exact-match, no passthrough); the reviewer flags the same items as findings citing IDs. If it fails, fix the skill's role directive or description — never the persona.*

**Stage 7 — Ship.** Run `scripts/validate-suite.sh` locally — CI is advisory (D6), so this local run is the gate. Add a CHANGELOG entry and commit to main.
*Gate: validator green, and a clean clone can invoke `/<skill-name>` with no verbal instructions. Plugin packaging and the `agentic-identity:` namespace arrive at the suite milestone (D3).*

> **First-skill rule:** after the first skill of any new *layer* (knowledge/judgment/deployment) passes Stage 6, stop and review the shape before replicating it.

---

## Part 4 — Assertion format and severity

**Format:** `<PREFIX>-NNN | <severity> | <assertion> | <source §>`

Example: `ACG-007 | CRITICAL | REJECT if `act` claim absent on an agent-facing endpoint | RFC 8693 §4.1`

**ID prefixes** (stable forever; never renumber, never reuse a retired ID — mark it `WITHDRAWN` instead):

| Skill | Prefix |
|---|---|
| agent-credentials-grants | ACG |
| agent-delegation-drafts | ADD |
| mcp-authorization | MCP |
| a2a-protocol | A2A |
| revocation-signals | RSG |
| agentic-architecture-review | AAR |
| openclaw-runtime | OCR |
| enterprise-iam-deployment | EID |
| *(future skills)* | *3–4 letters, registered here before Stage 3* |

**Severity scale:**

| Level | Meaning | Anchor |
|---|---|---|
| BLOCKER | Design cannot ship; failure defeats the purpose | no working revocation path |
| CRITICAL | Exploitable weakness; fix before implementation | bearer OBO token (no `cnf`) |
| MAJOR | Weakens the design; fix before production | scope widening across an exchange |
| ADVISORY | Hardening or hygiene | shorter TTLs on read scopes |

---

## Part 5 — How to use the skills (consumer guide)

**Install (teammates):** clone this repo and start Claude Code anywhere inside it — project skills in `.claude/skills/` load automatically (also from parent directories, and in cloud sessions working on this repo). When the suite is packaged as the `agentic-identity` plugin (D3 milestone), installation moves to `/plugin install` and skills gain the `agentic-identity:` namespace.

**Caution until packaging:** a same-named skill in your personal `~/.claude/skills/` silently overrides the project copy — don't keep private forks of suite skills under the same name.

**Pair with a persona (the primary pattern):**
```
@architect-reviewer use agent-credentials-grants to review the token flow for the payments feature
@golang-pro use mcp-authorization to implement the resource-server token validation
```
The persona supplies the idiom; the skill supplies the requirements. Expect outputs to cite assertion IDs — a review finding without an ID means the checklist wasn't consulted; re-invoke with the skill named explicitly.

**Stack skills for cross-protocol work:** `/agent-credentials-grants /mcp-authorization <task>` loads both; descriptions are disjoint by design so they compose without conflict.

**Direct invocation** (no persona): `/<skill-name> <question or task>` — useful for spec lookups and design Q&A.

**Trust rule for consumers:** if the staleness banner reports STALE, treat version-sensitive answers as provisional until sources are re-fetched.

**Version rule for consumers (P11):** every skill pins specific standard revisions, shown in the banner at the top of the skill. On version-sensitive ground, expect answers to name the revision they come from, and expect Claude to check whether a newer revision has been published. If one has, the choice is yours: proceed on the pinned revision or ask for re-verification first. If an answer neither names a revision nor mentions drift, ask "which revision is this from, and is it current?"

---

## Part 6 — Maintenance discipline

- **Quarterly sweep** of fast movers (MCP revision, the four delegation drafts, A2A extensions, OpenClaw docs): re-fetch, diff against `references/`, update assertions, bump fetch dates. RFCs never need re-checking (`recheck-days: 0`).
- **On any spec revision:** diff first, then update the reference file, then the checklist (IDs stable, content amended, withdrawn assertions marked `WITHDRAWN`), then re-run the skill's evals. All four steps or none.
- **Eval refresh on model updates:** when the default Claude model changes, re-run every skill's benchmark; skill-creator's comparison mode exists for exactly this.
- **On a drift report:** when the version drift protocol (P11) surfaces a newer revision during real use, treat it as an immediate maintenance trigger — run the spec-revision procedure above now, don't wait for the quarterly sweep.
- **CHANGELOG.md** at repo root records every shipped change per skill with date and reason.

---

## Part 7 — Definition of done (per skill)

- [ ] Description + `when_to_use` disjoint from all siblings (Stage 0 gate passed)
- [ ] `_source.md` complete; no source "from memory"; machine-readable dates
- [ ] Reference files: exact field names, section-cited requirements, copyable artifacts
- [ ] Checklist in SKILL.md body, early, IDs + severity + source per assertion
- [ ] Role directive at top of body (reviewer / implementer / tester)
- [ ] "No standard exists here" entries where applicable (P9)
- [ ] SKILL.md < 500 lines; staleness injection wired and tested
- [ ] ⚠ Pinned-versions banner present and matching `_source.md` revisions exactly; version drift protocol section included and tested against one live source (P11)
- [ ] `evals/evals.json`: ≥3 real tasks + fabrication bait + composition case, with per-skill fixtures under `evals/fixtures/`, all passing on default model + Haiku (D9)
- [ ] With-skill vs without-skill benchmark shows behavioral difference
- [ ] Chat-only composition test passed with one coding and one reviewer persona (pair recorded in `evals/`)
- [ ] `qa/verification-report.md` present: V1 dual verification + V2 three-sweep coverage, evidence quotes, file hashes, no blocking verdicts (QA strategy)
- [ ] QA stamp in the SKILL.md banner; human sign-off on CRITICAL+ assertions; audit sample passed
- [ ] `scripts/validate-suite.sh` green locally — the real gate, since CI is advisory (D6)
- [ ] CHANGELOG entry; invocable as `/<skill-name>` from a clean clone
