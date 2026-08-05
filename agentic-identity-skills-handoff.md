# Agentic Identity Skill Suite — Build Handoff

> **Status note (added 2026-08-05).** This public copy is sanitized of engagement-specific context; examples are generic. The brief remains the source of truth for objectives, design philosophy, per-skill scope, and the spec URL reference. Build-process questions it left open have since been decided — see [docs/build-decisions.md](docs/build-decisions.md) (D1–D9) and the binding [docs/skill-development-playbook.md](docs/skill-development-playbook.md). Where this document and those two conflict, they win. Specifically superseded:
>
> - **§4 (uniform structure):** the validation checklist now lives in the SKILL.md body, not `references/validation.md` (D1); the anatomy adds `scripts/staleness.sh` and a required `evals/` directory with per-skill fixtures (D4, D7).
> - **§6.1 (packaging):** the `package_skill.py` → `.skill` flow is superseded. Skills ship as project skills in this repo's `.claude/skills/`; plugin packaging is a suite-level milestone (D3, revised). skill-creator is still used — for evals, not packaging.
> - **§6.5 (loader format):** question closed — the environment supports folder skills (`SKILL.md` + `references/`); folders it is.
> - **§9 (staleness):** extended from an author-side note to an enforced mechanism — machine-readable pins, invocation-time staleness banner, and consumer-facing version-drift disclosure with user choice (D5, playbook P11).
> - **§10 (acceptance criteria):** extended by the playbook's definition of done — per-skill evals (including a fabrication-bait case) are now a shipping requirement, and every checklist assertion carries a stable ID with severity.

**For:** Claude Code + VSCode implementation session
**Purpose:** Build a suite of reusable, composable skills that encode the open standards for agent identity, delegation, agent-to-agent communication, and agent-to-tool authorization — so that named agents/personas can invoke them to *verify* and *formulate* correct architecture, and to *implement* and *security-test* it across languages.

---

## 0. How to read this document

This is a plan plus rationale plus source-of-truth links. Sections:

1. Objectives and the mental model behind the design
2. Why the skills are shaped the way they are (read before building — the shape is the whole point)
3. The skill inventory (what to build)
4. Uniform internal structure every skill follows
5. Build order and why
6. The authoring workflow in Claude Code
7. Per-skill build briefs (scope, sources, what to extract, known pitfalls)
8. Complete spec/standard URL reference
9. Staleness and maintenance discipline
10. Acceptance criteria

Do not skip section 2. Every downstream decision follows from it.

---

## 1. Objectives

Four objectives, in priority order:

1. **Verify architectures.** Given a design (a diagram, an epic, a sequence of API calls), check it against what the standards actually require and flag gaps by severity.
2. **Formulate architectures.** Propose the correct design — token structures, flows, validation rules — grounded in the specs, not in recollection.
3. **Implement.** Feed language skills (Java, Go, Rust, Ballerina, C++, etc.) the exact spec facts — schemas, claim structures, validation checklists — so generated code is correct.
4. **Security-test.** Provide the same validation checklists as a testing rubric so security-testing personas can probe implementations against them.

The unifying insight: **the security design and the UX design and the implementation spec are the same design.** One validation checklist serves the reviewer, the coder, and the tester. That checklist is the load-bearing artifact of the whole suite.

### Why this suite exists at all

These standards are (a) new, (b) fast-moving, and (c) exactly the kind of material where an LLM will generate plausible-but-wrong specifics — inventing claim names, guessing event-type URIs, reversing the nesting order of a delegation chain. The suite's job is to **replace fabrication with retrieval**: the skill carries the actual spec text, field tables, and citations, so answers come from ground truth instead of memory.

Corollary: a skill full of prose summaries reproduces the exact problem it's meant to solve. The payload is primary-source facts, not paraphrase.

---

## 2. Design philosophy — read this before building

### 2.1 Three layers, composing downward

- **Knowledge layer** (consulted, never drives): the protocol reference skills. They answer "what does the spec actually say?" They expose spec facts, copyable artifacts, testable validation checklists, known pitfalls, and a source citation. They do not drive workflows and say nothing about how to write code.
- **Judgment layer** (drives review, consults knowledge): `agentic-architecture-review`. Encodes the reasoning — severity, anti-patterns, the confirm-to-commit pattern, the delegation-vs-access distinction. This is not derivable from any single spec.
- **Deployment layer** (drives implementation-shaped work, consults both): `openclaw-runtime`, `enterprise-iam-deployment`. Product/stack-specific "how," kept separate so the protocol skills stay vendor-neutral and reusable.

The user's existing third-party skills (coding, QA, UX, PM, security-testing) sit *above* this suite and consult it. They are not modified.

### 2.2 The suite is a knowledge base, not a workflow engine

Language and QA skills own *workflows* (drive a task start to finish). The protocol skills are a *knowledge layer* those workflows consult. The Go skill owns "write idiomatic Go"; `agent-credentials-grants` owns "the token must carry `cnf`, `act` must be present." Neither knows about the other. They compose because the reference skill exposes **language-neutral facts a coder can act on** — the same reference serves Java, Go, and Rust identically.

