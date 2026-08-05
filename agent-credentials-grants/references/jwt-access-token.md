Source: rfc9068 — https://www.rfc-editor.org/rfc/rfc9068.txt — RFC (immutable) — fetched 2026-08-05 — extracted 2026-08-05

# RFC 9068 — JSON Web Token (JWT) Profile for OAuth 2.0 Access Tokens

## 1. Overview

Defines a profile for issuing OAuth 2.0 access tokens in JWT format so authorization servers (AS) and resource servers (RS) from different vendors can issue and consume access tokens interoperably (Abstract). It standardizes a common set of mandatory and optional claims, how request parameters shape the issued token, and how an RS validates it (§1). The spec distinguishes itself from RFC 7523: that RFC uses a JWT to *request* an access token; RFC 9068 encodes the access token *itself* as a JWT (§1).

## 2. Header (§2.1)

- JWT access tokens MUST be signed; use of asymmetric cryptography is RECOMMENDED (§2.1).
- JWT access tokens MUST NOT use `none` as the signing algorithm (§2.1).
- Conforming AS and RS MUST include RS256 (RFC 7518) among their supported signature algorithms (§2.1).
- `typ`: JWT access tokens MUST include the `application/at+jwt` media type in the `typ` header parameter to declare the JWT is an access token complying with this profile. Compatibility note: per the definition of `typ` in RFC 7515 §4.1.9, it is RECOMMENDED that the `application/` prefix be omitted; therefore the `typ` value used SHOULD be `at+jwt` (§2.1).
- Explicit typing exists to prevent OpenID Connect ID Tokens from being accepted as access tokens by resource servers implementing this profile (§2.1, §5).

## 3. Claims table (§2.2 and subsections)

| Claim | Requirement | Meaning (per spec) | Section |
|---|---|---|---|
| `iss` | REQUIRED | As defined in RFC 7519 §4.1.1 | §2.2 |
| `exp` | REQUIRED | As defined in RFC 7519 §4.1.4 | §2.2 |
| `aud` | REQUIRED | As defined in RFC 7519 §4.1.3; §3 governs how the AS determines its value from the request | §2.2 |
| `sub` | REQUIRED | RFC 7519 §4.1.2. With a resource owner involved (e.g., authorization code grant), value SHOULD be the resource owner's subject identifier; with no resource owner (e.g., client credentials grant), value SHOULD be an identifier the AS uses to indicate the client application | §2.2 |
| `client_id` | REQUIRED | As defined in RFC 8693 §4.3 | §2.2 |
| `iat` | REQUIRED | RFC 7519 §4.1.6; time at which the JWT access token was issued | §2.2 |
| `jti` | REQUIRED | As defined in RFC 7519 §4.1.7 | §2.2 |
| `auth_time` | OPTIONAL | As defined in OpenID Connect Core §2; MAY be issued in grants involving the resource owner; value fixed across all access tokens deriving from a given authorization response | §2.2.1 |
| `acr` | OPTIONAL | As defined in OpenID Connect Core §2; same issuance/fixed-value conditions as `auth_time` | §2.2.1 |
| `amr` | OPTIONAL | As defined in OpenID Connect Core §2; same issuance/fixed-value conditions as `auth_time` | §2.2.1 |
| `scope` | SHOULD (if request had a scope parameter) | As defined in RFC 8693 §4.2; every individual scope string MUST have meaning for the resources indicated in `aud` | §2.2.3 |
| `roles` | SHOULD (when embedding such attributes) | Claim type from the SCIM "User" resource schema, RFC 7643 §4.1.2; no specific vocabulary provided | §2.2.3.1 |
| `groups` | SHOULD (when embedding such attributes) | Same source; RFC 7643 §8.2 has a non-normative example | §2.2.3.1 |
| `entitlements` | SHOULD (when embedding such attributes) | Same source; no specific vocabulary provided | §2.2.3.1 |

Identity claims (§2.2.2): additional identity attributes whose semantics match an entry in the IANA "JSON Web Token (JWT)" registry SHOULD use the corresponding claim name. The AS MAY include arbitrary attributes not defined in any spec if the claim names are collision resistant or the tokens are used only within a private subsystem. No mechanism is defined for a client to directly request specific claims; the AS infers them from `client_id`, `scope`, and `resource` (§2.2.2).

