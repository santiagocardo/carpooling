defmodule Carpooling.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :phone, :string
    field :role, :string
    field :verification_code, :integer
    field :is_verified, :boolean, default: false

    belongs_to :ride, Carpooling.Rides.Ride

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:phone])
    |> validate_required([:phone])
    |> validate_length(:phone, min: 10, max: 13)
  end

  @doc false
  def creation_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:role, :ride_id, :verification_code, :is_verified])
    |> validate_required([:role, :ride_id, :verification_code, :is_verified])
  end
end
