Source: rfc7523 — https://www.rfc-editor.org/rfc/rfc7523.txt — RFC (immutable) — fetched 2026-08-05 — extracted 2026-08-05
Source: cimd — https://www.ietf.org/archive/id/draft-ietf-oauth-client-id-metadata-document-02.txt — draft -02 (EXPIRES 2027-01-07; Internet-Draft, work in progress, NOT a standard) — fetched 2026-08-05 — extracted 2026-08-05

# Client authentication: RFC 7523 JWT assertions + Client ID Metadata Documents

## Part A — RFC 7523 (JWT Profile for OAuth 2.0 Client Authentication and Authorization Grants)

### A1. Two uses and their selecting parameters (§1, §2.1, §2.2)
RFC 7523 profiles the OAuth Assertion Framework (RFC 7521) for two orthogonal, separable uses (§1): a JWT as an authorization grant, and a JWT as a client authentication mechanism. Client authentication via JWT is "nothing more than an alternative way for a client to authenticate to the token endpoint" and must be combined with some grant type (§1).

| Use | Selecting parameters (token endpoint) | Ref |
|---|---|---|
| Authorization grant | `grant_type` = `urn:ietf:params:oauth:grant-type:jwt-bearer`; `assertion` MUST contain a single JWT; `scope` may be used; `client_id` only needed when a client-auth form relying on it is used | §2.1 |
| Client authentication | `client_assertion_type` = `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`; `client_assertion` contains a single JWT and MUST NOT contain more than one JWT | §2.2 |

Example from §2.2 (client auth presented alongside an authorization-code grant; trimmed):

    grant_type=authorization_code&
    code=n0esc3NRze7LTCu7iYzS6a5acc3f0ogp4&
    client_assertion_type=urn%3Aietf%3Aparams%3Aoauth%3A
    client-assertion-type%3Ajwt-bearer&
    client_assertion=eyJhbGciOiJSUzI1NiIsImtpZCI6IjIyIn0.[...]

### A2. JWT claims for client authentication (§3)
| Claim | Requirement | Meaning per §3 | Ref |
|---|---|---|---|
| `iss` | MUST be present | "a unique identifier for the entity that issued the JWT"; absent an application profile, issuer values MUST be compared using Simple String Comparison (RFC 3986 §6.2.1) | §3(1) |
| `sub` | MUST be present | identifies the principal that is the subject. For client authentication: "the subject MUST be the \"client_id\" of the OAuth client" (§3(2)B). (For the grant use, §3(2)A: subject typically identifies an authorized accessor, or may be pseudonymous/anonymous.) | §3(2) |
| `aud` | MUST be present | value identifying the AS as an intended audience; the AS's token endpoint URL MAY be used as an `aud` value; AS MUST reject any JWT that does not contain its own identity as the intended audience; comparison via Simple String Comparison; precise audience strings are configured out of band (§5) | §3(3) |
| `exp` | MUST be present | limits the usable time window; AS MUST reject a JWT whose expiration time has passed (subject to allowable clock skew); AS may reject `exp` unreasonably far in the future | §3(4) |
| `nbf` | MAY be present | time before which the token MUST NOT be accepted for processing | §3(5) |
| `iat` | MAY be present | issue time; AS may reject `iat` unreasonably far in the past | §3(6) |
| `jti` | MAY be present | unique token identifier; AS MAY prevent replay by keeping used `jti` values until the applicable `exp` instant | §3(7) |

Other claims MAY be present (§3(8)). The JWT MUST be digitally signed or MACed by the issuer (§3(9)).

### A3. AS validation requirements (§3, §3.1, §3.2)
- The AS MUST validate the JWT per the §3 criteria before issuing a token response or relying on it for client authentication; additional restrictions/policy are at AS discretion (§3 intro).
- Reject missing/failed `iss`, `sub`, `aud`, `exp` checks as in table above (§3(1)–(4)).
- AS MUST reject JWTs with an invalid signature or MAC (§3(9)), and MUST reject a JWT "not valid in all other respects" per RFC 7519 (§3(10)).
- Grant use: if client credentials are present in the request, the AS MUST validate them (§3.1). Invalid grant JWT → error MUST be `invalid_grant`; `error_description`/`error_uri` MAY add detail (§3.1).
- Client authentication use: invalid client JWT → error MUST be `invalid_client`; `error_description`/`error_uri` MAY add detail (§3.2).
- Replay protection is NOT mandated for either use; it is an optional feature (§6). `jti` tracking is MAY (§3(7)).
- Error response example from §3.1 (exact):

      HTTP/1.1 400 Bad Request
      Content-Type: application/json
      Cache-Control: no-store

      {
       "error":"invalid_grant",
       "error_description":"Audience validation failed"
      }

- Interop: issuer/audience values, token endpoint location, keys, one-time-use rules, max lifetime, and subject/claim requirements must be agreed out of band (§5).

