# Popover interaction contract

`LiveViewContinuity.Popover.popover/1` renders one generated native button and one always-mounted `popover="auto"` body. A stable `id`, exactly one rich `trigger` slot, and exactly one body are required. `class`, `trigger_class`, and `popup_class` style the three surfaces; global attributes apply to the root.

The IDs are `<id>`, `<id>-trigger`, and `<id>-popup`. `aria-controls` and `aria-labelledby` form the stable graph. The trigger uses native button and Popover invoker behavior, so click, Enter, and Space open it; native light dismiss and Escape close it. An Escape belonging to the open popover does not continue to ancestor window-level dismiss handlers, so one key press does not also close a containing surface; a body control may still cancel the key before it reaches that boundary. The hook reflects effective state as root `data-lvc-open="true|false"` and a literal trigger `aria-expanded="true|false"`. Only those two browser-owned attributes are protected from patches.

LiveView owns body content while the browser owns transient open state. If root, trigger, and popup nodes are retained, acknowledged patches preserve node identity and native open state while patching descendants; browser focus therefore remains on a retained focused descendant. If the trigger or popup is replaced, the safe behavior is closed state rather than transferring state to a different native surface. Native focus behavior remains authoritative; the hook repairs focus to the trigger only when Escape or an explicit close leaves focus stranded in the now-closed popup.

Clicking a popup-body descendant with `data-lvc-popover-close` closes immediately. The hook does not prevent propagation or remove the descendant's own `phx-click`, so its LiveView action still runs and may patch the body. Light dismiss never repairs focus over the outside target.

Popover supplies no content role or composite-widget keyboard model. Consumers remain responsible for the body's semantic role, accessible name, and interaction semantics. This component depends on the native HTML Popover API and intentionally ships no fallback or polyfill for browsers that do not support it.

There is no server open/close event or controlled state. Positioning, modal and hover modes, nested behavior, callbacks, portals, animations, arbitrary trigger attributes, and a shared overlay abstraction are outside this slice.
