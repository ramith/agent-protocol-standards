Source: rfc9449 — https://www.rfc-editor.org/rfc/rfc9449.txt — RFC (immutable) — fetched 2026-08-05 — extracted 2026-08-05

# RFC 9449 — OAuth 2.0 Demonstrating Proof of Possession (DPoP)

## Overview

Application-level mechanism for sender-constraining OAuth 2.0 access and refresh tokens (§1). The client proves possession of a public/private key pair by sending a `DPoP` HTTP header whose value is a JWT ("DPoP proof"); the authorization server binds issued tokens to the public key, and recipients verify the binding (§1, §3). DPoP is not a client authentication method (§3) and is not a substitute for secure transport — it "MUST always be used in conjunction with HTTPS" (§2). Each HTTP request requires a unique DPoP proof (§4).

## DPoP proof JWT structure (§4.2)

A DPoP proof is a JWT signed (JWS) with a private key chosen by the client. The `DPoP` header field value uses token68 syntax; the header field name is case insensitive but case is significant in the value (§4.1).

JOSE Header — MUST contain at least (§4.2):

| Parameter | Required | Meaning | Section |
|---|---|---|---|
| `typ` | Required | Value `dpop+jwt`; explicitly types the DPoP proof JWT (per RFC 8725 §3.11) | §4.2 |
| `alg` | Required | JWS asymmetric digital signature algorithm identifier; MUST NOT be `none` or a symmetric (MAC) algorithm | §4.2 |
| `jwk` | Required | The client's public key in JWK format (RFC 7517, as defined in RFC 7515 §4.1.3); MUST NOT contain a private key | §4.2 |

Payload claims (§4.2):

| Claim | Required | Meaning | Section |
|---|---|---|---|
| `jti` | Required | Unique identifier for the proof; negligible collision probability in the validity window (e.g., ≥96 bits of pseudorandom data or a version 4 UUID); usable for replay detection | §4.2 |
| `htm` | Required | HTTP method of the request the JWT is attached to | §4.2 |
| `htu` | Required | HTTP target URI of the request, without query and fragment parts | §4.2 |
| `iat` | Required | Creation timestamp of the JWT (RFC 7519 §4.1.6) | §4.2 |
| `ath` | Required when the proof accompanies an access token at a protected resource (§7) | base64url encoding of the SHA-256 hash of the ASCII encoding of the access token's value | §4.2 |
| `nonce` | Required when the server provided a `DPoP-Nonce` header (§8, §9) | A recent nonce provided via the `DPoP-Nonce` HTTP header | §4.2 |

A proof MAY contain other JOSE Header Parameters or claims per extension, profile, or deployment (§4.2). Only the HTTP method and URI are covered by the proof (§4.2).

Spec example, decoded proof content (§4.2, Figure 4):

```json
{
  "typ":"dpop+jwt",
  "alg":"ES256",
  "jwk": {
    "kty":"EC",
    "x":"l8tFrhx-34tV3hRICRDY9zCkDlpBhF42UQUfWVAWBFs",
    "y":"9VE4jf_Ok_o64zbTTlcuNJajHmt6v9TDVrU0CdvGRDA",
    "crv":"P-256"
  }
}
.
{
  "jti":"-BwC3ESc6acc2lTc",
  "htm":"POST",
  "htu":"https://server.example.com/token",
  "iat":1562262616
}
```

## Proof validation checks (§4.3)

To validate a DPoP proof, the receiving server MUST ensure the following (§4.3; checks may be performed in any order):

1. There is not more than one `DPoP` HTTP request header field.
2. The `DPoP` HTTP request header field value is a single and well-formed JWT.
3. All required claims per §4.2 are contained in the JWT.
4. The `typ` JOSE Header Parameter has the value `dpop+jwt`.
5. The `alg` JOSE Header Parameter indicates a registered asymmetric digital signature algorithm, is not `none`, is supported by the application, and is acceptable per local policy.
6. The JWT signature verifies with the public key contained in the `jwk` JOSE Header Parameter.
7. The `jwk` JOSE Header Parameter does not contain a private key.
8. The `htm` claim matches the HTTP method of the current request.
9. The `htu` claim matches the HTTP URI value for the HTTP request in which the JWT was received, ignoring any query and fragment parts.
10. If the server provided a nonce value to the client, the `nonce` claim matches the server-provided nonce value.
11. The creation time of the JWT (from the `iat` claim or a server-managed timestamp via the `nonce` claim) is within an acceptable window (§11.1).
12. If presented to a protected resource in conjunction with an access token: ensure the value of the `ath` claim equals the hash of that access token, and confirm that the public key to which the access token is bound matches the public key from the DPoP proof.

Servers SHOULD employ syntax-based and scheme-based normalization (RFC 3986 §6.2.2, §6.2.3) before comparing the `htu` claim (§4.3).

## Token binding: `cnf` / `jkt` (§6)

