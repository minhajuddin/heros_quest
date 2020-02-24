defmodule ChessBoardWeb.RenderStateTest do
  use ChessBoard.ModelCase

  describe "render" do
    test "returns correct number of tiles" do
      state = %RenderState{rows: 3, cols: 5, wall: [], players: []}
      tiles = RenderState.render(state)
      assert Enum.count(tiles) == 3 * 5
    end
  end
end
