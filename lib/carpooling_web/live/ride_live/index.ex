defmodule CarpoolingWeb.RideLive.Index do
  use CarpoolingWeb, :live_view

  alias Carpooling.{Locations, Rides, Rides.Ride}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       origin: "",
       origins: [],
       origin_zipcode: "",
       destination: "",
       destinations: [],
       destination_zipcode: "",
       results: Rides.list_rides()
     ), temporary_assigns: [results: []]}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("suggest", params, socket) do
    %{
      "origin" => origin,
      "destination" => destination,
      "position" => position
    } = params

    {origins, %{address: %{"postalCode" => origin_zipcode}}} =
      Locations.get_locations(origin, position)

    {destinations, %{address: %{"postalCode" => destination_zipcode}}} =
      Locations.get_locations(destination, position)

    {:noreply,
     assign(socket,
       origins: origins,
       origin: origin,
       origin_zipcode: origin_zipcode,
       destinations: destinations,
       destination: destination,
       destination_zipcode: destination_zipcode
     )}
  end

  @impl true
  def handle_event("search", params, socket) do
    %{
      "origin_zipcode" => origin_zipcode,
      "destination_zipcode" => destination_zipcode
    } = params

    results = Rides.get_rides_in_radius(origin_zipcode, destination_zipcode, 3)

    msg =
      results
      |> Enum.count()
      |> build_msg()

    {:noreply,
     socket
     |> put_flash(:info, msg <> " para tu destino")
     |> assign(results: results)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Rides.get_ride(id) do
      %{is_verified: true} = ride ->
        socket
        |> assign(:page_title, "Editar Ruta")
        |> assign(:ride, ride)

      nil ->
        push_redirect(socket, to: Routes.ride_index_path(socket, :index))
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nueva Ruta")
    |> assign(:ride, %Ride{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Transporte Solidario")
    |> assign(:ride, nil)
  end

  defp build_msg(num) do
    case num do
      0 -> "No se encontraron rutas"
      1 -> "#{num} encontrada"
      _ -> "#{num} encontradas"
    end
  end
end
