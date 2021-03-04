defmodule Carpooling.Locations.HereMaps do
  alias Carpooling.Locations.Result

  @behaviour Carpooling.Locations.Backend

  @base "https://geocode.search.hereapi.com/v1/geocode"

  @impl true
  def name, do: "here_maps"

  @impl true
  def compute(query_str, _opts) do
    query_str
    |> fetch()
    |> build_results()
  end

  defp fetch(query) do
    query
    |> url()
    |> HTTPoison.get()
    |> handle_response()
  end

  defp url(input) do
    "#{@base}?" <>
      URI.encode_query(q: "#{input} colombia", apiKey: api_key())
  end

  defp api_key, do: Application.fetch_env!(:carpooling, :here_maps)[:apikey]

  defp handle_response({:ok, %{status_code: status_code, body: body}}) do
    {
      status_code |> check_for_error(),
      body |> Poison.Parser.parse!()
    }
  end

  def check_for_error(200), do: :ok
  def check_for_error(_), do: :error

  # defp build_results(nil), do: []

  # defp build_results(locations) do
  #   [%Result{backend: __MODULE__, locations: locations}]
  # end

  defp build_results({:ok, %{"items" => items}}) do
    locations =
      items
      |> Enum.map(fn item ->
        %{
          address: item["address"],
          position: item["position"],
          title: item["title"]
        }
      end)

    [%Result{backend: __MODULE__, locations: locations}]
  end

  defp build_results(_response), do: []
end
