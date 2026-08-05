# agent-credentials-grants — validation checklist (draft)

Each row is one testable assertion: reviewers check designs against it, coders implement it, security testers write one probe per row. Severity: BLOCKER (defeats the purpose) / CRITICAL (exploitable) / MAJOR (weakens design) / ADVISORY (hardening). Basis `spec` rows are traceable to a normative requirement in a reference file (cited as source id + §; spec SHOULDs are phrased "unless documented exception"). Basis `profile` rows are our hardening beyond spec, with a one-clause rationale.

## 00x — JWT access token baseline validation (RFC 9068)

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-001 | CRITICAL | spec | REJECT any JWT access token whose `typ` header is neither `at+jwt` nor `application/at+jwt` (accept-set, not a single value); no other `typ` (including ID Token types) is accepted. | rfc9068 §4, §2.1 |
| ACG-002 | CRITICAL | spec | REQUIRE that the RS validates the signature per RFC 7515 using the `alg` header and only AS-published keys; REJECT any token with `alg` = `none`. | rfc9068 §4 |
| ACG-003 | CRITICAL | spec | REJECT any token whose `iss` claim does not exactly match the issuer identifier obtained via discovery/metadata. | rfc9068 §4 |
| ACG-004 | CRITICAL | spec | REJECT any token whose `aud` claim does not contain a resource indicator the RS expects for itself. | rfc9068 §4 |
| ACG-005 | CRITICAL | spec | REJECT any token where the current time is not before `exp`; clock-skew leeway, if any, is bounded (a few minutes at most). | rfc9068 §4 |
| ACG-006 | MAJOR | spec | VERIFY that when token encryption was negotiated at registration, unencrypted tokens are rejected unless a documented exception exists (spec SHOULD); and that every validation failure returns error code `invalid_token` per RFC 6750 §3.1. | rfc9068 §4 |
| ACG-007 | MAJOR | spec | REQUIRE that every issued JWT access token is signed (never `none`) and contains `iss`, `exp`, `aud`, `sub`, `client_id`, `iat`, and `jti`; AS and RS include RS256 among supported algorithms. | rfc9068 §2.1, §2.2 |
| ACG-008 | ADVISORY | profile | VERIFY that the RS rejects tokens presented before an `nbf` claim (when present) and can track `jti` for replay detection — profile: rfc9068 §4 mandates neither check, but honoring them is standard JWT hygiene. | profile — rfc9068 §4 omits nbf/jti from the validation sequence |

## 01x — Token exchange and `act` (RFC 8693)

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-010 | CRITICAL | spec | REQUIRE that the AS validates `subject_token` per its declared `subject_token_type`, and `actor_token` per its declared type when present; REJECT requests carrying `actor_token` without `actor_token_type`, or `actor_token_type` without `actor_token`. | rfc8693 §2.1 |
| ACG-011 | MAJOR | spec | REJECT invalid or policy-unacceptable `subject_token`/`actor_token` with error `invalid_request` — never `invalid_grant`. | rfc8693 §2.2.2 |
| ACG-012 | MAJOR | spec | VERIFY that exchange responses carry `issued_token_type` and `token_type`, and include the `scope` parameter whenever the issued scope differs from the requested scope. | rfc8693 §2.2.1 |
| ACG-013 | CRITICAL | spec | REQUIRE that token consumers make authorization decisions only on top-level claims plus the current actor, resolved as the OUTERMOST `act`; nested `act` members (prior actors) are logged, never authorized on. | rfc8693 §4.1 |
| ACG-014 | MAJOR | profile | REQUIRE that OBO tokens consumed by agent-facing endpoints carry an `act` claim identifying the agent (delegation form); REJECT impersonation-form issuance (no `act`) for agent on-behalf-of flows. | profile — impersonation removes the audit distinction delegation exists to provide; rfc8693 §1.1 leaves composite issuance discretionary |
| ACG-015 | MAJOR | profile | REJECT a token exchange when the `subject_token` carries `may_act` and the requesting actor (actor_token subject, or authenticated client) is not the party it identifies. | profile — rfc8693 §4.4 defines the semantics but mandates no enforcement; an unenforced may_act is dead policy |
| ACG-016 | CRITICAL | profile | REJECT exchanges that issue scope or authorization exceeding what the subject_token's underlying grant conveys, absent an explicitly documented AS broadening policy. | profile — rfc8693 §2.1 leaves scope semantics service-specific; silent broadening is privilege escalation via the STS |
| ACG-017 | CRITICAL | profile | REQUIRE client authentication on every token exchange request. | profile — rfc8693 §2.1 makes it a deployment decision while warning that an unauthenticated STS lets anyone launder a compromised token |

