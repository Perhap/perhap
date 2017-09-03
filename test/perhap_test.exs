defmodule PerhapTest do
  use PerhapTest.Helper, port: 4499

  setup_all do
    # Fixture.start(nil, nil)
    on_exit fn ->
      # Fixture.stop()
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
    [ {route, handler, []} | _ ] = Fixture.routes()
    assert {route, handler} == {:_, Perhap.RootHandler}
  end

  test "POSTs an event" do
    event = make_random_event()
    resp = %{a: "A", b: "B"}
             |> Poison.encode!
             |> post("/test/domain1event/#{event.metadata.entity_id}/#{event.event_id}")
    assert resp.status == 204
  end

end
