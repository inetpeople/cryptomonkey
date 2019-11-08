defmodule CryptoMonkey.Boundary.Signal.Item do
  require Logger
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

  #  @type t :: %__MODULE__{signal: String.t(), created_at: Time.t()}

  def new(signal) when is_map(signal) do
    new_item = %__MODULE__{}
    item = struct(new_item, k_v(signal))

    case item.algo do
      "" ->
        item = %{item | received_signal: signal}
        {:error, item}

      _ ->
        item = %{item | recognized_signal: true, received_signal: signal}
        Logger.info("New Signal Map received")
        {:ok, item}
    end
  end

  def new(signal) when is_bitstring(signal) do
    new_item = %__MODULE__{}

    case import_signal(signal) do
      {:ok, signal} ->
        Logger.info("New Signal String received")

        item =
          struct(
            new_item,
            Map.new(signal, fn {k, v} ->
              {k, String.upcase(v)}
            end)
          )

        {:ok, %{item | recognized_signal: true}}

      {:ok, signal, :partial} ->
        item = struct(new_item, signal)
        Logger.warn("String Signal with unknown Values found!")
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
      ArgumentError -> Logger.warn("Map Signal with unknown Values found!")
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
