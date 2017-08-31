defmodule Perhap.PingHandler do
  use Perhap.Handler
  alias Perhap.Response

  def init(req0, opts) do
    req = req0 |> Response.send(200, %{status: "ACK"})
    {:ok, req, opts}
  end
end
