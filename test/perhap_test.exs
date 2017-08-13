defmodule PerhapTest do
  use ExUnit.Case, async: true
  use Plug.Test
  require PerhapTest.Fixture, as: Fixture

  @config [ network: [
            protocol: :http,
            bind: {'0.0.0.0', 4500},
            acceptors: System.schedulers_online * 2 ] ]
  Application.put_env(:perhap_test, :perhap, @config)

  @router_opts Perhap.Router.init([])

  test "Receives allowed methods on option call to root" do
    conn = conn(:options, "/") |> Perhap.Router.call(@router_opts)
    assert (conn.resp_headers |> Map.new)["access-control-allow-headers"] =~ "GET PUT POST DELETE OPTIONS"
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

  test "Finds the test path" do
    [
      [context: :two, domain: {:mine, [single: "me", events: [:none]]}],
      [context: :two, domain: {:ours, [model: "us", events: [:none]]}]
    ] = Fixture.routes()
  end

end
