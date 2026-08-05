Source: rfc8693 — https://www.rfc-editor.org/rfc/rfc8693.txt — RFC (immutable) — fetched 2026-08-05 — extracted 2026-08-05

# RFC 8693 — OAuth 2.0 Token Exchange

## Overview
Defines an HTTP/JSON Security Token Service (STS) protocol layered on OAuth 2.0: a client POSTs a token exchange request to the authorization server's token endpoint using a new extension grant type and receives a newly issued security token in a standard token response (§1, §2). The spec also defines JWT claims and introspection response members (`act`, `scope`, `client_id`, `may_act`) to express delegation and authorization-to-act semantics (§4). Token syntax/semantics and trust models are explicitly out of scope (§1). The requester is "the client" for the exchange even if it is actually a resource server trading an inbound access token for a downstream token (§1).

## Token exchange request parameters (§2.1)
Sent to the token endpoint via HTTP POST, `application/x-www-form-urlencoded`, UTF-8 (§2.1).

| Parameter | Req/Opt | Meaning | Section |
|---|---|---|---|
| `grant_type` | REQUIRED | Must be `urn:ietf:params:oauth:grant-type:token-exchange` to signal a token exchange. | §2.1 |
| `resource` | OPTIONAL | URI of the target service/resource where the token will be used (typically an https URL, same form used to access it); lets the AS pick policy, token type/content, encryption. MUST be an absolute URI (RFC 3986 §4.3), MAY include a query component, MUST NOT include a fragment. Multiple `resource` parameters allowed for multiple targets. | §2.1 |
| `audience` | OPTIONAL | Logical name of the target service (e.g., an OAuth client identifier, SAML entity ID, or OIDC Issuer Identifier). Values must be unique within the AS. Multiple `audience` parameters allowed; may be mixed with `resource`. | §2.1 |
| `scope` | OPTIONAL | Space-delimited, case-sensitive strings (RFC 6749 §3.3) giving the desired scope of the requested token; semantics are service specific. | §2.1 |
| `requested_token_type` | OPTIONAL | Token type identifier (§3) for the requested token; if absent, the issued type is at the AS's discretion (possibly driven by `resource`/`audience`). | §2.1 |
| `subject_token` | REQUIRED | Security token representing the identity of the party on behalf of whom the request is made; typically its subject becomes the subject of the issued token. | §2.1 |
| `subject_token_type` | REQUIRED | Token type identifier (§3) for `subject_token`. | §2.1 |
| `actor_token` | OPTIONAL | Security token representing the identity of the acting party — typically the party authorized to use the requested token and act on behalf of the subject. | §2.1 |
| `actor_token_type` | Conditional | Token type identifier (§3) for `actor_token`. REQUIRED when `actor_token` is present; MUST NOT be included otherwise. | §2.1 |

- Client authentication uses normal OAuth 2.0 mechanisms; whether to allow unauthenticated clients is an AS deployment decision. Omitting client authentication lets anyone holding a compromised token launder it into other tokens via the STS (§2.1).
- Request semantics with multiple targets: the client asks for a token with the requested scope usable at all requested targets — effectively "the Cartesian product of all the scopes at all the target services" (§2.1.1). `invalid_target` can signal too many targets requested at once (§2.1.1).
- Performing an exchange does not, by itself, affect the validity of the subject or actor token, and creates no tight linkage between input and output tokens (renewal of input not reflected in output) (§2.1).

## Token type identifiers (§3)
URIs used as values of `requested_token_type`, `subject_token_type`, `actor_token_type`, and `issued_token_type` (§3). Other URIs MAY be used for other token types (§3).

| Identifier | Meaning | Section |
|---|---|---|
| `urn:ietf:params:oauth:token-type:access_token` | OAuth 2.0 access token issued by the given AS — a typical access token, opaque to the client. | §3 |
| `urn:ietf:params:oauth:token-type:refresh_token` | OAuth 2.0 refresh token issued by the given AS. | §3 |
| `urn:ietf:params:oauth:token-type:id_token` | ID Token per OpenID Connect Core §2. | §3 |
| `urn:ietf:params:oauth:token-type:saml1` | base64url-encoded SAML 1.1 assertion. | §3 |
| `urn:ietf:params:oauth:token-type:saml2` | base64url-encoded SAML 2.0 assertion. | §3 |
| `urn:ietf:params:oauth:token-type:jwt` | A JWT specifically (defined in RFC 7519 §9), e.g., for cross-domain use as an authorization grant. | §3 |

§3 draws the distinction: an access token represents a delegated authorization decision; JWT is a format. `...:access_token` means "typical opaque access token from this AS (could be a JWT, client needn't know)"; `...:jwt` means a JWT specifically.

