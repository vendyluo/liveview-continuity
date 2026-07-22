# Accordion

`LiveViewContinuity.Accordion.accordion/1` is an unstyled, always-mounted disclosure group. It renders native headings and buttons rather than `details`/`summary`.

## API

`id`, `values`, and `on_change` are required. `id` is the stable DOM scope. `values` is the authoritative list of expanded logical item IDs. `multiple` defaults to `false`; single mode permits all panels closed and at most one value. `heading_level` defaults to 3 and accepts 1 through 6. `region` defaults to false. `class` and global attributes apply to the root.

The required `item` slot requires a stable `id` and non-blank `label`. It accepts `disabled`, `item_class`, `header_class`, `trigger_class`, and `panel_class`; its body is panel content. IDs must be nonempty strings without ASCII whitespace or NUL. Items must be nonempty and unique, and values must be unique existing item IDs. An expanded disabled item is valid.

```heex
<.accordion id="billing-help" values={@expanded} on_change="accordion_change" region>
  <:item id="invoices" label="Invoices">Invoice help</:item>
  <:item id="refunds" label="Refunds" disabled={@refunds_unavailable}>Refund help</:item>
</.accordion>
```

The handler must acknowledge the latest request by assigning payload `values` after validating/authorizing its IDs:

```elixir
def handle_event("accordion_change", %{"id" => id, "open" => open, "values" => values}, socket) do
  {:noreply, assign(socket, :expanded, values)}
end
```

## Ownership and patches

LiveView owns item order/content/disabled state, `multiple`, and authoritative values. The browser owns the immediate effective expanded set and keeps only the latest pending desired set until the server values acknowledge it by set equality. Stale intermediate patches therefore cannot overwrite a newer rapid click. There is no timeout or rejection protocol in this slice.

Every patch re-derives server intent from each item's unprotected `data-lvc-desired-open`. Only trigger `aria-expanded`, panel `hidden`/`aria-hidden`, item `data-lvc-open`, and root `data-lvc-values` are ignored narrowly. SSR has the correct state before hook mount. Reorder, insertion, removal, and content patches reconcile by logical ID; retained keyed trigger focus is restored if a DOM move drops it. Removal prunes missing pending IDs and does not rescue a removed trigger. If a server close would hide the panel containing focus, focus moves to that panel's connected trigger; outside focus is never stolen.

## Keyboard and accessibility

Each heading contains only its native button. Native click behavior gives pointer, Enter, and Space one activation each. Disabled triggers remain focusable with `aria-disabled="true"` but are inert. Tab order remains ordinary. In line with the accordion APG's optional navigation, this slice does not implement Arrow, Home, End, or roving `tabindex` behavior.

Panels are always mounted and always have `aria-labelledby`; `role="region"` is opt-in to avoid excessive landmarks. Consumers own all styling. This slice intentionally defers animations, required-open behavior, unmounting, `until-found`, and generic Collapsible/Disclosure abstractions.

The acknowledged content-patch path is verified with Live Interaction Contracts using node identity, owned attribute, and the expected focus transition to the external patch control. Retained-trigger focus across script-triggered patches, plus rich rapid-intent, keyboard, and focus-rescue behavior, belongs to the real-browser conformance suite.
