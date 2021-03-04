defmodule Carpooling.Repo do
  use Ecto.Repo,
    otp_app: :carpooling,
    adapter: Ecto.Adapters.Postgres
end