## Response parameters (§2.2.1) and errors (§2.2.2)
Success: HTTP 200, `application/json`, parameters at the top level of a JSON object (§2.2.1).

| Parameter | Req/Opt | Meaning | Section |
|---|---|---|---|
| `access_token` | REQUIRED | The issued security token. The name is "used for historical reasons and the issued token need not be an OAuth access token". | §2.2.1 |
| `issued_token_type` | REQUIRED | Token type identifier (§3) for the representation of the issued token. | §2.2.1 |
| `token_type` | REQUIRED | Case-insensitive method of using the issued token (RFC 6749 §7.1), e.g., `Bearer`. Distinct from `issued_token_type` (which is the representation). Value `N_A` when the issued token is not an access token or usable as one. | §2.2.1 |
| `expires_in` | RECOMMENDED | Validity lifetime in seconds of the issued token. | §2.2.1 |
| `scope` | Conditional | OPTIONAL if the issued token's scope is identical to the scope the client requested; otherwise REQUIRED. | §2.2.1 |
| `refresh_token` | OPTIONAL | Typically not issued for temporary-credential-for-temporary-credential exchanges; may be issued for offline/user-not-present access. Profiles/deployments should document when to expect one. | §2.2.1 |

Errors (§2.2.2):
- If the request is invalid, or `subject_token` / `actor_token` are invalid for any reason or unacceptable per policy: the AS MUST construct an error response per RFC 6749 §5.2, and the `error` value MUST be `invalid_request` (§2.2.2).
- If the AS is unwilling or unable to issue a token for any target indicated by `resource`/`audience`: the `invalid_target` error code SHOULD be used (§2.2.2).
- The AS MAY add `error_description`; other error codes may also be used as appropriate (§2.2.2).

## The `act` (Actor) claim (§4.1)
- Expresses within a JWT "that delegation has occurred" and identifies the acting party to whom authority has been delegated. Value is a JSON object whose members are claims identifying the actor (e.g., `iss` + `sub` together may be needed to uniquely identify one) (§4.1).
- Claims inside `act` "pertain only to the identity of the actor and are not relevant to the validity of the containing JWT"; non-identity claims (`exp`, `nbf`, `aud`) are not meaningful inside `act` and are not used (§4.1).
- Chained delegation nests `act` claims. Exact rule, quoted: "The outermost \"act\" claim represents the current actor while nested \"act\" claims represent prior actors.  The least recent actor is the most deeply nested." Nested `act` claims form a history trail from the initial subject through delegation steps (§4.1).
- Authorization vs identification: "For the purpose of applying access control policy, the consumer of a token MUST only consider the token's top-level claims and the party identified as the current actor by the \"act\" claim.  Prior actors identified by any nested \"act\" claims are informational only and are not to be considered in access control decisions." (§4.1)
- Spec's nested example (Figure 6, §4.1) — token is about user@example.com; service16 is the current actor, service77 a prior actor:

```json
{
  "aud":"https://service26.example.com",
  "iss":"https://issuer.example.com",
  "sub":"user@example.com",
  "act":
  {
    "sub":"https://service16.example.com",
    "act":
    {
      "sub":"https://service77.example.com"
    }
  }
}
```

- As a top-level member of an OAuth token introspection response, `act` has the same semantics and format as the JWT claim (§4.1).

## `may_act`, `client_id`, `scope` claims
- **`may_act` (Authorized Actor, §4.4)**: states that one party is authorized to become the actor and act on behalf of another party. E.g., when a `subject_token` carries `may_act`, the AS can use it to decide whether the client (or the party in the `actor_token`) is authorized to engage in the requested delegation or impersonation. Value is a JSON object of claims identifying the eligible party (e.g., `iss` + `sub`; `email` for extra info). As with `act`, `exp`/`nbf`/`aud` are not meaningful inside it and are not used. Same semantics/format as a top-level introspection response member (§4.4).
- **`client_id` (§4.3)**: carries the client identifier of the OAuth 2.0 client that requested the token; introspection already defines the same-named parameter (§4.3).
- **`scope` (§4.2)**: a JSON string containing a space-separated list of scopes associated with the token, per RFC 6749 §3.3 (a string, not an array); introspection already defines a `scope` parameter (§4.2).

