defmodule ChessBoard.Game do
  use GenServer

  alias ChessBoard.Player

  @custom_wall %{
    {3, 4} => true,
    {4, 4} => true,
    {7, 4} => true,
    {7, 5} => true
  }
  defstruct rows: 10,
            cols: 10,
            players: %{},
            wall:
              for(
                x <- 0..9,
                y <- 0..9,
                x == 0 || y == 0 || x == 9 || y == 9,
                do: {{x, y}, true},
                into: %{}
              )
              |> Map.merge(@custom_wall)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      shutdown: 5_000,
      restart: :permanent,
      type: :worker
    }
  end

  defmodule Tile do
    defstruct [:coords, :players, :walkable?, :color]
  end

  defmodule RenderState do
    defstruct [:rows, :cols, :wall, :players]

    def render(%__MODULE__{} = state) do
      players_map = state.players |> Enum.group_by(fn p -> p.coords end)

      for y <- 0..(state.cols - 1), x <- 0..(state.rows - 1) do
        %Tile{
          coords: {x, y},
          players: players_map[{x, y}],
          walkable?: !state.wall[{x, y}]
        }
      end
    end
  end

  def start_link(opts) do
    name = opts[:name] || __MODULE__
    GenServer.start_link(__MODULE__, [], name: name)
  end

  # Server
  def init(_) do
    :timer.send_interval(5000, self(), :reset_killed_players)
    {:ok, %__MODULE__{}}
  end

  def handle_info(:reset_killed_players, game) do
    game.players
    |> Enum.each(fn {_, p} ->
      Player.reset_if_dead(p, random_coords(game))
    end)

    {:noreply, game}
  end

  defp random_coords(game) do
    coords = {:rand.uniform(game.cols) - 1, :rand.uniform(game.rows) - 1}

    if game.wall[coords] do
      random_coords(game)
    else
      coords
    end
  end

  def handle_call({:join, name}, {from, _ref}, game) do
    random_coords = {3, 3}
    game = %{game | players: Map.put(game.players, name, from)}
    {:reply, random_coords, game}
  end

  def handle_call({:find_or_create_player, name}, _from, game) do
    player = game.players[name]

    {:ok, player} =
      if player do
        {:ok, player}
      else
        ChessBoard.PlayerSup.start_child(name, self())
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
    players =
      game.players
      |> Enum.map(fn {_name, player_pid} -> Player.get_state(player_pid) end)

    {:reply,
     %RenderState{
       rows: game.rows,
       cols: game.cols,
       wall: game.wall,
       players: players
     }, game}
  end

  def handle_call({:walkable?, coords}, _from, game) do
    {:reply, !game.wall[coords], game}
  end

  defp players_in_reach(attacker_pid, game) do
    coords = Player.get_coords(attacker_pid)

    game.players
    |> Enum.filter(fn {_name, player_pid} ->
      player_pid != attacker_pid &&
        Player.within_reach?(player_pid, coords)
    end)
    |> Enum.map(fn {_name, pid} -> pid end)
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
  end

  def walkable?(game \\ __MODULE__, coords) do
    GenServer.call(game, {:walkable?, coords})
  end
end
