# V1-A Adversarial Verification — client-auth.md

- Target: /Users/ramith/code/agent-protocol-standards/agent-credentials-grants/references/client-auth.md
- Sources (both read in full):
  - /Users/ramith/code/agent-protocol-standards/spec-src/agent-credentials-grants/rfc7523.txt (675 lines)
  - /Users/ramith/code/agent-protocol-standards/spec-src/agent-credentials-grants/cimd-02.txt (1120 lines)
- Verifier: A-adversarial
- Date: 2026-08-05

## Verdict counts

| Part | VERIFIED | UNSUPPORTED | CONTRADICTED | AMBIGUOUS |
|---|---|---|---|---|
| Part A (RFC 7523: A1–A4 + Part-A ambiguity notes) | 51 | 0 | 0 | 0 |
| Part B (CIMD: maturity warning, B1–B5 + Part-B ambiguity notes) | 78 | 0 | 0 | 4 |
| **Total** | **129** | **0** | **0** | **4** |

Claim granularity: each table row's individual facts, each normative bullet, each URN/quote/example, and each ambiguity note counted as separate claims. B5's condensed lists (~21 items) were checked item-by-item against the sections they cite and against the B1–B4 text they summarize. `Guidance — ours, not spec:` line (target line 119) exempt per instructions; it does not contradict either source.

Spot-verified as character-exact: both URNs (`urn:ietf:params:oauth:grant-type:jwt-bearer`, rfc7523 line 540; `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`, line 552); the §2.2 request example; the §3.1 error-response example (claimed "exact" — confirmed byte-identical incl. single-space JSON indent); the §8.2 CIMD metadata example; "5 kilobytes" (cimd line 686); "200 OK" in both §4 and §5 (cimd lines 259, 367); grep confirms uppercase "SHOULD" occurs in rfc7523 only in the §1.1 RFC 2119 boilerplate (line 178), supporting A4's closing claim; §7's "should only be transmitted over encrypted channels" is lowercase as the target states.

## Findings (non-VERIFIED items)

### F1. B3 SSRF bullet — loopback exception stated broader than the draft allows (dropped condition)
- Claim (target line 102): "a loopback exception MAY apply only to development/testing deployments and MUST NOT be applied in production"
- Source (cimd §8.6, lines 648–651): "Authorization servers deployed for development or testing purposes MAY relax this restriction to allow fetching from loopback addresses **when the authorization server itself is also running on a loopback address and the resolved address matches the same loopback interface.**"
- Verdict: AMBIGUOUS (dropped condition). The dev/test scoping and the production MUST NOT ("Authorization servers MUST NOT apply this exception in production deployments", lines 652–653) are accurate, but the extraction omits that even in dev/test the MAY is conditional on the AS itself running on the same loopback interface as the resolved address. As written, the extraction permits a dev AS on a routable address to fetch loopback URLs — the draft does not.

### F2. B4 — jwks/jwks_uri presented as "the draft's permitted vehicles" (exclusivity not in source)
- Claim (target line 107): "the draft's permitted vehicles are the `jwks` or `jwks_uri` properties (§4.1)"
- Source (cimd §4.1, lines 298–300): "only public keys, **such as** those published via the jwks or jwks_uri properties, are permitted"
- Verdict: AMBIGUOUS (overstated). The source's restriction is "only public keys"; `jwks`/`jwks_uri` are given illustratively ("such as"), not as an exhaustive list of permitted vehicles. Note B2 (line 93) renders this same bullet correctly, and the Ambiguities note (line 125) frames it acceptably ("key material rides on RFC 7591 registry metadata") — only the B4 phrasing adds exclusivity.

### F3. B4 — §8.2 SHOULD: condition compressed and "such as" hardened to "from"
- Claim (target line 107): "Clients capable of maintaining private key material SHOULD perform client authentication with an acceptable method from the OAuth Token Endpoint Authentication Methods registry (§8.2)"
- Source (cimd §8.2, lines 518–522): "Clients that are capable of maintaining private key material **and performing client authentication** SHOULD do so with an acceptable method, **such as** a method in the OAuth Token Endpoint Authentication Methods registry"
- Verdict: AMBIGUOUS (minor). Two shifts: (a) the source conditions the SHOULD on capability of maintaining keys AND performing client authentication — the extraction drops the second capability; (b) the registry is an example of acceptability ("such as"), not the definition of it ("from"). Low practical impact; flagged for precision.

