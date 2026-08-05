# Roadmap — agentic-identity Skill Suite

**Model:** sequence + checkpoints, no calendar dates (progress is gated by the playbook's stage gates, not deadlines). One skill at a time — lessons compound forward. Decided 2026-08-05.

**Ground rules already binding:** every skill passes the playbook's seven stage gates (`docs/skill-development-playbook.md` Part 3) and its definition of done (Part 7). Effort figures are working-session estimates, not commitments.

---

## Phase 0 — Foundations *(runs inside Phase 1, not before it)*

Built alongside skill 1, each piece landing when its first real consumer exists:

- [ ] Create `.claude/skills/` in this repo (restart session so the new directory is watched)
- [ ] Install skill-creator: `/plugin marketplace add anthropics/claude-plugins-official` → `/plugin install skill-creator@claude-plugins-official`
- [ ] Scratch layout for spec sources: `/tmp/spec-src/<skill-name>/` (extracts-only policy, D8)
- [ ] `scripts/staleness.sh` reference implementation (parses `_source.md`, POSIX, no deps)
- [ ] `scripts/validate-suite.sh` — **grown during skill 1**: each check written when its convention gets its first real instance; complete by skill 1's DoD
- [ ] CI workflow (advisory, D6) once the validator exists

## Phase 1 — Prove the shape: `agent-credentials-grants` (ACG)

The hardest skill deliberately goes first (8 sources, highest fabrication risk — token/claim structures, `act` nesting, `cnf` binding). ~2–3 sessions.

Stage 0–7 per the playbook, then:

**⛳ CHECKPOINT 1 — Shape review.** Before any replication: did checklist-in-body (D1) hold up in the composition test? Reference-file granularity right? Eval effort proportionate? Amend the playbook *now* if not — this is the cheapest moment to change the template. (Handoff §5: "stop and validate the shape.")

## Phase 2 — Knowledge layer, sequential

Order: **MCP → A2A → drafts → revocation** (MCP pulled forward: fastest-moving spec, pin it while `2026-07-28` is current; closest to current MCP-gateway integration work).

| Order | Skill | Prefix | Est. | Test pair (proposed; confirm at Stage 6) | Watch for |
|---|---|---|---|---|---|
| 2 | `mcp-authorization` | MCP | 1–2 | typescript-pro + architect-reviewer | shortest recheck cycle (90d); token-passthrough wording must be verbatim-accurate |
| 3 | `a2a-protocol` | A2A | 2 | java-architect + architect-reviewer | AgentCard schema reproduced field-exact; signed-cards MAY→MUST note for gov profiles |
| 4 | `agent-delegation-drafts` | ADD | 1–2 | golang-pro + architect-reviewer | drafts expire/rename params — shortest recheck; "not citable as standards" framing everywhere |
| 5 | `revocation-signals` | RSG | 1–2 | spring-boot-engineer + security-auditor | event-type URIs and subject formats are the highest per-fact fabrication risk in the suite |

**⛳ CHECKPOINT 2 — Layer consistency sweep.** With all five knowledge skills live: (a) description-disjointness test — route 15 sample requests using descriptions alone, zero ambiguity; (b) duplication audit — every duplicated fact carries identical citations; (c) full validator run; (d) cross-skill conflict check (draft claims vs RFC claims stated consistently).

## Phase 3 — Judgment layer

- [ ] **Decision due:** judgment-skill template (deferred from 2026-08-05) — duplicate vs cite sibling assertion IDs, `$ARGUMENTS` design-input contract, inline vs `context: fork`. Comes back as a question round.
- [ ] Build `agentic-architecture-review` (AAR, ~2 sessions) — layered checklist, pattern library, severity model, "no standard exists here" register, non-certification boundary note.
- [ ] Its `evals/fixtures/` must include one flawed design per canonical failure class (consent-vs-action; no kill switch) — handoff acceptance criterion 7 becomes executable here.

**⛳ CHECKPOINT 3 — Handoff acceptance §10 items 6–8** verified against the fixtures.

## Phase 4 — Deployment layer

| Order | Skill | Prefix | Est. | Test pair (proposed) | Watch for |
|---|---|---|---|---|---|
| 7 | `openclaw-runtime` | OCR | 1–2 | security-engineer + devops-engineer | product docs move fast; encode the untrusted-code-with-durable-credentials framing |
| 8 | `enterprise-iam-deployment` | EID | 2 | java-architect + security-engineer | every capability claim verified against live product docs; every "how" maps to a protocol skill's "what" (acceptance §10.9–10) |

## Phase 5 — Packaging milestone (D3)

- [ ] **Decisions due:** plugin/marketplace naming; team contribution rules (PR spot-check duty)
- [ ] `.claude-plugin/plugin.json` + marketplace setup; skills gain the `agentic-identity:` namespace
- [ ] Update playbook Part 5 install section; teammate rollout + short onboarding note
- [ ] Re-run every skill's evals from a clean plugin install (paths, `${CLAUDE_SKILL_DIR}`, namespaced invocation)

## Ongoing (starts the day skill 1 ships)

- **Drift-triggered maintenance:** any P11 drift report during real use → immediate spec-revision procedure (playbook Part 6)
- **Quarterly sweep:** fast movers (MCP, the four delegation drafts, A2A extensions, OpenClaw, vendor product docs). First sweep due ~November 2026
- **Model-update rerun:** default-model change → re-run all benchmarks (skill-creator comparison mode)

## Backlog — build only when the trigger fires (handoff §3)

| Skill | Trigger |
|---|---|
| `wimse-workload-identity` | agents run server-side (WIT/WPT, SPIFFE) |
| `fapi2-baseline` | a high-assurance security profile is being written |
| `delegation-mandate-precedents` | a formal delegation-mandate artefact is required for the target programme |
| `wallet-issuance-presentation` | the target identity scheme is wallet-based (OpenID4VCI/VP, HAIP) |

---

## Sprint plan

Sprints operationalize the phases: **one sprint = one skill through the full pipeline, ending in a push.** Sprints are scope-boxed, not time-boxed (consistent with the no-calendar decision) — a sprint ends when its exit criteria pass, however many sessions that takes.

### The standard sprint (template for every skill sprint)

1. **Scope** — Stage 0: description + `when_to_use` + covers/does-not-cover; disjointness check against shipped siblings
2. **Acquire** — Stage 1: fetch primary sources to scratch (canonical hosts, plain-text formats), record revisions + content hashes in `_source.md`
3. **Extract** — Stage 2: reference files; QA **V1** (adversarial check + blind re-extraction) over field tables
4. **Checklist** — Stage 3: assertions with IDs/severity; **V1** over assertions + **V2** three-sweep coverage map — no `MISSED`
5. **Assemble** — Stage 4: SKILL.md (pinned-versions banner, role directive, checklist early, QA stamp); **V5** artifact consistency + **V6** typed-content labels; staleness injection wired
6. **Test** — Stage 5: evals + probe bank + source-derived mutations + drift-simulation, on default model + Haiku; with/without-skill benchmark
7. **Compose** — Stage 6: composition test with the skill's recorded persona pair, fresh sessions
8. **Ship** — Stage 7: human sign-off on CRITICAL+ and audit sample; `validate-suite.sh` green; CHANGELOG + progress tracker updated; **`git commit` + `git push origin main`**

**Sprint exit criteria (all sprints):** playbook definition of done fully checked · QA verification report present with stamps · tracker + CHANGELOG updated · pushed to origin. *An unpushed skill is an unfinished sprint.*

### Sprint-by-sprint

| Sprint | Delivers | Beyond the standard template | Est. sessions (incl. QA) |
|---|---|---|---|
| **1** | `agent-credentials-grants` | Opens by **committing + pushing the governance baseline** (docs from 2026-08-05, currently uncommitted). Foundations built alongside: `.claude/skills/` (restart session after creating), skill-creator install, scratch layout, `staleness.sh`, validator grown to green, advisory CI workflow. Ends with **⛳ Checkpoint 1** (shape review — amend playbook if needed) | 4–6 |
| **2** | `mcp-authorization` | Set up the **automated sweep trigger** (QA strategy Layer 4) now that a shipped skill exists to maintain; wire the incident loop | 3–4 |
| **3** | `a2a-protocol` | Schema walk (V2 sweep 3) gets its first heavy workout — AgentCard/protobuf constraints | 3–4 |
| **4** | `agent-delegation-drafts` | Expect mid-sprint draft revisions: use the hash-mismatch **fork** procedure, don't block | 3 |
| **5** | `revocation-signals` | Ends with **⛳ Checkpoint 2** (layer consistency sweep: disjointness, duplication-citation audit, cross-skill conflicts, full validator run) | 3–4 |
| **6** | `agentic-architecture-review` | Opens with the **judgment-template decision** (question round: duplicate-vs-cite sibling IDs, `$ARGUMENTS` contract, inline vs fork). Fixtures include one flawed design per canonical failure class. Ends with **⛳ Checkpoint 3** (handoff acceptance §10.6–8) | 3–4 |
| **7** | `openclaw-runtime` | Short `recheck-days` on all sources; product-doc volatility | 3 |
| **8** | `enterprise-iam-deployment` | Every capability claim verified against live product docs (P12); every "how" mapped to a protocol skill's "what" | 3–4 |
| **9** | Packaging milestone | No new skill. Decisions due: plugin/marketplace naming, contribution rules. `.claude-plugin/plugin.json` + marketplace; re-run all evals from a clean plugin install; namespace re-test; teammate onboarding note; first full automated-sweep verification | 2 |

## Progress tracker

| # | Skill | Phase | Sprint | Status |
|---|---|---|---|---|
| 1 | agent-credentials-grants | 1 | 1 | not started |
| 2 | mcp-authorization | 2 | 2 | not started |
| 3 | a2a-protocol | 2 | 3 | not started |
| 4 | agent-delegation-drafts | 2 | 4 | not started |
| 5 | revocation-signals | 2 | 5 | not started |
| 6 | agentic-architecture-review | 3 | 6 | blocked on Checkpoint 2 + template decision |
| 7 | openclaw-runtime | 4 | 7 | not started |
| 8 | enterprise-iam-deployment | 4 | 8 | not started |
| — | plugin packaging | 5 | 9 | blocked on Sprint 8 |

Total estimate: **12–16 authoring sessions** across phases 1–4, plus the packaging milestone — and roughly as much again for accuracy QA per `docs/qa-strategy.md` (dual verification, coverage walks, mutations). Accuracy over token cost is the accepted stance; the QA stamp in each skill's banner keeps any deferred verification honest. Update this table (and CHANGELOG.md) as skills ship.
