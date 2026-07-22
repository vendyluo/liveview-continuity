# Menu interaction contract

`LiveViewContinuity.Menu.menu/1` is a single-level action and LiveView navigation menu. Its observable contract is deliberately smaller than a general menu system.

## Public inputs

- Required stable `id`.
- Required `on_action`, the one LiveView event receiving `%{"id" => logical_item_id}`.
- One required named `trigger` slot.
- One or more named `item` slots with required stable `id`; optional `disabled`, `class`, `typeahead_text`, `close_on_action`, and `navigate` values. A nonempty `navigate` path creates a navigation item; `close_on_action={false}` is invalid on it.
- Consumer class and global attributes on the root.

## DOM and state

The trigger is a native button with `aria-haspopup="menu"`, `aria-controls`, and reflected `aria-expanded`. The native popover has `role="menu"` and an `aria-labelledby` backlink. Action items are native buttons; navigation items are Phoenix `<.link navigate={...}>` anchors. Every item has `role="menuitem"`, a scoped stable DOM ID, a logical ID, `aria-disabled`, and roving `tabindex`.

The hook always re-queries the live DOM. It does not retain item arrays across patches. A logical active ID is rebound after each update. The browser-owned attributes protected from server patches are narrowly enumerated; LiveView continues to own and patch the subtree.

## Keyboard, action, and dismissal invariants

Opening focus, wrapping arrows, Home/End, disabled-item discoverability, typeahead, Escape, normal action, outside dismissal, and Tab behavior follow the list in the README. Action buttons send exactly one `on_action` event from Enter, Space, or click, then normal actions close and restore trigger focus. Navigation items never send `on_action`: click and native Enter retain Phoenix link behavior, while Space synthesizes one unmodified click without scrolling. Ordinary same-page navigation closes without restoring focus so the destination owns focus; modified link activation closes and restores the trigger on the retained source page. Disabled navigation items remain anchors for role semantics but omit `href` and LiveView link attributes, preventing primary, auxiliary, and browser-context navigation while leaving the menu open and focus in place.

Navigation intentionally supports only LiveView `navigate` paths in this slice. External `href`, `patch`, `target`, download behavior, and arbitrary item attributes remain outside the contract. Middle-click on an enabled navigation item keeps its native behavior and is not intercepted merely to close the menu.

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
