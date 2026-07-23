defmodule LiveViewContinuity.Switch do
  @moduledoc """
  An unstyled native switch with server-authoritative checked state and patch-safe optimistic interaction.

  See `SWITCH.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:checked, :boolean, required: true)
  attr(:on_change, :string, required: true)
  attr(:label, :string, default: nil)
  attr(:value, :string, default: "true")
  attr(:required, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:read_only, :boolean, default: false)
  attr(:invalid, :boolean, default: false)
  attr(:form, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:input_class, :any, default: nil)
  attr(:label_class, :any, default: nil)
  attr(:description_class, :any, default: nil)
  attr(:error_class, :any, default: nil)
  attr(:rest, :global)

  slot(:inner_block)
  slot(:description)
  slot(:error)

  def switch(assigns) do
    validate!(assigns)
    assigns = assign(assigns, :describedby, describedby(assigns))

    ~H"""
    <div
      id={@id}
      class={@class}
      phx-hook=".Switch"
      phx-mounted={JS.ignore_attributes("data-lvc-checked")}
      data-lvc-switch
      data-lvc-action={@on_change}
      data-lvc-desired-checked={to_string(@checked)}
      data-lvc-checked={to_string(@checked)}
      data-lvc-read-only={to_string(@read_only)}
      data-lvc-disabled={to_string(@disabled)}
      {@rest}
    >
      <input
        id={@id <> "-input"}
        type="checkbox"
        role="switch"
        name={@name}
        value={@value}
        form={@form}
        class={@input_class}
        checked={@checked}
        required={@required}
        disabled={@disabled}
        aria-describedby={@describedby}
        aria-invalid={to_string(@invalid)}
        aria-readonly={to_string(@read_only)}
        data-lvc-switch-input
        data-lvc-checked={to_string(@checked)}
        phx-mounted={JS.ignore_attributes(["checked", "data-lvc-checked"])}
      />
      <label id={@id <> "-label"} for={@id <> "-input"} class={@label_class}>{if @label,
        do: @label,
        else: render_slot(@inner_block)}</label>
      <div
        :if={@description != []}
        id={@id <> "-description"}
        class={@description_class}
        data-lvc-switch-description
      >
        {render_slot(@description)}
      </div>
      <div
        :if={@error != []}
        id={@id <> "-error"}
        class={@error_class}
        hidden={!@invalid}
        data-lvc-switch-error
      >
        {render_slot(@error)}
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Switch">
        const ROOT = "[data-lvc-switch]";
        const INPUT = "[data-lvc-switch-input]";

        export default {
          mounted() {
            this.hasPending = false;
            this.pending = null;
            this.resetTimer = null;
            this.resetReadOnly = false;
            this.initialDefault = this.input().defaultChecked;
            this.onChange = event => this.change(event);
            this.onClick = event => this.click(event);
            this.onReset = event => this.reset(event);
            this.el.addEventListener("change", this.onChange);
            this.el.addEventListener("click", this.onClick, true);
            document.addEventListener("reset", this.onReset);
            this.reflect(this.desired());
          },
          beforeUpdate() {
            this.wasFocused = document.activeElement === this.input();
          },
          updated() {
            if (this.resetTimer !== null && this.resetReadOnly) this.cancelResetTimer();
            const input = this.input();
            input.defaultChecked = this.initialDefault;
            const desired = this.desired();
            if (this.hasPending) {
              if (desired !== this.pendingBaseline) this.pendingSawDifferent = true;
              if (desired === this.pending && (desired !== this.pendingBaseline || this.pendingSawDifferent)) this.clearPending();
            }
            this.reflect(this.hasPending ? this.pending : desired);
            if (this.wasFocused && document.activeElement !== input) input.focus();
            this.wasFocused = false;
          },
          destroyed() {
            this.el.removeEventListener("change", this.onChange);
            this.el.removeEventListener("click", this.onClick, true);
            document.removeEventListener("reset", this.onReset);
            this.cancelResetTimer();
          },
          input() { return this.el.querySelector(":scope > [data-lvc-switch-input]"); },
          desired() { return this.el.dataset.lvcDesiredChecked === "true"; },
          effective() { return this.el.dataset.lvcChecked === "true"; },
          readOnly() { return this.el.dataset.lvcReadOnly === "true"; },
          componentDisabled() { return this.el.dataset.lvcDisabled === "true"; },
          click(event) {
            const target = event.target.closest?.(`${INPUT}, label`);
            const input = this.input();
            const belongs = target?.matches(INPUT)
              ? target.closest(ROOT) === this.el
              : target?.htmlFor === input.id && target.closest(ROOT) === this.el;
            if (!belongs || !this.readOnly()) return;
            event.preventDefault();
            queueMicrotask(() => this.reflect(this.effective()));
          },
          change(event) {
            const input = event.target.closest?.(INPUT);
            if (!input || input.closest(ROOT) !== this.el) return;
            if (this.readOnly() || this.componentDisabled()) return this.reflect(this.effective());
            this.intent(input.checked);
          },
          intent(checked) {
            this.hasPending = true;
            this.pending = checked;
            this.pendingBaseline = this.desired();
            this.pendingSawDifferent = false;
            this.reflect(checked);
            this.pushEvent(this.el.dataset.lvcAction, {checked});
          },
          clearPending() {
            this.hasPending = false;
            this.pending = null;
            this.pendingBaseline = null;
            this.pendingSawDifferent = false;
          },
          reflect(checked) {
            const input = this.input();
            input.checked = checked;
            input.dataset.lvcChecked = String(checked);
            this.el.dataset.lvcChecked = String(checked);
          },
          cancelResetTimer() {
            if (this.resetTimer !== null) clearTimeout(this.resetTimer);
            this.resetTimer = null;
            this.resetReadOnly = false;
          },
          reset(event) {
            const input = this.input();
            if (event.target !== input.form) return;
            this.cancelResetTimer();
            const before = this.effective();
            if (this.readOnly()) {
              this.resetReadOnly = true;
              input.defaultChecked = before;
              this.reflect(before);
              this.resetTimer = setTimeout(() => {
                this.resetTimer = null;
                this.resetReadOnly = false;
                if (!this.el.isConnected) return;
                input.defaultChecked = this.initialDefault;
                this.reflect(this.effective());
              }, 0);
              return;
            }
            this.resetTimer = setTimeout(() => {
              this.resetTimer = null;
              if (!this.el.isConnected || event.defaultPrevented) return;
              const checked = this.initialDefault;
              this.reflect(checked);
              if (checked !== before) this.intent(checked);
            }, 0);
          }
        };
      </script>
    </div>
    """
  end

  defp validate!(assigns) do
    validate_dom_value!(assigns.id, "switch id")
    validate_name!(assigns.name)
    validate_dom_value!(assigns.value, "switch value")

    if assigns.label != nil,
      do: validate_label!(assigns.label)

    if assigns.label == nil and assigns.inner_block == [],
      do: raise(ArgumentError, "switch requires a non-blank label or inner content")

    if length(assigns.inner_block) > 1,
      do: raise(ArgumentError, "switch accepts at most one inner content slot")

    if length(assigns.description) > 1,
      do: raise(ArgumentError, "switch accepts at most one description")

    if length(assigns.error) > 1,
      do: raise(ArgumentError, "switch accepts at most one error")
  end

  defp validate_dom_value!(value, name) when is_binary(value) do
    if value == "" or String.contains?(value, <<0>>) or Regex.match?(~r/[\t\n\f\r ]/, value),
      do:
        raise(ArgumentError, "#{name} must be a non-empty string without ASCII whitespace or NUL")
  end

  defp validate_dom_value!(_, name), do: raise(ArgumentError, "#{name} must be a string")

  defp validate_name!(name) when is_binary(name) do
    if String.trim(name) == "" or String.contains?(name, <<0>>),
      do: raise(ArgumentError, "switch name must be non-blank and contain no NUL")
  end

  defp validate_name!(_), do: raise(ArgumentError, "switch name must be a string")

  defp validate_label!(label) when is_binary(label) do
    if String.trim(label) == "", do: raise(ArgumentError, "switch label must be non-blank")
  end

  defp validate_label!(_), do: raise(ArgumentError, "switch label must be a non-blank string")

  defp describedby(assigns),
    do:
      Enum.join(
        Enum.reject(
          [
            assigns.description != [] && assigns.id <> "-description",
            assigns.invalid && assigns.error != [] && assigns.id <> "-error"
          ],
          &(&1 == false)
        ),
        " "
      )
      |> blank_to_nil()

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end
