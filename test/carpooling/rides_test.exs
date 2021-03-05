defmodule Carpooling.RidesTest do
  use Carpooling.DataCase

  alias Carpooling.Rides

  describe "rides" do
    alias Carpooling.Rides.Ride

    @valid_attrs %{cost: 42, date: ~N[2010-04-17 14:00:00], destination_zipcode: "some destination_zipcode", is_verified: true, origin_zipcode: "some origin_zipcode", seats: 42, verification_code: 42}
    @update_attrs %{cost: 43, date: ~N[2011-05-18 15:01:01], destination_zipcode: "some updated destination_zipcode", is_verified: false, origin_zipcode: "some updated origin_zipcode", seats: 43, verification_code: 43}
    @invalid_attrs %{cost: nil, date: nil, destination_zipcode: nil, is_verified: nil, origin_zipcode: nil, seats: nil, verification_code: nil}

    def ride_fixture(attrs \\ %{}) do
      {:ok, ride} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Rides.create_ride()

      ride
    end

    test "list_rides/0 returns all rides" do
      ride = ride_fixture()
      assert Rides.list_rides() == [ride]
    end

    test "get_ride!/1 returns the ride with given id" do
      ride = ride_fixture()
      assert Rides.get_ride!(ride.id) == ride
    end

    test "create_ride/1 with valid data creates a ride" do
      assert {:ok, %Ride{} = ride} = Rides.create_ride(@valid_attrs)
      assert ride.cost == 42
      assert ride.date == ~N[2010-04-17 14:00:00]
      assert ride.destination_zipcode == "some destination_zipcode"
      assert ride.is_verified == true
      assert ride.origin_zipcode == "some origin_zipcode"
      assert ride.seats == 42
      assert ride.verification_code == 42
    end

    test "create_ride/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rides.create_ride(@invalid_attrs)
    end

    test "update_ride/2 with valid data updates the ride" do
      ride = ride_fixture()
      assert {:ok, %Ride{} = ride} = Rides.update_ride(ride, @update_attrs)
      assert ride.cost == 43
      assert ride.date == ~N[2011-05-18 15:01:01]
      assert ride.destination_zipcode == "some updated destination_zipcode"
      assert ride.is_verified == false
      assert ride.origin_zipcode == "some updated origin_zipcode"
      assert ride.seats == 43
      assert ride.verification_code == 43
    end

    test "update_ride/2 with invalid data returns error changeset" do
      ride = ride_fixture()
      assert {:error, %Ecto.Changeset{}} = Rides.update_ride(ride, @invalid_attrs)
      assert ride == Rides.get_ride!(ride.id)
    end

    test "delete_ride/1 deletes the ride" do
      ride = ride_fixture()
      assert {:ok, %Ride{}} = Rides.delete_ride(ride)
      assert_raise Ecto.NoResultsError, fn -> Rides.get_ride!(ride.id) end
    end

    test "change_ride/1 returns a ride changeset" do
      ride = ride_fixture()
      assert %Ecto.Changeset{} = Rides.change_ride(ride)
    end
  end
end
