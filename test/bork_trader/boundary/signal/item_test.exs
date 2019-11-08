defmodule CryptoMonkey.Boundary.Signal.ItemTest do
  use ExUnit.Case, async: true
  alias CryptoMonkey.Boundary.Signal.{Item}

  def assert_item(item, type, expected) do
    {_, item} = item
    assert Map.get(item, type) == expected
    {:ok, item}
  end

  describe "new_item/1" do
    test "items can be created when signal is a Map" do
      signal = create_signal()

      Item.new(signal)
      |> assert_item(:algo, "BTCI")
      |> assert_item(:recognized_signal, true)
    end

    test "items can be created when signal is an uncomplete Map Signal" do
      signal = incomplete_signal()

      Item.new(signal)
      |> assert_item(:recognized_signal, false)
      |> assert_item(:received_signal, signal)
    end

    test "items can be created when signal is a String" do
      signal = "Btci ETHUSD Kraken Buy 5m none"

      Item.new(signal)
      |> assert_item(:algo, "BTCI")
      |> assert_item(:recognized_signal, true)
    end

    test "items can be created when signal is am uncomplete String" do
      signal = "Btci ETHUSD"

      Item.new(signal)
      |> assert_item(:recognized_signal, false)
      |> assert_item(:received_signal, signal)
    end

    defp create_signal do
      %{
        "algo" => "BTCI",
        "chart_timeframe" => "1W",
        "exchange" => "Kraken",
        "signal_price" => "",
        "signal_type" => "sell",
        "ticker" => "ETHUSD"
      }
    end

    defp incomplete_signal do
      %{"not_me" => "asdf"}
    end
  end
end
