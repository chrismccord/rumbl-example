defmodule Rumbl.EventHandler do
  def handle(event, value, metadata, config) do
    IO.puts("Got #{inspect(event)}, #{value}, #{inspect(metadata)}")
  end
end
