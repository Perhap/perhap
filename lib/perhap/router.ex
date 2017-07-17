defmodule Perhap.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/ping" do
    send_resp(conn, 200, "ACK")
  end

  match _ do
    send_resp(conn, 404, "NOT FOUND")
  end
end
