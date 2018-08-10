defmodule TelemetryStatsDTest do
  use ExUnit.Case

  @ip {127, 0, 0, 1}

  setup do
    {:ok, recv_socket} = :gen_udp.open(0, [:binary, ip: @ip, active: false])
    {:ok, port} = :inet.port(recv_socket)

    handler_id = random_handler_id()

    on_exit(fn ->
      :gen_udp.close(recv_socket)
      Telemetry.detach(handler_id)
    end)

    {:ok, port: port, socket: recv_socket, handler_id: handler_id}
  end

  test "attaches handler with given ID to specified events", %{handler_id: handler_id} do
    events = [
      [:event, :one],
      [:event, :two],
      [:event, :three]
    ]

    TelemetryStatsD.start(handler_id, fn _, _, _ -> [] end, events, [])

    for event <- events do
      assert [{^handler_id, ^event, TelemetryStatsD, :handle, _}] = Telemetry.list_handlers(event)
    end
  end

  test "sends counter metric to specified endpoint", %{
    port: port,
    socket: socket,
    handler_id: handler_id
  } do
    event = [:an, :event, :name]
    translator = create_translator(:counter)
    TelemetryStatsD.start(handler_id, translator, [event], hostname: @ip, port: port)

    for value <- [12.01, 10] do
      Telemetry.execute(event, value)

      assert_received_payload(socket, "#{event_to_metric(event)}:#{value}|c")
    end
  end

  test "sends timer metric to specified endpoint", %{
    port: port,
    socket: socket,
    handler_id: handler_id
  } do
    event = [:an, :event, :name]
    translator = create_translator(:timer)
    TelemetryStatsD.start(handler_id, translator, [event], hostname: @ip, port: port)

    for value <- [12.01, 10] do
      Telemetry.execute(event, value)

      assert_received_payload(socket, "#{event_to_metric(event)}:#{value}|ms")
    end
  end

  test "sends gauge metric to specified endpoint", %{
    port: port,
    socket: socket,
    handler_id: handler_id
  } do
    event = [:an, :event, :name]
    translator = create_translator(:gauge)
    TelemetryStatsD.start(handler_id, translator, [event], hostname: @ip, port: port)

    # TODO: test that one can send "+10" which is allowed datapoint for StatsD gauges
    # (or maybe only for some implementations?)
    for value <- [-12.01, 12.01, -10, 10] do
      Telemetry.execute(event, value)

      assert_received_payload(socket, "#{event_to_metric(event)}:#{value}|g")
    end
  end

  test "sends meter metric to specified endpoint", %{
    port: port,
    socket: socket,
    handler_id: handler_id
  } do
    event = [:an, :event, :name]
    value = 1
    translator = create_translator(:meter)
    TelemetryStatsD.start(handler_id, translator, [event], hostname: @ip, port: port)

    Telemetry.execute(event, value)
    assert_received_payload(socket, "#{event_to_metric(event)}:#{value}|m")
  end

  test "sends set metric to specified endpoint", %{
    port: port,
    socket: socket,
    handler_id: handler_id
  } do
    event = [:an, :event, :name]
    translator = create_translator(:set)
    TelemetryStatsD.start(handler_id, translator, [event], hostname: @ip, port: port)

    for value <- [-12.01, 12.01, -10, 10] do
      Telemetry.execute(event, value)

      assert_received_payload(socket, "#{event_to_metric(event)}:#{value}|s")
    end
  end

  test "multiple metrics can be updated at once", %{
    port: port,
    socket: socket,
    handler_id: handler_id
  } do
    event = [:an, :event, :name]
    value = 1
    translator = create_translator([:counter, :timer, :gauge, :meter, :set])
    TelemetryStatsD.start(handler_id, translator, [event], hostname: @ip, port: port)

    for type <- ["c", "ms", "g", "m", "s"] do
      Telemetry.execute(event, value)

      assert_received_payload(socket, "#{event_to_metric(event)}:#{value}|#{type}")
    end
  end

  @tag :capture_log
  test "handler is detached when wrong metric type is returned", %{
    port: port,
    handler_id: handler_id
  } do
    event = [:an, :event, :name]
    value = 1
    translator = create_translator(:invalid)
    TelemetryStatsD.start(handler_id, translator, [event], hostname: @ip, port: port)

    Telemetry.execute(event, value)

    assert [] == Telemetry.list_handlers(event)
  end

  ## Helpers

  defp random_handler_id() do
    :crypto.strong_rand_bytes(12) |> Base.encode16()
  end

  defp create_translator(types) when is_list(types) do
    fn event, value, _metadata ->
      for type <- types do
        {event_to_metric(event), type, value}
      end
    end
  end

  defp create_translator(type) do
    create_translator([type])
  end

  defp event_to_metric(event) do
    event
    |> Enum.map(&to_string/1)
    |> Enum.intersperse(".")
  end

  defp assert_received_payload(socket, payload) do
    {:ok, {_, _, data}} = :gen_udp.recv(socket, byte_size(payload), 5000)
    assert payload == data
  end
end