### A4. RFC 7523 normative MUST/SHOULD list
1. `assertion` MUST contain a single JWT (§2.1).
2. `client_assertion` MUST NOT contain more than one JWT (§2.2).
3. AS MUST validate the JWT per §3 criteria (§3).
4. JWT MUST contain `iss`; issuer comparison MUST use Simple String Comparison (§3(1)).
5. JWT MUST contain `sub`; for client authentication, `sub` MUST be the `client_id` (§3(2)).
6. JWT MUST contain `aud`; AS MUST reject a JWT lacking its own identity as audience; audience comparison MUST use Simple String Comparison (§3(3)).
7. JWT MUST contain `exp`; AS MUST reject expired JWTs, subject to allowable clock skew (§3(4)).
8. If `nbf` is present, the token MUST NOT be accepted before that time (§3(5)).
9. JWT MUST be digitally signed or MACed by the issuer; AS MUST reject invalid signature/MAC (§3(9)).
10. AS MUST reject a JWT not valid in all other respects per RFC 7519 (§3(10)).
11. If client credentials are present with a JWT grant, AS MUST validate them; the error for an invalid grant JWT MUST be `invalid_grant` (§3.1).
12. Error for an invalid client-authentication JWT MUST be `invalid_client` (§3.2).
13. `RS256` is a mandatory-to-implement JWS algorithm for this profile (§5).
(RFC 7523 states no uppercase SHOULD requirements; privacy advice in §7 — TLS transport, minimal claims — is lowercase "should".)

## Part B — CIMD (draft-ietf-oauth-client-id-metadata-document-02)

MATURITY WARNING: This is IETF Web Authorization Protocol (oauth) Working Group Internet-Draft revision -02, dated 6 July 2026, intended status Standards Track, and it EXPIRES 7 January 2027. It is a work in progress, NOT a standard; "It is inappropriate to use Internet-Drafts as reference material" (Status of This Memo). Contains an open TBD (a possible `client_id_expires_at` property, §4).

### B1. Concept: client_id as URL (§1, §3)
A client publishes its own registration metadata at an https URL — the Client Identifier URL — used directly as its `client_id`, so the AS can fetch client metadata without prior registration (§1). A Client Identifier URL (§3):
- MUST use the https URL scheme
- MUST NOT contain a userinfo component (RFC 3986)
- MAY contain a port
- MUST contain a path component
- MUST NOT contain single-dot or double-dot path components
- SHOULD NOT contain a query component; MUST NOT contain a fragment component
- MUST be compared using simple string comparison (RFC 3986 §6.2.1) — e.g., `https://example.com/client` and `https://example.com:443/client` are NOT equivalent (§3)
- MUST be associated with a Client ID Metadata Document available at that URL (§3)
Short and stable URLs are RECOMMENDED; a path of `/` is NOT RECOMMENDED; URL shorteners are unsuitable because redirects conflict with §5 (§3).

### B2. The metadata document (§4, §4.1, §4.2)
- A JSON (RFC 8259) document; metadata values are those in the IANA OAuth Dynamic Client Registration Metadata registry established by RFC 7591 (§4).
- MUST contain a `client_id` property whose value MUST match the Client Identifier URL, which MUST also match the URL the AS used to fetch the document; all comparisons via simple string comparison; the AS validates this match (§4).
- MUST be served with a 200 OK HTTP status code; MAY also be served with more specific content types as long as the response is JSON and conforms to `application/<AS-defined>+json` (§4, §5).
- Credential/key restrictions (§4.1): `token_endpoint_auth_method` MUST NOT include `client_secret_post`, `client_secret_basic`, `client_secret_jwt`, or any other shared-symmetric-secret method; `client_secret` and `client_secret_expires_at` MUST NOT be used; private key material MUST NOT be included — only public keys, such as those published via the `jwks` or `jwks_uri` properties, are permitted.
- Redirect URLs (§4.2): per RFC 9700 the AS MUST require registration of redirect URLs and MUST ensure the request's redirect URL exactly matches a registered one (simple string comparison); registration is established when the AS fetches the document. §4.2 does not apply to grant types without a redirect URL (e.g., Client Credentials Grant, Token Exchange), but identification/metadata discovery apply to all grant types.
- `software_statement` (RFC 7591) MAY be included as a document property (§4.3).

