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
