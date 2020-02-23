defmodule ChessBoardWeb.GameLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <%= @duration %> <br />
      <div class="board">
        <%= for _ <- 1..100 do %>
          <div class="col" style="background-color: <%=color(@current_time) %>"></div>
        <% end %>
      </div>
    """
  end

  def mount(_params, %{}, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    socket = assign(socket, :start_time, DateTime.utc_now())

    {:ok, update_board(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, update_board(socket)}
  end

  defp update_board(socket) do
    current_time = DateTime.utc_now()

    socket
    |> assign(:current_time, current_time)
    |> assign(:duration, duration(socket.assigns.start_time))
  end

  defp color(_time), do: Enum.random(~w[red black white blue green])

  defp duration(start_time) do
    duration = DateTime.diff(DateTime.utc_now(), start_time)

    cond do
      duration > 60 * 60 ->
        "#{div(duration, 60 * 60)} hours"

      duration > 60 ->
        "#{div(duration, 60)} minutes"

      true ->
        "#{duration} seconds"
    end
  end
end
