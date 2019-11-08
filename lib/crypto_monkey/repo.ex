defmodule CryptoMonkey.Repo do
  use Ecto.Repo,
    otp_app: :crypto_monkey,
    adapter: Ecto.Adapters.Postgres
end
