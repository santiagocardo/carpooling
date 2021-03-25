defmodule CarpoolingWeb.RideLive.FormComponent do
  use CarpoolingWeb, :live_component

  alias Carpooling.{Rides, Locations, ZipCodes, Accounts}

  @wa_url "https://api.whatsapp.com"
  @invalid_code_changeset %Ecto.Changeset{
    action: :validate,
    errors: [
      code: {"código de verificación inválido!", []}
    ],
    valid?: false
  }

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
  def handle_event("validate", %{"ride" => ride_params, "position" => position}, socket) do
    %{"origin" => origin, "destination" => destination} = ride_params

    {origins, %{address: %{"postalCode" => origin_zipcode}}} =
      Locations.get_locations(origin, position)

    {destinations, %{address: %{"postalCode" => destination_zipcode}}} =
      Locations.get_locations(destination, position)

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

  @impl true
  def handle_event("save", params, socket) do
    ride_params = params["ride"]

    case feed_locations(params) do
      [{:ok, _}, {:ok, _}] ->
        save_ride(socket, socket.assigns.action, ride_params)

      {:error, :missing_location} ->
        changeset =
          socket.assigns.ride
          |> Rides.change_ride(ride_params)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, :changeset, changeset)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Uups, Algo ha ocurrido mal!")
         |> push_redirect(to: socket.assigns.return_to)}
    end
  end

  defp save_ride(socket, :edit, ride_params) do
    ride = socket.assigns.ride
    code = parse_code(ride_params["code"])

    case ride.verification_code == code do
      true ->
        case Rides.update_ride(ride, ride_params) do
          {:ok, _ride} ->
            {:noreply,
             socket
             |> put_flash(:info, "Ruta editada exitosamente!")
             |> push_redirect(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      _ ->
        changeset = Map.put(@invalid_code_changeset, :data, ride)

        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_ride(socket, :new, ride_params) do
    verification_code = Enum.random(1_000..9_999)
    ride_params = Map.put(ride_params, "verification_code", verification_code)

    case Rides.create_ride(ride_params) do
      {:ok, ride} ->
        driver = %{
          role: "driver",
          phone: ride_params["phone"],
          ride_id: ride.id,
          verification_code: verification_code,
          is_verified: true,
          pickup_location: "driver location"
        }

        create_wa_url(ride, driver)
        |> create_driver_and_redirect(driver, socket)

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp create_driver_and_redirect(ride_wa_url, driver, socket) do
    case Accounts.create_user(driver) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ruta creada exitosamente!")
         |> redirect(external: ride_wa_url)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Uups, Algo ha ocurrido mal!")
         |> push_redirect(to: socket.assigns.return_to)}
    end
  end

  def feed_locations(%{"ride" => %{"origin_zipcode" => ""}}), do: {:error, :missing_location}
  def feed_locations(%{"ride" => %{"destination_zipcode" => ""}}), do: {:error, :missing_location}

  def feed_locations(%{"ride" => ride_params, "position" => position}) do
    %{
      "origin" => origin,
      "destination" => destination
    } = ride_params

    {_origins, origin_location} = Locations.get_locations(origin, position)
    {_destinations, destination_location} = Locations.get_locations(destination, position)

    [origin_location, destination_location]
    |> Enum.map(&map_and_feed_locations/1)
  end

  defp map_and_feed_locations(location) do
    location
    |> map_location()
    |> ZipCodes.validate_or_create_zip_code()
  end

  defp map_location(location) do
    %{
      address: %{
        "postalCode" => zip_code,
        "city" => city,
        "countyCode" => state
      },
      position: %{
        "lat" => lat,
        "lng" => lng
      }
    } = location

    city = String.downcase(city)
    state = String.downcase(state)

    %{
      city: city,
      state: state,
      zip_code: zip_code,
      point: %Geo.Point{coordinates: {lng, lat}, srid: 4326}
    }
  end

  defp parse_code(code) do
    case Integer.parse(code) do
      :error -> 0
      {num, _} -> num
    end
  end

  defp create_wa_url(ride, driver) do
    ride_path = "#{app_url()}/rutas/#{driver.ride_id}"
    text = "Transporte Solidario: Nueva Ruta Creada
      📍 Ruta: #{ride.origin} - #{ride.destination}
      ⏰ Fecha y hora: #{ride.date}

      Tu código de verificación es: #{driver.verification_code}
      Recuerda verificar tu ruta ingresando a: #{ride_path}/verificar

      Para ver esta ruta ingresa a: #{ride_path}
      Para editar esta ruta ingresa a: #{ride_path}/editar
      Para eliminar esta ruta ingresa a: #{ride_path}/eliminar"

    "#{@wa_url}/send?" <> URI.encode_query(phone: "+57#{driver.phone}", text: text)
  end

  defp app_url, do: Application.fetch_env!(:carpooling, :server)[:app_url]
end