### B3. Fetching and validation by the AS (§5, §5.1, §5.2, §8.6, §8.7)
- AS SHOULD automatically fetch the document at the Client Identifier URL, and SHOULD periodically re-fetch it (§5). An AS MAY instead associate the URL with metadata by other means, e.g., pre-registration (§5, §7.2).
- AS MUST treat any HTTP status other than 200 OK as an error, and MUST NOT automatically follow HTTP redirects when fetching (§5).
- If fetching fails, the AS SHOULD abort the authorization request (§5.1).
- Caching (§5.2): AS MAY cache the metadata; SHOULD respect HTTP cache headers (RFC 9111) but MAY set its own upper/lower cache-lifetime bounds; MUST NOT cache error responses; MUST NOT cache invalid or malformed documents.
- SSRF (§8.6): AS MUST NOT fetch a Client ID Metadata Document URL, or any URL within the document, resolving to special-use IP addresses (RFC 6890); ASes deployed for development or testing purposes MAY relax this restriction to allow fetching from loopback addresses when the AS itself is also running on a loopback address and the resolved address matches the same loopback interface — and MUST NOT apply this exception in production deployments; AS SHOULD only fetch or parse URLs with known and supported URI schemes.
- Size (§8.7): AS SHOULD limit the data read when fetching (recommended maximum to read: 5 kilobytes) and treat exceeding it as an error.
- AS metadata (§6): ASes publishing RFC 8414 metadata MUST include `client_id_metadata_document_supported` (listed as OPTIONAL; boolean) to signal support.

### B4. Interaction with client authentication (§4.1, §8.2)
No shared secret can be established, so credentials use public/private key pairs: the client publishes its public key in the metadata document — only public keys are permitted, such as those published via the `jwks` or `jwks_uri` properties (§4.1). Clients that are capable of maintaining private key material and performing client authentication SHOULD do so with an acceptable method, such as a method in the OAuth Token Endpoint Authentication Methods registry (§8.2). Example from §8.2 (trimmed):

    "token_endpoint_auth_method": "private_key_jwt",
    "jwks_uri": "https://client.example.com/jwks.json"

This establishes a confidential client, and "any communication with the authorization server MUST include client authentication of the registered type" (§8.2). When a client declares `token_endpoint_auth_method` as `private_key_jwt`, the AS MUST require client authentication per Section 2.2 of RFC 7523 using the corresponding key discovered from the client's metadata document (§8.2). Key changes (`jwks`, `jwks_uri`, or `jwks_uri` contents) may trigger AS actions such as revoking tokens or consent, at AS discretion (§8.4.1).

### B5. CIMD normative MUST/SHOULD list (condensed; see B1–B4 for full text)
MUST-level: URL scheme/shape rules ×5 (§3); simple-string comparison (§3); document available at URL (§3); `client_id` match (§4); 200 OK + non-200 = error + no redirect-following (§4, §5); shared-secret method/property bans ×3 (§4.1); redirect URL registration + exact match (§4.2); no caching of errors or invalid documents (§5.2); `client_id_metadata_document_supported` in RFC 8414 metadata (§6); require RFC 7523 §2.2 auth when `private_key_jwt` declared (§8.2); no fetching special-use IPs, no loopback exception in production (§8.6).
SHOULD-level: no query component (§3); auto-fetch and periodic re-fetch (§5); abort on fetch failure (§5.1); respect cache headers (§5.2, §9.1); generated non-URL client_ids not starting with `https://` (§7.1); fetch at pre-registration time (§7.2); clients SHOULD do key-based client auth (§8.2); fetch for user display + display client_id hostname (§8.5); known URI schemes only, network policies (§8.6); read-size limit (§8.7); prefetch/cache `logo_uri` (§8.8).

## Ambiguities & notes
- rfc7523 §3(2)B pins only `sub` to the `client_id` for client authentication; §3(1) requires `iss` merely to be "a unique identifier for the entity that issued the JWT" — the RFC never says `iss` must equal `client_id`. Guidance — ours, not spec: many deployed private_key_jwt profiles set `iss` = `sub` = `client_id`; do not assume that from RFC 7523 alone.
- rfc7523: the token endpoint URL is only a MAY for `aud` (§3(3)); the precise audience strings "must be configured out of band" (§5) — so exact `aud` matching behavior is deployment-specific.
- rfc7523: replay protection is explicitly optional (§6); `jti` presence and tracking are both MAY (§3(7)).
- cimd §4/§5: the draft states the 200 OK requirement and that "more specific" `application/<AS-defined>+json` types MAY be used, but never explicitly names a base content type (e.g., `application/json`) for the document.
- cimd §6: the property is labeled "OPTIONAL" yet the surrounding sentence says ASes publishing RFC 8414 metadata "MUST include" it to signal support — an internal tension in -02.
- cimd §4: open TBD on a possible `client_id_expires_at` property for ephemeral clients.
- cimd defines no new key-conveyance parameters: key material rides on RFC 7591 registry metadata (`jwks`/`jwks_uri`, public keys only, §4.1); private key management is out of scope (§8.2).
- cimd Appendix A (CIMD Services) is explicitly non-normative despite containing MUST/MAY language.
- Status recap: rfc7523 is Standards Track (May 2015, immutable); cimd is oauth WG Internet-Draft revision -02, work in progress, expires 2027-01-07 — every Part B fact may change in later revisions.