### F4. Part B maturity warning — "open TBDs" (plural)
- Claim (target line 75): "Contains open TBDs (e.g., a possible `client_id_expires_at` property, §4)"
- Source: grep finds exactly one TBD in cimd-02.txt (line 270: "TBD: We may want a property such as client_id_expires_at ..."). No other "TBD" occurrences.
- Verdict: AMBIGUOUS (trivial). The plural + "e.g." implies additional TBDs that do not exist in -02. The one TBD cited is real and correctly located; the later Ambiguities note (line 124) uses the singular correctly.

## Refutation attempts that failed (worth recording)

- A2 `iss` row cites Simple String Comparison for issuer values — checked suspicion that this only applies to `aud`; rfc7523 §3(1) (lines 289–292) does mandate it for issuer values too. VERIFIED.
- A3 "Reject missing/failed iss, sub, aud, exp checks" — rfc7523 §3(1)/(2) contain no explicit "MUST reject", but the §3 intro ("the authorization server MUST validate the JWT according to the criteria below", lines 274–276) plus §3(10) support the synthesis. VERIFIED.
- A2/Ambiguities attribution of "configured out of band" to §5 — the literal sentence lives in §3(3) (lines 318–321) but itself says "As noted in Section 5"; §5 requires out-of-band agreement on audience values. Attribution acceptable. VERIFIED.
- B2 "MUST be served with a 200 OK (§4, §5)" — suspected the -02 history note ("Moved the 200 OK requirement to the fetching process") meant §4 no longer states it; both §4 (line 259) and §5 (line 367) state it in -02. VERIFIED.
- B5 counts "×5" (URL shape MUSTs: https, no-userinfo, path, no dot-segments, no fragment) and "×3" (§4.1 bans) — both counts match the source bullets exactly. VERIFIED.
- cimd §6 tension claim — source (lines 407–414) does say "MUST include the following property" while labeling it "OPTIONAL"; the target reports the tension rather than resolving it. VERIFIED.
- Appendix A "explicitly non-normative despite containing MUST/MAY language" — line 929 "non-normative pattern"; MUST at line 963, MAY at lines 948/959/960. VERIFIED.
- rfc7523 example JWT header algorithm in §4 is ES256, not RS256 — checked that the target does not misstate this anywhere; it only claims RS256 as mandatory-to-implement (§5, lines 489–490). VERIFIED.

## NOT CHECKED:
Elided JWT payload segments in examples (both target and source show `[...]`; visible prefixes were compared exactly); live URLs and fetch-date metadata in the target's two Source header lines (not re-fetched); the content of third-party specs CIMD cites (RFC 7591, RFC 8414, RFC 9700, RFC 6890, RFC 9111, OpenID) — only that the target attributes them the same way the CIMD draft does; page-number/formatting artifacts.

## Triage 2026-08-05

- F1 — FIXED: B3 SSRF bullet now reads "... ASes deployed for development or testing purposes MAY relax this restriction to allow fetching from loopback addresses when the AS itself is also running on a loopback address and the resolved address matches the same loopback interface — and MUST NOT apply this exception in production deployments; ..." — the same-loopback-interface condition restored.
- F2 — FIXED: B4 now reads "only public keys are permitted, such as those published via the `jwks` or `jwks_uri` properties (§4.1)" — exclusivity claim removed; the restriction is "only public keys", with `jwks`/`jwks_uri` as the source's "such as" examples.
- F3 — FIXED: B4 now reads "Clients that are capable of maintaining private key material and performing client authentication SHOULD do so with an acceptable method, such as a method in the OAuth Token Endpoint Authentication Methods registry (§8.2)" — both capabilities restored to the condition and "from" reverted to the source's "such as".
- F4 — FIXED: maturity warning now reads "Contains an open TBD (a possible `client_id_expires_at` property, §4)." — singular, matching the one TBD in cimd-02.