## 02x — DPoP sender-constraining and `cnf`/`jkt` binding (RFC 9449)

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-020 | CRITICAL | spec | REJECT any DPoP proof failing structural validation: more than one `DPoP` header; not a single well-formed JWT; `typ` ≠ `dpop+jwt`; `alg` not a registered asymmetric algorithm or equal to `none`/a MAC; `jwk` containing a private key; or signature that does not verify with the embedded `jwk`. | rfc9449 §4.2, §4.3, §11.5, §11.6 |
| ACG-021 | MAJOR | spec | REJECT proofs whose `htm`/`htu` do not match the current request (URI compared after normalization, ignoring query and fragment) or whose creation time (via `iat` or server-managed nonce timestamp) is outside the server's limited acceptance window. | rfc9449 §4.3, §11.1 |
| ACG-022 | MAJOR | spec | REQUIRE that once a server has supplied a `DPoP-Nonce`, it rejects proofs lacking the `nonce` claim or carrying a non-matching value, signaling `use_dpop_nonce`. | rfc9449 §8, §9, §11.3 |
| ACG-023 | CRITICAL | spec | REQUIRE that the RS verifies `ath` equals base64url(SHA-256(ASCII(access token))) AND that the proof's public key matches the token's bound key (`cnf.jkt` = base64url RFC 7638 SHA-256 JWK thumbprint, from the JWT or introspection). | rfc9449 §4.3 check 12, §6.1, §6.2, §7 |
| ACG-024 | CRITICAL | spec | REQUIRE that the RS grants access only when every §4.3 check passes; REJECT a DPoP-bound access token presented under the Bearer scheme; VERIFY bound tokens are reliably identifiable (`token_type` = `DPoP` at issuance and, if present, in introspection). | rfc9449 §7.1, §7.2, §5, §6.2 |
| ACG-025 | CRITICAL | spec | REQUIRE that refresh tokens issued to public clients presenting a DPoP proof are bound to that public key, the binding is validated on every refresh, and the same key is proven on each refresh request. | rfc9449 §5 |
| ACG-026 | ADVISORY | profile | VERIFY that server-provided nonces are enabled for long-running agent processes. | profile — without nonces, proofs can be pre-generated with future `iat` values (rfc9449 §11.2 pre-generation attack) |

## 03x — Audience binding (RFC 8707)

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-030 | MAJOR | spec | REQUIRE that the AS validates each `resource` parameter as an absolute URI without a fragment (MUST/MUST NOT) and without a query component unless a documented exception exists (SHOULD NOT); unacceptable values are rejected with `invalid_target`. | rfc8707 §2, §2.1 |
| ACG-031 | CRITICAL | spec | VERIFY that the AS audience-restricts issued access tokens to the resource(s) indicated by `resource`; issuing unrestricted tokens requires a documented exception (spec SHOULD). | rfc8707 §2 |
| ACG-032 | CRITICAL | spec | REQUIRE that the AS uses distinct `aud` values for access tokens issued by the same issuer for distinct resources. | rfc9068 §5 |
| ACG-033 | CRITICAL | profile | REQUIRE that the RS derives the target-resource identity from the validated token's `aud` claim (or introspection `aud`), never from client-supplied request parameters or headers. | profile — rfc8707 defines no RS-side validation rules; trusting request data voids the replay boundary audience binding creates |
| ACG-034 | MAJOR | profile | REQUIRE that the exact audience value each RS checks (literal resource URI vs mapped identifier) is agreed out of band and compared by exact string match with no URI normalization. | profile — rfc8707 §2 mandates no token-level audience encoding; unagreed values silently disable the check |
| ACG-035 | MAJOR | profile | REQUIRE one `resource` per token request (per-resource downscoped tokens off a multi-resource grant); REJECT multi-audience tokens absent documented inter-resource trust; in multi-tenant deployments the audience URI includes the tenant-identifying portion. | profile — rfc8707 §3 cautions (non-normatively) that any audience of a multi-audience token can replay it at the others, and cross-tenant replay needs a tenant-scoped audience |

