---
name: agent-credentials-grants
description: Spec-accurate reference for issuing, structuring, binding, and validating OAuth tokens where an AI agent acts for a user or itself — RFC 8693 token exchange (act/may_act, delegation vs impersonation), RFC 9396 rich authorization requests, RFC 9470 step-up, RFC 9449 DPoP sender-constraining, RFC 8707 audience binding, RFC 7523 private_key_jwt, Client ID Metadata Documents, and OAuth Grant Management.
when_to_use: Reviewing or designing delegated/on-behalf-of token flows; implementing token issuance or resource-server validation for agents; writing security probes for agent token handling. Not for MCP endpoint specifics (mcp-authorization) or agent discovery/messaging (a2a-protocol).
---

<!-- Source freshness (auto-injected at invocation): -->
!`bash ${CLAUDE_SKILL_DIR}/scripts/staleness.sh`

# Agent Credentials & Grants

> **⚠ PINNED STANDARD VERSIONS — this skill encodes:**
>
> | Standard | Pinned revision |
> |---|---|
> | RFC 8693, 9396, 9470, 9449, 8707, 7523 | RFC (immutable) |
> | Client ID Metadata Documents | draft-ietf-oauth-client-id-metadata-document **-02** (expires 2027-01-07) |
> | Grant Management for OAuth 2.0 | Implementer's Draft 1 |
>
> Newer revisions may exist — apply the "Version drift protocol" below before relying on version-sensitive answers.

> **⚠ QA: UNVERIFIED — skill under construction (Sprint 1, Stage 1 of 7 complete).**
> Sources are acquired and hash-pinned (`references/_source.md`); extraction, checklist, and verification have not run yet. Do not treat this skill's future content as authoritative until this stamp reads `verified`.

## Covers / does not cover

**Covers:** everything needed to issue, structure, bind, and validate a delegated ("on-behalf-of") token for an agent acting for a user, and how an agent authenticates as itself: the token-exchange grant and its parameters; the `act`/`may_act` claim semantics including delegation-vs-impersonation; `authorization_details` (RAR) structure and grant-matching; step-up challenges; DPoP proofs and `cnf`/`jkt` binding; `resource`-parameter audience binding; `private_key_jwt` client authentication; URL-as-client-id (CIMD); grant lifecycle query/update/revocation (Grant Management).

**Does not cover:** how an MCP resource server publishes metadata or handles token passthrough (`mcp-authorization`); agent discovery, AgentCards, or task exchange (`a2a-protocol`); the in-flight IETF agent-delegation draft family and their conflicts (`agent-delegation-drafts`); revocation *propagation* across relying parties (`revocation-signals`). Those skills may not be loaded — this one stands alone for its own scope.

## Version drift protocol
Before answering a version-sensitive question: fetch the `latest-url` for the relevant source in `references/_source.md` and compare the current published revision to the pin above. If newer, report both — "this skill pins <X>; the current revision is <Y>" — and let the user choose: proceed on the pinned revision, or pause for re-verification. Never answer silently from a superseded pin.

## Staleness note
Sources, revisions, fetch dates, and content hashes are in `references/_source.md`. If the banner above says STALE, re-fetch before answering version-sensitive questions.
