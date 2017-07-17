alias Perhap.Error, as: E
alias Perhap.Response

defmodule Perhap.RootHandler do
  use Perhap.Handler
  def init(req0, opts) do
    method = :cowboy_req.method(req0)
    case method == "OPTIONS" do
      false ->
        { :ok, req0 |> Response.send(E.make(:not_found)), opts }
      true ->
        req = :cowboy_req.set_resp_header("access-control-allow-methods", "GET PUT POST DELETE OPTIONS", req0)
        { :ok, 
          :cowboy_req.set_resp_header("access-control-max-age", "86400", req) |> Response.send(200, ""),
          opts }
    end
  end
end
