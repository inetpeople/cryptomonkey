defmodule CryptoMonkeyWeb.MakerDaoView do
  use CryptoMonkeyWeb, :view
  use Number

  def format_currency(usd) do
    Number.Currency.number_to_currency(usd)
  end

  def format_ethereum(number) do
    Number.Currency.number_to_currency(number, unit: " Ξ ")
  end

  def format_percentage(percentage) do
    Number.Percentage.number_to_percentage(percentage, precision: 0)
  end
end
