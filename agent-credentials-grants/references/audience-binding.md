Source: rfc8707 — https://www.rfc-editor.org/rfc/rfc8707.txt — RFC (immutable) — fetched 2026-08-05 — extracted 2026-08-05

# Audience Binding: Resource Indicators for OAuth 2.0 (RFC 8707)

## Overview

Defines the `resource` request parameter, letting a client explicitly signal to the authorization
server (AS) the identity of the protected resource(s) where it intends to use the requested access
token (§1, Abstract). This lets the AS mint tokens per-resource (encryption, content, policy) and
audience-restrict them so a token cannot be used successfully at other resources (§1).

## The `resource` parameter (§2)

Syntactic rules for the value (§2):

| Rule | Keyword | Section |
|---|---|---|
| Value is an absolute URI, as specified by Section 4.3 of RFC 3986 | MUST | §2 |
| URI includes no fragment component | MUST NOT | §2 |
| URI includes no query component — though the spec recognizes cases where a query component is "useful and necessary", e.g. query parameters that scope requests to an application | SHOULD NOT | §2 |
| Value is an identifier of the resource's identity; it MAY be a locator corresponding to a network-addressable location where the resource is hosted | MAY | §2 |
| Multiple `resource` parameters MAY be used to indicate the token is intended for use at multiple resources | MAY | §2 |

Where it may appear:
- **Authorization request** (§2.1) — at the authorization endpoint. In the implicit flow the requested resource applies to the access token returned directly; in the code flow it applies to the full authorization grant (§2.1). For an authorization request sent as a JWT, such as when using the JWT Secured Authorization Request [JWT-SAR], a single value is a JSON string; multiple values are an array of strings (§2.1).
- **Access token request** (§2.2) — at the token endpoint, "for all grant types" (§2.2).
- IANA registration confirms usage locations: "authorization request, token request" (§5.1).

Multiple-occurrence semantics: with multiple `resource` values plus `scope`, the client asks for a token with the requested scope usable at all the requested target services — "the requested access rights of the token are the cartesian product of all the scopes at all the target services" (§2.2). Although multiple occurrences of the parameter may be included in a token request, §3 encourages using only a single `resource` parameter: a multi-audience bearer token is valid at more than one resource, so any one of them can use it to access the others, requiring "a high degree of trust between the involved parties"; also, an AS may be unwilling or unable to fulfill a multi-resource token request (§3).

Value selection (§2): the client SHOULD provide the most specific URI it can for the complete API or set of resources, and SHOULD use the base URI of the API unless specific knowledge dictates otherwise. Spec examples: `https://api.example.com/` for an exclusive application on a host; `https://api.example.com/app/` when it is one of many; `https://apps.example.com/scim/` to cover all SCIM endpoints (`.../scim/Users`, `.../scim/Groups`, `.../scim/Schemas`) (§2).

## AS behavior

- **Audience restriction** (§2): the AS SHOULD audience-restrict issued access tokens to the resource(s) indicated by the `resource` parameter. The AS may use the exact `resource` value as the audience or map it to a more general URI or abstract identifier (§2).
- **Acceptability is AS discretion** (§2.2): which resource values are acceptable "is at its sole discretion based on local policy or configuration". For `refresh_token` or `authorization_code` grants, policy may limit acceptable resources to those originally granted (or a subset). In the `authorization_code` subset case, the access token is based on the requested subset, but any returned refresh token is bound to the full original grant (§2.2).
- **Downscoping vs `scope`** (§2.2): "To the extent possible", when issuing access tokens the AS should downscope (give fewer permissions than the resource owner authorized) to what the respective resource can process and needs to know — a privacy improvement. Per RFC 6749 §5.1, the AS must indicate the token's effective scope in the `scope` response parameter when it differs from the requested scope (§2.2; both "should"/"must" here are lowercase in the spec).
- **Error code** (§2): `invalid_target` — "The requested resource is invalid, missing, unknown, or malformed." Usable in response to an authorization request or access token request, including for an invalid combination of resource and scope (§2). If the AS fails to parse the value(s) or finds the resource(s) unacceptable, it should (lowercase) reject with `invalid_target` as the `error` parameter value, optionally with `error_description` (§2.1). IANA usage locations: "implicit grant error response, token error response" (§5.2).
- **Omitted parameter** (§2.1): if the client omits the parameter when requesting authorization, the AS MAY process the request with no specific resource or a predefined default resource, or MAY require clients to specify resource(s) and MAY fail omitting requests with an `invalid_target` error. These MAYs are stated for authorization requests only; §2.2 gives no omission rule for token requests.

