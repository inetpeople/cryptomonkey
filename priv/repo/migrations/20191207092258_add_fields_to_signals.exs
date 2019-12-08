defmodule CryptoMonkey.Repo.Migrations.AddFieldsToSignals do
  use Ecto.Migration

  import Ecto.Query

  def up do
    alter table(:signals) do
      add(:closed_at, :timestamp)
      add(:published_at, :timestamp)
      add(:confirmed_at, :timestamp)
      add(:closing_signal_id, references(:signals))
    end

    # flush()

    # from(p in "posts",
    #   update: [set: [published_at: p.updated_at]],
    #   where: p.published
    # )
    # |> MyApp.Repo.update_all([])
  end

  def down do
    alter table(:signals) do
      remove(:closed_at)
      remove(:published_at)
      remove(:confirmed_at)
      remove(:closing_signal_id)
    end
  end
end
