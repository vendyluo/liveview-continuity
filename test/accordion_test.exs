defmodule LiveViewContinuity.AccordionTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp slot(id, label, attrs \\ []),
    do:
      Map.merge(
        %{id: id, label: label, inner_block: fn _, _ -> "#{label} body" end},
        Map.new(attrs)
      )

  defp render_accordion(values, items \\ [slot("a", "Alpha"), slot("b", "Bravo")], attrs \\ []) do
    render_component(
      &LiveViewContinuity.Accordion.accordion/1,
      Keyword.merge([id: "faq", values: values, on_change: "change", item: items], attrs)
    )
  end

  test "renders semantic, always-mounted disclosure graph and class seams" do
    html =
      render_accordion(
        ["a"],
        [
          slot("a", "Alpha",
            item_class: "item",
            header_class: "head",
            trigger_class: "button",
            panel_class: "panel"
          ),
          slot("b", "Bravo", disabled: true)
        ],
        heading_level: 2,
        region: true,
        class: "root"
      )

    assert html =~ ~s(id="faq" class="root")
    assert html =~ ~s(<h2 class="head">)
    assert html =~ ~s(id="faq-trigger-a")
    assert html =~ ~s(aria-controls="faq-panel-a")
    assert html =~ ~s(id="faq-panel-a")
    assert html =~ ~s(role="region")
    assert html =~ ~s(aria-labelledby="faq-trigger-a")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ ~s(aria-hidden="true" hidden)
    assert html =~ "Bravo body"
  end

  test "allows all collapsed and an expanded disabled item" do
    assert render_accordion([]) =~ ~s(data-lvc-values="[]")

    assert render_accordion(["a"], [slot("a", "Alpha", disabled: true)]) =~
             ~s(aria-expanded="true")
  end

  test "validates the public contract" do
    assert_raise ArgumentError, ~r/at least one/, fn -> render_accordion([], []) end

    assert_raise ArgumentError, ~r/accordion id/, fn ->
      render_accordion([], [slot("a", "A")], id: "bad id")
    end

    assert_raise ArgumentError, ~r/logical/, fn -> render_accordion([], [slot("bad\n", "A")]) end

    assert_raise ArgumentError, ~r/unique item/, fn ->
      render_accordion([], [slot("a", "A"), slot("a", "Again")])
    end

    assert_raise ArgumentError, ~r/values must be unique/, fn -> render_accordion(["a", "a"]) end
    assert_raise ArgumentError, ~r/existing/, fn -> render_accordion(["missing"]) end
    assert_raise ArgumentError, ~r/at most one/, fn -> render_accordion(["a", "b"]) end
    assert_raise ArgumentError, ~r/non-blank/, fn -> render_accordion([], [slot("a", " \n")]) end

    assert_raise ArgumentError, ~r/between 1 and 6/, fn ->
      render_accordion([], [slot("a", "A")], heading_level: 7)
    end

    assert_raise ArgumentError, ~r/value/, fn ->
      render_accordion(["bad\0id"], [slot("a", "A")])
    end
  end
end
