defmodule Perhap.ModelHandler do
  use Perhap.Handler

  @spec model_requested(:cowboy_req.req()) :: term()
  def model_requested(conn) do
    Perhap.Response.send(conn, Perhap.Error.make(:operation_not_implemented))
    # get_model_from_store
    :ok
  end
end
