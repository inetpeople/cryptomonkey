defmodule CryptoMonkey.MakerDaoTest do
  use CryptoMonkey.DataCase
  alias CryptoMonkey.MakerDao

  describe "maker dao" do
    # Account Start ETH
    @collateral_eth 734.11106508933161075

    # Account Start DEBT
    @debt 32272.296428372912148

    # Target Collateral Ratio
    @collateral_ratio 3.5

    # Liquidation protection, if bellow @collateral_sell_ratio, repay to @collateral_ratio
    @collateral_sell_ratio 3.3
    # Leverage increase, if above @collateral_buy_ratio, boost to @collateral_ratio
    # @collateral_buy_ratio 3.7

    @eth_price 152

    test "how much dai can be loaned with x eth as collateral?" do
      {:ok, _, max_debt} =
        MakerDao.get_max_dai_with_collateral_in_eth(
          @eth_price,
          @collateral_eth,
          @collateral_ratio
        )

      assert max_debt == 33398.949220489354
    end

    test "how much dai can be loaned with x% as collateral?" do
      {:ok, _, max_debt} =
        MakerDao.get_max_dai_with_target_collateral_ratio(
          @eth_price,
          @collateral_eth,
          @collateral_ratio
        )

      assert max_debt == 33398.949220489354
    end

    test "How much Dai can be borrowed max" do
      {:ok, _, max_debt} =
        MakerDao.how_much_dai?(
          @eth_price,
          @collateral_eth
        )

      assert max_debt == 77930.88151447517
    end

    test "get liquidation ratio with eth price, debt, and collateral eth" do
      {:ok, _, ratio} = MakerDao.collateralization_ratio?(@debt, @collateral_eth, @eth_price)
      assert ratio == 3.6221879199442633
    end

    test "what is the liquidation price?" do
      {:ok, _, liquidation_price} = MakerDao.liquidation_price?(@debt, @collateral_eth)
      assert liquidation_price == 69.08040079926344
    end

    test "get collateral in eth" do
      {:ok, _, result} = MakerDao.get_collateral_in_eth(@eth_price, @debt, @collateral_ratio)
      assert result == 778.4842242386325
    end
  end
end
