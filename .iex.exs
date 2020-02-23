alias ChessBoard.{Game, Player}

start_game = fn ->
  {:ok, game} = Game.start_link()
  {:ok, p1} = Player.start_link("Danny", game)
  {:ok, p2} = Player.start_link("Mujju", game)
  {:ok, p3} = Player.start_link("Maria", game)
  {:ok, game, p1, p2, p3}
end
