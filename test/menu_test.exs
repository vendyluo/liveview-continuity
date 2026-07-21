defmodule LiveViewContinuity.MenuTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  test "renders the menu ARIA graph and disabled semantics" do
    html =
      render_component(&LiveViewContinuity.Menu.menu/1,
        id: "account",
        on_action: "menu_action",
        trigger: [%{inner_block: fn _, _ -> "Actions" end}],
        item: [
          %{id: "edit", inner_block: fn _, _ -> "Edit" end},
          %{id: "delete", disabled: true, inner_block: fn _, _ -> "Delete" end}
        ]
      )

    assert html =~ ~s(aria-controls="account-popup")
    assert html =~ ~s(id="account-popup")
    assert html =~ ~s(aria-labelledby="account-trigger")
    assert html =~ ~s(id="account-item-delete")
    assert html =~ ~s(aria-disabled="true")
  end
end
