defmodule Carpooling.Locations do
  @backends [Carpooling.Locations.HereMaps]

  defmodule Result do
    defstruct backend: nil, locations: nil
  end

  alias Carpooling.Locations.Cache

  def get_locations(query, point) do
    search(query, point)
    |> attach_current_location()
  end

  defp search(query, point) do
    if not CarpoolingWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    if String.length(query) >= 5 do
      compute(query, point, [])
      |> Enum.map(fn item -> item.locations end)
      |> List.flatten()
    else
      []
    end
  end

  defp attach_current_location(locations) do
    current_location =
      case Enum.at(locations, 0) do
        %{address: %{"postalCode" => _}} = location -> location
        _ -> %{address: %{"postalCode" => ""}}
      end

    {locations, current_location}
  end

  def compute(query, point, opts \\ []) do
    timeout = opts[:timeout] || 10_000
    opts = Keyword.put_new(opts, :limit, 10)
    backends = opts[:backends] || @backends

    {uncached_backends, cached_results} = fetch_cached_results(backends, query, opts)

    uncached_backends
    |> Enum.map(&async_query(&1, query, point, opts))
    |> Task.yield_many(timeout)
    |> Enum.map(fn {task, res} ->
      res || Task.shutdown(task, :brutal_kill)
    end)
    |> Enum.flat_map(fn
      {:ok, results} -> results
      _ -> []
    end)
    |> write_results_to_cache(query, opts)
    |> Kernel.++(cached_results)
    |> Enum.take(opts[:limit])
  end

  defp fetch_cached_results(backends, query, opts) do
    {uncached_backends, results} =
      Enum.reduce(
        backends,
        {[], []},
        fn backend, {uncached_backends, acc_results} ->
          case Cache.fetch({backend.name(), query, opts[:limit]}) do
            {:ok, results} ->
              {uncached_backends, [results | acc_results]}

            :error ->
              {[backend | uncached_backends], acc_results}
          end
        end
      )

    {uncached_backends, List.flatten(results)}
  end

  defp write_results_to_cache(results, query, opts) do
    Enum.map(results, fn %Result{backend: backend} = result ->
      :ok = Cache.put({backend.name(), query, opts[:limit]}, result)

      result
    end)
  end

  defp async_query(backend, query, point, opts) do
    Task.Supervisor.async_nolink(
      Carpooling.TaskSupervisor,
      backend,
      :compute,
      [query, point, opts],
      shutdown: :brutal_kill
    )
  end
end
