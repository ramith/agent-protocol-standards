# Grant Management for OAuth 2.0

Source: grant-mgmt — https://openid.net/specs/oauth-v2-grant-management-ID1.html — Implementer's Draft 1 (NOT final; check https://openid.net/developers/specs/ for newer) — fetched 2026-08-05 — extracted 2026-08-05

Document identity (from the HTML header): Internet-Draft `oauth-v2-grant-management-03`, OpenID FAPI Working Group, published 9 May 2023, Standards Track. Authors: T. Lodderstedt (yes.com), S. Low (Biza.io), D. Postnikov (Independent).

## 1. Overview

OAuth grants (the privileges a resource owner delegated to a client) have no explicit representation in base OAuth, so clients cannot query, update, or revoke them directly (Section 1). This spec makes the grant a first-class referenceable object: a `grant_id` identifies an individual grant, new authorization request parameters control grant creation/update, and a new Grant Management API lets clients query a grant's status and revoke it (Sections 1, 2). Design principle: creating and updating grants always goes through an OAuth authorization request (resource-owner interaction assumed); query and revoke go through the Grant Management API (Section 2). The client is expected to manage its grant ids and tokens itself; the API offers no bulk listing (Sections 2, 6).

## 2. Request parameters (Section 5.2, Authorization Request)

Both parameters may be used with any request serving as an authorization request, e.g. CIBA requests (Section 5.2).

| Parameter | Where | Definition (Section 5.2) |
|---|---|---|
| `grant_id` | authorization request (also token response, Section 5.5; IANA A.1 registers it for both locations) | OPTIONAL. String identifying an individual grant managed by a particular AS for a certain client and a certain resource owner. Must have been issued by that AS; the client must be authorized to use it. |
| `grant_management_action` | authorization request (IANA A.1) | String controlling how the AS handles the grant when processing the authorization request. |

Allowed `grant_management_action` values defined in Section 5.2:

- `create` — the AS creates a fresh grant (if the AS supports the `create` action).
- `merge` — requires `grant_id`. The AS merges the permissions consented in this request with those already in the grant, and "shall invalidate existing refresh tokens associated with the updated grant".
- `replace` — requires `grant_id`. The AS changes the grant to be ONLY the permissions requested and consented in this request, and "shall invalidate existing refresh tokens associated with the replaced grant".

Spec example (Section 5.2, trimmed):

```http
GET /authorize?response_type=code&
     client_id=s6BhdRkqt3
     &grant_management_action=merge
     &grant_id=TSdqirmAxDa0_-DB_1bASQ
     &scope=write ... HTTP/1.1
Host: as.example.com
```

Authorization response is unchanged; `grant_id` should not be included in the authorization response (Section 5.3). Error responses (Section 5.4): error code `invalid_grant_id` when the `grant_id` is unknown, invalid, or the logged-in user does not match a resource owner; `invalid_request` when `grant_id` accompanies `create`, when `grant_id` is provided without an action, when the AS does not support the requested action, or when an action is required (per `grant_management_action_required` metadata) but missing.

## 3. Token response (Section 5.5)

New token response parameter `grant_id`: a URL-safe string identifying an individual grant; must be unique in the context of the AS and should have enough entropy to make guessing impractical. The AS must return a `grant_id` if the `grant_management_action` request parameter was provided and the action is valid and supported ("for example, `create`, `update` or `replace`" — sic; see notes). Spec example (Section 5.5, trimmed):

```json
{
   "access_token": "2YotnFZFEjr1zCsicMWpAA",
   "token_type": "example",
   "expires_in": 3600,
   "refresh_token": "tGzv3JOkF0XG5Qx2TlKWIA",
   "grant_id": "TSdqirmAxDa0_-DB_1bASQ"
}
```

## 4. Grant Management API (Section 6)

Supported actions: Query (retrieve current status of a specific grant) and Revoke (Section 6). No bulk access to all of a client's grants (functional and privacy reasons); the API never exposes tokens associated with a grant (Section 6).

- **Discovery**: the endpoint URL comes from the AS metadata parameter `grant_management_endpoint` (Sections 6.2, 7.1). Communication must use the "https" scheme (Section 6.2).
- **Grant resource URL** (Section 6.3): grant management endpoint URL + `/` + `grant_id`, e.g. `https://as.example.com/grants/TSdqirmAxDa0_-DB_1bASQ`.

### Query (Section 6.4)

HTTP GET to the grant resource URL with a Bearer access token. JSON response fields describing the granted privileges (all optional):

- `scopes` — JSON array of objects; each may contain a `scope` field (JSON string) and a `resource` field (array of absolute URIs referencing resources per RFC 8707 authorized for that scope). The mapping of scope values to resource indicators is at the AS's discretion.
- `claims` — JSON array of names of all OpenID Connect claims requested by the client (as RP) and consented by the resource owner across the grant's authorization requests. Consented-claims definition is implementation-defined when special scopes (e.g. `profile`) are used.
- `authorization_details` — JSON array of objects as defined in the OAuth Rich Authorization Requests draft [I-D.ietf-oauth-rar], containing all authorization details requested and consented for the grant.

Additional grant info fields (all optional, Section 6.4): `last_updated`, `expires_at`, `created_at` (each a NumericDate — seconds since 1970-01-01T00:00:00Z UTC), and `updated_by` (string; allowed values 'client' and "authorization_server"). The response MAY include further elements defined by extensions. Spec example (Section 6.4, trimmed):

