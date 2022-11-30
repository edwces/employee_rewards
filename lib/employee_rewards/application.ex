defmodule EmployeeRewards.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      EmployeeRewards.Repo,
      # Start the Telemetry supervisor
      EmployeeRewardsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: EmployeeRewards.PubSub},
      # Start the Endpoint (http/https)
      EmployeeRewardsWeb.Endpoint
      # Start a worker by calling: EmployeeRewards.Worker.start_link(arg)
      # {EmployeeRewards.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EmployeeRewards.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EmployeeRewardsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
