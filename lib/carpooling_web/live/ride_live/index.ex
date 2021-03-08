defmodule CarpoolingWeb.RideLive.Index do
  use CarpoolingWeb, :live_view

  alias Carpooling.{Rides, Rides.Ride}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :rides, list_rides())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Editar Ruta")
    |> assign(:ride, Rides.get_ride!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nueva Ruta")
    |> assign(:ride, %Ride{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Rutas Disponibles")
    |> assign(:ride, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    ride = Rides.get_ride!(id)
    {:ok, _} = Rides.delete_ride(ride)

    {:noreply, assign(socket, :rides, list_rides())}
  end

  defp list_rides do
    Rides.list_rides()
  end
end
