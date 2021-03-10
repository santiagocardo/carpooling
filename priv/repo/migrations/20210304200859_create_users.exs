defmodule Carpooling.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :role, :string
      add :phone, :string
      add :ride_id, references(:rides, on_delete: :delete_all)
      add :is_verified, :boolean, default: false, null: false
      add :verification_code, :integer, null: false

      timestamps()
    end

    create index(:users, [:ride_id])
  end
end