## 04x — Rich authorization requests (RFC 9396)

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-040 | CRITICAL | spec | REQUIRE that the AS aborts with `invalid_authorization_details` for any `authorization_details` object with an unknown `type`, unknown fields, wrong-typed fields, invalid values, or missing required fields; token error responses follow the same rules. | rfc9396 §5, §8 |
| ACG-041 | MAJOR | spec | REQUIRE that the token response returns the `authorization_details` as granted by the resource owner and assigned to the access token (which may lawfully differ from the request via subsetting or enrichment). | rfc9396 §7, §7.1 |
| ACG-042 | BLOCKER | spec | REQUIRE that the AS makes the approved authorization details available to the RS — as a top-level JWT claim (filtered to the audience) or as the top-level introspection member `authorization_details` in the §2 structure. | rfc9396 §9, §9.1, §9.2 |
| ACG-043 | MAJOR | spec | REQUIRE that when `scope` and `authorization_details` appear together, the AS processes both requirement sets in combination and presents the merged set at consent. | rfc9396 §3.1 |
| ACG-044 | MAJOR | spec | REQUIRE that the AS sanitizes `authorization_details` against injection, compares strings per RFC 8259 with no normalization, and that clients protect the parameter against tampering (signed request objects or PAR) whenever integrity is a concern. | rfc9396 §12 |
| ACG-045 | CRITICAL | profile | REQUIRE that the RS enforces `authorization_details` on write operations: REJECT any request whose payload (action, resource, amount, target) falls outside the granted details conveyed for its audience. | profile — RFC 9396 places the normative burden on the AS only (§9, §11.1); unenforced details reduce fine-grained consent to theater |

## 05x — Step-up authentication (RFC 9470)

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-050 | CRITICAL | profile | REQUIRE that write/destructive agent-facing operations declare `acr` and maximum-auth-age floors and that the RS enforces them against the token's `acr`/`auth_time` (JWT claims or introspection) before executing. | profile — rfc9470 defines the challenge protocol but imposes no RS enforcement mandate; floors without enforcement are decorative |
| ACG-051 | MAJOR | spec | VERIFY that when authentication is insufficient, the RS responds 401 with `WWW-Authenticate` carrying error `insufficient_user_authentication` plus `acr_values` and/or `max_age` (a non-negative integer). | rfc9470 §3 |
| ACG-052 | CRITICAL | spec | REQUIRE that authentication recency is computed from `auth_time` (the user-authentication event, fixed across token renewals) — REJECT implementations that evaluate `max_age` against token `iat` or issuance time. | rfc9470 §3, §6.1; rfc9068 §2.2.1 |
| ACG-053 | MAJOR | spec | VERIFY that the AS treats a requested `acr` value as necessary: it includes `acr` only when authentication satisfied it and otherwise fails with `unmet_authentication_requirements`, unless a documented exception exists (spec SHOULD). | rfc9470 §5 |
| ACG-054 | MAJOR | spec | VERIFY that the client parses `acr_values`/`max_age` from the challenge and relays them as authorization request parameters, unless a documented exception exists (spec SHOULD). | rfc9470 §4 |
| ACG-055 | MAJOR | profile | REQUIRE that an agent receiving `insufficient_user_authentication` routes to a user-interactive re-authorization leg; REJECT designs where the agent retries via token exchange or its own credentials. | profile — a user step-up cannot be satisfied by agent-held credentials; retry loops burn the challenge signal |

