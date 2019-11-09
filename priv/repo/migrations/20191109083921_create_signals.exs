defmodule CryptoMonkey.Repo.Migrations.CreateSignals do
  use Ecto.Migration

  def change do
    create table(:signals) do
      add(:algo, :string)
      add(:received_signal, :map)
      add(:ticker, :string)
      add(:exchange, :string)
      add(:signal_type, :string)
      add(:chart_timeframe, :string)
      add(:signal_price, :decimal)
      add(:recognized_signal, :boolean, default: false)
      timestamps()
    end

    create(index(:signals, [:algo], comment: "Index Algo"))
  end
end
