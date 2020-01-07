defmodule CryptoMonkey.Broadcast do
  def broadcast!(topic, event, msg) do
    CryptoMonkeyWeb.Endpoint.broadcast!(topic, event, msg)
  end

  def broadcast(topic, event, msg) do
    CryptoMonkeyWeb.Endpoint.broadcast(topic, event, msg)
  end

  def subscribe(topic) do
    CryptoMonkeyWeb.Endpoint.subscribe(topic)
  end
end
