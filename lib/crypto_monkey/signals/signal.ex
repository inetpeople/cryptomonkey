defmodule CryptoMonkey.Signals.Signal do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

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

  defmacro date_trunc(period, expr) do
    quote do
      fragment("date_trunc(?, ?)", unquote(period), unquote(expr))
    end
  end

  defmacro date_trunc_format(period, format, expr) do
    quote do
      fragment("to_char(date_trunc(?, ?), ?)", unquote(period), unquote(expr), unquote(format))
    end
  end

  @doc "to_char function for formatting datetime as dd MON YYYY"
  defmacro to_char(field, format) do
    quote do
      fragment("to_char(?, ?)", unquote(field), unquote(format))
    end
  end

  @doc "Builds a query with row counts per inserted_at date"
  def row_counts_by_date(algo) do
    query =
      from(s in __MODULE__,
        where: s.algo == ^algo
      )

    from record in query,
      group_by: to_char(record.inserted_at, "dd Mon YYYY"),
      select: {to_char(record.inserted_at, "dd Mon YYYY"), count(record.id)}
  end

  def func(chart_timeframe, filter) do
    query =
      from(s in __MODULE__,
        where: s.chart_timeframe == ^chart_timeframe
      )

    # IO.puts(filter)
    # filter = Atom.to_string(filter)
    case filter do
      # "by_" <> period ->
      #   from(d in Download,
      #     where: d.release_id == ^release_id)
      #     group_by: date_trunc(^period, d.day),
      #     order_by: date_trunc(^period, d.day),
      #     select: {date_trunc_format(^period, "YYYY-MM-DD", d.day), sum(d.downloads)})
      :by_day ->
        from(s in query,
          group_by: date_trunc("inserted_at", s.inserted_at),
          order_by: date_trunc("inserted_at", s.inserted_at),
          select: {date_trunc_format("inserted_at", "YYYY-MM-DD", s.inserted_at), count("*")}
        )

      :by_week ->
        from(s in query,
          group_by: date_trunc("week", s.day),
          order_by: date_trunc("week", s.day),
          select: {date_trunc_format("week", "YYYY-MM-DD", s.day), sum(s.downloads)}
        )

      :by_month ->
        from(s in query,
          group_by: date_trunc("month", s.day),
          order_by: date_trunc("month", s.day),
          select: {date_trunc_format("month", "YYYY-MM", s.day), sum(s.downloads)}
        )
    end
  end

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
