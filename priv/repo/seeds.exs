alias CryptoMonkey.Signals

signals = [
  %{
    algo: "Test1-Algo",
    ticker: "BTCUSD",
    exchange: "",
    signal_type: "BUY",
    chart_timeframe: "4H",
    recognized_signal: true
  },
  %{
    algo: "Test1-Algo",
    ticker: "BTCUSD",
    exchange: "",
    signal_type: "SELL",
    chart_timeframe: "4H",
    recognized_signal: true
  },

]



Enum.each(signals, fn(data) ->
  Signals.create_signal(data)
end)
