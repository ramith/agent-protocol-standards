# Wire artifacts — copy and adapt

All content is drawn from the seven reference files in this directory; §refs are the spec sections
those files carry. `#`/`//` comments, reflowed whitespace, and PLACEHOLDER values are ours.

## 1. Token exchange request — token-exchange.md, rfc8693 §2.1 parameter table + §3 token types (assembled from the table; the extract carries no verbatim request figure)

POST to the token endpoint, `application/x-www-form-urlencoded`, UTF-8 (§2.1).

```
grant_type=urn:ietf:params:oauth:grant-type:token-exchange           # REQUIRED, exactly this value (§2.1)
&resource=https%3A%2F%2Fapi.example.com%2F                           # OPTIONAL; absolute URI, no fragment (§2.1)
&audience=downstream-service                                         # OPTIONAL; logical name, unique within the AS (§2.1)
&scope=read                                                          # OPTIONAL; space-delimited (§2.1)
&requested_token_type=urn:ietf:params:oauth:token-type:access_token # OPTIONAL; else AS discretion (§2.1, types §3)
&subject_token=PLACEHOLDER_USER_TOKEN                                # REQUIRED; party on whose behalf (§2.1)
&subject_token_type=urn:ietf:params:oauth:token-type:access_token   # REQUIRED (§2.1)
&actor_token=PLACEHOLDER_AGENT_TOKEN                                 # OPTIONAL; the acting party, e.g. the agent (§2.1)
&actor_token_type=urn:ietf:params:oauth:token-type:access_token     # REQUIRED iff actor_token present (§2.1)
```

Response (§2.2.1): `access_token` + `issued_token_type` + `token_type` REQUIRED; `expires_in` RECOMMENDED; `scope` REQUIRED when it differs from the request.

## 2. DPoP proof JWT, decoded header.payload — dpop.md, rfc9449 §4.2 Figure 4

```json
{
  "typ":"dpop+jwt",
  "alg":"ES256",
  "jwk": { "kty":"EC", "crv":"P-256",
    "x":"l8tFrhx-34tV3hRICRDY9zCkDlpBhF42UQUfWVAWBFs",
    "y":"9VE4jf_Ok_o64zbTTlcuNJajHmt6v9TDVrU0CdvGRDA" }
}
.
{ "jti":"-BwC3ESc6acc2lTc", "htm":"POST",
  "htu":"https://server.example.com/token", "iat":1562262616 }
```

At a protected resource also add `ath` = base64url(SHA-256(ASCII(access token))) and, when the server
supplied one, `nonce` (§4.2, §7). `alg` MUST NOT be `none`/symmetric; `jwk` MUST NOT hold a private key (§4.2).

## 3. DPoP-bound access token `cnf`/`jkt` claims set — dpop.md, rfc9449 §6.1 Figure 9

```json
{
  "sub":"someone@example.com", "iss":"https://server.example.com",
  "nbf":1562262611, "exp":1562266216,
  "cnf": { "jkt":"0ZcOCORZNYy-DWpqq30jZyJGHTN0d2HglBV3uiguA4I" }
}
```

`jkt` MUST be the base64url RFC 7638 JWK SHA-256 Thumbprint of the bound key (§6.1); the token
response `token_type` MUST be `DPoP` (§5).

## 4. `authorization_details` — rich-authorization.md, rfc9396 §2.2 Figure 5

```json
[{
   "type": "customer_information",
   "locations": ["https://example.com/customers"],
   "actions": ["read", "write"],
   "datatypes": ["contacts", "photos"]
}]
```

`type` is REQUIRED (§2); combined fields grant the cross-product of all values — send multiple objects for finer control (§2.2).

## 5. Step-up challenge — step-up.md, rfc9470 §3 Figure 2

```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer error="insufficient_user_authentication",
  error_description="A different authentication level is required",
  acr_values="myACR"
```

Figure 3 variant: same error with `max_age="5"`. Both auth-params MAY appear in one challenge if the RS needs to express requirements about both recency and authentication level; the RS MAY also add `scope` (§3).

## 6. Client authentication JWT — client-auth.md, rfc7523 §2.2 wire example + §3 claims table (claims set assembled from the table; the extract has no verbatim claims figure)

