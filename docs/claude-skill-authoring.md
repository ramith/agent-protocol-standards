# Claude Code Skill Authoring Reference

**Sources:** https://code.claude.com/docs/en/skills.md (fetched 2026-08-05), platform.claude.com Agent Skills docs, agentskills.io (Agent Skills open standard), github.com/anthropics/skills, github.com/anthropics/claude-plugins-official (skill-creator).
**Re-check trigger:** before relying on any version-gated behavior noted below, re-fetch skills.md and diff.

This is the authoring ground truth for building the `agentic-identity` suite (see `agentic-identity-skills-handoff.md`). Facts below were extracted from the live docs, not recalled.

---

## 1. Anatomy

A skill is a directory with `SKILL.md` as the required entrypoint:

```
my-skill/
├── SKILL.md           # required: frontmatter + instructions
├── reference.md       # loaded on demand
├── examples/          # loaded on demand
└── scripts/           # executed, not loaded into context
```

Claude Code skills follow the **Agent Skills open standard** (agentskills.io) and extend it with invocation control, subagent execution, and dynamic context injection.

`.claude/commands/*.md` flat files still work, support the same frontmatter, and create the same `/name` command — but folders are recommended (supporting files, progressive disclosure). If a skill and a command share a name, **the skill wins**.

## 2. Frontmatter reference (complete, as of 2026-08-05)

All fields optional; only `description` is recommended. Booleans accept `true/false/yes/no/on/off/1/0` (≥ v2.1.218).

| Field | Behavior |
|---|---|
| `name` | **Display label only** for personal/project skills — the command name comes from the *directory name*. For plugin skills, `name` sets the last segment of `/plugin:name`. |
| `description` | What the skill does AND when to use it. Drives model-invocation. If omitted, first paragraph of body is used. `description` + `when_to_use` truncated at **1,536 chars** in listings. |
| `when_to_use` | Extra triggering context (trigger phrases, example requests). Appended to description; counts toward the 1,536 cap. |
| `argument-hint` | Autocomplete hint, e.g. `[issue-number]`. |
| `arguments` | Named positional args for `$name` substitution, e.g. `arguments: [issue, branch]` → `$issue`, `$branch`. |
| `disable-model-invocation` | `true` → only the user can invoke (`/name`); description removed from Claude's context entirely. Use for side-effectful workflows (deploy, commit). |
| `user-invocable` | `false` → hidden from `/` menu; only Claude invokes. Use for background knowledge that isn't an action. |
| `allowed-tools` | Tools pre-approved **for the turn that invokes the skill** (grant clears on next user message). It does NOT restrict other tools. Supports `${CLAUDE_SKILL_DIR}` in Bash rules (≥ v2.1.129) so bundled scripts run without prompts. |
| `disallowed-tools` | Tools removed from the pool while the skill is active (clears next message). |
| `model` / `effort` | Per-turn model/effort override while the skill is active. |
| `context: fork` | Run the skill in an isolated subagent; SKILL.md content becomes the subagent's prompt. |
| `agent` | Subagent type for `context: fork` (`Explore`, `Plan`, `general-purpose`, or any custom agent from `.claude/agents/`). Default: `general-purpose`. |
| `background` | With `context: fork`: `false` = block the turn and wait (default `true` = run in background; ≥ v2.1.218). |
| `hooks` | Hooks scoped to the skill's lifecycle. |
| `paths` | Glob patterns; skill auto-loads only when working on matching files. |
| `shell` | `bash` (default) or `powershell` for `` !`cmd` `` injection. |

Open-standard fields also seen in anthropics/skills: `license`, `metadata` (informational).

### String substitutions

| Token | Meaning |
|---|---|
| `$ARGUMENTS` | Full argument string. If absent from body, args appended as `ARGUMENTS: <value>`. |
| `$ARGUMENTS[N]` / `$N` | 0-based positional arg (shell-style quoting: `"hello world"` is one arg). Unmatched index stays literal. |
| `$name` | Named arg from `arguments:` frontmatter. Unmatched name → empty string. |
| `${CLAUDE_SKILL_DIR}` | Directory containing SKILL.md — use to call bundled scripts location-independently. |
| `${CLAUDE_PROJECT_DIR}` | Project root (≥ v2.1.196). |
| `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}` | Session ID / effort level. |

Escape a literal `$` before a digit/`ARGUMENTS`/arg-name with `\$`.

### Dynamic context injection

