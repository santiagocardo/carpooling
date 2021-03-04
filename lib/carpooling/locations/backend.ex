defmodule Carpooling.Locations.Backend do
  @callback name() :: String.t()
  @callback compute(query :: String.t(), opts :: Keyword.t()) ::
              [%Carpooling.Locations.Result{}]
end
