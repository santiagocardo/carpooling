defmodule Carpooling.Rides.Ride do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rides" do
    field :cost, :integer
    field :date, :naive_datetime
    field :destination, :string
    field :destination_zipcode, :string
    field :is_verified, :boolean, default: false
    field :origin, :string
    field :origin_zipcode, :string
    field :seats, :integer
    field :verification_code, :integer

    has_many :users, Carpooling.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(ride, attrs) do
    ride
    |> cast(attrs, [
      :origin,
      :destination,
      :origin_zipcode,
      :destination_zipcode,
      :date,
      :seats,
      :verification_code,
      :is_verified,
      :cost
    ])
    |> validate_required([
      :origin,
      :destination,
      :origin_zipcode,
      :destination_zipcode,
      :date,
      :seats,
      :cost
    ])
  end
end