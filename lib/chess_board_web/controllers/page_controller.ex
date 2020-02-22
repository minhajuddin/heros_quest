defmodule ChessBoardWeb.PageController do
  use ChessBoardWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
