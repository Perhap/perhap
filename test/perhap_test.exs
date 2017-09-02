defmodule PerhapTest do
  use ExUnit.Case, async: true
  use PerhapTest.Helper, port: 4499
  import PerhapTest.Helper
  require PerhapFixture, as: Fixture

  setup_all do
    Fixture.start(nil, nil)
    on_exit fn ->
      :ok
    end
    []
  end

  test "Cowboy is alive" do
    assert :ok == Application.ensure_started(:cowboy)
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
    [ {route, handler, []} | _ ] = Fixture.routes()
    assert {route, handler} == {:_, Perhap.RootHandler}
  end

  test "GETs an event" do
    resp = get("/two/event_id")
    # Todo: Implement GETting events
    assert resp.status == 500
  end

end
