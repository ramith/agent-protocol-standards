# Changelog

All shipped changes per skill, with date and reason (required by playbook Part 6).

## 2026-08-05 — Design phase

- Added `docs/claude-skill-authoring.md`: Claude Code skill platform mechanics, extracted from live official docs.
- Added `docs/build-decisions.md`: locked design decisions D1–D9. D3 revised same day (plugin-from-day-one → project skills now, plugin at the suite milestone).
- Added `docs/skill-development-playbook.md`: binding principles (P1–P11), seven stage gates, anatomy templates, assertion-ID registry, eval protocol, consumer guide, definition of done.
- Updated `README.md` from stub to repo front door.
- Annotated `agentic-identity-skills-handoff.md` with a status note mapping superseded sections to the decision record.

- Added `docs/roadmap.md`: sequence-based roadmap — MCP pulled to second, sequential builds, validator grown during skill 1, three checkpoints, packaging milestone, quarterly maintenance, triggered backlog.
- Added `docs/qa-strategy.md` (v1.0, binding): accuracy QA with threat model T1–T11, verification passes V1–V6 (de-correlated dual verification, three-sweep coverage, fabrication probes, source-derived mutations, artifact consistency, typed content), human sign-off + audit sampling, QA stamps, automated sweep trigger. Adversarially reviewed with the-fool (red team + pre-mortem); all 9 defenses/mitigations integrated. Accuracy prioritized over token cost (standing project directive).
- Added playbook principle P12 (uncertainty resolves online, never from recall) and integrated QA gates into stages 1–7 and the definition of done.
- Added sprint plan to `docs/roadmap.md`: 9 scope-boxed sprints — one skill per sprint through the full pipeline (stages + QA + evals), each ending with commit + push to origin/main; Sprint 1 opens by committing the governance baseline.
- Pre-kickoff sweep: verified all five spec hosts reachable (plain-text RFC fetches work); confirmed skill-creator installable; caught that the on-behalf-of draft is expired at rev 02. Decision D10: repo stays public with sanitization discipline — all personal/vendor/engagement-specific language generalized (skills renamed `enterprise-iam-deployment`, `delegation-mandate-precedents`); the-fool committed with MIT attribution; `.gitignore` added.

No skills shipped yet. Next: `agent-credentials-grants` (knowledge layer, skill 1 of 8).
