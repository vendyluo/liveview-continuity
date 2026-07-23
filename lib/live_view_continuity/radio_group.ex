defmodule LiveViewContinuity.RadioGroup do
  @moduledoc """
  An unstyled native radio group with server-authoritative value and patch-safe optimistic selection.

  See `RADIO_GROUP.md` for the observable interaction contract.
  """

  use Phoenix.Component
  alias Phoenix.LiveView.JS

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:value, :string, required: true)
  attr(:on_change, :string, required: true)
  attr(:label, :string, required: true)
  attr(:required, :boolean, default: false)
  attr(:disabled, :boolean, default: false)
  attr(:read_only, :boolean, default: false)
  attr(:invalid, :boolean, default: false)
  attr(:form, :string, default: nil)
  attr(:class, :any, default: nil)
  attr(:legend_class, :any, default: nil)
  attr(:description_class, :any, default: nil)
  attr(:error_class, :any, default: nil)
  attr(:rest, :global)

  slot :option, required: true do
    attr(:value, :string, required: true)
    attr(:label, :string)
    attr(:disabled, :boolean)
    attr(:class, :any)
    attr(:input_class, :any)
    attr(:label_class, :any)
  end

  slot(:description)
  slot(:error)

  def radio_group(assigns) do
    validate!(assigns)
    describedby = describedby(assigns)

    assigns = assign(assigns, :describedby, describedby)

    ~H"""
    <fieldset
      id={@id}
      role="radiogroup"
      class={@class}
      disabled={@disabled}
      aria-labelledby={@id <> "-legend"}
      aria-describedby={@describedby}
      aria-required={to_string(@required)}
      aria-disabled={to_string(@disabled)}
      aria-readonly={to_string(@read_only)}
      aria-invalid={to_string(@invalid)}
      phx-hook=".RadioGroup"
      phx-mounted={JS.ignore_attributes(["data-lvc-value", "data-lvc-has-value"])}
      data-lvc-radio-group
      data-lvc-action={@on_change}
      data-lvc-desired-value={@value}
      data-lvc-desired-has-value={to_string(@value != nil)}
      data-lvc-value={@value}
      data-lvc-has-value={to_string(@value != nil)}
      data-lvc-read-only={to_string(@read_only)}
      data-lvc-disabled={to_string(@disabled)}
      {@rest}
    >
      <legend id={@id <> "-legend"} class={@legend_class}>{@label}</legend>
      <div
        :if={@description != []}
        id={@id <> "-description"}
        class={@description_class}
        data-lvc-radio-description
      >
        {render_slot(@description)}
      </div>
      <div
        :for={option <- @option}
        :key={option.value}
        class={option[:class]}
        data-lvc-radio-option
        data-lvc-value={option.value}
        data-lvc-checked={to_string(option.value == @value)}
        phx-mounted={JS.ignore_attributes("data-lvc-checked")}
      >
        <input
          id={option_id(@id, option.value)}
          type="radio"
          name={@name}
          value={option.value}
          form={@form}
          class={option[:input_class]}
          checked={option.value == @value}
          required={@required}
          disabled={@disabled || option[:disabled] || false}
          aria-describedby={@describedby}
          data-lvc-radio-input
          data-lvc-value={option.value}
          data-lvc-checked={to_string(option.value == @value)}
          phx-mounted={JS.ignore_attributes(["checked", "data-lvc-checked"])}
        />
        <label for={option_id(@id, option.value)} class={option[:label_class]}>{if option[:label],
          do: option.label,
          else: render_slot(option)}</label>
      </div>
      <div
        :if={@error != []}
        id={@id <> "-error"}
        class={@error_class}
        hidden={!@invalid}
        data-lvc-radio-error
      >
        {render_slot(@error)}
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".RadioGroup">
        const ROOT = "[data-lvc-radio-group]";
        const INPUT = "[data-lvc-radio-input]";

        export default {
          mounted() {
            this.hasPending = false;
            this.pending = null;
            this.intentGeneration = 0;
            this.defaults = new Map(this.inputs().map(input => [input.value, input.defaultChecked]));
            this.onChange = event => this.change(event);
            this.onClick = event => this.click(event);
            this.onKeyDown = event => this.keyDown(event);
            this.onReset = event => this.reset(event);
            this.el.addEventListener("change", this.onChange);
            this.el.addEventListener("click", this.onClick, true);
            this.el.addEventListener("keydown", this.onKeyDown);
            this.reflect(this.desired());
            this.bindForm();
          },
          beforeUpdate() {
            const active = document.activeElement;
            this.focusedValue = active?.matches?.(INPUT) && active.closest(ROOT) === this.el ? active.value : null;
          },
          updated() {
            this.restoreDefaults();
            const values = this.inputs().map(input => input.value);
            const desired = this.desired();
            if (this.hasPending) {
              if (this.pending !== null && !values.includes(this.pending)) {
                this.clearPending();
              } else {
                if (desired !== this.pendingBaseline) this.pendingSawDifferent = true;
                if (desired === this.pending && (desired !== this.pendingBaseline || this.pendingSawDifferent || this.pendingReplied)) this.clearPending();
              }
            }
            const effective = this.hasPending ? this.pending : desired;
            this.reflect(effective !== null && !values.includes(effective) ? null : effective);
            if (this.focusedValue !== null && !this.el.contains(document.activeElement)) {
              this.inputs().find(input => input.value === this.focusedValue)?.focus();
            }
            this.focusedValue = null;
            this.bindForm();
          },
          destroyed() {
            this.el.removeEventListener("change", this.onChange);
            this.el.removeEventListener("click", this.onClick, true);
            this.el.removeEventListener("keydown", this.onKeyDown);
            this.form?.removeEventListener("reset", this.onReset);
          },
          inputs() { return [...this.el.querySelectorAll(INPUT)].filter(input => input.closest(ROOT) === this.el); },
          desired() { return this.el.dataset.lvcDesiredHasValue === "true" ? this.el.dataset.lvcDesiredValue : null; },
          effective() { return this.el.dataset.lvcHasValue === "true" ? this.el.dataset.lvcValue : null; },
          readOnly() { return this.el.dataset.lvcReadOnly === "true"; },
          componentDisabled() { return this.el.dataset.lvcDisabled === "true"; },
          keyDown(event) {
            const input = event.target.closest?.(INPUT);
            if (!input || input.closest(ROOT) !== this.el || !event.key.startsWith("Arrow")) return;
            const enabled = this.inputs().filter(candidate => !candidate.matches(":disabled"));
            const current = enabled.indexOf(input);
            if (current < 0 || !enabled.length) return;
            const forward = event.key === "ArrowRight" || event.key === "ArrowDown";
            const next = enabled[(current + (forward ? 1 : -1) + enabled.length) % enabled.length];
            event.preventDefault();
            next.focus();
            next.click();
          },
          click(event) {
            const target = event.target.closest?.(`${INPUT}, label`);
            const input = target?.matches(INPUT) ? target : this.inputs().find(candidate => candidate.id === target?.htmlFor);
            if (!input || input.closest(ROOT) !== this.el || !this.readOnly()) return;
            event.preventDefault();
            queueMicrotask(() => this.reflect(this.effective()));
          },
          change(event) {
            const input = event.target.closest?.(INPUT);
            if (!input || input.closest(ROOT) !== this.el) return;
            if (this.readOnly() || this.componentDisabled()) return this.reflect(this.effective());
            this.intent(input.value);
          },
          intent(value) {
            this.hasPending = true;
            this.pending = value;
            this.pendingBaseline = this.desired();
            this.pendingSawDifferent = false;
            this.pendingReplied = false;
            const generation = ++this.intentGeneration;
            this.reflect(value);
            this.pushEvent(this.el.dataset.lvcAction, {value}, () => {
              if (generation !== this.intentGeneration || !this.hasPending) return;
              this.pendingReplied = true;
              if (this.desired() === this.pending) {
                const desired = this.desired();
                this.clearPending();
                this.reflect(desired);
              }
            });
          },
          clearPending() {
            this.hasPending = false;
            this.pending = null;
            this.pendingBaseline = null;
            this.pendingSawDifferent = false;
            this.pendingReplied = false;
          },
          restoreDefaults() {
            this.inputs().forEach(input => {
              if (!this.defaults.has(input.value)) this.defaults.set(input.value, input.defaultChecked);
              input.defaultChecked = this.defaults.get(input.value);
            });
          },
          reflect(value) {
            this.inputs().forEach(input => {
              const checked = value !== null && input.value === value;
              input.checked = checked;
              input.dataset.lvcChecked = String(checked);
              input.closest("[data-lvc-radio-option]").dataset.lvcChecked = String(checked);
            });
            this.el.dataset.lvcHasValue = String(value !== null);
            if (value === null) delete this.el.dataset.lvcValue;
            else this.el.dataset.lvcValue = value;
          },
          bindForm() {
            const form = this.inputs()[0]?.form || null;
            if (form === this.form) return;
            this.form?.removeEventListener("reset", this.onReset);
            this.form = form;
            this.form?.addEventListener("reset", this.onReset);
          },
          reset(event) {
            const before = this.effective();
            if (this.readOnly()) {
              this.inputs().forEach(input => {
                input.defaultChecked = before !== null && input.value === before;
              });
              this.reflect(before);
              return;
            }
            const selected = this.inputs().filter(input => this.defaults.get(input.value)).at(-1)?.value || null;
            this.reflect(selected);
            if (selected !== before) this.intent(selected);
          }
        };
      </script>
    </fieldset>
    """
  end

  defp validate!(assigns) do
    validate_dom_value!(assigns.id, "radio group id")
    validate_name!(assigns.name)
    validate_label!(assigns.label, "radio group label")
    if assigns.option == [], do: raise(ArgumentError, "radio group requires at least one option")

    if length(assigns.description) > 1,
      do: raise(ArgumentError, "radio group accepts at most one description")

    if length(assigns.error) > 1,
      do: raise(ArgumentError, "radio group accepts at most one error")

    values = Enum.map(assigns.option, & &1.value)
    Enum.each(values, &validate_dom_value!(&1, "radio option value"))
    Enum.each(assigns.option, &validate_option_label!/1)

    if length(values) != length(Enum.uniq(values)),
      do: raise(ArgumentError, "radio option values must be unique")

    if assigns.value != nil, do: validate_dom_value!(assigns.value, "radio group value")

    if assigns.value != nil and assigns.value not in values,
      do: raise(ArgumentError, "radio group value must identify an existing option")
  end

  defp validate_dom_value!(value, name) when is_binary(value) do
    if value == "" or String.contains?(value, <<0>>) or Regex.match?(~r/[\t\n\f\r ]/, value),
      do:
        raise(ArgumentError, "#{name} must be a non-empty string without ASCII whitespace or NUL")
  end

  defp validate_dom_value!(_, name), do: raise(ArgumentError, "#{name} must be a string")

  defp validate_name!(name) when is_binary(name) do
    if String.trim(name) == "" or String.contains?(name, <<0>>),
      do: raise(ArgumentError, "radio group name must be non-blank and contain no NUL")
  end

  defp validate_name!(_), do: raise(ArgumentError, "radio group name must be a string")

  defp validate_label!(label, name) when is_binary(label) do
    if String.trim(label) == "", do: raise(ArgumentError, "#{name} must be a non-blank string")
  end

  defp validate_label!(_, name), do: raise(ArgumentError, "#{name} must be a non-blank string")

  defp validate_option_label!(%{label: label}) when not is_nil(label),
    do: validate_label!(label, "radio option label")

  defp validate_option_label!(%{inner_block: inner_block}) when is_function(inner_block), do: :ok

  defp validate_option_label!(_),
    do: raise(ArgumentError, "radio option requires a non-blank label or inner content")

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
  defp option_id(root, value), do: root <> "-option-" <> value
end