## 06x — Client authentication (RFC 7523) and CIMD

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-060 | CRITICAL | spec | REQUIRE that `client_assertion` contains exactly one JWT and that its `sub` claim equals the authenticating client's `client_id` (note: spec does NOT pin `iss` to client_id). | rfc7523 §2.2, §3(2)B |
| ACG-061 | CRITICAL | spec | REJECT any client assertion whose `aud` does not contain the AS's own identity, compared using Simple String Comparison. | rfc7523 §3(3) |
| ACG-062 | MAJOR | spec | REJECT client assertions without `exp` or whose `exp` has passed (bounded clock skew allowed); when `nbf` is present, REJECT before that time; the AS may reject unreasonably distant `exp`/`iat`. | rfc7523 §3(4)–(6) |
| ACG-063 | CRITICAL | spec | REQUIRE that the assertion signature/MAC is validated before the client is authenticated; an invalid client-authentication JWT yields error `invalid_client`. | rfc7523 §3(9), §3.2 |
| ACG-064 | MAJOR | profile | REJECT reuse of a client-assertion `jti` within its `exp` window (track used jti values until expiry). | profile — rfc7523 makes replay protection explicitly optional (§3(7), §6); a replayed assertion is client impersonation |
| ACG-065 | MAJOR | spec | REQUIRE CIMD client identifier URL validation: https scheme, no userinfo, path component present, no single/double-dot segments, no fragment; the document's `client_id` matches the URL matches the fetch URL, all by simple string comparison. | cimd §3, §4 |
| ACG-066 | CRITICAL | spec | REQUIRE CIMD fetch hardening: never follow redirects; treat any non-200 status as an error; never fetch document URLs or in-document URLs resolving to special-use IP addresses (RFC 6890), with no loopback exception in production; limit bytes read (~5 KB, SHOULD); never cache error responses or invalid documents. | cimd §5, §5.2, §8.6, §8.7 |
| ACG-067 | CRITICAL | spec | REJECT CIMD documents declaring shared-secret authentication (`client_secret_basic`/`client_secret_post`/`client_secret_jwt` or any symmetric method) or containing `client_secret`/private key material — public keys only via `jwks`/`jwks_uri`; when `private_key_jwt` is declared, the AS requires that authentication using the metadata-discovered key. | cimd §4.1, §8.2 |

## 07x — Grant management and lifecycle

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-070 | BLOCKER | spec | REQUIRE that DELETE on the grant resource URL revokes the grant and ALL refresh tokens issued on it, responding 204 with an empty body. | grant-mgmt §6.5 |
| ACG-071 | CRITICAL | profile | REQUIRE that access tokens issued off a revoked or replaced grant become unusable within a documented bound (short lifetimes, introspection on use, or out-of-band token revocation). | profile — grant-mgmt §6.5/Section 10 only lowercase-should access-token revocation; self-contained tokens otherwise outlive the grant they were minted from |
| ACG-072 | MAJOR | spec | REQUIRE that `merge` and `replace` actions are rejected without a `grant_id`, and that the AS invalidates existing refresh tokens associated with the updated/replaced grant. | grant-mgmt §5.2 |
| ACG-073 | MAJOR | spec | REQUIRE that the token response carries `grant_id` when a valid, supported `grant_management_action` was requested; `grant_id` is unique per AS with guess-resistant entropy; error cases return `invalid_grant_id` (unknown/invalid/wrong resource owner) or `invalid_request` per §5.4. | grant-mgmt §5.4, §5.5 |
| ACG-074 | MAJOR | spec | REQUIRE that the Grant Management API runs over https, is restricted to confidential clients, and demands an access token with scope `grant_management_query` (query) or `grant_management_revoke` (revoke). | grant-mgmt §5.1, §6.1, §6.2 |
| ACG-075 | CRITICAL | spec | REQUIRE that authorization for grant data is never inferred from possession of a `grant_id` (it is a public identifier assumed to leak) and that no user identity or PII is derivable from the `grant_id` value alone. | grant-mgmt §9, §10 |

