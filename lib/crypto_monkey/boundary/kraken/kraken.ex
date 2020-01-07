defmodule CryptoMonkey.Boundary.Kraken do
  use KrakenX.Futures.WebSocket

  alias CryptoMonkey.Broadcast

  def broadcast!(topic, event, msg) do
    Broadcast.broadcast!(topic, event, msg)
  end
end