### 2.3 Invocation is explicit and manual — optimize accordingly

The user's workflow names both the agent and the skill:

```
@architect-reviewer use agent-credentials-grants to review the token flow for the payments feature
@modern-cpp-dev use mcp-authorization to implement the resource-server token validation
```

This is decisive. It removes the autonomous-triggering problem entirely. **Do not write "pushy" descriptions** designed to force auto-triggering — the user routes by name. Descriptions should be plain, accurate, and above all *disjoint*, so that when the user (or the agent) picks one, it's unambiguous which one.

Consequence: the acceptance test is **not** "does it trigger correctly." It is "when persona X is handed this skill, is the output spec-correct?"

### 2.4 Persona-neutrality

Each skill will be invoked by different personas — a reviewer, a C++ dev, a business analyst. It must be written as **persona-neutral domain fact**: a reviewer reads it to check, a coder reads it to build, a BA reads it to scope. The skill provides the fact; the persona decides what to do with it. Do not bake a single persona's framing into a knowledge skill.

### 2.5 Ruthless self-containment

Because skills are composed ad hoc and unpredictably, each must stand alone. It cannot assume its siblings are loaded. Cross-references take the form "if you also have `mcp-authorization` loaded, see it for token-passthrough rules" — helpful when present, harmless when absent. Each skill carries its own source citations and staleness note.

### 2.6 The validation checklist is the keystone

For each protocol skill, the single most valuable artifact is a checklist written as **discrete, verifiable assertions** — not prose. Example (not prose): "REJECT if `act` claim absent on an agent-facing endpoint." This one artifact is consumed three ways:

- the reviewer checks a design against it,
- the coder implements each assertion,
- the tester writes a probe per assertion.

Write these as if they will become unit tests, because they will.

---

## 3. Skill inventory

