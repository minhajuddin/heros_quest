# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :chess_board,
  ecto_repos: [ChessBoard.Repo]

# Configures the endpoint
config :chess_board, ChessBoardWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Q0P18rYr5Lj05xnmDkP1gGrL99yr8gtR6LA9O9PHZ6qNtGz/ZlV81czaWN+Q/YVR",
  render_errors: [view: ChessBoardWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ChessBoard.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "oypDkZ7o"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
