defmodule Carpooling.Locations.HereMaps do
  alias Carpooling.Locations.Result

  @behaviour Carpooling.Locations.Backend

  @base "https://discover.search.hereapi.com/v1/discover"

  @impl true
  def name, do: "here_maps"

  @impl true
  def compute(query_str, point, _opts) do
    fetch(query_str, point)
    |> build_results()
  end

  defp fetch(query, point) do
    url(query, point)
    |> HTTPoison.get()
    |> handle_response()
  end

  defp url(query, point) do
    "#{@base}?" <>
      URI.encode_query(q: query, apiKey: api_key()) <>
      "&in=countryCode:COL" <>
      if String.length(point) > 0 do
        "&at=#{point}"
      else
        ""
      end
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
