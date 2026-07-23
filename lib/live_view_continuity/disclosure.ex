defmodule LiveViewContinuity.Disclosure do
  @moduledoc """
  An unstyled standalone disclosure with browser-owned, patch-safe expanded state.

  See `DISCLOSURE.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:default_expanded, :boolean, default: false)
  attr(:class, :any, default: nil)
  attr(:panel_class, :any, default: nil)
  attr(:rest, :global)

  slot :trigger, required: true do
    attr(:class, :any)
  end

  slot(:inner_block, required: true)

  def disclosure(assigns) do
    validate_id!(assigns.id)
    trigger = one!(assigns.trigger, "trigger")
    one!(assigns.inner_block, "body")
    assigns = assign(assigns, :trigger_entry, trigger)

    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Disclosure"
      phx-mounted={JS.ignore_attributes("data-lvc-open")}
      data-lvc-disclosure
      data-lvc-open={to_string(@default_expanded)}
      {@rest}
    >
      <button
        id={@id <> "-trigger"}
        type="button"
        class={@trigger_entry[:class]}
        aria-expanded={to_string(@default_expanded)}
        aria-controls={@id <> "-panel"}
        data-lvc-disclosure-trigger
        phx-mounted={JS.ignore_attributes("aria-expanded")}
      >
        {render_slot(@trigger_entry)}
      </button>
      <div
        id={@id <> "-panel"}
        class={@panel_class}
        aria-labelledby={@id <> "-trigger"}
        aria-hidden={to_string(!@default_expanded)}
        hidden={!@default_expanded}
        data-lvc-disclosure-panel
        phx-mounted={JS.ignore_attributes(["hidden", "aria-hidden"])}
      >
        {render_slot(@inner_block)}
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Disclosure">
        const ROOT = "[data-lvc-disclosure]";

        export default {
          mounted() {
            this.onClick = event => this.click(event);
            this.el.addEventListener("click", this.onClick);
            this.reflect(this.open());
          },
          updated() { this.reflect(this.open()); },
          destroyed() { this.el.removeEventListener("click", this.onClick); },
          trigger() { return this.el.querySelector(":scope > [data-lvc-disclosure-trigger]"); },
          panel() { return this.el.querySelector(":scope > [data-lvc-disclosure-panel]"); },
          open() { return this.el.dataset.lvcOpen === "true"; },
          click(event) {
            const trigger = event.target.closest("[data-lvc-disclosure-trigger]");
            if (!trigger || trigger.closest(ROOT) !== this.el) return;
            this.reflect(!this.open());
          },
          reflect(open) {
            this.el.dataset.lvcOpen = String(open);
            this.trigger()?.setAttribute("aria-expanded", String(open));
            const panel = this.panel();
            if (panel) {
              panel.hidden = !open;
              panel.setAttribute("aria-hidden", String(!open));
            }
          }
        };
      </script>
    </div>
    """
  end

  defp one!([entry], _name), do: entry

  defp one!(entries, name),
    do:
      raise(
        ArgumentError,
        "disclosure requires exactly one #{name} slot, got: #{length(entries)}"
      )

  defp validate_id!(id) when is_binary(id) do
    if id == "" or String.contains?(id, <<0>>) or Regex.match?(~r/[\t\n\f\r ]/, id),
      do:
        raise(
          ArgumentError,
          "disclosure id must be a non-empty string without ASCII whitespace or NUL"
        )
  end

  defp validate_id!(_id), do: raise(ArgumentError, "disclosure id must be a string")
end
