# Tabs interaction contract

`LiveViewContinuity.Tabs.tabs/1` provides horizontal tabs with manual activation. The server owns selection and panel visibility. The browser owns immediate focus, the focus cursor, and tab `tabindex`.

## API and DOM

Pass a stable root `id`, selected logical string `value`, `on_select` event, and the tab list's accessible `label`. Each `tab` slot requires stable `id` and display `label`, and accepts `disabled`, `tab_class`, and `panel_class`. Empty, all-disabled, duplicate-ID, missing-selection, and disabled-selection compositions raise `ArgumentError`.

`tabs/1` is the compact API when tab triggers and panel contents naturally live together. `tab_list/1` and `tab_panel/1` expose the same DOM and interaction contract for large LiveViews whose panels must remain in their existing layout. Every list tab must have exactly one matching external panel, with no extra or duplicate panels. Each panel uses the list's stable `root_id`, matching logical `id`, and an `active` value equal to whether the list `value` selects that ID. This cross-component bijection is the caller's responsibility.

The root exposes `data-lvc-tabs` and `data-orientation="horizontal"`. Tabs and panels expose stable scoped DOM IDs, reciprocal `aria-controls` and `aria-labelledby`, and `data-lvc-logical-id`. All panels remain mounted. Inactive panels have `hidden`, `inert`, and `data-lvc-hidden`; the active panel has `tabindex="0"`.

## Interaction and patches

Left and Right wrap among enabled tabs. Home and End focus the first and last enabled tabs. These keys never select. Enter, Space, and pointer click each push exactly one `%{"id" => logical_id}` selection event. Up, Down, and Tab retain browser behavior. Disabled tabs use `aria-disabled`, are skipped by sequential and component keyboard navigation, do not receive pointer focus, cannot activate, and are never selected.

After a patch, a surviving logical focused tab retains focus through reorder and rename. If it is removed or disabled, the enabled tab at its old index receives focus, or the previous last enabled tab when no enabled tab follows. If focus is outside, selection becomes the unique tabstop without stealing focus. Selection fallback is application-owned.

Only client-owned tab `tabindex` and `data-lvc-focused` are ignored during patches. Server-owned ARIA selection, disabled state, panels, visibility, and content remain patchable.
