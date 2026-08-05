# V1-B Blind Re-Extraction: RFC 7523 Client Authentication + CIMD -02

Sources: RFC 7523 (May 2015) and draft-ietf-oauth-client-id-metadata-document-02 (6 July 2026) only.

## Part A — RFC 7523

### A.1 The two URNs and their carrying parameters

| Use | URN (exact) | Carried in | JWT carried in | § |
|---|---|---|---|---|
| Authorization grant | `urn:ietf:params:oauth:grant-type:jwt-bearer` | `grant_type` | `assertion` — "The value of the \"assertion\" parameter MUST contain a single JWT." | §2.1 (registered §8.1) |
| Client authentication | `urn:ietf:params:oauth:client-assertion-type:jwt-bearer` | `client_assertion_type` | `client_assertion` — "contains a single JWT. It MUST NOT contain more than one JWT." | §2.2 (registered §8.2) |

Client authentication is orthogonal to the grant: it "must be used in conjunction with some grant type to form a complete and meaningful protocol request" (§1).

### A.2 JWT claims for client authentication (§3)

| Claim | Required? | Value requirement (§3 item) |
|---|---|---|
| `iss` (issuer) | REQUIRED ("The JWT MUST contain") | "a unique identifier for the entity that issued the JWT". §3 places NO client-authentication-specific constraint on `iss` — it does not say `iss` must equal the `client_id`. Absent an application profile, issuer values MUST be compared using Simple String Comparison per RFC 3986 §6.2.1. (§3 item 1) |
| `sub` (subject) | REQUIRED | "For client authentication, the subject MUST be the \"client_id\" of the OAuth client." (§3 item 2, case B) |
| `aud` (audience) | REQUIRED | Value that "identifies the authorization server as an intended audience"; the token endpoint URL of the AS MAY be used as an `aud` value. Audience values MUST be compared using Simple String Comparison per RFC 3986 §6.2.1 absent a profile; precise audience strings are configured out of band (§3 item 3, §5). |
| `exp` (expiration time) | REQUIRED | "limits the time window during which the JWT can be used" (§3 item 4) |
| `nbf` (not before) | OPTIONAL (MAY) | time before which the token MUST NOT be accepted for processing (§3 item 5) |
| `iat` (issued at) | OPTIONAL (MAY) | time at which the JWT was issued; AS may reject values unreasonably far in the past (§3 item 6) |
| `jti` (JWT ID) | OPTIONAL (MAY) | unique identifier for the token; AS MAY use it for replay prevention (§3 item 7) |
| other claims | OPTIONAL (MAY) | (§3 item 8) |

Additionally, the JWT MUST be digitally signed or have a MAC applied by the issuer (§3 item 9). `RS256` is mandatory-to-implement (§5).

### A.3 MUST-level validation requirements on the authorization server

1. The AS "MUST validate the JWT according to the criteria below" before issuing a token or relying on it for client authentication (§3, preamble).
2. Issuer comparison: compliant applications MUST compare issuer values using Simple String Comparison, RFC 3986 §6.2.1, absent a profile (§3 item 1).
3. Audience: "The authorization server MUST reject any JWT that does not contain its own identity as the intended audience"; audience values MUST be compared using Simple String Comparison, RFC 3986 §6.2.1, absent a profile (§3 item 3).
4. Expiration: "The authorization server MUST reject any JWT with an expiration time that has passed, subject to allowable clock skew between systems." (§3 item 4)
5. `nbf`: the token MUST NOT be accepted for processing before the `nbf` time, when present (§3 item 5).
6. Signature/MAC: "The authorization server MUST reject JWTs with an invalid signature or MAC." (§3 item 9)
7. General JWT validity: "The authorization server MUST reject a JWT that is not valid in all other respects per \"JSON Web Token (JWT)\" [JWT]." (§3 item 10)
8. Grant processing: "if client credentials are present in the request, the authorization server MUST validate them" (§3.1); on an invalid grant JWT the `error` parameter MUST be `invalid_grant` (§3.1).
9. Client authentication processing: on an invalid client JWT the `error` parameter MUST be `invalid_client` (§3.2).

(Required claims in A.2 — `iss`, `sub`, `aud`, `exp` MUST be present — are also MUST-level validation criteria per the §3 preamble.)

## Part B — CIMD draft -02

### B.1 Client Identifier URL constraints (§3)

A Client Identifier URL:
- MUST use the `https` URL scheme
- MUST NOT contain a userinfo component (as defined by RFC 3986)
- MAY contain a port
- MUST contain a path component
- MUST NOT contain single-dot or double-dot path components
- SHOULD NOT contain a query component
- MUST NOT contain a fragment component

Client Identifier URLs MUST be compared using simple string comparison (RFC 3986 §6.2.1) with no default-port normalization: `https://example.com/client` and `https://example.com:443/client` are not equivalent (§3). A short URL is RECOMMENDED; a stable URL is RECOMMENDED; a path of `/` is NOT RECOMMENDED; URL shortening services are generally unsuitable because they use HTTP redirects, conflicting with §5 (§3). The URL MUST be associated with a Client ID Metadata Document available at the Client Identifier URL (§3).

### B.2 AS fetch rules for the metadata document

