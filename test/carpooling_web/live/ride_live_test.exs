defmodule CarpoolingWeb.RideLiveTest do
  use CarpoolingWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Carpooling.Rides

  @create_attrs %{cost: 42, date: ~N[2010-04-17 14:00:00], destination_zipcode: "some destination_zipcode", is_verified: true, origin_zipcode: "some origin_zipcode", seats: 42, verification_code: 42}
  @update_attrs %{cost: 43, date: ~N[2011-05-18 15:01:01], destination_zipcode: "some updated destination_zipcode", is_verified: false, origin_zipcode: "some updated origin_zipcode", seats: 43, verification_code: 43}
  @invalid_attrs %{cost: nil, date: nil, destination_zipcode: nil, is_verified: nil, origin_zipcode: nil, seats: nil, verification_code: nil}

  defp fixture(:ride) do
    {:ok, ride} = Rides.create_ride(@create_attrs)
    ride
  end

  defp create_ride(_) do
    ride = fixture(:ride)
    %{ride: ride}
  end

  describe "Index" do
    setup [:create_ride]

    test "lists all rides", %{conn: conn, ride: ride} do
      {:ok, _index_live, html} = live(conn, Routes.ride_index_path(conn, :index))

      assert html =~ "Listing Rides"
      assert html =~ ride.destination_zipcode
    end

    test "saves new ride", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.ride_index_path(conn, :index))

      assert index_live |> element("a", "New Ride") |> render_click() =~
               "New Ride"

      assert_patch(index_live, Routes.ride_index_path(conn, :new))

      assert index_live
             |> form("#ride-form", ride: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#ride-form", ride: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ride_index_path(conn, :index))

      assert html =~ "Ride created successfully"
      assert html =~ "some destination_zipcode"
    end

    test "updates ride in listing", %{conn: conn, ride: ride} do
      {:ok, index_live, _html} = live(conn, Routes.ride_index_path(conn, :index))

      assert index_live |> element("#ride-#{ride.id} a", "Edit") |> render_click() =~
               "Edit Ride"

      assert_patch(index_live, Routes.ride_index_path(conn, :edit, ride))

      assert index_live
             |> form("#ride-form", ride: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#ride-form", ride: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ride_index_path(conn, :index))

      assert html =~ "Ride updated successfully"
      assert html =~ "some updated destination_zipcode"
    end

    test "deletes ride in listing", %{conn: conn, ride: ride} do
      {:ok, index_live, _html} = live(conn, Routes.ride_index_path(conn, :index))

      assert index_live |> element("#ride-#{ride.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#ride-#{ride.id}")
    end
  end

  describe "Show" do
    setup [:create_ride]

    test "displays ride", %{conn: conn, ride: ride} do
      {:ok, _show_live, html} = live(conn, Routes.ride_show_path(conn, :show, ride))

      assert html =~ "Show Ride"
      assert html =~ ride.destination_zipcode
    end

    test "updates ride within modal", %{conn: conn, ride: ride} do
      {:ok, show_live, _html} = live(conn, Routes.ride_show_path(conn, :show, ride))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Ride"

      assert_patch(show_live, Routes.ride_show_path(conn, :edit, ride))

      assert show_live
             |> form("#ride-form", ride: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#ride-form", ride: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.ride_show_path(conn, :show, ride))

      assert html =~ "Ride updated successfully"
      assert html =~ "some updated destination_zipcode"
    end
  end
end
