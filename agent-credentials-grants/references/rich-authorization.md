Source: rfc9396 — https://www.rfc-editor.org/rfc/rfc9396.txt — RFC (immutable) — fetched 2026-08-05 — extracted 2026-08-05

# RFC 9396 — OAuth 2.0 Rich Authorization Requests (RAR)

## Overview

Defines the `authorization_details` parameter: a JSON array of objects carrying fine-grained
authorization data in OAuth messages, going beyond what `scope` can express (e.g., "transfer
45 Euros to Merchant A") (§1). Each object's `type` field selects an API-specific schema; the AS
uses the data to gather user consent and then makes it available to RSs for enforcement (§2, §9).
Registers the error `invalid_authorization_details`, a JWT claim, an introspection member, and AS/client metadata (§5, §9, §10, §14).

## `authorization_details` structure (§2)

The parameter contains, in JSON notation, an array of objects; each object specifies the
authorization requirements for a certain type of resource (§2).

- `type` — string identifier for the authorization details type; its value determines the allowable
  contents of the containing object; unique for the described API in the context of the AS.
  REQUIRED (§2).
- The array MAY contain multiple entries of the same `type` (§2).
- The AS controls interpretation of `type` and the fields it allows; API designers are RECOMMENDED
  to pick unambiguous, easily copied `type` values, and to use a collision-resistant namespace
  (e.g., a URI they control) when an API is deployed across different servers (§2.1).

### Common data fields (§2.2)

Optional, reusable components; an API definition is not required to use them. Allowable values of
all fields are determined by the API being protected, as defined by a particular `type` value (§2.2).

| Field | Meaning | Section |
|---|---|---|
| `locations` | Array of strings for the location of the resource or RS, typically URIs; lets a client specify a particular RS (audience restriction, see §12) | §2.2 |
| `actions` | Array of strings for the kinds of actions to be taken at the resource | §2.2 |
| `datatypes` | Array of strings for the kinds of data being requested from the resource | §2.2 |
| `identifier` | String identifier indicating a specific resource available at the API | §2.2 |
| `privileges` | Array of strings for the types or levels of privilege being requested at the resource | §2.2 |

Combination semantics: when common fields are used together, the requested permissions are the
product of all values — every `actions` value at every `locations` value for every `datatypes`
value. For finer control, send multiple objects (e.g., read/contacts in one object, write/photos
in another) (§2.2). An API MAY define its own extension fields, subject to the object's `type` (§2.2).

Example from the spec (Figure 5, §2.2):

```json
[
   {
      "type": "customer_information",
      "locations": ["https://example.com/customers"],
      "actions": ["read", "write"],
      "datatypes": ["contacts", "photos"]
   }
]
```

## Where `authorization_details` appears

- **Authorization request (§3)**: usable everywhere `scope` is used for the same purpose —
  RFC 6749 authorization requests, RFC 8628 device authorization requests, and CIBA backchannel
  authentication requests. Encoding is context-dependent; in an RFC 6749 authorization request it
  is the serialized JSON in `application/x-www-form-urlencoded` format (§3). In case of
  authorization requests as defined in RFC 6749, implementers MAY consider using pushed
  authorization requests (RFC 9126) to improve the security, privacy, and reliability of the
  flow (§3). The AS asks the user for consent based on this
  data; the user may grant a subset (§3, note). The authorization response defines no extensions (§4).
- **Relationship to `scope` (§3.1)**: both can appear in the same request carrying independent
  requirements (supports incremental migration); a given API is RECOMMENDED to use only one form.
- **Relationship to `resource` (§3.2)**: the RFC 8707 `resource` parameter has no impact on how the
  AS processes `authorization_details`.
- **Token request (§6)**: the `authorization_details` token request parameter specifies what the
  client wants assigned to the access token. The AS checks whether the underlying grant
  (`authorization_code`, `refresh_token`, etc.) or the client's policy (`client_credentials`)
  allows issuance; otherwise it refuses with error code `invalid_authorization_details` (similar to
  `invalid_scope`) (§6).
- **Token response (§7)**: the AS MUST also return the `authorization_details` as granted by the
  resource owner and assigned to the respective access token (§7).
- **Introspection response (§9.2)**: `authorization_details` as a top-level member (see below).
- **JWT access token (§9.1)**: `authorization_details` as a top-level claim (see below).

### Comparing requested vs. granted (§6.1)

- There is **no standardized mechanism** to compare two arbitrary authorization detail requests;
  field semantics are implementation specific to a given API (§6.1).
- An AS should not rely on simple object comparison in most cases — intersections of fields can
  have side effects on granted rights depending on API design (§6.1).
- When comparing a new request to an existing one, the AS can use the same processing techniques
  used when granting the request originally, to determine whether the resource owner must
  re-authorize; the details of the comparison depend on the definition of the authorization details
  type and are outside the spec's scope (§6.1).
- The spec illustrates type-specific patterns: additive rights (verify actions/locations are
  subsets of what was approved), subsumption (`write` implies `read`; a `privileges` value of
  `admin` subsumes read/write — but other APIs may define non-subsuming values), and using
  `locations` to request an audience-restricted access token (§6.1).

### Enrichment (§7.1)

- The authorization details attached to the access token MAY differ from what the client requested:
  the user may authorize less, and the AS may **enrich** the object (e.g., adding the accounts the
  user selected, or `identifier` and `locations` for a chosen medical record) (§7.1).
- Whether enrichment is allowed and how it works is necessarily part of the definition of the
  respective authorization details type; the client needs to be aware upfront that a type can be
  enriched (§7.1).
- If the client omits `authorization_details` in the token request, the AS determines the resulting
  `authorization_details` at its discretion (§7). The AS MAY omit values in the
  `authorization_details` to the client (§7).

## AS and RS processing rules

- **AS error handling (§5)**: the AS MUST refuse to process any unknown authorization details type
  or details not conforming to the type definition, and MUST abort with error
  `invalid_authorization_details` if any object: has an unknown `type`; is of known type but
  contains unknown fields; has fields of the wrong type; has fields with invalid values; or is
  missing required fields. The Token Error Response MUST conform to the same rules (§8).
- **Making data available to the RS (§9)**: to enable the RS to enforce the authorization details
  as approved, the AS MUST make this data available to the RS. The AS MAY do so by adding the
  `authorization_details` field to JWT-format access tokens or to token introspection responses (§9).
- **JWT access tokens (§9.1)**: the AS is RECOMMENDED to add the authorization details object,
  filtered to the specific audience, as a top-level claim. The AS typically adds further RS-required
  claims (user ID, roles, transaction data) per RS-specific policy (§9.1).
- **Introspection (§9.2)**: if the AS includes authorization detail information for the token, it
  MUST be conveyed as `authorization_details`, a top-level member of the introspection response
  JSON object, and that member MUST contain the same structure defined in §2, potentially filtered
  and extended for the RS making the introspection request (§9.2).
- Guidance — ours, not spec: RFC 9396 puts no explicit normative obligation on the RS itself; the
  enforcement burden is framed as the AS making data available "to enable the RS to enforce" (§9),
  and deployments must "determine how the RSs process the authorization details" (§11.1).

## Metadata (§10)

- `authorization_details_types_supported` — AS metadata (RFC 8414) parameter, a JSON array of the
  authorization details types the AS supports (§10, §14.4).
- `authorization_details_types` — client registration metadata parameter, a JSON array; clients MAY
  use it to indicate the authorization details types they will use when requesting authorization
  (§10, §14.5).
- Registration of authorization details types with the AS is outside the scope of the spec (§10).
- IANA: parameter `authorization_details` registered for authorization request, token request, and
  token response (§14.1); JWT claim `authorization_details` (§14.2); introspection member
  `authorization_details` (§14.3); error `invalid_authorization_details` for token endpoint and
  authorization endpoint (§14.6).

## Normative requirements

- `type` is REQUIRED in every authorization details object (§2).
- Array MAY contain multiple entries of the same `type` (§2).
- Type values: RECOMMENDED to be unambiguous/easily copied; collision-resistant namespace
  RECOMMENDED for cross-server APIs (§2.1). APIs MAY define extension fields (§2.2).
- In case of authorization requests as defined in RFC 6749, implementers MAY consider using pushed
  authorization requests (RFC 9126) (§3).
- A given API is RECOMMENDED to use only one of `scope` / `authorization_details` (§3.1).
- AS MUST process `authorization_details` and `scope` requirements in combination (§3.1).
- AS MUST present the merged set of requirements when gathering user consent (§3.1).
- AS MUST refuse unknown types / non-conforming details; MUST abort with
  `invalid_authorization_details` for unknown type, unknown fields, wrong-typed fields, invalid
  values, or missing required fields (§5); Token Error Response MUST conform to the same rules (§8).
- Token response: AS MUST return the granted `authorization_details` assigned to the access
  token (§7); AS MAY omit values to the client (§7); granted details MAY differ from the
  request (enrichment) (§7.1).
- AS MUST make approved authorization details available to the RS (§9); MAY use JWT access tokens
  or introspection responses to do so (§9).
- JWT: RECOMMENDED to carry the details, filtered to the specific audience, as a top-level
  claim (§9.1).
- Introspection: if included, MUST be the top-level `authorization_details` member and MUST use the
  §2 structure, potentially filtered/extended per requesting RS (§9.2).
- Clients MAY declare types used via `authorization_details_types` registration metadata (§10).
- If integrity is a concern, clients MUST protect `authorization_details` against tampering and
  swapping (signed request objects per RFC 9101, or `request_uri` per RFC 9101 with RFC 9126) (§12).
- AS MUST properly sanitize and handle `authorization_details` data to prevent injection
  attacks (§12).
- String comparisons are done as defined by RFC 8259 — no additional transformation or
  normalization when evaluating equivalence (§12).

## Ambiguities & notes

- No standard comparison algorithm for requested-vs-granted details: entirely type-specific (§6.1);
  the AS decides using the type definition's own processing rules.
- No normative RS-side enforcement requirement exists in the spec; the availability obligation
  falls on the AS (§9), and RS processing is a deployment decision (§11.1).
- How AS combines `scope` and `authorization_details` requirements is API-specific and out of
  scope (§3.1); how enrichment works is defined per type, not by the RFC (§7.1).
- §6 refusal ("the AS refuses the request with the error code invalid_authorization_details") is
  stated in lowercase prose, not as a capitalized MUST; §5's MUSTs cover malformed/unknown details.
- Privacy: sensitive personal data in `authorization_details` must be kept from leaking (e.g.,
  referrer headers); options include encrypted request objects (RFC 9101) or PAR (RFC 9126); the AS
  should share the data with clients/RSs on a "need to know" basis per local policy (§13).
- Large requests: consider `request_uri` (RFC 9101) plus pushed request objects (RFC 9126) since
  URIs with `authorization_details` can become very long (§11.4).
