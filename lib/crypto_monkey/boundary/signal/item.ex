defmodule CryptoMonkey.Boundary.Signal.Item do
  import Logger, only: [info: 1]
  # @enforce_keys [:received_signal]

  defstruct received_signal: "",
            created_at: Time.utc_now(),
            algo: "",
            ticker: "",
            exchange: "",
            signal_type: "",
            chart_timeframe: "",
            signal_price: "",
            recognized_signal: false

  alias CryptoMonkey.{Signals, Signals.Signal}

  def new do
    %Signal{}
  end

  def new(signal) when is_map(signal) do
    # new_item = new()
    # item = struct(new_item, k_v(signal))

    item = k_v(signal)
    has_algo = Map.has_key?(item, :algo)

    case has_algo do
      false ->
        item =
          item
          |> Map.put(:received_signal, signal)
          |> Map.put(:recognized_signal, false)
          |> Map.put(:algo, "???")

        {:ok, signal} = Signals.create_signal(item)
        info("New unrecognized Signal Map received")

        {:ok, signal}

      true ->
        item =
          item
          |> Map.put(:recognized_signal, true)
          |> Map.put(:received_signal, signal)

        {:ok, signal} = Signals.create_signal(item)
        info("New Signal Map received")

        {:ok, signal}
    end
  end

  def new(signal) when is_bitstring(signal) do
    case import_signal(signal) do
      {:ok, signal} ->
        info("New Signal String received")

        item =
          struct(
            new(),
            Map.new(signal, fn {k, v} ->
              {k, String.upcase(v)}
            end)
          )

        {:ok, %{item | recognized_signal: true}}

      {:ok, signal, :partial} ->
        item = struct(new(), signal) |> Map.put(:algo, "???")
        info("String Signal with unknown Values found!")

        {:ok, item}
    end
  end

  ### private ###

  defp k_v(signal) do
    for {key, val} <-
          signal,
        into: %{},
        do: {atomize(key), String.upcase(val)}
  end

  def atomize(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> info("Map Signal with unknown Values found!")
    end
  end

  defp import_signal(signal) do
    case String.split(signal) do
      [algo, ticker, exchange, signal_type, chart_timeframe, signal_price] ->
        signal = %{
          received_signal: signal,
          algo: algo,
          ticker: ticker,
          exchange: exchange,
          chart_timeframe: chart_timeframe,
          signal_price: signal_price,
          signal_type: signal_type
        }

        {:ok, signal}

      _ ->
        signal = %{received_signal: signal}
        {:ok, signal, :partial}
    end
  end
end
