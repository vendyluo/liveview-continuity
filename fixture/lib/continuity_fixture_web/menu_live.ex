defmodule ContinuityFixtureWeb.MenuLive do
  use Phoenix.LiveView
  import LiveViewContinuity.Menu
  import LiveViewContinuity.Tabs
  import LiveViewContinuity.Dialog
  import LiveViewContinuity.Tooltip

  @base_items [
    %{id: "alpha", label: "Álpha"},
    %{id: "disabled", label: "Disabled", disabled: true},
    %{id: "bravo", label: "Bravo"},
    %{id: "charlie", label: "Charlie", typeahead_text: "Quartz"},
    %{id: "patch", label: "Patch in place", keep_open: true},
    %{id: "reorder", label: "Reorder items", keep_open: true},
    %{id: "remove", label: "Remove Bravo", keep_open: true},
    %{id: "empty", label: "Empty menu", keep_open: true}
  ]

  @base_tabs [
    %{id: "alpha", label: "Alpha"},
    %{id: "disabled", label: "Disabled", disabled: true},
    %{id: "bravo", label: "Bravo"},
    %{id: "charlie", label: "Charlie"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       items: @base_items,
       revision: 0,
       actions: [],
       mode: "base",
       tabs: @base_tabs,
       selected: "alpha",
       tab_revision: 0,
       tab_selections: [],
       tab_mode: "base",
       dialog_open: false,
       dialog_revision: 0,
       dialog_input: true,
       dialog_positive: true,
       dialog_opens: [],
       dialog_closes: [],
       tooltip_revision: 0,
       tooltip_delay: 120,
       tooltip_disabled: false,
       tooltip_present: true,
       tooltip_base: "fixture-help"
     )}
  end

  def render(assigns) do
    ~H"""
    <main>
      <h1>LiveView Continuity Menu fixture</h1>
      <.menu id="fixture-menu" on_action="menu_action" data-revision={@revision}>
        <:trigger>Actions</:trigger>
        <:item
          :for={item <- @items}
          id={item.id}
          disabled={Map.get(item, :disabled, false)}
          close_on_action={!Map.get(item, :keep_open, false)}
          typeahead_text={Map.get(item, :typeahead_text)}
        >
          {item.label}
        </:item>
      </.menu>
      <input id="outside" aria-label="Outside target" />
      <button id="patch" phx-click="patch">Patch</button>
      <button id="reorder" phx-click="reorder">Reorder and rename</button>
      <button id="remove" phx-click="remove">Remove active candidate</button>
      <button id="empty" phx-click="empty">Empty</button>
      <button id="reset" phx-click="reset">Reset</button>
      <output id="revision" data-revision={@revision}>{@revision}</output>
      <output id="mode">{@mode}</output>
      <output id="actions">{Enum.join(@actions, ",")}</output>

      <h2>Tabs fixture</h2>
      <.tab_list
        id="fixture-tabs"
        value={@selected}
        on_select="tabs_select"
        label="Fixture sections"
        data-revision={@tab_revision}
      >
        <:tab
          :for={tab <- @tabs}
          id={tab.id}
          label={tab.label}
          disabled={Map.get(tab, :disabled, false)}
        />
      </.tab_list>
      <.tab_panel
        :for={tab <- @tabs}
        root_id="fixture-tabs"
        id={tab.id}
        active={tab.id == @selected}
      >
        {tab.label} panel content
        <input :if={tab.id == "alpha"} id="tabs-panel-input" aria-label="Panel input" />
      </.tab_panel>
      <input id="tabs-outside" aria-label="Outside tabs" />
      <button id="tabs-patch" phx-click="tabs_patch">Patch tabs</button>
      <button id="tabs-reorder" phx-click="tabs_reorder">Reorder tabs</button>
      <button id="tabs-remove-focused" phx-click="tabs_remove_focused">Remove Bravo</button>
      <button id="tabs-remove-selected" phx-click="tabs_remove_selected">Remove selected</button>
      <button id="tabs-reset" phx-click="tabs_reset">Reset tabs</button>
      <output id="tabs-revision">{@tab_revision}</output>
      <output id="tabs-mode">{@tab_mode}</output>
      <output id="tabs-selected">{@selected}</output>
      <output id="tabs-selections">{Enum.join(@tab_selections, ",")}</output>

      <h2>Dialog fixture</h2>
      <.dialog
        id="fixture-dialog"
        open={@dialog_open}
        on_open="dialog_open"
        on_close="dialog_close"
        initial_focus="#dialog-initial"
        data-revision={@dialog_revision}
        data-lvc-dialog-trigger
      >
        <:trigger>Open dialog</:trigger>
        <:title>Fixture dialog</:title>
        <:description>Native modal conformance fixture</:description>
        <h3 id="dialog-initial" tabindex="-1">Dialog content</h3>
        <button id="dialog-fake-close" type="button" tabindex="-2" data-lvc-dialog-close>Not close</button>
        <fieldset disabled>
          <button id="dialog-disabled-positive" type="button" tabindex="1">Disabled positive</button>
        </fieldset>
        <input :if={@dialog_input} id="dialog-name" aria-label="Dialog name" />
        <button id="dialog-second" type="button">Second control</button>
        <button id="dialog-patch" type="button" phx-click="dialog_patch">Patch dialog</button>
        <button id="dialog-remove-focus" type="button" phx-click="dialog_remove_focus">Remove focused input</button>
        <button :if={@dialog_positive} id="dialog-positive-first" type="button" tabindex="1">Positive tab index</button>
        <button id="dialog-remove-positive" type="button" phx-click="dialog_remove_positive">Remove positive tab index</button>
        <:close>Close dialog</:close>
      </.dialog>
      <button id="dialog-server-open" phx-click="dialog_server_open">Server open</button>
      <button id="dialog-server-close" phx-click="dialog_server_close">Server close</button>
      <button id="dialog-stale-patch" phx-click="dialog_stale_patch">Stale patch</button>
      <button id="dialog-ack-close" phx-click="dialog_ack_close">Acknowledge close</button>
      <button id="dialog-reset" phx-click="dialog_reset">Reset dialog</button>
      <output id="dialog-revision">{@dialog_revision}</output>
      <output id="dialog-opens">{Enum.join(@dialog_opens, ",")}</output>
      <output id="dialog-closes">{Enum.join(@dialog_closes, ",")}</output>

      <h2>Tooltip fixture</h2>
      <span id="fixture-help">Existing description</span>
      <.tooltip
        :if={@tooltip_present}
        id="fixture-tooltip"
        delay={@tooltip_delay}
        disabled={@tooltip_disabled}
        describedby={@tooltip_base}
        data-revision={@tooltip_revision}
      >
        <:trigger><span>Tooltip trigger</span></:trigger>
        Tooltip content revision {@tooltip_revision}
      </.tooltip>
      <button id="tooltip-patch" phx-click="tooltip_patch">Patch tooltip</button>
      <button id="tooltip-delay" phx-click="tooltip_delay">Change tooltip delay</button>
      <button id="tooltip-base" phx-click="tooltip_base">Change base description</button>
      <button id="tooltip-disable" phx-click="tooltip_disable">Disable tooltip</button>
      <button id="tooltip-remove" phx-click="tooltip_remove">Remove tooltip</button>
      <button id="tooltip-reset" phx-click="tooltip_reset">Reset tooltip</button>
      <output id="tooltip-revision">{@tooltip_revision}</output>
    </main>
    """
  end

  def handle_event("menu_action", %{"id" => id}, socket) do
    socket =
      assign(socket,
        actions: socket.assigns.actions ++ [id],
        revision: socket.assigns.revision + 1
      )

    case id do
      "reorder" ->
        items =
          Enum.reverse(socket.assigns.items)
          |> Enum.map(&if(&1.id == "bravo", do: %{&1 | label: "Bravo updated"}, else: &1))

        {:noreply, assign(socket, items: items, mode: "reorder")}

      "remove" ->
        {:noreply,
         assign(socket,
           items: Enum.reject(socket.assigns.items, &(&1.id == "bravo")),
           mode: "remove"
         )}

      "empty" ->
        {:noreply, assign(socket, items: [], mode: "empty")}

      other ->
        {:noreply, assign(socket, mode: other)}
    end
  end

  def handle_event("patch", _, socket), do: revise(socket, socket.assigns.items, "patch")

  def handle_event("reorder", _, socket) do
    items =
      Enum.reverse(socket.assigns.items)
      |> Enum.map(&if(&1.id == "bravo", do: %{&1 | label: "Bravo updated"}, else: &1))

    revise(socket, items, "reorder")
  end

  def handle_event("remove", _, socket),
    do: revise(socket, Enum.reject(socket.assigns.items, &(&1.id == "bravo")), "remove")

  def handle_event("empty", _, socket), do: revise(socket, [], "empty")
  def handle_event("reset", _, socket), do: revise(socket, @base_items, "reset")

  def handle_event("tabs_select", %{"id" => id}, socket) do
    {:noreply,
     assign(socket,
       selected: id,
       tab_selections: socket.assigns.tab_selections ++ [id],
       tab_revision: socket.assigns.tab_revision + 1,
       tab_mode: "select"
     )}
  end

  def handle_event("tabs_patch", _, socket), do: revise_tabs(socket, socket.assigns.tabs, "patch")

  def handle_event("tabs_reorder", _, socket) do
    tabs =
      Enum.reverse(socket.assigns.tabs)
      |> Enum.map(&if(&1.id == "bravo", do: %{&1 | label: "Bravo renamed"}, else: &1))

    revise_tabs(socket, tabs, "reorder")
  end

  def handle_event("tabs_remove_focused", _, socket) do
    revise_tabs(socket, Enum.reject(socket.assigns.tabs, &(&1.id == "bravo")), "remove-focused")
  end

  def handle_event("tabs_remove_selected", _, socket) do
    tabs = Enum.reject(socket.assigns.tabs, &(&1.id == socket.assigns.selected))
    fallback = Enum.find(tabs, &(not Map.get(&1, :disabled, false))).id

    {:noreply,
     assign(socket,
       tabs: tabs,
       selected: fallback,
       tab_revision: socket.assigns.tab_revision + 1,
       tab_mode: "remove-selected"
     )}
  end

  def handle_event("tabs_reset", _, socket) do
    {:noreply,
     assign(socket,
       tabs: @base_tabs,
       selected: "alpha",
       tab_revision: socket.assigns.tab_revision + 1,
       tab_mode: "reset"
     )}
  end

  def handle_event("dialog_open", _, socket) do
    {:noreply,
     assign(socket, dialog_open: true, dialog_opens: socket.assigns.dialog_opens ++ ["open"])}
  end

  def handle_event("dialog_close", %{"reason" => reason}, socket) do
    {:noreply, update(socket, :dialog_closes, &(&1 ++ [reason]))}
  end

  def handle_event("dialog_patch", _, socket),
    do: {:noreply, update(socket, :dialog_revision, &(&1 + 1))}

  def handle_event("dialog_remove_focus", _, socket) do
    {:noreply, socket |> assign(:dialog_input, false) |> update(:dialog_revision, &(&1 + 1))}
  end

  def handle_event("dialog_remove_positive", _, socket),
    do: {:noreply, assign(socket, :dialog_positive, false)}

  def handle_event("dialog_server_open", _, socket),
    do: {:noreply, assign(socket, :dialog_open, true)}

  def handle_event("dialog_server_close", _, socket),
    do: {:noreply, assign(socket, :dialog_open, false)}

  def handle_event("dialog_stale_patch", _, socket),
    do: {:noreply, update(socket, :dialog_revision, &(&1 + 1))}

  def handle_event("dialog_ack_close", _, socket),
    do: {:noreply, assign(socket, :dialog_open, false)}

  def handle_event("dialog_reset", _, socket) do
    {:noreply, assign(socket, dialog_open: false, dialog_input: true, dialog_positive: true)}
  end

  def handle_event("tooltip_patch", _, socket),
    do: {:noreply, update(socket, :tooltip_revision, &(&1 + 1))}

  def handle_event("tooltip_delay", _, socket),
    do: {:noreply, assign(socket, :tooltip_delay, 80)}

  def handle_event("tooltip_base", _, socket),
    do: {:noreply, assign(socket, :tooltip_base, "fixture-help-updated")}

  def handle_event("tooltip_disable", _, socket),
    do: {:noreply, assign(socket, :tooltip_disabled, true)}

  def handle_event("tooltip_remove", _, socket),
    do: {:noreply, assign(socket, :tooltip_present, false)}

  def handle_event("tooltip_reset", _, socket) do
    {:noreply,
     assign(socket,
       tooltip_present: true,
       tooltip_disabled: false,
       tooltip_delay: 120,
       tooltip_base: "fixture-help"
     )}
  end

  defp revise(socket, items, mode) do
    {:noreply, assign(socket, items: items, mode: mode, revision: socket.assigns.revision + 1)}
  end

  defp revise_tabs(socket, tabs, mode) do
    {:noreply,
     assign(socket,
       tabs: tabs,
       tab_mode: mode,
       tab_revision: socket.assigns.tab_revision + 1
     )}
  end
end
