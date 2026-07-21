defmodule LiveViewContinuity.Menu do
  @moduledoc """
  An unstyled, action-only menu with patch-safe client interaction state.

  See `MENU.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:on_action, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:rest, :global)

  slot :trigger, required: true do
    attr(:class, :any)
  end

  slot :item, required: true do
    attr(:id, :string, required: true)
    attr(:disabled, :boolean)
    attr(:class, :any)
    attr(:close_on_action, :boolean)
    attr(:typeahead_text, :string)
  end

  def menu(assigns) do
    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Menu"
      phx-mounted={JS.ignore_attributes(["data-lvc-open", "data-lvc-dismiss-reason"])}
      data-lvc-menu
      data-lvc-action={@on_action}
      {@rest}
    >
      <button
        id={@id <> "-trigger"}
        type="button"
        class={@trigger[:class]}
        aria-haspopup="menu"
        aria-expanded="false"
        aria-controls={@id <> "-popup"}
        popovertarget={@id <> "-popup"}
      >
        {render_slot(@trigger)}
      </button>
      <div
        id={@id <> "-popup"}
        role="menu"
        popover="auto"
        aria-labelledby={@id <> "-trigger"}
      >
        <button
          :for={item <- @item}
          :key={item.id}
          id={@id <> "-item-" <> item.id}
          type="button"
          role="menuitem"
          tabindex="-1"
          aria-disabled={to_string(item[:disabled] || false)}
          class={item[:class]}
          data-lvc-item
          data-lvc-logical-id={item.id}
          data-lvc-typeahead={item[:typeahead_text]}
          data-lvc-close-on-action={to_string(Map.get(item, :close_on_action, true))}
          phx-mounted={JS.ignore_attributes(["tabindex", "data-lvc-active"])}
        >
          {render_slot(item)}
        </button>
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Menu">
        const ITEM = "[data-lvc-item]";
        const RESET_MS = 500;

        export default {
          mounted() {
            this.trigger = () => this.el.querySelector(`#${CSS.escape(this.el.id)}-trigger`);
            this.popup = () => this.el.querySelector(`#${CSS.escape(this.el.id)}-popup`);
            this.items = () => [...this.el.querySelectorAll(ITEM)];
            this.activeId = null;
            this.buffer = "";
            this.bufferTimer = null;
            this.collator = new Intl.Collator(undefined, {usage: "search", sensitivity: "base"});
            this.onTriggerKey = event => this.triggerKey(event);
            this.onPopupKey = event => this.popupKey(event);
            this.onPopupClick = event => this.popupClick(event);
            this.onPopupFocus = event => this.popupFocus(event);
            this.onToggle = event => this.toggle(event);
            this.onBeforeToggle = event => this.beforeToggle(event);
            this.bind();
          },
          updated() {
            this.bind();
            if (!this.popup().matches(":popover-open")) return;
            const active = this.activeId && this.itemById(this.activeId);
            if (active) return this.focusItem(active);
            const first = this.items()[0];
            if (first) return this.focusItem(first);
            this.close("empty", true);
          },
          destroyed() { clearTimeout(this.bufferTimer); },
          bind() {
            const trigger = this.trigger();
            const popup = this.popup();
            if (this.boundTrigger !== trigger) {
              this.boundTrigger?.removeEventListener("keydown", this.onTriggerKey);
              trigger.addEventListener("keydown", this.onTriggerKey);
              this.boundTrigger = trigger;
            }
            if (this.boundPopup !== popup) {
              this.boundPopup?.removeEventListener("keydown", this.onPopupKey);
              this.boundPopup?.removeEventListener("click", this.onPopupClick);
              this.boundPopup?.removeEventListener("focusin", this.onPopupFocus);
              this.boundPopup?.removeEventListener("toggle", this.onToggle);
              this.boundPopup?.removeEventListener("beforetoggle", this.onBeforeToggle);
              popup.addEventListener("keydown", this.onPopupKey);
              popup.addEventListener("click", this.onPopupClick);
              popup.addEventListener("focusin", this.onPopupFocus);
              popup.addEventListener("toggle", this.onToggle);
              popup.addEventListener("beforetoggle", this.onBeforeToggle);
              this.boundPopup = popup;
            }
          },
          triggerKey(event) {
            const destinations = {ArrowDown: 0, ArrowUp: -1, Enter: 0, " ": 0};
            if (!(event.key in destinations)) return;
            event.preventDefault();
            this.open(destinations[event.key]);
          },
          popupKey(event) {
            const items = this.items();
            const current = Math.max(0, items.findIndex(item => item.dataset.lvcLogicalId === this.activeId));
            let next;
            if (event.key === "ArrowDown") next = (current + 1) % items.length;
            else if (event.key === "ArrowUp") next = (current - 1 + items.length) % items.length;
            else if (event.key === "Home") next = 0;
            else if (event.key === "End") next = items.length - 1;
            else if (event.key === "Escape") { event.preventDefault(); return this.close("escape", true); }
            else if (event.key === "Tab") { this.close("tab", false); return; }
            else if ((event.key === "Enter" || event.key === " ") && event.target.matches(ITEM)) {
              event.preventDefault();
              return this.activate(event.target);
            } else if (event.key.length === 1 && !event.ctrlKey && !event.metaKey && !event.altKey) {
              return this.typeahead(event.key);
            } else return;
            event.preventDefault();
            if (items[next]) this.focusItem(items[next]);
          },
          popupClick(event) {
            const item = event.target.closest(ITEM);
            if (item) this.activate(item);
          },
          popupFocus(event) {
            const item = event.target.closest(ITEM);
            if (!item) return;
            this.items().forEach(candidate => {
              candidate.tabIndex = candidate === item ? 0 : -1;
              if (candidate === item) candidate.dataset.lvcActive = "";
              else delete candidate.dataset.lvcActive;
            });
            this.activeId = item.dataset.lvcLogicalId;
          },
          activate(item) {
            if (item.getAttribute("aria-disabled") === "true") return;
            const id = item.dataset.lvcLogicalId;
            this.pushEvent(this.el.dataset.lvcAction, {id});
            if (item.dataset.lvcCloseOnAction !== "false") this.close("action", true);
          },
          open(index) {
            const popup = this.popup();
            if (!popup.matches(":popover-open")) popup.showPopover();
            const items = this.items();
            const item = index === -1 ? items.at(-1) : items[index];
            if (item) this.focusItem(item); else this.close("empty", true);
          },
          close(reason, restore) {
            const popup = this.popup();
            clearTimeout(this.bufferTimer);
            this.buffer = "";
            this.el.dataset.lvcDismissReason = reason;
            if (popup.matches(":popover-open")) popup.hidePopover();
            this.activeId = null;
            this.items().forEach(item => { item.tabIndex = -1; delete item.dataset.lvcActive; });
            if (restore) this.trigger().focus();
          },
          toggle() {
            const open = this.popup().matches(":popover-open");
            this.el.dataset.lvcOpen = String(open);
            this.trigger().setAttribute("aria-expanded", String(open));
            if (open && !this.activeId) {
              const first = this.items()[0];
              if (first) this.focusItem(first); else this.close("empty", true);
            }
          },
          beforeToggle(event) {
            if (event.newState === "open") delete this.el.dataset.lvcDismissReason;
            if (event.newState === "closed" && !this.el.contains(document.activeElement)) {
              this.el.dataset.lvcDismissReason = "outside";
              clearTimeout(this.bufferTimer);
              this.buffer = "";
              this.activeId = null;
              this.items().forEach(item => { item.tabIndex = -1; delete item.dataset.lvcActive; });
            }
          },
          focusItem(item) {
            this.items().forEach(candidate => {
              const active = candidate === item;
              candidate.tabIndex = active ? 0 : -1;
              if (active) candidate.dataset.lvcActive = ""; else delete candidate.dataset.lvcActive;
            });
            this.activeId = item.dataset.lvcLogicalId;
            item.focus();
          },
          itemById(id) { return this.items().find(item => item.dataset.lvcLogicalId === id); },
          typeahead(character) {
            clearTimeout(this.bufferTimer);
            this.buffer += character;
            this.bufferTimer = setTimeout(() => { this.buffer = ""; }, RESET_MS);
            const startsWith = (text, prefix) => {
              const chars = [...text.trim()];
              const candidate = chars.slice(0, [...prefix].length).join("");
              return this.collator.compare(candidate, prefix) === 0;
            };
            const match = this.items().find(item => startsWith(item.dataset.lvcTypeahead || item.textContent, this.buffer));
            if (match) this.focusItem(match);
          }
        };
      </script>
    </div>
    """
  end
end
