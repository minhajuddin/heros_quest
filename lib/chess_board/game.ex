defmodule ChessBoard.Game do
  use GenServer

  alias ChessBoard.Player

  defstruct rows: 8, cols: 8, players: %{}

  def add_player(%__MODULE__{} = board, name) do
    Map.put(board.players, name, true)
  end

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  # Server
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:join, name}, {from, _ref}, game) do
    random_coords = {3, 3}
    game = %{game | players: Map.put(game.players, name, from)}
    {:reply, random_coords, game}
  end

  def handle_call({:attack, player_pid}, _from, game) do
    kill_count =
      player_pid
      |> players_in_reach(game)
      |> Enum.map(&Player.kill/1)
      |> Enum.count()

    {:reply, kill_count, game}
  end

  defp players_in_reach(attacker_pid, game) do
    coords = Player.get_coords(attacker_pid)

    game.players
    |> Enum.filter(fn {name, player_pid} ->
      player_pid != attacker_pid &&
        Player.within_reach?(player_pid, coords)
    end)
    |> Enum.map(fn {name, pid} -> pid end)
  end

  # Client
  # move player
  def move_player(name, direction) do
  end

  def attack(game, player_pid) do
    GenServer.call(game, {:attack, player_pid})
  end

  def join(game, name) do
    GenServer.call(game, {:join, name})
  end
end