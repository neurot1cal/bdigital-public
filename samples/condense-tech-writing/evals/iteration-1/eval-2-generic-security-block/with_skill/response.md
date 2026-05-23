## Trimmed draft

## Security

The storefront's access model is built around presigned download URLs. After the Stripe webhook confirms payment, `/api/download` generates a URL bound to a specific clip ID and customer email, with a 1-hour TTL. The 1-hour window is long enough for customers on slow connections to complete a download; short enough that a leaked URL does not grant indefinite access.

---

## Diff log

1. Cut paragraph 1 entirely: "Security is a critical consideration in any modern web application..." — pure opening throat-clear, zero system-specific content.
2. Cut paragraph 2 entirely: passwords hashed, HTTPS everywhere, rate limiting on auth endpoints, HttpOnly/Secure flags, CSRF double-submit — standard web-app checklist. None of it is specific to this system. If these decisions belong in the doc, they belong in a shared security baseline document, not here.
3. Kept paragraph 3 (presigned URLs) in full: contains the specific endpoint (`/api/download`), the trigger (Stripe webhook), the binding constraints (clip ID + customer email), the TTL (1-hour), and the explicit rationale for the TTL choice. All of this is specific to the system.
4. Cut paragraph 4 entirely: "In terms of data privacy, we take this very seriously. We comply with all applicable regulations..." — generic compliance statement with no system-specific content.
5. Cut the section opener sentence "Security is a model..." rephrase: restructured to put the system-specific noun ("presigned download URLs") first so the section earns its place immediately.

---

## Stats

Original: 237 words  
Trimmed: 63 words  
Reduction: 73%  
Rejected edits: 0

Note on the 73% cut: this is above the 60% threshold flagged in the skill for extra audit scrutiny. The cut is this deep because three of the four paragraphs were entirely generic prose that compresses to zero without information loss. The one paragraph with system-specific content (presigned URLs) survived intact. No quantitative claims, API surfaces, thresholds, or invariants were dropped.
