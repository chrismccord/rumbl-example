defmodule Rumbl.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised

    TelemetryStatsD.start(
      "statsd_reporter",
      &Rumbl.Metrics.translate/3,
      [
        [:phoenix, :controller, :render, :start],
        [:phoenix, :controller, :render, :stop],
        [:phoenix, :controller, :call, :start],
        [:phoenix, :controller, :call, :stop]
      ],
      hostname: "localhost",
      port: 8125
    )

    children = [
      # Start the Ecto repository
      Rumbl.Repo,
      # Start the endpoint when the application starts
      RumblWeb.Endpoint,
      RumblWeb.Presence
      # Starts a worker by calling: Rumbl.Worker.start_link(arg)
      # {Rumbl.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rumbl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RumblWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
