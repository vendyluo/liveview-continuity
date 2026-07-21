# Menu interaction contract

`LiveViewContinuity.Menu.menu/1` is a single-level, action-only menu. Its observable contract is deliberately smaller than a general menu system.

## Public inputs

- Required stable `id`.
- Required `on_action`, the one LiveView event receiving `%{"id" => logical_item_id}`.
- One required named `trigger` slot.
- One or more named `item` slots with required stable `id`; optional `disabled`, `class`, `typeahead_text`, and `close_on_action` values.
- Consumer class and global attributes on the root.

## DOM and state

The trigger is a native button with `aria-haspopup="menu"`, `aria-controls`, and reflected `aria-expanded`. The native popover has `role="menu"` and an `aria-labelledby` backlink. Every item is a native button with `role="menuitem"`, a scoped stable DOM ID, a logical ID, `aria-disabled`, and roving `tabindex`.

The hook always re-queries the live DOM. It does not retain item arrays across patches. A logical active ID is rebound after each update. The browser-owned attributes protected from server patches are narrowly enumerated; LiveView continues to own and patch the subtree.

## Keyboard, action, and dismissal invariants

Opening focus, wrapping arrows, Home/End, disabled-item discoverability, typeahead, Escape, normal action, outside dismissal, and Tab behavior follow the list in the README. Enter, Space, and click share one activation path. The disabled guard precedes dispatch, so disabled items dispatch zero actions. An enabled activation invokes `pushEvent` once. Normal actions then close and restore trigger focus.

The typeahead buffer resets 500 ms after the latest printable key and whenever the menu closes. Matching compares a prefix of `typeahead_text` or text content with a base-sensitive `Intl.Collator`. No match changes nothing.

When a patch retains the logical active item, the existing keyed DOM node and actual focus are rebound to it. If the item disappears, the first remaining item receives focus. If no item remains, the menu closes and trigger focus is restored.

Native outside light dismiss never invokes focus restoration. Tab closes without `preventDefault`, preserving normal sequential navigation.

## Styling hooks

- `data-lvc-menu`
- `data-lvc-open="true|false"`
- `data-lvc-dismiss-reason="escape|action|outside|trigger|tab|empty"`
- `data-lvc-item`
- `data-lvc-logical-id`
- `data-lvc-active`

These are the stable styling and test hooks. Other hook implementation details are not public API.
