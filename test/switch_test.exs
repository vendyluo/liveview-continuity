defmodule LiveViewContinuity.SwitchTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render_switch(checked, attrs) do
    render_component(
      &LiveViewContinuity.Switch.switch/1,
      Keyword.merge(
        [
          id: "sale",
          name: "sale_active",
          checked: checked,
          on_change: "change",
          label: "Sale active"
        ],
        attrs
      )
    )
  end

  test "renders native switch semantics and complete ARIA graph" do
    html =
      render_switch(true,
        value: "enabled",
        required: true,
        invalid: true,
        description: [slot("Controls public sale")],
        error: [slot("Choose a state")]
      )

    assert html =~ ~s(<div id="sale")
    assert html =~ ~s(data-lvc-switch)
    assert html =~ ~s(data-lvc-desired-checked="true")
    assert html =~ ~s(data-lvc-checked="true")
    assert html =~ ~s(id="sale-input" type="checkbox" role="switch")
    assert html =~ ~s(name="sale_active" value="enabled")
    assert input_tag(html) =~ ~r/\schecked(?:\s|>)/
    assert input_tag(html) =~ ~r/\srequired(?:\s|>)/
    assert html =~ ~s(aria-describedby="sale-description sale-error")
    assert html =~ ~s(aria-invalid="true")
    assert html =~ ~s(<label id="sale-label" for="sale-input" class="">Sale active</label>)
    assert html =~ ~s(id="sale-description")
    assert html =~ ~s(id="sale-error" class="")
  end

  test "renders unchecked, disabled, read-only, external form and consumer attributes" do
    html =
      render_switch(false,
        disabled: true,
        read_only: true,
        form: "settings",
        class: "root",
        input_class: "input",
        label_class: "label",
        rest: %{"data-test": "yes"}
      )

    assert html =~ ~s(class="root")
    assert html =~ ~s(class="input")
    assert html =~ ~s(class="label")
    assert html =~ ~s(form="settings")
    assert html =~ ~s(data-lvc-read-only="true")
    assert html =~ ~s(data-lvc-disabled="true")
    assert input_tag(html) =~ ~s(aria-readonly="true")
    assert html =~ ~s(data-test="yes")
    assert input_tag(html) =~ ~r/\sdisabled(?:\s|>)/
    refute input_tag(html) =~ ~r/\schecked(?:\s|>)/
  end

  test "renders structured label content" do
    html =
      render_switch(false,
        label: nil,
        inner_block: [slot({:safe, "<span>Sale</span><span class=\"state\">Paused</span>"})]
      )

    assert html =~
             ~s(<label id="sale-label" for="sale-input" class=""><span>Sale</span><span class="state">Paused</span></label>)
  end

  test "description is always referenced and error only while invalid" do
    html = render_switch(false, description: [slot("Help")], error: [slot("Error")])
    assert html =~ ~s(aria-describedby="sale-description")
    assert html =~ ~s(id="sale-error" class="" hidden)
    refute html =~ ~s(aria-describedby="sale-description sale-error")
  end

  test "rejects invalid composition" do
    for {attrs, message} <- [
          {[id: "bad id"], "switch id"},
          {[name: "  "], "switch name"},
          {[name: "bad\0name"], "switch name"},
          {[value: "bad value"], "switch value"},
          {[label: "\n"], "switch label"},
          {[label: nil], "label or inner content"},
          {[inner_block: [slot("a"), slot("b")]], "at most one inner content"},
          {[description: [slot("a"), slot("b")]], "at most one description"},
          {[error: [slot("a"), slot("b")]], "at most one error"}
        ] do
      assert_raise ArgumentError, ~r/#{message}/, fn -> render_switch(false, attrs) end
    end
  end

  defp slot(content), do: %{inner_block: fn _, _ -> content end}
  defp input_tag(html), do: opening_tag(html, "input", "sale-input")

  defp opening_tag(html, tag, id) do
    [match] = Regex.run(~r/<#{tag}(?=[^>]*\sid="#{Regex.escape(id)}")[^>]*>/, html)
    match
  end
end
