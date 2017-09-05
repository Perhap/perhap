defmodule Perhap.RootHandler do
  use Perhap.Handler

  def handle("OPTIONS", conn, state) do
    { :ok,
      conn
      |> set_response_header("access-control-allow-methods", "GET PUT POST DELETE OPTIONS")
      |> set_response_header("access-control-max-age", "86400")
      |> Perhap.Response.send(200, ""),
      state }
  end
  def handle(_, conn, state) do
    { :ok, conn |> Perhap.Response.send(Perhap.Error.make(:not_found)), state }
  end

end
