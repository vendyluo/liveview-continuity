defmodule LiveViewContinuity.CheckboxTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render_checkbox(checked, attrs \\ []) do
    render_component(
      &LiveViewContinuity.Checkbox.checkbox/1,
      Keyword.merge(
        [
          id: "terms",
          name: "terms",
          checked: checked,
          on_change: "change",
          label: "Accept terms"
        ],
        attrs
      )
    )
  end

  test "renders native checkbox and complete label and description graph" do
    html =
      render_checkbox(true,
        value: "accepted",
        required: true,
        invalid: true,
        description: [slot("Required")],
        error: [slot("Accept this")]
      )

    input = opening_tag(html, "input", "terms-input")
    assert input =~ ~s(type="checkbox")
    refute input =~ ~s(role=)
    assert input =~ ~s(name="terms" value="accepted")
    assert input =~ ~r/\schecked(?:\s|>)/
    assert input =~ ~r/\srequired(?:\s|>)/
    assert input =~ ~s(aria-describedby="terms-description terms-error")
    assert html =~ ~s(<label id="terms-label" for="terms-input" class="">Accept terms</label>)
  end

  test "supports native flags, external form, consumer attributes, and synthetic readonly only" do
    html =
      render_checkbox(false,
        disabled: true,
        read_only: true,
        form: "checkout",
        class: "root",
        input_class: "input",
        rest: %{"data-test": "yes"}
      )

    input = opening_tag(html, "input", "terms-input")
    assert input =~ ~s(form="checkout")
    assert input =~ ~s(aria-readonly="true")
    assert input =~ ~r/\sdisabled(?:\s|>)/
    assert html =~ ~s(data-test="yes")
    refute opening_tag(render_checkbox(false), "input", "terms-input") =~ "aria-readonly"
  end

  test "supports structured label and conditional error reference" do
    html =
      render_checkbox(false,
        label: nil,
        inner_block: [slot({:safe, "<span>Accept</span><strong>terms</strong>"})],
        description: [slot("Help")],
        error: [slot("Error")]
      )

    assert html =~
             ~s(<label id="terms-label" for="terms-input" class=""><span>Accept</span><strong>terms</strong></label>)

    assert html =~ ~s(aria-describedby="terms-description")
    assert html =~ ~s(id="terms-error" class="" hidden)
  end

  test "rejects checkbox-specific invalid composition" do
    for {attrs, message} <- [
          {[id: "bad id"], "checkbox id"},
          {[name: " "], "checkbox name"},
          {[value: "bad value"], "checkbox value"},
          {[label: "\n"], "checkbox label"},
          {[label: nil], "label or inner content"},
          {[inner_block: [slot("a"), slot("b")]], "at most one inner content"},
          {[description: [slot("a"), slot("b")]], "at most one description"},
          {[error: [slot("a"), slot("b")]], "at most one error"}
        ] do
      assert_raise ArgumentError, ~r/#{message}/, fn -> render_checkbox(false, attrs) end
    end
  end

  defp slot(content), do: %{inner_block: fn _, _ -> content end}

  defp opening_tag(html, tag, id) do
    [match] = Regex.run(~r/<#{tag}(?=[^>]*\sid="#{Regex.escape(id)}")[^>]*>/, html)
    match
  end
end
