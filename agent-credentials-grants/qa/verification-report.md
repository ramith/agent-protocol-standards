# Verification Report — agent-credentials-grants

Per `docs/qa-strategy.md`. This report accumulates per stage; the checklist (Stage 3) section is added when that gate runs.

## Stage 2 — reference-file verification (V1 dual pass) — 2026-08-05

**Method.** Seven adversarial verifiers (V1-A: independent sessions instructed to refute, every verdict quoting exact source text) + seven blind re-extractors (V1-B: read only the raw hash-pinned specs, never the reference files) + a consolidated diff of B-output against the reference files. Ground truth: the hash-pinned copies registered in `references/_source.md`. Full evidence: `qa/v1a-*.md`, `qa/v1b-*.md`, `qa/v1b-diff.md`.

**V1-A results (pre-triage):**

| Reference file | Claims | VERIFIED | UNSUPPORTED | CONTRADICTED | AMBIGUOUS |
|---|---|---|---|---|---|
| token-exchange.md | 76 | 69 | 2 | 0 | 5 |
| rich-authorization.md | 58 | 57 | 0 | 0 | 1 |
| step-up.md | 45 | 43 | 0 | 0 | 2 |
| dpop.md | 139 | 137 | 1 | 0 | 1 |
| audience-binding.md | 52 | 46 | 0 | 0 | 6 |
| client-auth.md | 133 | 129 | 0 | 0 | 4 |
| grant-management.md | 79 | 77 | 0 | 0 | 2 |
| **Total** | **582** | **558** | **3** | **0** | **21** |

**V1-B blind-control diff:** all 7 pairs CLEAN — 0 MISMATCH, 0 LEVEL-SHIFT, 0 NAMING, 1 minor GAP (IANA A.2 capitalized-MUST context for `grant_management_action_required`, since added).

**Triage (2026-08-05):** every UNSUPPORTED/AMBIGUOUS finding and the GAP fixed — 29 edits across 9 files, each anchored to the source quote in the corresponding report; per-finding FIXED records appended to each `v1a-*.md` under `## Triage 2026-08-05`. Unsupported editorial claims were deleted or relabeled `Guidance — ours, not spec:`. One deliberate no-change (pitfalls.md ID1 summary line — accurate as stated; provenance caveat lives in grant-management.md's Source line).

**Gate verdict: PASS.** Zero contradictions; zero mismatches in the blind control; all precision findings remediated.

**Not verified at this stage:** the SKILL.md body (no checklist exists yet — Stage 3); artifacts.md's composite delegated-token example beyond its per-field citations (checked at V5, Stage 4); live IANA registry state; sources beyond the pinned revisions.

**Post-triage file hashes (freshness anchors — the validator compares these against current files):**

```
SKILL.md sha256: e077c1d5eb37dcd103196d83cab55044204db879306eeda860900700cdf6ec72
references/_source.md sha256: 82fe0dddf8510e01325eab054266b63a042451c4ebcdc27ebfbe0494a04c9d2a
references/artifacts.md sha256: 904b17544f133530511c3eeedcfe98b96c26ee8e9f0fdcef3936575a35e1db49
references/audience-binding.md sha256: 8be2b58068eb52dcd1d1a59bdd6e60e9f484755d05fd0c452de169da9db0a3a8
references/client-auth.md sha256: 3064c4444141e1a95f2961a29f045525908ee5e0efbbbe701cda8c7e6c941510
references/dpop.md sha256: 20a8c1b392b585d928c06df3dc065e7c556329629d0ad651cef77987c005c7f5
references/grant-management.md sha256: bb8ef0fdd0cdd40b0d5d4d0c02d6132ec8ef9b8657cd141f63bf38c0e75ded13
references/pitfalls.md sha256: 13f1d9573ef14fec18ca857db8af79540d746587d0aaa5ee980e3814c14ba0e4
references/rich-authorization.md sha256: bf8deeab606cc7fab1a94a5b90ce666bb783669acaacb23ed7e1b8ffcceae4b1
references/step-up.md sha256: c82be9a59d4326f379472a51860c124f1aa62bcd8930b52bb90bef2977798a9c
references/token-exchange.md sha256: bc1a8ee3d7a816fc9654b221dcd41621349f187874c6c8b4549c22942b78de35
```

Note: SKILL.md's hash will legitimately change at Stage 4 (body assembly); this section's reference-file hashes remain the Stage 2 anchors, and the Stage 3/4 sections will record their own.
