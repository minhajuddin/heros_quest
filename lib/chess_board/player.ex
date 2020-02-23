defmodule ChessBoard.Player do
  use GenServer

  alias ChessBoard.Game

  defstruct name: "", coords: {0, 0}, alive: true, game_pid: nil

  def start_link(name, game_pid) do
    GenServer.start_link(__MODULE__, %__MODULE__{name: name, game_pid: game_pid})
  end

  def init(player) do
    {:ok, player, {:continue, :after_init}}
  end

  def handle_continue(:after_init, player) do
    coords = Game.join(player.game_pid, player.name)
    {:noreply, %{player | coords: coords}}
  end

  def handle_call(:kill, _from, player) do
    {:reply, :ok, %{player | alive: false}}
  end

  def handle_call({:within_reach?, {x, y}}, _from, %__MODULE__{coords: {px, py}} = player) do
    within_reach = abs(px - x) <= 1 && abs(py - y) <= 1
    {:reply, within_reach, player}
  end

  def handle_call({:move, direction}, _from, player) do
    {x, y} = player.coords

    coords =
      case direction do
        :up -> {x, y - 1}
        :down -> {x, y + 1}
        :left -> {x - 1, y}
        :right -> {x + 1, y}
      end

    {:reply, coords, %{player | coords: coords}}
  end

  def handle_call(:get_coords, _from, player) do
    {:reply, player.coords, player}
  end

  def kill(player_pid) do
    GenServer.call(player_pid, :kill)
  end

  def get_coords(player_pid) do
    GenServer.call(player_pid, :get_coords)
  end

  def move(player_pid, direction) do
    GenServer.call(player_pid, {:move, direction})
  end

  def within_reach?(player_pid, coords) do
    GenServer.call(player_pid, {:within_reach?, coords})
  end
end