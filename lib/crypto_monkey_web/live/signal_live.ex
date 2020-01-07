defmodule CryptoMonkeyWeb.SignalLive do
  use Phoenix.LiveView
  require Logger
  alias CryptoMonkeyWeb.SignalView
  alias CryptoMonkey.Signals
  alias CryptoMonkey.Signals.Center

  def render(assigns) do
    SignalView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    # Signals
    # returns %{signals: [Signal.t]}
    db_signals = Signals.list_signals()
    :ok = Signals.subscribe()

    {:ok, assign(socket, db_signals)}
  end

  def handle_info(%{topic: "signals_center", event: "list_signals", payload: payload}, socket) do
    Logger.info("got new signals, overwritting memory")
    {:noreply, assign(socket, :signals, payload)}
  end

  def handle_info(%{topic: "signals_center", event: "new_signal", payload: payload}, socket) do
    Logger.info("got new signal")
    new_signal = List.insert_at(socket.assigns.signals, 0, payload)
    {:noreply, assign(socket, :signals, new_signal)}
  end

  ######
  ### Private Functions
  ######
end
