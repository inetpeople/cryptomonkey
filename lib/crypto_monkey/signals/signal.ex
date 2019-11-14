defmodule CryptoMonkey.Signals.Signal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "signals" do
    field :algo, :string
    field :received_signal, :map
    field :ticker, :string
    field :exchange, :string
    field :signal_type, :string
    field :chart_timeframe, :string
    field :signal_price, :decimal
    field :recognized_signal, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(signal, attrs) do
    allowed_fields = [
      :received_signal,
      :algo,
      :ticker,
      :exchange,
      :signal_type,
      :chart_timeframe,
      :signal_price,
      :recognized_signal
    ]

    signal
    |> cast(attrs, allowed_fields)
    |> validate_required([:algo])
  end
end
