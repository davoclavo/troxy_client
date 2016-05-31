defmodule TroxyClient.Mixfile do
  use Mix.Project

  def project do
    [app: :troxy_client,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [
      mod: {TroxyClient, []},
      applications: [
        :logger,
        :websocket_client, :phoenix_gen_socket_client,
        :hackney
      ]
    ]
  end

  defp deps do
    [
      {:phoenix_gen_socket_client, github: "aircloak/phoenix_gen_socket_client"},
      {:websocket_client, github: "sanmiguel/websocket_client", tag: "1.1.0"},
      {:poison, "~> 1.5.2"},
      {:hackney, "~> 1.1"},
    ]
  end
end
