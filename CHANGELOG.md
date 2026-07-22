# Changelog

## 0.4.0 — 2026-07-22

- Add a controlled Dialog mode that omits the trigger and `on_open` for server-driven confirmation flows while preserving native modal, close, focus, and patch-continuity behavior.

## 0.3.0 — 2026-07-22

- Add native LiveView `navigate` items to Menu while preserving link semantics, disabled behavior, roving focus, typeahead, and patch identity.

## 0.2.0 — 2026-07-22

- Add a narrow `trigger_attrs` seam to Tooltip for `aria-label`, `phx-click`, `phx-target`, and `phx-value-*` attributes while preserving component ownership of identity, button semantics, and descriptive ARIA state.
- Add real-application guidance for cross-browser Tooltip positioning and eagerly rendered Dialog content.

## 0.1.0 — 2026-07-22

- Add the first vertical slice: an unstyled, action-only, patch-safe LiveView Menu.
- Add the second vertical slice: unstyled, horizontal, manual-activation, patch-safe Tabs.
- Add the third vertical slice: an unstyled, native-modal, patch-safe Dialog.
- Add the fourth vertical slice: an unstyled, descriptive, patch-safe Tooltip.
- Add the fifth vertical slice: an unstyled, server-authoritative, patch-safe Accordion.
- Add the sixth vertical slice: an unstyled, native, patch-safe Radio Group.