- The AS SHOULD automatically fetch the document at the Client Identifier URL, and SHOULD periodically re-fetch it (§5). Alternatively it MAY associate the URL with metadata by other means such as pre-registration (§5, §7.2).
- Status code: the document MUST be served with a 200 OK HTTP status code; the AS MUST treat all other HTTP status codes as an error response (§5; the 200 OK requirement also appears in §4). It MAY be served with more specific content types as long as the response is JSON and conforms to `application/<AS-defined>+json` (§4).
- Redirects: "The authorization server MUST NOT automatically follow HTTP redirects when fetching the Client ID Metadata Document." (§5)
- Fetch failure: the AS SHOULD abort the authorization request (§5.1).
- Caching: the AS MAY cache; SHOULD respect HTTP cache headers (RFC 9111) but MAY define its own upper and/or lower bounds on cache lifetime; MUST NOT cache error responses; MUST NOT cache documents which are invalid or malformed (§5.2).
- Content validation: the document MUST contain a `client_id` property whose value MUST match the Client Identifier URL, which MUST also match the URL the AS used to fetch the document; comparisons MUST use simple string comparison per RFC 3986 §6.2.1; the AS is responsible for validating this match (§4).
- SSRF: the AS MUST NOT fetch a Client ID Metadata Document URL, or any URLs contained within a Client ID Metadata Document, that resolve to special-use IP addresses as defined in RFC 6890 (§8.6). Development/testing deployments MAY relax this to allow loopback fetches when the AS itself runs on a loopback address and the resolved address matches the same loopback interface; the AS MUST NOT apply this exception in production deployments (§8.6). The AS SHOULD only fetch or parse URLs with known and supported URI schemes (e.g., to avoid `javascript:`) and SHOULD consider network policies against special-use addresses (§8.6).
- Size limit: the AS SHOULD limit the amount of data it reads and processes, e.g. stopping after a maximum number of bytes and treating the response as an error if the limit is reached before the document is fully read; "The recommended maximum size to read is 5 kilobytes." (§8.7)
- Timeouts: the draft states no timeout values anywhere.

### B.3 Client key material and auth method restrictions

- Because no shared secret can be established, the following apply to the document's contents (§4.1):
  - `token_endpoint_auth_method` MUST NOT include `client_secret_post`, `client_secret_basic`, `client_secret_jwt`, "or any other method based around a shared symmetric secret"
  - the `client_secret` and `client_secret_expires_at` properties MUST NOT be used
  - private key material MUST NOT be included in the Client ID Metadata Document; only public keys, such as those published via the `jwks` or `jwks_uri` properties, are permitted
- Key material is conveyed by publishing the public key in the metadata document (`jwks` / `jwks_uri`); clients capable of maintaining private key material SHOULD authenticate with an acceptable method from the OAuth Token Endpoint Authentication Methods registry (§8.2). Example: `"token_endpoint_auth_method": "private_key_jwt"` with `"jwks_uri": "https://client.example.com/jwks.json"` (§8.2).
- Declaring an auth method establishes the client as a confidential client, and "any communication with the authorization server MUST include client authentication of the registered type" (§8.2).
- "When a client declares token_endpoint_auth_method as private_key_jwt, the authorization server MUST require client authentication according to Section 2.2 of [RFC7523] using the corresponding key discovered from the client's metadata document." (§8.2)
- Other specifications MAY add restrictions, e.g. requiring `token_endpoint_auth_method` be `private_key_jwt`, effectively requiring confidential clients (§4).
- Key changes: if `jwks`, `jwks_uri`, or the contents at the `jwks_uri` change, the AS may revoke tokens or consent at its discretion (§8.4.1, non-normative).

### B.4 The 6 most load-bearing MUSTs

1. Identity binding: the document MUST contain a `client_id` property whose value MUST match the Client Identifier URL, which MUST also match the URL the AS used to fetch the document, via simple string comparison (§4).
2. No redirects and 200-only: the document MUST be served with 200 OK, the AS MUST treat all other status codes as errors, and the AS MUST NOT automatically follow HTTP redirects (§5).
3. SSRF: the AS MUST NOT fetch a Client ID Metadata Document URL or any URLs within the document that resolve to special-use IP addresses (RFC 6890), and MUST NOT apply the loopback exception in production (§8.6).
4. No shared secrets: `token_endpoint_auth_method` MUST NOT include `client_secret_post`, `client_secret_basic`, `client_secret_jwt`, or any other shared-symmetric-secret method; `client_secret`/`client_secret_expires_at` MUST NOT be used; private key material MUST NOT be included (§4.1).
5. Enforced key-based auth: when the client declares `token_endpoint_auth_method` as `private_key_jwt`, the AS MUST require client authentication per RFC 7523 §2.2 using the key discovered from the client's metadata document (§8.2).
6. URL form: a Client Identifier URL MUST use the `https` scheme, MUST contain a path component, MUST NOT contain a userinfo component, single-/double-dot path segments, or a fragment; and per RFC 9700 the AS MUST require registration of redirect URLs and MUST ensure exact-match (simple string comparison) of the redirect URL in an authorization request (§3, §4.2).

## Source ambiguities noted

- RFC 7523 §3 does NOT require `iss` = `client_id` for client authentication; it only requires `iss` be "a unique identifier for the entity that issued the JWT" (item 1). Only `sub` is pinned to the `client_id` (item 2.B).
- CIMD §6 reads "Authorization servers that publish Authorization Server Metadata [RFC8414] MUST include the following property" yet defines `client_id_metadata_document_supported` as "OPTIONAL" — internally contradictory as written.
- CIMD specifies no fetch timeout values; the only stated numbers are 200 (status) and 5 kilobytes (recommended max read, a SHOULD-level recommendation in §8.7).
