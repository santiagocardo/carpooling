defmodule CarpoolingWeb.ConfirmationActionLive do
  use CarpoolingWeb, :live_view

  alias Carpooling.{Rides, Accounts}

  @user_changeset Accounts.change_user(%Accounts.User{})
  @ride_changeset Rides.Ride.base_changeset(%Rides.Ride{}, %{})

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

  defp check_code(code, {entity_id, entity}, socket) do
    changeset =
      case entity_id do
        :user -> @user_changeset
        :ride -> @ride_changeset
      end

    socket = assign(socket, :changeset, changeset)

    case code < 1_000 do
      true ->
        {:noreply, socket}

      false ->
        entity_tuple = {socket.assigns.live_action, entity}
        validate_code(code, entity_tuple, socket)
    end
  end

  defp validate_code(code, {entity_action, entity}, socket) do
    verification_code =
      case entity_action in [:user_delete, :user_verify] do
        false -> entity.verification_code
        _ -> entity.ride.verification_code
      end

    case verification_code == code do
      true ->
        do_entity_action(entity_action, entity, socket)

      _ ->
        {:noreply, assign(socket, :changeset, invalid_code_changeset(socket.assigns.changeset))}
    end
  end

  defp do_entity_action(:user_delete, user, socket) do
    case Accounts.delete_user(user) do
      {:ok, _user} ->
        case Rides.update_ride_seats(user.ride, :inc) do
          {:ok, _ride} ->
            {:noreply,
             socket
             |> put_flash(:info, "Pasajero eliminado exitosamente!")
             |> push_redirect(to: Routes.ride_show_path(socket, :show, user.ride_id))}

          _ ->
            {:noreply,
             socket
             |> put_flash(:error, "Uups! Parece que hubo un problema!")
             |> push_redirect(to: Routes.ride_show_path(socket, :show, user.ride_id))}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp do_entity_action(:user_verify, user, socket) do
    case Accounts.update_user(user, %{"is_verified" => true}) do
      {:ok, _user} ->
        case Rides.update_ride_seats(user.ride, :dec) do
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

  defp do_entity_action(:ride_delete, ride, socket) do
    case Rides.delete_ride(ride) do
      {:ok, _ride} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ruta eliminada exitosamente!")
         |> push_redirect(to: Routes.ride_index_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp do_entity_action(:ride_verify, ride, socket) do
    case Rides.verify_ride(ride) do
      {:ok, _ride} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ruta verificada exitosamente!")
         |> push_redirect(to: Routes.ride_show_path(socket, :show, ride.id))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp apply_action(socket, :user_delete, %{"id" => user_id}) do
    case Accounts.get_user(user_id) do
      nil ->
        flash_message_and_redirect(socket, :user)

      user ->
        case user do
          %{role: "driver"} ->
            flash_message_and_redirect(socket, :driver)

          %{is_verified: false} ->
            flash_message_and_redirect(socket, :user)

          _ ->
            socket
            |> assign(:page_title, "Eliminar Pasajero")
            |> assign(:user, user)
            |> assign(:changeset, @user_changeset)
        end
    end
  end

  defp apply_action(socket, :user_verify, %{"id" => user_id}) do
    case Accounts.get_user(user_id) do
      nil ->
        push_redirect(socket, to: Routes.ride_index_path(socket, :index))

      %{is_verified: true} = user ->
        flash_message_and_redirect(socket, :user, user.ride_id)

      user ->
        socket
        |> assign(:page_title, "Verificar Pasajero")
        |> assign(:user, user)
        |> assign(:changeset, @user_changeset)
    end
  end

  defp apply_action(socket, :ride_delete, %{"id" => ride_id}) do
    case Rides.get_ride(ride_id) do
      nil ->
        flash_message_and_redirect(socket, :ride)

      ride ->
        socket
        |> assign(:page_title, "Eliminar Ruta")
        |> assign(:ride, ride)
        |> assign(:changeset, @ride_changeset)
    end
  end

  defp apply_action(socket, :ride_verify, %{"id" => ride_id}) do
    case Rides.get_ride(ride_id) do
      nil ->
        push_redirect(socket, to: Routes.ride_index_path(socket, :index))

      %{is_verified: true} = ride ->
        flash_message_and_redirect(socket, :ride, ride.id)

      ride ->
        socket
        |> assign(:page_title, "Verificar Ruta")
        |> assign(:ride, ride)
        |> assign(:changeset, @ride_changeset)
    end
  end

  defp flash_message_and_redirect(socket, entity_id, id) do
    msg =
      case entity_id do
        :user -> "Pasajero ya verificado!"
        :ride -> "Ruta ya verificada!"
      end

    socket
    |> put_flash(:info, msg)
    |> push_redirect(to: Routes.ride_show_path(socket, :show, id))
  end

  defp flash_message_and_redirect(socket, entity_id) do
    msg =
      case entity_id do
        :user -> "Pasajero inexistente!"
        :ride -> "Ruta inexistente!"
        :driver -> "No se puede eliminar conductor. Para ello se debe eliminar la ruta!"
      end

    socket
    |> put_flash(:info, msg)
    |> push_redirect(to: Routes.ride_index_path(socket, :index))
  end

  defp parse_code(code) do
    case Integer.parse(code) do
      :error -> 0
      {num, _} -> num
    end
  end

  defp invalid_code_changeset(changeset) do
    changeset
    |> Ecto.Changeset.add_error(:code, "código de verificación inválido!")
    |> Map.put(:action, :validate)
  end
end
