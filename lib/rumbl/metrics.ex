defmodule Rumbl.Metrics do
  @moduledoc false

  def translate([:phoenix, :controller, :render, :stop], value, metadata) do
    controller = Phoenix.Controller.controller_module(metadata.conn)
    action = Phoenix.Controller.action_name(metadata.conn)
    controller_and_action = concat_controller_and_action(controller, action)

    [
      {[controller_and_action, ".request_count"], :counter, 1},
      {[controller_and_action, ".request_latency"], :timer, value}
    ]
  end

  def translate([:phoenix, :controller, :call, :stop], value, metadata) do
    controller = Phoenix.Controller.controller_module(metadata.conn)
    action = Phoenix.Controller.action_name(metadata.conn)
    controller_and_action = concat_controller_and_action(controller, action)

    [
      {[controller_and_action, ".render_latency"], :timer, value}
    ]
  end

  def translate(_, _, _) do
    []
  end

  @spec concat_controller_and_action(module, atom) :: IO.chardata()
  defp concat_controller_and_action(controller, action) do
    controller =
      controller
      |> Module.split()
      |> Enum.map(&Macro.underscore/1)
      |> Enum.intersperse(?.)

    [controller, ?., :erlang.atom_to_binary(action, :utf8)]
  end
end
