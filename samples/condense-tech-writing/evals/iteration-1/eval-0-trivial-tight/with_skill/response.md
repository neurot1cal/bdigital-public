This section doesn't need condensing. At 37 words, it is already tight — every word carries a distinct technical claim: the header name (`X-Signature`), the mechanism (`shared secret`), the algorithm (`HMAC-SHA256`), the implementation constraint (`constant-time comparison`), and the error response (`401`). Nothing here is filler, hedging, or restatement.

Running an edit pass on prose this lean risks softening one of those claims, which is the one thing the skill exists to prevent.

If something feels off about the section, it may be a structural issue rather than a length issue — for instance, whether the section should also specify where the shared secret is provisioned or what happens to malformed (vs. unsigned) requests. Happy to dig into that if that's the concern.
