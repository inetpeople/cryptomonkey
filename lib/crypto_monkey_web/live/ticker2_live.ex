defmodule CryptoMonkeyWeb.Ticker2Live do
  use Phoenix.LiveView
  require Logger

  alias CryptoMonkeyWeb.TickerView

  def render(assigns) do
    IO.puts("RENDER #{inspect(self())}")
    TickerView.render("index.html", assigns)
  end

  def new do
    %{
      signals: [],
      # pi_ethusd: %{product_id: "PI_ETHUSD", markPrice: "loading", volume: "loading..."},
      # pi_xbtusd: %{product_id: "PI_XBTUSD", markPrice: "loading", volume: "loading..."},
      subscribed_tickers: ["PI_ETHUSD", "PI_XBTUSD"],
      heartbeat: %{time: ""},
      account_balances_and_margins: %{},
      open_positions: %{},
      open_orders_verbose_snapshot: %{},
      open_orders_snapshot: %{},
      unsubscribed: %{},
      tickers: %{
        pi_ethusd: %{
          product_id: "PI_ETHUSD",
          markPrice: "loading",
          volume: "loading...",
          ask: "",
          ask_size: "",
          bid: "",
          bid_size: ""
        },
        pi_xbtusd: %{
          product_id: "PI_XBTUSD",
          markPrice: "loading",
          volume: "loading...",
          ask: "",
          ask_size: "",
          bid: "",
          bid_size: ""
        }
      },
      error: %{}
    }
  end

  alias CryptoMonkey.Boundary.Kraken

  def mount(_params, _session, socket) do
    IO.puts("MOUNT #{inspect(self())}")

    state = new()
    product_ids = state.subscribed_tickers

    # Kraken
    Kraken.subscribe_channels(Kraken, product_ids)
    Kraken.get_open_positions(Kraken)

    # Kraken.get_account_balances_and_margins(Kraken)
    # Kraken.get_open_orders_verbose(Kraken)
    # Kraken.get_open_orders(Kraken)

    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(CryptoMonkey.PubSub, "krakenx_futures")
    end

    # Signals
    # :ok = CryptoMonkey.Signals.subscribe()
    signals = []
    # signals = CryptoMonkey.Signals.list_last_5_signals()

    Phoenix.PubSub.subscribe(CryptoMonkey.PubSub, "signals")
    state = %{state | signals: signals}
    {:ok, assign(socket, state)}
  end

  def handle_info({"tickers", payload}, socket) do
    IO.puts("TICKERS #{inspect(self())}")

    msg = map_to_atom(payload)
    atom_key = String.downcase(msg.product_id) |> String.to_existing_atom()
    # new_tickers = socket.assigns.tickers |> List.keyreplace(atom_key, 0, {atom_key, msg})
    new_tickers = socket.assigns.tickers |> Map.replace!(atom_key, msg)
    {:noreply, assign(socket, :tickers, new_tickers)}
  end

  def handle_info({"subscribed_tickers", payload}, socket) do
    tickers = (payload["product_ids"] ++ socket.assigns.subscribed_tickers) |> Enum.uniq()
    {:noreply, assign(socket, :subscribed_tickers, tickers)}
  end

  def handle_info({"open_positions", payload}, socket) do
    open_positions = map_to_atom(payload)
    {:noreply, assign(socket, :open_positions, open_positions)}
  end

  def handle_info(debug, socket) do
    IO.inspect(debug)
    {:noreply, socket}
  end

  # def handle_info(%{topic: "krakenx_futures", event: "heartbeat", payload: payload}, socket) do
  #   heartbeat = map_to_atom(payload)
  #   {:noreply, assign(socket, :heartbeat, heartbeat)}
  # end

  # def handle_info(
  #       %{topic: "krakenx_futures", event: "account_balances_and_margins", payload: payload},
  #       socket
  #     ) do
  #   account_balances_and_margins = payload
  #   {:noreply, assign(socket, :account_balances_and_margins, account_balances_and_margins)}
  # end

  # def handle_info(
  #       %{topic: "krakenx_futures", event: "open_orders_verbose_snapshot", payload: payload},
  #       socket
  #     ) do
  #   open_orders_verbose_snapshot = map_to_atom(payload)
  #   {:noreply, assign(socket, :open_orders_verbose_snapshot, open_orders_verbose_snapshot)}
  # end

  # def handle_info(
  #       %{topic: "krakenx_futures", event: "open_orders_snapshot", payload: payload},
  #       socket
  #     ) do
  #   open_orders_snapshot = map_to_atom(payload)
  #   {:noreply, assign(socket, :open_orders_snapshot, open_orders_snapshot)}
  # end

  # def handle_info(%{topic: "krakenx_futures", event: "unsubscribed", payload: payload}, socket) do
  #   unsubscribed = map_to_atom(payload)
  #   {:noreply, assign(socket, :subscribed_tickers, unsubscribed)}
  # end

  # def handle_info(%{topic: "krakenx_futures", event: "error", payload: payload}, socket) do
  #   error = map_to_atom(payload)
  #   {:noreply, assign(socket, :error, error)}
  # end

  # def handle_info(%{topic: "signals", event: "new_signal", payload: payload}, socket) do
  #   new_signal = List.insert_at(socket.assigns.signals, 0, payload) |> Enum.take(5)
  #   {:noreply, assign(socket, :signals, new_signal)}
  # end

  ######
  ### Private Functions
  ######
  defp map_to_atom(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      {String.to_atom(k), v}
    end)
  end

  # defp utc_time(time) do
  #   DateTime.from_unix!(time, :millisecond)
  # end

  # def beautiful_date(%{year: year, month: month}) do
  #   "#{year}-#{month}..."
  # end
end
