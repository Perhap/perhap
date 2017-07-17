alias Perhap.Response

defmodule Perhap.PingHandler do
  use Perhap.Handler
  def init(req0, opts) do
    req = req0 |> Response.send(200, %{status: "Ack"})
    {:ok, req, opts}
  end
end
