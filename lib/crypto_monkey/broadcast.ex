defmodule CryptoMonkey.Broadcast do
  def broadcast!(topic, event, msg) do
    # Phoenix.PubSub.broadcast!(topic, event, msg)
    Phoenix.PubSub.broadcast(CryptoMonkey.PubSub, topic, {event, msg})
  end

  def broadcast(topic, event, msg) do
    # PubSub.broadcast(:my_pubsub, "user:123", {:user_update, %{id: 123, name: "Shane"}})
    Phoenix.PubSub.broadcast(CryptoMonkey.PubSub, topic, {event, msg})
  end

  def subscribe(topic) do
    # CryptoMonkeyWeb.Endpoint.subscribe(topic)
    Phoenix.PubSub.subscribe(CryptoMonkey.PubSub, topic)
  end
end
