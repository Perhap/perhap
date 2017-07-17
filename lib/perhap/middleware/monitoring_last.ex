defmodule Perhap.Monitoring.Last do
  @behaviour :cowboy_middleware
  require Logger

  def execute(req0, env0) do
    before_time = env0[:before_time]
    after_time = System.monotonic_time()
    diff = System.convert_time_unit(after_time - before_time, :native, :microseconds) / 1000
    path = :cowboy_req.path(req0)
    method = :cowboy_req.method(req0)
    path_info = String.split(path, "/") |> Enum.at(2)
    Logger.info("#{path_info},#{method}/#{diff}ms")
    {:ok, req0, env0}
  end
end
