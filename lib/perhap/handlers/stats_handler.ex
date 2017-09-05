defmodule Perhap.StatsHandler do
  use Perhap.Handler
  alias Perhap.Response

  def handle("GET", conn, state) do
    {:ok, conn |> Response.send(200, %{body: "stats"}), state}
  end
end
