defmodule LivebookWeb.SessionLive.InsertButtonsComponent do
  use LivebookWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="relative top-0.5 m-0 flex justify-center"
      role="toolbar"
      aria-label="insert new"
      data-element="insert-buttons">
      <div class={"w-full absolute z-10 focus-within:z-[11] #{if(@persistent, do: "opacity-100", else: "opacity-0")} hover:opacity-100 focus-within:opacity-100 flex space-x-2 justify-center items-center"}>
        <button class="button-base button-small"
          phx-click="insert_cell_below"
          phx-value-type="code"
          phx-value-section_id={@section_id}
          phx-value-cell_id={@cell_id}
          >+ Code</button>
        <.menu id={"#{@id}-block-menu"} position="left">
          <:toggle>
            <button class="button-base button-small">+ Block</button>
          </:toggle>
          <:content>
            <button class="menu-item text-gray-500"
              role="menuitem"
              phx-click="insert_cell_below"
              phx-value-type="markdown"
              phx-value-section_id={@section_id}
              phx-value-cell_id={@cell_id}>
              <.remix_icon icon="markdown-fill" />
              <span class="font-medium">Markdown</span>
            </button>
            <button class="menu-item text-gray-500"
              role="menuitem"
              phx-click="insert_section_below"
              phx-value-section_id={@section_id}
              phx-value-cell_id={@cell_id}>
              <.remix_icon icon="h-2" />
              <span class="font-medium">Section</span>
            </button>
          </:content>
        </.menu>
        <%= cond do %>
          <% @runtime == nil -> %>
            <button class="button-base button-small"
              phx-click={
                with_confirm(
                  JS.push("setup_default_runtime"),
                  title: "Setup runtime",
                  description: ~s'''
                  To see the available smart cells, you need to start a runtime.
                  Do you want to start and setup the default one?
                  ''',
                  confirm_text: "Setup runtime",
                  confirm_icon: "play-line",
                  danger: false
                )
              }>+ Smart</button>

          <% @smart_cell_definitions == [] -> %>
            <span class="tooltip right" data-tooltip="No smart cells available">
              <button class="button-base button-small" disabled>+ Smart</button>
            </span>

          <% true -> %>
            <.menu id={"#{@id}-smart-menu"} position="left">
              <:toggle>
                <button class="button-base button-small">+ Smart</button>
              </:toggle>
              <:content>
                <%= for definition <- Enum.sort_by(@smart_cell_definitions, & &1.name) do %>
                  <button class="menu-item text-gray-500"
                    role="menuitem"
                    phx-click={on_smart_cell_click(definition, @section_id, @cell_id)}>
                    <span class="font-medium"><%= definition.name %></span>
                  </button>
                <% end %>
              </:content>
            </.menu>
        <% end %>
      </div>
    </div>
    """
  end

  defp on_smart_cell_click(%{requirement: nil} = definition, section_id, cell_id) do
    insert_smart_cell(definition, section_id, cell_id)
  end

  defp on_smart_cell_click(%{requirement: %{}} = definition, section_id, cell_id) do
    with_confirm(
      JS.push("add_smart_cell_dependencies", value: %{kind: definition.kind})
      |> insert_smart_cell(definition, section_id, cell_id),
      title: "Add package",
      description: ~s'''
      The “#{definition.name}“ smart cell requires #{definition.requirement.name}.
      Do you want to add it as a dependency and restart the runtime?
      ''',
      confirm_text: "Add and restart",
      confirm_icon: "add-line",
      danger: false
    )
  end

  defp insert_smart_cell(js \\ %JS{}, definition, section_id, cell_id) do
    JS.push(js, "insert_cell_below",
      value: %{
        type: "smart",
        kind: definition.kind,
        section_id: section_id,
        cell_id: cell_id
      }
    )
  end
end