## Delegation vs impersonation (§1.1)
- **Impersonation**: when principal A impersonates principal B, A "is given all the rights that B has within some defined rights context and is indistinguishable from B in that context" — any recipient of the token is, for all intents and purposes, dealing with B. Awareness of the impersonation elsewhere in the identity system is possible but not required. A's ability to impersonate can be limited in scope, time, or one-time use (§1.1).
- **Delegation**: A retains its own identity separate from B; "it is explicitly understood that while B may have delegated some of its rights to A, any actions taken are being taken by A representing B.  In a sense, A is an agent for B." (§1.1)
- Delegation is typically expressed as a **composite token** containing both the primary subject and the actor. In the request, `subject_token` represents the party on behalf of whom the token is requested; `actor_token` represents the party to whom the access rights are being delegated. Whether/when a composite token is issued is at the AS's discretion and policy (§1.1). Non-JWT composite representations are out of scope; the JWT `act` claim represents a chain of delegation (§1.1).
- Presence signal: the impersonation example notes "delegation is impossible with only a \"subject_token\" and no \"actor_token\"" (§A.1.1). In the impersonation example the issued token's `sub` equals the subject token's subject with no `act` claim, which "effectively enables the client to impersonate that subject" at the target (§A.1.4). In the delegation example the issued token's `sub` equals the `subject_token` subject and `act.sub` equals the `actor_token` subject (§A.2.5).
- Neither semantic applies when a principal acts directly on its own behalf; they are simply the most common token exchange semantics (§1.1).

## Normative requirements (issuing / validating exchanged tokens)
- `grant_type` is REQUIRED and must be the value `urn:ietf:params:oauth:grant-type:token-exchange` (§2.1).
- `resource` value MUST be an absolute URI, MAY include a query component, and MUST NOT include a fragment component (§2.1).
- `subject_token` and `subject_token_type` are REQUIRED in every request (§2.1).
- `actor_token_type` is REQUIRED when `actor_token` is present and MUST NOT be included otherwise (§2.1).
- The AS MUST perform the appropriate validation procedures for the indicated subject token type and, if an actor token is present, also for its indicated token type (§2.1).
- Response: `access_token`, `issued_token_type`, and `token_type` are REQUIRED; `expires_in` is RECOMMENDED (§2.2.1).
- Response `scope` is REQUIRED when the issued scope differs from the requested scope; OPTIONAL when identical (§2.2.1).
- On an invalid request, or invalid/policy-unacceptable `subject_token` or `actor_token`, the AS MUST construct an RFC 6749 §5.2 error response and the `error` value MUST be `invalid_request` (§2.2.2).
- `invalid_target` SHOULD be used when the AS is unwilling/unable to issue a token for any indicated target service (§2.2.2); the AS MAY include `error_description` (§2.2.2).
- Other URIs MAY be used to indicate token types beyond those defined in §3 (§3).
- Access control: a token consumer MUST only consider the token's top-level claims and the current actor in `act`; nested (prior) actors are informational only (§4.1).
- Tokens carrying privacy-sensitive information MUST only be transmitted over encrypted channels (e.g., TLS); where certain information must be hidden from the client, the token MUST be encrypted to its intended recipient; deployments SHOULD include only the minimally necessary data in issued tokens (§6).

## Ambiguities & notes
- Most-misquoted fact: in nested `act`, the OUTERMOST `act` is the CURRENT actor; the most deeply nested is the LEAST RECENT (earliest) actor (§4.1). Many implementations invert this.
- The error code for an invalid `subject_token`/`actor_token` is `invalid_request`, not `invalid_grant` (§2.2.2) — frequently misimplemented.
- `access_token` response member may carry a non-access-token (name is historical); pair it with `issued_token_type` to know what was issued, and `token_type` is `N_A` when the issued token is not (usable as) an access token (§2.2.1).
- `token_type` (how to use the token) vs `issued_token_type` (representation of the token) is an explicit, easy-to-confuse distinction the spec itself calls out (§2.2.1).
- `actor_token_type`'s requiredness is conditional and stated in prose rather than a leading REQUIRED/OPTIONAL label (§2.1).
- The `audience` uniqueness rule uses lowercase "must" ("must be unique within that server"), so it is not a BCP 14 keyword (§2.1).
- §4.2's `scope` claim is a single space-separated JSON string — not a JSON array.
- The spec never mandates that an `actor_token` produce an `act` claim: issuing a composite token "is at the discretion of the authorization server and applicable policy" (§1.1).
- "delegation is impossible with only a subject_token and no actor_token" appears only in the non-normative Appendix A.1.1, not the normative body.
- No linkage: exchanged tokens are independent of their inputs after issuance; revocation propagation is implementation-specific, not a protocol property (§2.1).
- Guidance — ours, not spec: when validating agent delegation chains, enforce policy only on `sub` plus the outermost `act`, and log (not authorize on) deeper `act` history; this is the direct operational reading of the §4.1 MUST.
