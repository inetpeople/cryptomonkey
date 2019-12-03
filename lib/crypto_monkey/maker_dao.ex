defmodule CryptoMonkey.MakerDao do
  import Logger, only: [info: 1, warn: 1]
  # https://mkr.tools/tokens/peth
  # 1.0476
  @peth_eth_ratio 1.0476

  @collateral_ratio 2
  # Liquidation protection, if bellow @collateral_sell_ratio, repay to @collateral_ratio
  @collateral_sell_ratio 1.7
  # Leverage increase, if above @collateral_buy_ratio, boost to @collateral_ratio
  @collateral_buy_ratio 2.1

  @liquidation_ratio 1.5

  def get_max_dai_with_collateral_in_eth(
        eth_price,
        collateral_eth,
        collateral_ratio
      ) do
    max_debt = collateral_eth * eth_price * @peth_eth_ratio / collateral_ratio
    # |> div(collateral_ratio)
    # |> Kernel.*(100)
    {:ok,
     "You can borrow up to %{max_debt} DAI with a Collateralization Ratio of ${collateral_ratio}!",
     max_debt}
  end

  def get_max_dai_with_target_collateral_ratio(
        eth_price,
        collateral_eth,
        collateral_ratio
      ) do
    max_debt = collateral_eth * eth_price * @peth_eth_ratio / collateral_ratio

    {:ok,
     "You can borrow up to %{max_debt} DAI with a Collateralization Ratio of ${collateral_ratio}!",
     max_debt}
  end

  def how_much_dai?(eth_price, collateral_eth) do
    max_debt = collateral_eth * eth_price * @peth_eth_ratio / @liquidation_ratio

    {:ok,
     "You can borrow up to %{max_debt} DAI with a Collateralization Ratio of ${@liquidation_ratio}!",
     max_debt}
  end

  @doc """
  What is the liquidation ratio with the given ETH Price?
  """
  def collateralization_ratio?(debt, collateral_eth, eth_price) do
    # ratio = collateral_amount x collateral_price) ÷ generated_dai × 100
    ratio = collateral_eth * eth_price * @peth_eth_ratio / debt
    {:ok, "Collateralization Ratio is #{ratio * 100}%", ratio}
  end

  @doc """
  What is the liquidation price?
  """
  def liquidation_price?(debt, collateral_eth) do
    liquidation_price = debt * @liquidation_ratio / collateral_eth * @peth_eth_ratio

    {:ok, "Liquidation will be executed when ETH Price reaches: #{liquidation_price}",
     liquidation_price}
  end

  def get_collateral_in_eth(eth_price, debt, collateral_ratio) do
    amount = debt * collateral_ratio / eth_price * @peth_eth_ratio
    {:ok, "You have #{amount} ETH locked as collateral.", amount}
  end

  # def liquid?(eth_price, debt, collateral_eth) do

  #   {:ok, _, ratio} = get_collateral_ratio(eth_price, debt, collateral_eth)

  #   if ratio <= @collateral_sell_ratio * 100 do
  #     # how much debt is possible with new eth price?
  #     # max_debt = get_max_dai_with_collateral_in_eth(eth_price)

  #     # how much debt is possible with default collateral ratio?

  #     # new_debt = max_debt - debt

  #     # new_collateral_eth = new_debt / eth_price

  #     # {:ok, max_debt, new_collateral_eth, new_debt}
  #   end
  #

  @doc """
  Pay back this amount of DAI to get the wanted liquidation price.
  """
  def target_liquidation_price(target_liquidation_price, debt, collateral_eth) do
    amount =
      debt - target_liquidation_price * (collateral_eth * @peth_eth_ratio) / @liquidation_ratio

    {:ok,
     "Pay back #{amount} of DAI to reach your Target Liquidation price of #{
       target_liquidation_price
     }", amount}
  end

  def repay_or_boost?(eth_price, debt, collateral_eth) do
    # (Generated Dai x Liquidation Ratio) ÷ Collateral Amount = Liquidation Price

    sell_trigger_price = sell_trigger_price(debt, collateral_eth)
    buy_trigger_price = buy_trigger_price(debt, collateral_eth)

    cond do
      sell_trigger_price >= eth_price ->
        # warn("repay")
        repay_cdp(eth_price, debt, collateral_eth)

      buy_trigger_price <= eth_price ->
        # warn("boost")
        boost_cdp(eth_price, debt, collateral_eth)

      true ->
        # info("neutral")
        neutral_cdp(eth_price, debt, collateral_eth)
    end
  end

  #### private
  def sell_trigger_price(debt, collateral_eth) do
    debt * @collateral_sell_ratio / collateral_eth
  end

  def buy_trigger_price(debt, collateral_eth) do
    debt * @collateral_buy_ratio / collateral_eth
  end

  def neutral_cdp(eth_price, debt, collateral_eth) do
    {:ok, _, liquidation_price} = liquidation_price?(debt, collateral_eth)
    {:ok, _, collateralization_ratio} = collateralization_ratio?(debt, collateral_eth, eth_price)

    # CryptoMonkeyWeb.Endpoint.broadcast!("MakerDao", "neutral_cdp", %{
    #   new_collateral_eth: collateral_eth,
    #   max_debt: debt,
    #   eth_price: eth_price,
    #   liquidation_price: liquidation_price,
    #   collaterizations_ratio: collateralization_ratio
    # })

    {:ok,
     %{
       collateral_eth: collateral_eth,
       debt: debt,
       eth_price: eth_price,
       liquidation_price: liquidation_price,
       collaterizations_ratio: collateralization_ratio
     }}
  end

  def repay_cdp(eth_price, debt, collateral_eth) do
    {:ok, _, max_debt} =
      get_max_dai_with_target_collateral_ratio(eth_price, collateral_eth, @collateral_ratio)

    dai_to_repay = debt - max_debt
    eth_to_sell = dai_to_repay / eth_price
    new_collateral_eth = collateral_eth - eth_to_sell
    {:ok, _, liquidation_price} = liquidation_price?(max_debt, new_collateral_eth)

    {:ok, _, collateralization_ratio} =
      collateralization_ratio?(max_debt, new_collateral_eth, eth_price)

    CryptoMonkeyWeb.Endpoint.broadcast!("MakerDao", "repay_cdp", %{
      dai_to_repay: dai_to_repay,
      eth_to_sell: eth_to_sell,
      new_collateral_eth: new_collateral_eth,
      max_debt: max_debt,
      eth_price: eth_price,
      liquidation_price: liquidation_price,
      collaterizations_ratio: collateralization_ratio
    })

    {:ok,
     %{
       collateral_eth: new_collateral_eth,
       debt: max_debt,
       eth_price: eth_price,
       liquidation_price: liquidation_price,
       collaterizations_ratio: collateralization_ratio
     }}
  end

  def boost_cdp(eth_price, debt, collateral_eth) do
    {:ok, _, max_debt} =
      get_max_dai_with_target_collateral_ratio(eth_price, collateral_eth, @collateral_ratio)

    dai_to_boost = max_debt - debt
    eth_to_buy = dai_to_boost / eth_price
    new_collateral_eth = collateral_eth + eth_to_buy
    {:ok, _, liquidation_price} = liquidation_price?(max_debt, new_collateral_eth)

    {:ok, _, collateralization_ratio} =
      collateralization_ratio?(max_debt, new_collateral_eth, eth_price)

    CryptoMonkeyWeb.Endpoint.broadcast!("MakerDao", "boost_cdp", %{
      eth_to_buy: eth_to_buy,
      new_collateral_eth: new_collateral_eth,
      max_debt: max_debt,
      eth_price: eth_price,
      liquidation_price: liquidation_price,
      collaterizations_ratio: collateralization_ratio
    })

    {:ok,
     %{
       collateral_eth: new_collateral_eth,
       debt: max_debt,
       eth_price: eth_price,
       liquidation_price: liquidation_price,
       collaterizations_ratio: collateralization_ratio
     }}
  end
end
