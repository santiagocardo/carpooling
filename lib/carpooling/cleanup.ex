defmodule Carpooling.Cleanup do
  use GenServer
  import Ecto.Query, warn: false

  alias Carpooling.{Repo, Rides.Ride}

  @clear_interval :timer.hours(12)
  @thirty_hours -108_000

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    state = %{
      interval: opts[:clear_interval] || @clear_interval,
      timer: nil
    }

    {:ok, schedule_clear(state)}
  end

  def handle_info(:delete_old_rides, state) do
    past_day =
      DateTime.utc_now()
      |> DateTime.add(@thirty_hours)
      |> DateTime.to_naive()

    query = from(ride in Ride, where: ride.date < ^past_day)

    Repo.delete_all(query)

    {:noreply, schedule_clear(state)}
  end

  defp schedule_clear(state) do
    %{state | timer: Process.send_after(self(), :delete_old_rides, state.interval)}
  end
end
