# agent-protocol-standards

A suite of Claude Code skills that encode the open standards for **agent identity, delegation, agent-to-agent communication, and agent-to-tool authorization** — so that AI personas can verify, formulate, implement, and security-test agentic architectures against what the specs actually say, instead of plausible-but-wrong recall.

**Status:** design phase complete (2026-08-05); building skill 1 of 8 (`agent-credentials-grants`) next.

## Why this exists

The standards in scope (RFC 8693 token exchange, MCP authorization, A2A, SSF/CAEP, the IETF agent-delegation drafts) are new, fast-moving, and exactly the material where an LLM fabricates specifics — claim names, event-type URIs, delegation nesting order. Each skill replaces fabrication with retrieval: primary-source field tables, copyable artifacts, and a testable validation checklist, with pinned spec revisions and drift disclosure.

## The suite (three layers)

| Layer | Skills | Role |
|---|---|---|
| Knowledge | `agent-credentials-grants` · `agent-delegation-drafts` · `mcp-authorization` · `a2a-protocol` · `revocation-signals` | What the specs say — facts, artifacts, validation checklists |
| Judgment | `agentic-architecture-review` | Turns spec facts into design verdicts with severity |
| Deployment | `openclaw-runtime` · `enterprise-iam-deployment` | How to realize the patterns on specific stacks |

## Documentation map

Read in this order:

1. [agentic-identity-skills-handoff.md](agentic-identity-skills-handoff.md) — the original brief: objectives, design philosophy, per-skill build briefs, spec URL reference. *Some sections superseded — see the status note at its top.*
2. [docs/build-decisions.md](docs/build-decisions.md) — the locked design decisions (D1–D9) and their rationale.
3. [docs/skill-development-playbook.md](docs/skill-development-playbook.md) — **binding** for every skill: principles P1–P11 with violation tests, the seven stage gates, templates, assertion-ID registry, and the definition of done.
4. [docs/claude-skill-authoring.md](docs/claude-skill-authoring.md) — Claude Code skill platform mechanics, verified against live docs (frontmatter, loading, evals, distribution).
5. [docs/roadmap.md](docs/roadmap.md) — phases, checkpoints, the sprint plan (one skill per sprint: build → test → commit → push), and the status tracker.
6. [docs/qa-strategy.md](docs/qa-strategy.md) — **binding** accuracy QA: how every skill is verified against the standard it codifies (dual verification, coverage walks, fabrication probes, mutation tests, honest QA stamps). Adversarially reviewed via red team + pre-mortem.

## Using the skills

Clone the repo and start Claude Code anywhere inside it — skills in `.claude/skills/` load automatically. The primary pattern pairs a persona with a skill:

```
@architect-reviewer use agent-credentials-grants to review the token flow
@golang-pro use mcp-authorization to implement the resource-server token validation
```

Review findings and generated code cite assertion IDs (e.g. `ACG-007`). Every skill shows its **pinned standard revisions** in a banner; if a newer spec revision exists, you'll be told and you choose whether to proceed. Full consumer guide: playbook Part 5.

## Contributing a skill

Follow the playbook's stage gates (Part 3) — a skill that skips a gate doesn't ship. Every skill pins exact spec revisions, carries its own evals with fixtures, and passes `scripts/validate-suite.sh` locally before it lands. Changes are recorded in [CHANGELOG.md](CHANGELOG.md).

## Acknowledgements

The bundled [the-fool](.claude/skills/the-fool/) skill (structured adversarial review) is from [jeffallan/claude-skills](https://github.com/jeffallan/claude-skills), MIT-licensed; it was used for the red-team + pre-mortem review of the QA strategy.
