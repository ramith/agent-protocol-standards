# QA Strategy — Skill Accuracy Against the Standards They Codify

**Status:** v1.0, binding. Adversarially reviewed 2026-08-05 (the-fool: red team + pre-mortem); all identified defenses and mitigations integrated.
**Scope:** validating that a skill's *content* faithfully represents the standard/protocol it codifies. Behavioral quality (triggering, persona usage) is covered by the playbook's evals; this document covers **factual fidelity**.
**Cost stance:** accuracy is explicitly prioritized over token cost (standing project directive, 2026-08-05). Verification redundancy is never trimmed to save tokens. The scarce resource is human review time; the strategy concentrates it where machine passes are weakest.

---

## 1. Threat model — how inaccuracy gets in

| # | Failure mode | Example |
|---|---|---|
| T1 | Transcription error | field table misplaces `may_act` |
| T2 | Fabrication during authoring | an event URI filled in from recall |
| T3 | Meaning drift in paraphrase | MUST softened to SHOULD; scope condition dropped |
| T4 | Omission | a normative requirement never extracted |
| T5 | Overreach | our MAY→MUST hardening advice presented as spec-required |
| T6 | Internal inconsistency | example artifact violates the skill's own checklist |
| T7 | Context distortion | rule true in spec context, generalized wrongly (`act` nesting) |
| T8 | Staleness | spec revised after extraction (P11 handles disclosure; the mechanism itself must be tested) |
| T9 | **Ground-truth substitution** | verification runs against a mangled/mirrored/wrong fetch — HTML→markdown table mangling is the sharpest case |
| T10 | **Correlated verifier error** | two same-model verifiers misread confusing prose the same way; redundancy without independence |
| T11 | **Unverified connective prose** | advisory glue text between assertions carries an error no pass examines |

## 2. QA architecture — four layers

### Layer 1 — Provenance discipline (prevention, already binding)
Extracts-only (D8), every fact cited to URL + section + fetch date, `_source.md` register, exact reproduction of names/schemas (P7), uncertainty resolved online, never by recall (P12). Prevention only — the layers below assume it can fail.

### Layer 2 — Verification passes (detection; the core)

**Ground-truth integrity (precondition for everything below, → T9).**
- Fetch from canonical hosts only (the handoff §8 URL register). Prefer immutable plain-text formats over HTML→markdown: `rfc-editor.org/rfc/rfcXXXX.txt` for RFCs, datatracker `.txt` for drafts.
- Record a content hash per scratch copy in `_source.md` at extraction time. Every QA run re-fetches and compares hashes **before any verdict counts**.
- Hash mismatch is a **fork, not a blocker**: the source revised. Finish verification against the pinned copy (that is what pinning means), and queue the revision diff as immediate maintenance. Treating mid-run revision as an error is how hash-checking gets quietly abandoned on fast-moving drafts.

