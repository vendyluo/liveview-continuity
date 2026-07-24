defmodule LiveViewContinuity.Accordion do
  @moduledoc """
  An unstyled accordion with server-authoritative values and immediate, patch-safe disclosure state.

  See `ACCORDION.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:values, :list, required: true)
  attr(:on_change, :string, required: true)
  attr(:multiple, :boolean, default: false)
  attr(:heading_level, :integer, default: 3)
  attr(:region, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :item, required: true do
    attr(:id, :string, required: true)
    attr(:label, :string, required: true)
    attr(:disabled, :boolean)
    attr(:item_class, :any)
    attr(:header_class, :any)
    attr(:trigger_class, :any)
    attr(:panel_class, :any)
  end

  def accordion(assigns) do
    validate!(assigns)

    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Accordion"
      phx-mounted={JS.ignore_attributes("data-lvc-values")}
      data-lvc-accordion
      data-lvc-action={@on_change}
      data-lvc-multiple={to_string(@multiple)}
      data-lvc-values={inspect(@values)}
      {@rest}
    >
      <div
        :for={item <- @item}
        :key={item.id}
        class={item[:item_class]}
        data-lvc-accordion-item
        data-lvc-logical-id={item.id}
        data-lvc-desired-open={to_string(item.id in @values)}
        data-lvc-open={to_string(item.id in @values)}
        phx-mounted={JS.ignore_attributes("data-lvc-open")}
      >
        <.dynamic_tag tag_name={"h#{@heading_level}"} class={item[:header_class]}>
          <button
            id={trigger_id(@id, item.id)}
            type="button"
            class={item[:trigger_class]}
            aria-expanded={to_string(item.id in @values)}
            aria-controls={panel_id(@id, item.id)}
            aria-disabled={to_string(item[:disabled] || false)}
            data-lvc-accordion-trigger
            data-lvc-logical-id={item.id}
            phx-mounted={JS.ignore_attributes("aria-expanded")}
          >{item.label}</button>
        </.dynamic_tag>
        <div
          id={panel_id(@id, item.id)}
          class={item[:panel_class]}
          role={if @region, do: "region"}
          aria-labelledby={trigger_id(@id, item.id)}
          aria-hidden={to_string(item.id not in @values)}
          hidden={item.id not in @values}
          data-lvc-accordion-panel
          data-lvc-logical-id={item.id}
          phx-mounted={JS.ignore_attributes(["hidden", "aria-hidden"])}
        >
          {render_slot(item)}
        </div>
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Accordion">
        const ROOT = "[data-lvc-accordion]";
        const ITEM = "[data-lvc-accordion-item]";
        const sameSet = (a, b) => a.length === b.length && a.every(value => b.includes(value));

        export default {
          mounted() {
            this.pending = null;
            this.onClick = event => this.click(event);
            this.el.addEventListener("click", this.onClick);
            this.reflect(this.effective());
          },
          beforeUpdate() {
            const panel = document.activeElement?.closest?.("[data-lvc-accordion-panel]");
            const trigger = document.activeElement?.closest?.("[data-lvc-accordion-trigger]");
            this.focusedPanelId = panel?.closest(ROOT) === this.el ? panel.dataset.lvcLogicalId : null;
            this.focusedTriggerId = trigger?.closest(ROOT) === this.el ? trigger.dataset.lvcLogicalId : null;
          },
          updated() {
            const existing = this.ids();
            const desired = this.desired().filter(id => existing.includes(id));
            if (this.pending) {
              this.pending = this.pending.filter(id => existing.includes(id));
              if (sameSet(this.pending, desired)) this.pending = null;
            }
            const effective = this.pending || desired;
            if (this.focusedPanelId && !effective.includes(this.focusedPanelId)) {
              this.trigger(this.focusedPanelId)?.focus();
            } else if (this.focusedTriggerId) {
              this.trigger(this.focusedTriggerId)?.focus();
            }
            this.reflect(effective);
            this.focusedPanelId = null;
            this.focusedTriggerId = null;
          },
          destroyed() { this.el.removeEventListener("click", this.onClick); },
          items() { return [...this.el.querySelectorAll(ITEM)].filter(item => item.closest(ROOT) === this.el); },
          ids() { return this.items().map(item => item.dataset.lvcLogicalId); },
          desired() { return this.items().filter(item => item.dataset.lvcDesiredOpen === "true").map(item => item.dataset.lvcLogicalId); },
          effective() { return this.items().filter(item => item.dataset.lvcOpen === "true").map(item => item.dataset.lvcLogicalId); },
          trigger(id) { return this.items().find(item => item.dataset.lvcLogicalId === id)?.querySelector("[data-lvc-accordion-trigger]"); },
          panel(id) { return this.items().find(item => item.dataset.lvcLogicalId === id)?.querySelector("[data-lvc-accordion-panel]"); },
          click(event) {
            const trigger = event.target.closest("[data-lvc-accordion-trigger]");
            if (!trigger || trigger.closest(ROOT) !== this.el || trigger.getAttribute("aria-disabled") === "true") return;
            const id = trigger.dataset.lvcLogicalId;
            const current = this.effective();
            const wasOpen = current.includes(id);
            let values;
            if (this.el.dataset.lvcMultiple === "true") values = wasOpen ? current.filter(value => value !== id) : [...current, id];
            else values = wasOpen ? [] : [id];
            values = this.ids().filter(value => values.includes(value));
            this.pending = values;
            this.reflect(values);
            this.pushEventTo(this.el, this.el.dataset.lvcAction, {id, open: !wasOpen, values});
          },
          reflect(values) {
            this.el.dataset.lvcValues = JSON.stringify(values);
            this.items().forEach(item => {
              const open = values.includes(item.dataset.lvcLogicalId);
              item.dataset.lvcOpen = String(open);
              const trigger = item.querySelector("[data-lvc-accordion-trigger]");
              const panel = item.querySelector("[data-lvc-accordion-panel]");
              trigger?.setAttribute("aria-expanded", String(open));
              if (panel) {
                panel.hidden = !open;
                panel.setAttribute("aria-hidden", String(!open));
              }
            });
          }
        };
      </script>
    </div>
    """
  end

  defp validate!(assigns) do
    validate_id!(assigns.id, "accordion id")
    if assigns.item == [], do: raise(ArgumentError, "accordion requires at least one item")
    ids = Enum.map(assigns.item, & &1.id)
    Enum.each(ids, &validate_id!(&1, "logical accordion item id"))
    Enum.each(assigns.values, &validate_id!(&1, "accordion value"))

    if length(ids) != length(Enum.uniq(ids)),
      do: raise(ArgumentError, "accordion requires unique item IDs")

    if length(assigns.values) != length(Enum.uniq(assigns.values)),
      do: raise(ArgumentError, "accordion values must be unique")

    if Enum.any?(assigns.values, &(&1 not in ids)),
      do: raise(ArgumentError, "accordion values must identify existing items")

    if !assigns.multiple and length(assigns.values) > 1,
      do: raise(ArgumentError, "single accordion allows at most one value")

    if assigns.heading_level not in 1..6,
      do: raise(ArgumentError, "accordion heading_level must be between 1 and 6")

    if Enum.any?(assigns.item, &(not is_binary(&1.label) or String.trim(&1.label) == "")),
      do: raise(ArgumentError, "accordion item labels must be non-blank strings")
  end

  defp validate_id!(value, name) when is_binary(value) do
    if value == "" or String.contains?(value, <<0>>) or Regex.match?(~r/[\t\n\f\r ]/, value),
      do:
        raise(ArgumentError, "#{name} must be a non-empty string without ASCII whitespace or NUL")
  end

  defp validate_id!(_, name), do: raise(ArgumentError, "#{name} must be a string")
  defp trigger_id(root, logical), do: root <> "-trigger-" <> logical
  defp panel_id(root, logical), do: root <> "-panel-" <> logical
end
