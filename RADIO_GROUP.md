# Radio Group contract

`LiveViewContinuity.RadioGroup.radio_group/1` is an unstyled native radio group. It renders a `fieldset`, visible `legend`, associated labels, and real focusable `input[type=radio]` controls. Browsers own label activation, Space, same-name exclusivity, focus, constraint validation, and form submission. Chromium and Firefox wrap native arrow navigation but WebKit does not, so the local hook normalizes Right/Down to the next enabled input and Left/Up to the previous enabled input, wrapping in DOM order. No `role=radio`, hidden proxy, orientation abstraction, Home/End handling, or indicator is added.

## API and ownership

`id`, `name`, authoritative `value` (`nil` or an option value), `on_change`, `label`, and at least one `option` are required. Options require a stable `value` and either a non-blank `label` attribute or visible inner content; inner content supports structured labels such as text with a count badge while remaining inside the native `<label>`. When both are supplied, the `label` attribute takes precedence. Options also accept `disabled`, `class`, `input_class`, and `label_class`. The root accepts `required`, `disabled`, `read_only`, `invalid`, external `form`, global/root attributes, and legend/description/error classes. At most one `description` and one `error` slot may be supplied.

The server owns options, content, flags, and desired value. A native `change` optimistically reflects selection and sends exactly `%{value: selected_string}`. The handler must validate and acknowledge the latest payload by assigning that value. Pending selection survives older patches; acknowledgment clears it, and removal of the pending option falls back to current server intent. Server rejection and timeout policy are deferred.

The legend is `ROOT-legend`; option inputs are `ROOT-option-VALUE`; optional description and error IDs are `ROOT-description` and `ROOT-error`. Group and inputs reference the description and reference the error only while invalid. An error may stay mounted and hidden otherwise.

## Forms, reset, and patches

Every input carries the native `name`, `value`, optional `form`, `required`, and effective disabled state. A selected disabled option is valid authoritative state. `read_only` is implemented by capture-cancelling radio activation because HTML radios have no native readonly state: controls stay focusable and the selected control remains a successful form control. Disabled controls remain native: form reset may reset them and emit an acknowledgment intent even though they are excluded from `FormData`.

The hook binds the actual owner form and records each option's initial SSR `defaultChecked`. LiveView's radio synchronization may still rewrite checked attributes despite narrow ignore instructions, so the hook restores those per-value defaults after every patch while changing only effective `.checked` state. During a reset event, the hook derives the target from that recorded baseline and establishes the reset intent before any network patch can interleave; the browser's native default action then applies the same value. A read-only group temporarily aligns its radio defaults with its current value instead of cancelling the form-level reset, so unrelated controls still reset normally without emitting a radio intent. Autofill synchronization is not claimed in this slice.

Retained options preserve native input identity, selection, and logical focus through content patches and reorder. Focus is restored only if a DOM move dropped focus; removed focused options get no fallback, and outside focus is untouched.

One component root must own the complete native group for a given tree root, form owner, and `name`. Reusing the same `name` in the same form outside that component joins the browser's native group and is unsupported. Nested Radio Group hooks isolate their own descendants, but nested groups must use a different name or form owner.

## Evidence and limits

`data-lvc-checked`, root `data-lvc-value`, and `data-lvc-has-value` expose browser-owned reflections for styling and LIC attribute probes. `data-lvc-desired-*` remains server-owned. LIC v1 cannot inspect the checked property, FormData, native validity, event count, or keyboard behavior; the three-engine Playwright suite covers those. Generic field wrappers, custom indicators, arbitrary validation UI, rejection UX, and autofill are deferred.
