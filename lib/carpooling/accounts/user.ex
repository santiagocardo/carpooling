defmodule Carpooling.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :phone, :string
    field :role, :string

    belongs_to :ride, Carpooling.Rides.Ride

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:role, :phone, :ride_id])
    |> validate_required([:role, :phone, :ride_id])
  end
end
