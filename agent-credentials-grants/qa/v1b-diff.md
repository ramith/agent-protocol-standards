# V1-B Blind-Control Diff Report

Compared: 7 blind re-extractions (`qa/v1b-*.md`, produced from raw specs only) against the skill's
independently extracted reference files (`references/*.md`). Scope of comparison: factual content only —
field/parameter/claim names and spellings, required/optional/conditional status, requirement levels
(MUST vs SHOULD vs lowercase prose), exact identifier strings (URNs, URIs, error codes, metadata names,
action values), section attributions, and load-bearing semantic statements. Formatting, ordering,
phrasing, and non-load-bearing coverage differences ignored.

Discrepancy classes: **MISMATCH** (incompatible facts), **LEVEL-SHIFT** (same fact, different
requirement level), **GAP** (load-bearing fact in blind output missing from reference),
**NAMING** (identifier spelling / section attribution differs).

Date: 2026-08-05

---

## Pair 1 — RFC 8693: `qa/v1b-rfc8693.md` ↔ `references/token-exchange.md`

**Verdict: CLEAN**

Verified point-by-point, no discrepancies found:

- All 9 request parameters with identical req/opt status, including the conditional
  `actor_token_type` ("REQUIRED when `actor_token` is present; MUST NOT be included otherwise") and
  the `resource` URI constraints (MUST absolute, MAY query, MUST NOT fragment) — both files, §2.1.
- All 6 response parameters, including `expires_in` RECOMMENDED and the conditional `scope`
  ("OPTIONAL if identical to requested, otherwise REQUIRED") — both files, §2.2.1.
- All 6 token type URNs identical, including the `...:jwt` attribution to RFC 7519 §9 rather than
  RFC 8693 itself — both files, §3.
