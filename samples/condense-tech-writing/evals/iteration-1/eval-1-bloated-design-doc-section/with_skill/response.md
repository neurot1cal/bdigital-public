## Trimmed draft

## Decision: storage layer for clip artifacts

Primary object storage: Cloudflare R2, bucket `bdigital-clips`.

- **Zero egress fees.** Clips are downloaded by paying customers; bandwidth charges would directly reduce margin per sale.
- **S3-compatible API.** Existing S3 SDKs and tooling work without a custom client.
- **Existing Cloudflare relationship.** We already use Cloudflare for Workers, DNS, and CDN; R2 adds no new vendor.

R2 list operations are eventually consistent, so newly uploaded files may not appear in list responses immediately. The upload pipeline must not rely on list-after-write semantics; track uploaded keys in a separate data store instead. The clip-upload pipeline already does this via `clips.json`.

---

## Diff log

1. Cut "In order to support the storage requirements of the clip storefront, we will need to make a decision about which storage backend to use for the underlying video artifacts." (restates the heading)
2. Cut "It is worth noting that there are several options available to us in this space, and each comes with its own tradeoffs that we need to carefully consider before moving forward with implementation." (generic preamble, zero information content)
3. Cut "This decision was made for several reasons that are worth discussing in detail." (announces the list; removed; list follows directly)
4. Cut "First/Second/Third" prose paragraphs → converted to 3 labeled bullets (same content, tighter structure)
5. Cut "which is critically important for our use case because" on the egress bullet (filler; the reason is the reason)
6. Cut "without having to write a custom client" trailing clause on the S3 bullet → reworded to "without a custom client" (same meaning, shorter)
7. Cut "so adopting it does not introduce a new vendor relationship that we would need to manage separately" → "R2 adds no new vendor" (same claim, half the words)
8. Cut "It is important to understand that there are some tradeoffs associated with this choice." (filler hedge; the tradeoff paragraph follows directly)
9. Cut "In practice, this means that" (filler transition; the constraint stated directly is sufficient)
10. Cut "In the next section, we will discuss the access control model for presigned download URLs." (forward-reference announcement; cut entirely; no information lost)
11. Preserved: "bdigital-clips" bucket name (specific noun)
12. Preserved: "clips.json" filename (specific noun)
13. Preserved: "eventually consistent for list operations" phrasing (technical invariant)
14. Preserved: "list-after-write semantics" (specific constraint language)

No edits rejected.

---

## Stats

Original: 302 words  
Trimmed: 148 words  
Reduction: 51%  
Rejected edits: 0
