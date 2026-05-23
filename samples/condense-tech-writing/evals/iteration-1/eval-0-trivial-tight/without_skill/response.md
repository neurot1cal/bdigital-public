## Webhook signature validation

The handler validates `X-Signature` against the shared secret via HMAC-SHA256 with constant-time comparison. Invalid or missing signatures return 401.
