defmodule LiveViewContinuity.Tooltip do
  @moduledoc """
  An unstyled, descriptive tooltip with patch-safe browser interaction state.

  See `TOOLTIP.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:delay, :integer, default: 600)
  attr(:disabled, :boolean, default: false)
  attr(:describedby, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:tooltip_class, :any, default: nil)
  attr(:rest, :global)

  slot(:trigger, required: true)
  slot(:inner_block, required: true)

  def tooltip(assigns) do
    validate_id!(assigns.id)
    validate_delay!(assigns.delay)
    validate_idrefs!(assigns.describedby)
    trigger = one!(assigns.trigger, "trigger")
    one!(assigns.inner_block, "body")
    assigns = assign(assigns, :trigger_entry, trigger)

    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Tooltip"
      phx-mounted={JS.ignore_attributes("data-lvc-open")}
      data-lvc-tooltip
      data-lvc-open="false"
      data-lvc-delay={@delay}
      data-lvc-disabled={to_string(@disabled)}
      data-lvc-base-describedby={@describedby}
      {@rest}
    >
      <button
        id={@id <> "-trigger"}
        type="button"
        class={@trigger_class}
        aria-describedby={@describedby}
        data-lvc-tooltip-trigger
        phx-mounted={JS.ignore_attributes("aria-describedby")}
      >
        {render_slot(@trigger_entry)}
      </button>
      <div
        id={@id <> "-popup"}
        role="tooltip"
        popover="manual"
        class={@tooltip_class}
        data-lvc-tooltip-popup
      >
        {render_slot(@inner_block)}
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Tooltip">
        export default {
          mounted() {
            this.pointer = false;
            this.focus = false;
            this.dismissed = false;
            this.generation = 0;
            this.timer = null;
            this.onPointerEnter = event => {
              if (event.pointerType !== "mouse") return;
              this.pointer = true;
              this.dismissed = false;
              if (this.focus) {
                this.cancelTimer();
                this.open();
              } else this.schedule();
            };
            this.onPointerLeave = event => {
              if (event.pointerType !== "mouse") return;
              this.pointer = false;
              this.cancelTimer();
              this.reconcileSources();
            };
            this.onFocusIn = event => {
              if (event.target !== this.trigger()) return;
              this.focus = true;
              if (this.pressing) return;
              this.dismissed = false;
              this.cancelTimer();
              this.open();
            };
            this.onFocusOut = event => {
              if (event.target !== this.boundTrigger) return;
              this.focus = false;
              this.pressing = false;
              this.reconcileSources();
            };
            this.onPointerDown = () => {
              this.pressing = true;
              this.dismiss();
            };
            this.onPointerUp = () => { this.pressing = false; };
            this.onClick = () => this.dismiss();
            this.onKeyDown = event => {
              if (event.target === this.trigger() && (event.key === "Enter" || event.key === " ")) {
                this.dismiss();
              }
            };
            this.onDocumentKeyDown = event => {
              if (event.key !== "Escape" || (!this.pointer && !this.focus && !this.timer && !this.popup()?.matches(":popover-open"))) return;
              event.preventDefault();
              this.dismiss();
            };
            document.addEventListener("keydown", this.onDocumentKeyDown);
            document.addEventListener("pointerup", this.onPointerUp);
            document.addEventListener("pointercancel", this.onPointerUp);
            this.bind();
            this.close();
          },
          beforeUpdate() {
            this.previousTrigger = this.trigger();
            this.previousPopup = this.popup();
            this.triggerHadFocus = document.activeElement === this.previousTrigger;
          },
          updated() {
            const replaced = this.trigger() !== this.previousTrigger || this.popup() !== this.previousPopup;
            this.bind();
            if (this.disabled()) return this.resetAndClose();
            if (replaced) return this.resetAndClose();
            this.reflect(this.popup()?.matches(":popover-open") || false);
          },
          destroyed() {
            this.cancelTimer();
            this.unbind();
            document.removeEventListener("keydown", this.onDocumentKeyDown);
            document.removeEventListener("pointerup", this.onPointerUp);
            document.removeEventListener("pointercancel", this.onPointerUp);
            this.close();
          },
          trigger() { return this.el.querySelector("[data-lvc-tooltip-trigger]"); },
          popup() { return this.el.querySelector("[data-lvc-tooltip-popup]"); },
          disabled() { return this.el.dataset.lvcDisabled === "true"; },
          bind() {
            const trigger = this.trigger();
            if (trigger === this.boundTrigger) return;
            this.unbind();
            trigger?.addEventListener("pointerenter", this.onPointerEnter);
            trigger?.addEventListener("pointerleave", this.onPointerLeave);
            trigger?.addEventListener("focusin", this.onFocusIn);
            trigger?.addEventListener("focusout", this.onFocusOut);
            trigger?.addEventListener("pointerdown", this.onPointerDown);
            trigger?.addEventListener("click", this.onClick);
            trigger?.addEventListener("keydown", this.onKeyDown);
            this.boundTrigger = trigger;
          },
          unbind() {
            const trigger = this.boundTrigger;
            trigger?.removeEventListener("pointerenter", this.onPointerEnter);
            trigger?.removeEventListener("pointerleave", this.onPointerLeave);
            trigger?.removeEventListener("focusin", this.onFocusIn);
            trigger?.removeEventListener("focusout", this.onFocusOut);
            trigger?.removeEventListener("pointerdown", this.onPointerDown);
            trigger?.removeEventListener("click", this.onClick);
            trigger?.removeEventListener("keydown", this.onKeyDown);
            this.boundTrigger = null;
          },
          schedule() {
            if (this.disabled() || this.dismissed || this.focus || this.timer) return;
            const generation = ++this.generation;
            const delay = Math.max(0, Number(this.el.dataset.lvcDelay) || 0);
            this.timer = setTimeout(() => {
              this.timer = null;
              if (generation === this.generation && this.pointer && !this.disabled() && !this.dismissed) this.open();
            }, delay);
          },
          cancelTimer() {
            clearTimeout(this.timer);
            this.timer = null;
            this.generation++;
          },
          reconcileSources() {
            if (!this.pointer && !this.focus) this.close();
          },
          dismiss() {
            this.dismissed = true;
            this.cancelTimer();
            this.close();
          },
          resetAndClose() {
            this.pointer = false;
            this.focus = false;
            this.pressing = false;
            this.dismissed = true;
            this.cancelTimer();
            this.close();
          },
          open() {
            const popup = this.popup();
            if (this.disabled() || this.dismissed || !popup?.isConnected) return;
            if (!popup.matches(":popover-open")) popup.showPopover();
            if (popup.isConnected) this.reflect(popup.matches(":popover-open"));
          },
          close() {
            const popup = this.popup();
            if (popup?.isConnected && popup.matches(":popover-open")) popup.hidePopover();
            this.reflect(false);
          },
          reflect(open) {
            if (!this.el?.isConnected && open) return;
            this.el.dataset.lvcOpen = String(open);
            const trigger = this.trigger();
            if (!trigger) return;
            const popupId = `${this.el.id}-popup`;
            const base = (this.el.dataset.lvcBaseDescribedby || "").trim().split(/\s+/).filter(Boolean);
            const tokens = base.filter((token, index) => token !== popupId && base.indexOf(token) === index);
            if (open) tokens.push(popupId);
            if (tokens.length) trigger.setAttribute("aria-describedby", tokens.join(" "));
            else trigger.removeAttribute("aria-describedby");
          }
        };
      </script>
    </div>
    """
  end

  defp one!([entry], _name), do: entry

  defp one!(entries, name),
    do: raise(ArgumentError, "tooltip requires exactly one #{name} slot, got: #{length(entries)}")

  defp validate_id!(id) do
    if id == "" or String.contains?(id, <<0>>) or Regex.match?(~r/[\t\n\f\r ]/, id),
      do:
        raise(
          ArgumentError,
          "tooltip id must be a non-empty string without ASCII whitespace or NUL"
        )
  end

  defp validate_delay!(delay) when is_integer(delay) and delay >= 0, do: :ok
  defp validate_delay!(_), do: raise(ArgumentError, "tooltip delay must be a nonnegative integer")

  defp validate_idrefs!(nil), do: :ok

  defp validate_idrefs!(value) when is_binary(value) do
    tokens = String.split(value, ~r/[\t\n\f\r ]+/, trim: true)

    if tokens == [] or Enum.any?(tokens, &String.contains?(&1, <<0>>)),
      do: raise(ArgumentError, "tooltip describedby must contain valid IDREF tokens")
  end

  defp validate_idrefs!(_),
    do: raise(ArgumentError, "tooltip describedby must be an IDREF string")
end