- `act` nesting rule quoted identically in both ("The outermost 'act' claim represents the current
  actor while nested 'act' claims represent prior actors"; least recent = most deeply nested), and
  the §4.1 access-control MUST (top-level claims + current actor only; prior actors informational)
  matches verbatim.
- Error handling: both state the AS MUST construct an RFC 6749 §5.2 error response with `error` =
  `invalid_request` for invalid subject/actor tokens (§2.2.2), and both give `invalid_target` for
  target refusal.
- §6 requirements (encrypted channels MUST; encrypt-to-recipient MUST) and `may_act` semantics match.

---

## Pair 2 — RFC 9396: `qa/v1b-rfc9396.md` ↔ `references/rich-authorization.md`

**Verdict: CLEAN**

Verified, no discrepancies:

- `type` REQUIRED; five common fields (`locations`, `actions`, `datatypes`, `identifier`,
  `privileges`) with identical types and semantics; multiple same-`type` entries MAY; cross-product
  combination semantics (§2, §2.2) — identical in both.
- Message locations identical: authorization request (RFC 6749 / RFC 8628 / CIBA), no authorization
  response extension (§4), token request (§6), token response MUST return granted details (§7),
  JWT claim RECOMMENDED filtered to audience (§9.1), introspection top-level member MUST use §2
  structure (§9.2), IANA locations authorization request / token request / token response (§14.1),
  `invalid_authorization_details` registered for token endpoint and authorization endpoint (§14.6).
- Metadata names identical: `authorization_details_types_supported` (AS, §14.4) and
  `authorization_details_types` (client, MAY, §14.5).
- All MUSTs at matching levels: §5 refuse/abort with `invalid_authorization_details` (5 trigger
  conditions match); §8 token error response same rules; §3.1 combined processing MUST and merged
  consent MUST; §12 client tamper-protection MUST and AS sanitization MUST.

**Explicit question — enforcement obligation:** The two files **agree**, and the reference's claim is
**compatible** with the blind file's account of §1/§9.

- Blind file: "**Who bears the enforcement obligation, per the spec:** the AS and the respective RS
  'will together enforce this consent' (§1). Concretely, the AS bears the obligations to
  validate/refuse requests (§5, §8), ... and make the approved details available to the RS (§9); the
  RS enforces the authorization details ... at the protected API, enabled by that AS-provided data
  (§9, §11.1)." — and its requirement #6 assigns the obligation as "AS (making data available); the
  RS performs the runtime enforcement".
- Reference file: "the AS MUST make this data available to the RS" (§9) and "Guidance — ours, not
  spec: RFC 9396 puts no explicit normative obligation on the RS itself; the enforcement burden is
  framed as the AS making data available 'to enable the RS to enforce' (§9), and deployments must
  'determine how the RSs process the authorization details' (§11.1)."

Both files attribute every normative MUST to the AS (validation §5/§8, consent §3.1, return §7,
availability §9) and describe RS enforcement as the architectural role enabled by the AS data. The
blind file's §1 quote ("will together enforce this consent") is descriptive design intent, not a
normative RS-side keyword, so it does not contradict the reference's "no normative RS-side
obligation" reading; the blind file itself locates the normative burden on the AS. No MISMATCH, no
LEVEL-SHIFT.

---

## Pair 3 — RFC 9470: `qa/v1b-rfc9470.md` ↔ `references/step-up.md`

**Verdict: CLEAN**

Verified, no discrepancies:

- Error code `insufficient_user_authentication`, identical definition sentence, Bearer + DPoP
  applicability, IANA usage location "resource access error response" (§3, §10.1) — both.
- `acr_values` (space-separated, order of preference, one-of semantics) and `max_age` (seconds since
  last active authentication event; token or quoted-string; "has to represent a non-negative
  integer" — both files note this is not a capitalized keyword) — both, §3.
- §4 client SHOULD parse and relay; `acr_values`/`max_age` are OPTIONAL OIDC §3.1.2.1 parameters;
  no AS behavior changes — both.
- Claims: `acr` and `auth_time` in JWT access tokens per RFC 9068 §2.2.1 (values fixed at
  user-authentication time, unchanged on renewal, §6.1); `acr`/`auth_time` as top-level
  introspection members with matching definitions (§6.2, IANA §10.2) — both.
- Normative inventory matches exactly: client SHOULD (§4); AS SHOULD treat requested acr as
  necessary else `unmet_authentication_requirements` [OIDCUAR] (§5); MUST NOT position OAuth as an
  authentication protocol (§9); the §5 MUST (auth_time in ID Token when `max_age` present) flagged
  by both as a restated OIDC §3.1.2.1 requirement, not native to RFC 9470; MAY items (§3, §6, §9)
  match. Both note the lowercase, non-BCP-14 "must not inspect" in §2 and `acr_values_supported`
  discovery via §7.

---

## Pair 4 — RFC 9449: `qa/v1b-rfc9449.md` ↔ `references/dpop.md`

**Verdict: CLEAN**

Verified, no discrepancies:

- JOSE header: `typ` = `dpop+jwt`, `alg` MUST NOT be `none`/symmetric, `jwk` MUST NOT contain a
  private key (§4.2) — identical.
- Payload claims with identical conditionality: `jti`/`htm`/`htu`/`iat` always required; `ath`
  required with protected-resource access token presentation (§7); `nonce` required once a
  `DPoP-Nonce` was provided (§8, §9) — identical, including the ≥96-bit / UUIDv4 `jti` guidance and
  `htu` "without query and fragment parts".
- All 12 §4.3 validation checks match one-for-one, including check 11's `iat`-or-nonce-timestamp
  alternative and the SHOULD-level RFC 3986 §6.2.2/§6.2.3 `htu` normalization.
- Key binding: `cnf`/`jkt`, base64url (RFC 7515) of RFC 7638 JWK SHA-256 Thumbprint (§6.1);
  introspection `token_type` if present MUST be `DPoP` (§6.2); response `token_type` MUST be `DPoP`
  (§5); `dpop_jkt` same thumbprint (§10) — identical.
- Identifiers: `invalid_dpop_proof`, `use_dpop_nonce`, `DPoP`, `DPoP-Nonce`,
  `application/dpop+jwt`, `dpop_signing_alg_values_supported`, `dpop_bound_access_tokens`,
  `dpop_jkt` — all spelled and attributed identically.
- The blind file's 8 load-bearing MUSTs (§5 token endpoint + refresh-token binding, §6 RS binding
  checks, §7/§7.1 proof+token+ath and MUST NOT grant, §7.2 bearer downgrade rejection, §11.3 nonce
  downgrade, §11.5/§11.6 typ/none, §11.1 limited proof lifetime) all appear at the same level in the
  reference, as do the secondary MUSTs (HTTPS §2, nonce rules §8, `dpop_bound_access_tokens` §5.2,
  PAR §10/§10.1, proxy-field prohibition §7.1).

(Trivial slip in the blind file, not a factual discrepancy: §4.2 nonce row says "authentication
server" where "authorization server" is meant; the rule stated is identical.)

---

## Pair 5 — RFC 8707: `qa/v1b-rfc8707.md` ↔ `references/audience-binding.md`

**Verdict: CLEAN**

Verified, no discrepancies:

- Syntax constraints at identical levels: MUST absolute URI (RFC 3986 §4.3), MUST NOT fragment,
  SHOULD NOT query (with the recognized exceptions), MAY locator, SHOULD most-specific URI, SHOULD
  base URI (§2).
- Locations: authorization request (§2.1, with the implicit-flow vs code-flow applicability
  difference stated identically), token request "for all grant types" (§2.2), IANA §5.1
  "authorization request, token request" — both.
- Multiplicity: MAY repeat (§2); cartesian-product semantics quote (§2.2); single-parameter
  encouragement and multi-audience trust caveat (§3) — both.
- `invalid_target`: identical definition sentence; both flag §2.1 rejection as lowercase "should"
  (not BCP 14); IANA §5.2 "implicit grant error response, token error response" — both.
- Audience representation: both state audience restriction is only SHOULD (§2), that token
  representation is not mandated ("can be communicated" via JWT `aud` / introspection top-level
  `aud`), and that the AS may map `resource` to a more general/abstract identifier.
- BCP 14 keyword inventory agrees: blind counts 12 instances (1 MUST, 1 MUST NOT, 1 SHOULD NOT,
  4 SHOULD, 5 MAY); the reference's table lists the same 12 (its row 11 merges the two §2.1 MAYs).
  Both flag the §2.2 lowercase downscoping "should" and the lowercase effective-scope "must"
  inherited from RFC 6749 §5.1.

---

## Pair 6 — RFC 7523 + CIMD: `qa/v1b-clientauth.md` ↔ `references/client-auth.md`

**Verdict: CLEAN**

Verified, no discrepancies:

- Part A URNs and carriers identical: `urn:ietf:params:oauth:grant-type:jwt-bearer` in
  `grant_type` + `assertion` (single JWT MUST); `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`
  in `client_assertion_type` + `client_assertion` (MUST NOT contain more than one JWT) (§2.1, §2.2).
- §3 claims table identical: `iss`/`sub`/`aud`/`exp` required, `nbf`/`iat`/`jti`/others MAY,
  signature/MAC MUST (§3(9)), `RS256` mandatory-to-implement (§5). Both files make the same
  load-bearing negative point explicitly: §3 pins only `sub` = `client_id` for client
  authentication; `iss` is never required to equal `client_id`.
- AS validation MUSTs identical, including Simple String Comparison (RFC 3986 §6.2.1) for issuer and
  audience, reject-expired subject to clock skew, reject invalid signature/MAC, reject
  otherwise-invalid JWTs, and the error-code split: `invalid_grant` (§3.1) vs `invalid_client` (§3.2).
- Part B (CIMD -02) identical on: all 7 Client Identifier URL shape rules and the
  simple-string-comparison / no-port-normalization rule (§3); `client_id` triple-match requirement
  (§4); 200 OK MUST + all-other-statuses-error + MUST NOT follow redirects (§4, §5); SHOULD
  fetch/re-fetch, SHOULD abort on failure (§5, §5.1); caching rules including MUST NOT cache errors
  or invalid documents (§5.2); shared-secret prohibitions (`client_secret_post`,
  `client_secret_basic`, `client_secret_jwt`, `client_secret`, `client_secret_expires_at`, no
  private keys; `jwks`/`jwks_uri` only) (§4.1); `private_key_jwt` → AS MUST require RFC 7523 §2.2
  authentication with the discovered key (§8.2); RFC 9700 redirect-URL registration + exact match
  (§4.2); SSRF MUST NOTs with dev-only loopback exception (§8.6); 5-kilobyte SHOULD-level read limit
  and absence of any timeout values (§8.7).
- Both independently flag the same internal contradiction: CIMD §6 says RFC 8414 publishers "MUST
  include" `client_id_metadata_document_supported` while labeling the property OPTIONAL.

---

## Pair 7 — Grant Management: `qa/v1b-grantmgmt.md` ↔ `references/grant-management.md`

**Verdict: 1 minor discrepancy (GAP); otherwise clean**

**Explicit question — where `grant_management_action` may appear:** The reference file **correctly**
states authorization request only, matching the blind file; neither file places it in the token
request.

- Blind file: "`grant_management_action` is defined as an **authorization request** parameter
  (Section 5.2 ...). It is NOT defined as a token-request parameter; IANA registration (Appendix
  A.1) lists its parameter location as \"authorization request\" only (`grant_id` is registered for
  \"authorization request, token response\")."
- Reference file (parameter table): "`grant_management_action` | authorization request (IANA A.1)";
  and for `grant_id`: "authorization request (also token response, Section 5.5; IANA A.1 registers
  it for both locations)".

Agreement on everything else checked:

- Action values `create` / `merge` / `replace` with identical semantics; `merge`/`replace` require
  `grant_id`; both quote the lowercase "shall invalidate existing refresh tokens" for merge and
  replace; both flag the stale `update` mention in Section 5.5 (renamed to `merge` in -02).
- Metadata names and values identical: `grant_management_endpoint`,
  `grant_management_actions_supported` (allowed values `query`, `revoke`, `merge`, `replace`,
  `create`; omitted = no support), `grant_management_action_required` (boolean, default `false`);
  both flag the IANA A.2 copy-paste error describing `grant_management_actions_supported` as
  "authorization details types".
- API scopes `grant_management_query` / `grant_management_revoke` with lowercase "required" (§6.1);
  confidential-clients-only restriction (Section 5.1); https-scheme lowercase must (Section 6.2);
  grant resource URL = endpoint + `/` + `grant_id` (Section 6.3) — identical.
- Query response shape identical (`scopes` with `scope`/`resource`, `claims`,
  `authorization_details`, `expires_at`, `created_at`, `updated_by` with values 'client' /
  "authorization_server", extension MAY, 503 + Retry-After); both flag the `last_updated` (prose)
  vs `last_updated_at` (example) inconsistency without resolving it.
- Revocation levels identical and both draw the load-bearing level split: DELETE → 204; "The AS
  MUST revoke the grant and all refresh tokens issued based on that particular grant" (capitalized
  MUST) vs "it should revoke all access tokens" (lowercase should); both give the RFC 7009 contrast.
