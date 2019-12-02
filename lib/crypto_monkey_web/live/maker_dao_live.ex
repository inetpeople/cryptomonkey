defmodule CryptoMonkeyWeb.MakerDaoLive do
  use Phoenix.LiveView
  import Logger, only: [info: 1, warn: 1]
  alias CryptoMonkey.MakerDao
  alias CryptoMonkeyWeb.MakerDaoView
  @topic "MakerDao"

  def render(assigns) do
    MakerDaoView.render("index.html", assigns)
  end

  def new do
    %{
      collateral_eth: 740,
      eth_price: 154,
      debt: 32000,
      cdp_states: [
        %{
          eth_price: 0,
          total_value: 0,
          debt: 0,
          free_value: 0,
          eth_sold: 0,
          eth_bought: 0,
          collateral_eth: 0,
          collaterizations_ratio: 0,
          liquidation_price: 0,
          original_collateral_eth: 0,
          original_value: 0
        }
      ]
    }
  end

  def mount(_session, socket) do
    state = new()
    :ok = CryptoMonkeyWeb.Endpoint.subscribe(@topic)

    MakerDao.repay_or_boost?(state.eth_price, state.debt, state.collateral_eth)

    # play(state.eth_price)

    {:ok, assign(socket, state)}
  end

  def handle_info(%{topic: @topic, event: "boost_cdp", payload: payload}, socket) do
    # Logger.info("Boost CDP")

    new_entry = %{
      eth_price: payload.eth_price,
      total_value: payload.eth_price * payload.new_collateral_eth,
      debt: payload.max_debt,
      free_value: payload.eth_price * payload.new_collateral_eth - payload.max_debt,
      eth_sold: 0,
      eth_bought: payload.eth_to_buy,
      collateral_eth: payload.new_collateral_eth,
      collaterizations_ratio: payload.collaterizations_ratio * 100,
      liquidation_price: payload.liquidation_price,
      original_collateral_eth: socket.assigns.collateral_eth,
      original_value: socket.assigns.collateral_eth * payload.eth_price
    }

    new_state = List.insert_at(socket.assigns.cdp_states, 0, new_entry)

    {:noreply, assign(socket, :cdp_states, new_state)}
  end

  def handle_info(%{topic: @topic, event: "repay_cdp", payload: payload}, socket) do
    # Logger.info("Repay CDP")

    new_entry = %{
      eth_price: payload.eth_price,
      total_value: round(payload.eth_price * payload.new_collateral_eth),
      debt: payload.max_debt,
      free_value: payload.eth_price * payload.new_collateral_eth - payload.max_debt,
      eth_sold: payload.eth_to_sell,
      eth_bought: 0,
      collateral_eth: payload.new_collateral_eth,
      collaterizations_ratio: payload.collaterizations_ratio * 100,
      liquidation_price: round(payload.liquidation_price),
      original_collateral_eth: socket.assigns.collateral_eth,
      original_value: socket.assigns.collateral_eth * payload.eth_price
    }

    new_state = List.insert_at(socket.assigns.cdp_states, 0, new_entry)

    {:noreply, assign(socket, :cdp_states, new_state)}
  end

  def handle_info(%{topic: @topic, event: "neutral_cdp", payload: payload}, socket) do
    # Logger.info("Nautral CDP")

    new_entry = %{
      eth_price: round(payload.eth_price),
      total_value: round(payload.eth_price * payload.collateral_eth),
      debt: payload.max_debt,
      free_value: payload.eth_price * payload.collateral_eth - payload.max_debt,
      eth_sold: 0,
      eth_bought: 0,
      collateral_eth: payload.new_collateral_eth,
      collaterizations_ratio: payload.collaterizations_ratio * 100,
      liquidation_price: payload.liquidation_price,
      original_collateral_eth: socket.assigns.collateral_eth,
      original_value: socket.assigns.collateral_eth * payload.eth_price
    }

    new_state = List.insert_at(socket.assigns.cdp_states, 0, new_entry)

    {:noreply, assign(socket, :cdp_states, new_state)}
  end

  def play_with_prices(start_price) do
    deepest_price = 120
    highest_price = 6000
    downtrend = Enum.to_list(start_price..deepest_price)
    uptrend = Enum.to_list(deepest_price..highest_price)
    downtrend ++ uptrend
  end

  def play(start_price) do
    state = new()

    price_samples = play_with_prices(start_price)

    Enum.reduce(
      price_samples,
      %{
        debt: state.debt,
        collateral_eth: state.collateral_eth
      },
      fn x, map ->
        {:ok, map} = MakerDao.repay_or_boost?(x, map.debt, map.collateral_eth)
        map
      end
    )
  end
end