```json
{
   "scopes":[
      {"scope":"contacts read", "resource":["https://rs.example.com/api1"]},
      {"scope":"write", "resource":["https://rs.example.com/api2","https://rs.example.com/api3"]},
      {"scope":"openid"}
   ],
   "claims":["given_name","nickname","email","email_verified"],
   "authorization_details":[
      {"type":"account_information",
       "actions":["list_accounts","read_balances","read_transactions"],
       "locations":["https://example.com/accounts"]}
   ],
   "created_at":1356123600, "last_updated_at":1356123600,
   "expires_at":1356123600, "updated_by":"client"
}
```

Under high load the OP may return HTTP 503 with a Retry-After header; clients should retry only after the indicated time (Section 6.4).

### Revoke (Section 6.5)

HTTP DELETE to the grant resource URL; the AS responds with HTTP 204 and an empty body. On revocation: "The AS MUST revoke the grant and all refresh tokens issued based on that particular grant, it should revoke all access tokens issued based on that particular grant." Contrast with RFC 7009 token revocation: revoking a token is not required to revoke the underlying grant; the AS may retain the grant so the client can re-connect to it via a later authorization request (Section 6.5 Note).

### Error responses (Section 6.6)

Unknown resource URL → HTTP 404. Client not authorized for the call → HTTP 403. Missing/invalid access token → HTTP 401 with error code `invalid_token`.

## 5. AS metadata (Section 7.1; IANA registration in Appendix A.2)

- `grant_management_actions_supported` — OPTIONAL. JSON array of actions the AS supports. Allowed values: `query`, `revoke`, `merge`, `replace`, `create`. If omitted, the AS does not support any grant management actions.
- `grant_management_endpoint` — OPTIONAL. URL of the AS's Grant Management Administration Endpoint.
- `grant_management_action_required` — OPTIONAL. Boolean; if `true`, all authorization requests must specify a `grant_management_action`. Defaults to `false`.

## 6. Security / authorization for the API (Section 6.1)

The client must obtain an access token authorized for the Grant Management API; the grant type used to obtain it is out of scope. Required scope values: `grant_management_query` (to query grant status) and `grant_management_revoke` (to revoke grants). Grant management as a whole is restricted to confidential clients only, for security reasons (Section 5.1). A grant id is a public identifier, not a secret — implementations must assume grant ids leak (e.g. via authorization requests), so grant data must be protected by client authentication/authorization (Section 10).

## 7. Normative requirements

- Grant management is restricted to confidential-only clients (Section 5.1).
- `grant_id` in a request must have been issued by that AS, and the client must be authorized to use it (Section 5.2).
- `merge`/`replace` require the client to supply `grant_id`; the AS shall invalidate existing refresh tokens associated with the updated/replaced grant (Section 5.2).
- The AS shall return `invalid_grant_id` / `invalid_request` for the error cases enumerated in Section 5.4.
- The AS must return a `grant_id` in the token response when a valid, supported `grant_management_action` was requested (Section 5.5).
- Token-response `grant_id` must be unique per AS and should have enough entropy to resist guessing (Section 5.5).
- If tokens are never claimed, the AS should delete the grant after a reasonable timeout (Section 5.6.1); the AS may remove obsolete grants at its discretion, considering status/expiry of grant elements (Section 5.6.3).
- Grant Management API communication must use "https" (Section 6.2).
- Query response MAY include further extension-defined elements (Section 6.4); clients should respect 503 Retry-After (Section 6.4).
- On DELETE, the AS MUST revoke the grant and all refresh tokens issued based on it, and should revoke all access tokens issued based on it (Section 6.5).
- It must not be possible to identify the user or derive PII from `grant_id` alone (Section 9).
- After `replace` narrows permissions, with self-contained access tokens and a propagation requirement shorter than token lifespan, the AS should immediately revoke relevant tokens out-of-band (Section 10).
- Deployments should issue audience-restricted access tokens (existing "aud" claim) (Section 8.3).
- AS support for sharing grants among client ids of the same logical client is recommended (Section 8.1); `grant_id` could potentially be shared across client ids of the same entity (Section 9).

## 8. Ambiguities & notes

- **Maturity**: Implementer's Draft 1 (draft -03, May 2023), not a Final Specification. Parameter names, actions, and API shape may change in later drafts/final; verify against the current spec before relying on details.
- **Lowercase keywords**: the BCP 14 note says keywords are normative only in ALL CAPS, yet most requirement language in the body is lowercase ("must", "shall", "should"). Only a few (e.g. the revocation MUST in Section 6.5, MAY in Section 6.4) are capitalized. Guidance — ours, not spec: treat the lowercase ones as intended requirements but expect interoperability wiggle room.
- **`update` vs `merge`**: the action was renamed `update` → `merge` in draft -02 (Appendix D), but stale "update" mentions remain in Sections 5.5 ("for example, `create`, `update` or `replace`") and 5.6.2. The defined action value is `merge`.
- **`last_updated` vs `last_updated_at`**: Section 6.4 prose defines `last_updated`, but the Section 6.4 example uses `"last_updated_at"`. The spec does not resolve this; implementations may emit either.
- **IANA description mismatch**: Appendix A.2 describes `grant_management_actions_supported` as a "JSON array containing the authorization details types the AS supports" — apparently a copy-paste error; Section 7.1 defines it as the supported actions.
- Metadata actions (`query`, `revoke`) and request actions (`create`, `merge`, `replace`) form one 5-value set in `grant_management_actions_supported`; only `create`/`merge`/`replace` are valid `grant_management_action` request values (Sections 5.2, 7.1).
- Out of scope (Section 4): historical/archived consent records and consent resources shared with third parties (e.g. central consent dashboards).
