defmodule ChessBoardWeb.ThermostatLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <%= @time %> <br />
    Current temperature: <%= @temperature %>
      <div class="board">
        <%= for _ <- 1..100 do %>
          <div class="col" style="background-color: <%=color(@time) %>"></div>
        <% end %>
      </div>
    """
  end

  def color(_time), do: Enum.random(~w[red black white blue green])

  def mount(_params, %{}, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)
    {:ok, update(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, update(socket)}
  end

  defp update(socket) do
    temperature = :crypto.rand_uniform(80, 100)
    time = DateTime.utc_now() |> DateTime.to_iso8601()

    socket
    |> assign(:temperature, temperature)
    |> assign(:time, time)
  end
end
