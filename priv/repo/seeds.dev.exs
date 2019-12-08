alias CryptoMonkey.{Repo, Signals}

signals = File.read!("./priv/data/dev/signals.txt") |> :erlang.binary_to_term()

Enum.each(signals, fn data ->
  Repo.insert(data)
end)
