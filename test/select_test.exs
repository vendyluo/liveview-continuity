defmodule LiveViewContinuity.SelectTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render_select(attrs) do
    render_component(
      &LiveViewContinuity.Select.select/1,
      Keyword.merge(
        [
          id: "choice",
          name: "choice",
          value: "a",
          on_change: "change",
          label: "Choice",
          option: [slot("a", "Alpha"), slot("b", "Bravo")]
        ],
        attrs
      )
    )
  end

  test "renders custom listbox and native form bridge" do
    html =
      render_select(
        required: true,
        form: "form",
        description: [content("Help")],
        rest: %{"phx-target": "1"}
      )

    assert html =~ ~s(aria-haspopup="listbox")
    assert html =~ ~s(role="combobox")
    assert html =~ ~s(aria-required="true")
    assert html =~ ~s(role="listbox")
    assert html =~ ~s(role="option")
    assert html =~ ~s(<select id="choice-native" name="choice" form="form")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ ~s(style="position:absolute;width:1px;height:1px;)
    assert html =~ ~s(data-lvc-placeholder="")
    assert html =~ ~s(phx-target="1")
  end

  test "validates composition" do
    assert_raise ArgumentError, ~r/unique/, fn ->
      render_select(option: [slot("a", "A"), slot("a", "Again")])
    end

    assert_raise ArgumentError, ~r/match an option/, fn -> render_select(value: "missing") end
    assert_raise ArgumentError, ~r/label/, fn -> render_select(label: " ") end

    for id <- ["", "has space", "has\ttab", "has\nnewline", "nul\0"] do
      assert_raise ArgumentError, ~r/select id/, fn -> render_select(id: id) end
    end

    assert render_select(value: "a b", option: [slot("a b", "Spaced")]) =~
             ~s(id="choice-option-YSBi")
  end

  test "normalizes an empty form value to no selection" do
    html = render_select(value: "", required: true, placeholder: "Choose")

    assert html =~ ~s(data-lvc-desired-has-value="false")
    assert html =~ ~s(data-lvc-has-value="false")
    assert html =~ ~s(<option value="" selected></option>)
    refute html =~ ~s(data-lvc-desired-value="")
  end

  defp slot(value, label), do: %{value: value, inner_block: fn _, _ -> label end}
  defp content(value), do: %{inner_block: fn _, _ -> value end}
end
