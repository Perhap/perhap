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
    [ {route, handler, []} | _ ] = Fixture.routes() |> Enum.reverse
    assert {route, handler} == {:_, Perhap.RootHandler}
  end

  test "POSTs an event" do
    event = make_random_event()
    resp = %{a: "A", b: "B"}
             |> Poison.encode!
             |> post("/test/domain1event/#{event.metadata.entity_id}/#{event.event_id}")
    assert resp.status == 204
  end

  test "retrieves a single event" do
    event = make_random_event()
    data = %{"a" => "A", "b" => "B"}
    data |> Poison.encode! |> post("/test/domain1event/#{event.metadata.entity_id}/#{event.event_id}")
    resp = get("/test/#{event.event_id}/event")
    %{"data" => data2, "event_id" => event_id} = resp.body |> Poison.decode!
    assert data == data2
    assert event_id == event.event_id
  end

  test "retrieves multiple events" do
    event1 = Perhap.Event.get_uuid_v1()
    event2 = Perhap.Event.get_uuid_v1()
    event3 = Perhap.Event.get_uuid_v1()
    entity1 = Perhap.Event.get_uuid_v4()
    entity2 = Perhap.Event.get_uuid_v4()
    data = %{"a" => "A", "b" => "B"}
    data |> Poison.encode! |> post("/test/domain2event1/#{entity1}/#{event1}")
    data |> Poison.encode! |> post("/test/domain2event2/#{entity2}/#{event2}")
    data |> Poison.encode! |> post("/test2/domain3event/#{entity1}/#{event3}")
    resp1 = get("/test/#{entity1}/events")
    resp1body = Poison.decode!(resp1.body)
    assert List.first(resp1body["events"])["metadata"]["entity_id"] == entity1
    resp2 = get("/test/#{entity2}/events")
    resp2body = Poison.decode!(resp2.body)
    assert List.first(resp2body["events"])["event_id"] == event2
    resp3 = get("/test/events")
    resp3body = Poison.decode!(resp3.body)
    assert length(resp3body["events"]) >= 2
    resp4 = get("/test2/#{entity1}/events")
    resp4body = Poison.decode!(resp4.body)
    assert List.first(resp4body["events"])["metadata"]["entity_id"] == entity1
    resp5 = get("/test2/events")
    resp5body = Poison.decode!(resp5.body)
    refute resp5body == resp3body
  end

  test "POSTs an event, gets a model" do
    event = make_random_event()
    resp = %{}
             |> Poison.encode!
             |> post("/test/domain2event1/#{event.metadata.entity_id}/#{event.event_id}")
    assert resp.status == 204
    resp2 = get("/test/domain2/#{event.metadata.entity_id}/model")
    resp2body = Poison.decode!(resp2.body)
    assert resp2body["model"] == %{"value" => 1}
  end

  test "interacts with events and models directly too" do
    entity_id = Perhap.Event.get_uuid_v4()
    assert :ok == Fixture.event(%{context: :test,
                                  event_type: :domain1event,
                                  entity_id: entity_id,
                                  event_id: Perhap.Event.get_uuid_v1(),
                                  data: %{doesnt: "matter"}})
    Process.sleep(100)
    assert Fixture.model(:test, :domain1) > 0
    assert Fixture.model(:test, :domain2, entity_id) > 0
  end

  test "two models for one event through web interface" do
    entity_id = Perhap.Event.get_uuid_v4()
    event_id = Perhap.Event.get_uuid_v1()
    resp1 = %{} |> Poison.encode! |> post("/test/domain1event/#{entity_id}/#{event_id}")
    assert resp1.status == 204
    resp2 = get("/test/domain1/model")
    resp2body = Poison.decode!(resp2.body)
    assert resp2body["value"] > 0
    resp3 = get("/test/domain2/#{entity_id}/model")
    resp3body = Poison.decode!(resp3.body)
    assert resp3body["value"] > 0
  end

end
