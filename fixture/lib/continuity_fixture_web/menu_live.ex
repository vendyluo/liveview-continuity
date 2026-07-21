defmodule ContinuityFixtureWeb.MenuLive do
  use Phoenix.LiveView
  import LiveViewContinuity.Menu

  @base_items [
    %{id: "alpha", label: "Álpha"},
    %{id: "disabled", label: "Disabled", disabled: true},
    %{id: "bravo", label: "Bravo"},
    %{id: "charlie", label: "Charlie"},
    %{id: "patch", label: "Patch in place", keep_open: true},
    %{id: "reorder", label: "Reorder items", keep_open: true},
    %{id: "remove", label: "Remove Bravo", keep_open: true},
    %{id: "empty", label: "Empty menu", keep_open: true}
  ]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, items: @base_items, revision: 0, actions: [], mode: "base")}
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

  defp revise(socket, items, mode) do
    {:noreply, assign(socket, items: items, mode: mode, revision: socket.assigns.revision + 1)}
  end
end
