defmodule CryptoMonkey.MixProject do
  use Mix.Project

  def project do
    [
      app: :crypto_monkey,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CryptoMonkey.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.1"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.12.0"},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_html, "~> 2.13"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.1"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.1"},

      ##### RealTime
      # {:websockex, "~> 0.4.2"},

      ##### Http
      {:httpoison, "~> 1.6"},

      ##### SSL Certificate Lets encrypt
      # {:acme, "~> 0.5.1"},
      # {:acmex, "~> 0.1.0"}, v2 letsencrypt

      ##### DB
      {:instream, "~> 0.22"},

      #### Helpers
      # {:ex_money, "~> 4.0"},
      # {:phoenix_html_simplified_helpers, "~> 2.1"}
      {:number, "~> 1.0.0"},
      {:csv, "~> 2.3"},
      {:decimal, "~> 1.0"},

      # schedule jobs
      # {:quantum, "~> 2.3"},
      # work with time
      {:timex, "~> 3.0"},

      #### Tests
      # {:excoveralls, "~> 0.10", only: :test},
      {:mix_test_watch, "~> 1.0.1", only: :dev, runtime: false},

      # {:exconstructor, "~> 1.1.0"},

      ### Node
      # {:nodejs, "~> 1.0"},

      #### Exchanges
      # {:deribit, "~> 0.2.0"},
      # {:ccxtex, "~> 0.4.3"},
      # {:ccxtex, git: "https://github.com/inetpeople/ccxtex.git"},
      # {:ex_okex, "~> 0.2.0"}
      # {:ex_bitmex, "~> 0.2"}
      # {:binance, "~> 0.7.1"},
      # {:kraken_x, path: "../kraken_x"},
      {:kraken_x, git: "https://github.com/inetpeople/KrakenX.git"}

      # IRC
      # {:exirc, "~> 1.1"},

      # https://stackoverflow.com/questions/55063639/automatically-take-snapshots-of-tradingview-charts-and-save-in-google-docs
      # {:hound, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.seed": ["run priv/repo/seeds.#{Mix.env()}.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
