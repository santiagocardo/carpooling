defmodule Carpooling.Repo.Migrations.CreateRides do
  use Ecto.Migration

  def change do
    create table(:rides) do
      add :origin, :string
      add :origin_zipcode, :string
      add :destination, :string
      add :destination_zipcode, :string
      add :date, :naive_datetime
      add :seats, :integer
      add :verification_code, :integer
      add :is_verified, :boolean, default: false, null: false
      add :cost, :integer

      timestamps()
    end

    create index(:rides, [:origin_zipcode])
    create index(:rides, [:destination_zipcode])
  end
end
