# Checkbox contract

`LiveViewContinuity.Checkbox.checkbox/1` renders a native `input[type=checkbox]` without a role override. LiveView owns authoritative `checked`, content, and flags; the browser owns focus, native label/keyboard activation, form behavior, and short-lived optimistic state.

## API and ownership

`id`, `name`, `checked`, and unique `on_change` are required. Supply either a non-blank `label` or one structured label block. `value` defaults to `"true"`; `required`, `disabled`, synthetic `read_only`, `invalid`, external `form`, styling attributes, and one description and error are supported. Description is always referenced; error is referenced only when invalid.

Each native change immediately sends exactly `%{"checked" => boolean}` with `pushEventTo` targeting the component owner represented by the stable root. The event name and owner—not extra payload—identify the logical target. The server acknowledges by assigning `checked`. The latest queued intent survives stale and ABA patches without callback acknowledgement.

## Native forms and continuity

The real checkbox owns `name`, `value`, `required`, `disabled`, and optional external form association, so native validation and `FormData` work normally. Since checkboxes have no readonly attribute, `read_only` intercepts activation, remains focusable, and alone emits `aria-readonly="true"`. Native reset restores the SSR default and emits an exact intent only if logical state changes; cancelable reset, read-only reset, unrelated controls, and replaced external owner forms retain native behavior.

Retained patches preserve node identity, focus, optimistic checked state, and `data-lvc-checked`; `data-lvc-desired-checked` remains server-owned. Server-driven state wins when no intent is pending. Custom indicators, tri-state behavior, hidden inputs, rejection policy, callback acknowledgements, and a shared Checkbox/Switch state machine are out of scope.
