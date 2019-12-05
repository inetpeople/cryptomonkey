defmodule HistoricalPrices do
  def get_data_from_csv_file(file) do
    file
    |> File.stream!([{:encoding, :utf8}])
    |> CSV.decode!(headers: true)
    |> Enum.reduce([], fn x, acc ->
      [
        %{
          date: x["Date"],
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
    |> Number.Conversion.to_decimal()

    # String.to_float(string)
  end
end
