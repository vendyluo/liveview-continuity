defmodule LiveViewContinuity.MenuTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  test "renders the menu ARIA graph and disabled semantics" do
    html =
      render_component(&LiveViewContinuity.Menu.menu/1,
        id: "account",
        on_action: "menu_action",
        trigger: [%{class: "account-trigger", inner_block: fn _, _ -> "Actions" end}],
        item: [
          %{id: "edit", inner_block: fn _, _ -> "Edit" end},
          %{id: "settings", navigate: "/settings", inner_block: fn _, _ -> "Settings" end},
          %{
            id: "reports",
            navigate: "/reports",
            disabled: true,
            inner_block: fn _, _ -> "Reports" end
          },
          %{id: "delete", disabled: true, inner_block: fn _, _ -> "Delete" end}
        ]
      )

    assert html =~ ~s(aria-controls="account-popup")
    assert html =~ ~s(id="account-popup")
    assert html =~ ~s(aria-labelledby="account-trigger")
    assert html =~ ~s(id="account-item-delete")
    assert html =~ ~s(aria-disabled="true")
    assert html =~ ~s(class="account-trigger")
    assert html =~ ~s(data-lvc-open="false")

    assert html =~ ~s(<a href="/settings" data-phx-link="redirect" data-phx-link-state="push")
    assert html =~ ~s(id="account-item-settings" role="menuitem")

    assert html =~
             ~s(<a id="account-item-reports" role="menuitem" tabindex="-1" aria-disabled="true")

    assert html =~ ~s(<button id="account-item-edit" type="button" role="menuitem")

    [_before, disabled_navigation] = String.split(html, ~s(id="account-item-reports"), parts: 2)
    disabled_navigation = disabled_navigation |> String.split("</a>", parts: 2) |> hd()
    refute disabled_navigation =~ "href="
    refute disabled_navigation =~ "data-phx-link"
  end

  test "rejects invalid navigation item combinations" do
    for item <- [
          %{id: "empty", navigate: "", inner_block: fn _, _ -> "Empty" end},
          %{
            id: "persistent",
            navigate: "/settings",
            close_on_action: false,
            inner_block: fn _, _ -> "Persistent" end
          }
        ] do
      assert_raise ArgumentError, fn ->
        render_component(&LiveViewContinuity.Menu.menu/1,
          id: "account",
          on_action: "menu_action",
          trigger: [%{inner_block: fn _, _ -> "Actions" end}],
          item: [item]
        )
      end
    end
  end
end
