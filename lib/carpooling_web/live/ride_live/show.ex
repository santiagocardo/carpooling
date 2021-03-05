defmodule CarpoolingWeb.RideLive.Show do
  use CarpoolingWeb, :live_view

  alias Carpooling.Rides

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ride, Rides.get_ride!(id))}
  end

  defp page_title(:show), do: "Show Ride"
  defp page_title(:edit), do: "Edit Ride"
end
