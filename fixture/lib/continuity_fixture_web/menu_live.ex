defmodule ContinuityFixtureWeb.MenuLive do
  use Phoenix.LiveView
  import LiveViewContinuity.Menu
  import LiveViewContinuity.Tabs
  import LiveViewContinuity.Dialog
  import LiveViewContinuity.Tooltip
  import LiveViewContinuity.Accordion
  import LiveViewContinuity.Disclosure
  import LiveViewContinuity.Popover
  import LiveViewContinuity.RadioGroup
  import LiveViewContinuity.Switch

  @base_items [
    %{id: "alpha", label: "Álpha"},
    %{id: "disabled", label: "Disabled", disabled: true},
    %{id: "bravo", label: "Bravo"},
    %{id: "charlie", label: "Charlie", typeahead_text: "Quartz"},
    %{id: "patch", label: "Patch in place", keep_open: true},
    %{id: "reorder", label: "Reorder items", keep_open: true},
    %{id: "remove", label: "Remove Bravo", keep_open: true},
    %{
      id: "disabled-destination",
      label: "Unavailable destination",
      navigate: "/destination",
      disabled: true
    },
    %{
      id: "destination",
      label: "Destination",
      navigate: "/destination",
      typeahead_text: "Go destination"
    },
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
       controlled_dialog_open: false,
       controlled_dialog_revision: 0,
       controlled_dialog_closes: [],
       disclosure_revision: 0,
       popover_revision: 0,
       popover_actions: 0,
       tooltip_revision: 0,
       tooltip_delay: 120,
       tooltip_disabled: false,
       tooltip_present: true,
       tooltip_base: "fixture-help",
       action_tooltip_revision: 0,
       action_tooltip_events: [],
       action_tooltip_barrier: 0,
       accordion_items: [
         %{id: "shipping", label: "Shipping"},
         %{id: "disabled", label: "Unavailable", disabled: true},
         %{id: "returns", label: "Returns"}
       ],
       accordion_values: ["shipping"],
       accordion_multiple_values: [],
       accordion_revision: 0,
       accordion_events: [],
       accordion_multiple_events: [],
       radio_options: [
         %{value: "email", label: "Email"},
         %{value: "phone", label: "Phone"},
         %{value: "disabled", label: "Disabled", disabled: true},
         %{value: "mail", label: "Mail"}
       ],
       radio_value: "email",
       radio_read_only: false,
       radio_disabled: false,
       radio_revision: 0,
       radio_events: [],
       switch_checked: true,
       switch_read_only: false,
       switch_disabled: false,
       switch_external_checked: true,
       switch_revision: 0,
       switch_events: []
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
          navigate={Map.get(item, :navigate)}
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

      <h2>Disclosure fixture</h2>
      <.disclosure id="fixture-disclosure" data-revision={@disclosure_revision}>
        <:trigger>Show disclosure details</:trigger>
        Disclosure content revision {@disclosure_revision}
        <input id="disclosure-panel-input" aria-label="Disclosure panel input" />
      </.disclosure>
      <.disclosure id="fixture-disclosure-default-open" default_expanded>
        <:trigger>Default-open disclosure</:trigger>
        Default-open content
      </.disclosure>
      <input id="disclosure-outside" aria-label="Outside disclosure" />
      <button id="disclosure-patch" phx-click="disclosure_patch">Patch disclosure</button>

      <h2>Popover fixture</h2>
      <.popover id="fixture-popover" data-revision={@popover_revision}>
        <:trigger>Choose a date</:trigger>
        <p id="popover-content">Popover content revision {@popover_revision}</p>
        <input id="popover-input" aria-label="Popover retained input" />
        <button id="popover-inner-patch" phx-click="popover_patch">Patch in place</button>
        <button id="popover-close-action" phx-click="popover_action" data-lvc-popover-close>
          Done
        </button>
      </.popover>
      <input id="popover-outside" aria-label="Outside popover" />
      <button id="popover-patch" phx-click="popover_patch">Patch popover</button>
      <output id="popover-actions">{@popover_actions}</output>

      <h2>Accordion fixture</h2>
      <.accordion
        id="fixture-accordion"
        values={@accordion_values}
        on_change="accordion_change"
        data-revision={@accordion_revision}
      >
        <:item
          :for={item <- @accordion_items}
          id={item.id}
          label={item.label}
          disabled={Map.get(item, :disabled, false)}
        >
          {item.label} content revision {@accordion_revision}
          <input
            :if={item.id == "shipping"}
            id="accordion-panel-input"
            aria-label="Accordion panel input"
          />
          <.accordion
            :if={item.id == "shipping"}
            id="fixture-accordion-multiple"
            values={@accordion_multiple_values}
            on_change="accordion_multiple_change"
            multiple
          >
            <:item id="one" label="One">One content</:item>
            <:item id="two" label="Two">Two content</:item>
          </.accordion>
          <output :if={item.id == "shipping"} id="accordion-multiple-events">
            {length(@accordion_multiple_events)}
          </output>
        </:item>
      </.accordion>
      <input id="accordion-outside" aria-label="Outside accordion" />
      <button id="accordion-patch" phx-click="accordion_patch">Patch accordion</button>
      <button id="accordion-reorder" phx-click="accordion_reorder">Reorder accordion</button>
      <button id="accordion-insert" phx-click="accordion_insert">Insert accordion item</button>
      <button id="accordion-remove" phx-click="accordion_remove">Remove Returns</button>
      <button id="accordion-server-close" phx-click="accordion_server_close">Server close</button>
      <button id="accordion-reset" phx-click="accordion_reset">Reset accordion</button>
      <output id="accordion-events">{Enum.map_join(@accordion_events, ";", fn {id, open, values} ->
        "#{id}:#{open}:#{Enum.join(values, ",")}"
      end)}</output>

      <h2>Radio Group fixture</h2>
      <form id="radio-form">
        <input id="radio-sibling" value="original" />
        <.radio_group
          id="fixture-radio"
          name="contact"
          value={@radio_value}
          on_change="radio_change"
          label="Contact method"
          required
          read_only={@radio_read_only}
          disabled={@radio_disabled}
          data-revision={@radio_revision}
        >
          <:description>Choose one contact method.</:description>
          <:option
            :for={option <- @radio_options}
            value={option.value}
            disabled={Map.get(option, :disabled, false)}
          >
            <span>{option.label}</span>
            <span :if={option.value == "phone"} data-rich-label-count>2</span>
          </:option>
        </.radio_group>
        <button id="radio-native-reset" type="reset">Reset form</button>
      </form>
      <form id="radio-external-form">
        <input id="radio-external-sibling" value="original" />
        <button id="radio-external-reset" type="reset">Reset external form</button>
      </form>
      <.radio_group
        id="fixture-radio-external"
        name="external_contact"
        value="phone"
        on_change="radio_change"
        label="External contact method"
        form="radio-external-form"
        read_only
      >
        <:option value="email" label="Email" />
        <:option value="phone" label="Phone" />
      </.radio_group>
      <input id="radio-outside" />
      <button id="radio-patch" phx-click="radio_patch">Patch radio</button>
      <button id="radio-reorder" phx-click="radio_reorder">Reorder radio</button>
      <button id="radio-insert" phx-click="radio_insert">Insert radio</button>
      <button id="radio-remove" phx-click="radio_remove">Remove selected</button>
      <button id="radio-server-nil" phx-click="radio_server_nil">Server nil</button>
      <button id="radio-read-only" phx-click="radio_read_only">Read only</button>
      <button id="radio-disable" phx-click="radio_disable">Disable</button>
      <button id="radio-reset" phx-click="radio_reset">Reset radio fixture</button>
      <output id="radio-events">{Enum.map_join(
        @radio_events,
        ",",
        &if(&1 == nil, do: "nil", else: &1)
      )}</output>

      <h2>Switch fixture</h2>
      <form id="switch-form">
        <input id="switch-sibling" value="original" />
        <.switch
          id="fixture-switch"
          name="notifications"
          value="enabled"
          checked={@switch_checked}
          on_change="switch_change"
          read_only={@switch_read_only}
          disabled={@switch_disabled}
          data-revision={@switch_revision}
        >
          <span>Notifications</span>
          <span data-switch-label-state>{if @switch_checked, do: "On", else: "Off"}</span>
          <:description>Receive notifications.</:description>
        </.switch>
        <button id="switch-native-reset" type="reset">Reset switch form</button>
      </form>
      <form id="switch-external-form">
        <input id="switch-external-sibling" value="original" />
        <button id="switch-external-reset" type="reset">Reset external switch form</button>
      </form>
      <.switch
        id="fixture-switch-external"
        name="external_notifications"
        checked={@switch_external_checked}
        on_change="switch_change"
        form="switch-external-form"
        label="External notifications"
        read_only
      />
      <button id="switch-patch" phx-click="switch_patch">Patch switch</button>
      <button id="switch-server-false" phx-click="switch_server_false">Server false</button>
      <button id="switch-read-only" phx-click="switch_read_only">Read only switch</button>
      <button id="switch-disable" phx-click="switch_disable">Disable switch</button>
      <button id="switch-external-false" phx-click="switch_external_false">External false</button>
      <button id="switch-reset" phx-click="switch_reset">Reset switch fixture</button>
      <output id="switch-events">{Enum.map_join(@switch_events, ",", &to_string/1)}</output>

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

      <h2>Controlled dialog fixture</h2>
      <button id="controlled-dialog-open" phx-click="controlled_dialog_open">
        Open controlled dialog
      </button>
      <.dialog
        id="controlled-dialog"
        open={@controlled_dialog_open}
        on_close="controlled_dialog_close"
        initial_focus="#controlled-dialog-initial"
        data-revision={@controlled_dialog_revision}
      >
        <:title>Controlled fixture dialog</:title>
        <:description>Server-opened native modal conformance fixture</:description>
        <h3 id="controlled-dialog-initial" tabindex="-1">Controlled content</h3>
        <button id="controlled-dialog-patch" type="button" phx-click="controlled_dialog_patch">
          Patch controlled dialog
        </button>
        <:close>Close controlled dialog</:close>
      </.dialog>
      <output id="controlled-dialog-closes">{Enum.join(@controlled_dialog_closes, ",")}</output>

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

      <.tooltip
        id="fixture-action-tooltip"
        delay={0}
        trigger_attrs={
          %{
            "aria-label" => "Remove fixture record",
            "phx-click" => "tooltip_action",
            "phx-value-id" => "record-42",
            "phx-value-source" => "action-tooltip"
          }
        }
        data-revision={@action_tooltip_revision}
      >
        <:trigger><span aria-hidden="true">×</span></:trigger>
        Remove fixture record
      </.tooltip>
      <output id="action-tooltip-events">{Enum.join(@action_tooltip_events, ",")}</output>
      <button id="action-tooltip-barrier" phx-click="tooltip_action_barrier">Action barrier</button>
      <output id="action-tooltip-barrier-revision">{@action_tooltip_barrier}</output>
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

  def handle_event("accordion_change", %{"id" => id, "open" => open, "values" => values}, socket)
      when is_boolean(open) and is_list(values) do
    known = MapSet.new(socket.assigns.accordion_items, & &1.id)

    if id not in known or Enum.any?(values, &(&1 not in known)),
      do: raise(ArgumentError, "unknown accordion ID")

    {:noreply,
     assign(socket,
       accordion_values: values,
       accordion_events: socket.assigns.accordion_events ++ [{id, open, values}]
     )}
  end

  def handle_event(
        "accordion_multiple_change",
        %{"id" => id, "open" => open, "values" => values},
        socket
      )
      when id in ["one", "two"] and is_boolean(open) and is_list(values) do
    if Enum.any?(values, &(&1 not in ["one", "two"])),
      do: raise(ArgumentError, "unknown multiple accordion ID")

    {:noreply,
     assign(socket,
       accordion_multiple_values: values,
       accordion_multiple_events:
         socket.assigns.accordion_multiple_events ++
           [
             {id, open, values}
           ]
     )}
  end

  def handle_event("accordion_patch", _, socket),
    do: {:noreply, update(socket, :accordion_revision, &(&1 + 1))}

  def handle_event("disclosure_patch", _, socket),
    do: {:noreply, update(socket, :disclosure_revision, &(&1 + 1))}

  def handle_event("popover_patch", _, socket),
    do: {:noreply, update(socket, :popover_revision, &(&1 + 1))}

  def handle_event("popover_action", _, socket),
    do:
      {:noreply,
       socket
       |> update(:popover_actions, &(&1 + 1))
       |> update(:popover_revision, &(&1 + 1))}

  def handle_event("accordion_reorder", _, socket),
    do:
      {:noreply,
       socket
       |> update(
         :accordion_items,
         &(Enum.reverse(&1)
           |> Enum.map(fn item ->
             if item.id == "returns", do: %{item | label: "Returns renamed"}, else: item
           end))
       )
       |> update(:accordion_revision, &(&1 + 1))}

  def handle_event("accordion_insert", _, socket),
    do:
      {:noreply,
       socket
       |> update(:accordion_items, fn items ->
         if Enum.any?(items, &(&1.id == "billing")),
           do: items,
           else: [%{id: "billing", label: "Billing"} | items]
       end)
       |> update(:accordion_revision, &(&1 + 1))}

  def handle_event("accordion_remove", _, socket),
    do:
      {:noreply,
       socket
       |> update(:accordion_items, &Enum.reject(&1, fn item -> item.id == "returns" end))
       |> update(:accordion_values, &Enum.reject(&1, fn id -> id == "returns" end))
       |> update(:accordion_revision, &(&1 + 1))}

  def handle_event("accordion_server_close", _, socket),
    do:
      {:noreply,
       socket |> assign(:accordion_values, []) |> update(:accordion_revision, &(&1 + 1))}

  def handle_event("accordion_reset", _, socket),
    do:
      {:noreply,
       assign(socket,
         accordion_items: [
           %{id: "shipping", label: "Shipping"},
           %{id: "disabled", label: "Unavailable", disabled: true},
           %{id: "returns", label: "Returns"}
         ],
         accordion_values: ["shipping"],
         accordion_multiple_values: [],
         accordion_events: [],
         accordion_multiple_events: [],
         accordion_revision: socket.assigns.accordion_revision + 1
       )}

  def handle_event("dialog_close", %{"reason" => reason}, socket) do
    {:noreply, update(socket, :dialog_closes, &(&1 ++ [reason]))}
  end

  def handle_event("controlled_dialog_open", _, socket),
    do: {:noreply, assign(socket, :controlled_dialog_open, true)}

  def handle_event("controlled_dialog_close", %{"reason" => reason}, socket) do
    {:noreply,
     assign(socket,
       controlled_dialog_open: false,
       controlled_dialog_closes: socket.assigns.controlled_dialog_closes ++ [reason]
     )}
  end

  def handle_event("controlled_dialog_patch", _, socket),
    do: {:noreply, update(socket, :controlled_dialog_revision, &(&1 + 1))}

  def handle_event("radio_change", %{"value" => value}, socket)
      when is_binary(value) or is_nil(value) do
    known = Enum.map(socket.assigns.radio_options, & &1.value)
    if value != nil and value not in known, do: raise(ArgumentError, "unknown radio value")

    {:noreply,
     assign(socket,
       radio_value: value,
       radio_events: socket.assigns.radio_events ++ [value]
     )}
  end

  def handle_event("radio_patch", _, socket),
    do: {:noreply, update(socket, :radio_revision, &(&1 + 1))}

  def handle_event("radio_reorder", _, socket),
    do:
      {:noreply,
       socket
       |> update(
         :radio_options,
         &(Enum.reverse(&1)
           |> Enum.map(fn option ->
             if option.value == "phone", do: %{option | label: "Telephone"}, else: option
           end))
       )
       |> update(:radio_revision, &(&1 + 1))}

  def handle_event("radio_insert", _, socket),
    do:
      {:noreply,
       socket
       |> update(:radio_options, fn options ->
         if Enum.any?(options, &(&1.value == "chat")),
           do: options,
           else: options ++ [%{value: "chat", label: "Chat"}]
       end)
       |> update(:radio_revision, &(&1 + 1))}

  def handle_event("radio_remove", _, socket),
    do:
      {:noreply,
       socket
       |> update(
         :radio_options,
         &Enum.reject(&1, fn option -> option.value == socket.assigns.radio_value end)
       )
       |> assign(:radio_value, nil)
       |> update(:radio_revision, &(&1 + 1))}

  def handle_event("radio_server_nil", _, socket),
    do: {:noreply, socket |> assign(:radio_value, nil) |> update(:radio_revision, &(&1 + 1))}

  def handle_event("radio_read_only", _, socket),
    do: {:noreply, socket |> assign(:radio_read_only, true) |> update(:radio_revision, &(&1 + 1))}

  def handle_event("radio_disable", _, socket),
    do: {:noreply, socket |> assign(:radio_disabled, true) |> update(:radio_revision, &(&1 + 1))}

  def handle_event("radio_reset", _, socket) do
    {:noreply,
     assign(socket,
       radio_options: [
         %{value: "email", label: "Email"},
         %{value: "phone", label: "Phone"},
         %{value: "disabled", label: "Disabled", disabled: true},
         %{value: "mail", label: "Mail"}
       ],
       radio_value: "email",
       radio_read_only: false,
       radio_disabled: false,
       radio_events: [],
       radio_revision: socket.assigns.radio_revision + 1
     )}
  end

  def handle_event("switch_change", %{"checked" => checked}, socket)
      when is_boolean(checked) do
    {:noreply,
     assign(socket,
       switch_checked: checked,
       switch_events: socket.assigns.switch_events ++ [checked]
     )}
  end

  def handle_event("switch_patch", _, socket),
    do: {:noreply, update(socket, :switch_revision, &(&1 + 1))}

  def handle_event("switch_server_false", _, socket),
    do:
      {:noreply, socket |> assign(:switch_checked, false) |> update(:switch_revision, &(&1 + 1))}

  def handle_event("switch_read_only", _, socket),
    do:
      {:noreply, socket |> assign(:switch_read_only, true) |> update(:switch_revision, &(&1 + 1))}

  def handle_event("switch_disable", _, socket),
    do:
      {:noreply, socket |> assign(:switch_disabled, true) |> update(:switch_revision, &(&1 + 1))}

  def handle_event("switch_external_false", _, socket),
    do: {:noreply, assign(socket, :switch_external_checked, false)}

  def handle_event("switch_reset", _, socket) do
    {:noreply,
     assign(socket,
       switch_checked: true,
       switch_read_only: false,
       switch_disabled: false,
       switch_external_checked: true,
       switch_events: [],
       switch_revision: socket.assigns.switch_revision + 1
     )}
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

  def handle_event(
        "tooltip_action",
        %{"id" => "record-42", "source" => "action-tooltip"},
        socket
      ) do
    {:noreply,
     assign(socket,
       action_tooltip_events: socket.assigns.action_tooltip_events ++ ["record-42"],
       action_tooltip_revision: socket.assigns.action_tooltip_revision + 1
     )}
  end

  def handle_event("tooltip_action_barrier", _params, socket),
    do: {:noreply, update(socket, :action_tooltip_barrier, &(&1 + 1))}

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
