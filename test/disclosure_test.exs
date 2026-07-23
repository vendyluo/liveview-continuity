defmodule LiveViewContinuity.DisclosureTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render_disclosure(attrs) do
    render_component(
      &LiveViewContinuity.Disclosure.disclosure/1,
      Keyword.merge(
        [
          id: "details",
          trigger: [%{class: "trigger", inner_block: fn _, _ -> "Show details" end}],
          inner_block: [%{inner_block: fn _, _ -> "Patchable content" end}]
        ],
        attrs
      )
    )
  end

  test "renders a collapsed, always-mounted disclosure graph" do
    html = render_disclosure(class: "root", panel_class: "panel")

    assert html =~ ~s(id="details" class="root")
    assert html =~ ~s(data-lvc-open="false")
    assert html =~ ~s(id="details-trigger")
    assert html =~ ~s(class="trigger")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="details-panel")
    assert html =~ ~s(id="details-panel" class="panel")
    assert html =~ ~s(aria-labelledby="details-trigger")
    assert html =~ ~s(aria-hidden="true" hidden)
    assert html =~ "Patchable content"
  end

  test "renders default expanded only as the initial state" do
    html = render_disclosure(default_expanded: true)

    assert html =~ ~s(data-lvc-open="true")
    assert html =~ ~s(aria-expanded="true")
    assert html =~ ~s(aria-hidden="false")
    refute html =~ ~r/id="details-panel"[^>]*\shidden(?:[\s=>])/
  end

  test "validates ID and slot cardinality" do
    assert_raise ArgumentError, ~r/disclosure id/, fn -> render_disclosure(id: "bad id") end
    assert_raise ArgumentError, ~r/disclosure id/, fn -> render_disclosure(id: nil) end

    assert_raise ArgumentError, ~r/exactly one trigger/, fn ->
      render_disclosure(trigger: [])
    end

    assert_raise ArgumentError, ~r/exactly one trigger/, fn ->
      render_disclosure(
        trigger: [
          %{inner_block: fn _, _ -> "one" end},
          %{inner_block: fn _, _ -> "two" end}
        ]
      )
    end

    assert_raise ArgumentError, ~r/exactly one body/, fn ->
      render_disclosure(inner_block: [])
    end
  end
end
