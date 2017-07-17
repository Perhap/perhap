defmodule PerhapTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @config [ network: [
            protocol: :http,
            bind: {'0.0.0.0', 4500},
            acceptors: System.schedulers_online * 2 ] ]
  Application.put_env(:perhap_test, :perhap, @config)

  @router_opts Perhap.Router.init([])

  defmodule PerhapFixture do
    use Perhap, app: :perhap_test
    #assert is_list(config())
    assert @app == :perhap_test
  end

  test "Receives an ACK on ping" do
    conn = conn(:get, "/ping") |> Perhap.Router.call(@router_opts)
    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "ACK"
  end

  test "Receives a 404 on a non-existent route" do
    conn = conn(:get, "/doesnt-exist") |> Perhap.Router.call(@router_opts)
    assert conn.state == :sent
    assert conn.status == 404
  end

end
