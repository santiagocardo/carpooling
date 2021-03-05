defmodule CarpoolingWeb.SearchLive do
  use CarpoolingWeb, :live_view

  alias Carpooling.Locations

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
       results: []
     )}
  end

  @impl true
  def handle_event("suggest", %{"origin" => origin, "destination" => destination}, socket) do
    {origins, origin_zipcode} = Locations.get_locations_and_zipcode(origin)
    {destinations, destination_zipcode} = Locations.get_locations_and_zipcode(destination)

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

    {:noreply,
     socket
     |> put_flash(:info, "2 rutas encontradas para tu destino!")
     |> assign(results: [])}
  end
end
