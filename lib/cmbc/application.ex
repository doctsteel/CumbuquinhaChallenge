defmodule Cmbc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    initialize_database()

    children = [
      CmbcWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:cmbc, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cmbc.PubSub},
      # Start a worker by calling: Cmbc.Worker.start_link(arg)
      # {Cmbc.Worker, arg},
      # Start to serve requests, typically the last entry
      CmbcWeb.Endpoint,
      Cmbc.TransactionManager
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Cmbc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp initialize_database do
    file_path = "priv/dbzinho.txt"

    case File.read(file_path) do
      {:ok, _content} ->
        IO.puts("Little db already exists! Skipping creation.")

      {:error, _reason} ->
        IO.puts("Little db not found. Creating a new one.")
        File.write(file_path, "")
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CmbcWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
