defmodule Carpooling.ZipCodes.ZipCode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "zip_codes" do
    field :zip_code, :string
    field :city, :string
    field :state, :string
    field :point, Geo.PostGIS.Geometry
  end

  def changeset(zip_code, attrs) do
    all_fields = [:zip_code, :city, :state, :point]

    zip_code
    |> cast(attrs, all_fields)
    |> validate_required(all_fields)
  end
end
