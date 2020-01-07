defmodule CryptoMonkey.Signals.SignalInfluxDB do
  alias CryptoMonkey.InfluxDB
  use Instream.Series

  @db_name Application.get_env(:crypto_monkey, :influx_db_name)

  # signal,algo=ETHI,ticker=ETHUSD,chart_timeframe=15m,exchange=coinbase,price=122.33

  series do
    database(@db_name)
    measurement("signal")

    # Store data in tags if you plan to use them with GROUP BY()
    tag(:algo)
    tag(:chart_timeframe)
    tag(:ticker)
    tag(:exchange)
    field(:signal_type)
    field(:signal_price)
    # field(:timestamp)
  end

  def write(data) do
    InfluxDB.write(data,
      # async: true,
      # precision: :nanosecond,
      database: @db_name
    )
  end

  def list_signals do
    """
    SELECT * FROM "signal"
    """
    |> InfluxDB.query(database: "#{@db_name}", precision: :nanosecond)
    |> from_result()
  end

  def list_algo_signals(algo) do
    """
    SELECT * FROM signal WHERE "algo"='#{algo}'
    """
    # SELECT signal_type FROM signal WHERE time > now() - 30d AND exchange = 'KRAKEN' GROUP BY time(1d), ticker

    |> InfluxDB.query(database: "#{@db_name}", precision: :nanosecond)
    |> from_result()
  end

  def b do
    """
    SELECT * FROM "signal" WHERE "algo"='ETH-I' AND time >= '2019-08-18T00:00:00Z' AND time <= '2020-08-18T00:54:00Z'
    """
    |> InfluxDB.query(database: "#{@db_name}", precision: :nanosecond)
  end

  def count do
    """
    SELECT COUNT("signal_type") FROM "signal" WHERE "exchange"='KRAKEN'AND "signal_type"='BUY' AND time >= '2019-12-01T00:00:00Z' AND time <= '2020-08-18T00:30:00Z' GROUP BY time(15m), algo, chart_timeframe
    """
    |> InfluxDB.query(database: "#{@db_name}", precision: :nanosecond)
  end

  def drop_db do
    @db_name
    |> Instream.Admin.Database.drop()
    |> InfluxDB.execute()
  end

  def create_db do
    @db_name
    |> Instream.Admin.Database.create()
    |> InfluxDB.execute()
  end

  def reset_db do
    drop_db()
    create_db()
  end

  def example_struct do
    %{
      chart_timeframe: "15M",
      signal_price: 8888,
      signal_type: "BUY",
      algo: "ETHI",
      exchange: "KRAKEN",
      ticker: "ETHUSD",
      timestamp: DateTime.utc_now() |> DateTime.to_unix(:nanosecond)
    }
    |> from_map()
  end

  def seed do
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
      |> from_map()
    end)
    |> write()
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
end
