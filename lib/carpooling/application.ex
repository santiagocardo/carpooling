defmodule Carpooling.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Carpooling.Locations.Cache,
      {Task.Supervisor, name: Carpooling.TaskSupervisor},
      Carpooling.Repo,
      # Start the Telemetry supervisor
      CarpoolingWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Carpooling.PubSub},
      # Start the Endpoint (http/https)
      CarpoolingWeb.Endpoint
      # Start a worker by calling: Carpooling.Worker.start_link(arg)
      # {Carpooling.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Carpooling.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CarpoolingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
