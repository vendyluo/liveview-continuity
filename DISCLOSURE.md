# Disclosure interaction contract

`LiveViewContinuity.Disclosure.disclosure/1` is an unstyled standalone disclosure whose effective expanded state is owned by the browser. Required inputs are a stable `id`, exactly one rich trigger slot, and exactly one always-mounted panel body. `default_expanded` defaults to `false` and only seeds SSR or a newly mounted instance. Root, trigger, and panel classes are consumer-owned; global attributes apply to the root.

The trigger is a native `button type="button"` with stable `aria-controls` and browser-reflected `aria-expanded`. The panel has a stable `aria-labelledby` backlink and browser-reflected `hidden` and `aria-hidden`. Pointer, Enter, and Space use native button activation. Each activation changes the effective state immediately without sending a LiveView event or waiting for server acknowledgment.

LiveView owns the trigger and panel content and may patch either subtree. The browser owns root `data-lvc-open`, trigger `aria-expanded`, and panel `hidden`/`aria-hidden`; only those attributes are ignored narrowly. A retained-root patch therefore preserves effective expanded state even when the server continues to render the original `default_expanded`, while panel content remains patchable. A newly mounted root starts from the current server-rendered default.

`data-lvc-open="true|false"` is the stable styling and test hook. Consumers should derive indicator rotation or other visual changes from it rather than maintaining another state copy.

Disclosure is intentionally distinct from `LiveViewContinuity.Accordion`: Disclosure is one browser-owned boolean with no event, while Accordion coordinates server-authoritative logical values and acknowledgment. Controlled expanded state, server callbacks, grouped disclosures, required-open behavior, heading wrappers, region landmarks, animations, conditional unmount, `hidden="until-found"`, detached or multiple triggers, and navigation-persistent state remain outside this contract. There is no shared Disclosure/Accordion state-machine abstraction in this slice.