## 08x — Cross-cutting profile rules

| ID | Severity | Basis | Assertion | Source |
|---|---|---|---|---|
| ACG-080 | CRITICAL | spec | REQUIRE that every security token (input and issued) is transmitted only over encrypted channels (TLS), and that DPoP is always used in conjunction with HTTPS. | rfc8693 §6; rfc9449 §2 |
| ACG-081 | CRITICAL | profile | REJECT designs that issue bearer (non-sender-constrained) on-behalf-of tokens for write-capable scopes; REQUIRE DPoP (or equivalent proof-of-possession) binding on such tokens. | profile — a stolen agent bearer token is silently replayable; sender-constraining is the compensating control for long-running automated holders |
| ACG-082 | MAJOR | profile | REQUIRE that write operations are authorized via token introspection or an equivalent revocation-aware check, not local JWT validation alone. | profile — a revoked grant must not keep authorizing writes for the residual exp window of a self-contained token |
| ACG-083 | MAJOR | profile | VERIFY that refresh tokens are not issued by default for write-scope agent grants; where issued, REQUIRE sender-constraining (public clients) and invalidation on grant merge/replace/revoke. | profile — long-lived silent re-auth extends the blast radius of an agent compromise beyond any single access token |
| ACG-084 | CRITICAL | profile | REQUIRE that the AS re-evaluates the user's underlying grant/consent at every token exchange; REJECT exchanges once the grant is revoked or narrowed below the requested authorization. | profile — rfc8693 §2.1 creates no input/output token linkage, so the exchange is the only checkpoint where revoked authority can be caught |
| ACG-085 | ADVISORY | profile | VERIFY that implementations pin the draft versions they build on (CIMD draft -02, expires 2027-01-07; Grant Management Implementer's Draft 1) and re-verify behavior on each revision. | profile — both documents are non-final; parameter names, actions, and API shape may change |

## Deliberately not asserted

- **DPoP proof freshness window value.** RFC 9449 §4.3/§11.1 requires a limited acceptance window but leaves its size unspecified ("preferably ... seconds or minutes", future `iat` MAY be tolerated for clock offset). ACG-021 asserts a bounded window exists; the number is deployment policy.
- **Audience encoding inside the token.** RFC 8707 mandates no token format or claim for audience restriction ("can be communicated" via JWT/introspection `aud`), and the AS may map `resource` to an abstract identifier. ACG-034 requires the value be agreed out of band; the value itself cannot be standardized here.
- **RAR requested-vs-granted comparison algorithm.** RFC 9396 §6.1 states there is no standardized mechanism — semantics are type-specific (subsets, subsumption, enrichment) and generic object equality is explicitly discouraged. Per-type comparison rules belong to each API's type definition, not this checklist.
- **An `acr` hierarchy or ordering.** RFC 9470 §2 says "level" and "step up" are metaphors with no interoperable hierarchy of authentication methods; which `acr` values satisfy a given floor (ACG-050) is RS/AS deployment policy.
- **Case sensitivity of the `at+jwt` typ comparison.** RFC 9068's own example header uses `at+JWT` while §2.1/§4 use `at+jwt`, and the spec never states whether the §4 comparison is case-sensitive. Probes for ACG-001 should record, not judge, case handling.
- **DPoP refresh-token binding internals.** RFC 9449 §5 leaves the binding implementation "at the discretion of the authorization server" with explicitly no interoperability requirement; ACG-025 asserts the observable behavior only.