- Binding is conveyed by associating the public key with the token, e.g., embedding the JWK hash in a JWT access token (§6.1) or via token introspection (§6.2). Other methods are possible by AS/RS agreement but out of scope (§6).
- `jkt` is a JWT Confirmation Method (RFC 7800) member under the `cnf` claim: its value MUST be the base64url encoding (RFC 7515) of the JWK SHA-256 Thumbprint (computed according to **RFC 7638**) of the DPoP public key (in JWK format) to which the access token is bound (§6.1).
- Access token response `token_type` MUST be `DPoP` to signal a DPoP-bound access token (§5).

Spec example, JWT claims set with confirmation (§6.1, Figure 9):

```json
{
  "sub":"someone@example.com",
  "iss":"https://server.example.com",
  "nbf":1562262611,
  "exp":1562266216,
  "cnf":
  {
    "jkt":"0ZcOCORZNYy-DWpqq30jZyJGHTN0d2HglBV3uiguA4I"
  }
}
```

Introspection (§6.2): the same `cnf` content with `jkt` member appears as a top-level member of the introspection response JSON. The resource server does not send a DPoP proof with the introspection request; the AS does not validate the DPoP binding at the introspection endpoint — the RS validates the binding locally from the response data. If the `token_type` member is included in the introspection response, it MUST contain the value `DPoP` (§6.2).

## The `ath` claim (§4.3, §7)

- Requests to DPoP-protected resources MUST include both a DPoP proof and the access token; the proof MUST include the `ath` claim with a valid hash of the associated access token (§7).
- `ath` hashes the access token: base64url encoding of the SHA-256 hash of the ASCII encoding of the access token's value (§4.2).
- The RS is required to calculate the hash of the presented token value and verify it equals the `ath` value (§7, §4.3 check 12).
- `ath` prevents a captured proof from being replayed with a different access token, but does not by itself prevent proof replay or bind to the request — time window, `htm`, and `htu` still matter (§7).

## Server-provided nonces (§8, §9)

- Authorization server (§8): the AS MAY supply a nonce to be included in DPoP proofs. Requests lacking a required nonce get HTTP 400 (Bad Request) per RFC 6749 §5.2 with error code `use_dpop_nonce`, plus a `DPoP-Nonce` HTTP header supplying the nonce. The same error code is used on nonce mismatch. Nonce values MUST be unpredictable; the nonce is opaque to the client. There MUST NOT be more than one `DPoP-Nonce` header (§8).
- If the `nonce` claim does not exactly match a recently supplied nonce, the AS MUST reject the request; the rejection MAY include a `DPoP-Nonce` header with a new value (§8).
- New nonces (§8.2): may be supplied via `DPoP-Nonce` on an error response, or more efficiently on an HTTP 200 (OK) response; the client MUST use the newly supplied nonce for the next and all subsequent token requests until the AS supplies a new one. Responses with `DPoP-Nonce` should be uncacheable (§8.2).
- Resource server (§9): the RS provides nonces the same way, using HTTP 401 (Unauthorized) with `WWW-Authenticate: DPoP` (error `use_dpop_nonce`) and a `DPoP-Nonce` header. AS and RS nonces are distinct — a nonce is only accepted by the server that issued it (§9).
- Downgrade: a server MUST NOT accept any DPoP proofs without the `nonce` claim when a DPoP nonce has been provided to the client (§11.3).

## Authorization-server and resource-server requirements (§5, §7, §10)

