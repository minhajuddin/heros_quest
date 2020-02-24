defmodule ChessBoard.ModelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias ChessBoard.{Game, Player, Game.RenderState}
    end
  end
end
