defmodule CryptoMonkeyWeb.TickerLive do
  use Phoenix.LiveView
  require Logger

  # TODO: https://adamdelong.com/elixir-dynamic-maps/

  # <hr>

  # <table>
  # <thead>
  # <tr>
  #   <th>Pair:</th>
  #   <%= for {k,_v} <- @pi_ethusd do %>
  #     <th><%= k %></th>
  #   <% end %>
  # </tr>
  # </thead>
  # <tbody>
  # <tr>
  #   <td><%= @pi_ethusd.product_id %></td>
  #   <%= for {_k,v} <- @pi_ethusd do %>
  #   <td><%= v %></td>
  # <% end %>
  # </tr>
  # <tr>
  #   <td><%= @pi_xbtusd.product_id %></td>
  #   <%= for {_k,v} <- @pi_xbtusd do %>
  #   <td><%= v %></td>
  # <% end %>
  # </tr>
  # </tbody>
  # </table>
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <div class="container">
    <hr>


    <table>
    <tr>
      <td>Ticker</td>
      <td>Mark Price</td>
      <td>Ask Price</td>
      <td>Ask Size</td>
      <td>Bid Price</td>
      <td>Bid Size</td>
      <td>Volume</td>
    </tr>
    <%= for {_k,v} <- @tickers do %>
    <tr>
      <td><%= v.product_id %></td>
      <td><%= v.markPrice %></td>
      <td><%= v.ask %></td>
      <td><%= v.ask_size %></td>
      <td><%= v.bid %></td>
      <td><%= v.bid_size %></td>
      <td><%= v.volume %></td>
    </tr>
    <% end %>
    </table>
    <hr>
    Heartbeat Time: <%= @heartbeat.time %>

    <hr>
    <%= for account <- @account_balances_and_margins do %>
    <%= account.account %>

    <% end %>

    <%= for {k,v} <- @open_positions do %>
    <%= k %>
    <%= v %>
    <% end %>

    <%= for {k,v} <- @open_orders_verbose_snapshot do %>
    <%= k %>
    <%= v %>
    <% end %>

    <%= for {k,v} <- @open_orders_snapshot do %>
    <%= k %>
    <%= v %>
    <% end %>

    <%= for {k,v} <- @unsubscribed do %>
    <%= k %>
    <%= v %>
    <% end %>

    <%= for {k,v} <- @error do %>
    <%= k %>
    <%= v %>
    <% end %>

    <table>
    <tr>
    <%= for signal <- @signals do %>
    <td><%= signal.algo %></td>
    <td><%= signal.ticker %></td>
    <td><%= signal.exchange %></td>
    <td><%= signal.signal_type %></td>
    <td><%= signal.chart_timeframe %></td>
    </tr>
    <% end %>
    </table>
    </div>
    """
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

  def mount(_session, socket) do
    state = new()
    product_ids = state.subscribed_tickers
    Kraken.subscribe_channels(Kraken, product_ids)
    Kraken.get_open_positions(Kraken)

    signals = CryptoMonkey.Signals.list_signals()

    # Kraken.get_account_balances_and_margins(Kraken)
    # Kraken.get_open_orders_verbose(Kraken)
    # Kraken.get_open_orders(Kraken)

    if connected?(socket) do
      :ok = CryptoMonkeyWeb.Endpoint.subscribe("krakenx_futures")
    end

    state = %{state | signals: signals}
    {:ok, assign(socket, state)}
  end

  def handle_info(%{topic: "krakenx_futures", event: "tickers", payload: payload}, socket) do
    msg = map_to_atom(payload)
    atom_key = String.downcase(msg.product_id) |> String.to_atom()
    # new_tickers = socket.assigns.tickers |> List.keyreplace(atom_key, 0, {atom_key, msg})
    new_tickers = socket.assigns.tickers |> Map.replace!(atom_key, msg)
    {:noreply, assign(socket, :tickers, new_tickers)}
  end

  def handle_info(
        %{topic: "krakenx_futures", event: "subscribed_tickers", payload: payload},
        socket
      ) do
    tickers = (payload["product_ids"] ++ socket.assigns.subscribed_tickers) |> Enum.uniq()
    {:noreply, assign(socket, :subscribed_tickers, tickers)}
  end

  # def handle_info(%{topic: "krakenx_futures", event: product_id, payload: payload}, socket) do
  #   new_price = map_to_atom(payload)
  #   atom_key = String.downcase(product_id) |> String.to_atom()
  #   {:noreply, assign(socket, atom_key, new_price)}
  # end

  def handle_info(%{topic: "krakenx_futures", event: "heartbeat", payload: payload}, socket) do
    heartbeat = map_to_atom(payload)
    {:noreply, assign(socket, :heartbeat, heartbeat)}
  end

  def handle_info(
        %{topic: "krakenx_futures", event: "account_balances_and_margins", payload: payload},
        socket
      ) do
    account_balances_and_margins = payload
    {:noreply, assign(socket, :account_balances_and_margins, account_balances_and_margins)}
  end

  def handle_info(%{topic: "krakenx_futures", event: "open_positions", payload: payload}, socket) do
    open_positions = map_to_atom(payload)
    {:noreply, assign(socket, :open_positions, open_positions)}
  end

  def handle_info(
        %{topic: "krakenx_futures", event: "open_orders_verbose_snapshot", payload: payload},
        socket
      ) do
    open_orders_verbose_snapshot = map_to_atom(payload)
    {:noreply, assign(socket, :open_orders_verbose_snapshot, open_orders_verbose_snapshot)}
  end

  def handle_info(
        %{topic: "krakenx_futures", event: "open_orders_snapshot", payload: payload},
        socket
      ) do
    open_orders_snapshot = map_to_atom(payload)
    {:noreply, assign(socket, :open_orders_snapshot, open_orders_snapshot)}
  end

  def handle_info(%{topic: "krakenx_futures", event: "unsubscribed", payload: payload}, socket) do
    unsubscribed = map_to_atom(payload)
    {:noreply, assign(socket, :subscribed_tickers, unsubscribed)}
  end

  def handle_info(%{topic: "krakenx_futures", event: "error", payload: payload}, socket) do
    error = map_to_atom(payload)
    {:noreply, assign(socket, :error, error)}
  end

  ######
  ### Private Functions
  ######
  defp map_to_atom(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      {String.to_atom(k), v}
    end)
  end

  defp utc_time(time) do
    DateTime.from_unix!(time, :millisecond)
  end
end
