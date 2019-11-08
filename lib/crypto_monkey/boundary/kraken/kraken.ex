defmodule CryptoMonkey.Boundary.Kraken do
  use KrakenX.Futures.WebSocket

  def broadcast!(topic, event, msg) do
    CryptoMonkeyWeb.Endpoint.broadcast!(topic, event, msg)
  end
end
