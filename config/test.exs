use Mix.Config

# Configure your database
config :crypto_monkey, CryptoMonkey.Repo,
  username: "postgres",
  password: "postgres",
  database: "crypto_monkey_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :crypto_monkey, CryptoMonkeyWeb.Endpoint,
  http: [port: 4002],
  server: false

config :crypto_monkey, :influx_db_name, "crypto_monkey_test"

# Print only warnings and errors during test
config :logger, level: :warn
