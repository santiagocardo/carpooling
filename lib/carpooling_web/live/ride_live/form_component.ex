defmodule CarpoolingWeb.RideLive.FormComponent do
  use CarpoolingWeb, :live_component

  alias Carpooling.{Rides, Locations}

  @impl true
  def update(%{ride: ride} = assigns, socket) do
    changeset = Rides.change_ride(ride)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       changeset: changeset,
       origins: [],
       destinations: []
     )}
  end

  @impl true
  def handle_event("validate", %{"ride" => ride_params}, socket) do
    %{"origin" => origin, "destination" => destination} = ride_params

    {origins, origin_zipcode} = Locations.get_locations_and_zipcode(origin)
    {destinations, destination_zipcode} = Locations.get_locations_and_zipcode(destination)

    ride_params =
      Map.merge(ride_params, %{
        "origin_zipcode" => origin_zipcode,
        "destination_zipcode" => destination_zipcode
      })

    changeset =
      socket.assigns.ride
      |> Rides.change_ride(ride_params)
      |> Map.put(:action, :validate)

    {:noreply,
     assign(socket,
       changeset: changeset,
       origins: origins,
       destinations: destinations
     )}
  end

  def handle_event("save", %{"ride" => ride_params}, socket) do
    save_ride(socket, socket.assigns.action, ride_params)
  end

  defp save_ride(socket, :edit, ride_params) do
    case Rides.update_ride(socket.assigns.ride, ride_params) do
      {:ok, _ride} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ride updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_ride(socket, :new, ride_params) do
    case Rides.create_ride(ride_params) do
      {:ok, _ride} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ride created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
