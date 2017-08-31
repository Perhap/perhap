require Logger

defmodule Perhap.Response do

  alias Perhap.Error, as: E

  def send(req0, %Perhap.Error{} = error) do
    req0 |> send(error.http_code, E.format(error))
  end
  def send(req0, 204) do
    :cowboy_req.reply(204, %{}, "", req0)
  end

  def send(req0, 200, "") do
    :cowboy_req.reply(200,
      %{"access-control-allow-origin" => "*",
        "access-control-allow-headers" => "content-type"}, "", req0)
  end
  def send(req0, status, response_term) do
    {:ok, json, crc32} = make(response_term)
    :cowboy_req.reply(status,
      %{"content-type" => "application/json",
        "access-control-allow-origin" => "*",
        "x-perhap-crc32" => Integer.to_string(crc32)}, json, req0)
  end

  defp make(map) when is_map(map) do
    json = Poison.encode!(map)
    makeCRC(json)
  end
  defp make(list) when is_list(list) do
    json = Poison.encode!(list)
    makeCRC(json)
  end
  defp make(json) when is_binary(json) do
    makeCRC(json)
  end
  defp makeCRC(data) when is_binary(data) do
    crc32 = :erlang.crc32(data)
    {:ok, data, crc32}
  end

end
