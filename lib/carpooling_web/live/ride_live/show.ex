defmodule CarpoolingWeb.RideLive.Show do
  use CarpoolingWeb, :live_view

  alias Carpooling.{Rides, Accounts, Accounts.User}

  @impl true
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user(%User{})

    {:ok,
     socket
     |> assign(:user, %User{})
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    case Rides.get_ride(id) do
      %{is_verified: true} = ride ->
        {:noreply,
         socket
         |> assign(:page_title, "Ver Ruta")
         |> assign(:ride, ride)}

      nil ->
        {:noreply, push_redirect(socket, to: Routes.ride_index_path(socket, :index))}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    user_params =
      Map.merge(user_params, %{
        "role" => "passenger",
        "ride_id" => socket.assigns.ride.id,
        "verification_code" => Enum.random(1_000..9_999),
        "is_verified" => false
      })

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ruta asignada exitosamente!")
         |> push_redirect(to: Routes.confirmation_action_path(socket, :user_verify, user.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