```
grant_type=authorization_code&code=n0esc3NRze7LTCu7iYzS6a5acc3f0ogp4&
client_assertion_type=urn%3Aietf%3Aparams%3Aoauth%3Aclient-assertion-type%3Ajwt-bearer&
client_assertion=eyJhbGciOiJSUzI1NiIsImtpZCI6IjIyIn0.[...]
```

```jsonc
{
  "iss": "PLACEHOLDER_ISSUER",           // MUST; unique id of the JWT's issuer — NOT pinned to client_id (§3(1))
  "sub": "PLACEHOLDER_CLIENT_ID",        // MUST; for client auth, MUST be the client_id (§3(2)B)
  "aud": "https://as.example.com/token", // MUST identify the AS; token endpoint URL only MAY be used (§3(3), §5)
  "exp": 1562266216,                     // MUST; AS rejects expired, modulo clock skew (§3(4))
  "jti": "PLACEHOLDER_UNIQUE_ID"         // MAY; AS MAY track to prevent replay (§3(7))
}
```

The JWT MUST be signed or MACed by the issuer (§3(9)); `RS256` is mandatory-to-implement (§5).

## 7. Grant query response — grant-management.md, grant-mgmt Section 6.4 example (Implementer's Draft 1)

```json
{
   "scopes":[
      {"scope":"contacts read", "resource":["https://rs.example.com/api1"]},
      {"scope":"write", "resource":["https://rs.example.com/api2","https://rs.example.com/api3"]},
      {"scope":"openid"}],
   "claims":["given_name","nickname","email","email_verified"],
   "authorization_details":[
      {"type":"account_information", "actions":["list_accounts","read_balances","read_transactions"],
       "locations":["https://example.com/accounts"]}],
   "created_at":1356123600, "last_updated_at":1356123600,
   "expires_at":1356123600, "updated_by":"client"
}
```

## 8. Composite: delegated agent access-token claims set

Guidance — ours, not spec: no single spec defines this shape; it assembles claims from five
reference files. Every field cites its source; values are illustrative, taken from those sources.

```jsonc
{
  "iss": "https://issuer.example.com",     // token-exchange.md rfc8693 §4.1 Fig 6: token issuer
  "sub": "user@example.com",               // token-exchange.md §4.1 Fig 6 / §A.2.5: delegation keeps sub = subject_token's subject
  "aud": "https://service26.example.com",  // token-exchange.md §4.1 Fig 6; audience-binding.md rfc8707 §2: aud can carry the audience restriction (encoding not mandated)
  "client_id": "s6BhdRkqt3",               // token-exchange.md rfc8693 §4.3: client that requested the token
  "scope": "read write",                   // token-exchange.md rfc8693 §4.2: single space-separated string, not an array
  "act": { "sub": "https://service16.example.com" },                // token-exchange.md rfc8693 §4.1: outermost act = CURRENT actor (the agent)
  "cnf": { "jkt": "0ZcOCORZNYy-DWpqq30jZyJGHTN0d2HglBV3uiguA4I" },  // dpop.md rfc9449 §6.1 Fig 9: RFC 7638 thumbprint of the agent's DPoP key
  "authorization_details": [{ "type": "customer_information",      // rich-authorization.md rfc9396 §9.1: RECOMMENDED top-level JWT claim, filtered to audience
    "locations": ["https://example.com/customers"],
    "actions": ["read"], "datatypes": ["contacts"] }],              // structure per rich-authorization.md rfc9396 §2.2 Fig 5
  "acr": "myACR",                          // step-up.md rfc9470 §6.1 Fig 6 (RFC 9068 §2.2.1): set at user-authentication time
  "auth_time": 1646340198,                 // step-up.md rfc9470 §6.1 Fig 6: user-auth event time; unchanged on token renewals
  "exp": 1562266216,                       // dpop.md rfc9449 §6.1 Fig 9 shows exp on a bound token; client-auth.md rfc7523 §3(4): bounds usable window
  "jti": "PLACEHOLDER_UNIQUE_ID"           // client-auth.md rfc7523 §3(7): unique token id for replay tracking (defined there for assertion JWTs)
}
```
