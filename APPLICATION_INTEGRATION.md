# Application integration

LiveView Continuity owns interaction state, native element state, patch reconciliation, and the ARIA reflections documented by each component contract. Applications continue to own product styling, layout, data loading, and server event outcomes. The practices below are integration recipes, not additional component guarantees.

## Tooltip positioning

Tooltip deliberately ships without a positioning engine. The consumer must style tooltip content with `pointer-events: none` and place the manual popover beside its trigger.

CSS Anchor Positioning can be a useful progressive enhancement, but an application that requires identical behavior in Chromium, Firefox, and WebKit should verify the exact browser versions it supports rather than treating CSS anchors as an unconditional baseline. A geometry adapter is an application-owned alternative. A complete adapter should:

1. Wait until the popover is open before measuring the trigger and popup bounding boxes.
2. Place the popup relative to those measured boxes, clamp it within the viewport, and flip it when the preferred side lacks room.
3. Recalculate while an open tooltip is affected by scrolling, viewport resizing, or an acknowledged LiveView patch.
4. Remove any application-level listeners when their owning surface is destroyed.

The adapter must not take ownership of `data-lvc-open`, Popover state, Tooltip timers, or `aria-describedby`. Those remain part of the component contract. Portals, arrows, safe polygons, collision middleware, and a general overlay manager remain outside the package scope.

## Dialog first paint

Dialog opens synchronously in the browser and then sends `on_open` for server acknowledgment. Content fetched or constructed only by that event cannot be present for the first modal paint.

Render forms and other immediately required content before the trigger can be used. If the data cannot be prepared eagerly, render an explicit, accessible loading state inside the permanently mounted Dialog and replace it through the acknowledged patch. Do not assume the server response will arrive before `showModal()`.

Dialog currently closes through Escape or its explicit Close control. It intentionally does not interpret backdrop coordinates as light dismiss. Use it where explicit dismissal is suitable—such as an edit form where accidental closure could discard input—and retain another product pattern where backdrop dismissal is required.
