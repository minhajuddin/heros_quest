defmodule ChessBoard.Board do
  alias __MODULE__

  defstruct rows: 8, cols: 8, players: %{}

  def add_player(%Board{} = board, name) do
    Map.put(board.players, name, true)
  end
end
