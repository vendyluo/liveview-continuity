defmodule LiveViewContinuity.TooltipTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render_tooltip(attrs) do
    render_component(
      &LiveViewContinuity.Tooltip.tooltip/1,
      Keyword.merge(
        [
          id: "help",
          trigger: [slot("More information")],
          inner_block: [slot("Helpful details")]
        ],
        attrs
      )
    )
  end

  test "renders the stable manual-popover ARIA graph and class seams" do
    html =
      render_tooltip(
        delay: 25,
        describedby: "existing another",
        class: "root",
        trigger_class: "trigger",
        tooltip_class: "popup",
        "data-test": "root"
      )

    assert html =~ ~s(id="help-trigger")
    assert html =~ ~s(aria-describedby="existing another")
    assert html =~ ~s(id="help-popup")
    assert html =~ ~s(role="tooltip")
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(data-lvc-delay="25")
    assert html =~ ~s(data-lvc-disabled="false")
    assert html =~ ~s(class="root")
    assert html =~ ~s(class="trigger")
    assert html =~ ~s(class="popup")
    assert html =~ ~s(data-test="root")
  end

  test "renders allowed action and accessible-name attributes on the trigger" do
    html =
      render_tooltip(
        trigger_attrs: %{
          "aria-label" => "Remove tag",
          "phx-click" => "remove_tag",
          "phx-target" => "#owner",
          "phx-value-tag-id" => "tag-42",
          "phx-value-source" => "tooltip"
        }
      )

    assert html =~ ~s(aria-label="Remove tag")
    assert html =~ ~s(phx-click="remove_tag")
    assert html =~ ~s(phx-target="#owner")
    assert html =~ ~s(phx-value-tag-id="tag-42")
    assert html =~ ~s(phx-value-source="tooltip")

    [root, trigger] = String.split(html, "<button", parts: 2)
    refute root =~ "remove_tag"
    assert trigger =~ ~s(id="help-trigger")
    assert trigger =~ ~s(type="button")
    assert trigger =~ ~s(data-lvc-tooltip-trigger)
  end

  test "rejects trigger attributes owned by the component or outside the action seam" do
    for name <- [
          "id",
          "type",
          "class",
          "aria-describedby",
          "phx-hook",
          "phx-mounted",
          "data-lvc-tooltip-trigger",
          "disabled",
          "tabindex",
          "phx-disable-with",
          "aria-expanded",
          "phx-value-"
        ] do
      assert_raise ArgumentError, ~r/trigger_attrs only accepts/, fn ->
        render_tooltip(trigger_attrs: %{name => "override"})
      end
    end

    assert_raise ArgumentError, ~r/trigger_attrs must be a map/, fn ->
      render_tooltip(trigger_attrs: ["phx-click": "remove_tag"])
    end

    assert_raise ArgumentError, ~r/duplicate attribute aria-label/, fn ->
      render_tooltip(trigger_attrs: %{:"aria-label" => "one", "aria-label" => "two"})
    end
  end

  test "validates IDs, slot cardinality, delay, and base IDREFs" do
    assert_raise ArgumentError, ~r/tooltip id/, fn -> render_tooltip(id: "bad id") end
    assert_raise ArgumentError, ~r/exactly one trigger/, fn -> render_tooltip(trigger: []) end

    assert_raise ArgumentError, ~r/exactly one body/, fn ->
      render_tooltip(inner_block: [slot("one"), slot("two")])
    end

    assert_raise ArgumentError, ~r/nonnegative integer/, fn -> render_tooltip(delay: -1) end
    assert_raise ArgumentError, ~r/nonnegative integer/, fn -> render_tooltip(delay: 1.5) end
    assert_raise ArgumentError, ~r/IDREF/, fn -> render_tooltip(describedby: "") end
    assert_raise ArgumentError, ~r/IDREF/, fn -> render_tooltip(describedby: "bad\0token") end
  end

  defp slot(content), do: %{inner_block: fn _, _ -> content end}
end
