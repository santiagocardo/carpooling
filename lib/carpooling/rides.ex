defmodule Carpooling.Rides do
  @moduledoc """
  The Rides context.
  """

  import Ecto.Query, warn: false
  alias Carpooling.{Rides.Ride, Repo, ZipCodes}

  @doc """
  Returns the list of rides.

  ## Examples

      iex> list_rides()
      [%Ride{}, ...]

  """
  def list_rides do
    Repo.all(Ride)
  end

  @doc """
  Gets a single ride.

  Raises `Ecto.NoResultsError` if the Ride does not exist.

  ## Examples

      iex> get_ride!(123)
      %Ride{}

      iex> get_ride!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ride!(id), do: Repo.get!(Ride, id)

  @doc """
  Creates a ride.

  ## Examples

      iex> create_ride(%{field: value})
      {:ok, %Ride{}}

      iex> create_ride(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ride(attrs \\ %{}) do
    %Ride{}
    |> Ride.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ride.

  ## Examples

      iex> update_ride(ride, %{field: new_value})
      {:ok, %Ride{}}

      iex> update_ride(ride, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ride(%Ride{} = ride, attrs) do
    ride
    |> Ride.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ride.

  ## Examples

      iex> delete_ride(ride)
      {:ok, %Ride{}}

      iex> delete_ride(ride)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ride(%Ride{} = ride) do
    Repo.delete(ride)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ride changes.

  ## Examples

      iex> change_ride(ride)
      %Ecto.Changeset{data: %Ride{}}

  """
  def change_ride(%Ride{} = ride, attrs \\ %{}) do
    Ride.create_changeset(ride, attrs)
  end

  def change_updating(%Ride{} = ride, attrs \\ %{}) do
    Ride.update_changeset(ride, attrs)
  end

  def get_rides_in_radius(origin_zipcode, destination_zipcode, radius_in_miles) do
    origin_zipcodes_in_radius = get_zipcodes_in_radius(origin_zipcode, radius_in_miles)
    destination_zipcodes_in_radius = get_zipcodes_in_radius(destination_zipcode, radius_in_miles)

    query =
      from ride in Ride,
        where:
          ride.origin_zipcode in ^origin_zipcodes_in_radius and
            ride.destination_zipcode in ^destination_zipcodes_in_radius

    Repo.all(query)
  end

  defp get_zipcodes_in_radius(zipcode, radius_in_miles) do
    zipcode
    |> ZipCodes.get_zip_codes_in_radius(radius_in_miles)
    |> case do
      {:ok, zip_codes} -> Enum.map(zip_codes, & &1.zip_code)
      error -> error
    end
  end
end