## Normative requirements (capitalized BCP 14 keywords)

| # | Requirement | Keyword | Section |
|---|---|---|---|
| 1 | Client MAY indicate the protected resource by including the parameter in requests to the AS | MAY | §2 |
| 2 | Value MUST be an absolute URI (RFC 3986 §4.3) | MUST | §2 |
| 3 | URI MUST NOT include a fragment component | MUST NOT | §2 |
| 4 | URI SHOULD NOT include a query component (exceptions recognized) | SHOULD NOT | §2 |
| 5 | Value MAY be a locator for a network-addressable location | MAY | §2 |
| 6 | Multiple `resource` parameters MAY be used for multi-resource tokens | MAY | §2 |
| 7 | Client SHOULD provide the most specific URI it can for the complete API / resource set | SHOULD | §2 |
| 8 | Client SHOULD use the base URI of the API as the value unless specific knowledge dictates otherwise | SHOULD | §2 |
| 9 | AS SHOULD audience-restrict issued access tokens to the indicated resource(s) | SHOULD | §2 |
| 10 | On omission when requesting authorization, AS MAY process with no specific resource or a predefined default | MAY | §2.1 |
| 11 | AS MAY require clients to specify resource(s), and MAY fail authorization requests omitting the parameter with `invalid_target` | MAY | §2.1 |

## Spec examples (trimmed)

Code-flow authorization request with two resources (§2.1, Figure 2):

    GET /as/authorization.oauth2?response_type=code
       &client_id=s6BhdRkqt3
       ...
       &scope=calendar%20contacts
       &resource=https%3A%2F%2Fcal.example.com%2F
       &resource=https%3A%2F%2Fcontacts.example.com%2F HTTP/1.1

Token request narrowing to one resource (§2.2, Figure 3):

    grant_type=authorization_code
    &redirect_uri=https%3A%2F%2Fclient.example.org%2Fcb
    &code=10esc29BWC2qZB0acc9v8zAv9ltc2pko105tQauZ
    &resource=https%3A%2F%2Fcal.example.com%2F

## Ambiguities & notes

- **Token representation is not mandated.** §2 only says audience restrictions "can be communicated" via the `aud` claim in JWTs (RFC 7519) or the top-level `aud` member in a Token Introspection (RFC 7662) response; no token format or claim is required, and the AS may map the `resource` value to a more general or abstract audience identifier.
- **Audience restriction itself is only SHOULD** (§2), not MUST — an AS can ignore the parameter's audience implications and still conform.
- **Rejection is not a capitalized requirement**: §2.1 says the AS "should reject" unparseable/unacceptable values with `invalid_target` — lowercase, so not BCP 14 normative.
- **Downscoping and effective-scope signaling** in §2.2 use lowercase "should"/"must"; the effective-scope duty is inherited from RFC 6749 §5.1, not newly imposed here.
- **Multi-tenant caution** (§3): use a resource URI that includes any tenant-identifying portion (e.g. a path component) so audience restriction prevents cross-tenant token replay — stated as "it is important", not a keyword.
- **Location vs abstract identifier** (§3): "whenever feasible" the value should (lowercase) be the network-addressable location; with an abstract identifier, the client is responsible for validating out of band that endpoints receiving the token are the intended audience.
- **No resource-server validation rules**: the spec defines client request behavior and AS handling only; it states no requirements on how a resource server validates audience.
- Guidance — ours, not spec: for agent token issuance, treat `resource` + AS audience restriction as the primary replay boundary between downstream services — pair it with per-resource downscoped tokens (one `resource` per token request off a multi-resource grant, as in Figures 3/5) rather than one multi-audience token.
- Guidance — ours, not spec: since token-level audience encoding is unspecified, interoperating parties must agree out of band on the audience value (exact URI vs mapped identifier) that resource servers check.