**V1. Reverse verification — every assertion, structurally de-correlated (→ T1, T2, T3, T10).**
Two independent verifier sessions per assertion, with **different tasks**, not two copies of the same check:
- **Verifier A (assertion check):** given the assertion and its citation, fetch the pinned source text and judge: `VERIFIED` / `UNSUPPORTED` / `CONTRADICTED` / `AMBIGUOUS`. Framed adversarially ("find the error"), never confirmatively.
- **Verifier B (blind re-extraction):** given *only* the source section — never our assertion — write the assertions that section supports. A separate diff step compares B's output against ours. B cannot confirm what it never saw; this is real independence within one model family.
- Any A/B disagreement escalates to a third session plus human review.
- Verdicts must quote the exact source text they rest on — evidence-bearing, human-auditable without redoing the work.
- `AMBIGUOUS` triggers an errata check (RFC errata, the spec repo's issues); unresolved ambiguity becomes a "spec ambiguity" note *in the skill* — ambiguity is information.
- Output: `qa/verification-report.md` in the skill directory, which records the content hash of SKILL.md and each reference file at verification time, and lists what was **not** verified. Any `CONTRADICTED` or `UNSUPPORTED` blocks shipping.

**V2. Coverage verification — hunting omissions from three inputs (→ T4).**
Within the skill's declared "covers" boundary, enumerate the source's requirements from **three sweeps** — RFC 2119 keywords are a floor, not the method:
1. Keyword sweep (MUST / MUST NOT / SHALL / SHOULD / REQUIRED);
2. Declarative-requirement sweep (specs bind behavior without keywords: "the server rejects…", "the value is computed as…");
3. **Schema walk** — required fields, enums, and constraints in the spec's JSON Schema / protobuf / ABNF, where MCP and A2A carry much of their normative load.

Each requirement is classified `EXTRACTED` (→ assertion ID or reference section) / `EXCLUDED` (reason from a **fixed taxonomy**: out-of-declared-scope, transport detail, non-security editorial, superseded text) / `MISSED`. Any `MISSED` blocks shipping. `EXCLUDED` entries get their own human audit sample — the escape valve is itself audited.

**V3. Fabrication probes (→ T2) — the standing probe bank.**
Per-skill probes designed to elicit invention: plausible-but-nonexistent claim names, event URIs one token off from real ones, cross-spec traps ("what does RFC 8693 say about `authorization_details`?" — that's RFC 9396). Pass = cite-or-refuse. Probes live in `evals/evals.json` tagged `probe` and rerun with every eval run. Every real-use wrong answer adds a probe (see Layer 4) so the bank grows away from teaching-to-the-test.

**V4. Mutation testing — all assertions, mutations authored from the source (→ T3, T7).**
For each assertion, a mutated fixture that violates the *real* rule while satisfying a plausible *misreading*. **Mutations are authored by the blind re-extractor (Verifier B) from the source text, before it ever sees our checklist** — a mutation derived from the assertion would encode the author's own misunderstanding and then "pass". The review-shaped eval must catch every mutation. Full scope: accuracy over token cost.

**V5. Cross-artifact consistency (→ T6).**
Every copyable artifact in `references/artifacts.md` is checked against the skill's own checklist — the example JWT must pass every assertion that applies to it. Mechanized where possible in the validator (parse JSON artifacts, check required claims); verifier-session pass for the rest.

**V6. Typed content discipline (→ T11).**
Skills contain two classes of sentence and must say which is which. Extracted spec fact is the default; anything advisory or synthesized is explicitly marked **`Guidance — ours, not spec:`**. The validator flags unlabeled prose paragraphs in reference files; unmarked prose is in V1's scope and will fail as `UNSUPPORTED` if it asserts spec facts without citation. Readers must never have to guess which sentences were verified.

### Layer 3 — Human review (judgment machine passes can't replace)
- **High-severity sign-off:** every BLOCKER/CRITICAL assertion human-reviewed against the quoted evidence before first ship. This is where T5 (overreach) is caught — whether "we recommend MUST" is honestly labeled is a judgment call.
- **Audit sampling:** per QA run, spot-audit a random 10% of `VERIFIED` verdicts and a sample of `EXCLUDED` coverage entries by reading the quoted source. **A failed audit reruns the failing verifier's batch** (that session's verdicts), not the entire pass — a rule too expensive to obey becomes a dead letter.

### Layer 4 — Continuous accuracy (post-ship)
- **QA status is visible in the skill itself (anti-erosion):** the SKILL.md banner carries a stamp — `QA: 41/41 assertions verified (2026-08-20)` or `⚠ QA: UNVERIFIED / PARTIAL (see qa/verification-report.md)`. Shipping unverified is *possible* under pressure but never *silent*, and the validator maintains a suite-wide **verification-debt register**. There is a degraded mode, and it is honest.
- **Verification freshness is mechanical:** the validator compares the hashes recorded in the verification report against current files. Any post-verification edit flips the skill to "verification stale" — visibly, in the stamp and the validator output.
- **Automated sweep trigger:** a scheduled routine (not a human's memory) runs the staleness checks and `latest-url` diffs on the fast movers and files the diff report; the human acts on diffs only. The validator additionally warns when any source's age exceeds `recheck-days + 30` — the sweep's own death is detectable.
- **Drift protocol (P11) is itself tested:** each skill's evals include a drift-simulation case (artificially old pin in a fixture; the skill must disclose).
- **Incident loop:** every real-use wrong answer becomes (a) a fix, (b) a new probe in the bank, (c) a CHANGELOG entry. Wrong answers are the cheapest QA signal we get.

## 3. Independence rules

- Verifier sessions never share context with the authoring session, or with each other.
- Verifier B (blind re-extraction) never sees the assertion, the checklist, or the skill — only source text.
- All verification is retrieval-anchored against hash-checked pinned copies: a textual check, not a knowledge check.
- Residual risk — same model family misreading genuinely ambiguous prose identically in *both* the A-check and the blind re-extraction — is mitigated by the human audit and the errata step, and accepted beyond that. It is listed in §6, not hidden.

## 4. Integration with the playbook gates

| Playbook stage | This strategy adds |
|---|---|
| Stage 1 | canonical-host + plain-text-format fetch rules; content hashes into `_source.md` |
| Stage 2 gate (was: spot-check 5 field names) | **upgraded:** full V1 (A + B) over field tables |
| Stage 3 gate | V1 over assertions + V2 three-sweep coverage map — no `MISSED`, no `CONTRADICTED`/`UNSUPPORTED` |
| Stage 4 | V5 consistency pass; V6 typed-content labels present |
| Stage 5 | V3 probe bank; V4 source-derived mutations; drift-simulation case |
| Stage 7 / DoD | verification report present with hashes; QA stamp in banner; human sign-off on CRITICAL+; audit sample passed |
| Part 6 maintenance | automated sweep trigger; hash-mismatch fork procedure; incident loop |

## 5. What this strategy does not guarantee

- That the *spec itself* is right, unambiguous, or complete — only fidelity to it.
- That a persona *applies* a correct assertion correctly (composition evals cover application, imperfectly).
- Immunity to the residual correlated-misreading risk on genuinely ambiguous prose (§3) — mitigated, sampled, not eliminated.
- Anything about sources that could not be fetched — those are flagged, never trusted.
- Its own execution: the strategy holds only while the stamps, hashes, and automated sweeps stay wired into the validator. That wiring is itself part of skill 1's definition of done.
