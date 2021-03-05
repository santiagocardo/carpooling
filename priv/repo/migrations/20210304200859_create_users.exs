defmodule Carpooling.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :role, :string
      add :phone, :string
      add :ride_id, references(:rides, on_delete: :delete_all)

      timestamps()
    end

    create index(:users, [:ride_id])
  end
end
