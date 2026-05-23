# cursor-team-kit — project guidance

Advisory rules consolidated from the upstream `cursor-team-kit/rules/` directory. Cursor's `.mdc` rules carry an `alwaysApply: true` flag that auto-injects them into every conversation; Claude Code has no equivalent primitive, so these are surfaced here for parents to consult when working in repos covered by this plugin.

Original rules (MIT, © 2026 Cursor): https://github.com/cursor/plugins/tree/3347cbab5b54136f6fba0994c3a01a56f7fb7fca/cursor-team-kit/rules

## TypeScript: exhaustive switch handling

In `switch` statements over discriminated unions or enums, use a `never` check in the `default` case so newly added variants cause compile-time failures until handled.

```typescript
function handle(event: AppEvent) {
  switch (event.kind) {
    case "open": return openWindow(event);
    case "close": return closeWindow(event);
    default:
      const _exhaustive: never = event;
      throw new Error(`Unhandled event: ${(_exhaustive as AppEvent).kind}`);
  }
}
```

## No inline imports

Always place imports at the top of the module. Avoid inline imports inside function bodies, type annotations, or interface fields unless there is a strict circular-dependency reason — and document the reason inline when you do.

Acceptable exception (documented):
```typescript
// Inline import required to break a circular dep between routing/ and ui/.
// Remove once we extract the shared type into types/navigation.ts.
function navigate() {
  const { Router } = require("./router");
  return new Router();
}
```
