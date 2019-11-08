defmodule CryptoMonkey.Boundary.KrakenFuturexTest do
  use ExUnit.Case, async: true
  alias CryptoMonkey.Boundary.Signal.{Item}

  def assert_item(item, type, expected) do
    {_, item} = item
    assert Map.get(item, type) == expected
    {:ok, item}
  end

  describe "connection" do
    test "items can be created when signal is a Map" do
      false
    end
  end
end
