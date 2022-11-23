defmodule CryptoMonkey.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the DBs
      CryptoMonkey.InfluxDB.child_spec(),
      CryptoMonkey.Repo,
      # Start the Telemetry supervisor
      CryptoMonkeyWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CryptoMonkey.PubSub},
      # Start the endpoint when the application starts
      CryptoMonkeyWeb.Endpoint,
      # Starts workers
      {CryptoMonkey.Boundary.Signal.Server, []},
      # {CryptoMonkey.Boundary.Kraken,
      #  %{channels: ["pi_xbtusd", "pi_ethusd"], require_auth: true, debug: []}},
      {CryptoMonkey.Signals.Center, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CryptoMonkey.Supervisor]
    Supervisor.start_link(children, opts)
    # |> create_influx_db
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CryptoMonkeyWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # def create_influx_db({:ok, _pid} = result) do
  #   CryptoMonkey.InfluxDB.wait_till_up()
  #   CryptoMonkey.InfluxDB.create_database()
  #   # CryptoMonkey.InfluxDB.create_retention_policies
  #   # CryptoMonkey.InfluxDB.create_continuous_queries
  #   result
  # end
end
