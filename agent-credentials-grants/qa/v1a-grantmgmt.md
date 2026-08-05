# V1-A Adversarial Verification: grant-management.md

- Target: /Users/ramith/code/agent-protocol-standards/agent-credentials-grants/references/grant-management.md
- Source (ground truth): /Users/ramith/code/agent-protocol-standards/spec-src/agent-credentials-grants/grant-mgmt-ID1.html (oauth-v2-grant-management-03, raw HTML, read in full)
- Verifier: A-adversarial
- Date: 2026-08-05

## Verdict counts

- Claims checked: 79
- VERIFIED: 77
- UNSUPPORTED: 0
- CONTRADICTED: 0
- AMBIGUOUS: 2

Every action value (`create`, `merge`, `replace`; metadata set `query`, `revoke`, `merge`, `replace`, `create`), endpoint/metadata name (`grant_management_endpoint`, `grant_management_actions_supported`, `grant_management_action_required`), scope name (`grant_management_query`, `grant_management_revoke`), error name (`invalid_grant_id`, `invalid_request`, `invalid_token`), HTTP status (404/403/401/204/503), the query-response JSON shape (`scopes`/`claims`/`authorization_details` + `created_at`/`last_updated_at`/`expires_at`/`updated_by`), and all revocation semantics were checked character-exact against the HTML and matched.

Verbatim quotes in the extraction were confirmed exact:
- merge: source section-5.2-4.2.1 "shall invalidate existing refresh tokens associated with the updated grant" — exact.
- replace: source section-5.2-4.3.1 "shall invalidate existing refresh tokens associated with the replaced grant" — exact.
- revoke: source section-6.5-5 "The AS MUST revoke the grant and all refresh tokens issued based on that particular grant, it should revoke all access tokens issued based on that particular grant." — exact.
- 5.5 sic-quote: source section-5.5-3 "(for example, <code>create</code>, <code>update</code> or <code>replace</code>)" — exact.
- updated_by mixed quoting: source section-6.4-9 "Allowed values are 'client' and \"authorization_server\"." — exact, including the mixed quote styles.

The three alleged internal spec defects were all confirmed real:
1. Stale `update` mentions: Appendix D under "-02" says "renamed <code>update</code> action to <code>merge</code>"; yet section-5.5-3 still says "for example, <code>create</code>, <code>update</code> or <code>replace</code>" and section-5.6.2-1 says "Grant can be modified by a client via update or replace actions." — allegation VERIFIED.
2. `last_updated` vs `last_updated_at`: section-6.4-9 prose defines "<code>last_updated</code>: (optional) time when the grant was last updated"; the section-6.4-4 example emits `"last_updated_at":1356123600`; no reconciling text exists anywhere in the document — allegation VERIFIED (see Finding 2 for the extraction's appended inference).
3. IANA description error: section-a.2-2.4.1 describes `grant_management_actions_supported` as "JSON array containing the authorization details types the AS supports" while section-7.1-1 defines it as "JSON array containing the actions supported by the AS. Allowed values are <code>query</code>, <code>revoke</code>, <code>merge</code>, <code>replace</code> and <code>create</code>." — allegation VERIFIED, quote character-exact.

## Findings (non-VERIFIED items)

### Finding 1 — AMBIGUOUS: "Implementer's Draft 1" designation
- Claim (target, line 3 and note 1): "Implementer's Draft 1 (NOT final ...)" / "Maturity: Implementer's Draft 1 (draft -03, May 2023), not a Final Specification."
- Source quotes: the document text never states "Implementer's Draft 1". Title: "Grant Management for OAuth 2.0 (Draft)"; identifiers: "Internet-Draft: oauth-v2-grant-management-03", "Published: 9 May 2023". The Notices only reference the category generically: "implementing Implementers Drafts and Final Specifications based on such documents".
- Verdict: AMBIGUOUS. The ID1 status is supported only by file identity (grant-mgmt-ID1.html / the cited openid.net ...-ID1.html URL), not by any statement inside the ground-truth content. Draft-ness itself ("(Draft)", Internet-Draft -03, May 2023) is fully supported; only the specific "Implementer's Draft 1" label is externally sourced.

### Finding 2 — AMBIGUOUS: "implementations may emit either" (last_updated note)
- Claim (target, note "last_updated vs last_updated_at"): "The spec does not resolve this; implementations may emit either."
- Source quotes: prose (section-6.4-9) "<code>last_updated</code>: (optional) time when the grant was last updated expressed as a number containing a NumericDate value." vs example (section-6.4-4) "\"last_updated_at\":1356123600". No text in the spec licenses either field name or addresses the discrepancy.
- Verdict: AMBIGUOUS. "The spec does not resolve this" is VERIFIED. "implementations may emit either" is the extraction's own inference presented without the `Guidance — ours, not spec:` label used elsewhere in the file; it is not contradicted by the source, but it is not sourced either.

## Minor observations (no verdict impact)

- The stale-`update` note lists Sections 5.5 and 5.6.2; the list is non-exhaustive. Section 1.1 (Terminology) also says the Grant Management API can "query the status of, update, replace and revoke grants", which additionally conflicts with Section 6 (API supports only Query and Revoke). The extraction never claims exhaustiveness, so no verdict change.
- "HTTP GET ... with a Bearer access token" is supported by the source example only ("Authorization: Bearer 2YotnFZFEjr1zCsicMWpAA", section-6.4-2); the prose (6.1) requires an authorized access token without naming the scheme. Counted VERIFIED via example.
- Overview paraphrase "resource-owner interaction assumed" slightly strengthens section-2-2's "creation and updates of grants almost always require interaction with the resource owner"; within paraphrase tolerance. Counted VERIFIED.

NOT CHECKED: fetch/extraction provenance dates ("fetched 2026-08-05 — extracted 2026-08-05"); liveness/correctness of the openid.net URLs and whether newer drafts exist (no network access); whether the ID1 publication on openid.net is byte-identical to this local file.

## Triage 2026-08-05

- Finding 1 — FIXED: Source line now reads "... — Implementer's Draft 1 (the \"Implementer's Draft 1\" designation comes from the OpenID specs index/URL; the document title itself says only \"Grant Management for OAuth 2.0 (Draft)\") (NOT final; check https://openid.net/developers/specs/ for newer) — ..." — the externally sourced designation is now labeled as such. (The Section 8 maturity note keeps the ID1 label, which the annotated Source line now covers.)
- Finding 2 — FIXED: note now reads "The spec does not resolve this. Guidance — ours, not spec: expect implementations to emit either." — the unsourced inference kept but labeled with the file's guidance prefix. (Same labeling applied to the mirrored line in references/pitfalls.md.)
- v1b-diff GAP 7.1 — FIXED: metadata bullet now reads "`grant_management_action_required` — OPTIONAL. Boolean; if `true`, all authorization requests must specify a `grant_management_action` (lowercase \"must\" in Section 7.1; the IANA registration description in Appendix A.2 uses a capitalized MUST: \"Boolean where, if `true`, all authorization requests MUST specify a `grant_management_action`\"). Defaults to `false`." — A.2 wording confirmed against grant-mgmt-ID1.html (section-a.2-2.20.1).
