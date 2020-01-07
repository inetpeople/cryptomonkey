alias CryptoMonkey.Signals
alias CryptoMonkey.Signals.Signal

signals = File.read!("./priv/data/dev/signals.txt") |> :erlang.binary_to_term()

  Enum.map(signals, fn data ->
    %{
      __meta__: _,
      __struct__: _,
      id: _,
      received_signal: _,
      recognized_signal: _,
      updated_at: _,
      inserted_at: time,
      chart_timeframe: ctf,
      signal_price: price,
      signal_type: signal,
      algo: algo,
      exchange: exchange,
      ticker: ticker
    } = data

    %{
      chart_timeframe: ctf,
      signal_price: price |> convert_price(),
      signal_type: signal,
      algo: clean_str(algo),
      exchange: exchange,
      ticker: ticker,
      timestamp: time |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:nanosecond)
    }
    |> Signal.from_map()
  end)
  |> Signal.write
end

defp clean_str(string) do
  string |> String.trim() |> String.split() |> List.to_string()
end

defp convert_price(price) do
  case price do
    nil -> nil
    _ -> Decimal.to_float(price)
  end
end
