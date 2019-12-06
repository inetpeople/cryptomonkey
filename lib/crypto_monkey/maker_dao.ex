defmodule CryptoMonkey.MakerDao do
  import Logger, only: [info: 1, warn: 1]
  # https://mkr.tools/tokens/peth
  # 1.0476
  @peth_eth_ratio "1.047" |> Decimal.new()

  @collateral_ratio "2" |> Decimal.new()
  # Liquidation protection, if bellow @collateral_sell_ratio, repay to @collateral_ratio
  @collateral_sell_ratio "1.8" |> Decimal.new()
  # Leverage increase, if above @collateral_buy_ratio, boost to @collateral_ratio
  @collateral_buy_ratio "2.2" |> Decimal.new()

  @liquidation_ratio "1.5" |> Decimal.new()
  def get_max_dai_with_collateral_in_eth(
        eth_price,
        collateral_eth,
        collateral_ratio
      ) do
    # max_debt = collateral_eth * eth_price * @peth_eth_ratio / collateral_ratio
    max_debt =
      collateral_eth
      |> Decimal.mult(eth_price)
      |> Decimal.mult(@peth_eth_ratio)
      |> Decimal.div(collateral_ratio)

    {:ok,
     "You can borrow up to %{max_debt} DAI with a Collateralization Ratio of ${collateral_ratio}!",
     max_debt}
  end

  def get_max_dai_with_target_collateral_ratio(
        eth_price,
        collateral_eth,
        collateral_ratio
      ) do
    # max_debt = collateral_eth * eth_price * @peth_eth_ratio / collateral_ratio

    max_debt =
      collateral_eth
      |> Decimal.mult(eth_price)
      |> Decimal.mult(@peth_eth_ratio)
      |> Decimal.div(collateral_ratio)

    {:ok,
     "You can borrow up to %{max_debt} DAI with a Collateralization Ratio of ${collateral_ratio}!",
     max_debt}
  end

  def how_much_dai?(eth_price, collateral_eth) do
    # max_debt = collateral_eth * eth_price * @peth_eth_ratio / @liquidation_ratio
    max_debt =
      collateral_eth
      |> Decimal.mult(eth_price)
      |> Decimal.mult(@peth_eth_ratio)
      |> Decimal.div(@liquidation_ratio)

    {:ok,
     "You can borrow up to %{max_debt} DAI with a Collateralization Ratio of ${@liquidation_ratio}!",
     max_debt}
  end

  @doc """
  What is the liquidation ratio with the given ETH Price?
  """
  def collateralization_ratio?(debt, collateral_eth, eth_price) do
    #  ratio = collateral_eth * eth_price * @peth_eth_ratio / debt
    ratio =
      collateral_eth
      |> Decimal.mult(eth_price)
      |> Decimal.mult(@peth_eth_ratio)
      |> Decimal.div(debt)

    {:ok, "Collateralization Ratio is #{ratio}", ratio}
  end

  @doc """
  What is the liquidation price?
  """
  def liquidation_price?(debt, collateral_eth) do
    # liquidation_price = debt * @liquidation_ratio / collateral_eth * @peth_eth_ratio

    liquidation_price =
      debt
      |> Decimal.mult(@liquidation_ratio)
      |> Decimal.div(Decimal.mult(collateral_eth, @peth_eth_ratio))

    {:ok, "Liquidation will be executed when ETH Price reaches: #{liquidation_price}",
     liquidation_price}
  end

  def get_collateral_in_eth(eth_price, debt, collateral_ratio) do
    # amount = debt * collateral_ratio / eth_price * @peth_eth_ratio
    amount =
      debt
      |> Decimal.mult(collateral_ratio)
      |> Decimal.div(Decimal.mult(eth_price, @peth_eth_ratio))

    {:ok, "You have #{amount} ETH locked as collateral.", amount}
  end

  @doc """
  Pay back this amount of DAI to get the wanted liquidation price.
  """
  def target_liquidation_price(target_liquidation_price, debt, collateral_eth) do
    # ((generated_dai - repaying_dai)  × liquidation_ratio ) ÷ (collateral_eth) = target_liquidation_price
    # (target_liquidation_price * collateral_eth) /  liquidation_ratio  = (generated_dai - repaying_dai)
    # (target_liquidation_price * collateral_eth) /  liquidation_ratio  - generated_dai = repaying_dai * (-1)
    amount =
      target_liquidation_price
      |> Decimal.mult(collateral_eth)
      |> Decimal.div(@liquidation_ratio)
      |> Decimal.sub(debt)

    {:ok,
     "Pay back #{amount} of DAI to reach your Target Liquidation price of #{
       target_liquidation_price
     }", amount}
  end

  def repay_or_boost?(data, debt, collateral_eth) do
    # (Generated Dai x Liquidation Ratio) ÷ Collateral Amount = Liquidation Price

    sell_trigger_price = sell_trigger_price(debt, collateral_eth)
    buy_trigger_price = buy_trigger_price(debt, collateral_eth)

    # -1 to repay
    repay = Decimal.compare(data.close, sell_trigger_price)
    # 1 to boot
    boost = Decimal.compare(data.close, buy_trigger_price)

    trigger = [Decimal.to_integer(repay), Decimal.to_integer(boost)]

    case trigger do
      [-1, -1] ->
        info("repay")
        repay_cdp(data, debt, collateral_eth)

      [1, 1] ->
        info("boost")
        boost_cdp(data, debt, collateral_eth)

      _ ->
        info("neutral")
        neutral_cdp(data, debt, collateral_eth)
    end
  end

  def sell_trigger_price(debt, collateral_eth) do
    # debt * @collateral_sell_ratio / collateral_eth
    debt |> Decimal.mult(@collateral_sell_ratio) |> Decimal.div(collateral_eth)
  end

  def buy_trigger_price(debt, collateral_eth) do
    # debt * @collateral_buy_ratio / collateral_eth
    Decimal.mult(debt, @collateral_buy_ratio) |> Decimal.div(collateral_eth)
  end

  def neutral_cdp(data, debt, collateral_eth) do
    {:ok, _, liquidation_price} = liquidation_price?(debt, collateral_eth)

    {:ok, _, collateralization_ratio} = collateralization_ratio?(debt, collateral_eth, data.close)

    {:ok,
     %{
       date: data.date,
       collateral_eth: collateral_eth,
       debt: debt,
       eth_price: data.close,
       liquidation_price: liquidation_price,
       collaterizations_ratio: collateralization_ratio
     }}
  end

  def repay_cdp(data, debt, collateral_eth) do
    {:ok, _, max_debt} =
      get_max_dai_with_target_collateral_ratio(data.close, collateral_eth, @collateral_ratio)

    #  dai_to_repay = debt - max_debt
    #   eth_to_sell = dai_to_repay / eth_price
    #   new_collateral_eth = collateral_eth - eth_to_sell

    dai_to_repay = Decimal.sub(debt, max_debt)
    eth_to_sell = Decimal.div(dai_to_repay, data.close)
    new_collateral_eth = Decimal.sub(collateral_eth, eth_to_sell)

    {:ok, _, liquidation_price} = liquidation_price?(max_debt, new_collateral_eth)

    {:ok, _, collateralization_ratio} =
      collateralization_ratio?(max_debt, new_collateral_eth, data.close)

    :ok =
      CryptoMonkeyWeb.Endpoint.broadcast!("MakerDao", "repay_cdp", %{
        date: data.date,
        dai_to_repay: dai_to_repay,
        eth_to_sell: eth_to_sell,
        new_collateral_eth: new_collateral_eth,
        max_debt: max_debt,
        eth_price: data.close,
        liquidation_price: liquidation_price,
        collaterizations_ratio: collateralization_ratio
      })

    {:ok,
     %{
       collateral_eth: new_collateral_eth,
       debt: max_debt,
       eth_price: data.close,
       liquidation_price: liquidation_price,
       collaterizations_ratio: collateralization_ratio,
       data: data.date
     }}
  end

  def boost_cdp(data, debt, collateral_eth) do
    {:ok, _, max_debt} =
      get_max_dai_with_target_collateral_ratio(data.close, collateral_eth, @collateral_ratio)

    # dai_to_boost = max_debt - debt
    # eth_to_buy = dai_to_boost / eth_price
    # new_collateral_eth = collateral_eth + eth_to_buy
    dai_to_boost = Decimal.sub(max_debt, debt)
    eth_to_buy = Decimal.div(dai_to_boost, data.close)
    new_collateral_eth = Decimal.add(collateral_eth, eth_to_buy)
    {:ok, _, liquidation_price} = liquidation_price?(max_debt, new_collateral_eth)

    {:ok, _, collateralization_ratio} =
      collateralization_ratio?(max_debt, new_collateral_eth, data.close)

    CryptoMonkeyWeb.Endpoint.broadcast!("MakerDao", "boost_cdp", %{
      date: data.date,
      eth_to_buy: eth_to_buy,
      new_collateral_eth: new_collateral_eth,
      max_debt: max_debt,
      eth_price: data.close,
      liquidation_price: liquidation_price,
      collaterizations_ratio: collateralization_ratio
    })

    {:ok,
     %{
       date: data.date,
       collateral_eth: new_collateral_eth,
       debt: max_debt,
       eth_price: data.close,
       liquidation_price: liquidation_price,
       collaterizations_ratio: collateralization_ratio
     }}
  end
end
