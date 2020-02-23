defmodule ChessBoard.Game do
  use GenServer

  alias ChessBoard.Player

  defstruct rows: 10, cols: 10, players: %{}

  def start_link(opts) do
    name = opts[:name] || __MODULE__
    GenServer.start_link(__MODULE__, [], name: name)
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

  def handle_call({:find_or_create_player, name}, {from, _ref}, game) do
    player = game.players[name]

    {:ok, player} =
      if player do
        {:ok, player}
      else
        Player.start_link(name, self())
      end

    {:reply, player, game}
  end

  def handle_call({:attack, player_pid}, _from, game) do
    kill_count =
      player_pid
      |> players_in_reach(game)
      |> Enum.map(&Player.kill/1)
      |> Enum.count()

    {:reply, kill_count, game}
  end

  def handle_call(:layout, _from, game) do
    player_coords =
      game.players
      |> Enum.reduce(%{}, fn {name, player_pid}, acc ->
        {coords, alive} = Player.get_state(player_pid)
        players_at_coords = [{name, alive} | acc[coords] || []]
        Map.put(acc, coords, players_at_coords)
      end)

    {:reply, {{game.rows, game.cols}, player_coords}, game}
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

  def attack(game \\ __MODULE__, player_pid) do
    GenServer.call(game, {:attack, player_pid})
  end

  def join(game \\ __MODULE__, name) do
    GenServer.call(game, {:join, name})
  end

  def find_or_create_player(game \\ __MODULE__, name) do
    GenServer.call(game, {:find_or_create_player, name})
  end

  def layout(game \\ __MODULE__) do
    GenServer.call(game, :layout)
    # {{rows, cols}, player_coords} = GenServer.call(game, :player_coords)
    # for x <- 0..cols, y <- 0..rows, do: player_coords[{x, y}] || :blank
  end
end
