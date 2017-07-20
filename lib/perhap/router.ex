defmodule Perhap.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  options "/" do
    conn
      |> merge_resp_headers([{"access-control-allow-headers", "GET PUT POST DELETE OPTIONS"},
       {"access-control-max-age", "86400"}])
      |> send_resp(204, "")
  end

  get "/ping" do
    send_resp(conn, 200, "ACK")
  end

  match _ do
    send_resp(conn, 404, "NOT FOUND")
  end
end
