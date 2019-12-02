defmodule CryptoMonkeyWeb.SignalLive do
  use Phoenix.LiveView
  require Logger
  alias CryptoMonkeyWeb.SignalView
  alias CryptoMonkey.Signals

  def render(assigns) do
    SignalView.render("index.html", assigns)
  end

  def new do
    %{
      signals: []
    }
  end

  def mount(_session, socket) do
    state = new()

    # Signals
    signals = CryptoMonkey.Signals.list_signals_by_latest()
    :ok = CryptoMonkey.Signals.subscribe()
    state = %{state | signals: signals}

    {:ok, assign(socket, state)}
  end

  def handle_info(%{topic: "signals", event: "new_signal", payload: payload}, socket) do
    Logger.info("got new signal")
    new_signal = List.insert_at(socket.assigns.signals, 0, payload)
    {:noreply, assign(socket, :signals, new_signal)}
  end

  ######
  ### Private Functions
  ######
end
