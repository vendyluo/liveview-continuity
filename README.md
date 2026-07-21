# LiveView Continuity

LiveView Continuity is an experimental collection of unstyled, accessible interaction primitives for Phoenix LiveView.

**Contract-backed, patch-safe interaction primitives for Phoenix LiveView.** Components are verified with Live Interaction Contracts and application-specific real-browser conformance tests.

This independent community project explores a narrow ownership model: LiveView keeps authority over application data and rendered content while the browser keeps short-lived interaction state. It originated as an experiment in making that boundary explicit and executable, rather than as a general component library.

## Installation

Use a path dependency while the project is experimental:

```elixir
{:liveview_continuity, path: "../liveview-continuity"}
```

The package requires Elixir 1.18 or newer, Phoenix 1.8 or newer, and Phoenix LiveView 1.1 or newer. Phoenix 1.8 is required by colocated hooks. Add the LiveView compiler to the consuming project:

```elixir
compilers: [:phoenix_live_view] ++ Mix.compilers()
```

After `mix compile`, import the extracted colocated hook in the application's JavaScript bundle:

```javascript
import {hooks as continuityHooks} from "phoenix-colocated/liveview_continuity";

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: {...continuityHooks}
});
```

## Menu

```heex
<.menu id="account-actions" on_action="account_action" class="account-menu">
  <:trigger class="account-menu-trigger">Actions</:trigger>
  <:item id="edit" class="account-menu-item">Edit</:item>
  <:item id="archive" typeahead_text="Archive">Archive account</:item>
  <:item id="delete" disabled={@cannot_delete}>Delete</:item>
</.menu>
```

Handle the single server event in the containing LiveView:

```elixir
def handle_event("account_action", %{"id" => id}, socket) do
  # authorize and perform the named action
  {:noreply, socket}
end
```

`id` is required and stable. Item IDs are logical IDs and become stable DOM IDs scoped by the menu. `typeahead_text` is optional; otherwise visible text content is used. `close_on_action={false}` is a narrow escape hatch for an action whose acknowledged patch must remain inside the open menu. Normal actions close by default.

### Ownership

| Owner | State |
| --- | --- |
| LiveView | item content, order, disabled state, action outcome |
| Native popover | top-layer open state and light dismiss |
| Menu hook | open reflection, actual focus, active item, roving `tabindex`, typeahead buffer, dismissal reason, focus restoration |

Client-owned reflections use stable `data-lvc-*` styling hooks. Only trigger `aria-expanded`, `data-lvc-open`, `data-lvc-dismiss-reason`, `data-lvc-active`, and item `tabindex` are protected with LiveView's narrow `JS.ignore_attributes/1` mechanism. Descendants remain server-patchable.

### Supported behavior

- Pointer, Enter, Space, and ArrowDown open to the first item; ArrowUp opens to the last.
- Arrow keys wrap, with Home and End navigation.
- Disabled items remain focusable and announced, but never dispatch an action.
- Typeahead uses a 500 ms reset window, multi-character prefixes, and `Intl.Collator` with base sensitivity for practical case/accent-insensitive matching. Ctrl, Meta, and Alt combinations do not match.
- Escape and successful normal actions close and restore trigger focus.
- Outside pointer dismissal does not restore focus over the outside target.
- Tab and Shift+Tab close without trapping focus or preventing normal movement.
- Acknowledged patches preserve logical active focus across content changes and reorder. Active removal falls back to the first item; an empty menu closes and restores the trigger.

See [MENU.md](MENU.md) for the observable contract.

## Non-scope

The first slice intentionally excludes selection, check/radio items, submenus, portals, detached or multiple triggers, and a positioning engine. It also excludes a generic state machine, arbitrary JavaScript assertion API, component generator, CSS framework, and design tokens.

## Verification

Install and build:

```sh
mix deps.get
npm install
mix compile
NODE_PATH="$PWD/deps:$PWD/_build/dev" npx esbuild fixture/assets/js/app.js \
  --bundle --target=es2022 --outfile=fixture/priv/static/assets/app.js
mix run fixture/server.exs
```

In another shell, run the app-specific three-engine gate and the published LIC 1.3 runner:

```sh
npm run test:browser
mix live_interaction_contracts.check \
  --url http://127.0.0.1:4140 \
  --contract test/interaction_contracts/menu_patch.json
```

Also run `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test`, `node --check playwright/conformance.mjs`, `test/package-smoke.sh`, `mix hex.build`, and `mix docs`. The fixture uses loopback port 4140 and the shipped component plus its compiler-extracted colocated hook. The package smoke unpacks the Hex artifact into a fresh consumer, compiles it, and bundles the extracted hook through esbuild.

The LIC v1 contract honestly checks popup node identity and native popover state across an acknowledged in-menu patch. Rich menu semantics stay in the application-specific Playwright driver because LIC 1.3 has no arbitrary menu assertion surface. An intentionally broken red fixture is not included in this slice; capturing a checked-in red-path proof is a release blocker before any Hex publication and a candidate for a future LIC 1.4 evidence workflow.

## Inspiration and status

Behavioral rigor and composition are inspired by React Aria and Base UI. LiveView Continuity is not API-compatible with either project, and it does not copy a React lifecycle model. This is an independent community project, not affiliated with Phoenix, React Aria, Base UI, or the Live Interaction Contracts project.

Released under the MIT License.