Plugin/namespace: **`agentic-identity`** (adjust to match the user's skill-loading convention).

### Knowledge layer (protocol references)

| Skill | Covers |
|---|---|
| `agent-credentials-grants` | Delegation/OBO token mechanics: RFC 8693 delegation-vs-impersonation, `act`/`may_act`, RFC 9396 Rich Authorization Requests, RFC 9470 step-up, CIMD (URL-as-client-id), `private_key_jwt` in the agent context, DPoP-bound tokens, OIDF Grant Management |
| `agent-delegation-drafts` | The competing IETF agent-delegation drafts and where they conflict: on-behalf-of, klrc aiagent-auth, transaction-tokens-for-agents, attenuating-agent-tokens |
| `mcp-authorization` | MCP as OAuth 2.1 resource server; Protected Resource Metadata; RFC 8707 `resource`; token-passthrough prohibition; the 2026-07-28 stateless/authorization changes; Enterprise-Managed Authorization |
| `a2a-protocol` | A2A v1.0: three-layer model (data/operations/bindings), AgentCard schema, signed Agent Cards (JWS + JCS), security schemes, the official extensions (Secure Passport especially) |
| `revocation-signals` | OpenID Shared Signals Framework, CAEP, RISC: SET structure, stream config, event types, subject formats — the mechanism for revocation propagation across relying parties |

### Judgment layer

| Skill | Covers |
|---|---|
| `agentic-architecture-review` | The verification checklist (generalized) + pattern library (the fixes) + severity model + "no standard exists here" register. References the knowledge-layer skills. |

### Deployment layer

| Skill | Covers |
|---|---|
| `openclaw-runtime` | OpenClaw gateway/node/skill/plugin trust model, config precedence, `security audit`, tool policy resolution, sandbox modes, the untrusted-code-with-durable-credentials threat model |
| `enterprise-iam-deployment` | How to realize the correct patterns on the enterprise IAM / API-management stack in use (agent-identity service, API manager / AI gateway, MCP proxy). References the protocol skills for correctness. |

### Optional / later (build once the core proves out)

- `wimse-workload-identity` — only if agents run server-side (WIT/WPT, SPIFFE relationship)
- `fapi2-baseline` — if writing a high-assurance profile
- `delegation-mandate-precedents` — EUDI ARF powers-of-representation position + India DEPA/ReBIT consent artefact; the only working prior art for a delegation artefact no standard defines.
- `wallet-issuance-presentation` — OpenID4VCI/VP, HAIP, SD-JWT VC, ISO 18013-5/-7 — only if the target identity scheme is wallet-based.

**Recommendation:** build the five knowledge skills + `agentic-architecture-review` first. Add the deployment skills next. Defer the optional set until the target delegation model and stack are confirmed.

---

## 4. Uniform internal structure

Every skill follows the same shape so the set is maintainable and composes predictably.

```
<skill-name>/
├── SKILL.md                 # navigation + judgment; keep well under 500 lines
└── references/
    ├── _source.md           # canonical URLs, revision/version consulted, fetch date, re-check trigger
    ├── <topic-1>.md         # field tables, normative requirements, short verbatim excerpts
    ├── <topic-2>.md
    ├── artifacts.md         # copyable schemas / claim structures / wire examples
    └── validation.md        # the testable-assertion checklist (the keystone artifact)
```

### SKILL.md body contains

- **Frontmatter:** `name`, `description` (plain and disjoint — see 2.3).
- **What this covers / what it does not.** Draw the boundary against sibling skills explicitly.
- **A table of contents** pointing into `references/`.
- **The 3–5 things most easily gotten wrong**, flagged as *"verify against reference, do not answer from recall."* (e.g. `act` nesting order; bearer-vs-`cnf`; impersonation-by-default.)
- **A staleness note** naming the revision consulted and pointing at `_source.md`.

### Content rules

- **Copyable artifacts, not prose.** The actual schema, the actual claim object, the actual discovery URL. A coder copies these.
- **Language-neutral**, with library pointers as a convenience note only (e.g. "Java: nimbus-jose-jwt; Go: lestrrat-go/jwx") — never as the skill's core.
- **Respect copyright when extracting.** Paraphrase specs; keep any verbatim quote short. Field names, parameter names, and schema keys are facts, not creative text — reproduce those exactly. Prose explanation should be reworded, with a link to the source.
- **Every reference file cites its source** at the top (URL + section + date).

---

## 5. Build order and rationale

Build **`agent-credentials-grants` first.** Reasons:

1. It is the highest-value and most-fabricatable domain (token/claim structures).
2. It is the hardest test of the composition model: can a reference skill hand a *coding* persona exactly the token-validation checklist and JSON — usable in Go/Java/Rust — without dragging in judgment-layer prose? If that shape works, every other knowledge skill copies it. Prove the riskiest assumption on skill one.

Then:

3. `a2a-protocol` and `mcp-authorization` — the two most-referenced specs, same template.
4. `agent-delegation-drafts` — the draft family (cross-references credentials-grants).
5. `revocation-signals` — the revocation-propagation mechanism.
6. `agentic-architecture-review` — the judgment layer, referencing all of the above.
7. `openclaw-runtime`, then `enterprise-iam-deployment`.

After skill 1 is built, **stop and validate the shape** with a real paired persona (see section 6.4) before replicating five times.

---

## 6. Authoring workflow in Claude Code

### 6.1 Use the skill-creator

If the skill-creator skill/plugin is available in the environment, use it — it encodes the draft → test → review → improve loop and the packaging step. Its key conventions:

- **Progressive disclosure:** metadata (name+description) always in context; SKILL.md body loaded on trigger; `references/` loaded only as needed. Keep SKILL.md lean and push bulk into references.
- **Description is the routing surface.** Here, because invocation is manual/named, prioritize *disjointness* over pushiness.
- **Package** with the skill-creator's `package_skill.py` to produce an installable `.skill` file.

### 6.2 Download specs locally for perusal

For each skill, fetch the primary source(s) into a scratch dir and read them properly before extracting. Do not codify from memory. Suggested scratch layout:

```
/tmp/spec-src/<skill-name>/
```

Fetch with `curl`/`wget` where the network config allows, or read via the browsing tool. Record exact retrieval URL and date — they go into `_source.md`.

> **Note on network access:** the Claude Code environment may restrict outbound domains. `datatracker.ietf.org`, `rfc-editor.org`, `openid.net`, `modelcontextprotocol.io`, and `a2a-protocol.org` must be reachable to fetch primary sources. If blocked, fetch via an allowed mirror or the browsing tool, and flag any source you could not retrieve directly so it can be verified later rather than trusted from recall.

### 6.3 Extract, don't summarize

For each source, pull out:

- **Field/parameter tables** — name, type, required/optional, meaning. Reproduce names exactly.
- **Normative requirements** — the MUST/SHOULD/MUST NOT list, rephrased concisely, each with a section reference.
- **Copyable artifacts** — schemas, claim structures, example requests/responses.
- **Known pitfalls** — the things implementers get wrong.
- **The validation checklist** — recast the normative requirements as testable assertions.

### 6.4 Validate the composition (the real acceptance test)

After building `agent-credentials-grants`, test it the way it will actually be used:

- Simulate `@<a-coding-persona> use agent-credentials-grants` on a task like *"implement OBO token validation."* Confirm the output takes idiom from the coding persona and **security requirements from the skill** — specifically that it produces the `cnf` check, the `act`-present check, the audience check, and rejects bearer tokens.
- Simulate `@<a-reviewer-persona> use agent-credentials-grants` on *"review this token design."* Confirm it flags the same items as findings.

If the coding persona's output ignores the checklist, the fix is in the skill's description/structure (make the verification role explicit), not in the persona. Find that on skill one.

### 6.5 Package and hand back

Package each skill as a `.skill` file (or the user's preferred single-`.md` form — confirm their loader). If their existing skills are flat single `.md` files (e.g. `ballerina-lang-bestpractices.md`), either (a) match that with references inlined into one file, or (b) confirm the loader accepts folders with `SKILL.md` + `references/`. Folders suit this content better via progressive loading; flat files may be a hard constraint. **Confirm this before building.**

---

## 7. Per-skill build briefs

### 7.1 `agent-credentials-grants` (BUILD FIRST)

**Scope:** everything needed to issue, structure, bind, and validate a delegated ("on-behalf-of") token for an agent acting for a user, plus how an agent authenticates as itself.

**Primary sources:**
- RFC 8693 Token Exchange — `act`, `may_act`, delegation vs impersonation
- RFC 9396 Rich Authorization Requests (RAR) — `authorization_details`
- RFC 9470 Step-up Authentication Challenge
- RFC 9449 DPoP — sender-constrained tokens (`cnf`/`jkt`)
- RFC 8707 Resource Indicators — audience binding
- RFC 7523 — `private_key_jwt` client authentication
- `draft-ietf-oauth-client-id-metadata-document` (CIMD)
- OpenID Grant Management for OAuth 2.0

**Extract:**
- The **delegation-vs-impersonation** distinction and how the presence of `actor_token` / the `act` claim selects it. State the rule: *agent-facing endpoints MUST NOT accept impersonation tokens.*
- The **`act` nesting rule** — outermost `act` is the current actor; nested are prior actors. This is reversed by implementers constantly. Include a worked multi-hop example.
- **`may_act`** — how it pins which agent may act for a subject (turns an ownership link into an AS-enforced constraint).
- The full **claim structure** for a delegated access token as a copyable JSON artifact: `iss`, `sub`, `act`, `client_id`, `aud`, `scope`, `cnf.jkt`, `authorization_details`, `acr`, `amr`, `auth_time`, `exp`, `jti`.
- The **token-exchange request** parameters (`grant_type`, `subject_token`, `actor_token`, `requested_token_type`, `resource`, `scope`).
- RAR `authorization_details` structure and the rule that the **submitted payload must validate against the grant**.

**Validation checklist (seed — expand from sources):**
- REJECT if signature invalid / `iss` not in trust store / `typ` not `at+jwt`.
- REJECT if `aud` ≠ this resource (exact match, no prefix/wildcard).
- REJECT if `exp`/`nbf`/`iat` outside skew, or `jti` seen before (replay).
- REJECT if `cnf.jkt` does not match the DPoP proof key thumbprint.
- REJECT if `act` absent on an agent-facing endpoint (no impersonation).
- REJECT if `act.sub` resolves to an unknown or suspended agent.
- REJECT if scope is not a subset of the grant (scope must narrow, never widen, across exchanges).
- REJECT if `authorization_details` absent on a write op, or if the request payload exceeds it.
- REJECT if `acr`/`amr` below the operation's assurance floor, or `auth_time` too old for the risk tier.
- Resource identity MUST derive from `sub`, never from a request parameter.
- For write ops: introspect, do not rely on local JWT validation alone.

**Known pitfalls:** bearer OBO tokens (no `cnf`); refresh tokens on write scopes; authorizing on `client_id` (public, forgeable) instead of `act.sub`; treating `act` as a log field only; exchanging without re-evaluating consent.

---

### 7.2 `a2a-protocol`

**Scope:** how agents discover each other and exchange tasks, and how that channel is secured.

**Primary sources:**
- A2A v1.0 specification — `https://a2a-protocol.org/latest/specification/`
- What's New in v1.0 — `https://a2a-protocol.org/latest/whats-new-v1/` (breaking changes vs 0.x)
- The A2A repo and extensions — `https://github.com/a2aproject/A2A`
- The official extensions, **Secure Passport** first (carries caller/user context across a hop — directly relevant to delegation)

**Extract:**
- The **three-layer model**: Layer 1 data model (AgentCard, AgentSkill, Task, Message, Part, Artifact, Extension — as Protocol Buffers / JSON Schema 2020-12); Layer 2 operations (SendMessage, SendStreamingMessage, GetTask, ListTasks, CancelTask, SubscribeToTask, push-notification config, Agent Card retrieval); Layer 3 bindings (JSON-RPC 2.0 over HTTPS primary, gRPC, HTTP/JSON/REST).
- The **AgentCard schema** — field by field (`name`, `description`, `url`, `provider`, `version`, `securitySchemes`, `skills`, signature, etc.). Reproduce field names exactly.
- **Signed Agent Cards** — JWS (RFC 7515) over JCS-canonicalized (RFC 8785) content. Note it is typically a MAY in-spec — recommend making it a MUST in any hardened profile.
- **Security schemes** declared in the card (OAuth2 authz-code+PKCE, device code, mTLS, API keys, OIDC).
- The **authenticated extended card** (`GetExtendedAgentCard`) — keep sensitive detail out of the public card.
- Normative security items, e.g. *servers must only return tasks visible to the caller.*
- The **known gaps**: no protocol-native admission/removal primitive; no human-escalation mechanism; per-skill body schemas, token downscoping, and registry standardization still need application-level workarounds.

**Validation checklist (seed):** verify card signature before trusting any card field; treat every card field as untrusted input even after signature verification (signing proves origin, not benignity); pin cards to a known-good signature/version; reject unsigned cards in a hardened profile; authorize on the immutable agent identity, never on `name`; enforce `PushNotificationConfig.authentication` and allowlist webhook destinations (SSRF).

**Known pitfalls:** Agent Card context poisoning (instructions in `description`/`skills` metadata); agent shadowing / tool squatting (lookalike names); treating signature as trust rather than provenance.

---

### 7.3 `mcp-authorization`

**Scope:** how an agent authenticates to a tool/resource server and how that server enforces authorization. **Pin to revision `2026-07-28`** (current final; note `2025-11-25` was prior).

**Primary sources:**
- MCP spec authorization — `https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization/`
- Security considerations — the token-passthrough prohibition
- The 2026-07-28 release notes — `https://blog.modelcontextprotocol.io/posts/2026-07-28/` (stateless core, deprecations, Enterprise-Managed Authorization now stable)
- `https://github.com/modelcontextprotocol`

**Extract:**
- **MCP server = OAuth 2.1 resource server** (not an authorization server).
- MUST publish **Protected Resource Metadata (RFC 9728)**; clients MUST send **RFC 8707 `resource`** in authorization and token requests.
- **Token-passthrough prohibition** — a server MUST NOT accept or forward a token not issued for it; to call upstream it obtains a new token for that audience. State this verbatim-accurate; it is the confused-deputy control.
- The **2026-07-28 structural changes**: stateless core (session/initialize handshake removed), Multi-Round-Trip Requests, header-based routing, formal deprecation policy, Roots/Sampling/Logging deprecated, MCP Apps + Tasks promoted, Enterprise-Managed Authorization stable.
- **MCP Apps caution:** server-rendered UI is untrusted content and must be sandboxed.
- The **acknowledged gap:** no standard yet for how authorization propagates through gateways to downstream servers.

**Validation checklist (seed):** reject tokens whose `aud` does not include this server; never forward the client's token upstream; require the `resource` parameter; publish PRM at the well-known location; sandbox any server-rendered UI.

**Known pitfalls:** token passthrough; assuming session state post-2026-07-28; treating the gateway→downstream auth hop as solved by the spec (it isn't).

---

### 7.4 `agent-delegation-drafts`

**Scope:** the in-flight IETF work specific to AI-agent delegation, and — importantly — **where the drafts conflict**, so a design doesn't unknowingly mix incompatible models. These are Internet-Drafts: usable as design patterns, **not citable as standards** in formal procurement or compliance documents.

**Primary sources (datatracker; unversioned URLs resolve to current):**
- `draft-oauth-ai-agents-on-behalf-of-user` — `requested_actor`, `actor_token`; front-channel consent for an agent
- `draft-klrc-aiagent-auth` — broad model; states the anti-pattern that tools MUST NOT forward agent tokens downstream
- `draft-araut-oauth-transaction-tokens-for-agents` — `act` on transaction tokens for traceability across the service graph
- `draft-niyikiza-oauth-attenuating-agent-tokens` — offline attenuation (narrow, never amplify) for delegation chains
- Base: `draft-ietf-oauth-transaction-tokens`, `draft-ietf-oauth-identity-chaining`

**Extract:** each draft's added parameters/claims; its intended flow; its maturity (individual vs WG-adopted); and a **comparison table** of the three carriage strategies — exchange-at-every-hop (RFC 8693), transaction tokens, attenuating tokens — with tradeoffs. Include the **chain-splicing** attack and the mitigation (audience of hop N must match subject of hop N+1; short lifetimes; back-channel revocation).

**Known pitfalls:** designing around an individual draft as if stable; mixing two drafts' claim models; assuming WG adoption where there is none.

---

### 7.5 `revocation-signals`

**Scope:** how a revocation/compromise event propagates to every relying party holding a live grant — the fix for the "suspension is a no-op until token expiry" problem.

**Primary sources:**
- OpenID **Shared Signals Framework (SSF)**
- **CAEP** (Continuous Access Evaluation Profile)
- **RISC** (account-compromise events)
- `https://github.com/openid/sharedsignals`
- Supporting: RFC 7662 introspection, RFC 7009 revocation, OAuth Grant Management (grant-level revocation object model)

**Extract:** the **Security Event Token (SET)** structure; the `events` claim; stream configuration/management API; the specific **CAEP event types** (e.g. session-revoked, token-claims-change, credential-change, assurance-level-change) and their **required subject identifier formats**; how a transmitter and receiver establish a stream. Reproduce event-type URIs and subject formats exactly — these are the highest-fabrication-risk items in the whole suite.

**Validation checklist (seed):** every RP holding a live grant subscribes to the AS's signal stream; write-scope operations introspect rather than trust local validation; short TTLs for read scopes; on consent withdrawal, emit revocation to all subscribed RPs; agent-identity suspension fans out, not just a point-to-point report.

**Known pitfalls:** inventing event URIs; assuming local JWT validation can observe revocation; point-to-point reporting with no fan-out; report channel that any party can spoof (must be mutually authenticated / signed).

---

### 7.6 `agentic-architecture-review` (judgment layer)

**Scope:** the reasoning that turns spec facts into a design verdict and a corrected design. Not a spec extract — an encoded review methodology. References the five knowledge skills.

**Contents:**

- **Verification checklist, organized by architectural layer:**
  - *Identity & enrolment:* does anything secret transit the agent/LLM/transcript? where does the private key live? is agent creation attested and step-up-gated? is there an owner-facing kill switch?
  - *Delegation:* is this consent-to-*access* or authorization-of-*action*, and do the stakes demand they be separate events? is the grant bound to specific parameters (RAR) or a blank cheque? TTL / refresh / re-consent?
  - *Token:* sender-constrained (`cnf`) or bearer? `act` present (delegation) or absent (impersonation)? audience-bound? passthrough anywhere?
  - *Resource enforcement:* is resource identity derived from the token subject or a client parameter? does the RS run the full validation checklist?
  - *Revocation & lifecycle:* does revocation propagate and reach every RP? is there a *mechanism*, not just an intention? class/fleet-level revocation? identity-lifecycle propagation (owner suspended/deceased)?

- **Pattern library (the fixes):** confirm-to-commit (draft → server-rendered summary → approve → commit); enrolment inversion (nothing secret moves toward the agent); the `sub`/`act`/`cnf` token shape; SSF/CAEP fan-out; reader-agent pattern for untrusted content; RAR-bound mandates; step-up via RFC 9470.

- **Severity model:** each finding rated (e.g. "ends the project" vs "tighten later"), with a real-world anchor where possible (ClawHub malicious-skill wave; the untrusted-code-with-durable-credentials chain; confused-deputy).

- **"No standard exists here" register:** be explicit where the design must invent mechanism — agent runtime attestation; agent class/fleet revocation; a delegation-mandate artefact for natural-person principals (note that even the EUDI ARF declines to specify powers/mandates; India's DEPA/ReBIT consent artefact is the closest working precedent); authorization propagation through MCP gateways; cross-service behavioural baselining. A skill that pretends a standard exists here is actively harmful.

- **Boundary/humility note:** the output is an informed review, not a certification. For high-assurance work, human security sign-off remains required. State this inside the skill so it never over-claims.

---

### 7.7 `openclaw-runtime` (deployment layer)

**Scope:** the OpenClaw execution model and its security-relevant configuration, so advice targeting OpenClaw is grounded rather than guessed.

**Primary sources:** `https://docs.openclaw.ai/` — security, architecture, and configuration reference pages. (Fast-moving; record exact fetch dates.)

**Extract:** the gateway/node/skill/plugin model; that plugins run in-process and are trusted code; config key precedence; `security audit` (and `--deep`/`--fix`) check IDs; tool policy resolution (`tools.profile`, deny lists, `tools.exec.*`); per-agent sandbox modes/scope/workspace access; `dmPolicy`, `contextVisibility`, `tools.agentToAgent`; the reader-agent pattern; the browser SSRF policy; where state/credentials/transcripts live on disk.

**Framing to encode:** OpenClaw is *untrusted code execution with persistent credentials* — two supply chains (untrusted skills + untrusted instructions) meet in one loop with durable credentials. Transcripts on disk are a credential-exposure surface. Do not run on a standard workstation.

---

### 7.8 `enterprise-iam-deployment` (deployment layer)

**Scope:** how to realize the correct patterns on the enterprise IAM / API-management stack in use. References the protocol skills for correctness; adds product specifics.

**Sources:** the vendor's current product docs for its agent-identity service, API manager / AI gateway / MCP proxy, and identity server. (Verify current capabilities against docs — do not assert from memory; product features move.)

**Extract:** how the agent-identity service registers/authenticates/authorizes/audits agents as first-class identities; delegation policy configuration; how the AI gateway exposes REST APIs as MCP tools and governs third-party MCP usage; where token exchange / introspection / revocation are enforced; guardrail configuration. Map each item back to the relevant protocol skill's requirement so the "how" stays tied to the "what."

---

## 8. Spec & standard URL reference

> Convention: IETF datatracker URLs **without** a version suffix resolve to the current revision — prefer those for drafts so links stay valid. RFCs are immutable. Internet-Drafts are "work in progress" and must not be cited as standards.

### Stable — RFCs / finals (citable)

| Spec | ID | URL |
|---|---|---|
| OAuth 2.0 Security BCP | RFC 9700 (BCP 240) | https://www.rfc-editor.org/rfc/rfc9700.html |
| OAuth 2.0 | RFC 6749 | https://www.rfc-editor.org/rfc/rfc6749.html |
| Bearer tokens | RFC 6750 | https://www.rfc-editor.org/rfc/rfc6750.html |
| PKCE | RFC 7636 | https://www.rfc-editor.org/rfc/rfc7636.html |
| JWT | RFC 7519 | https://www.rfc-editor.org/rfc/rfc7519.html |
| JWS | RFC 7515 | https://www.rfc-editor.org/rfc/rfc7515.html |
| JSON Canonicalization (JCS) | RFC 8785 | https://www.rfc-editor.org/rfc/rfc8785.html |
| JWT access tokens | RFC 9068 | https://www.rfc-editor.org/rfc/rfc9068.html |
| JWT client auth (`private_key_jwt`) | RFC 7523 | https://www.rfc-editor.org/rfc/rfc7523.html |
| Assertion framework | RFC 7521 | https://www.rfc-editor.org/rfc/rfc7521.html |
| mTLS / cert-bound tokens | RFC 8705 | https://www.rfc-editor.org/rfc/rfc8705.html |
| DPoP | RFC 9449 | https://www.rfc-editor.org/rfc/rfc9449.html |
| Resource Indicators | RFC 8707 | https://www.rfc-editor.org/rfc/rfc8707.html |
| Protected Resource Metadata | RFC 9728 | https://www.rfc-editor.org/rfc/rfc9728.html |
| AS Metadata | RFC 8414 | https://www.rfc-editor.org/rfc/rfc8414.html |
| Dynamic Client Registration | RFC 7591 / 7592 | https://www.rfc-editor.org/rfc/rfc7591.html |
| Device Authorization Grant | RFC 8628 | https://www.rfc-editor.org/rfc/rfc8628.html |
| **Token Exchange** (`act`, `may_act`) | RFC 8693 | https://www.rfc-editor.org/rfc/rfc8693.html |
| **Rich Authorization Requests** | RFC 9396 | https://www.rfc-editor.org/rfc/rfc9396.html |
| Pushed Authorization Requests | RFC 9126 | https://www.rfc-editor.org/rfc/rfc9126.html |
| JWT-Secured Authz Request (JAR) | RFC 9101 | https://www.rfc-editor.org/rfc/rfc9101.html |
| Step-up Authentication Challenge | RFC 9470 | https://www.rfc-editor.org/rfc/rfc9470.html |
| Token Introspection | RFC 7662 | https://www.rfc-editor.org/rfc/rfc7662.html |
| Token Revocation | RFC 7009 | https://www.rfc-editor.org/rfc/rfc7009.html |
| OAuth for Native Apps | RFC 8252 (BCP 212) | https://www.rfc-editor.org/rfc/rfc8252.html |
| HTTP Message Signatures | RFC 9421 | https://www.rfc-editor.org/rfc/rfc9421.html |
| SCIM core / protocol | RFC 7643 / 7644 | https://www.rfc-editor.org/rfc/rfc7643.html |
| iCalendar / iTIP | RFC 5545 / 5546 | https://www.rfc-editor.org/rfc/rfc5545.html |
| Well-known URIs | RFC 8615 | https://www.rfc-editor.org/rfc/rfc8615.html |

### IETF drafts — agent/delegation (work in progress)

| Draft | URL |
|---|---|
| OAuth 2.1 | https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1/ |
| Client ID Metadata Document (CIMD) | https://datatracker.ietf.org/doc/draft-ietf-oauth-client-id-metadata-document/ |
| Identity & Authorization Chaining Across Domains | https://datatracker.ietf.org/doc/draft-ietf-oauth-identity-chaining/ |
| Transaction Tokens | https://datatracker.ietf.org/doc/draft-ietf-oauth-transaction-tokens/ |
| Transaction Tokens **for Agents** | https://datatracker.ietf.org/doc/draft-araut-oauth-transaction-tokens-for-agents/ |
| On-Behalf-Of User Authorization for AI Agents | https://datatracker.ietf.org/doc/draft-oauth-ai-agents-on-behalf-of-user/ |
| AI Agent Authentication & Authorization | https://datatracker.ietf.org/doc/draft-klrc-aiagent-auth/ |
| Attenuating Authorization Tokens for Agentic Delegation Chains | https://datatracker.ietf.org/doc/draft-niyikiza-oauth-attenuating-agent-tokens/ |
| SD-JWT | https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/ |
| SD-JWT VC | https://datatracker.ietf.org/doc/draft-ietf-oauth-sd-jwt-vc/ |
| Token Status List | https://datatracker.ietf.org/doc/draft-ietf-oauth-status-list/ |
| OAuth WG (all docs) | https://datatracker.ietf.org/wg/oauth/documents/ |

### IETF WIMSE (workload identity — optional skill)

| Draft | URL |
|---|---|
| WIMSE Architecture | https://datatracker.ietf.org/doc/draft-ietf-wimse-arch/ |
| Service-to-Service (WIT + WPT) | https://datatracker.ietf.org/doc/draft-ietf-wimse-s2s-protocol/ |
| Workload Identifier | https://datatracker.ietf.org/doc/draft-ietf-wimse-identifier/ |
| WG documents | https://datatracker.ietf.org/wg/wimse/documents/ |

### OpenID Foundation

Specs index (authoritative entry point — filenames shift with revisions): https://openid.net/developers/specs/

| Spec | URL |
|---|---|
| OpenID Connect Core 1.0 | https://openid.net/specs/openid-connect-core-1_0.html |
| OIDC Discovery 1.0 | https://openid.net/specs/openid-connect-discovery-1_0.html |
| CIBA Core 1.0 | via specs index (search "CIBA") |
| FAPI 2.0 Security Profile | via specs index (search "FAPI 2.0") |
| Grant Management for OAuth 2.0 | via specs index (search "Grant Management") |
| Shared Signals Framework (SSF) | via specs index; repo: https://github.com/openid/sharedsignals |
| CAEP | via specs index (search "CAEP") |
| RISC | via specs index (search "RISC") |
| OpenID4VCI / OpenID4VP | via specs index |
| HAIP | via specs index |
| OIDC Federation 1.0 | via specs index |

### Agent protocols

**MCP** — pin `2026-07-28`
| Resource | URL |
|---|---|
| Spec home | https://modelcontextprotocol.io/ |
| Authorization | https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization/ |
| Security considerations | https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization/security-considerations |
| 2026-07-28 release notes | https://blog.modelcontextprotocol.io/posts/2026-07-28/ |
| GitHub | https://github.com/modelcontextprotocol |

**A2A** — v1.0
| Resource | URL |
|---|---|
| Specification (latest) | https://a2a-protocol.org/latest/specification/ |
| What's New in v1.0 | https://a2a-protocol.org/latest/whats-new-v1/ |
| Announcing 1.0 | https://a2a-protocol.org/latest/announcing-1.0/ |
| Roadmap / release notes | https://a2a-protocol.org/latest/roadmap/ |
| GitHub (incl. extensions) | https://github.com/a2aproject/A2A |

**SPIFFE**
| Resource | URL |
|---|---|
| SPIFFE-ID standard | https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE-ID.md |
| Site | https://spiffe.io/ |

### W3C

| Spec | URL |
|---|---|
| WebAuthn Level 3 | https://www.w3.org/TR/webauthn-3/ |
| Verifiable Credentials Data Model 2.0 | https://www.w3.org/TR/vc-data-model-2.0/ |
| Trace Context | https://www.w3.org/TR/trace-context/ |
| schema.org Reservation | https://schema.org/Reservation |

### Frameworks / governance / precedents

| Resource | URL |
|---|---|
| OWASP Top 10 for Agentic Applications 2026 | https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/ |
| OWASP GenAI Security Project | https://genai.owasp.org/ |
| MITRE ATLAS | https://atlas.mitre.org/ |
| NIST SP 800-207 (Zero Trust) | https://csrc.nist.gov/pubs/sp/800/207/final |
| NIST AI RMF | https://www.nist.gov/itl/ai-risk-management-framework |
| OpenTelemetry GenAI semconv | https://opentelemetry.io/docs/specs/semconv/gen-ai/ |
| EUDI Wallet ARF | https://eudi.dev/ · https://github.com/eu-digital-identity-wallet/eudi-doc-architecture-and-reference-framework |
| India DEPA / account-aggregator consent artefact | https://rebit.org.in/ · https://sahamati.org.in/ |
| OpenClaw docs | https://docs.openclaw.ai/ |

---

## 9. Staleness & maintenance discipline

The fast-movers — MCP revisions and every IETF draft — will change within months. Bake this in:

- Every `references/_source.md` records: canonical URL, **exact revision/version consulted**, **fetch date**, and a **re-check trigger** ("before answering any version-sensitive question, re-fetch and diff").
- MCP: pinned to `2026-07-28`. When a newer revision appears, diff the authorization and transport sections before updating.
- Drafts: unversioned datatracker URLs auto-resolve; still record which version you read, since parameter names can change between revisions.
- A skill that silently serves a superseded revision is **worse than no skill.** The staleness note is not decoration.

Suggested cadence: re-verify the fast-movers (MCP, the four delegation drafts, A2A extensions, OpenClaw) quarterly; RFCs never need re-checking.

---

## 10. Acceptance criteria

Per knowledge skill:
1. `SKILL.md` is lean, disjoint in description from siblings, and points into `references/`.
2. `references/` contains field tables, copyable artifacts, and a **testable-assertion validation checklist**.
3. Every reference file cites source + section + date; `_source.md` present with re-check trigger.
4. Content is extracted fact, not paraphrase-of-recall; verbatim quotes kept short; schema/param names exact.
5. **Composition test passes:** when paired with a real coding persona, the generated code honors the validation checklist (esp. `cnf`, `act`-present, audience, no passthrough); when paired with a reviewer persona, the same items surface as findings.

Per judgment skill (`agentic-architecture-review`):
6. Produces layered findings with severity and, where relevant, a real-world anchor.
7. Correctly flags the two canonical failure classes on a test design: (a) consent-to-access treated as authorization-of-action; (b) no working revocation/kill-switch.
8. Uses the "no standard exists here" register where appropriate and states its non-certification boundary.

Per deployment skill:
9. Every product-specific "how" maps back to a protocol skill's "what."
10. Claims about current product capability are verified against live docs, not asserted from memory.

Suite-level:
11. Each skill stands alone (self-contained, siblings-optional).
12. Confirm the loader format (flat `.md` vs folder) **before** mass-building, and match it.

---

## Appendix — the two failure classes the suite must always catch

These recur across designs; the review skill should treat them as first-check items.

1. **Consent-to-access ≠ authorization-of-action.** Approving "agent may access service X" is not approving "agent performed action Y with these specific parameters." For any binding or high-stakes action, the human must confirm the *action* (with its real figures) out of band, via a channel the agent cannot read or write. Pattern: draft → server-rendered summary → approve → commit.

2. **No functioning off switch.** Revocation must have a *mechanism* (short TTL + introspection for writes; not local-JWT-only), must *propagate* (SSF/CAEP fan-out to every RP holding a grant, not point-to-point), must be *fast* (automatic on signed report, not gated on a human admin), and must be *reachable by the resource owner* (a direct kill switch). All four, or it does not work.

Everything else is detail; these two are load-bearing.
