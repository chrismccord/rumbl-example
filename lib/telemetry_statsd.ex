defmodule TelemetryStatsD do
  @moduledoc """
  Telemetry reporter sending metrics to StatsD
  """

  ## API

  def start(handler_id, translator, events, opts) do
    hostname = opts |> Keyword.get(:hostname, 'localhost') |> normalize_hostname()
    port = Keyword.get(opts, :port, 8125)
    {:ok, socket} = :gen_udp.open(0)
    config = %{translator: translator, socket: socket, hostname: hostname, port: port}
    :ok = Telemetry.attach_many(handler_id, events, __MODULE__, :handle, config)
  end

  def handle(event, value, metadata, config) do
    metrics = config.translator.(event, value, metadata)
    lines = metrics_to_statsd(metrics)

    for line <- lines do
      :ok = :gen_udp.send(config.socket, config.hostname, config.port, line)
    end
  end

  ## Internals

  defp normalize_hostname(host) when is_binary(host), do: to_charlist(host)
  defp normalize_hostname(host), do: host

  defp metrics_to_statsd(metrics) do
    Enum.map(metrics, &metric_to_statsd/1)
  end

  defp metric_to_statsd({metric, type, value}) do
    [metric, ?:, to_string(value), ?|, statsd_metric_type(type)]
  end

  defp statsd_metric_type(:counter), do: "c"
  defp statsd_metric_type(:timer), do: "ms"
  defp statsd_metric_type(:gauge), do: "g"
  defp statsd_metric_type(:meter), do: "m"
  defp statsd_metric_type(:set), do: "s"
end
