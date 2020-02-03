defmodule CryptoMonkey.Signals.Signal do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias CryptoMonkey.Repo

  schema "signals" do
    field :algo, :string
    field :received_signal, :map
    field :ticker, :string
    field :exchange, :string
    field :signal_type, :string
    field :chart_timeframe, :string
    field :signal_price, :decimal
    field :recognized_signal, :boolean, default: false
    field :closed_at, :naive_datetime
    field :published_at, :naive_datetime
    field :confirmed_at, :naive_datetime
    belongs_to :closing_signal, __MODULE__

    timestamps()
  end

  @doc false
  def changeset(signal, attrs) do
    allowed_fields = [
      :received_signal,
      :algo,
      :ticker,
      :exchange,
      :signal_type,
      :chart_timeframe,
      :signal_price,
      :recognized_signal,
      :closed_at,
      :published_at,
      :confirmed_at,
      :closing_signal_id
    ]

    signal
    |> cast(attrs, allowed_fields)
    |> validate_required([:algo])

    # |> will_confirm_at()
  end

  # SELECT
  #   TIMESTAMP WITH TIME ZONE 'epoch' +
  #   INTERVAL '1 second' * round(extract('epoch' from timestamp) / 300) * 300 as timestamp, name, count(b.name)
  # FROM time a, id
  # WHERE …
  # GROUP BY
  # round(extract('epoch' from timestamp) / 300), name

  # https://www.postgresql.org/docs/9.1/functions-datetime.html#FUNCTIONS-DATETIME-TRUNC

  # https://hexdocs.pm/ecto_function/readme.html

  # select  date_trunc('hour', val) + date_part('minute', val)::int / 5 * interval '5 min'

  # select date_trunc('day', inserted_at) + date_part('hour', inserted_at)::int / 4 * interval '4 hour' as date,

  defmacro date_trunc(period, expr) do
    quote do
      fragment("date_trunc(?, ?)", unquote(period), unquote(expr))
    end
  end

  defmacro date_part(period, expr) do
    quote do
      fragment("date_part(?,?)", unquote(period), unquote(expr))
    end
  end

  defmacro interval(period) do
    quote do: fragment("interval ?", unquote(period))
  end

  defmacro between(date, start_date, end_date) do
    quote do:
            fragment(
              "? BETWEEN ? AND ?",
              unquote(date),
              unquote(start_date),
              unquote(end_date)
            )
  end


#   from q in Post,
#   select: [fragment("date_trunc('day', ?) as date", q.inserted_at],
#   group_by: fragment("date")
  def q do
    from(signal in "signals",
      group_by: [
        date_trunc("day", signal.inserted_at) +
          date_part("hour", signal.inserted_at) / 4 * interval("4 hour"),
        signal.algo,
        signal.ticker,
        signal.exchange,
        signal.chart_timeframe
      ],
      order_by:
        date_trunc("day", signal.inserted_at) +
          date_part("hour", signal.inserted_at) / 4 * interval("4 hour"),
      select: %{
        date:
          date_trunc("day", signal.inserted_at) +
            date_part("hour", signal.inserted_at) / 4 * interval("4 hour"),
        signal_count: count(signal.signal_type),
        algo: signal.algo,
        ticker: signal.ticker,
        exchange: signal.exchange,
        chart_timeframe: signal.chart_timeframe,
        lowest_price: min(signal.signal_price),
        highest_price: max(signal.signal_price)
      },
      where: [chart_timeframe: "4H", signal_type: "BUY", algo: "ETH-I"],
      where: between(signal.inserted_at, ^~U[2019-12-05 08:00:00Z], ^~U[2019-12-05 11:59:59Z])
    )
  end


  # https://stackoverflow.com/questions/7299342/what-is-the-fastest-way-to-truncate-timestamps-to-5-minutes-in-postgres

  # {trunc, part, interval, chart_timeframe}
  # [{'day', 'hour', '1 hour', '1H'}, {'week', 'day', '1 day', '1D'}, {'hour', 'minute', '5 minute', '5M'}]

  def sql do
    ~s"""
    select date_trunc('day', inserted_at) + (date_part('hour', inserted_at)::int / 4) * interval '4 hour' as date,
    count(signal_type) as signal_count, algo, ticker, exchange, chart_timeframe, min(signal_price) as min_price, max(signal_price) as max_price
    from "signals"
    where chart_timeframe='4H' AND signal_type='BUY' AND inserted_at BETWEEN '2019-12-05 08:00:00' AND '2019-12-05 11:59:59' and algo='ETH-I'
    group by date, algo, ticker, exchange, chart_timeframe
    order by date
    """
  end

  def four_hours_buy do
    ~s"""
    select date_trunc('day', inserted_at) + (date_part('hour', inserted_at)::int / 4) * interval '4 hour' as date,
    count(signal_type) as signal_count, algo, ticker, exchange, chart_timeframe, min(signal_price) as min_price, max(signal_price) as max_price
    from "signals"
    where chart_timeframe='4H' AND signal_type='BUY'
    group by date, algo, ticker, exchange, chart_timeframe
    order by date
    """
  end

  def result_to_maps(%Postgrex.Result{columns: _, rows: nil}), do: []

  def result_to_maps(%Postgrex.Result{columns: col_nms, rows: rows}),
    do: Enum.map(rows, fn row -> row_to_map(col_nms, row) end)

  defp row_to_map(col_nms, vals),
    do: Stream.zip(col_nms, vals) |> Enum.into(Map.new(), & &1)

  def query(query) do
    Ecto.Adapters.SQL.query!(Repo, query)
    # |> result_to_maps()
  end

  # select date_trunc('day', inserted_at) + date_part('hour', inserted_at)::int / 4 * interval '4 hour' as date,
  # count(signal_type), algo, ticker, exchange, chart_timeframe, min(signal_price) as min_price, max(signal_price) as max_price
  # from "signals"
  # where chart_timeframe='4H' AND signal_type='BUY' AND inserted_at BETWEEN '2019-12-05 08:00:00' AND '2019-12-05 11:59:59' and algo='ETH-I'
  # group by date, algo, ticker, exchange, chart_timeframe
  # order by date

  # defp will_confirm_at(signal) do
  #   signal
  # end

  # def samechart_intervalls(signal) do
  #   case signal.chart_timeframe do
  #     "4H" ->
  #       hrs = get_hour(signal)
  #       [true, false, false, false, false, false] = candle_4h_member?(hrs)
  #   end
  # end

  # def compare_time_frame(signal1, signal2) do
  #   naive1 = signal1
  #   naive2 = signal2
  # end

  # def candle_4h_member?(hrs) do
  #   [0..3, 4..7, 8..11, 12..15, 16..19, 20..24]
  #   |> Enum.map(fn x -> Enum.member?(x, hrs) end)
  # end

  # def get_hour(time) do
  #   naive = time
  #   naive.hour
  # end

  # def get_minute(time) do
  #   naive = time
  #   naive.minute
  # end

  # def expected_map(algo \\ "", ctf \\ "", exh \\ "", type \\ "", ticker \\ "") do
  #   %{
  #     algo: algo,
  #     chart_timeframe: ctf,
  #     exchange: exh,
  #     signal_price: "",
  #     signal_type: type,
  #     ticker: ticker
  #   }
  #   |> Jason.encode!()
  # end

  # {
  # "algo":"PSAR",
  # "chart_timeframe":"4h",
  # "exchange": "bitstamp",
  # "signal_price":"",
  # "signal_type":"buy",
  # "ticker":"BTCUSD"
  # }
end
