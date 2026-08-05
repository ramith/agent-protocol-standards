# Implementer pitfalls

Compiled from the "Ambiguities & notes" sections of the seven reference files in this directory;
§refs are the spec sections those files carry.

## Token exchange (token-exchange.md, RFC 8693)

**Reading nested `act` inside-out.** The OUTERMOST `act` is the CURRENT actor; the most deeply
nested is the LEAST RECENT (earliest) actor (§4.1). Guidance — ours, not spec: many
implementations invert this.

**Making access-control decisions on prior actors.** Consumers MUST only consider top-level claims
plus the current actor; nested `act` members are informational only (§4.1).

**Assuming an `actor_token` guarantees an `act` claim.** Issuing a composite token is "at the
discretion of the authorization server and applicable policy and configuration" (§1.1); "delegation is impossible
without an actor_token" appears only in the non-normative Appendix A.1.1.

**Returning `invalid_grant` for a bad subject/actor token.** The mandated error is
`invalid_request` for invalid or policy-unacceptable subject/actor tokens (§2.2.2).

**Confusing `token_type` with `issued_token_type`.** `token_type` says how to use the token;
`issued_token_type` says its representation. `access_token` is a historical name and may carry a
non-access-token — `token_type` is then `N_A` (§2.2.1).

**Emitting the `scope` claim as a JSON array.** §4.2 defines it as a single space-separated JSON
string.

**Expecting input/output token linkage.** Exchanged tokens are independent of their inputs after
issuance; revocation propagation is implementation-specific, not a protocol property (§2.1).

## Rich authorization (rich-authorization.md, RFC 9396)

**Expecting the RFC to force RS-side enforcement of `authorization_details`.** The normative
obligation is on the AS to make the data available (§9); RS processing is a deployment decision
(§11.1). Guidance — ours, not spec: your RS should still enforce the details it receives.

**Comparing requested vs granted details with generic object equality.** No standardized comparison
exists; semantics are type-specific and the AS should not rely on simple object comparison (§6.1).

**Treating the §6 refusal as a capitalized MUST.** The `invalid_authorization_details` refusal in
§6 is lowercase prose; the capitalized MUSTs in §5 cover unknown/malformed details (§5, §6).

## Step-up (step-up.md, RFC 9470)

**Treating "authentication level" as an interoperable hierarchy.** "Level" and "step up" are
explicitly metaphors; they "do not suggest that there is an absolute hierarchy of authentication
methods expressed in interoperable fashion" (§2).

**Assuming a stepped-up token supersedes older tokens.** Not necessarily (e.g. high-ACR short-lived
tokens); the spec recommends no caching strategy, and clients "must not" (lowercase, non-BCP14)
inspect access token content (§2).

**Reading §5's OIDC citations as new RFC 9470 normatives.** The MAY/SHOULD/MUST for ID Token
`acr`/`auth_time` restate OIDC requirements; only the access-token SHOULD is native to §5.

## DPoP (dpop.md, RFC 9449)

**Hardcoding a "standard" proof freshness window.** §4.3 check 11 accepts either `iat` or a
server-managed timestamp via `nonce`; the acceptable window is unspecified — §11.1 says only
"preferably ... seconds or minutes", and future-skewed `iat` MAY be accepted for clock offset.

**Expecting interoperable refresh-token binding details.** They are "at the discretion of the
authorization server" — explicitly no interoperability requirement (§5).

Guidance — ours, not spec: without server nonces, a party controlling the client can pre-generate
proofs with future `iat` values (§11.2) — prefer nonce support for long-running agent processes.

## Audience binding (audience-binding.md, RFC 8707)

**Assuming RFC 8707 mandates how audience is encoded in the token.** §2 only says restrictions
"can be communicated" via JWT `aud` or introspection `aud`; no token format or claim is required,
and the AS may map `resource` to a more general or abstract identifier.

**Treating audience restriction as mandatory.** It is only SHOULD (§2), and the spec states no
RS-side audience validation rules. Guidance — ours, not spec: agree out of band on the exact
audience value (URI vs mapped identifier) that resource servers check.

## Client auth (client-auth.md, RFC 7523 + CIMD draft)

**Believing RFC 7523 pins `iss` to the client_id.** Only `sub` MUST be the `client_id` for client
authentication (§3(2)B); `iss` is just "a unique identifier for the entity that issued the JWT"
(§3(1)). Guidance — ours, not spec: many profiles set iss = sub = client_id; don't assume it.

**Hardcoding the token endpoint URL as the required `aud`.** The token endpoint URL is only a MAY
(§3(3)); precise audience strings "must be configured out of band" (§5).

**Assuming assertion replay protection.** Replay protection is explicitly optional (§6); `jti`
presence and AS tracking are both MAY (§3(7)).

**Building on CIMD as if it were a standard.** CIMD is IETF Internet-Draft -02, work in progress,
EXPIRES 2027-01-07 — every fact may change. Note its internal tension: §6 labels
`client_id_metadata_document_supported` OPTIONAL yet says RFC 8414 publishers "MUST include" it.

## Grant management (grant-management.md, OAuth Grant Management, Implementer's Draft 1)

**Relying on draft details as stable.** The spec is Implementer's Draft 1 (draft -03, May 2023),
not final; parameter names, actions, and API shape may change — verify against the current spec.

**Implementing an `update` action.** `update` was renamed to `merge` in draft -02 (Appendix D);
stale "update" mentions remain in Sections 5.5 and 5.6.2. The defined action value is `merge`.

**Emitting or parsing only one of `last_updated`/`last_updated_at`.** Section 6.4 prose defines
`last_updated` but its example uses `"last_updated_at"`; the spec does not resolve this.
Guidance — ours, not spec: expect implementations to emit either.

**Trusting the IANA registry description of `grant_management_actions_supported`.** Appendix A.2
describes it as "authorization details types" — apparently a copy-paste error; Section 7.1 defines
it as the supported actions (`query`, `revoke`, `merge`, `replace`, `create`).

**Reading lowercase "must/shall/should" as non-binding.** The BCP 14 note makes only ALL-CAPS
normative, yet most body requirements are lowercase. Guidance — ours, not spec: treat them as
intended requirements but expect interoperability wiggle room.

**Treating `grant_id` as a secret.** It is a public identifier — assume it leaks (e.g. via
authorization requests) and protect grant data with client authentication/authorization instead
(Section 10).
