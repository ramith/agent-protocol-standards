Source: rfc9470 — https://www.rfc-editor.org/rfc/rfc9470.txt — RFC (immutable) — fetched 2026-08-05 — extracted 2026-08-05

# OAuth 2.0 Step Up Authentication Challenge Protocol (RFC 9470)

## Overview

A resource server (RS) that finds the authentication event behind a presented access token too weak or too old denies the request with a `WWW-Authenticate` challenge carrying the `insufficient_user_authentication` error code plus `acr_values` and/or `max_age` (§1, §2). The client relays those values as OIDC authorization request parameters to obtain a new access token whose `acr`/`auth_time` reflect the required authentication (§4, §5). The RS then evaluates the new token's authentication information via JWT claims (RFC 9068) or token introspection (RFC 7662) (§6).

## The challenge (§2–3)

- Error code: `insufficient_user_authentication` — "The authentication event associated with the access token presented with the request does not meet the authentication requirements of the protected resource" (§3). Registered in the OAuth Extensions Error Registry, usage location "resource access error response" (§10.1).
- Defined for the Bearer scheme's `error` parameter (RFC 6750) and other OAuth authentication schemes that use the same error parameter, such as DPoP (RFC 9449) (§3).

WWW-Authenticate auth-param values defined by this spec (§3):

| auth-param | Meaning | Section |
|---|---|---|
| `acr_values` | Space-separated string of authentication context class reference values in order of preference; the protected resource requires one of them for the authentication event associated with the access token | §3 |
| `max_age` | Allowable elapsed time in seconds since the last active authentication event associated with the access token (user interacting with the AS in response to an authentication prompt); may be conveyed as token or quoted-string but has to represent a non-negative integer | §3 |

Example challenge from the spec (Figure 2, §3):

```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer error="insufficient_user_authentication",
  error_description="A different authentication level is required",
  acr_values="myACR"
```

A `max_age` variant is shown in Figure 3 (§3): same error code with `max_age="5"`. Both auth-params MAY occur in the same challenge if the RS needs to express requirements about both recency and authentication level; the RS MAY also include the `scope` attribute (per RFC 6750 §3.1) if scopes are lacking (§3).

## Authorization request behavior (§4)

A client receiving a challenge with the `insufficient_user_authentication` error code SHOULD parse the `WWW-Authenticate` header for `acr_values` and `max_age` and use them, if present, when constructing an authorization request sent to the AS's authorization endpoint via the user agent (§4). `acr_values` and `max_age` are both OPTIONAL authorization request parameters defined in Section 3.1.2.1 of OIDC; this document changes nothing about AS processing of them, so any OIDC-implementing AS can participate with little or no change (§4).

Example request URI after the Figure 2 challenge (Figure 4, §4):

```
https://as.example.net/authorize?client_id=s6BhdRkqt3
&response_type=code&scope=purchase&acr_values=myACR
```

The `max_age` equivalent (Figure 5, §4) uses `&max_age=5` instead.

## Token/claims side (§5–6)

- Who asserts: the authorization server. An AS complying with this spec reacts to `acr_values`/`max_age` in the request by including `acr` and `auth_time` in the access token (§5). Background OIDC behavior cited in §5: on `acr_values`, the AS MAY authenticate to satisfy the requested ACR and include it in the ID Token's `acr` claim, and SHOULD otherwise reflect the current session's level (OIDC §5.5.1.1); if `max_age` is present, the AS MUST include `auth_time` in the issued ID Token (OIDC §3.1.2.1).
- For access tokens, the AS SHOULD treat the requested acr value as necessary to fulfil the request: include it only if authentication met it, otherwise fail with the `unmet_authentication_requirements` error defined in [OIDCUAR] — this prevents clients looping on tokens the RS already rejected (§5).
- Who validates: the resource server assesses the "authentication level" of the token and decides if it meets the resource's criteria (§2, §6).
- JWT access tokens (§6.1): the `auth_time` and `acr` claims (per RFC 9068 §2.2.1) convey the time and context of the user-authentication event; their values are set at user-authentication time and do not change on access token renewals. Example decoded claims (Figure 6, trimmed): `"auth_time": 1646340198, "acr": "myACR"`.
- Token introspection (§6.2): defines two top-level introspection response members — `acr` (string ACR value satisfied by the user-authentication event) and `auth_time` (JSON numeric, seconds since 1970-01-01T00:00:00Z UTC of the authentication event); both IANA-registered (§10.2). Example response (Figure 7, trimmed): `{"active": true, ..., "auth_time": 1646340198, "acr": "myACR"}`.
- Deployment prerequisites called out: the RS needs some agreed way to evaluate the token's authentication event — JWT or introspection are the two profiled; other methods are possible per AS/RS agreement but out of scope (§2, §6). An AS advertises support by publishing `acr_values_supported` (OIDC Discovery §3) in its RFC 8414 metadata document, signaling it will understand and honor `acr_values` and `max_age` in authorization requests (§7). Achievable UX depends on RS/AS policy pairs; the spec imposes no constraints on those policies (§8).

## Normative requirements

| Req | Actor | Requirement | Section |
|---|---|---|---|
| SHOULD | Client | On an `insufficient_user_authentication` challenge, parse `WWW-Authenticate` for `acr_values` and `max_age` and use them, if present, in the authorization request | §4 |
| SHOULD | AS | Consider the requested acr value necessary to fulfil the request when issuing the access token; otherwise fail with `unmet_authentication_requirements` [OIDCUAR] | §5 |
| MUST NOT | Anyone | Use this document to position OAuth as an authentication protocol | §9 |
| MAY | RS | Include both `max_age` and `acr_values` in the same challenge, if it needs to express requirements about both recency and authentication level | §3 |
| MAY | RS | Include the `scope` attribute (RFC 6750 §3.1) if required scopes are also lacking | §3 |
| MAY | AS/RS | Use encoding/validation methods other than JWT (RFC 9068) or introspection (RFC 7662) — out of scope | §6 |
| MAY | RS | Return a challenge without verifying the client presented a valid token (but this leaks required token properties to unproven actors) | §9 |
| MUST (OIDC, restated) | AS | Include `auth_time` in the issued ID Token when the request includes `max_age` (OIDC §3.1.2.1) | §5 |

## Ambiguities & notes

- "Authentication level" and "step up" are explicitly metaphors: they "do not suggest that there is an absolute hierarchy of authentication methods expressed in interoperable fashion" (§2).
- How the RS determines/expresses/publishes its authentication requirements is out of scope (§3 note).
- The auth-params are only defined for use with `insufficient_user_authentication`, but future specs may define their use with other error codes (§3).
- A stepped-up token does not necessarily supersede older tokens (e.g., high-ACR short-lived tokens); the spec recommends no token-caching strategy, and clients "must not" (lowercase, non-BCP14) inspect access token content (§2).
- The `max_age` non-negative-integer constraint is phrased "has to represent", not as a capitalized BCP 14 keyword (§3).
- §5's OIDC citations (MAY/SHOULD for `acr` in ID Tokens, MUST for `auth_time`) are OIDC requirements restated, not new RFC 9470 normatives; only the access-token SHOULD is native to §5.
- Security: `acr_values` in a challenge can leak information about the user/resource/AS (e.g., flagging high-privilege users for phishing); challenge logic may run before or after token validation; a malicious RS can abuse the user-interaction trigger (§9).
- Guidance — ours, not spec: for agent flows, treat the challenge as a signal to re-run the user-facing authorization leg — an agent holding only its own credentials cannot satisfy a user step-up on its own.
