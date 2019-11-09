defmodule CryptoMonkey.Repo do
  use Ecto.Repo,
    otp_app: :crypto_monkey,
    adapter: Ecto.Adapters.Postgres,
    pool_size: System.get_env("POOL_SIZE")

  def init(_type, config) do
    {:ok, Keyword.put(config, :url, System.get_env("DATABASE_URL"))}
  end
end
