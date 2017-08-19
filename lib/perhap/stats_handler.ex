defmodule Perhap.StatsHandler do
  use Perhap.Handler
  alias Perhap.Response

  def init(req0, opts) do
    req = req0 |> Response.send(200, %{body: "stats"})
    {:ok, req, opts}
  end
end
