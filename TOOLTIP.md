# Tooltip contract

`LiveViewContinuity.Tooltip.tooltip/1` is an unstyled descriptive tooltip. It renders one server-owned button trigger and one always-mounted `div[role="tooltip"][popover="manual"]`, with stable IDs `<id>-trigger` and `<id>-popup`.

## API and ownership

`id` is required and stable. Exactly one `trigger` slot and one body are required. `delay` is a nonnegative integer in milliseconds and defaults to `600`; `disabled` defaults to `false`. `describedby` supplies optional base IDREF tokens. `class`, `trigger_class`, and `tooltip_class` are styling seams, and global attributes apply only to the root.

LiveView owns trigger markup and content, tooltip content, existence, disabled state, delay, and base description tokens. The hook owns effective open state, pointer and focus source flags, timer generation, dismissal, `data-lvc-open`, native Popover state, and insertion of the tooltip ID into `aria-describedby`. Only those browser-owned reflections use narrow `JS.ignore_attributes/1`; the unprotected `data-lvc-base-describedby` root attribute lets server patches replace base tokens without freezing stale text.

Closed triggers omit the tooltip's own ID from `aria-describedby`. Open triggers append it exactly once while preserving base tokens. Closing removes only that token.

## Interaction and timing

- Real mouse pointer entry opens after the current delay. Pointer leave cancels pending work and closes immediately only when focus is not also active.
- Keyboard or programmatic focus opens immediately. Blur closes only when mouse hover is not also active.
- Escape, pointer press, Enter, and Space dismiss immediately and invalidate pending timers. Escape does not move focus. Dismissal remains effective until a fresh pointer-entry or focus cycle.
- Touch pointer entry does not open a tooltip. There is no close delay.
- Timer generations prevent callbacks from an old enter/leave cycle from opening. Focus during a pending hover cancels the timer and opens once. Unrelated content patches do not restart a hover timer.

## Patch continuity

The hook re-queries and rebinds the trigger and popup after patches. An in-place content patch preserves popup and trigger identity, focus, `:popover-open`, ARIA, and effective state while updating server content. A disabled patch closes and cancels pending work. If a replaced trigger loses focus, the tooltip closes instead of moving focus. Removal cleans listeners, timer, native state, and ARIA; re-adding starts closed.

The consumer owns all visual CSS and positioning. Tooltip content must be non-interactive and styled with `pointer-events: none`; it supplements rather than replaces the trigger's accessible name.

## Accessibility limits and deferred scope

This slice provides role and description lifecycle semantics, but is not full screen-reader certification. It intentionally has no touch affordance, interactive content, hover transit or safe polygon, portal, floating or collision engine, provider, arrow, animation, warmup/cooldown, close delay, or long press. Use visible or otherwise available content when touch users need the information.

The LIC v1 contract verifies retained popup identity and correct source-exit close/ARIA cleanup around an acknowledged patch. The three-engine application-specific browser tests verify the stronger focused-open patch path, including native open state, trigger and popup identity, focus, updated content, and ARIA. It makes no React Aria or Base UI compatibility claim.
