defmodule ChessBoard.PlayerSup do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name, game_pid) do
    spec = %{
      id: {ChessBoard.Player, name},
      start: {ChessBoard.Player, :start_link, [name, game_pid]},
      shutdown: 5_000,
      restart: :permanent,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
