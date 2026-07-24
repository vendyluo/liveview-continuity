defmodule LiveViewContinuity.Select do
  @moduledoc "An unstyled custom single select with a native form bridge. See `SELECT.md`."

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :string, required: true)
  attr(:on_change, :string, required: true)
  attr(:label, :string, required: true)
  attr(:placeholder, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:read_only, :boolean, default: false)
  attr(:invalid, :boolean, default: false)
  attr(:form, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:trigger_class, :any, default: nil)
  attr(:popup_class, :any, default: nil)
  attr(:native_class, :any, default: nil)
  attr(:label_class, :any, default: nil)
  attr(:description_class, :any, default: nil)
  attr(:error_class, :any, default: nil)
  attr(:rest, :global)

  slot :option, required: true do
    attr(:value, :string, required: true)
    attr(:disabled, :boolean)
    attr(:class, :any)
  end

  slot(:description)
  slot(:error)

  def select(assigns) do
    assigns = if assigns.value == "", do: assign(assigns, :value, nil), else: assigns
    validate!(assigns)

    assigns =
      assigns
      |> assign(:describedby, describedby(assigns))
      |> assign(:selected_option, Enum.find(assigns.option, &(&1.value == assigns.value)))

    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Select"
      phx-mounted={JS.ignore_attributes(["data-lvc-value", "data-lvc-has-value", "data-lvc-open"])}
      data-lvc-select
      data-lvc-action={@on_change}
      data-lvc-desired-value={@value}
      data-lvc-desired-has-value={to_string(@value != nil)}
      data-lvc-value={@value}
      data-lvc-has-value={to_string(@value != nil)}
      data-lvc-open="false"
      data-lvc-read-only={to_string(@read_only)}
      data-lvc-disabled={to_string(@disabled)}
      data-lvc-placeholder={@placeholder || ""}
      data-lvc-invalid={to_string(@invalid)}
      {@rest}
    >
      <span id={@id <> "-label"} class={@label_class}>{@label}</span>
      <button
        id={@id <> "-trigger"}
        type="button"
        class={@trigger_class}
        disabled={@disabled}
        role="combobox"
        aria-required={to_string(@required)}
        aria-labelledby={@id <> "-label " <> @id <> "-value"}
        aria-describedby={@describedby}
        aria-invalid={to_string(@invalid)}
        aria-readonly={@read_only && "true"}
        aria-haspopup="listbox"
        aria-expanded="false"
        aria-controls={@id <> "-popup"}
        phx-mounted={JS.ignore_attributes("aria-expanded")}
        data-lvc-select-trigger
      >
        <span id={@id <> "-value"} data-lvc-select-value>{if @selected_option,
          do: render_slot(@selected_option),
          else: @placeholder}</span>
      </button>
      <div
        id={@id <> "-popup"}
        class={@popup_class}
        role="listbox"
        popover="manual"
        aria-labelledby={@id <> "-label"}
        tabindex="-1"
        data-lvc-select-popup
      >
        <div
          :for={option <- @option}
          :key={option.value}
          id={option_id(@id, option.value)}
          role="option"
          tabindex="-1"
          class={option[:class]}
          aria-selected={to_string(option.value == @value)}
          aria-disabled={to_string(option[:disabled] || false)}
          data-lvc-select-option
          data-lvc-value={option.value}
          phx-mounted={JS.ignore_attributes(["aria-selected", "tabindex", "data-lvc-active"])}
        >
          {render_slot(option)}
        </div>
      </div>
      <select
        id={@id <> "-native"}
        name={@name}
        form={@form}
        class={@native_class}
        style="position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0;appearance:none;"
        required={@required}
        disabled={@disabled}
        tabindex="-1"
        aria-hidden="true"
        data-lvc-select-native
        phx-mounted={JS.ignore_attributes("value")}
      >
        <option value="" selected={@value == nil}></option>
        <option
          :for={option <- @option}
          :key={option.value}
          value={option.value}
          selected={option.value == @value}
          disabled={option[:disabled] || false}
        >
          {render_slot(option)}
        </option>
      </select>
      <div :if={@description != []} id={@id <> "-description"} class={@description_class}>
        {render_slot(@description)}
      </div>
      <div :if={@error != []} id={@id <> "-error"} class={@error_class} hidden={!@invalid}>
        {render_slot(@error)}
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Select">
        const OPTION = "[data-lvc-select-option]", RESET_MS = 500;
        export default {
          mounted() {
            this.hasPending = false; this.pending = null; this.activeValue = null; this.buffer = ""; this.nativeInvalid = false; const initial = [...this.native().options].find(o => o.defaultSelected)?.value; this.defaults = initial ? initial : null;
            this.collator = new Intl.Collator(undefined, {usage: "search", sensitivity: "base"});
            this.onClick = e => this.click(e); this.onKey = e => this.key(e); this.onReset = e => this.reset(e); this.onPointerDown = e => this.outside(e); this.onInvalid = e => this.invalid(e);
            this.el.addEventListener("click", this.onClick); this.el.addEventListener("keydown", this.onKey); this.native().addEventListener("invalid", this.onInvalid); document.addEventListener("pointerdown", this.onPointerDown); document.addEventListener("reset", this.onReset);
            this.reflect(this.desired());
          },
          beforeUpdate() { const active = document.activeElement; this.focusOwned = active === this.trigger() || this.popup().contains(active); this.triggerFocused = active === this.trigger(); },
          updated() {
            const values = this.options().map(o => o.dataset.lvcValue); const effectiveDefault = this.defaults !== null && values.includes(this.defaults) ? this.defaults : "";
            [...this.native().options].forEach(o => o.defaultSelected = o.value === effectiveDefault); const desired = this.desired();
            if (this.hasPending && (this.readOnly() || this.disabled() || !values.includes(this.pending))) this.clearPending();
            else if (this.hasPending) { if (desired !== this.baseline) this.sawDifferent = true; if (desired === this.pending && (desired !== this.baseline || this.sawDifferent)) this.clearPending(); }
            this.reflect(this.hasPending ? this.pending : desired);
            if (this.disabled() && this.opened()) { this.close(false); if (this.focusOwned) document.activeElement?.blur(); }
            else if (this.opened()) { const candidate = this.option(this.activeValue); const active = candidate && this.isEnabled(candidate) ? candidate : this.enabled()[0]; if (active) this.focus(active); else { this.close(false); if (this.focusOwned && !this.disabled()) this.trigger().focus(); } }
            else if (this.triggerFocused && !this.disabled()) this.trigger().focus();
          },
          destroyed() { clearTimeout(this.timer); this.el.removeEventListener("click", this.onClick); this.el.removeEventListener("keydown", this.onKey); this.native()?.removeEventListener("invalid", this.onInvalid); document.removeEventListener("pointerdown", this.onPointerDown); document.removeEventListener("reset", this.onReset); },
          trigger() { return this.el.querySelector(":scope > [data-lvc-select-trigger]"); },
          popup() { return this.el.querySelector(":scope > [data-lvc-select-popup]"); },
          native() { return this.el.querySelector(":scope > [data-lvc-select-native]"); },
          options() { return [...this.popup().querySelectorAll(OPTION)]; },
          isEnabled(option) { return option?.getAttribute("aria-disabled") !== "true"; }, enabled() { return this.options().filter(o => this.isEnabled(o)); },
          option(value) { return this.options().find(o => o.dataset.lvcValue === value); },
          desired() { return this.el.dataset.lvcDesiredHasValue === "true" ? this.el.dataset.lvcDesiredValue : null; },
          readOnly() { return this.el.dataset.lvcReadOnly === "true"; }, disabled() { return this.el.dataset.lvcDisabled === "true"; }, opened() { return this.popup().matches(":popover-open"); },
          click(e) { const option = e.target.closest?.(OPTION); if (option && this.popup().contains(option)) return this.choose(option); if (e.target.closest?.("[data-lvc-select-trigger]") === this.trigger()) this.opened() ? this.close(true) : this.open(0); },
          outside(e) { if (this.opened() && !this.el.contains(e.target)) this.close(false); },
          key(e) {
            if (e.target === this.trigger()) { const at = {ArrowDown: 0, ArrowUp: -1, Enter: 0, " ": 0}[e.key]; if (at === undefined) return; e.preventDefault(); return this.open(at); }
            if (!this.popup().contains(e.target)) return; const enabled = this.enabled(), current = Math.max(0, enabled.findIndex(o => o.dataset.lvcValue === this.activeValue)); let at;
            if (e.key === "ArrowDown") at = (current + 1) % enabled.length; else if (e.key === "ArrowUp") at = (current - 1 + enabled.length) % enabled.length;
            else if (e.key === "Home") at = 0; else if (e.key === "End") at = enabled.length - 1;
            else if (e.key === "Escape") { e.preventDefault(); return this.close(true); } else if (e.key === "Tab") { setTimeout(() => this.close(false), 0); return; }
            else if (e.key === "Enter" || e.key === " ") { e.preventDefault(); return this.choose(e.target.closest(OPTION)); }
            else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) return this.typeahead(e.key); else return;
            e.preventDefault(); if (enabled[at]) this.focus(enabled[at]);
          },
          open(at) { if (this.disabled()) return; const enabled = this.enabled(); if (!enabled.length) return; if (!this.opened()) this.popup().showPopover(); this.el.dataset.lvcOpen = "true"; this.trigger().setAttribute("aria-expanded", "true"); const selected = this.option(this.el.dataset.lvcHasValue === "true" ? this.el.dataset.lvcValue : null); this.focus(at === -1 ? enabled.at(-1) : (at === 0 && this.isEnabled(selected) ? selected : enabled[at])); },
          close(restore) { if (this.opened()) this.popup().hidePopover(); this.el.dataset.lvcOpen = "false"; this.trigger().setAttribute("aria-expanded", "false"); this.options().forEach(o => { o.tabIndex = -1; delete o.dataset.lvcActive; }); this.activeValue = null; clearTimeout(this.timer); this.buffer = ""; if (restore && !this.disabled()) this.trigger().focus(); },
          setActive(option) { if (!option) return; this.options().forEach(o => { o.tabIndex = o === option ? 0 : -1; if (o === option) o.dataset.lvcActive = ""; else delete o.dataset.lvcActive; }); this.activeValue = option.dataset.lvcValue; },
          focus(option) { if (!option) return; this.setActive(option); option.focus(); },
          choose(option) { if (!option || option.getAttribute("aria-disabled") === "true" || this.readOnly() || this.disabled()) return; this.intent(option.dataset.lvcValue); this.close(true); },
          intent(value) { this.hasPending = true; this.pending = value; this.baseline = this.desired(); this.sawDifferent = false; this.reflect(value); this.pushEventTo(this.el, this.el.dataset.lvcAction, {value}); },
          clearPending() { this.hasPending = false; this.pending = null; this.baseline = null; this.sawDifferent = false; },
          reflect(value) { this.el.dataset.lvcHasValue = String(value !== null); if (value === null) delete this.el.dataset.lvcValue; else this.el.dataset.lvcValue = value; this.native().value = value ?? ""; this.options().forEach(o => o.setAttribute("aria-selected", String(o.dataset.lvcValue === value))); const selected = this.option(value); this.el.querySelector("[data-lvc-select-value]").textContent = selected ? selected.textContent.trim() : this.el.dataset.lvcPlaceholder; if (this.native().validity.valid) this.nativeInvalid = false; this.el.dataset.lvcNativeInvalid = String(this.nativeInvalid); this.trigger().setAttribute("aria-invalid", String(this.el.dataset.lvcInvalid === "true" || this.nativeInvalid)); },
          typeahead(char) { clearTimeout(this.timer); this.buffer += char; this.timer = setTimeout(() => this.buffer = "", RESET_MS); const start = Math.max(0, this.enabled().findIndex(o => o.dataset.lvcValue === this.activeValue)); const ordered = [...this.enabled().slice(start + 1), ...this.enabled().slice(0, start + 1)]; const found = ordered.find(o => this.collator.compare(o.textContent.trim().slice(0, this.buffer.length), this.buffer) === 0); if (found) this.focus(found); },
          invalid(event) { event.preventDefault(); this.nativeInvalid = true; this.el.dataset.lvcNativeInvalid = "true"; this.trigger().setAttribute("aria-invalid", "true"); if (this.disabled()) return; this.trigger().focus(); const native = this.native(); const firstInvalid = [...(native.form?.elements ?? [])].find(control => control.willValidate && !control.validity.valid); if (firstInvalid === native) setTimeout(() => { if (this.el.isConnected && !this.disabled()) this.trigger().focus(); }, 0); },
          reset(event) { if (event.target !== this.native().form) return; const before = this.el.dataset.lvcHasValue === "true" ? this.el.dataset.lvcValue : null; setTimeout(() => { if (!this.el.isConnected) return; if (event.defaultPrevented || this.readOnly() || this.disabled()) return this.reflect(before); this.clearPending(); const value = this.defaults !== null && this.option(this.defaults) ? this.defaults : null; this.reflect(value); if (value !== before) this.intent(value); }, 0); }
        };
      </script>
    </div>
    """
  end

  defp validate!(a) do
    if not is_binary(a.id) or a.id == "" or String.match?(a.id, ~r/[\x00\x09-\x0D\x20]/),
      do:
        raise(ArgumentError, "select id must be non-empty and contain no ASCII whitespace or NUL")

    for {value, name} <- [
          {a.name, "name"},
          {a.on_change, "on_change"},
          {a.label, "label"}
        ],
        do: nonblank!(value, name)

    if a.value != nil and not is_binary(a.value),
      do: raise(ArgumentError, "select value must be a string or nil")

    if length(a.description) > 1 or length(a.error) > 1,
      do: raise(ArgumentError, "select accepts at most one description and one error")

    values =
      Enum.map(a.option, fn o ->
        nonblank!(o.value, "option value")
        o.value
      end)

    if length(values) != length(Enum.uniq(values)),
      do: raise(ArgumentError, "select option values must be unique")

    if a.value != nil and a.value not in values,
      do: raise(ArgumentError, "select value must match an option")
  end

  defp nonblank!(v, name) when is_binary(v),
    do:
      if(String.trim(v) == "" or String.contains?(v, <<0>>),
        do: raise(ArgumentError, "select #{name} must be non-blank")
      )

  defp nonblank!(_, name), do: raise(ArgumentError, "select #{name} must be a string")
  defp option_id(id, value), do: id <> "-option-" <> Base.url_encode64(value, padding: false)

  defp describedby(a),
    do:
      [
        a.description != [] && a.id <> "-description",
        a.invalid && a.error != [] && a.id <> "-error"
      ]
      |> Enum.reject(&(&1 == false))
      |> Enum.join(" ")
      |> then(&if(&1 == "", do: nil, else: &1))
end
