defmodule CryptoMonkeyWeb.MakerDaoLive do
  use Phoenix.LiveView
  import Logger, only: [info: 1]
  alias CryptoMonkey.MakerDao
  alias CryptoMonkeyWeb.MakerDaoView
  @topic "MakerDao"

  def render(assigns) do
    MakerDaoView.render("index.html", assigns)
  end

  def new do
    %{
      collateral_eth: "720.0" |> Decimal.new(),
      eth_price: "140.0" |> Decimal.new(),
      debt: "32000.00" |> Decimal.new(),
      cdp_states: [
        %{
          date: ~D[2999-12-31],
          eth_price: 140,
          total_value: 1,
          debt: 0,
          free_value: 1,
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
    play("eth_historical_prices_copy.csv")
    # MakerDao.repay_or_boost?(state.eth_price, state.debt, state.collateral_eth)

    {:ok, assign(socket, state)}
  end

  def handle_info(%{topic: @topic, event: "boost_cdp", payload: payload}, socket) do
    # Logger.info("Boost CDP")

    new_entry = %{
      date: payload.date,
      eth_price: payload.eth_price,
      total_value: Decimal.mult(payload.eth_price, payload.new_collateral_eth),
      debt: payload.max_debt,
      free_value:
        Decimal.sub(Decimal.mult(payload.eth_price, payload.new_collateral_eth), payload.max_debt),
      eth_sold: 0,
      eth_bought: payload.eth_to_buy,
      collateral_eth: payload.new_collateral_eth,
      collaterizations_ratio: Decimal.mult(payload.collaterizations_ratio, 100),
      liquidation_price: payload.liquidation_price,
      original_collateral_eth: socket.assigns.collateral_eth,
      original_value:
        Decimal.sub(
          Decimal.mult(socket.assigns.collateral_eth, payload.eth_price),
          socket.assigns.debt
        )
    }

    new_state = List.insert_at(socket.assigns.cdp_states, 0, new_entry)

    {:noreply, assign(socket, :cdp_states, new_state)}
  end

  def handle_info(%{topic: @topic, event: "repay_cdp", payload: payload}, socket) do
    # Logger.info("Repay CDP")

    new_entry = %{
      date: payload.date,
      eth_price: payload.eth_price,
      total_value: Decimal.mult(payload.eth_price, payload.new_collateral_eth),
      debt: payload.max_debt,
      free_value:
        Decimal.sub(Decimal.mult(payload.eth_price, payload.new_collateral_eth), payload.max_debt),
      eth_sold: payload.eth_to_sell,
      eth_bought: 0,
      collateral_eth: payload.new_collateral_eth,
      collaterizations_ratio: Decimal.mult(payload.collaterizations_ratio, 100),
      liquidation_price: payload.liquidation_price,
      original_collateral_eth: socket.assigns.collateral_eth,
      original_value: Decimal.mult(socket.assigns.collateral_eth, payload.eth_price)
    }

    new_state = List.insert_at(socket.assigns.cdp_states, 0, new_entry)

    {:noreply, assign(socket, :cdp_states, new_state)}
  end

  # def handle_info(%{topic: @topic, event: "neutral_cdp", payload: payload}, socket) do
  #   new_entry = %{
  #     date: payload.date,
  #     eth_price: round(payload.eth_price),
  #     total_value: round(payload.eth_price * payload.collateral_eth),
  #     debt: payload.max_debt,
  #     free_value: payload.eth_price * payload.collateral_eth - payload.max_debt,
  #     eth_sold: 0,
  #     eth_bought: 0,
  #     collateral_eth: payload.new_collateral_eth,
  #     collaterizations_ratio: payload.collaterizations_ratio * 100,
  #     liquidation_price: payload.liquidation_price,
  #     original_collateral_eth: socket.assigns.collateral_eth,
  #     original_value: socket.assigns.collateral_eth * payload.eth_price
  #   }

  #   new_state = List.insert_at(socket.assigns.cdp_states, 0, new_entry)
  #   {:noreply, assign(socket, :cdp_states, new_state)}
  # end

  def play(file) do
    # price_samples = play_with_prices(start_price)
    info("Play time")

    state = new()
    price_samples = HistoricalPrices.get_data_from_csv_file(file)

    Enum.reduce(
      price_samples,
      %{
        debt: state.debt,
        collateral_eth: state.collateral_eth
      },
      fn x, data ->
        {:ok, map} = MakerDao.repay_or_boost?(x, data.debt, data.collateral_eth)
        map
      end
    )
  end
end
