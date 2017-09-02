defmodule Perhap.ModelHandler do
  use Perhap.Handler

  def handle("GET", conn, state) do
    {:ok, model_requested(conn), state}
  end

  @spec model_requested(:cowboy_req.req()) :: term()
  def model_requested(conn) do
    conn |> Perhap.Response.send(Perhap.Error.make(:operation_not_implemented))
  end
end
