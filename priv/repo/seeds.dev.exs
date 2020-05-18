defmodule Helper do
  def clean_str(string) do
    string |> String.trim() |> String.split() |> List.to_string()
  end

  def convert_price(price) do
    case price do
      nil -> nil
      _ -> Decimal.to_float(price)
    end
  end
end

alias CryptoMonkey.Signals
alias CryptoMonkey.Signals.Signal
alias CryptoMonkey.Repo
require Logger

signals = File.read!("./priv/data/dev/signals.txt") |> :erlang.binary_to_term()

Enum.each(signals, fn data ->
  Repo.insert(data)
end)

# Enum.map(signals, fn data ->
#   %{
#     __meta__: _,
#     __struct__: _,
#     id: _,
#     received_signal: _,
#     recognized_signal: _,
#     updated_at: _,
#     inserted_at: time,
#     chart_timeframe: ctf,
#     signal_price: price,
#     signal_type: signal,
#     algo: algo,
#     exchange: exchange,
#     ticker: ticker
#   } = data

#   %{
#     chart_timeframe: ctf,
#     signal_price: price |> Helper.convert_price(),
#     signal_type: signal,
#     algo: Helper.clean_str(algo),
#     exchange: exchange,
#     ticker: ticker
#     # timestamp: time |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:nanosecond)
#   }
# end)