`` !`command` `` (inline, `!` must follow start-of-line or whitespace) and ```` ```! ```` fenced blocks run shell commands **before** Claude sees the content; output replaces the placeholder. Single pass, output not re-scanned. Disable org-wide with `"disableSkillShellExecution": true`. Include the word `ultrathink` in a skill body to request deeper reasoning when it runs.

## 3. Locations, precedence, discovery

| Level | Path | Scope |
|---|---|---|
| Enterprise | managed settings | whole org |
| Personal | `~/.claude/skills/<name>/SKILL.md` | all projects |
| Project | `.claude/skills/<name>/SKILL.md` | this project |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | namespaced `/plugin:name` |

On a name collision: **enterprise > personal > project**; any of these overrides a bundled skill; plugin skills are namespaced so never collide. (Note: this is the opposite of what most people assume — personal beats project.)

- Project skills load from cwd **and every parent up to the repo root**.
- Nested `.claude/skills/` below cwd load lazily when Claude touches files in that subtree; collisions get directory-qualified names (`apps/web:deploy`).
- `--add-dir`/`/add-dir` load skills from added dirs; the `additionalDirectories` *setting* does not.
- Skill dirs can be **symlinks**; live change detection picks up SKILL.md edits mid-session (new top-level dirs need a restart).
- Cloud/Cowork sessions don't read `~/.claude/skills/` — commit skills to the repo's `.claude/skills/` or enable them on claude.ai.
- A skill folder with `.claude-plugin/plugin.json` loads as a plugin (`<name>@skills-dir`) and can bundle agents/hooks/MCP.

## 4. Progressive disclosure and context lifecycle

Three levels: (1) name+description always in context (~dozens of tokens each, 1,536-char cap); (2) SKILL.md body loads on invocation; (3) supporting files load only when Claude reads them; scripts execute without their code entering context.

Lifecycle facts that shape authoring:

- Invoked skill content **persists in context for the rest of the session** — every line is a recurring token cost. Write standing instructions, not one-time steps.
- Re-invocation with identical rendered content adds a "already loaded" note, not a duplicate (≥ v2.1.202).
- On auto-compaction, each invoked skill is re-attached keeping its first **5,000 tokens**, within a combined **25,000-token** budget, most-recent first — older skills can drop entirely.
- Keep SKILL.md **under 500 lines**; push bulk to `references/`. Keep references one level deep; give files >100 lines a table of contents (partial reads happen).

## 5. Invocation control matrix

| Frontmatter | User invokes | Claude invokes | Description in context |
|---|---|---|---|
| (default) | yes | yes | always |
| `disable-model-invocation: true` | yes | no | no |
| `user-invocable: false` | no | yes | always |

Permission rules can gate the Skill tool: `Skill(name)` exact, `Skill(name *)` prefix. `skillOverrides` in settings (`on` / `name-only` / `user-invocable-only` / `off`) controls visibility without editing shared skill files — but does not affect plugin skills.

Stacking: `/skill-a /skill-b args` loads up to six inline skills; trailing text goes to each as `$ARGUMENTS`. A forked skill ends the stack.

## 6. Running in a subagent (`context: fork`)

- SKILL.md content becomes the subagent's **task prompt**; no conversation history crosses over. Only meaningful for skills with explicit task instructions, not passive guidelines.
- Runs in background by default (≥ v2.1.218); backgrounded forks get a narrower tool set and their edits bypass checkpoints (`/rewind` won't undo — use git). `background: false` to block and keep the full tool set.
- `agent: Explore`/`Plan` skip CLAUDE.md for a lean context.
- Inverse composition: a custom subagent can **preload skills** via its `skills` field — full skill content injected at startup (this is how persona+skill pairing works mechanically).

## 7. Description writing

Formula: **[what it does]. Use when [specific triggers, in the user's vocabulary].** Third person, concrete keywords, ≤1,024 chars per the open standard (1,536 combined cap in Claude Code listings). Put the key use case first — truncation is real.

For the agentic-identity suite: invocation is explicit/manual (`@persona use <skill>`), so optimize for **disjointness between siblings**, not trigger aggressiveness. If a skill misfires, tune `description`/`when_to_use` (or add "not when..."), never the persona.

## 8. Scripts in skills

- Claude runs them via Bash from the skill dir; only stdout/stderr enter context.
- Reference them as `${CLAUDE_SKILL_DIR}/scripts/foo.sh` and mirror that in an `allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/foo.sh *)` rule for prompt-free execution.
- Handle errors inside the script; state execution intent ("Run X to…" vs "See X for…").
- Environment differs by surface: Claude Code = full network; Claude API code execution = no network, no package installs; claude.ai = admin-dependent.

## 9. Evaluate and iterate (skill-creator)

Install: `/plugin marketplace add anthropics/claude-plugins-official` then `/plugin install skill-creator@claude-plugins-official`.

Core discipline: **triggering and output quality are separate measurements.** Baseline-compare realistic prompts in fresh sessions with the skill enabled vs disabled (`skillOverrides: off`).

skill-creator automates: test cases in `evals/evals.json` inside the skill dir; isolated subagent runs; assertion grading → `grading.json`; with/without benchmark → `benchmark.json` (pass rate vs token/time overhead); blind A/B between skill versions; description tuning (should-trigger / should-not-trigger hit rates); HTML review viewer. Eval format: https://agentskills.io/skill-creation/evaluating-skills.

For this suite, the composition test from the handoff (§6.4) is the acceptance bar: pair the skill with a coding persona and a reviewer persona and check the validation checklist survives into the output.

## 10. Sharing

- **Project:** commit `.claude/skills/` (fits this repo — cloud sessions also pick these up).
- **Plugin:** `skills/` dir + `.claude-plugin/plugin.json` (`name`, `description`, `version`) → `/plugin-name:skill-name`; distribute via a marketplace repo. Right target for the `agentic-identity` namespace once the suite stabilizes.
- **Managed:** org-wide via managed settings.
- **claude.ai / API:** separate uploads (zip of the skill folder; API `/v1/skills` beta) — no cross-surface sync.

## 11. Decision table: skill vs the alternatives

| Need | Use |
|---|---|
| Knowledge/procedure needed *every* task | CLAUDE.md |
| Knowledge/procedure needed *sometimes* | Skill (this suite) |
| Isolated investigation with its own context/tools | Subagent |
| Deterministic behavior at an event | Hook |
| External service integration | MCP |
| Bundle skills+agents+hooks for distribution | Plugin |

## 12. Environment notes for this suite (verified 2026-08-05)

- Local environment: personas are flat `.md` subagents in `~/.claude/agents/` (with `tools:` frontmatter); existing commands in `~/.claude/commands/`; **no skills dirs yet** — nothing constrains us to flat files. Build folder skills in this repo's `.claude/skills/`.
- Persona+skill pairing has two mechanical forms: (a) explicit `@persona use <skill>` in chat, (b) adding a `skills:` preload field to the subagent's frontmatter so the full skill content is injected at the subagent's startup. Option (b) is the robust form for the composition test.
