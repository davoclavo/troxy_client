defmodule TroxyClient.SocketClient do
  require Logger
  alias Phoenix.Channels.GenSocketClient

  def start_link do
    Logger.info("starting #{inspect __MODULE__}")
    GenSocketClient.start_link(
      __MODULE__,
      Phoenix.Channels.GenSocketClient.Transport.WebSocketClient,
      "ws://localhost:4000/socket/websocket?room=lobby"
    )
  end

  @behaviour GenSocketClient

  def init(url) do
    Logger.info("connecting via init #{inspect self}")
    {:connect, url, %{hackney_client: nil}}
  end

  def handle_connected(transport, state) do
    Logger.info("connected")
    GenSocketClient.join(transport, "users:lobby")
    {:ok, state}
  end

  def handle_disconnected(reason, state) do
    Logger.error("disconnected: #{inspect reason}")

    # I think Phoenix disconnects after some time of inactivity, so reconnect
    Process.send_after(self, :connect, :timer.seconds(1))
    {:ok, state}
  end

  def handle_joined(topic, _payload, _transport, state) do
    Logger.info("joined the topic #{topic}")
    {:ok, state}
  end

  def handle_join_error(topic, payload, _transport, state) do
    Logger.error("join error on the topic #{topic} - #{inspect payload}")
    {:ok, state}
  end

  def handle_channel_closed(topic, payload, _transport, state) do
    Logger.error("disconnected from the topic #{topic} - #{inspect payload}")
    {:ok, state}
  end

  @topic "users:lobby"
  def handle_message(@topic, "conn:req", conn, _transport, state) do
    method = conn["method"] |> String.downcase |> String.to_atom

    base = to_string(conn["scheme"]) <> "://" <> conn["req_headers"]["host"]<> conn["request_path"]
    url = case conn["query_string"] do
      "" -> base
      query_string -> base <> "?" <> query_string
    end

    headers = conn["req_headers"] |> Enum.into([])
    payload = :stream
    hackney_options = []
    {:ok, hackney_client} = :hackney.request(method, url, headers, payload, hackney_options)

    {:ok, %{state | hackney_client: hackney_client}}
  end
  def handle_message(@topic, "conn:req_body_chunk", conn, _transport, state = %{hackney_client: hackney_client}) do
    decoded_chunk = Base.decode64!(conn["body_chunk"])
    :hackney.send_body(hackney_client, decoded_chunk)
    {:ok, %{state | hackney_client: hackney_client}}
  end
  def handle_message(topic, event, payload, _transport, state) do
    Logger.warn("message on topic #{topic} - #{event} #{inspect payload}")
    {:ok, state}
  end

  def handle_reply(topic, _ref, payload, _transport, state) do
    Logger.warn("reply on topic #{topic} - #{inspect payload}")
    {:ok, state}
  end



  def handle_info(:connect, _transport, state) do
    Logger.info("connecting")
    {:connect, state}
  end

  def handle_info({:join, topic}, transport, state) do
    Logger.info("joining the topic #{topic}")
    case GenSocketClient.join(transport, topic) do
      {:error, reason} ->
        Logger.error("error joining the topic #{topic}: #{inspect reason}")
        # Process.send_after(self, {:join, topic}, :timer.seconds(1))
      {:ok, _ref} -> :ok
    end

    {:ok, state}
  end

  def handle_info(message, _transport, state) do
    Logger.warn("Unhandled message #{inspect message}")
    {:ok, state}
  end
end
