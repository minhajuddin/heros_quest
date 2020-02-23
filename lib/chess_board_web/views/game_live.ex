defmodule ChessBoardWeb.GameLive do
  use Phoenix.LiveView

  alias ChessBoard.{Game, Player}

  def render(assigns) do
    ~L"""
    <%= @duration %> <br />
      <div class="board">
        <%= for y <- 0..(@rows-1), x <- 0..(@cols-1) do %>
          <div class="col" style="background-color: <%= color({x, y}, @my_coords, @player_coords[{x, y}]) %>">
            <%= "#{inspect({x, y})}" %>
          <%= (@player_coords[{x, y}] || []) |> Enum.map(fn {name, _alive} -> name end) |> Enum.join(", ")%>
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

  @empty_cell_color "#ffffff"
  @my_alive_color "#2ECC40"
  @my_dead_color "#FF4136"
  @other_player_color "#FF851B"
  defp color(_coords, _my_coords, nil), do: @empty_cell_color
  defp color(coords, coords, [{_, true} | _]), do: @my_alive_color
  defp color(coords, coords, _), do: @my_dead_color
  defp color(_, _, _), do: @other_player_color

  def mount(params, %{}, socket) do
    player_pid = Game.find_or_create_player(params["name"] || random_name())

    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    socket = assign(socket, start_time: DateTime.utc_now(), player_pid: player_pid)

    LiveMonitor.monitor(self(), __MODULE__, %{id: socket.id})

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

defmodule LiveMonitor do
  use GenServer

  def monitor(pid, view_module, meta) do
    GenServer.call(pid, {:monitor, pid, view_module, meta})
  end

  def init(_) do
    {:ok, %{views: %{}}}
  end

  def handle_call({:monitor, pid, view_module}, _, %{views: views} = state) do
    Process.monitor(pid)
    {:reply, :ok, %{state | views: Map.put(views, pid, {view_module, :meta})}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    {{module, meta}, new_views} = Map.pop(state.views)
    # should wrap in isolated task or rescue from exception
    module.unmount(reason, meta)
    {:noreply, %{state | views: new_views}}
  end
end
