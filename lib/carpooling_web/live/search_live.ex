defmodule CarpoolingWeb.SearchLive do
  use CarpoolingWeb, :live_view

  alias Carpooling.Locations

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       origin_query: "",
       origins: [],
       destination_query: "",
       destinations: [],
       results: []
     )}
  end

  @impl true
  def handle_event("suggest", params, socket) do
    origin_query = params["origin"] |> IO.inspect()
    destination_query = params["destination"]

    {:noreply,
     assign(socket,
       origins: search(origin_query),
       origin_query: origin_query,
       destinations: search(destination_query),
       destination_query: destination_query
     )}
  end

  @impl true
  def handle_event("search", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "2 rutas encontradas para tu destino!")
     |> assign(results: [])}
  end

  defp search(query) do
    if not CarpoolingWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    if String.length(query) >= 5 do
      Locations.compute(query, [])
      |> Enum.map(fn item -> item.locations end)
      |> List.flatten()
    else
      []
    end
  end
end
