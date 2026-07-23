defmodule LiveViewContinuity.Popover do
  @moduledoc """
  An unstyled native auto popover with patch-safe browser-owned open state.

  See `POPOVER.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:popup_class, :any, default: nil)
  attr(:rest, :global)

  slot(:trigger, required: true)
  slot(:inner_block, required: true)

  def popover(assigns) do
    validate_id!(assigns.id)
    trigger = one!(assigns.trigger, "trigger")
    one!(assigns.inner_block, "body")
    assigns = assign(assigns, :trigger_entry, trigger)

    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Popover"
      phx-mounted={JS.ignore_attributes("data-lvc-open")}
      data-lvc-popover
      data-lvc-open="false"
      {@rest}
    >
      <button
        id={@id <> "-trigger"}
        type="button"
        class={@trigger_class}
        popovertarget={@id <> "-popup"}
        aria-controls={@id <> "-popup"}
        aria-expanded="false"
        data-lvc-popover-trigger
        phx-mounted={JS.ignore_attributes("aria-expanded")}
      >
        {render_slot(@trigger_entry)}
      </button>
      <div
        id={@id <> "-popup"}
        class={@popup_class}
        popover="auto"
        aria-labelledby={@id <> "-trigger"}
        data-lvc-popover-popup
      >
        {render_slot(@inner_block)}
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Popover">
        export default {
          mounted() {
            this.onToggle = event => {
              this.reflect(event.newState === "open");
            };
            this.onKeyDown = event => {
              const popup = this.popup();
              if (event.key !== "Escape" || !popup?.matches(":popover-open")) return;
              event.stopPropagation();
              setTimeout(() => this.repairFocus(popup), 0);
            };
            this.onClick = event => {
              const close = event.target.closest("[data-lvc-popover-close]");
              const popup = this.popup();
              if (close && popup?.contains(close) && close.closest("[data-lvc-popover]") === this.el) {
                if (popup.matches(":popover-open")) popup.hidePopover();
                this.repairFocus(popup);
              }
            };
            this.el.addEventListener("click", this.onClick);
            document.addEventListener("keydown", this.onKeyDown);
            this.bind();
            this.reflect(this.isOpen());
          },
          beforeUpdate() {
            this.previousTrigger = this.trigger();
            this.previousPopup = this.popup();
          },
          updated() {
            const retained = this.trigger() === this.previousTrigger && this.popup() === this.previousPopup;
            this.bind();
            if (!retained && this.isOpen()) this.popup().hidePopover();
            this.reflect(this.isOpen());
          },
          destroyed() {
            this.el.removeEventListener("click", this.onClick);
            document.removeEventListener("keydown", this.onKeyDown);
            this.unbind();
          },
          trigger() { return this.el.querySelector(":scope > [data-lvc-popover-trigger]"); },
          popup() { return this.el.querySelector(":scope > [data-lvc-popover-popup]"); },
          isOpen() { return this.popup()?.matches(":popover-open") || false; },
          bind() {
            const popup = this.popup();
            if (popup === this.boundPopup) return;
            this.unbind();
            popup?.addEventListener("toggle", this.onToggle);
            this.boundPopup = popup;
          },
          unbind() {
            this.boundPopup?.removeEventListener("toggle", this.onToggle);
            this.boundPopup = null;
          },
          repairFocus(popup) {
            if (popup !== this.popup() || popup.matches(":popover-open")) return;
            const active = document.activeElement;
            if (active === document.body || active === popup || popup.contains(active)) {
              this.trigger()?.focus({preventScroll: true});
            }
          },
          reflect(open) {
            this.el.dataset.lvcOpen = String(open);
            this.trigger()?.setAttribute("aria-expanded", String(open));
          }
        };
      </script>
    </div>
    """
  end

  defp one!([entry], _name), do: entry

  defp one!(entries, name),
    do: raise(ArgumentError, "popover requires exactly one #{name} slot, got: #{length(entries)}")

  defp validate_id!(id) when is_binary(id) do
    if id == "" or String.contains?(id, <<0>>) or Regex.match?(~r/[\t\n\f\r ]/, id),
      do:
        raise(
          ArgumentError,
          "popover id must be a non-empty string without ASCII whitespace or NUL"
        )
  end

  defp validate_id!(_), do: raise(ArgumentError, "popover id must be a string")
end
