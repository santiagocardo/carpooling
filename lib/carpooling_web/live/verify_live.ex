defmodule CarpoolingWeb.VerifyLive do
  use CarpoolingWeb, :live_view

  alias Carpooling.{Rides, Accounts}

  @user_changeset Accounts.change_user(%Accounts.User{})
  @ride_changeset Rides.change_ride(%Rides.Ride{})
  @invalid_code_changeset %Ecto.Changeset{
    action: :validate,
    errors: [
      code: {"código de verificación inválido!", []}
    ],
    valid?: false
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    user_params["code"]
    |> parse_code()
    |> check_code({:user, socket.assigns.user}, socket)
  end

  @impl true
  def handle_event("validate", %{"ride" => ride_params}, socket) do
    ride_params["code"]
    |> parse_code()
    |> check_code({:ride, socket.assigns.ride}, socket)
  end

  defp check_code(code, entity_tuple, socket) do
    changeset =
      case entity_tuple do
        {:user, _} -> @user_changeset
        {:ride, _} -> @ride_changeset
      end

    case code < 1_000 do
      true ->
        {:noreply, assign(socket, :changeset, changeset)}

      false ->
        validate_code(code, entity_tuple, socket)
    end
  end

  defp validate_code(code, {entity_id, entity}, socket) do
    case entity.verification_code == code do
      true ->
        update_entity(entity_id, entity, socket)

      _ ->
        {:noreply, assign(socket, :changeset, invalid_code_changeset(entity))}
    end
  end

  defp update_entity(:user, user, socket) do
    case Accounts.update_user(user, %{"is_verified" => true}) do
      {:ok, _user} ->
        case Rides.update_ride(user.ride, %{"seats" => user.ride.seats - 1}) do
          {:ok, _ride} ->
            {:noreply,
             socket
             |> put_flash(:info, "Pasajero verificado exitosamente!")
             |> push_redirect(to: Routes.ride_show_path(socket, :show, user.ride_id))}

          _ ->
            {:noreply,
             socket
             |> put_flash(:error, "Uups! Parece que esta ruta ya no tiene asientos disponibles!")
             |> push_redirect(to: Routes.ride_show_path(socket, :show, user.ride_id))}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp update_entity(:ride, ride, socket) do
    case Rides.update_ride(ride, %{"is_verified" => true}) do
      {:ok, _ride} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ruta verificada exitosamente!")
         |> push_redirect(to: Routes.ride_show_path(socket, :show, ride.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp apply_action(socket, :user, %{"id" => user_id}) do
    user = Accounts.get_user!(user_id)

    case user.is_verified do
      true ->
        redirect(socket, :user, user.ride_id)

      false ->
        socket
        |> assign(:page_title, "Verificar Usuario")
        |> assign(:user, user)
        |> assign(:changeset, @user_changeset)
    end
  end

  defp apply_action(socket, :ride, %{"id" => ride_id}) do
    ride = Rides.get_ride!(ride_id)

    case ride.is_verified do
      true ->
        redirect(socket, :ride, ride.id)

      false ->
        socket
        |> assign(:page_title, "Verificar Ruta")
        |> assign(:ride, ride)
        |> assign(:changeset, @ride_changeset)
    end
  end

  defp redirect(socket, entity_id, id) do
    msg =
      case entity_id do
        :user -> "Pasajero ya verificado!"
        :ride -> "Ruta ya verificada!"
      end

    socket
    |> put_flash(:info, msg)
    |> push_redirect(to: Routes.ride_show_path(socket, :show, id))
  end

  defp parse_code(code) do
    case Integer.parse(code) do
      :error -> 0
      {num, _} -> num
    end
  end

  defp invalid_code_changeset(entity) do
    Map.put(@invalid_code_changeset, :data, entity)
  end
end
