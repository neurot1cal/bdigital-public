## Decision: storage layer for clip artifacts

Clip artifacts will be stored in Cloudflare R2, bucket `bdigital-clips`.

Three factors drove the choice: R2 has zero egress fees, keeping per-sale margin intact; its S3-compatible API means no custom client work; and it fits within our existing Cloudflare footprint (Workers, DNS, CDN) without adding a new vendor relationship.

One constraint to track: R2 list operations are eventually consistent, so newly uploaded files may not appear in list responses immediately. The upload pipeline must not rely on list-after-write semantics — track uploaded keys in an external data store instead. The current `clips.json` file already handles this.

Next: access control model for presigned download URLs.
