# V1-B Blind Re-Extraction: Grant Management for OAuth 2.0 (Draft)

Source: `spec-src/agent-credentials-grants/grant-mgmt-ID1.html` — "Grant Management for OAuth 2.0 (Draft)", Internet-Draft `oauth-v2-grant-management-03`, FAPI WG, published 9 May 2023 (Lodderstedt, Low, Postnikov).

Notational conventions note (unnumbered "Notational Conventions" section): BCP 14 keywords are normative "when, and only when, they appear in all capitals". Most requirements in this draft use lowercase must/shall/should, so capitalization is tracked below.

## 1. `grant_management_action` — allowed values and semantics (Section 5.2)

`grant_management_action` is defined as an **authorization request** parameter (Section 5.2: "This specification introduces the authorization request parameters `grant_id` and `grant_management_action`. These parameters can be used with any request serving as authorization request, e.g. it may be used with CIBA requests."). It is NOT defined as a token-request parameter; IANA registration (Appendix A.1) lists its parameter location as "authorization request" only (`grant_id` is registered for "authorization request, token response").

Defined values (Section 5.2):

- `create` — "The AS will create a fresh grant if the AS supports the grant management action `create`." (Providing `grant_id` with `create` → error `invalid_request`, Section 5.4.)
- `merge` — Requires the client to specify a grant id via the `grant_id` parameter. If present and supported, "the AS will merge the permissions consented by the resource owner in the actual request with those which already exist within the grant and shall invalidate existing refresh tokens associated with the updated grant" (lowercase shall).
- `replace` — Requires `grant_id`. If present and supported, "the AS will change the grant to be ONLY the permissions requested by the client and consented by the resource owner in the actual request and shall invalidate existing refresh tokens associated with the replaced grant" (lowercase shall).

Related: Section 3.7 — clients obtain fresh access (and optionally refresh) tokens for an existing grant by re-issuing an authorization request referencing the grant with `grant_management_action=merge`.

Source inconsistency: Section 5.5 says the AS must return a `grant_id` when the action is "valid and supported (for example, `create`, `update` or `replace`)" — `update` appears to be a stale leftover; Document History (-02) records "renamed `update` action to `merge`".

## 2. Endpoint, AS metadata field names, API scopes — exact strings

Endpoint (Sections 6.2, 6.3):
- The Grant Management API is a new endpoint provided by the authorization server; its URL is discovered via server metadata parameter `grant_management_endpoint` (Section 6.2). No fixed path is defined.
- Grant Resource URL (Section 6.3) = grant management endpoint URL + `/` + `grant_id` (e.g. `https://as.example.com/grants/TSdqirmAxDa0_-DB_1bASQ`).
- "Communication with the Grant Management API must use the \"https\" scheme." (Section 6.2, lowercase must.)

AS metadata (Section 7.1, "Authorization server's metadata"; IANA Appendix A.2):
- `grant_management_actions_supported` — OPTIONAL. JSON array of actions supported by the AS. Allowed values: `query`, `revoke`, `merge`, `replace`, `create`. If omitted, the AS does not support any grant management actions.
- `grant_management_endpoint` — OPTIONAL. "URL of the authorization server's Grant Management Administration Endpoint."
- `grant_management_action_required` — OPTIONAL. Boolean; if `true`, all authorization requests must specify a `grant_management_action` (lowercase must in Section 7.1; the IANA A.2 description uses capitalized "MUST"). Defaults to `false` if omitted.

API scopes (Section 6.1, "API authorization"): "The token is required to be associated with the following scope value:" (lowercase "required"):
- `grant_management_query` — "Scope value the client uses to request an access token to query the status of its grants."
- `grant_management_revoke` — "Scope value the client uses to request an access token to revoke its grants."

(The grant type used to obtain this access token is out of scope of the spec.)

## 3. Grant query (GET) response JSON shape (Section 6.4)

HTTP GET to the grant resource URL with `Authorization: Bearer ...`; 200 OK, `Content-Type: application/json`, `Cache-Control: no-cache, no-store`.

Top-level members (all optional):
- `scopes` — JSON array; every JSON object may contain:
  - `scope` — JSON string (space-delimited scope values, per examples e.g. `"contacts read"`, `"openid email address phone"`),
  - `resource` — array of one or more absolute URIs referencing resources (RFC 8707 resource indicators) authorized for that scope. Mapping of scopes to resources is at the AS's discretion.
- `claims` — JSON array of names of all OpenID Connect claims requested by the client and consented by the Resource Owner across authorization requests associated with the grant.
- `authorization_details` — JSON array of JSON objects as defined in [I-D.ietf-oauth-rar] (example objects show nested `type` string, `actions` array, `locations` array).
- Grant info fields (each optional, NumericDate = seconds since 1970-01-01T00:00:00Z UTC):
  - `last_updated` — per the prose field list ("time when the grant was last updated"); **the example JSON instead shows `last_updated_at`** — a source inconsistency (Document History -02 says "added `expires_at`, `created_at`, `last_updated` and `updated_by`").
  - `expires_at` — time when the grant expires (NumericDate).
  - `created_at` — time when the grant was originally created (NumericDate).
  - `updated_by` — string indicating who updated the grant; "Allowed values are 'client' and \"authorization_server\"." (example: `"updated_by":"client"`).
