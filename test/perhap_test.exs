defmodule PerhapTest do
  use ExUnit.Case, async: true
  import PerhapTest.Helper
  require PerhapTest.Fixture, as: Fixture

  @config protocol: :http,
          bind: "0.0.0.0",
          port: 4499,
          acceptors: System.schedulers_online * 2
  Application.put_env(:perhap_test, :perhap, @config)

  setup_all do
    Fixture.start(nil, nil)
    on_exit fn ->
      :ok
    end
    []
  end

  test "Receives allowed methods on option call to root" do
    resp = options("/")
    assert resp.status == 200
    headers = Enum.into(resp.headers, %{})
    assert Map.get(headers, "access-control-allow-methods", "") =~ "GET PUT POST DELETE OPTIONS"
  end

  test "Receives an ACK on ping" do
    resp = get("/ping")
    assert resp.status == 200
    assert resp.body =~ "ACK"
  end

  test "Receives a 404 on a non-existent route" do
    resp = get("/doesnt-exist")
    assert resp.status == 404
  end

  test "Finds the test routes" do
    IO.inspect Fixture.routes()
    [ {route, handler, []} | _ ] = Fixture.routes()
    assert {route, handler} == {:_, Perhap.RootHandler}
  end

  test "creates route functions" do

  end

end
