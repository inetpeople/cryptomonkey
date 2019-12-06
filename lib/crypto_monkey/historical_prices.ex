defmodule HistoricalPrices do
  def get_data_from_csv_file(file) do
    file
    |> File.stream!([{:encoding, :utf8}])
    |> CSV.decode!(headers: true)
    |> Enum.reduce([], fn x, acc ->
      [
        %{
          date: to_date(x["Date"]),
          open: to_number(x["Open"]),
          high: to_number(x["High"]),
          low: to_number(x["Low"]),
          close: to_number(x["Close"]),
          volume: to_number(x["Volume"]),
          market_cap: to_number(x["MarketCap"])
        }
        | acc
      ]
    end)

    # |> Enum.drop(-1)
  end

  def to_number(string) do
    string
    |> String.split(",")
    |> List.to_string()
    |> Decimal.new()
  end

  def to_date(string) do
    [day_month, year] = String.split(string, ",")
    [month, day] = String.split(day_month, " ")

    mth =
      case month do
        "Jan" -> "1"
        "Feb" -> "2"
        "Mar" -> "3"
        "Apr" -> "4"
        "May" -> "5"
        "Jun" -> "6"
        "Jul" -> "7"
        "Aug" -> "8"
        "Sep" -> "9"
        "Oct" -> "10"
        "Nov" -> "11"
        "Dec" -> "12"
      end

    [y, m, d] =
      [String.trim(year), mth, day]
      |> Enum.map(fn x ->
        String.to_integer(x)
      end)

    {:ok, date} = Date.new(y, m, d)
    date
  end
end
