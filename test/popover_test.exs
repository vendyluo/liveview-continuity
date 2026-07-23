defmodule LiveViewContinuity.PopoverTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render_popover(attrs) do
    render_component(
      &LiveViewContinuity.Popover.popover/1,
      Keyword.merge(
        [
          id: "picker",
          trigger: [%{inner_block: fn _, _ -> "Choose date" end}],
          inner_block: [%{inner_block: fn _, _ -> "Patchable dates" end}]
        ],
        attrs
      )
    )
  end

  test "renders the native, initially closed, always-mounted ARIA graph" do
    html = render_popover(class: "root", trigger_class: "trigger", popup_class: "popup")
    assert html =~ ~s(id="picker" class="root")
    assert html =~ ~s(data-lvc-open="false")
    assert html =~ ~s(id="picker-trigger")
    assert html =~ ~s(class="trigger")
    assert html =~ ~s(popovertarget="picker-popup")
    assert html =~ ~s(aria-controls="picker-popup")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(id="picker-popup" class="popup" popover="auto")
    assert html =~ ~s(aria-labelledby="picker-trigger")
    assert html =~ "Patchable dates"
  end

  test "allows global attributes on only the root" do
    html = render_popover(rest: %{"data-revision": "2", "aria-label": "Date picker"})
    assert html =~ ~r/id="picker"[^>]*data-revision="2"/
    assert html =~ ~r/id="picker"[^>]*aria-label="Date picker"/
  end

  test "validates ID and exact slot cardinality" do
    assert_raise ArgumentError, ~r/popover id/, fn -> render_popover(id: "bad id") end
    assert_raise ArgumentError, ~r/popover id/, fn -> render_popover(id: nil) end
    assert_raise ArgumentError, ~r/exactly one trigger/, fn -> render_popover(trigger: []) end
    assert_raise ArgumentError, ~r/exactly one body/, fn -> render_popover(inner_block: []) end
  end
end
