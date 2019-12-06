defmodule CryptoMonkey.MakerDaoTest do
  use CryptoMonkey.DataCase
  alias CryptoMonkey.MakerDao

  describe "maker dao" do
    # Account Start ETH
    @collateral_eth "746.51880868933161075" |> Decimal.new()

    # Account Start DEBT
    @debt "54475.351138008553114" |> Decimal.new()

    # Target Collateral Ratio
    @collateral_ratio "2" |> Decimal.new()

    # Liquidation protection, if bellow @collateral_sell_ratio, repay to @collateral_ratio
    # @collateral_sell_ratio "1.8" |> Decimal.new()
    # Leverage increase, if above @collateral_buy_ratio, boost to @collateral_ratio
    # @collateral_buy_ratio "2.2" |> Decimal.new

    @target_liquidation_price "50" |> Decimal.new()

    @eth_price 152 |> Decimal.new()

    @boost_price %{close: "165" |> Decimal.new(), date: ""}
    @neutral_price %{close: "150" |> Decimal.new(), date: ""}
    @repay_price %{close: "120" |> Decimal.new(), date: ""}

    test "how much dai can be loaned with x eth as collateral?" do
      {:ok, _, max_debt} =
        MakerDao.get_max_dai_with_collateral_in_eth(
          @eth_price,
          @collateral_eth,
          @collateral_ratio
        )

      assert max_debt == "59401.99464502749493059900" |> Decimal.new()
    end

    test "how much dai can be loaned with x% as collateral?" do
      {:ok, _, max_debt} =
        MakerDao.get_max_dai_with_target_collateral_ratio(
          @eth_price,
          @collateral_eth,
          @collateral_ratio
        )

      assert max_debt == "59401.99464502749493059900" |> Decimal.new()
    end

    test "How much Dai can be borrowed max" do
      {:ok, _, max_debt} =
        MakerDao.how_much_dai?(
          @eth_price,
          @collateral_eth
        )

      assert max_debt == "79202.6595267033265741320" |> Decimal.new()
    end

    test "get liquidation ratio with eth price, debt, and collateral eth" do
      {:ok, _, ratio} = MakerDao.collateralization_ratio?(@debt, @collateral_eth, @eth_price)
      assert ratio == "2.180876062442910004609139169" |> Decimal.new()
    end

    test "what is the liquidation price?" do
      {:ok, _, liquidation_price} = MakerDao.liquidation_price?(@debt, @collateral_eth)
      assert liquidation_price == "104.5451430855752637419268193" |> Decimal.new()
    end

    test "get collateral in eth" do
      {:ok, _, result} = MakerDao.get_collateral_in_eth(@eth_price, @debt, @collateral_ratio)
      assert result == "684.6045234254329803699793897" |> Decimal.new()
    end

    test "How much to pay back to reach target liquidation price" do
      {:ok, _, result} =
        MakerDao.target_liquidation_price(@target_liquidation_price, @debt, @collateral_eth)

      assert result == "-29591.3908483641660890" |> Decimal.new()
    end

    test "repay_or_boost? ->  boost the vault" do
      ## Boost
      {:ok, boost} = MakerDao.repay_or_boost?(@boost_price, @debt, @collateral_eth)
      b_diff = Decimal.compare(boost.collateral_eth, @collateral_eth)
      assert b_diff == "1" |> Decimal.new()
    end

    test "repay_or_boost -> repay the vault" do
      ## Repay
      {:ok, repay} = MakerDao.repay_or_boost?(@repay_price, @debt, @collateral_eth)

      r_diff = Decimal.compare(repay.collateral_eth, @collateral_eth)
      assert r_diff == "-1" |> Decimal.new()

      d_diff = Decimal.compare(repay.debt, @debt)
      assert d_diff == "-1" |> Decimal.new()
    end

    test "repay_or_boost -> keep neutral Vault" do
      ## Neutral
      {:ok, neutral} = MakerDao.repay_or_boost?(@neutral_price, @debt, @collateral_eth)
      n_diff = Decimal.compare(neutral.collateral_eth, @collateral_eth)
      assert n_diff == "0" |> Decimal.new()
    end

    test "give me the sell trigger price" do
      sell_triggger_price = MakerDao.sell_trigger_price(@debt, @collateral_eth)
      assert sell_triggger_price == "131.3505177727167613653568558" |> Decimal.new()
    end

    test "give me the buy trigger price" do
      buy_triggger_price = MakerDao.buy_trigger_price(@debt, @collateral_eth)
      assert buy_triggger_price == "160.5395217222093750021028238" |> Decimal.new()
    end

    test "test the neutral_cdp algo" do
      {:ok, neutral_cdp} = MakerDao.neutral_cdp(@neutral_price, @debt, @collateral_eth)
      compare = Decimal.compare(neutral_cdp.collateral_eth, @collateral_eth)
      assert compare == "0" |> Decimal.new()
      assert neutral_cdp.debt == @debt
    end

    test "test the repay_cdp algo" do
      {:ok, repay_cdp} = MakerDao.repay_cdp(@repay_price, @debt, @collateral_eth)
      compare = Decimal.compare(repay_cdp.collateral_eth, @collateral_eth)
      assert compare == "-1" |> Decimal.new()
      compare_debt = Decimal.compare(repay_cdp.debt, @debt)
      assert compare_debt == "-1" |> Decimal.new()
    end

    test "test the boost_cdp algo" do
      {:ok, boost_cdp} = MakerDao.boost_cdp(@boost_price, @debt, @collateral_eth)
      compare = Decimal.compare(boost_cdp.collateral_eth, @collateral_eth)
      assert compare == "1" |> Decimal.new()
      compare_debt = Decimal.compare(boost_cdp.debt, @debt)
      assert compare_debt == "1" |> Decimal.new()
    end
  end
end
