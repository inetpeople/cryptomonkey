alias CryptoMonkey.Signals

signals = [
  %{
    algo: "Test1-Algo",
    ticker: "BTCUSD",
    exchange: "KRAKEN",
    signal_type: "BUY",
    signal_price: 8005,
    chart_timeframe: "4H",
    recognized_signal: true
  },
  %{
    algo: "Test1-Algo",
    ticker: "BTCUSD",
    exchange: "KRAKEN",
    signal_type: "SELL",
    signal_price: 19000,
    chart_timeframe: "4H",
    recognized_signal: true
  },

]



Enum.each(signals, fn(data) ->
  Signals.create_signal(data)
end)
