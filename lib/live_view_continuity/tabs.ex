defmodule LiveViewContinuity.Tabs do
  @moduledoc """
  Horizontal, manual-activation tabs with patch-safe browser focus.

  See `TABS.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:value, :string, required: true)
  attr(:on_select, :string, required: true)
  attr(:label, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :tab, required: true do
    attr(:id, :string, required: true)
    attr(:label, :string, required: true)
    attr(:disabled, :boolean)
    attr(:tab_class, :any)
    attr(:panel_class, :any)
  end

  def tabs(assigns) do
    validate!(assigns.id, assigns.label, assigns.tab, assigns.value)

    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Tabs"
      data-lvc-tabs
      data-lvc-action={@on_select}
      data-orientation="horizontal"
      {@rest}
    >
      <div role="tablist" aria-label={@label} aria-orientation="horizontal">
        <button
          :for={tab <- @tab}
          :key={tab.id}
          id={tab_id(@id, tab.id)}
          type="button"
          role="tab"
          class={tab[:tab_class]}
          aria-selected={to_string(tab.id == @value)}
          aria-disabled={to_string(tab[:disabled] || false)}
          aria-controls={panel_id(@id, tab.id)}
          tabindex={if tab.id == @value, do: "0", else: "-1"}
          data-lvc-tab
          data-lvc-logical-id={tab.id}
          data-lvc-active={tab.id == @value}
          data-lvc-disabled={tab[:disabled] || nil}
          phx-mounted={JS.ignore_attributes(["tabindex", "data-lvc-focused"])}
        >
          {tab.label}
        </button>
      </div>
      <div
        :for={tab <- @tab}
        :key={tab.id}
        id={panel_id(@id, tab.id)}
        role="tabpanel"
        class={tab[:panel_class]}
        aria-labelledby={tab_id(@id, tab.id)}
        tabindex={if tab.id == @value, do: "0", else: nil}
        hidden={tab.id != @value}
        inert={tab.id != @value}
        data-lvc-panel
        data-lvc-logical-id={tab.id}
        data-lvc-hidden={tab.id != @value || nil}
      >
        {render_slot(tab)}
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Tabs">
        const TAB = "[data-lvc-tab]";

        export default {
          mounted() {
            this.focusedId = null;
            this.focusedIndex = null;
            this.onKey = event => this.key(event);
            this.onClick = event => this.click(event);
            this.onFocus = event => this.focus(event);
            this.onPointerDown = event => this.pointerDown(event);
            this.el.addEventListener("keydown", this.onKey);
            this.el.addEventListener("click", this.onClick);
            this.el.addEventListener("focusin", this.onFocus);
            this.el.addEventListener("pointerdown", this.onPointerDown);
            this.reconcile(false);
          },
          beforeUpdate() {
            this.hadFocus = this.list().contains(document.activeElement);
          },
          updated() { this.reconcile(true); },
          list() { return this.el.querySelector("[role=tablist]"); },
          tabs() { return [...this.el.querySelectorAll(TAB)]; },
          enabled() { return this.tabs().filter(tab => tab.getAttribute("aria-disabled") !== "true"); },
          focus(event) {
            const tab = event.target.closest(TAB);
            if (!tab || tab.getAttribute("aria-disabled") === "true") return;
            this.setCursor(tab, true);
          },
          key(event) {
            const tab = event.target.closest(TAB);
            if (!tab || tab.getAttribute("aria-disabled") === "true") return;
            const enabled = this.enabled();
            const current = enabled.indexOf(tab);
            let next;
            if (event.key === "ArrowRight") next = (current + 1) % enabled.length;
            else if (event.key === "ArrowLeft") next = (current - 1 + enabled.length) % enabled.length;
            else if (event.key === "Home") next = 0;
            else if (event.key === "End") next = enabled.length - 1;
            else if (event.key === "Enter" || event.key === " ") {
              event.preventDefault();
              return this.activate(tab);
            } else return;
            event.preventDefault();
            enabled[next]?.focus();
          },
          click(event) {
            const tab = event.target.closest(TAB);
            if (tab) this.activate(tab);
          },
          pointerDown(event) {
            const tab = event.target.closest(TAB);
            if (tab?.getAttribute("aria-disabled") === "true") event.preventDefault();
          },
          activate(tab) {
            if (tab.getAttribute("aria-disabled") === "true") return;
            this.pushEvent(this.el.dataset.lvcAction, {id: tab.dataset.lvcLogicalId});
          },
          setCursor(tab, focused) {
            const tabs = this.tabs();
            tabs.forEach(candidate => {
              candidate.tabIndex = candidate === tab ? 0 : -1;
              if (focused && candidate === tab) candidate.dataset.lvcFocused = "";
              else delete candidate.dataset.lvcFocused;
            });
            this.focusedId = tab.dataset.lvcLogicalId;
            this.focusedIndex = tabs.indexOf(tab);
          },
          reconcile(wasUpdated) {
            const tabs = this.tabs();
            const focusInside = this.list().contains(document.activeElement) || (wasUpdated && this.hadFocus);
            let cursor;
            if (focusInside && this.focusedId) {
              cursor = tabs.find(tab => tab.dataset.lvcLogicalId === this.focusedId && tab.getAttribute("aria-disabled") !== "true");
              if (!cursor && wasUpdated) {
                const enabled = this.enabled();
                cursor = tabs.slice(this.focusedIndex).find(tab => enabled.includes(tab)) || [...tabs.slice(0, this.focusedIndex)].reverse().find(tab => enabled.includes(tab));
              }
            }
            if (!cursor) cursor = tabs.find(tab => tab.getAttribute("aria-selected") === "true" && tab.getAttribute("aria-disabled") !== "true");
            if (!cursor) return;
            this.setCursor(cursor, focusInside);
            if (focusInside && document.activeElement !== cursor) cursor.focus();
            this.hadFocus = false;
          }
        };
      </script>
    </div>
    """
  end

  defp validate!(root_id, label, tabs, value) do
    validate_dom_id!(root_id, "tabs id")

    if String.trim(label) == "",
      do: raise(ArgumentError, "tabs label cannot be blank")

    validate_tabs!(tabs, value)
  end

  defp validate_tabs!([], _value), do: raise(ArgumentError, "tabs requires at least one tab")

  defp validate_tabs!(tabs, value) do
    ids = Enum.map(tabs, & &1.id)

    Enum.each(ids, &validate_dom_id!(&1, "logical tab id"))

    if Enum.any?(tabs, &(String.trim(&1.label) == "")),
      do: raise(ArgumentError, "tabs requires non-blank tab labels")

    if length(ids) != length(Enum.uniq(ids)),
      do: raise(ArgumentError, "tabs requires unique logical tab IDs")

    if Enum.all?(tabs, &(&1[:disabled] || false)),
      do: raise(ArgumentError, "tabs requires at least one enabled tab")

    selected = Enum.find(tabs, &(&1.id == value))

    if is_nil(selected),
      do: raise(ArgumentError, "tabs value must identify an existing tab, got: #{inspect(value)}")

    if selected[:disabled],
      do:
        raise(ArgumentError, "tabs value cannot identify a disabled tab, got: #{inspect(value)}")
  end

  defp validate_dom_id!(value, name) do
    if value == "" or String.contains?(value, <<0>>) or Regex.match?(~r/[\t\n\f\r ]/, value),
      do:
        raise(ArgumentError, "#{name} must be a non-empty string without ASCII whitespace or NUL")
  end

  defp tab_id(root, logical), do: root <> "-tab-" <> logical
  defp panel_id(root, logical), do: root <> "-panel-" <> logical
end
