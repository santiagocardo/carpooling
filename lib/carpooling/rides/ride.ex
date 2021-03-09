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
    field :phone, :string, virtual: true

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
    |> validate_number(:seats, greater_than: 0, less_than: 5)
    |> validate_length(:origin, min: 5)
    |> validate_length(:destination, min: 5)
    |> validate_length(:origin_zipcode, min: 5, max: 6)
    |> validate_length(:destination_zipcode, min: 5, max: 6)
    |> validate_zipcode(:origin)
    |> validate_zipcode(:destination)
  end

  def create_changeset(ride, attrs) do
    ride
    |> changeset(attrs)
    |> cast(attrs, [:phone])
    |> validate_required([:phone])
    |> validate_length(:phone, min: 10, max: 13)
  end

  defp validate_zipcode(%Ecto.Changeset{errors: errors} = changeset, location) do
    location_zipcode =
      (Atom.to_string(location) <> "_zipcode")
      |> String.to_atom()

    case List.keyfind(errors, location, 0) do
      nil ->
        case List.keyfind(errors, location_zipcode, 0) do
          nil ->
            changeset

          _ ->
            errors = List.insert_at(errors, -1, {location, {"ubicación inválida", []}})

            changeset
            |> Map.put(:errors, errors)
        end

      _ ->
        changeset
    end
  end
end
