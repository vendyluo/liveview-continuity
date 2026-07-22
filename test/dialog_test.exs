defmodule LiveViewContinuity.DialogTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  defp render_dialog(attrs) do
    render_component(
      &LiveViewContinuity.Dialog.dialog/1,
      Keyword.merge(
        [
          id: "confirm",
          open: false,
          on_open: "open_dialog",
          on_close: "close_dialog",
          trigger: [slot("Open")],
          title: [slot("Confirm action")],
          description: [slot("This is permanent")],
          inner_block: [slot("Body")],
          close: [slot("Close")]
        ],
        attrs
      )
    )
  end

  test "renders a closed native dialog and complete ARIA graph" do
    html = render_dialog(initial_focus: "#name", class: "root", dialog_class: "popup")
    assert html =~ ~s(data-lvc-dialog)
    assert html =~ ~s(data-lvc-desired-open="false")
    assert html =~ ~s(data-lvc-open="false")
    assert html =~ ~s(id="confirm-trigger")
    assert html =~ ~s(aria-controls="confirm-popup")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(<dialog id="confirm-popup" class="popup")
    refute html =~ ~r/<dialog[^>]*\sopen(?:[\s=>])/
    assert html =~ ~s(aria-labelledby="confirm-title")
    assert html =~ ~s(aria-describedby="confirm-description")
    assert html =~ ~s(id="confirm-title")
    assert html =~ ~s(id="confirm-description")
    assert html =~ ~s(data-lvc-dialog-close)
  end

  test "renders server open as intent without an open attribute" do
    html = render_dialog(open: true, description: [])
    assert html =~ ~s(data-lvc-desired-open="true")
    refute html =~ ~r/<dialog[^>]*\sopen(?:[\s=>])/
    refute html =~ "aria-describedby"
  end

  test "renders a controlled dialog without a trigger or open callback" do
    html = render_dialog(trigger: [], on_open: nil, open: true)

    assert html =~ ~s(data-lvc-desired-open="true")
    refute html =~ ~s(id="confirm-trigger")
    refute html =~ "data-lvc-dialog-trigger"
    refute html =~ "data-lvc-on-open"
    refute html =~ "aria-controls"
    refute html =~ "aria-expanded"
  end

  test "requires trigger and on_open to be supplied together" do
    assert_raise ArgumentError, ~r/without a trigger must omit on_open/, fn ->
      render_dialog(trigger: [])
    end

    assert_raise ArgumentError, ~r/with a trigger requires a non-empty on_open/, fn ->
      render_dialog(on_open: nil)
    end

    assert_raise ArgumentError, ~r/with a trigger requires a non-empty on_open/, fn ->
      render_dialog(on_open: "")
    end
  end

  test "rejects unsafe IDs and incorrect slot cardinality" do
    assert_raise ArgumentError, ~r/dialog id/, fn -> render_dialog(id: "bad id") end

    assert_raise ArgumentError, ~r/exactly one trigger/, fn ->
      render_dialog(trigger: [slot("one"), slot("two")])
    end

    assert_raise ArgumentError, ~r/exactly one title/, fn -> render_dialog(title: []) end

    assert_raise ArgumentError, ~r/exactly one description/, fn ->
      render_dialog(description: [slot("one"), slot("two")])
    end

    assert_raise ArgumentError, ~r/exactly one close/, fn -> render_dialog(close: []) end
    assert_raise ArgumentError, ~r/exactly one body/, fn -> render_dialog(inner_block: []) end
  end

  defp slot(content), do: %{inner_block: fn _, _ -> content end}
end
