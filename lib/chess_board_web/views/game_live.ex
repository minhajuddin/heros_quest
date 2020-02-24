defmodule ChessBoardWeb.GameLive do
  use Phoenix.LiveView

  alias ChessBoard.{Game, Player}

  def render(assigns) do
    ~L"""
    Playing as @<%= @name %>
    <%= @duration %> <br />
      <div class="board">
        <%= for tile <- @tiles do %>
          <div class="col <%= color_class(tile, @name) %>" title="Tile <%= inspect tile.coords %> Players: <%= player_names(tile) %>">
          <span class='player-names'> <%= player_count_badge(tile.players) %>
         <%= tile_name(tile, @name) %></span>
          </div>
        <% end %>
      </div>
    <br />
    <button phx-click=player-move phx-value-direction="left">left</button>
    <button phx-click=player-move phx-value-direction="up">up</button>
    <button phx-click=player-move phx-value-direction="down">down</button>
    <button phx-click=player-move phx-value-direction="right">right</button>
    &nbsp;
    &nbsp;
    <button phx-click=player-attack>attack</button>
    """
  end

  def player_count_badge(nil), do: nil
  def player_count_badge([_]), do: nil
  def player_count_badge(players), do: "(#{Enum.count(players)})"

  defp tile_name(%{players: nil}, _my_name), do: nil

  defp tile_name(tile, my_name) do
    if Enum.any?(tile.players, &(&1.name == my_name)) do
      my_name
    else
      tile.players
      |> List.wrap()
      |> Enum.map(fn x -> x.name end)
      |> Enum.join(", ")
    end
  end

  defp player_names(tile) do
    tile.players
    |> List.wrap()
    |> Enum.map(fn x -> x.name end)
    |> Enum.join(", ")
  end

  defp color_class(%{walkable?: false}, _my_name), do: "wall-tile"
  defp color_class(%{players: nil}, _my_name), do: "empty-tile"

  defp color_class(%{players: players}, my_name) do
    my_player = Enum.find(players, &(&1.name == my_name))

    cond do
      my_player && my_player.alive -> "my-tile"
      my_player -> "dead-tile"
      Enum.any?(players, &(!&1.alive)) -> "dead-tile"
      true -> "enemy-tile"
    end
  end

  # @empty_cell_color "#ffffff"
  # @my_alive_color "#2ECC40"
  # @my_dead_color "#FF4136"
  # @other_player_color "#FF851B"
  # defp color(_coords, _my_coords, nil), do: @empty_cell_color
  # defp color(coords, coords, [{_, true} | _]), do: @my_alive_color
  # defp color(coords, coords, _), do: @my_dead_color
  # defp color(_, _, _), do: @other_player_color

  def mount(params, %{}, socket) do
    player_pid = Game.find_or_create_player(params["name"] || random_name())

    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    socket =
      assign(socket,
        start_time: DateTime.utc_now(),
        player_pid: player_pid,
        name: Player.get_state(player_pid).name
      )

    {:ok, update_board(socket)}
  end

  def unmount(%{id: id}, _reason) do
    IO.puts("view #{id} unmounted")
    :ok
  end

  defp random_name(), do: :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)

  def handle_info(:tick, socket) do
    {:noreply, update_board(socket)}
  end

  def handle_event("player-move", value, socket) do
    Player.move(socket.assigns.player_pid, parse_direction(value["direction"]))
    {:noreply, update_board(socket)}
  end

  def handle_event("player-attack", _value, socket) do
    Game.attack(socket.assigns.player_pid)
    {:noreply, update_board(socket)}
  end

  def handle_event(event, _value, socket) do
    IO.inspect(event, label: "PHX-EVENT")
    {:noreply, socket}
  end

  def parse_direction(direction) do
    %{"up" => :up, "down" => :down, "left" => :left, "right" => :right}[direction]
  end

  defp update_board(socket) do
    current_time = DateTime.utc_now()

    tiles = Game.layout() |> Game.RenderState.render()

    assign(socket,
      tiles: tiles,
      duration: duration(socket.assigns.start_time),
      current_time: current_time
    )
  end

  defp duration(start_time) do
    duration = DateTime.diff(DateTime.utc_now(), start_time)

    cond do
      duration > 60 * 60 ->
        "#{div(duration, 60 * 60)} hours"

      duration > 60 ->
        "#{div(duration, 60)} minutes"

      true ->
        "#{duration} seconds"
    end
  end
end
