defmodule CryptoMonkeyWeb.LayoutView do
  use CryptoMonkeyWeb, :view

  def utc_time_from_millisecond(time) do
    DateTime.from_unix!(time, :millisecond)
  end
end
