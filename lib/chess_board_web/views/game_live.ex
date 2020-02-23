defmodule ChessBoardWeb.GameLive do
  use Phoenix.LiveView

  alias ChessBoard.{Game, Player}

  def render(assigns) do
    ~L"""
    <%= @duration %> <br />
      <div class="board">
        <%= for y <- 0..(@rows-1), x <- 0..(@cols-1) do %>
          <div class="col" style="background-color: <%= color({x, y}, @my_coords, @player_coords[{x, y}]) %>">
            <%= "{#{x}, #{y}}" %> <%= @player_coords[{x, y}] %>
          </div>
        <% end %>
      </div>
    <br />
    <button phx-click=player-move phx-value-direction="left">left</button>
    <button phx-click=player-move phx-value-direction="up">up</button>
    <button phx-click=player-move phx-value-direction="down">down</button>
    <button phx-click=player-move phx-value-direction="right">right</button>
    """
  end

  @empty_cell_color "#ffffff"
  @my_color "#2ECC40"
  @other_players_color "#FF851B"
  defp color(_coords, _my_coords, nil), do: @empty_cell_color
  defp color(coords, coords, _), do: @my_color
  defp color(_, _, _), do: @other_players_color

  def mount(params, %{}, socket) do
    player_pid = Game.find_or_create_player(params["name"] || random_name())

    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    socket = assign(socket, start_time: DateTime.utc_now(), player_pid: player_pid)

    {:ok, update_board(socket)}
  end

  defp random_name(), do: :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)

  def handle_info(:tick, socket) do
    {:noreply, update_board(socket)}
  end

  def handle_event("player-move", value, socket) do
    Player.move(socket.assigns.player_pid, parse_direction(value["direction"]))
    {:noreply, update_board(socket)}
  end

  def parse_direction(direction) do
    %{"up" => :up, "down" => :down, "left" => :left, "right" => :right}[direction]
  end

  defp update_board(socket) do
    current_time = DateTime.utc_now()

    {{rows, cols}, player_coords} = Game.layout()

    assign(socket,
      cols: cols,
      rows: rows,
      player_coords: player_coords,
      my_coords: Player.get_coords(socket.assigns.player_pid),
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
