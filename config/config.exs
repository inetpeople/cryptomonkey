# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :crypto_monkey,
  ecto_repos: [CryptoMonkey.Repo]

# Configures the endpoint
config :crypto_monkey, CryptoMonkeyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qysb1DHiMeocJVKEV9s4k6OZY0bjSoTga+iFXVytYj700u0ennWln1llXXvI05N3",
  render_errors: [view: CryptoMonkeyWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: CryptoMonkey.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "SECRET_SALTiFXVytYj700u0ennWln1llXXvI05N3"
  ]

config :crypto_monkey, CryptoMonkey.Connection,
  host: "localhost",
  pool: [max_overflow: 10, size: 5],
  port: 8086,
  scheme: "http",
  writer: Instream.Writer.Line,
  json_decoder: {Jason, :decode!, [[keys: :atoms]]},
  json_encoder: {Jason, :encode!, []}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