Issuance rules (§3): if the request has a `resource` parameter (RFC 8707), `aud` SHOULD equal it. If not, the AS MUST use a default resource indicator in `aud`; if `scope` is present it SHOULD be used to infer that default; if scope values map to different default resource indicators, the AS SHOULD reject with `invalid_scope`. The AS MUST NOT issue a JWT access token if the authorization granted would be ambiguous (§3).

Example from Figure 2 (§3), reproduced exactly:

Header:

    {"typ":"at+JWT","alg":"RS256","kid":"RjEwOwOA"}

Claims:

    {
      "iss": "https://authorization-server.example.com/",
      "sub": "5ba552d67",
      "aud":   "https://rs.example.com/",
      "exp": 1639528912,
      "iat": 1618354090,
      "jti" : "dbe39bf3a3ba4238a513f51d6e1691c4",
      "client_id": "s6BhdRkqt3",
      "scope": "openid profile reademail"
    }

## 4. Validation rules (§4)

Discovery preamble (§4): the AS SHOULD advertise signing keys via RFC 8414 metadata (`jwks_uri`) and the expected `iss` value via `issuer`; authorization servers implementing OpenID Connect MAY use OpenID Connect discovery instead; if it supports both, values MUST be consistent. The AS MAY use different keys for ID Tokens vs. JWT access tokens, but no mechanism identifies which key signs access tokens — any advertised key may be used (§4).

"Resource servers receiving a JWT access token MUST validate it in the following manner" (§4) — steps itemized in the spec's order:

1. The RS MUST verify that the `typ` header value is `at+jwt` or `application/at+jwt` and reject tokens carrying any other value (§4).
2. If the JWT access token is encrypted, decrypt it using the keys and algorithms the RS specified during registration. If encryption was negotiated with the AS at registration time and the incoming token is not encrypted, the RS SHOULD reject it (§4). (Decryption is listed before signature validation.)
3. The issuer identifier for the AS (typically obtained during discovery) MUST exactly match the value of the `iss` claim (§4).
4. The RS MUST validate that the `aud` claim contains a resource indicator value corresponding to an identifier the RS expects for itself; the token MUST be rejected if `aud` does not contain a resource indicator of the current RS as a valid audience (§4).
5. The RS MUST validate the signature of all incoming JWT access tokens per RFC 7515 using the algorithm in the JWT `alg` Header Parameter; MUST reject any JWT whose `alg` value is `none`; and MUST use the keys provided by the AS (§4).
6. The current time MUST be before the time represented by the `exp` claim; implementers MAY allow small leeway (usually no more than a few minutes) for clock skew (§4).

After validation: errors MUST be handled per RFC 6750 §3.1; on any failure of the checks above the response MUST include the error code `invalid_token` (this does not restrict tokens to the "Bearer" scheme) (§4). If the token includes §2.2.3 authorization claims, the RS SHOULD use them with other contextual information to decide authorization; how is out of scope (§4).

## 5. Security considerations relevant to validation (§5)

- Cross-JWT confusion: the JWT access token layout is very similar to the OpenID Connect id_token; the explicit typing required here (in line with RFC 8725) helps the RS distinguish them (§5).
- Audience protection: to prevent cross-JWT confusion, the AS MUST use a distinct identifier as an `aud` claim value to uniquely identify access tokens issued by the same issuer for distinct resources (see RFC 8725 §2.8) (§5).
- `sub` confusion: the AS should prevent clients from influencing `sub` in confusing ways — e.g., if `client_id` is used as `sub` for client-credentials tokens, arbitrary client_id registration would let a malicious client pick a high-privilege resource owner's `sub` (§5).
- Ambiguity with multiple resource indicators: each scope string in the token should be unambiguously correlatable to a specific resource among those in `aud` (§5).
- Key separation is not a safeguard: because the RS cannot know which advertised key signs access tokens, it must accept signatures from any key published in AS metadata/OIDC discovery; compromise of any one published key lets an attacker mint tokens the RS accepts (§5).

## 6. Normative requirements (MUST / MUST NOT / SHOULD)