- "The response structure MAY also include further elements defined by extensions." (capitalized MAY).

Under high load the OP may return HTTP 503 with a Retry-After header (RFC 7231 Section 7.1.3); clients should respect it (lowercase should).

## 4. Revocation (DELETE) semantics (Section 6.5)

- Client sends HTTP DELETE to the grant's resource URL; "The authorization server responds with an HTTP status code 204 and an empty response body." (example: `HTTP/1.1 204 No Content`).
- Requirement (Section 6.5): "The AS MUST revoke the grant and all refresh tokens issued based on that particular grant, it should revoke all access tokens issued based on that particular grant."
  - Grant: MUST revoke (capitalized MUST — normative).
  - Refresh tokens (all issued on that grant): MUST revoke (covered by the same capitalized MUST).
  - Access tokens (all issued on that grant): should revoke (lowercase should — not a BCP 14 capitalized keyword).
- Contrast note: RFC 7009 token revocation is not required to revoke the underlying grant; retaining the grant on token revocation is at the AS's discretion.
- Security consideration (Section 10): after `replace`, where self-contained access tokens are used and immediate propagation is needed, "the AS should immediately revoke all relevant tokens by an out-of-band means" (lowercase should).

## 5. Error codes defined

Authorization Error Response (Section 5.4) — all with lowercase "shall respond":
- `invalid_grant_id` — when `grant_id` is unknown, invalid, or the logged in user doesn't match a resource owner. (Registered in IANA "OAuth Extensions Error registry", Appendix A.3.)
- `invalid_request` — when (a) `grant_id` is provided for the `create` action; (b) `grant_id` is provided and the action is not specified; (c) the AS does not support the requested grant management action, or the action is required (per `grant_management_action_required` metadata) but not specified.

Grant Management API Error Responses (Section 6.6):
- HTTP 404 — resource URL unknown.
- HTTP 403 — client not authorized to perform the call.
- HTTP 401 with error code `invalid_token` — request lacks a valid access token.
- (Section 6.4: HTTP 503 with Retry-After under high load.)

## 6. Eight most load-bearing requirements

1. **DELETE revokes grant + refresh tokens** — "The AS MUST revoke the grant and all refresh tokens issued based on that particular grant" — MUST, capitalized (the only capitalized MUST in the body text). (Section 6.5)
2. **DELETE and access tokens** — "...it should revoke all access tokens issued based on that particular grant" — should, lowercase (non-capitalized). (Section 6.5)
3. **`merge` invalidates refresh tokens** — AS merges newly consented permissions with existing ones "and shall invalidate existing refresh tokens associated with the updated grant" — shall, lowercase; also requires `grant_id` to be specified. (Section 5.2)
4. **`replace` narrows grant and invalidates refresh tokens** — grant becomes "ONLY the permissions requested by the client and consented by the resource owner in the actual request and shall invalidate existing refresh tokens associated with the replaced grant" — shall, lowercase ("ONLY" capitalized in source); requires `grant_id`. (Section 5.2)
5. **Token response `grant_id`** — "The AS must return a `grant_id` if the `grant_management_action` request parameter is provided and specified action is valid and supported" — must, lowercase. `grant_id` value "must be unique in the context of a certain authorization server and should have enough entropy to make it impractical to guess it" — must/should, lowercase. (Section 5.5)
6. **Authorization error on bad grant_id** — "In case the `grant_id` is unknown, invalid or logged in user doesn't match a resource owner, the authorization server shall respond with an error code `invalid_grant_id`" — shall, lowercase. (Section 5.4)
7. **Confidential clients only** — "Grant management is restricted to confidential only clients due to security reasons." — declarative statement, no BCP 14 keyword. (Section 5.1)
8. **API scope requirement** — "The token is required to be associated with the following scope value:" `grant_management_query` / `grant_management_revoke` — "required", lowercase (not "REQUIRED"). (Section 6.1)

Runners-up: Grant Management API "must use the \"https\" scheme" (Section 6.2, lowercase must); if `grant_management_action_required` is `true`, all authorization requests must specify a `grant_management_action` (Section 7.1 lowercase must; Appendix A.2 IANA description capitalizes MUST); `grant_id` "should not be included in the authorization response" (Section 5.3, lowercase should); "It must not be possible to identify the user or derive any personally identifiable information (PII) based on `grant_id` alone" (Section 9, lowercase must not).

## Source ambiguities noted

1. Query-response field name conflict: prose defines `last_updated`, but the Section 6.4 example JSON uses `last_updated_at`.
2. Section 5.5 lists example valid actions as "`create`, `update` or `replace`" although `update` was renamed to `merge` in -02 (per Document History); `merge` is the defined value.
3. `updated_by` allowed values are given with mixed quoting: 'client' and "authorization_server".
4. Nearly all requirements use lowercase keywords, which per the document's own Notational Conventions are not BCP 14 normative; the sole capitalized MUST in the body is the DELETE revocation rule (plus a MAY in Section 6.4 and a MUST in the Appendix A.2 IANA description).
5. Metadata `grant_management_actions_supported` allows `query` and `revoke` (API operations) in addition to the three `grant_management_action` request-parameter values — the two lists are distinct. IANA A.2's description of `grant_management_actions_supported` ("JSON array containing the authorization details types the AS supports") is an apparent copy-paste error inconsistent with Section 7.1.
