defmodule LiveViewContinuity.TabsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render(value, tabs, attrs \\ []) do
    render_component(
      &LiveViewContinuity.Tabs.tabs/1,
      Keyword.merge(
        [id: "sections", value: value, on_select: "select", label: "Sections", tab: tabs],
        attrs
      )
    )
  end

  test "renders the complete ARIA graph and mounted panels" do
    html = render("alpha", [slot("alpha", "Alpha"), slot("beta", "Beta", disabled: true)])
    assert html =~ ~s(role="tablist")
    assert html =~ ~s(aria-label="Sections")
    assert html =~ ~s(id="sections-tab-alpha")
    assert html =~ ~s(aria-controls="sections-panel-alpha")
    assert html =~ ~s(aria-labelledby="sections-tab-alpha")
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ ~s(data-lvc-hidden)
    assert html =~ ~s(hidden)
    assert html =~ ~s(inert)
  end

  test "renders a composable tab list and external panel with the same IDREF graph" do
    list =
      render_component(&LiveViewContinuity.Tabs.tab_list/1,
        id: "sections",
        value: "alpha",
        on_select: "select",
        label: "Sections",
        tab: [slot("alpha", "Alpha"), slot("beta", "Beta")]
      )

    panels =
      for {id, active} <- [{"alpha", true}, {"beta", false}] do
        render_component(&LiveViewContinuity.Tabs.tab_panel/1,
          root_id: "sections",
          id: id,
          active: active,
          inner_block: [%{inner_block: fn _, _ -> "#{id} content" end}]
        )
      end

    assert list =~ ~s(id="sections" role="tablist")
    assert list =~ ~s(aria-controls="sections-panel-alpha")
    assert list =~ ~s(aria-controls="sections-panel-beta")
    assert Enum.at(panels, 0) =~ ~s(id="sections-panel-alpha")
    assert Enum.at(panels, 0) =~ ~s(aria-labelledby="sections-tab-alpha")
    refute Enum.at(panels, 0) =~ ~s( hidden)
    refute Enum.at(panels, 0) =~ ~s( inert)
    assert Enum.at(panels, 1) =~ ~s(id="sections-panel-beta")
    assert Enum.at(panels, 1) =~ ~s(aria-labelledby="sections-tab-beta")
    assert Enum.at(panels, 1) =~ ~s( hidden)
    assert Enum.at(panels, 1) =~ ~s( inert)
  end

  test "rejects invalid composition" do
    assert_raise ArgumentError, ~r/at least one tab/, fn -> render("x", []) end

    assert_raise ArgumentError, ~r/unique logical/, fn ->
      render("x", [slot("x", "X"), slot("x", "Again")])
    end

    assert_raise ArgumentError, ~r/existing tab/, fn -> render("missing", [slot("x", "X")]) end

    assert_raise ArgumentError, ~r/cannot identify a disabled/, fn ->
      render("x", [slot("x", "X", disabled: true), slot("y", "Y")])
    end

    assert_raise ArgumentError, ~r/at least one enabled/, fn ->
      render("x", [slot("x", "X", disabled: true)])
    end

    assert_raise ArgumentError, ~r/tabs id/, fn ->
      render("x", [slot("x", "X")], id: "bad id")
    end

    assert_raise ArgumentError, ~r/logical tab id/, fn ->
      render("", [slot("", "X")])
    end

    assert_raise ArgumentError, ~r/logical tab id/, fn ->
      render("bad id", [slot("bad id", "X")])
    end

    assert_raise ArgumentError, ~r/tabs label/, fn ->
      render("x", [slot("x", "X")], label: " \n")
    end

    assert_raise ArgumentError, ~r/tab labels/, fn ->
      render("x", [slot("x", " \t")])
    end
  end

  defp slot(id, label, attrs \\ []) do
    Map.merge(
      %{id: id, label: label, inner_block: fn _, _ -> "#{label} content" end},
      Map.new(attrs)
    )
  end
end