| # | Requirement | Section |
|---|---|---|
| 1 | JWT access tokens MUST be signed | §2.1 |
| 2 | JWT access tokens MUST NOT use `none` as the signing algorithm | §2.1 |
| 3 | Conforming AS and RS MUST include RS256 among supported signature algorithms | §2.1 |
| 4 | Tokens MUST include the `application/at+jwt` media type in the `typ` header parameter | §2.1 |
| 5 | The `typ` value used SHOULD be `at+jwt` (prefix omission RECOMMENDED per RFC 7515 §4.1.9) | §2.1 |
| 6 | `sub` SHOULD be the resource owner's subject identifier (resource-owner grants) / an AS identifier for the client (no resource owner) | §2.2 |
| 7 | Identity attributes matching an IANA JWT registry entry SHOULD use the registered claim name | §2.2.2 |
| 8 | If the authorization request includes a scope parameter, the token SHOULD include a `scope` claim | §2.2.3 |
| 9 | All individual scope strings in `scope` MUST have meaning for the resources indicated in `aud` | §2.2.3 |
| 10 | AS SHOULD use `groups`, `roles`, `entitlements` (RFC 7643 §4.1.2) as claim types for such attributes | §2.2.3.1 |
| 11 | AS SHOULD encode those claim values per RFC 7643 guidance | §2.2.3.1 |
| 12 | If the request has a `resource` parameter, `aud` SHOULD have the same value | §3 |
| 13 | AS MUST NOT issue a JWT access token if the authorization granted would be ambiguous | §3 |
| 14 | Without a `resource` parameter, AS MUST use a default resource indicator in `aud` | §3 |
| 15 | If `scope` is present, AS SHOULD use it to infer the default resource indicator | §3 |
| 16 | If scope values map to different default resource indicators, AS SHOULD reject with `invalid_scope` | §3 |
| 17 | AS SHOULD advertise keys and issuer via RFC 8414 AS metadata | §4 |
| 18 | If both AS metadata and OIDC discovery are supported, published values MUST be consistent | §4 |
| 19 | RS MUST verify `typ` is `at+jwt` or `application/at+jwt` and reject any other value | §4 |
| 20 | RS SHOULD reject an unencrypted token when encryption was negotiated at registration | §4 |
| 21 | Issuer identifier MUST exactly match the `iss` claim | §4 |
| 22 | RS MUST validate `aud` contains its own resource indicator; MUST reject otherwise | §4 |
| 23 | RS MUST validate the signature per RFC 7515 using the `alg` header; MUST reject `alg` = `none`; MUST use the AS-provided keys | §4 |
| 24 | Current time MUST be before `exp` (small leeway MAY be allowed) | §4 |
| 25 | RS MUST handle errors per RFC 6750 §3.1; validation failures MUST return error code `invalid_token` | §4 |
| 26 | RS SHOULD use included authorization claims plus context to authorize the call | §4 |
| 27 | AS MUST use distinct `aud` identifiers for tokens issued by the same issuer for distinct resources | §5 |
| 28 | The client MUST NOT inspect the content of the access token | §6 |

## 7. Ambiguities & notes

- `typ` case: §2.1 says the value SHOULD be `at+jwt` and §4 requires verifying `at+jwt` or `application/at+jwt`, but the Figure 2 example header is `"typ":"at+JWT"` (§3). The spec does not state whether the §4 comparison is case-sensitive. Guidance — ours, not spec: implementations should tolerate case variation seen in the spec's own example, but emit lowercase `at+jwt`.
- §4's error paragraph reads "the authorization server response MUST include the error code invalid_token" although the surrounding text concerns resource-server error handling. Guidance — ours, not spec: this appears to mean the resource server's response.
- The §4 validation steps are bullets introduced by "MUST validate it in the following manner"; the spec presents decryption before signature validation but never explicitly labels the bullets a strict sequence.
- §2.2.3.1 says authorization attributes "go beyond the delegated scenarios described by [RFC7519]". Guidance — ours, not spec: RFC 7519 is the JWT spec, so this citation reads oddly (delegation scenarios are an OAuth framework concept), but it is reproduced as the source states it.
- No mechanism identifies which advertised key signs JWT access tokens (§4), with the security consequence spelled out in §5 (any published key's compromise suffices to forge accepted tokens).
- Requirement levels for `roles`/`groups`/`entitlements` and `scope` are conditional SHOULDs — they apply only when the AS chooses to embed such attributes / when the request carried a scope parameter (§2.2.3, §2.2.3.1).
