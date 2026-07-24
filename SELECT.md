# Select contract

`LiveViewContinuity.Select.select/1` is an unstyled custom single-select. LiveView owns the authoritative string-or-nil value, fixed options, content, and flags. The retained hook owns the open manual popover, active option, focus, typeahead buffer, and short-lived optimistic value.

## API and semantics

`id`, `name`, `value`, unique `on_change`, a non-blank `label`, and options with unique non-blank string values are required. Options may be disabled. The component supports a placeholder, `required`, `disabled`, synthetic focusable `read_only`, `invalid`, external `form`, root/trigger/popup/option/native/label/description/error classes, one description, one error, and global root attributes including `phx-target`.

The button trigger uses the supported select-only combobox model (`role="combobox"`) and exposes required, read-only, invalid, `aria-haspopup="listbox"`, expanded state, and controls. The always-mounted manual popover contains options with selected and disabled state. One intrinsically visually hidden, `aria-hidden` native select is the sole form control and owns name, validation, FormData, reset/defaultValue, disabled, required, and external form association. Its invalid event suppresses the inaccessible native popup, reflects invalid state, and focuses the visible trigger. Selection sends exactly `%{"value" => value}` through `pushEventTo` to the root owner.

## Interaction and continuity

Click, Enter, Space, and vertical arrows open; Arrow/Home/End move over enabled options. Buffered prefix typeahead follows Menu's 500 ms and base-sensitivity behavior. Enter, Space, or click selects. Escape closes and restores trigger focus; Tab closes without trapping. Read-only remains focusable but cannot select; disabled cannot open.

Selection reflects optimistically in the custom and native controls. Authoritative patches reconcile pending values, including stale/ABA patches. As with Checkbox and Switch, a pending intent is authoritatively rejected only when a patch marks the control read-only/disabled or removes that pending option. A general silent/no-op rejection is indistinguishable from a stale baseline patch without a new acknowledgment protocol and is explicitly out of scope; Select does not add callback acknowledgements. Retained patches preserve popup, logical active option, focus, and trigger/listbox/option identity; option values identify options across reorder. Multi-select, filtering, creation, groups, virtualization, a public Listbox, custom hidden inputs, and a shared state kernel are out of scope.
