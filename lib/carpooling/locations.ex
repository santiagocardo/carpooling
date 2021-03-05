defmodule Carpooling.Locations do
  @backends [Carpooling.Locations.HereMaps]

  defmodule Result do
    defstruct backend: nil, locations: nil
  end

  alias Carpooling.Locations.Cache

  def get_locations_and_zipcode(query) do
    query
    |> search()
    |> attach_zipcode()
  end

  defp search(query) do
    if not CarpoolingWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    if String.length(query) >= 5 do
      compute(query, [])
      |> Enum.map(fn item -> item.locations end)
      |> List.flatten()
    else
      []
    end
  end

  defp attach_zipcode(locations) do
    zipcode =
      case Enum.at(locations, 0) do
        %{address: %{"postalCode" => zipcode}} -> zipcode
        _ -> ""
      end

    {locations, zipcode}
  end

  def compute(query, opts \\ []) do
    timeout = opts[:timeout] || 10_000
    opts = Keyword.put_new(opts, :limit, 10)
    backends = opts[:backends] || @backends

    {uncached_backends, cached_results} = fetch_cached_results(backends, query, opts)

    uncached_backends
    |> Enum.map(&async_query(&1, query, opts))
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

  defp async_query(backend, query, opts) do
    Task.Supervisor.async_nolink(Carpooling.TaskSupervisor, backend, :compute, [query, opts],
      shutdown: :brutal_kill
    )
  end
end