- Token endpoint (§5): the client MUST provide a valid DPoP proof JWT in a `DPoP` header on access token requests (all grant types). Invalid proof → error `invalid_dpop_proof` per RFC 6749 §5.2. `token_type` of `DPoP` MUST be included in the response for bound tokens.
- Refresh tokens (§5): a refresh token issued to a public client presenting a valid DPoP proof MUST be bound to that public key; the binding MUST be validated when the refresh token is presented; the client MUST present a proof for the same key on each refresh. Confidential-client refresh tokens are not DPoP-bound (already sender-constrained via client authentication).
- The AS MAY issue non-DPoP-bound access tokens (signaled by `token_type` `Bearer`); the client MUST discard the response if a `token_type` other than `DPoP` is returned and DPoP protection is deemed important (§5).
- Metadata: AS metadata `dpop_signing_alg_values_supported` (JSON array of supported JWS `alg` values) (§5.1); client registration metadata `dpop_bound_access_tokens` (boolean, default false) — if true, the AS MUST reject token requests from that client without the `DPoP` header (§5.2).
- `dpop_jkt` authorization request parameter (§10): OPTIONAL; value is the JWK Thumbprint (RFC 7638, SHA-256) of the proof-of-possession public key — same value as the `jkt` confirmation method. On token request, the AS computes the thumbprint of the key in the DPoP proof and MUST reject the request if it does not match `dpop_jkt`. With PAR (§10.1): `dpop_jkt` in the PAR POST body, or a `DPoP` header on the PAR request (AS MUST check the proof per §4.3 and MUST behave as if the key's thumbprint was provided via `dpop_jkt`); an AS supporting PAR and DPoP MUST support both; if both are used, the AS MUST reject on thumbprint/key mismatch.
- Resource access (§7.1): a DPoP-bound access token is sent in the `Authorization` header with authentication scheme `DPoP`. The RS MUST check that a DPoP proof was received in the `DPoP` header, check it per §4.3, and check that the proof's public key matches the key the token is bound to per §6. The RS MUST NOT grant access unless all checks succeed. RSs MUST be able to reliably identify whether a token is DPoP-bound and MUST ensure the proof's public key matches the one bound to the token (§6). Challenges use 401 with `WWW-Authenticate: DPoP`; parameters include `realm` (MAY), `scope` (MAY), `error` (SHOULD, e.g. `use_dpop_nonce`, `invalid_dpop_proof`), `error_description` (MAY), `algs` (SHOULD — space-delimited acceptable JWS alg values); unknown parameters MUST be ignored (§7.1). The scheme MUST NOT be used with `Proxy-Authenticate` or `Proxy-Authorization` (§7.1).
- Bearer compatibility (§7.2): a protected resource supporting both schemes MUST reject a DPoP-bound access token received as a bearer token.

## Normative requirements (issuing / validating DPoP-bound tokens)

- DPoP MUST always be used in conjunction with HTTPS (§2).
- JOSE Header: `alg` MUST NOT be `none` or symmetric; `jwk` MUST NOT contain a private key (§4.2). Servers MUST verify `typ` is `dpop+jwt` (§11.5); only asymmetric algorithms deemed secure may be used, `none` MUST NOT be allowed (§11.6).
- `jti` MUST be assigned with negligible collision probability in the validity window (§4.2).
- `ath` MUST be present, computed as base64url(SHA-256(ASCII(access token))), when the proof accompanies an access token at a protected resource (§4.2, §7); `nonce` MUST be present when the server has provided one (§4.2, §11.3).
- Receiving servers MUST perform all §4.3 checks; SHOULD normalize URIs before comparing `htu` (§4.3).
- The token endpoint's `DPoP` header MUST contain a valid DPoP proof; `token_type` `DPoP` MUST be in the response; the client MUST discard responses with a different `token_type` if DPoP protection matters (§5).
- Public-client refresh tokens MUST be key-bound; binding MUST be validated on use; the same key MUST be used for each refresh (§5). If `dpop_bound_access_tokens` is true, the AS MUST reject token requests lacking the `DPoP` header (§5.2).
- `jkt` MUST be the base64url-encoded RFC 7638 JWK SHA-256 Thumbprint of the bound DPoP public key (§6.1); introspection `token_type`, if present, MUST be `DPoP` (§6.2).
- RS: MUST require proof + token together with `ath` (§7); MUST NOT grant access unless all checks pass (§7.1); MUST reject DPoP-bound tokens presented as bearer tokens (§7.2); MUST NOT use the scheme with proxy authentication fields (§7.1).
- Nonces: values MUST be unpredictable; mismatch MUST be rejected; at most one `DPoP-Nonce` header (§8); client MUST use the newest nonce for subsequent token requests (§8.2); server MUST NOT accept proofs without `nonce` once a nonce was provided (§11.3).
- `dpop_jkt` mismatch with the proof key MUST be rejected (§10); PAR: both mechanisms MUST be supported, mismatch between `dpop_jkt` and `DPoP` header key MUST be rejected (§10.1).
- Replay: servers MUST only accept DPoP proofs for a limited time after creation (preferably on the order of seconds or minutes) (§11.1). Clients SHOULD generate a unique proof even when retrying idempotent requests (RECOMMENDED, §7.3). Deployments not using the nonce mechanism SHOULD NOT issue long-lived DPoP-constrained access tokens (§11.2).

## Ambiguities & notes

- §4.3 check 11 allows proof freshness via either `iat` or "a server managed timestamp via the nonce claim"; the acceptable window is unspecified (§11.1 says "preferably ... seconds or minutes"; iat slightly in the future MAY be accepted for clock offset).
- Refresh-token binding implementation details are "at the discretion of the authorization server" — explicitly no interoperability requirement (§5).
- Nonce-issuing policy (when/whether to require one) is out of scope (§8); replay (`jti`) tracking is described as SHOULD-level practice, not an absolute requirement (§11.1).
- Error names registered: `invalid_dpop_proof` and `use_dpop_nonce`, usable in both token error responses and resource access error responses (§12.2). HTTP fields registered: `DPoP` and `DPoP-Nonce` (§12.8). Media type: `application/dpop+jwt` (§12.5).
- Guidance — ours, not spec: for agent deployments, note the pre-generation attack (§11.2) — without server nonces, a party controlling the client (including the legitimate user) can pre-generate proofs with future `iat` values, so nonce support is the stronger posture for long-running agent processes.
