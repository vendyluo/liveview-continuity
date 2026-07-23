# Switch contract

`LiveViewContinuity.Switch.switch/1` is an unstyled native checkbox exposed with `role="switch"`. The browser owns focus, label activation, keyboard activation, form participation, and short-lived optimistic checked state. LiveView owns the authoritative `checked` value, content, and flags.

## API and ownership

`id`, `name`, authoritative `checked`, and `on_change` are required. Supply either a non-blank `label` attribute or one structured inner-content block; structured content remains inside the native `<label>`. The component also accepts `value` (default `"true"`), `required`, `disabled`, `read_only`, `invalid`, external `form`, style classes, global root attributes, and at most one `description` and `error` slot.

A native change is reflected immediately and sends exactly `%{"checked" => boolean}`. This is desired state, not a toggle command: the handler validates the boolean and acknowledges it by assigning `checked`. Exact intent makes retries and rapid `false → true` input unambiguous. A pending latest intent survives stale patches until the server acknowledges that value; server rejection and timeout policy are deferred.

The input ID is `ROOT-input`, its label is `ROOT-label`, and optional description and error IDs are `ROOT-description` and `ROOT-error`. The description is always referenced when present; the error is referenced only while invalid and may remain mounted but hidden otherwise.

## Forms, reset, and patches

The real checkbox carries `name`, `value`, optional `form`, `required`, and `disabled`, so checked state participates directly in `FormData` and native constraint validation. HTML checkboxes have no readonly state: `read_only` capture-cancels activation while leaving the input focusable and preserving its successful-control behavior.

The hook records the SSR `defaultChecked` value and binds the input's actual owner form. Native reset restores that default and sends an exact intent only when logical state changes. A read-only switch temporarily aligns the reset default with its current state without cancelling the form reset, then restores the original default; unrelated controls therefore reset normally. Disabled switches keep native reset behavior but remain excluded from `FormData`.

Retained patches preserve input identity and focused state. `data-lvc-checked` exposes effective browser state for styling and LIC attribute probes; `data-lvc-desired-checked` remains server-owned. Only the effective `checked` property and reflection are narrowly protected from patch overwrite, so label, description, errors, and other descendants remain server-patchable.

## Evidence and limits

The three-engine Playwright suite covers pointer and keyboard activation, structured labels, exact and rapid intent, stale patches, focus and identity, FormData, native reset, external form ownership, read-only behavior, disabled behavior, and server-driven state. The LIC contract covers retained identity, effective checked reflection, and focus around an acknowledged patch.

Custom indicators, hidden inputs, tri-state semantics, field wrappers, arbitrary validation UI, rejection UX, animation, and a shared toggle state machine are intentionally deferred.
