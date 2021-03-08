defmodule CarpoolingWeb.SearchLive do
  use CarpoolingWeb, :live_view

  alias Carpooling.{Locations, Rides}

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
       results: nil
     )}
  end

  @impl true
  def handle_event("suggest", %{"origin" => origin, "destination" => destination}, socket) do
    {origins, %{address: %{"postalCode" => origin_zipcode}}} = Locations.get_locations(origin)

    {destinations, %{address: %{"postalCode" => destination_zipcode}}} =
      Locations.get_locations(destination)

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
    results_count = Enum.count(results)

    flash_msg =
      "#{results_count} ruta#{
        if results_count == 1 do
          " encontrada"
        else
          "s encontradas"
        end
      } para tu destino!"

    {:noreply,
     socket
     |> put_flash(:info, flash_msg)
     |> assign(results: results)}
  end
end
