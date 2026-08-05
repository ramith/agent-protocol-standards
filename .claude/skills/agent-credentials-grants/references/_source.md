# Sources — agent-credentials-grants

Raw copies live in `spec-src/agent-credentials-grants/` (git-ignored; extracts-only policy, D8). Hashes are SHA-256 of the raw fetched file; QA runs re-fetch and compare before any verdict counts. A hash mismatch is a fork, not a blocker (see `docs/qa-strategy.md`).

| id | url | revision | fetched | recheck-days | latest-url | sha256 |
|---|---|---|---|---|---|---|
| rfc8693 | https://www.rfc-editor.org/rfc/rfc8693.txt | RFC (immutable) | 2026-08-05 | 0 | — | 358d658014738bf4dc56c8aae2094ce716ede23b6d5a80488a7dc8e8d72da609 |
| rfc9396 | https://www.rfc-editor.org/rfc/rfc9396.txt | RFC (immutable) | 2026-08-05 | 0 | — | d6a8f032d8a585daae1c33a8c7b6e539d199f886ec8cc1c7898436f7f2eed29c |
| rfc9470 | https://www.rfc-editor.org/rfc/rfc9470.txt | RFC (immutable) | 2026-08-05 | 0 | — | 02d742f49cc0a03fb09197563c436b6f38928a71b0d8e41cde9cfe0362363e56 |
| rfc9449 | https://www.rfc-editor.org/rfc/rfc9449.txt | RFC (immutable) | 2026-08-05 | 0 | — | 3842c58e1f6043389416023b9bb8d765048266024982fbbd90640e05943f4e13 |
| rfc8707 | https://www.rfc-editor.org/rfc/rfc8707.txt | RFC (immutable) | 2026-08-05 | 0 | — | 3b89844a938b9219571931b664ed4a7b380555a4dda1df4e9445a2f72188e76b |
| rfc7523 | https://www.rfc-editor.org/rfc/rfc7523.txt | RFC (immutable) | 2026-08-05 | 0 | — | ae24f77a8fc4338903c805c6ace38def1f23d40194aea87b123b13c5b3d2d915 |
| cimd | https://www.ietf.org/archive/id/draft-ietf-oauth-client-id-metadata-document-02.txt | draft -02 (expires 2027-01-07) | 2026-08-05 | 90 | https://datatracker.ietf.org/doc/draft-ietf-oauth-client-id-metadata-document/ | 1a0d5f079042734e754afc88ca7a554418d12a2c64c936519130c55e322297fe |
| grant-mgmt | https://openid.net/specs/oauth-v2-grant-management-ID1.html | Implementer's Draft 1 | 2026-08-05 | 90 | https://openid.net/developers/specs/ | 13c3b8d3b2f16ad7cd529984e1fa0c228aca62de8eb9d7c155083d40d08798ab |

Fetch notes:
- RFCs fetched as immutable plain text from rfc-editor.org (`.txt`) — preferred format per QA strategy (no HTML→markdown conversion risk).
- CIMD fetched as the revision-pinned archive text; the datatracker landing page is the drift-check target.
- Grant Management is HTML-only at OpenID; hash is of the raw HTML. **Caution from acquisition:** an index-summary pass returned a nonexistent URL for this spec — the URL above was verified by direct fetch (title: "Grant Management for OAuth 2.0 (Draft)").
