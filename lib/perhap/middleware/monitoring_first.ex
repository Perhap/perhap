defmodule Perhap.Monitoring.First do
  @behaviour :cowboy_middleware
  def execute(req0, env0) do
    env = env0 |> Map.put(:before_time, System.monotonic_time())
    {:ok, req0, env}
  end
end
