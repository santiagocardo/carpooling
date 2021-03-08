defmodule Carpooling.Repo.Migrations.ZipCodeTable do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS postgis")

    create table(:zip_codes) do
      add :zip_code, :string, null: false
      add :city, :string, null: false
      add :state, :string, size: 2, null: false
    end

    execute("SELECT AddGeometryColumn('zip_codes', 'point', 4326, 'POINT', 2)")
    execute("CREATE INDEX zip_code_point_index on zip_codes USING gist (point)")

    create unique_index(:zip_codes, [:zip_code])
  end

  def down do
    drop(table(:zip_codes))
    execute("DROP EXTENSION IF EXISTS postgis")
  end
end
