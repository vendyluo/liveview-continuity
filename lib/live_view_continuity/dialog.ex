defmodule LiveViewContinuity.Dialog do
  @moduledoc """
  A native modal dialog with server-owned intent and patch-safe browser state.

  See `DIALOG.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:open, :boolean, required: true)
  attr(:on_open, :string, required: true)
  attr(:on_close, :string, required: true)
  attr(:initial_focus, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:dialog_class, :any, default: nil)
  attr(:rest, :global)

  slot :trigger, required: true do
    attr(:class, :any)
  end

  slot :title, required: true do
    attr(:class, :any)
  end

  slot :description do
    attr(:class, :any)
  end

  slot(:inner_block, required: true)

  slot :close, required: true do
    attr(:class, :any)
  end

  def dialog(assigns) do
    validate_id!(assigns.id)
    assigns = assign_entries!(assigns)

    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Dialog"
      phx-mounted={JS.ignore_attributes(["data-lvc-open", "data-lvc-close-reason"])}
      data-lvc-dialog
      data-lvc-desired-open={to_string(@open)}
      data-lvc-open="false"
      data-lvc-on-open={@on_open}
      data-lvc-on-close={@on_close}
      data-lvc-initial-focus={@initial_focus}
      {@rest}
    >
      <button
        id={@id <> "-trigger"}
        type="button"
        class={@trigger_entry[:class]}
        aria-controls={@id <> "-popup"}
        aria-expanded="false"
        data-lvc-dialog-trigger
        phx-mounted={JS.ignore_attributes("aria-expanded")}
      >
        {render_slot(@trigger_entry)}
      </button>
      <dialog
        id={@id <> "-popup"}
        class={@dialog_class}
        aria-labelledby={@id <> "-title"}
        aria-describedby={if @description_entry, do: @id <> "-description"}
        data-lvc-dialog-popup
        phx-mounted={JS.ignore_attributes("open")}
      >
        <h2 id={@id <> "-title"} class={@title_entry[:class]}>{render_slot(@title_entry)}</h2>
        <p :if={@description_entry} id={@id <> "-description"} class={@description_entry[:class]}>
          {render_slot(@description_entry)}
        </p>
        {render_slot(@inner_block)}
        <button
          id={@id <> "-close"}
          type="button"
          class={@close_entry[:class]}
          data-lvc-dialog-close
        >
          {render_slot(@close_entry)}
        </button>
      </dialog>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Dialog">
        const modalInstances = new Set();
        let savedScrollStyle = null;
        const lock = instance => {
          modalInstances.add(instance);
          if (modalInstances.size !== 1) return;
          const root = document.documentElement;
          savedScrollStyle = {overflow: root.style.overflow, scrollbarGutter: root.style.scrollbarGutter};
          root.style.overflow = "hidden";
          root.style.scrollbarGutter = "stable";
        };
        const unlock = instance => {
          modalInstances.delete(instance);
          if (modalInstances.size || !savedScrollStyle) return;
          document.documentElement.style.overflow = savedScrollStyle.overflow;
          document.documentElement.style.scrollbarGutter = savedScrollStyle.scrollbarGutter;
          savedScrollStyle = null;
        };
        const FOCUSABLE = ":is(button,input,select,textarea,a[href],[tabindex],[contenteditable])";
        const available = element => !!element && !element.matches(":disabled") && !element.closest("[inert]") && element.getClientRects().length > 0 && !["hidden", "collapse"].includes(getComputedStyle(element).visibility);
        const focusElement = element => {
          if (!available(element)) return false;
          element.focus();
          return document.activeElement === element;
        };
        const tabbables = popup => [...popup.querySelectorAll(FOCUSABLE)]
          .filter(element => available(element) && element.tabIndex >= 0)
          .sort((a, b) => {
            if (a.tabIndex > 0 && b.tabIndex <= 0) return -1;
            if (a.tabIndex <= 0 && b.tabIndex > 0) return 1;
            return a.tabIndex > 0 && b.tabIndex > 0 ? a.tabIndex - b.tabIndex : 0;
          });

        export default {
          mounted() {
            this.pendingIntent = null;
            this.userCloseReason = null;
            this.focusedId = null;
            this.onClick = event => this.click(event);
            this.onCancel = event => {
              event.preventDefault();
              this.pendingIntent = "close";
              this.userCloseReason = "escape";
              this.popup().close();
            };
            this.onClose = () => this.closed();
            this.onFocus = event => { if (event.target.id) this.focusedId = event.target.id; };
            this.onKey = event => this.key(event);
            this.el.addEventListener("click", this.onClick);
            this.bind();
            this.reconcile(false);
          },
          beforeUpdate() {
            const dialog = this.popup();
            this.wasOpen = dialog?.open || false;
            this.hadFocus = !!dialog?.contains(document.activeElement);
            this.focusedId = this.hadFocus ? document.activeElement.id || null : null;
          },
          updated() { this.bind(); this.reconcile(true); },
          destroyed() {
            this.unbindPopup();
            this.el.removeEventListener("click", this.onClick);
            unlock(this);
          },
          trigger() { return this.el.querySelector(`#${CSS.escape(this.el.id)}-trigger`); },
          closeButton() { return this.el.querySelector(`#${CSS.escape(this.el.id)}-close`); },
          popup() { return this.el.querySelector("[data-lvc-dialog-popup]"); },
          bind() {
            const popup = this.popup();
            if (popup === this.boundPopup) return;
            this.unbindPopup();
            popup.addEventListener("cancel", this.onCancel);
            popup.addEventListener("close", this.onClose);
            popup.addEventListener("focusin", this.onFocus);
            popup.addEventListener("keydown", this.onKey);
            this.boundPopup = popup;
          },
          unbindPopup() {
            this.boundPopup?.removeEventListener("cancel", this.onCancel);
            this.boundPopup?.removeEventListener("close", this.onClose);
            this.boundPopup?.removeEventListener("focusin", this.onFocus);
            this.boundPopup?.removeEventListener("keydown", this.onKey);
            this.boundPopup = null;
          },
          key(event) {
            if (event.key !== "Tab") return;
            const items = tabbables(this.popup());
            if (!items.length) return;
            const first = items[0];
            const last = items.at(-1);
            if (event.shiftKey && document.activeElement === first) {
              event.preventDefault();
              last.focus();
            } else if (!event.shiftKey && document.activeElement === last) {
              event.preventDefault();
              first.focus();
            }
          },
          click(event) {
            const trigger = event.target.closest("[data-lvc-dialog-trigger]");
            const close = event.target.closest("[data-lvc-dialog-close]");
            if (trigger === this.trigger()) {
              if (!this.popup().open) {
                this.pendingIntent = "open";
                this.openNative();
                this.pushEvent(this.el.dataset.lvcOnOpen, {});
              }
            } else if (close === this.closeButton()) {
              this.pendingIntent = "close";
              this.userCloseReason = "close";
              this.popup().close();
            }
          },
          reconcile(wasUpdated) {
            const desired = this.el.dataset.lvcDesiredOpen === "true";
            if (this.pendingIntent === "open" && desired) this.pendingIntent = null;
            if (this.pendingIntent === "close" && !desired) this.pendingIntent = null;
            const effectiveDesired = this.pendingIntent === "open" ? true : this.pendingIntent === "close" ? false : desired;
            const popup = this.popup();
            if (effectiveDesired && !popup.open) this.openNative();
            else if (!effectiveDesired && popup.open) popup.close();
            else this.reflect(popup.open);
            if (popup.open && wasUpdated && this.hadFocus && !popup.contains(document.activeElement)) {
              const preserved = this.focusedId && this.el.querySelector(`#${CSS.escape(this.focusedId)}`);
              if (!focusElement(preserved)) this.focusFallback();
            }
          },
          openNative() {
            const popup = this.popup();
            popup.showModal();
            lock(this);
            this.reflect(true);
            this.focusFallback();
          },
          focusFallback() {
            let target = null;
            const selector = this.el.dataset.lvcInitialFocus;
            if (selector) {
              try {
                const matches = [...this.popup().querySelectorAll(selector)];
                if (matches.length === 1) target = matches[0];
              } catch (_) {}
            }
            if (!focusElement(target)) focusElement(this.closeButton());
          },
          reflect(open) {
            this.el.dataset.lvcOpen = String(open);
            this.trigger().setAttribute("aria-expanded", String(open));
            if (open) delete this.el.dataset.lvcCloseReason;
          },
          closed() {
            unlock(this);
            this.reflect(false);
            const reason = this.userCloseReason;
            this.userCloseReason = null;
            if (reason) {
              this.el.dataset.lvcCloseReason = reason;
              this.pendingIntent = "close";
              this.pushEvent(this.el.dataset.lvcOnClose, {reason});
            }
            setTimeout(() => {
              const active = document.activeElement;
              const trigger = this.trigger();
              if ((active === document.body || active === this.popup()) && trigger.isConnected) focusElement(trigger);
            }, 0);
          }
        };
      </script>
    </div>
    """
  end

  defp assign_entries!(assigns) do
    trigger = one!(assigns.trigger, "trigger", true)
    title = one!(assigns.title, "title", true)
    description = one!(assigns.description, "description", false)
    close = one!(assigns.close, "close", true)
    one!(assigns.inner_block, "body", true)

    assigns
    |> assign(:trigger_entry, trigger)
    |> assign(:title_entry, title)
    |> assign(:description_entry, description)
    |> assign(:close_entry, close)
  end

  defp one!([entry], _name, _required), do: entry
  defp one!([], _name, false), do: nil

  defp one!(entries, name, _),
    do: raise(ArgumentError, "dialog requires exactly one #{name} slot, got: #{length(entries)}")

  defp validate_id!(id) do
    if id == "" or String.contains?(id, <<0>>) or Regex.match?(~r/[\t\n\f\r ]/, id),
      do:
        raise(
          ArgumentError,
          "dialog id must be a non-empty string without ASCII whitespace or NUL"
        )
  end
end