- Errors identical: `invalid_grant_id` and the three `invalid_request` triggers (Section 5.4,
  lowercase "shall respond"); API errors 404 / 403 / 401 + `invalid_token` (Section 6.6).
- Token response `grant_id` rules (lowercase must return; must be unique; should have entropy) —
  identical; both note `grant_id` should not appear in the authorization response (Section 5.3) and
  the Section 9 PII rule.

### Discrepancy 7.1 — GAP (minor)

The blind file records that the IANA Appendix A.2 registration description of
`grant_management_action_required` uses a **capitalized MUST**, whereas Section 7.1 uses lowercase
"must"; the reference file records only the lowercase form. Under this draft's caps-only BCP 14
convention, a capitalized MUST in A.2 is a (minor) requirement-level data point missing from the
reference.

- Blind file: "`grant_management_action_required` — OPTIONAL. Boolean; if `true`, all authorization
  requests must specify a `grant_management_action` (lowercase must in Section 7.1; the IANA A.2
  description uses capitalized \"MUST\"). Defaults to `false` if omitted."
- Reference file: "`grant_management_action_required` — OPTIONAL. Boolean; if `true`, all
  authorization requests must specify a `grant_management_action`. Defaults to `false`."

Not a MISMATCH: the reference's capitalization survey is hedged ("Only a few (e.g. the revocation
MUST in Section 6.5, MAY in Section 6.4) are capitalized"), so the two files state compatible facts;
the reference simply omits the A.2 datum.

---

## Summary of discrepancies by class

| # | Pair | Class | Severity | Description |
|---|------|-------|----------|-------------|
| 7.1 | Grant Management | GAP | Minor | IANA A.2 description of `grant_management_action_required` uses capitalized "MUST" (per blind file); reference records only the lowercase §7.1 "must". |

| Class | Count |
|---|---|
| MISMATCH | 0 |
| LEVEL-SHIFT | 0 |
| GAP | 1 |
| NAMING | 0 |

**Overall:** 6 of 7 pairs fully CLEAN; 1 minor GAP in the grant-management pair. No identifier
string, requirement level, section attribution, or load-bearing semantic statement conflicts
anywhere. On the two targeted questions: (Pair 2) both files place all normative RAR obligations on
the AS and treat RS enforcement as AS-enabled architecture — the reference's "no normative RS-side
obligation" claim is compatible with the blind file's §1/§9 account; (Pair 7) the reference
correctly restricts `grant_management_action` to the authorization request (never the token
request), agreeing with the blind extraction and IANA A.1.
