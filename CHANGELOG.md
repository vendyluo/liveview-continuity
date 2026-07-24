# Changelog

## 0.10.0 — 2026-07-24

- Add a standalone custom Select with a native form bridge, accessible listbox interaction, optimistic server-authoritative value, and patch-safe identity, focus, and open state.
- Owner-target all remaining colocated-hook server events for Accordion, Menu, Radio Group, Tabs, and Dialog without changing event names or payloads.

## 0.9.0 — 2026-07-23

- Add native Checkbox with server-authoritative state, optimistic exact-boolean intent, native forms and reset, synthetic read-only, and retained focus and identity through stale/ABA patches.
- Owner-target Checkbox and Switch events with `pushEventTo`, including nested LiveComponent delivery.

## 0.8.0 — 2026-07-23

- Add a native, server-authoritative Switch with optimistic checked state and exact boolean intent across rapid interaction and stale LiveView patches.
- Support structured native-label content, FormData, native and external-form reset, read-only and disabled states, and retained focus and identity.

## 0.7.0 — 2026-07-23

- Let Radio Group options render structured native-label content, such as text with a dynamic count badge, while preserving the existing concise `label` attribute API.

## 0.6.0 — 2026-07-23

- Add a native auto Popover whose browser-owned open state, ARIA reflection, focus behavior, and interactive patchable body survive retained LiveView patches.
- Keep one Escape press scoped to the open Popover so it does not also dismiss a containing window-level surface.

## 0.5.0 — 2026-07-23

- Add a standalone, browser-owned Disclosure that preserves expanded state and synchronized ARIA/visibility attributes across retained LiveView patches.

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
